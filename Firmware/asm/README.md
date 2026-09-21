# Lossless gpasm reconstruction

`foxmox-v2.6.asm` is an address-stable source representation of the recovered
PIC16F84A image. It preserves every program word, the four user-ID locations,
the configuration word, and all 64 EEPROM bytes.

The preservation source began with every recovered program word expressed as
`DW`, then converted proved code to ordinary mnemonics under the `make verify`
gate. **All executable words are now mnemonic assembly.** The only remaining
`DW` directives intentionally emit erased `0x3FFF` words: reset-vector padding
at `0x001–0x003` and unused program space at `0x28B–0x2FF`.

Converted regions include:

- reset and interrupt vectors, timer ISR, and waveform service (`0x000–0x057`)
- hardware initialization and initial message (`0x058–0x08F`)
- startup-delay selection and countdown (`0x090–0x0BF`)
- transmit/silent phase loop and N0PUF insertion (`0x0C0–0x111`)
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

### Build-time callsign

The identification callsign defaults to the recovered value, `N0PUF`. Build a
custom alphanumeric callsign with:

```sh
make image CALLSIGN=K0SWE BUILD_DIR=build/K0SWE
```

The resulting programming image is
`build/K0SWE/foxmox-v2.6.hex`. `emit_callsign.py` validates and normalizes the
value, emits one `CALL send_morse_*` instruction per character, and adjusts the
erased padding before the page-3 tables. Consequently callsigns shorter or
longer than five characters do not move `hex_digit_dispatch` from `0x300` or
`tone_pattern_lookup` from `0x367`.

Supported characters are `A-Z` and `0-9`; punctuation such as `/` is rejected.
The available erased program space permits 1–122 characters, although normal
amateur callsigns are much shorter. `make verify` is intentionally restricted
to the default `N0PUF`, because only that build can be byte-identical to the
recovered image. Use a separate `BUILD_DIR` for each customized image.

Run the emitter unit tests independently with:

```sh
make test
```

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
- the build-time generated callsign identifier (default `N0PUF`);
- Morse primitives and message routines;
- S1 message dispatch; and
- lookup tables.

The remaining `DW 0x3FFF` words represent erased program space. Three are
explicit reset-vector padding; the generated callsign include emits the rest so
custom callsign lengths cannot move the computed tables.

## Safe refinement workflow

1. Make one bounded source change.
2. Run `make verify` for the default recovered image.
3. Keep the change only if all programmed-memory checks pass.
4. For callsign customization, run `make image CALLSIGN=...` and retain the
   generated HEX with its chosen callsign and hash.

This workflow keeps the recovered image reproducible while allowing deliberate
custom builds.
