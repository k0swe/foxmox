#!/usr/bin/env python3
"""Build one PIC16F84A Intel HEX image from picpro binary dumps.

Use picpro's ``dump ... --binary`` commands to obtain ROM, EEPROM, and config
files, then pass those three files here. Picpro swaps each adjacent pair in its
binary ROM and EEPROM output. ROM is already in the little-endian byte order
used by Intel HEX; EEPROM is byte-addressed, so this script reverses that swap.

The 26-byte config dump is a K150 protocol response rather than a memory image:
its silicon ID and generic calibration field are diagnostic and are not written
to the output. The user-ID words and PIC16F84A configuration word are retained.
"""

from __future__ import annotations

import argparse
import struct
from pathlib import Path

from intelhex import IntelHex


def unswap_pairs(data: bytes) -> bytes:
    if len(data) % 2:
        raise ValueError("pair-swapped data must have an even length")
    return b"".join(data[i : i + 2][::-1] for i in range(0, len(data), 2))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rom", required=True, type=Path, help="2048-byte picpro binary ROM dump")
    parser.add_argument("--eeprom", required=True, type=Path, help="64-byte picpro binary EEPROM dump")
    parser.add_argument("--config", required=True, type=Path, help="26-byte picpro binary config dump")
    parser.add_argument("-o", "--output", required=True, type=Path, help="combined Intel HEX output")
    args = parser.parse_args()

    rom = args.rom.read_bytes()
    eeprom_dump = args.eeprom.read_bytes()
    config_dump = args.config.read_bytes()
    if len(rom) != 2048:
        raise ValueError(f"expected 2048 ROM bytes, got {len(rom)}")
    if len(eeprom_dump) != 64:
        raise ValueError(f"expected 64 EEPROM bytes, got {len(eeprom_dump)}")
    if len(config_dump) != 26:
        raise ValueError(f"expected 26 config bytes, got {len(config_dump)}")

    chip_id = struct.unpack_from("<H", config_dump, 0)[0]
    user_id = config_dump[2:10]
    fuse = struct.unpack_from("<H", config_dump, 10)[0]
    calibration = struct.unpack_from("<H", config_dump, 24)[0]
    if chip_id & 0xFFF0 != 0x0560:
        raise ValueError(f"unexpected PIC16F84A device ID 0x{chip_id:04X}")
    if fuse & ~0x3FFF:
        raise ValueError(f"invalid 14-bit configuration word 0x{fuse:04X}")

    image = IntelHex()
    image.puts(0x0000, rom)
    image.puts(0x4000, user_id)                    # user-ID words 0x2000..0x2003
    image.puts(0x400E, struct.pack("<H", fuse))  # configuration word 0x2007
    image.puts(0x4200, unswap_pairs(eeprom_dump)) # data EEPROM 0x2100..
    args.output.parent.mkdir(parents=True, exist_ok=True)
    image.write_hex_file(str(args.output), byte_count=16)

    print(f"Wrote {args.output}")
    print(f"  silicon ID (diagnostic only): 0x{chip_id:04X}")
    print(f"  user ID:                     {user_id.hex()}")
    print(f"  configuration word:          0x{fuse:04X}")
    print(f"  generic CAL (not included):  0x{calibration:04X}")


if __name__ == "__main__":
    main()
