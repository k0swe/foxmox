# FoxMox V2.6

A KiCad reproduction of Larry Benko **W0QE**'s _Low Power FoxMOX Controller
V2.6_ (December 2004), transcribed by Chris Keller **K0SWE**.

FoxMox is a PIC16F84A-based amateur-radio foxhunt/ARDF beacon controller. It
keys and modulates an Alinco DJ-S11 through the radio's 2.5 mm microphone jack,
is powered by the jack's microphone-bias supply, and uses two hexadecimal rotary
switches for field configuration.

This repository includes the reconstructed hardware, the original scanned
schematic, recovered and hardware-tested firmware, readable assembly source, and
field operating instructions.

## Repository contents

| Path                                                                     | Purpose                                                                                                |
| ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| [`USER-GUIDE.md`](USER-GUIDE.md)                                         | Field switch settings, timing profiles, and staggered five-fox startup.                                |
| [`Hardware/README.md`](Hardware/README.md)                               | Circuit behavior, radio interface, power constraints, R5 service strap, and bench checks.              |
| [`Hardware/W0QE FoxMox scanned.pdf`](<Hardware/W0QE FoxMox scanned.pdf>) | Scan of the original W0QE schematic and source of truth for the hardware transcription.                |
| `Hardware/foxmox.kicad_sch` / `Hardware/foxmox.kicad_pcb`                | Reconstructed KiCad schematic and PCB.                                                                 |
| [`Hardware/foxmox.pdf`](Hardware/foxmox.pdf)                             | Exported reconstructed schematic.                                                                      |
| [`Firmware/README.md`](Firmware/README.md)                               | PIC programming, clock calibration, assembly builds, regression verification, and callsign generation. |
| `Firmware/foxmox-v2.6.hex`                                               | Original recovered, hardware-tested PIC programming image.                                             |
| `Firmware/foxmox-v2.6.asm`                                               | Validated, readable gpasm source that reproduces the recovered image exactly.                          |

## Quick start

- For field setup, begin with [`USER-GUIDE.md`](USER-GUIDE.md).
- For hardware construction or troubleshooting, see
  [`Hardware/README.md`](Hardware/README.md).
- For PIC programming or firmware builds, see
  [`Firmware/README.md`](Firmware/README.md).

The default assembly build identifies as **N0PUF** and is regression-tested
byte-for-byte against the recovered programming image.
