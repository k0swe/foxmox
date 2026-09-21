#!/usr/bin/env python3
"""Normalize gpasm output to the canonical picpro-derived Intel HEX encoding.

Gpasm correctly emits PIC16F84A user-ID words as 0x000F because only each low
nibble exists. Picpro preserved erased readback as 0xFFFF. Both program the same
silicon state; this normalizer restores the original readback representation and
record layout so the complete file can be compared byte-for-byte.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from verify_image import read_hex, region


def record(address: int, kind: int, data: bytes) -> str:
    body = bytes([len(data)]) + address.to_bytes(2, "big") + bytes([kind]) + data
    checksum = (-sum(body)) & 0xFF
    return ":" + (body + bytes([checksum])).hex().upper()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    image = read_hex(args.input)
    rom = region(image, 0x0000, 0x0800)
    config = region(image, 0x400E, 2)
    eeprom = region(image, 0x4200, 0x40)

    lines = [record(address, 0, rom[address : address + 16]) for address in range(0, 0x0800, 16)]
    lines.append(record(0x4000, 0, b"\xFF" * 8))
    lines.append(record(0x400E, 0, config))
    lines.extend(record(0x4200 + offset, 0, eeprom[offset : offset + 16]) for offset in range(0, 0x40, 16))
    lines.append(record(0, 1, b""))
    args.output.write_text("\n".join(lines) + "\n", encoding="ascii", newline="\n")


if __name__ == "__main__":
    main()
