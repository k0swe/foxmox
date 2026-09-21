# Generated FoxMox firmware map

- ROM SHA-256: `546781166e6c349ccbb167d5767dacbf99e84a844c02573d8a7d724120fe6fbd`
- EEPROM SHA-256 (logical image order): `3ecd61956a537acd8086bfbe1c5345dce7cae8af925cf8473f01e992a6cb9bab`
- Logical EEPROM: `1428146418602490285030c03cf03cf00c181414142814640c24103010403c00000007080e101c20ffffffffffffffffffffffffffffffffffffffffffffffff`

## S1 content dispatch

| S1 | Content | ROM target |
|---:|:---|---:|
| 0 | MOE | `0x1F8` |
| 1 | MOI | `0x201` |
| 2 | MOS | `0x20A` |
| 3 | MOH | `0x213` |
| 4 | MO5 | `0x21C` |
| 5 | MO | `0x225` |
| 6 | A | `0x22D` |
| 7 | B | `0x238` |
| 8 | C | `0x241` |
| 9 | L | `0x24A` |
| A | N | `0x253` |
| B | P | `0x25E` |
| C | V | `0x267` |
| D | X | `0x270` |
| E | Z | `0x279` |
| F | FOX | `0x282` |

## S2 cadence addressing

| S2 | fox address (S1 0-4) | other address (S1 5-F) | special jitter for other modes |
|---:|---:|---:|:---|
| 0 | `0x00` | `0x10` | no |
| 1 | `0x02` | `0x12` | no |
| 2 | `0x04` | `0x14` | no |
| 3 | `0x06` | `0x16` | no |
| 4 | `0x08` | `0x18` | no |
| 5 | `0x0A` | `0x1A` | no |
| 6 | `0x0C` | `0x1C` | no |
| 7 | `0x0E` | `0x1E` | no |
| 8 | `0x00` | `0x10` | no |
| 9 | `0x02` | `0x12` | no |
| A | `0x04` | `0x14` | no |
| B | `0x06` | `0x16` | no |
| C | `0x08` | `0x18` | yes |
| D | `0x0A` | `0x1A` | yes |
| E | `0x0C` | `0x1C` | yes |
| F | `0x0E` | `0x1E` | no |

## Logical EEPROM 0x00-0x27 timing records

Nominal timing uses EEPROM[0x28]=0. The recovered value is shown separately below.

| Address | Bytes | BE counter | nominal primary | nominal low-byte follow-up |
|---:|:---:|---:|---:|---:|
| `0x00` | `14 28` | 5160 | 5157.565 s (85.959 min) | 39.981 s |
| `0x02` | `14 64` | 5220 | 5217.537 s (86.959 min) | 99.953 s |
| `0x04` | `18 60` | 6240 | 6237.056 s (103.951 min) | 95.955 s |
| `0x06` | `24 90` | 9360 | 9355.584 s (155.926 min) | 143.932 s |
| `0x08` | `28 50` | 10320 | 10315.131 s (171.919 min) | 79.962 s |
| `0x0A` | `30 C0` | 12480 | 12474.111 s (207.902 min) | 191.909 s |
| `0x0C` | `3C F0` | 15600 | 15592.639 s (259.877 min) | 239.887 s |
| `0x0E` | `3C F0` | 15600 | 15592.639 s (259.877 min) | 239.887 s |
| `0x10` | `0C 18` | 3096 | 3094.539 s (51.576 min) | 23.989 s |
| `0x12` | `14 14` | 5140 | 5137.575 s (85.626 min) | 19.991 s |
| `0x14` | `14 28` | 5160 | 5157.565 s (85.959 min) | 39.981 s |
| `0x16` | `14 64` | 5220 | 5217.537 s (86.959 min) | 99.953 s |
| `0x18` | `0C 24` | 3108 | 3106.533 s (51.776 min) | 35.983 s |
| `0x1A` | `10 30` | 4144 | 4142.045 s (69.034 min) | 47.977 s |
| `0x1C` | `10 40` | 4160 | 4158.037 s (69.301 min) | 63.970 s |
| `0x1E` | `3C 00` | 15360 | 15352.752 s (255.879 min) | 0.000 s |
| `0x20` | `00 00` | 0 | 0.000 s (0.000 min) | 0.000 s |
| `0x22` | `07 08` | 1800 | 1799.151 s (29.986 min) | 7.996 s |
| `0x24` | `0E 10` | 3600 | 3598.301 s (59.972 min) | 15.992 s |
| `0x26` | `1C 20` | 7200 | 7196.603 s (119.943 min) | 31.985 s |

## Initial pair selection

| S1 class | S2 | EEPROM pair |
|:---|:---|---:|
| 0-4 | 0,1,2,3,4,5,6 | `0x00` |
| 0-4 | 7,8 | `0x02` |
| 0-4 | 9,A,B,C,D,E | `0x04` |
| 0-4 | F | `0x06` |
| 5-F | 0,1,2,3,4,5,6,7 | `0x00` |
| 5-F | 8,9,A,B,C,D,E,F | `0x04` |

## Runtime timing trim

- EEPROM `0x28` = `0xFF` (255).
- Nominal counter tick at setting `0x00`: 0.999528152 s.
- Counter tick at recovered setting `0xFF`: 1.072475971 s.
- Verified callsign routine at ROM `0x109-0x110`: `N0PUF`.
- All checked machine-code anchors matched.
