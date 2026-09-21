# FoxMox hardware

This directory contains the complete hardware design and its source references
for Larry Benko **W0QE**'s _Low Power FoxMOX Controller V2.6_ (December 2004),
transcribed by Chris Keller **K0SWE**.

| Path                            | Purpose                                                                           |
| ------------------------------- | --------------------------------------------------------------------------------- |
| `foxmox.kicad_pro`              | KiCad project entry point.                                                        |
| `foxmox.kicad_sch`              | Reconstructed schematic.                                                          |
| `foxmox.kicad_pcb`              | PCB layout.                                                                       |
| `foxmox.pdf`                    | PDF export of the reconstructed schematic.                                        |
| `W0QE FoxMox scanned.pdf`       | Scan of Larry Benko W0QE's original schematic; source of truth for transcription. |
| `fp-lib-table`, `sym-lib-table` | Project-local KiCad library tables.                                               |
| `Libraries/`                    | Project-local symbols, footprints, and 3D models.                                 |
| `Datasheets/`                   | Component datasheets.                                                             |

Open `foxmox.kicad_pro` from this directory. Library references use
`${KIPRJMOD}/Libraries/...`, so moving the project and `Libraries/` together
preserves their relative paths.

The target radio in this build is the **Alinco DJ-S11**, connected through its
2.5 mm microphone jack.

## How the controller keys the radio

The DJ-S11 microphone jack has ground, a bias rail, and audio, but no separate
PTT contact. The microphone tip serves as both the audio input and PTT sense.
The radio biases that contact to power an electret microphone and watches its DC
level: pulling it toward ground through a resistor keys the transmitter;
releasing it returns the radio to receive. Transmit audio is AC-coupled onto the
same contact.

This resistive keying arrangement is common on Alinco, Icom, and Yaesu handheld
microphone interfaces. It does not depend on a VOX setting in the radio; VOX
accessories for these radios implement their own resistive pull-down. Kenwood
accessory wiring is a notable exception because it commonly provides a separate
PTT contact.

### Audio path — PIC RA0, pin 17

```text
RA0 ── R1 20k ── R2 5k pot ──(wiper)── C4 1 µF ── P1 tip
                      └── bottom ── GND
```

RA0 generates the square-wave tone. R1 and R2 attenuate it, while C4 blocks DC
so the tone does not disturb the keying level.

W0QE annotated the original drawing:

> Adjust for 20 to 40 mV peak to peak. Or set R2 for ~300 ohms from wiper to
> ground.

That setting is internally consistent: `3.0 V × 300 / 25000 ≈ 36 mV`. Avoid
excessive drive; the source waveform is already square and harmonic-rich.

### PTT path — PIC RA1, pin 18

```text
RA1 ── R3 20k ── Q1 base (2N2222A, emitter → GND)
                 Q1 collector ── R4 2.7k ── P1 tip
```

RA1 high saturates Q1 and pulls the microphone tip toward ground through R4.
**R4, 2.7 kΩ, is the radio's keying resistor.** RA1 low turns Q1 off and allows
the microphone contact to return to its bias voltage.

Both paths meet at the microphone tip. In the PCB netlist, `Net-(C4-Pad2)`
contains `C4.2`, `P1.T`, and `R4.2`.

## Power source and current budget

The controller has no battery of its own. It is parasitically powered by the
radio's microphone-bias rail:

```text
P1 ring ── S3 (SPDT power switch) ── VDD ── U1.14, U1.4 (MCLR), C3, D1, TP1
P1 sleeve ── GND
```

W0QE recorded:

> Measured current draw @ 3.0 V from Ring to Sleeve = **0.5 mA idle, 0.9 mA
> transmitting**

This sub-milliamp supply is a binding design constraint. It explains the
PIC16F84, resistively attenuated square-wave audio, and absence of more
power-hungry circuitry. Before substituting another MCU, verify that its
complete idle and transmit current does not collapse the microphone-bias rail or
false-key the radio.

D1 is a 6.2 V zener used for overvoltage protection. It is not regulating the
normal approximately 3 V supply.

## R5 is the boot/service-mode strap

R5, 10 kΩ, is intentionally connected between **RA2 (PIC pin 1)** and
**RA3 (PIC pin 2)**. **RA4/T0CKI (PIC pin 3) is unconnected. Do not move R5 to
RA4.**

The original scan is easy to misread:

1. The `R5 10k` text is printed below its resistor body, placing the label near
   the RA4 row even though the component itself connects RA2 to RA3. Component
   label placement in this drawing is not a reliable indication of connectivity.
2. The X on the RA4 row is a printed no-connect mark. The pin stub ends at that
   mark; it is not a wire crossed out by hand. Pixel measurements support that
   reading: its darkness matches printed material rather than the lighter pencil
   handwriting elsewhere on the scan.

   | Scan feature | Mean gray |
   |---|---:|
   | Printed wire | 73 |
   | RA4 X mark | 81 |
   | Printed text | 89 |
   | Pencil handwriting at top margin | 140 |

The reconstructed schematic has an explicit RA4 no-connect at `(97.79,
105.41)`; with U1 placed at `(80.01, 110.49)`, that location resolves to PIC pin
3. The PCB independently names the pad
`unconnected-(U1-TOCKI{slash}RA4-Pad3)`. The reconstructed schematic and PCB
therefore agree.

The firmware also proves R5's purpose: at reset RA3 is driven high while RA2 is
an input, so R5 pulls RA2 high for normal startup. Holding RA2 low during startup
enters the clock-calibration service mode; the firmware waits for RA2 to be
released before continuing. Moving R5 to RA4 would break that boot test.

The service-mode procedure is documented in
[`../Firmware/README.md`](../Firmware/README.md).

## Bench checks with an Alinco DJ-S11

Before relying on a rebuilt controller in the field, check it with the actual
radio and cable:

1. **Bias supply:** measure approximately 3 V from ring to sleeve and confirm it
   can source at least 1 mA without excessive sag.
2. **PTT keying:** confirm that the 2.7 kΩ pull-down keys reliably with both a
   fresh radio battery and a nearly discharged one. The microphone-bias voltage
   can move with battery condition.
3. **Audio level:** begin with R2 adjusted to approximately 300 Ω from wiper to
   ground, then verify 20–40 mV peak-to-peak or check deviation on a service
   monitor or trusted receiver.

## Verifying the transcription

The scanned schematic is lossy and its geometry is easy to misread. Use these
sources in descending order of confidence:

1. Treat `W0QE FoxMox scanned.pdf` as the source of truth for the original
   design.
2. Use the resolved nets in `foxmox.kicad_pcb` when checking the reconstructed
   connectivity. Footprint pad records carry their net names and avoid visual
   wire-tracing mistakes.
3. Cross-check hardware-dependent behavior against
   [`../Firmware/foxmox-v2.6.asm`](../Firmware/foxmox-v2.6.asm).
4. For close inspection of the scan, render it at high resolution:

   ```sh
   pdftoppm -r 300 -png "Hardware/W0QE FoxMox scanned.pdf" out
   ```

`Hardware/.history/` and `*.kicad_prl` are intentionally ignored by the outer
repository. They are local KiCad state, not versioned design artifacts.
