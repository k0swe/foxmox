#!/usr/bin/env python3
"""Verify gpasm output against the canonical FoxMox programming image."""

from __future__ import annotations

import argparse
from pathlib import Path


def read_hex(path: Path) -> dict[int, int]:
    image: dict[int, int] = {}
    base = 0
    eof = False
    for number, raw in enumerate(path.read_text(encoding="ascii").splitlines(), 1):
        line = raw.strip()
        if not line:
            continue
        if not line.startswith(":"):
            raise ValueError(f"{path}:{number}: not Intel HEX")
        record = bytes.fromhex(line[1:])
        if len(record) != record[0] + 5 or sum(record) & 0xFF:
            raise ValueError(f"{path}:{number}: invalid length or checksum")
        count = record[0]
        address = int.from_bytes(record[1:3], "big")
        kind = record[3]
        data = record[4 : 4 + count]
        if kind == 0:
            for offset, value in enumerate(data):
                absolute = base + address + offset
                if absolute in image:
                    raise ValueError(f"{path}:{number}: overlap at 0x{absolute:X}")
                image[absolute] = value
        elif kind == 1:
            eof = True
        elif kind == 2:
            base = int.from_bytes(data, "big") << 4
        elif kind == 4:
            base = int.from_bytes(data, "big") << 16
        elif kind not in (3, 5):
            raise ValueError(f"{path}:{number}: unsupported record type {kind}")
    if not eof:
        raise ValueError(f"{path}: missing EOF")
    return image


def region(image: dict[int, int], start: int, size: int) -> bytes:
    try:
        return bytes(image[address] for address in range(start, start + size))
    except KeyError as error:
        raise ValueError(f"missing byte at 0x{error.args[0]:X}") from error


def words(data: bytes) -> list[int]:
    if len(data) % 2:
        raise ValueError("word region has odd byte count")
    return [data[i] | data[i + 1] << 8 for i in range(0, len(data), 2)]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("built", type=Path)
    parser.add_argument(
        "--reference",
        type=Path,
        default=Path(__file__).resolve().parent / "foxmox-v2.6.hex",
    )
    args = parser.parse_args()

    reference = read_hex(args.reference)
    built = read_hex(args.built)

    checks: list[tuple[str, bool]] = []
    checks.append(("program ROM (1024 words)", region(built, 0x0000, 0x0800) == region(reference, 0x0000, 0x0800)))
    checks.append(("configuration word", region(built, 0x400E, 2) == region(reference, 0x400E, 2)))
    checks.append(("data EEPROM (64 bytes)", region(built, 0x4200, 0x40) == region(reference, 0x4200, 0x40)))

    # PIC16F84A user-ID locations implement only the low nibble of each word.
    # Picpro preserved erased reads as 0xFFFF; gpasm's __IDLOCS correctly emits
    # words 0x000F. Compare the physically implemented nibbles.
    ref_ids = words(region(reference, 0x4000, 8))
    built_ids = words(region(built, 0x4000, 8))
    checks.append(("user-ID implemented nibbles", [x & 0xF for x in built_ids] == [x & 0xF for x in ref_ids]))

    expected_addresses = set(range(0x0000, 0x0800)) | set(range(0x4000, 0x4008)) | set(range(0x400E, 0x4010)) | set(range(0x4200, 0x4240))
    checks.append(("no unexpected output regions", set(built) == expected_addresses))

    failed = False
    for name, passed in checks:
        print(f"{'PASS' if passed else 'FAIL'} {name}")
        failed |= not passed
    if failed:
        raise SystemExit(1)
    print("PASS lossless programmed-memory equivalence")


if __name__ == "__main__":
    main()
