# AGENTS.md — FoxMox

Contributor instructions for this repository. Start with
[`README.md`](README.md) for the public project overview; durable design and
operating information belongs in the linked public documentation rather than
here.

## Repository workflow

- Check `git status` before editing. Hardware work may already be in progress;
  stage and commit only files belonging to the current task.
- Do not commit or mine `Hardware/.history/`; it is KiCad's ignored local
  snapshot repository.
- Keep `Hardware/Datasheets/` for selected-part datasheets and
  `Hardware/Libraries/` for project-local symbols, footprints, and models.
- Preserve the recovered `Firmware/foxmox-v2.6.hex` as the regression oracle.
  After firmware-source changes, run `make -C Firmware verify` and require exact
  programmed-memory and canonical-HEX equivalence for the default N0PUF build.
- For a custom callsign, use `make -C Firmware image CALLSIGN=...` as documented
  in `Firmware/README.md`; customized images are expected to differ from the
  recovered oracle.

## Checking difficult schematic claims

- Prefer resolved pad net names in `Hardware/foxmox.kicad_pcb` over visually
  tracing wires in the schematic. Parse footprint blocks and their
  `(pad ... (net ...))` records when a netlist export is unavailable.
- Cross-check pin-direction or startup claims against `Firmware/foxmox-v2.6.asm`
  rather than inferring behavior from the drawing.
- Render ambiguous scan regions at high resolution when needed:

  ```sh
  pdftoppm -r 300 -png "Hardware/W0QE FoxMox scanned.pdf" out
  ```
