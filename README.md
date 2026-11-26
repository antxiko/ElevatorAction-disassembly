# Elevator Action - commented disassembly

*(También [en español](README.es.md).)*

The commented disassembly of **Elevator Action** (Taito, 1985) for the MSX: a 32 KB cartridge with its header at 0x4000.

- **100%** of the binary explained: 13,361 bytes of code and 19,407 of named data, not a single byte unassigned.
- **49.9%** of the listing commented, 857 routines and labels, none below 10% comments.
- The listing reassembles into the original ROM **byte for byte**.
- The building comes from running the ROM, checked against openMSX's RAM tile by tile; the music and the effects, from its own sound engine (`make musica`).
- The red doors and the basement lift are drawn by lot each round, and the cartridge carries a copy of the memory of the MSX it was burnt with.

The website: <https://antxiko.github.io/ElevatorAction-disassembly/>
(in Spanish: <https://antxiko.github.io/ElevatorAction-disassembly/es/>).

## Reproducing it

The ROM image is not distributed. Put yours in the root as `elevator.rom` (the GoodMSX `[!]` dump, sha1 `6cbddd11...`) and run `make`. The details are in [UNDER THE HOOD](docs/UNDER-THE-HOOD.md).

## Legal

The game belongs to Taito and its rights holders. The licence in `LICENSE` only covers the tools, comments, analysis and documentation here. See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
