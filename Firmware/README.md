# FoxMox firmware

This directory contains the recovered and hardware-tested firmware for the W0QE
FoxMOX V2.6 controller built around a PIC16F84A.

## Contents

| Path                                     | Purpose                                                                      |
| ---------------------------------------- | ---------------------------------------------------------------------------- |
| `foxmox-v2.6.hex`                        | Complete programming image: ROM, user IDs, configuration word, and EEPROM.   |
| `requirements.txt`                       | Pinned Python package needed to operate a K150 with `picpro`.                |
| `tools/reconstruct_from_picpro_dumps.py` | Rebuild a combined Intel HEX file from fresh binary ROM/EEPROM/config reads. |
| `reverse-engineering/`                   | Reproducible disassembly, firmware map, and detailed behavioral analysis.    |

`foxmox-v2.6.hex` was reconstructed from two original FoxMox PIC16F84A chips.
Each chip was read twice. All four ROM reads and all four configuration reads
matched. The two reads from each chip's EEPROM matched; the committed image uses
the first chip's EEPROM. A newly programmed blank PIC reproduced the correct
behavior in an original FoxMox circuit.

SHA-256:

```text
fd2546d702d7f152492bd81f077fed141b5110a9ec950f8becbee85d6fce2018  foxmox-v2.6.hex
```

The disposable raw binary reads were removed after reconstruction and
verification. Their SHA-256 provenance is retained here:

| Original reads                       | SHA-256                                                            |
| ------------------------------------ | ------------------------------------------------------------------ |
| ROM reads 1–4                        | `546781166e6c349ccbb167d5767dacbf99e84a844c02573d8a7d724120fe6fbd` |
| Config reads 1–4                     | `ef243db2cd17e4bd231702d4772631d3d2b1c6517537b5ffe5ee716e1d2c0511` |
| EEPROM reads 1–2 (chip 1; used here) | `1717c8d193e79f42a47fa1c73697095e1c3cf7151fb5c31dcc71067034cc6e31` |
| EEPROM reads 3–4 (chip 2)            | `ec9046ee89c522c35967271c6c3d923df622bfac4652ae824c0369186abe2a14` |

The two EEPROM images differed only at logical addresses `0x00` and `0x28`.

## K150 placement for the PIC16F84A

On the common 40-pin K150 ZIF socket:

- orient PIC pin 1 toward the **lever end**;
- align PIC pin 1 with **ZIF position 2**, leaving ZIF position 1 empty;
- the 18-pin device therefore occupies ZIF positions 2–10 and 31–39.

An incorrect position returns plausible-looking default data identical to an
empty socket, including a zero device ID. Correct placement returns the expected
PIC16F84A silicon ID `0x0560`.

Disconnect USB before inserting, removing, or repositioning a PIC.

## Re-create the picpro environment

From the repository root:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r Firmware/requirements.txt
```

The tested version is `picpro 0.4.1`. The K150 used here reports firmware
version 3 and the required P18A protocol:

```sh
.venv/bin/picpro programmer_info -p /dev/ttyUSB0
```

Expected:

```text
Firmware version: 3
Protocol version: P18A
```

If access to `/dev/ttyUSB0` is denied, add the user to the distribution's serial
port group (commonly `dialout`) and start a new login session.

## Safely identify and read a chip

Read-only configuration check:

```sh
.venv/bin/picpro read_chip_config -p /dev/ttyUSB0 -t 16f84a
```

A connected PIC16F84A should return `Chip ID: 1376 (0x560)`. The recovered
FoxMox configuration word is `0x3FF1`, decoded as:

```text
WDT = Disabled
PWRTE = Enabled
Oscillator = XT
Code Protect = Disabled
```

Read all three regions as binary files into a scratch directory:

```sh
mkdir -p /tmp/foxmox-read
.venv/bin/picpro dump rom \
  -p /dev/ttyUSB0 -t 16f84a --binary \
  -o /tmp/foxmox-read/rom.bin
.venv/bin/picpro dump eeprom \
  -p /dev/ttyUSB0 -t 16f84a --binary \
  -o /tmp/foxmox-read/eeprom.bin
.venv/bin/picpro dump config \
  -p /dev/ttyUSB0 -t 16f84a --binary \
  -o /tmp/foxmox-read/config.bin
```

Read twice and compare hashes before treating a recovery as trustworthy.

## Reconstruct a combined image from new reads

The K150 protocol returns ROM, EEPROM, and configuration separately. Picpro's
binary dump path also swaps adjacent EEPROM bytes. The reconstruction utility
handles the memory map and byte order:

```sh
.venv/bin/python Firmware/tools/reconstruct_from_picpro_dumps.py \
  --rom /tmp/foxmox-read/rom.bin \
  --eeprom /tmp/foxmox-read/eeprom.bin \
  --config /tmp/foxmox-read/config.bin \
  -o /tmp/foxmox-read/combined.hex
```

The generated PIC16F84A Intel HEX regions are:

| Region             |  Byte addresses |
| ------------------ | --------------: |
| Program ROM        | `0x0000–0x07FF` |
| User-ID words      | `0x4000–0x4007` |
| Configuration word | `0x400E–0x400F` |
| Data EEPROM        | `0x4200–0x423F` |

The silicon ID is read-only and is not placed in the image. The generic K150
`CAL` field is also excluded because the PIC16F84A has no calibration word.

## Program and verify a replacement PIC

**Programming erases and overwrites the chip currently in the socket. Never run
this against one of the originals.** Confirm that a replaceable blank PIC is
installed first.

```sh
.venv/bin/picpro program \
  -p /dev/ttyUSB0 -t 16f84a \
  -i Firmware/foxmox-v2.6.hex

.venv/bin/picpro verify \
  -p /dev/ttyUSB0 -t 16f84a \
  -i Firmware/foxmox-v2.6.hex
```

The strongest practical check is to install the replacement in an original
FoxMox controller and confirm its on-air behavior; that validation has already
succeeded for this committed image.

## Reproduce the reverse engineering

The analysis uses only Python's standard library and reads the committed Intel
HEX image directly:

```sh
python3 Firmware/reverse-engineering/pic14_disasm.py \
  -o Firmware/reverse-engineering/generated-disassembly.txt
python3 Firmware/reverse-engineering/analyze_foxmox.py \
  -o Firmware/reverse-engineering/generated-map.md
python3 -m py_compile Firmware/reverse-engineering/*.py
```

See [`reverse-engineering/README.md`](reverse-engineering/README.md) for the
switch map, timing model, callsign routine, EEPROM interpretation, and R5 boot
strap analysis.
