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
| 8 | F | `0x241` |
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

## Normal cadence records at EEPROM 0x00-0x1F

Each pair contains independent transmit and silent durations. Nominal timing uses EEPROM[0x28]=0.

| Address | Bytes | transmit | silent | total cycle |
|---:|:---:|---:|---:|---:|
| `0x00` | `14 28` | 19.991 s | 39.981 s | 59.972 s |
| `0x02` | `14 64` | 19.991 s | 99.953 s | 119.943 s |
| `0x04` | `18 60` | 23.989 s | 95.955 s | 119.943 s |
| `0x06` | `24 90` | 35.983 s | 143.932 s | 179.915 s |
| `0x08` | `28 50` | 39.981 s | 79.962 s | 119.943 s |
| `0x0A` | `30 C0` | 47.977 s | 191.909 s | 239.887 s |
| `0x0C` | `3C F0` | 59.972 s | 239.887 s | 299.858 s |
| `0x0E` | `3C F0` | 59.972 s | 239.887 s | 299.858 s |
| `0x10` | `0C 18` | 11.994 s | 23.989 s | 35.983 s |
| `0x12` | `14 14` | 19.991 s | 19.991 s | 39.981 s |
| `0x14` | `14 28` | 19.991 s | 39.981 s | 59.972 s |
| `0x16` | `14 64` | 19.991 s | 99.953 s | 119.943 s |
| `0x18` | `0C 24` | 11.994 s | 35.983 s | 47.977 s |
| `0x1A` | `10 30` | 15.992 s | 47.977 s | 63.970 s |
| `0x1C` | `10 40` | 15.992 s | 63.970 s | 79.962 s |
| `0x1E` | `3C 00` | 59.972 s | 0.000 s | 59.972 s |

## Startup-delay records at EEPROM 0x20-0x27

These four records are big-endian 16-bit startup delays.

| Address | Bytes | ticks | nominal delay |
|---:|:---:|---:|---:|
| `0x20` | `00 00` | 0 | 0.000 s (0.000 min) |
| `0x22` | `07 08` | 1800 | 1799.151 s (29.986 min) |
| `0x24` | `0E 10` | 3600 | 3598.301 s (59.972 min) |
| `0x26` | `1C 20` | 7200 | 7196.603 s (119.943 min) |

## Initial pair selection

| S1 class | S2 | EEPROM pair |
|:---|:---|---:|
| 0-4 | 0,1,2,3,4,5,6 | `0x20` |
| 0-4 | 7,8 | `0x22` |
| 0-4 | 9,A,B,C,D,E | `0x24` |
| 0-4 | F | `0x26` |
| 5-F | 0,1,2,3,4,5,6,7 | `0x20` |
| 5-F | 8,9,A,B,C,D,E,F | `0x24` |

## Runtime timing trim

- EEPROM `0x28` = `0xFF` (255).
- Nominal counter tick at setting `0x00`: 0.999528152 s.
- Average counter tick at recovered setting `0xFF`: 1.000667962 s.
- Verified callsign routine at ROM `0x109-0x110`: `N0PUF`.
- All checked machine-code anchors matched.
