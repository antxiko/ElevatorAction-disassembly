# Curiosities

## A copy of an MSX's memory inside the cartridge

The game ends at 0xA2EF, with the last note of the tune. After that the cartridge is not empty: from 0xA2F0 to
0xB2EE it carries **a copy of an MSX's RAM, from 0xF001 to 0xFFFF**, the system variables area. You can tell because
everything falls into place at once, with the same 0x4D11 offset:

- from 0xB089 to 0xB1EE, the system hooks (0xFD9A to 0xFEFF in RAM), all with their stock `ret` (0xC9);
- at 0xA66F, the slot-switching routines the BIOS copies to 0xF380 (`D3 A8 5E 18 03 D3 A8 73 ...`);
- at 0xAB6E, the function keys from 0xF87F: `color`, `auto`, `goto`, `list`, `run`, `color 15,4,7`, `cload"`,
  `cont`, `list.`.

Most likely a chunk too much of memory from the machine used to make the ROM went into it when it was burnt. Nothing
in the game reads it. After it come zeros up to 0xB3FF and 0xFF padding to the end.

## The rush hour

The interrupt counts the frames of the round (0xC3A0) and, at 0x38 x 256 (about four minutes), sets 0xC39F
(`int_partida_reloj`, 0x4C50). From then on the enemies choose their pose as in round 6, the hardest in the table
(`enemigo_decide`, 0x64E4): staying long in a round makes it harder.

## The red doors are drawn by lot

The red doors are not always the same: each round they are picked at random from three groups of doors, more the
later the round (from 5 in the first to 10 from the sixth on). The lift going down to the car is also drawn among
five, and some lifts come out double. See [The building](THE-BUILDING.html).

## A trick to turn the characters round

The sprite drawings are loaded twice into VRAM, once normal and once mirrored, in two 2 KB tables. For the agent to
face the other way the game does not change a single drawing: it changes VDP register 6, which says where the
drawings are (`dibujos_del_lado`, 0x53C7). The enemies do not use the trick: both of their sides are loaded in both
tables and each enemy picks its own (0x58 or 0x90) by itself.

## Sprites flicker instead of vanishing

The MSX only shows four sprites per line. So that it is not always the same one that disappears, the interrupt sends
the sprite table in order one frame and reversed the next (`sprites_a_vram`, 0x7937): the extra ones flicker.

## A wait that does not count frames

`espera` (0x4E6C), the pause of the entrances and exits, is an empty loop of 100 turns per unit: it does not look at
the VDP clock, so it lasts as long as the Z80 takes, plus whatever the interrupts that come in between steal.
