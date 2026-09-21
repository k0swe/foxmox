# FoxMox V2.6 PIC16F84A firmware reverse engineering

This directory is a reproducible analysis of the recovered W0QE FoxMOX V2.6
firmware. It does **not** modify or reinterpret the original dumps.

## Results at a glance

- **[PROVED]** `../foxmox-v2.6.hex` contains 1,024 little-endian PIC14 program
  words (2,048 bytes). The extracted ROM SHA-256 is
  `546781166e6c349ccbb167d5767dacbf99e84a844c02573d8a7d724120fe6fbd`.
- **[PROVED]** The same image contains 64 logical EEPROM bytes at Intel HEX
  addresses `0x4200..0x423F`. Their SHA-256 is
  `3ecd61956a537acd8086bfbe1c5345dce7cae8af925cf8473f01e992a6cb9bab`.
  The discarded picpro binary source required swapping each adjacent pair to
  reach this logical address order.
- **[PROVED]** RB0..RB3 select the 16 messages in the observed order:
  `MOE, MOI, MOS, MOH, MO5, MO, A, B, F, L, N, P, V, X, Z, FOX`.
  S1=`8` was initially logged by ear as C, but its routine calls the proved
  hexadecimal-F emitter (`0x332`: `..-.`).
- **[PROVED]** RB4..RB7 select timing, but the low three S2 bits select one of
  eight EEPROM records. Thus S2 `8..F` aliases `0..7` for the basic cadence.
- **[PROVED]** The firmware's embedded identification is **N0PUF**, not W0QE or
  K0SWE.
- **[PROVED]** EEPROM `0x28` is a persistent one-second-base calibration value,
  not a message or ordinary delay table byte. The recovered chip-1 value is
  erased `0xFF`.
- **[PROVED]** R5 is active in the firmware design: RA3 is driven high while
  RA2 is an input during the boot-mode test, so the 10 kOhm RA3-to-RA2 resistor
  pulls RA2 high. Pulling RA2 low at boot enters the calibration/settings path.
- **[PROVED]** The recovered image does not coordinate foxes or derive phase
  from S1. In the documented field procedure, S1=`0..4` selects the five fox
  identities, a common S2 selects their shared timing profile, and deliberately
  staggered power-up supplies the phase offset. There is no receiver/listening
  logic. The recovered EEPROM values imply long timing intervals (roughly 52 to
  260 minutes at calibration zero), whose exact operational interpretation
  remains to be reconciled with field timing.

## Reproduction

From the repository root:

```sh
python3 Firmware/reverse-engineering/pic14_disasm.py \
  -o Firmware/reverse-engineering/generated-disassembly.txt
python3 Firmware/reverse-engineering/analyze_foxmox.py \
  -o Firmware/reverse-engineering/generated-map.md
python3 -m py_compile Firmware/reverse-engineering/*.py
```

Both scripts use only the Python standard library. `analyze_foxmox.py` checks
input hashes, lengths, 14-bit word validity, the complete S1 jump table, and all
machine-code anchors used below. It fails instead of silently analyzing a
changed dump.

## Confidence labels

- **PROVED:** direct machine-code/data-flow evidence, with addresses given.
- **HIGH CONFIDENCE:** direct evidence plus a timing or hardware interpretation
  with no plausible competing interpretation found.
- **INFERRED:** consistent interpretation whose external electrical or human
  intent is not represented in the binary.
- **UNKNOWN:** the binary is insufficient; no guess is substituted.

Addresses written as `ROM 0xNNN` are PIC **word** addresses. EEPROM addresses
are byte addresses.

## Correct PIC16F84A bank semantics

The critical setup sequence is:

| ROM | Instruction | Effective register |
|---:|:---|:---|
| `0x058` | `CLRF 0x0B` | `INTCON` (mirrored) |
| `0x059` | `BCF STATUS,RP0` | select bank 0 |
| `0x05A-0x05D` | write `0x08` to `0x05`, `0x00` to `0x06` | `PORTA`, `PORTB` latches |
| `0x05E` | `BSF STATUS,RP0` | select bank 1 |
| `0x05F-0x060` | write `0x08` to `0x01` | `OPTION_REG`, **not TMR0** |
| `0x061-0x062` | write `0xE4` to `0x05` | `TRISA`, **not PORTA** |
| `0x063-0x064` | write `0x00` to `0x06` | `TRISB`, **not PORTB** |
| `0x065` | `BCF STATUS,RP0` | return to bank 0 |

`OPTION_REG=0x08` means TMR0 uses the internal instruction clock and the
prescaler is assigned to the watchdog, so TMR0 itself is unprescaled. The
script's disassembly deliberately prints bank-0/bank-1 alternatives for
non-mirrored SFR operands. It does not pretend that a raw file address alone
resolves the bank.

The EEPROM read at `0x116-0x11C` is also bank-correct: W is written to bank-0
`EEADR` at `0x117`; RP0 is set; `EECON1.RD` is set at `0x119`; RP0 is cleared;
and bank-0 `EEDATA` is read at `0x11B`. The write sequence at `0x11D-0x12D`
uses bank-1 `EECON1/EECON2`, including `0x55,0xAA`, and restores bank 0.

The word `0x0103` at ROM `0x0C4` is a valid `CLRW`: on this core the low seven
bits are don't-care for that encoding. It is not an invalid `CLRF STATUS`.

## Switch sampling and polarity

**[PROVED]** `read_switches` is ROM `0x13E-0x147`:

1. RP0 is set and `0xFF` is written to file `0x06` (`TRISB`) at `0x13E-0x140`.
2. RP0 is cleared and `COMF PORTB,W` samples and inverts all eight pins at
   `0x141-0x142`.
3. The result is saved in RAM `0x1B` at `0x143`.
4. `TRISB` is restored to outputs (`0x00`) at `0x144-0x146`.

Therefore the internal byte is `(S2 << 4) | S1` after active-low inversion:
RB0..RB3 are S1 and RB4..RB7 are S2. This exactly accounts for the observed
front-panel numbering.

## Exact S1 mapping

At ROM `0x340-0x355`, the firmware masks RAM `0x1B` with `0x0F`, adds it to
PCL, and selects one of 16 absolute branches. The target routines and decoded
Morse are:

| S1 | ROM target | Message | Confidence |
|---:|---:|:---|:---|
| `0` | `0x1F8` | MOE | PROVED |
| `1` | `0x201` | MOI | PROVED |
| `2` | `0x20A` | MOS | PROVED |
| `3` | `0x213` | MOH | PROVED |
| `4` | `0x21C` | MO5 | PROVED |
| `5` | `0x225` | MO | PROVED |
| `6` | `0x22D` | A | PROVED |
| `7` | `0x238` | B | PROVED |
| `8` | `0x241` | F | PROVED |
| `9` | `0x24A` | L | PROVED |
| `A` | `0x253` | N | PROVED |
| `B` | `0x25E` | P | PROVED |
| `C` | `0x267` | V | PROVED |
| `D` | `0x270` | X | PROVED |
| `E` | `0x279` | Z | PROVED |
| `F` | `0x282` | FOX | PROVED |

The Morse primitives are at `0x190-0x1C6`; letter composition is at
`0x1C7-0x1F7`; hexadecimal digit composition is at `0x300-0x334`. For example,
S1=`F` calls F (`0x332`), O (`0x1DA`), and X (`0x1EF`) at
`0x286-0x289`. This is machine-code confirmation, independent of listening.

## Exact S2 mapping and EEPROM timing table

The normal cadence selector is ROM `0x0C1-0x0D0`. It computes:

```text
address = (0x10 if S1 >= 5 else 0x00) + 2 * (S2 & 7)
```

It reads the selected EEPROM byte into the low counter byte at `0x0D0-0x0D1`.
The initial pass had already read a two-byte big-endian counter at
`0x0AA-0x0B2`. The counter decrement at interrupt ROM `0x014-0x022` proves RAM
`0x13:0x14` is a big-endian 16-bit down-counter.

Consequently S2 has these exact base-record aliases:

| S2 | S1 `0..4` record | S1 `5..F` record |
|---:|---:|---:|
| `0`, `8` | `0x00` | `0x10` |
| `1`, `9` | `0x02` | `0x12` |
| `2`, `A` | `0x04` | `0x14` |
| `3`, `B` | `0x06` | `0x16` |
| `4`, `C` | `0x08` | `0x18` |
| `5`, `D` | `0x0A` | `0x1A` |
| `6`, `E` | `0x0C` | `0x1C` |
| `7`, `F` | `0x0E` | `0x1E` |

**[PROVED]** S2=`C,D,E` has one additional distinction for S1=`5..F`.
The tests at `0x0F9-0x103` select exactly these three values. The firmware then
adds either 0 or 32 ticks to RAM `0x14`, selected from bit 5 of the evolving
per-message state byte at RAM `0x20`, and advances that state three LFSR steps
at `0x104-0x108`. Thus `C,D,E` are randomized/jittered versions of the same
base records as `4,5,6`; `8..B` and `F` have no such extra step.

### Logical EEPROM bytes 0x00-0x27

Adjacent-byte unswapping gives:

```text
00: 14 28  14 64  18 60  24 90  28 50  30 C0  3C F0  3C F0
10: 0C 18  14 14  14 28  14 64  0C 24  10 30  10 40  3C 00
20: 00 00  07 08  0E 10  1C 20
```

The complete generated table, including decimal counters and timing, is in
[`generated-map.md`](generated-map.md). EEPROM `0x00-0x1F` contains the normal
cadence records. EEPROM `0x20-0x27` contains four startup-delay records selected
at ROM `0x090-0x0AC`: 0, 1800, 3600, and 7200 nominal one-second ticks.

## Time base, initial offset, and cadence

### One-second counter tick

TMR0 overflows every `256 * 4 / 3,579,545 = 286.070 us`. At ROM
`0x00C-0x013`, the nested `0x0E:0x0F` software divider is reloaded to
`0x0E:A6`. Its decrement path reaches the event after
`13*256 + 0xA6 = 3494` overflows, nominally **0.999528152 s** before normal
interrupt-execution phase error. This is strong evidence that it is intended
as a one-second tick.

At each tick, ROM `0x014-0x022` decrements `0x13:0x14`; ROM `0x023-0x02E`
similarly decrements cooldown `0x15:0x16`; and ROM `0x02F-0x033` increments a
six-bit seconds/divider byte.

### Initial record selection

ROM `0x090-0x0A9` selects an offset of 0, 2, 4, or 6. Crucially, ROM
`0x0AB-0x0AC` then adds `0x20`, selecting the dedicated startup-delay records:

| S1 class | S2 values | EEPROM pair | Nominal delay |
|:---|:---|---:|---:|
| `0..4` | `0..6` | `0x20` (`00 00`) | 0 min |
| `0..4` | `7,8` | `0x22` (`07 08`) | 30 min |
| `0..4` | `9..E` | `0x24` (`0E 10`) | 60 min |
| `0..4` | `F` | `0x26` (`1C 20`) | 120 min |
| `5..F` | `0..7` | `0x20` (`00 00`) | 0 min |
| `5..F` | `8..F` | `0x24` (`0E 10`) | 60 min |

This is the firmware's simple startup-delay mechanism. Units remain independent;
manually staggered power-up provides any finer phase offset used in the field.
The non-linear selection is reproduced by `initial_pair_address()` in the
analyzer rather than simplified from an assumed product description.

### Repeating messages

**[PROVED]** ROM `0x0D2-0x0E2` loads RAM `0x12` with 4, sends the selected S1
message through the dispatch at `0x340`, and waits on the interrupt tick at
`0x112-0x115`. RAM `0x12` is decremented once per counter tick, so message
starts repeat at approximately four-second intervals while the main 16-bit
counter is nonzero. Morse generation itself continues under interrupt control,
so this is cadence, not a claim that every message has exactly four seconds of
silence after it.

When the 16-bit phase reaches zero, ROM `0x0F1-0x0F6` reloads only its low byte
from the second byte of the selected EEPROM pair and waits again. Thus each
record contributes:

1. a primary interval equal to the big-endian 16-bit value, and
2. a follow-up interval equal to the record's low byte.

With setting `0x00`, recovered primary intervals range from about 51.6 to 259.9
minutes. With recovered setting `0xFF`, every tick is about 7.3% longer. These
large values follow directly from the bytes and code; whether they were the
intended field programming is **UNKNOWN**.

## Callsign insertion

**[PROVED]** ROM `0x109-0x110` sets a faster Morse element constant (`0x31`)
and emits:

```text
N  0  P  U  F
```

The calls target N at `0x1D8`, hexadecimal digit 0 through entry `0x305`, P at
`0x1DC`, U at `0x1E8`, and F at `0x332`. The resulting callsign is **N0PUF**.

ROM `0x0D9-0x0EF` calls it when the main high byte is zero, the low byte equals
4, and cooldown `0x15:0x16` is zero. It then reloads the cooldown to `0x0258`
(600 one-second ticks). Therefore the ID is inserted near the end of a phase
and no more frequently than roughly ten minutes. Exact audible placement can
shift by the duration of in-progress Morse output; this qualification is
**HIGH CONFIDENCE**, not a cycle-accurate simulator claim.

## EEPROM 0x28 runtime setting

At reset, ROM `0x076-0x078` reads EEPROM `0x28` into RAM `0x3F`.
At each nominal one-second event, ROM `0x034-0x038` adds it to the
`0x0E:0x0F` software-divider preload. The effective number of TMR0 overflows is
`3494 + EEPROM[0x28]`, continuously across the low-byte carry. Therefore:

- `0x00` gives about `0.999528152 s` per counter tick.
- recovered `0xFF` gives about `1.072475971 s` per counter tick.

The service path displays this byte as two hexadecimal Morse digits through ROM
`0x148-0x150`. S2 high-nibble bit tests at `0x17F-0x185` decrement it for
S2=`8..F`, increment it for odd S2 values `1,3,5,7`, and ignore even nonzero
values `2,4,6`; ROM `0x186-0x189` writes the result back to EEPROM `0x28`.
The UI intent of every S2 position in this service mode is **INFERRED** from the
bit tests, but the arithmetic and EEPROM destination are proved.

## Five-fox round robin: simple timers with manual phasing

The field procedure is now confirmed: there was no intelligent coordination or
receiver/listening behavior. Five independent controllers were configured and
powered up at deliberately staggered times.

The firmware matches that architecture:

1. S1=`0..4` changes only the transmitted identity at `0x340-0x34A`:
   MOE/MOI/MOS/MOH/MO5.
2. For a fixed S2, all five identities select the same cadence pair via
   `0x0C1-0x0D0`.
3. For a fixed S2, all five select the same initial pair via `0x090-0x0A8`.
4. No code samples receive audio or waits for another fox; each unit is an
   independent timer.

Therefore S2 selects a common timing profile while **power-up time establishes
phase**. Powering all five simultaneously with the same S2 would make them
broadly synchronous. Powering them sequentially at the desired slot spacing
creates the round robin, and their crystal-derived clocks preserve that spacing
subject to oscillator drift.

The remaining discrepancy is narrower: the recovered EEPROM counters evaluate
to tens or hundreds of minutes using the proved nominal one-second tick, rather
than an obvious one-minute/five-minute ARDF table. This may reflect the intended
FoxMox event format, a less-obvious phase structure in the main loop, or EEPROM
programming for this particular fleet. It does **not** imply coordination between
units; that question is settled by both firmware and field practice.

## R5 between RA2 and RA3

This is the firmware evidence the schematic note was missing.

1. Bank 0 writes PORTA latch `0x08` at ROM `0x05A-0x05B`: RA3 latch high,
   RA2 latch low.
2. Bank 1 writes `TRISA=0xE4` at `0x05E-0x062`. Only the implemented low five
   bits matter: RA2 is input; RA3 is output.
3. Bank 0 tests `PORTA,2` at `0x079`. With R5 between RA3 and RA2, driven-high
   RA3 pulls the RA2 input high through 10 kOhm. High enters normal operation;
   externally holding RA2 low branches to `0x151`.
4. The service path waits for RA2 to go high at `0x154-0x159`, consistent with
   release of a temporary ground/service contact.
5. Normal and service continuation write `TRISA=0xE8` at `0x07E-0x080` and
   `0x15A-0x15C`: RA2 becomes an output and RA3 an input. The only subsequent
   PORTA accesses are RA2 set/clear at `0x18B/0x18E` in the zero-switch halt
   loop; there is no firmware read of RA3.

**Conclusion [PROVED]:** R5 is a firmware-used, current-limited boot/service
strap from a driven-high RA3 to sensed RA2. It is not an RA4 pull-up and moving
it to RA4 would break the boot test. **UNKNOWN:** the original user's physical
method for grounding RA2, and whether the final RA2 toggling loop was intended
for factory probing, are not recoverable from firmware alone.

## Ambiguities and boundaries

- Erased words `0x3FFF` share the arithmetic encoding `ADDLW 0xFF`; the
  disassembler marks them as erased and notes that encoding rather than
  treating blank program space as reachable code.
- Computed `ADDWF PCL` tables are decoded only where their index bounds are
  proved by masks or callers. No speculative control-flow edges are added.
- EEPROM `0x20-0x27` is the proved startup-delay table; ROM `0x0AB-0x0B2`
  loads its selected big-endian counter.
- The timing calculation assumes the documented 3.579545 MHz crystal and normal
  PIC16F84A instruction timing. It does not model analog oscillator tolerance or
  every interrupt-entry instruction cycle.
- The report describes recovered chip 1. Other EEPROM dumps in the repository
  are not silently merged into it.
