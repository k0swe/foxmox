# Lossless gpasm reconstruction

`foxmox-v2.6.asm` is an address-stable source representation of the recovered
PIC16F84A image. It preserves every program word, the four user-ID locations,
the configuration word, and all 64 EEPROM bytes.

The preservation source begins with recovered program words expressed as `DW`
and adds labels plus decoded comments. That avoids inventing source-level
structure or changing instruction placement. Proven routines are converted to
ordinary mnemonics incrementally; `make verify` is the gate that must remain
green after every such change.

Mnemonic conversions completed so far:

- reset vector, hardware initialization, and initial message (`0x000`, `0x058–0x08F`)
- startup-delay selection and countdown (`0x090–0x0BF`)
- `wait_for_tmr0_interrupt` (`0x112–0x115`)
- `eeprom_read` (`0x116–0x11C`)
- `eeprom_write` (`0x11D–0x12D`)
- `advance_lfsr_3` (`0x12E–0x133`)
- `advance_lfsr_1` (`0x134–0x13D`)
- `read_switches` (`0x13E–0x147`)
- `send_hex_byte` (`0x148–0x150`)
- calibration/service mode and halt loop (`0x151–0x18F`)
- `morse_tone_unit` / `morse_silence_unit` (`0x190–0x1A1`)
- Morse sequence fragments and complete G–Z emitters (`0x1A2–0x1F7`)
- all sixteen S1 message routines (`0x1F8–0x28A`)
- `send_dot` / `send_dash` / `send_character_space` (`0x1BA–0x1C6`)
- hexadecimal Morse dispatcher and 0–F entries (`0x300–0x334`)
- `bit_mask_lookup` (`0x335–0x33F`)
- `message_dispatch` (`0x340–0x355`)
- `lfsr_seed_lookup` (`0x356–0x366`)
- tone waveform lookup table (`0x367–0x3FF`)

## Toolchain

Install the open-source, MPASM-compatible gputils assembler:

```sh
sudo apt install gputils
```

The verified build used:

```text
gpasm-1.4.0 #1107 (Jan 1 2021)
```

No compiler or linker is involved. The source selects the PIC16F84A and INHX8M
output format itself.

## Build and verify

From this directory:

```sh
make verify
```

Or from the repository root:

```sh
make -C Firmware/asm verify
```

This creates both `build/foxmox-v2.6-gpasm.hex` and a normalized
`build/foxmox-v2.6.hex`. The dependency-free verifier compares the former's
programmed meaning against `../foxmox-v2.6.hex`; the normalized file is then
required to be byte-for-byte identical to the canonical image.

The verifier requires all of these to match:

- all 1,024 program words;
- configuration word `0x3FF1`;
- all 64 EEPROM bytes;
- the implemented low nibbles of all four user-ID words; and
- the complete set of emitted memory regions.

Raw gpasm output is not text-identical because gpasm emits erased user-ID words
as `0x000F`, while picpro preserved erased reads as `0xFFFF`. A PIC16F84A
implements only the low nibble at each user-ID location, so both represent the
same programmed state. `canonicalize_hex.py` restores the readback representation
and canonical record layout; `make verify` proves that result is byte-for-byte
identical to `../foxmox-v2.6.hex`. ROM, configuration, and EEPROM already match
without normalization.

Remove generated files with:

```sh
make clean
```

## Source organization

The source includes labels for routines already established by reverse
engineering, including:

- reset and interrupt vectors;
- EEPROM read/write routines;
- switch sampling;
- the N0PUF identifier;
- Morse primitives and message routines;
- S1 message dispatch; and
- lookup tables.

Comments after each `DW` show the PIC word address and bank-conservative decode
from `../reverse-engineering/pic14_disasm.py`. Those comments are explanatory;
the numeric word is the lossless evidence.

## Safe refinement workflow

1. Replace one `DW` or one small routine with gpasm mnemonics and symbolic names.
2. Run `make verify`.
3. Keep the change only if all programmed-memory checks pass.
4. Preserve uncertain encodings as `DW` rather than guessing.

This lets the reconstruction become progressively more readable without ever
losing the original binary.
