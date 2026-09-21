# FoxMox hardware

This directory contains the complete hardware design and its source references.

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
| `.history/`                     | KiCad local-history repository and snapshots.                                     |

Open `foxmox.kicad_pro` from this directory. Library references use
`${KIPRJMOD}/Libraries/...`, so moving the project and `Libraries/` together
preserves their relative paths.

`.history/` and `*.kicad_prl` are intentionally ignored by the outer repository;
they remain local KiCad state rather than versioned design artifacts.
