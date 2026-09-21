#!/usr/bin/env python3
"""Minimal Intel HEX reader for the committed FoxMox firmware image."""

from __future__ import annotations

from pathlib import Path


def read_intel_hex(path: Path) -> dict[int, int]:
    image: dict[int, int] = {}
    base = 0
    eof = False

    for line_number, raw_line in enumerate(path.read_text(encoding="ascii").splitlines(), 1):
        line = raw_line.strip()
        if not line:
            continue
        if not line.startswith(":"):
            raise ValueError(f"{path}:{line_number}: not an Intel HEX record")
        record = bytes.fromhex(line[1:])
        if len(record) < 5 or len(record) != record[0] + 5:
            raise ValueError(f"{path}:{line_number}: invalid record length")
        if sum(record) & 0xFF:
            raise ValueError(f"{path}:{line_number}: checksum mismatch")

        count = record[0]
        address = int.from_bytes(record[1:3], "big")
        record_type = record[3]
        data = record[4 : 4 + count]

        if record_type == 0x00:
            for offset, value in enumerate(data):
                absolute = base + address + offset
                if absolute in image:
                    raise ValueError(f"{path}:{line_number}: overlapping address 0x{absolute:X}")
                image[absolute] = value
        elif record_type == 0x01:
            if count or address:
                raise ValueError(f"{path}:{line_number}: malformed EOF record")
            eof = True
        elif record_type == 0x02:
            if count != 2:
                raise ValueError(f"{path}:{line_number}: malformed segment-address record")
            base = int.from_bytes(data, "big") << 4
        elif record_type == 0x04:
            if count != 2:
                raise ValueError(f"{path}:{line_number}: malformed linear-address record")
            base = int.from_bytes(data, "big") << 16
        elif record_type in (0x03, 0x05):
            # Start-address records do not contribute memory bytes.
            continue
        else:
            raise ValueError(f"{path}:{line_number}: unsupported record type 0x{record_type:02X}")

    if not eof:
        raise ValueError(f"{path}: missing EOF record")
    return image


def region(image: dict[int, int], start: int, size: int) -> bytes:
    missing = [address for address in range(start, start + size) if address not in image]
    if missing:
        raise ValueError(f"missing address 0x{missing[0]:X} in requested region")
    return bytes(image[address] for address in range(start, start + size))
