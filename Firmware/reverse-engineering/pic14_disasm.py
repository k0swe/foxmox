#!/usr/bin/env python3
"""Deterministic PIC16F84A (14-bit mid-range) firmware disassembler.

The input is the committed Intel HEX image. Its program region contains 1,024
little-endian 14-bit words. File-register operands retain the encoded 7-bit
address. SFR names are rendered as bank-qualified alternatives unless the
register is mirrored in both banks; this deliberately avoids silently treating
TRIS as PORT or EECON as EEPROM data.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from intelhex_image import read_intel_hex, region

MIRRORED = {0x00: "INDF", 0x02: "PCL", 0x03: "STATUS", 0x04: "FSR", 0x0A: "PCLATH", 0x0B: "INTCON"}
BANK0 = {0x01: "TMR0", 0x05: "PORTA", 0x06: "PORTB", 0x08: "EEDATA", 0x09: "EEADR"}
BANK1 = {0x01: "OPTION_REG", 0x05: "TRISA", 0x06: "TRISB", 0x08: "EECON1", 0x09: "EECON2"}


def reg_name(f: int) -> str:
    if f in MIRRORED:
        return MIRRORED[f]
    if f in BANK0 or f in BANK1:
        return f"{BANK0.get(f, f'0x{f:02X}')}[b0]/{BANK1.get(f, f'0x{f:02X}')}[b1]"
    return f"0x{f:02X}"


def decode(word: int) -> str:
    if word & ~0x3FFF:
        return f"INVALID_OUTSIDE_14_BITS 0x{word:04X}"
    if word == 0x3FFF:
        return "erased (instruction encoding: addlw 0xFF)"
    exact = {
        0x0000: "nop", 0x0008: "return", 0x0009: "retfie",
        0x0062: "option", 0x0063: "sleep", 0x0064: "clrwdt",
        0x0065: "tris 5", 0x0066: "tris 6", 0x0067: "tris 7",
    }
    if word in exact:
        return exact[word]
    if word & 0x3F80 == 0x0080:
        return f"movwf {reg_name(word & 0x7F)}"
    # CLRW ignores the seven low bits on this core; 0x0103 in this image is valid.
    if word & 0x3F80 == 0x0100:
        return "clrw"
    if word & 0x3F80 == 0x0180:
        return f"clrf {reg_name(word & 0x7F)}"
    byte_ops = {
        0x0200: "subwf", 0x0300: "decf", 0x0400: "iorwf", 0x0500: "andwf",
        0x0600: "xorwf", 0x0700: "addwf", 0x0800: "movf", 0x0900: "comf",
        0x0A00: "incf", 0x0B00: "decfsz", 0x0C00: "rrf", 0x0D00: "rlf",
        0x0E00: "swapf", 0x0F00: "incfsz",
    }
    base = word & 0x3F00
    if base in byte_ops:
        return f"{byte_ops[base]} {reg_name(word & 0x7F)},{'F' if word & 0x80 else 'W'}"
    for opbase, mnemonic in ((0x1000, "bcf"), (0x1400, "bsf"), (0x1800, "btfsc"), (0x1C00, "btfss")):
        if word & 0x3C00 == opbase:
            return f"{mnemonic} {reg_name(word & 0x7F)},{(word >> 7) & 7}"
    if word & 0x3800 == 0x2000:
        return f"call 0x{word & 0x07FF:03X}"
    if word & 0x3800 == 0x2800:
        return f"goto 0x{word & 0x07FF:03X}"
    literals = (
        (0x3000, 0x3C00, "movlw"), (0x3400, 0x3C00, "retlw"),
        (0x3800, 0x3F00, "iorlw"), (0x3900, 0x3F00, "andlw"),
        (0x3A00, 0x3F00, "xorlw"), (0x3C00, 0x3E00, "sublw"),
        (0x3E00, 0x3E00, "addlw"),
    )
    for opbase, mask, mnemonic in literals:
        if word & mask == opbase:
            return f"{mnemonic} 0x{word & 0xFF:02X}"
    return f"INVALID_OR_RESERVED 0x{word:04X}"


def words_from_image(path: Path) -> list[int]:
    data = region(read_intel_hex(path), 0x0000, 0x0800)
    words = [data[i] | (data[i + 1] << 8) for i in range(0, len(data), 2)]
    bad = [(i, w) for i, w in enumerate(words) if w & ~0x3FFF]
    if bad:
        raise ValueError(f"{path}: {len(bad)} words exceed 14 bits; first is {bad[0]}")
    return words


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "firmware",
        nargs="?",
        type=Path,
        default=Path(__file__).resolve().parent.parent / "foxmox-v2.6.hex",
    )
    parser.add_argument("-o", "--output", type=Path)
    args = parser.parse_args()
    lines = [f"{pc:04X}: {word:04X}  {decode(word)}" for pc, word in enumerate(words_from_image(args.firmware))]
    text = "\n".join(lines) + "\n"
    if args.output:
        args.output.write_text(text, encoding="utf-8", newline="\n")
    else:
        print(text, end="")


if __name__ == "__main__":
    main()
