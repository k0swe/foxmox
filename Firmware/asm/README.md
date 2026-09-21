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

- `wait_for_tmr0_interrupt` (`0x112–0x115`)
- `eeprom_read` (`0x116–0x11C`)

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
