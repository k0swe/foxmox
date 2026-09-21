# FoxMox firmware

This directory contains the recovered and hardware-tested firmware for the W0QE
FoxMOX V2.6 controller built around a PIC16F84A.

## Contents

| Path                                     | Purpose                                                                      |
| ---------------------------------------- | ---------------------------------------------------------------------------- |
| `foxmox-v2.6.hex`                        | Complete programming image: ROM, user IDs, configuration word, and EEPROM.   |
| `requirements.txt`                       | Pinned Python package needed to operate a K150 with `picpro`.                |
| `tools/reconstruct_from_picpro_dumps.py` | Rebuild a combined Intel HEX file from fresh binary ROM/EEPROM/config reads. |
| `asm/`                                   | Lossless gpasm reconstruction and exact-memory verifier.                     |
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

## Calibrate the one-second time base

The firmware stores an unsigned clock-trim byte in data EEPROM address `0x28`.
The recovered chip-1 image contains `0xFF`; this is a runtime setting, not the
PIC programmer's unrelated generic `CAL` field.

Every 64th nominal second, the timer ISR adds the trim byte to that one
software-divider interval. Consequently:

- increasing the value makes firmware seconds and all timed phases **longer**;
- decreasing the value makes them **shorter**;
- one count changes the average rate by approximately **4.472 ppm**.

There is no universal target byte: crystal frequency, loading, supply voltage,
and temperature all affect the correct setting. Measure the assembled controller
rather than copying another unit's value.

The firmware's service interface was reconstructed from code. No surviving
factory instruction identifies the original fixture or contact used to ground
RA2. On an unmodified board, use a temporary, controlled connection to RA2 only
if you are comfortable working directly at the PIC; RA2 is PIC pin 1. During the
boot test RA2 is an input pulled high from RA3 through R5 (10 kOhm). **Do not
leave RA2 grounded:** after service entry the firmware changes RA2 to an output.

### Measure the error

Use a stable reference clock and measure complete PTT cycles rather than Morse
element lengths. A convenient setup is S1=`0` through `4` and S2=`6`, whose
normal cycle is 60 seconds transmitting plus 240 seconds silent, or 300 firmware
seconds. Ignore the one-time transmission immediately after power-on and time
from one later PTT assertion to the same edge after several complete cycles.
Twelve cycles give a nominal one-hour observation.

For a one-hour measurement:

```text
trim change ≈ (3600.000 s - measured seconds) / 0.016091 s
```

Round to the nearest whole count:

- a measurement shorter than 3600 seconds means the firmware is fast, so
  **increase** the trim;
- a measurement longer than 3600 seconds means it is slow, so **decrease** the
  trim.

For an arbitrary observation of `N` nominal firmware seconds, the equivalent
calculation is:

```text
trim change ≈ (N - measured seconds) / (N × 4.47195e-6)
```

This is a first-order correction. Re-measure after adjustment, preferably over a
longer interval and at the expected field temperature.

### Enter service mode and change the value

Service mode keys the transmitter and announces values over the radio. Use a
dummy load or an authorized test frequency and identify as required.

1. Power the controller off.
2. Set **S1=`1` and S2=`2`**. This keeps the combined switch value nonzero while
   selecting a no-change S2 position.
3. Hold RA2 low and apply power.
4. Release RA2. The firmware waits for a stable high level, enters service mode,
   keys the transmitter, and sends the current trim as two hexadecimal Morse
   characters.
5. Use S2 to adjust or hold the value:

   | S2 position | Service-mode action |
   |---:|:---|
   | `1`, `3`, `5`, `7` | Increment the trim |
   | `8`–`F` | Decrement the trim |
   | `2`, `4`, `6` | Hold without changing it |
   | `0` | Exit service mode after the five-second service timer |

   S2 positions that change the value repeat the operation while selected. Each
   new value is written immediately to EEPROM `0x28` and announced in
   hexadecimal Morse. Return S2 to `2` after the desired number of steps.
6. Turn S2 to `0` and wait. The firmware announces the stored value again,
   restarts, and enters normal operation using the new trim.
7. Power off, remove any temporary RA2 connection, restore the desired S1/S2
   operating settings, and repeat the timing measurement.

Do not enter service mode with both switches at zero. That combination branches
to the firmware's halt/blink loop instead of the adjustment interface. The trim
arithmetic wraps at `00`/`FF`; there is no saturation check, so count carefully
near either endpoint.

## Build the lossless assembly reconstruction

Install `gputils`, then assemble and compare every programmed memory region:

```sh
sudo apt install gputils
make -C Firmware/asm verify
```

See [`asm/README.md`](asm/README.md) for the exactness boundary and the safe
incremental workflow for replacing numeric words with named gpasm mnemonics.

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
