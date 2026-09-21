#!/usr/bin/env python3
"""Reproduce the evidence tables used by the FoxMox firmware report.

No third-party modules are required. The script validates the committed Intel
HEX image, extracts its ROM and logical EEPROM regions, checks the machine words
at all control-flow anchors used by the analysis, and emits a deterministic
Markdown map. It intentionally fails closed if an input or relevant opcode
changes.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

from intelhex_image import read_intel_hex, region

ROOT = Path(__file__).resolve().parent.parent
EXPECTED_ROM_SHA256 = "546781166e6c349ccbb167d5767dacbf99e84a844c02573d8a7d724120fe6fbd"
EXPECTED_EEPROM_SHA256 = "3ecd61956a537acd8086bfbe1c5345dce7cae8af925cf8473f01e992a6cb9bab"
FOSC_HZ = 3_579_545

S1_NAMES = ["MOE", "MOI", "MOS", "MOH", "MO5", "MO", "A", "B", "F", "L", "N", "P", "V", "X", "Z", "FOX"]
S1_TARGETS = [0x1F8, 0x201, 0x20A, 0x213, 0x21C, 0x225, 0x22D, 0x238, 0x241, 0x24A, 0x253, 0x25E, 0x267, 0x270, 0x279, 0x282]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def words_from_raw(data: bytes) -> list[int]:
    if len(data) != 2048:
        raise ValueError(f"ROM: expected 2048 bytes, got {len(data)}")
    words = [data[i] | data[i + 1] << 8 for i in range(0, len(data), 2)]
    if any(word & ~0x3FFF for word in words):
        raise ValueError("ROM contains a word outside the PIC14 14-bit range")
    return words


def expect(words: list[int], address: int, expected: int) -> None:
    actual = words[address]
    if actual != expected:
        raise ValueError(f"ROM 0x{address:03X}: expected 0x{expected:04X}, got 0x{actual:04X}")


def initial_pair_address(s1: int, s2: int) -> int:
    """Equivalent of ROM 0x090-0x0AC; returns 0x20, 0x22, 0x24, or 0x26."""
    if s1 >= 5:
        offset = 4 if s2 >= 8 else 0
    elif s2 == 15:
        offset = 6
    elif s2 >= 9:
        offset = 4
    elif s2 >= 7:
        offset = 2
    else:
        offset = 0
    return 0x20 + offset


def cadence_pair_address(s1: int, s2: int) -> int:
    """Equivalent of ROM 0x0C1-0x0D0."""
    return (0x10 if s1 >= 5 else 0x00) + 2 * (s2 & 7)


def counter_tick_seconds(setting: int) -> float:
    # OPTION_REG=0x08 assigns the prescaler to WDT, so TMR0 advances at Fosc/4.
    # The 0x0E:0xA6 nested countdown fires after 0x0D*256+0xA6 = 3494
    # overflows. ROM 0x034-0x038 adds EEPROM[0x28] to that preload.
    return (3494 + setting) * 256 * 4 / FOSC_HZ


def be16(data: bytes, address: int) -> int:
    return data[address] << 8 | data[address + 1]


def verify_rom(words: list[int]) -> None:
    anchors = {
        0x000: 0x2858, 0x004: 0x2805,
        0x05E: 0x1683, 0x060: 0x0081, 0x061: 0x30E4, 0x062: 0x0085,
        0x076: 0x3028, 0x077: 0x2116, 0x078: 0x00BF, 0x079: 0x1D05,
        0x07E: 0x1683, 0x07F: 0x30E8, 0x080: 0x0085,
        0x090: 0x01AC, 0x091: 0x0E1B, 0x0A8: 0x082C,
        0x0AA: 0x2112, 0x0AE: 0x2116, 0x0B1: 0x2116,
        0x0C0: 0x213E, 0x0C1: 0x01AC, 0x0C4: 0x0103,
        0x0D0: 0x2116, 0x0D2: 0x3004, 0x0D4: 0x2340,
        0x0DC: 0x3A04, 0x0E9: 0x3004, 0x0EC: 0x0095, 0x0ED: 0x3058,
        0x0EF: 0x2109, 0x0F1: 0x0A2C, 0x0F2: 0x2116,
        0x103: 0x2112, 0x104: 0x301F, 0x105: 0x0520, 0x107: 0x212E,
        0x109: 0x3031, 0x10B: 0x21C2, 0x10C: 0x21D8, 0x10D: 0x2305,
        0x10E: 0x21DC, 0x10F: 0x21E8, 0x110: 0x2332,
        0x116: 0x1283, 0x117: 0x0089, 0x118: 0x1683, 0x119: 0x1408,
        0x11A: 0x1283, 0x11B: 0x0808,
        0x13E: 0x1683, 0x140: 0x0086, 0x141: 0x1283, 0x142: 0x0906,
        0x148: 0x00A8, 0x151: 0x019E, 0x154: 0x1D05,
        0x15A: 0x1683, 0x15B: 0x30E8, 0x15C: 0x0085,
        0x17B: 0x3028, 0x17C: 0x2116, 0x186: 0x3028, 0x189: 0x211D,
        0x18B: 0x1505, 0x18E: 0x1105,
        0x300: 0x390F, 0x304: 0x0782,
        0x335: 0x081D, 0x337: 0x0782,
        0x340: 0x149A, 0x343: 0x390F, 0x345: 0x0782,
        0x356: 0x0782, 0x367: 0x0782,
    }
    for address, opcode in anchors.items():
        expect(words, address, opcode)
    for index, target in enumerate(S1_TARGETS):
        expect(words, 0x346 + index, 0x2800 | target)


def produce_map(firmware_path: Path) -> str:
    image = read_intel_hex(firmware_path)
    rom = region(image, 0x0000, 0x0800)
    eeprom = region(image, 0x4200, 0x40)
    if sha256(rom) != EXPECTED_ROM_SHA256:
        raise ValueError(f"unexpected ROM SHA-256 {sha256(rom)}")
    if sha256(eeprom) != EXPECTED_EEPROM_SHA256:
        raise ValueError(f"unexpected EEPROM SHA-256 {sha256(eeprom)}")
    words = words_from_raw(rom)
    verify_rom(words)

    lines = [
        "# Generated FoxMox firmware map", "",
        f"- ROM SHA-256: `{sha256(rom)}`",
        f"- EEPROM SHA-256 (logical image order): `{sha256(eeprom)}`",
        f"- Logical EEPROM: `{eeprom.hex()}`", "",
        "## S1 content dispatch", "",
        "| S1 | Content | ROM target |", "|---:|:---|---:|",
    ]
    lines += [f"| {i:X} | {name} | `0x{target:03X}` |" for i, (name, target) in enumerate(zip(S1_NAMES, S1_TARGETS))]
    lines += ["", "## S2 cadence addressing", "", "| S2 | fox address (S1 0-4) | other address (S1 5-F) | special jitter for other modes |", "|---:|---:|---:|:---|"]
    for s2 in range(16):
        lines.append(f"| {s2:X} | `0x{cadence_pair_address(0, s2):02X}` | `0x{cadence_pair_address(5, s2):02X}` | {'yes' if s2 in (0xC, 0xD, 0xE) else 'no'} |")

    lines += ["", "## Logical EEPROM 0x00-0x27 timing records", "", "Nominal timing uses EEPROM[0x28]=0. The recovered value is shown separately below.", "", "| Address | Bytes | BE counter | nominal primary | nominal low-byte follow-up |", "|---:|:---:|---:|---:|---:|"]
    tick0 = counter_tick_seconds(0)
    for address in range(0, 0x28, 2):
        value = be16(eeprom, address)
        low = eeprom[address + 1]
        lines.append(f"| `0x{address:02X}` | `{eeprom[address]:02X} {low:02X}` | {value} | {value*tick0:.3f} s ({value*tick0/60:.3f} min) | {low*tick0:.3f} s |")

    current = eeprom[0x28]
    lines += ["", "## Initial pair selection", "", "| S1 class | S2 | EEPROM pair |", "|:---|:---|---:|"]
    for s1class, s1 in (("0-4", 0), ("5-F", 5)):
        groups: dict[int, list[str]] = {}
        for s2 in range(16):
            groups.setdefault(initial_pair_address(s1, s2), []).append(f"{s2:X}")
        for address, values in groups.items():
            lines.append(f"| {s1class} | {','.join(values)} | `0x{address:02X}` |")

    lines += [
        "", "## Runtime timing trim", "",
        f"- EEPROM `0x28` = `0x{current:02X}` ({current}).",
        f"- Nominal counter tick at setting `0x00`: {tick0:.9f} s.",
        f"- Counter tick at recovered setting `0x{current:02X}`: {counter_tick_seconds(current):.9f} s.",
        "- Verified callsign routine at ROM `0x109-0x110`: `N0PUF`.",
        "- All checked machine-code anchors matched.", "",
    ]
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("firmware", nargs="?", type=Path, default=ROOT / "foxmox-v2.6.hex")
    parser.add_argument("-o", "--output", type=Path)
    args = parser.parse_args()
    text = produce_map(args.firmware)
    if args.output:
        args.output.write_text(text, encoding="utf-8", newline="\n")
    else:
        print(text, end="")


if __name__ == "__main__":
    main()
