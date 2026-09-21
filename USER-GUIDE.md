# FoxMox V2.6 User Guide

This guide covers ordinary field setup of a FoxMox controller running the
reconstructed V2.6 firmware. For programmer wiring, chip recovery, and exact
build verification, see [`Firmware/README.md`](Firmware/README.md).

## Callsign: programmed into the PIC

The station callsign is compiled into the PIC16F84A program. It is **not field
programmable** and neither rotary switch changes it. The firmware inserts the
callsign near the end of a transmit phase, no more frequently than approximately
once every ten minutes.

The recovered firmware defaults to **N0PUF**. To build a replacement image with
a different callsign, install `gputils` and run, for example:

```sh
make -C Firmware/asm image CALLSIGN=K0SWE BUILD_DIR=build/K0SWE
```

The resulting programming image is:

```text
Firmware/asm/build/K0SWE/foxmox-v2.6.hex
```

The callsign may contain `A-Z` and `0-9`. Lowercase is normalized to uppercase;
punctuation such as `/` is not currently supported. Changing the callsign
requires rebuilding the image and programming the PIC again. It does not alter
the S1 message identity.

The normal exact-reconstruction command remains:

```sh
make -C Firmware/asm verify
```

That command always uses the recovered **N0PUF** callsign and verifies that the
result is byte-for-byte identical to the recovered image.

## Set the switches before applying power

The two hexadecimal rotary switches select operating behavior:

- **S1** selects the transmitted fox or practice message.
- **S2** selects the transmit/silent timing profile and, for some settings, a
  one-time startup delay.

The firmware samples them at startup and again at points in the operating cycle.
Set both switches while the controller is off; changing them live can combine an
old phase with a newly sampled setting. The unit transmits its selected S1
message once shortly after power is applied, then observes the selected startup
delay and enters its repeating transmit/silent cycle.

### S1: transmitted message

| S1 | Transmitted message | Typical use |
|---:|:---|:---|
| `0` | `MOE` | Fox 1 |
| `1` | `MOI` | Fox 2 |
| `2` | `MOS` | Fox 3 |
| `3` | `MOH` | Fox 4 |
| `4` | `MO5` | Fox 5 |
| `5` | `MO` | Alternate/practice message |
| `6` | `A` | Alternate/practice message |
| `7` | `B` | Alternate/practice message |
| `8` | `F` | Alternate/practice message |
| `9` | `L` | Alternate/practice message |
| `A` | `N` | Alternate/practice message |
| `B` | `P` | Alternate/practice message |
| `C` | `V` | Alternate/practice message |
| `D` | `X` | Alternate/practice message |
| `E` | `Z` | Alternate/practice message |
| `F` | `FOX` | General fox/practice message |

S1=`8` is **F** (`..-.`), not C.

## S2 timing for the five standard fox identities

Use this table when S1 is `0` through `4`. Durations are nominal whole seconds;
the clock-calibration value stored in EEPROM can shift them slightly.

| S2 | Transmit | Silent | Cycle | Startup delay |
|---:|---:|---:|---:|---:|
| `0` | 20 s | 40 s | 1 min | none |
| `1` | 20 s | 100 s | 2 min | none |
| `2` | 24 s | 96 s | 2 min | none |
| `3` | 36 s | 144 s | 3 min | none |
| `4` | 40 s | 80 s | 2 min | none |
| `5` | 48 s | 192 s | 4 min | none |
| `6` | 60 s | 240 s | 5 min | none |
| `7` | 60 s | 240 s | 5 min | 30 min |
| `8` | 20 s | 40 s | 1 min | 30 min |
| `9` | 20 s | 100 s | 2 min | 60 min |
| `A` | 24 s | 96 s | 2 min | 60 min |
| `B` | 36 s | 144 s | 3 min | 60 min |
| `C` | 40 s | 80 s | 2 min | 60 min |
| `D` | 48 s | 192 s | 4 min | 60 min |
| `E` | 60 s | 240 s | 5 min | 60 min |
| `F` | 60 s | 240 s | 5 min | 120 min |

S2 `8` through `F` repeat the cadence profiles of `0` through `7`, but select
different startup delays.

## S2 timing for alternate messages

Use this table when S1 is `5` through `F`.

| S2 | Transmit | Silent | Cycle | Startup delay | Additional behavior |
|---:|---:|---:|---:|---:|:---|
| `0` | 12 s | 24 s | 36 s | none | — |
| `1` | 20 s | 20 s | 40 s | none | — |
| `2` | 20 s | 40 s | 1 min | none | — |
| `3` | 20 s | 100 s | 2 min | none | — |
| `4` | 12 s | 36 s | 48 s | none | — |
| `5` | 16 s | 48 s | 64 s | none | — |
| `6` | 16 s | 64 s | 80 s | none | — |
| `7` | 60 s | 0 s | 1 min | none | — |
| `8` | 12 s | 24 s | 36 s | 60 min | — |
| `9` | 20 s | 20 s | 40 s | 60 min | — |
| `A` | 20 s | 40 s | 1 min | 60 min | — |
| `B` | 20 s | 100 s | 2 min | 60 min | — |
| `C` | 12 s | 36 s | 48 s | 60 min | Adds 0–31 s pseudo-random silent jitter |
| `D` | 16 s | 48 s | 64 s | 60 min | Adds 0–31 s pseudo-random silent jitter |
| `E` | 16 s | 64 s | 80 s | 60 min | Adds 0–31 s pseudo-random silent jitter |
| `F` | 60 s | 0 s | 1 min | 60 min | — |

The jitter is added to the silent phase. It applies only to S1=`5` through `F`
with S2=`C`, `D`, or `E`.

## Standard five-fox round robin

For the familiar five-fox sequence—one fox transmitting for one minute, then
silent for four minutes—configure five independent controllers as follows:

| Unit | S1 | Message | S2 |
|---:|---:|:---|---:|
| 1 | `0` | `MOE` | `6` |
| 2 | `1` | `MOI` | `6` |
| 3 | `2` | `MOS` | `6` |
| 4 | `3` | `MOH` | `6` |
| 5 | `4` | `MO5` | `6` |

S2=`6` gives each unit a 60-second transmit phase followed by 240 seconds of
silence, with no built-in startup delay.

### Staggered power-on procedure

The controllers do not communicate with one another, listen for another fox, or
synchronize over the air. **The time at which each unit is powered establishes
its phase.**

1. Set S1/S2 on all five powered-off units as shown above.
2. At `T+0:00`, power Fox 1 (`MOE`).
3. At `T+1:00`, power Fox 2 (`MOI`).
4. At `T+2:00`, power Fox 3 (`MOS`).
5. At `T+3:00`, power Fox 4 (`MOH`).
6. At `T+4:00`, power Fox 5 (`MO5`).
7. Monitor one complete five-minute cycle and confirm the order before
   deployment.

Each controller sends its selected message shortly after power-on, before its
normal timed phase begins. Those one-time startup announcements can briefly
overlap the preceding fox during setup; judge the round robin from the first
complete cycle after all five units are running. Perform the sequence on the
intended operating frequency only when those setup transmissions are acceptable.
Powering all five at the same time would put their normal cycles at approximately
the same phase and cause continuing overlap.

The clocks are crystal-derived but independent. For long events, allow for some
drift and verify the sequence before participants start. If a unit loses power,
its phase is lost; restore the intended sequence by powering it again at the
correct point in the five-minute cycle.

## Other useful configurations

- **Single continuously repeating practice fox:** S1=`F`, S2=`7` gives `FOX`
  with a nominal 60-second transmit phase and no silent phase.
- **One-minute fox cycle:** S1=`0` through `4`, S2=`0` gives 20 seconds on and
  40 seconds silent, with no startup delay.
- **Delayed deployment:** upper-half S2 settings (`8`–`F`) retain a lower-half
  cadence but add a 30-, 60-, or 120-minute startup delay as shown in the
  tables. The unit still sends its selected message once immediately after
  power-on before waiting through that delay.

## Operational cautions

- Set S1 and S2 before power-on; do not rely on changing them during a cycle.
- The callsign and S1 message are separate: changing S1 never changes the
  programmed callsign.
- The controller is powered from the radio microphone-bias supply. Confirm the
  radio and cable can provide the required current before field deployment.
- Verify deviation and reliable PTT keying with the actual radio and battery
  condition being used.
- Program only a replaceable PIC. Keep recovered original chips read-only.
