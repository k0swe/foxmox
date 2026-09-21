# AGENTS.md — FoxMox

Notes for anyone (human or agent) working on this repo. Records findings that
cost real effort to establish and are **not** self-evident from the files.

## What this is

A KiCad reproduction of Larry Benko **W0QE**'s _Low Power FoxMOX Controller
V.2.6_ (Dec 2004), a non-programmable amateur radio foxhunt/ARDF beacon
controller. Transcribed by Chris Keller, **K0SWE**.

| File                                                      | Role                                       |
| --------------------------------------------------------- | ------------------------------------------ |
| `Hardware/W0QE FoxMox scanned.pdf`                        | **Source of truth.** Scan of the original. |
| `Hardware/foxmox.kicad_sch` / `Hardware/foxmox.kicad_pcb` | The reproduction.                          |
| `Hardware/foxmox.pdf`                                     | KiCad PDF export of the schematic.         |
| `Firmware/foxmox-v2.6.hex`                                | Recovered, hardware-tested PIC image.      |
| `Firmware/reverse-engineering/`                           | Reproducible firmware analysis.            |

Behavior is set entirely by the two hex switches (S1, S2). Program the PIC with
**version 2.6** from `Firmware/foxmox-v2.6.hex`; setup, recovery, and
verification commands are documented in `Firmware/README.md`.

Target radio in this build: **Alinco DJ-S11**, via the 2.5mm mic jack.

## How it keys the radio — there is no PTT pin

The single most confusing thing about this design, and the first question anyone
asks. The mic jack has only ground, a bias rail, and audio — no dedicated PTT
line, and the DJ-S11 has no VOX setting.

**The mic tip is simultaneously the audio input and the PTT line.** The radio
holds that pin at a DC bias (it expects to power an electret element) and
watches its DC level. Pull it toward ground through a resistor and the radio
transmits; release it and the radio reverts to receive. Audio rides on top as AC
through a coupling cap. One wire, two jobs.

This is standard across Alinco, Icom and Yaesu handhelds. (Kenwood is the
exception — it has a real separate PTT on the sleeve.) Alinco's VOX-capable
accessory headsets work by performing this same resistive pull-down; the VOX
lives in the headset, not in the radio. That is why the radio has no VOX menu.

### The two paths, as built

Verified against the resolved netlist in `Hardware/foxmox.kicad_pcb`:

**Audio — PIC RA0 (pin 17):**

```
RA0 ── R1 20k ── R2 5k pot ──(wiper)── C4 1µF ── P1 tip
                      └── bottom ── GND
```

RA0 emits a square-wave tone. R1+R2 form a ~25k divider; **C4 blocks DC** so
only AC reaches the tip and the keying level is undisturbed.

W0QE's annotation — _"Adjust for 20 to 40mV peak to peak. Or set R2 for ~300
ohms from wiper to ground"_ — is self-consistent: `3.0V x 300/25000 ~= 36mV`.
Don't run it hotter; square-wave drive is already harmonic-rich.

**PTT — PIC RA1 (pin 18):**

```
RA1 ── R3 20k ── Q1 base (2N2222A, emitter -> GND)
                 Q1 collector ── R4 2.7k ── P1 tip
```

RA1 high saturates Q1, pulling the tip to ground through **R4 = 2.7k**. That
2.7k **is** the keying resistor. RA1 low -> Q1 off -> tip floats back to the
radio's bias -> receive.

Both paths sum on the tip (`Net-(C4-Pad2)` = `C4.2, P1.T, R4.2`).

## Power budget — the binding constraint

**The controller is parasitically powered from the radio's mic bias rail.**
There is no battery.

```
P1 ring ── S3 (SPDT power switch) ── VDD ── U1.14, U1.4 (MCLR), C3, D1, TP1
P1 sleeve ── GND
```

W0QE's measured figures, from the scan:

> Measured current draw @ 3.0V from Ring to Sleeve = **.5mA idle, .9mA
> transmitting**

Treat this as a hard design constraint, not trivia. It explains every other
choice on the board: the PIC16F84 at 3.579 MHz, the resistively-attenuated
square wave instead of a DAC or PWM stage, and the general absence of anything
power-hungry.

**D1 (6.2V zener) is overvoltage protection on that rail, not regulation** — it
sits well above the ~3V operating point.

> **Before substituting a modern MCU**, check its idle current against that
> sub-milliamp budget. Many will brown out or drag the bias rail down far enough
> to false-key.

## R5 — resolved, do not "fix" it

`R5` (10k) is strapped between **RA2 (pin 1) and RA3 (pin 2)**. `RA4/TOCKI`
(pin 3) is **unconnected**, with an explicit `no_connect` at `(97.79 105.41)` in
`Hardware/foxmox.kicad_sch` — which computes to exactly U1 pin 3 given U1's
placement at `(80.01, 110.49)`. The PCB agrees:
`unconnected-(U1-TOCKI{slash}RA4-Pad3)`.

**This has been investigated and the transcription is correct.** It was
previously suspected to be a transcription error, on the reasoning that RA4 is
open-drain and therefore _wants_ a pull-up, whereas 10k between two ordinary
bidirectional pins does nothing obvious. That reasoning is sound but the premise
was wrong.

Two traps caused the false alarm:

1. **Label placement.** The text `R5 10k` is set _below_ its own zigzag, so the
   label lands on the RA4 row while the symbol body sits one row up on RA3. At
   low zoom it reads as "R5 is on RA4." Note that `R1` and `R3` have their
   labels set _above_ their symbols — label placement in this drawing is
   inconsistent and is **not** reliable evidence. Trace the zigzag body.
2. **The X mark on the RA4 row is a printed no-connect flag, not a crossed-out
   wire.** The RA4 pin stub is short and _ends_ where the X begins — there is no
   wire beneath it to cross out. Ink-darkness measurement confirms it is part of
   the original printed drawing, not a later pencil edit:

   | Ink                             | Mean gray |
   | ------------------------------- | --------- |
   | Printed wire                    | 73        |
   | The X                           | 81        |
   | Printed text                    | 89        |
   | Pencil handwriting (top margin) | 140       |

The recovered V2.6 firmware settles its purpose: **R5 is a boot/service-mode
strap.** At reset RA3 is driven high while RA2 is an input, so R5 pulls RA2 high
for normal operation. Holding RA2 low at boot enters the calibration path; that
path waits for RA2 to return high before continuing. Moving R5 to RA4 would
break the boot test. Exact instruction addresses and bank-state proof are in
`Firmware/reverse-engineering/README.md`.

## Verifying schematic claims

The scan is lossy and geometry is easy to misread. Two techniques that worked:

- **Get connectivity from `Hardware/foxmox.kicad_pcb`, not by tracing wires.**
  The PCB file carries resolved net names per pad. Parse footprint blocks for
  `(property "Reference" ...)` and each `(pad ... (net "..."))` to build a full
  pad-to-net map in one pass. Far more reliable than following wire segments in
  `.kicad_sch`.
- **`kicad-cli` is not installed on this machine**, so netlist export is
  unavailable. Parse the files directly.
- For the scan, render high-DPI and inspect regions:
  `pdftoppm -r 300 -png "Hardware/W0QE FoxMox scanned.pdf" out`

## Bench checks against a real DJ-S11

Assumptions worth confirming on hardware before trusting a rebuild:

1. **Ring-to-sleeve rail:** confirm ~3V and that it sources >=1mA without
   sagging. The entire design rests on this.
2. **Keying at 2.7k:** confirm reliable keying with a **fresh battery and a
   nearly-dead one**. The bias rail moves with battery voltage, and this is the
   failure mode that strands a fox mid-hunt.
3. **Deviation:** set R2 to ~300 ohms wiper-to-ground, then verify on a service
   monitor or a trusted receiver.

## Repo conventions

- `Hardware/.history/` is KiCad's local snapshot directory and is
  **gitignored**. Don't commit it or mine it as history.
- `Hardware/Datasheets/` holds vendor PDFs for chosen parts (PIC16F84A, Raltron
  crystals, Same Sky rotary switches).
- `Hardware/Libraries/` holds footprints/symbols for parts not in stock KiCad
  libs.
- The working tree is often dirty with in-progress footprint/PCB work. **Check
  `git status` before committing and stage only your own files.**
