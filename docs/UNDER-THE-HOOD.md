# Under the hood

## Rebuilding the ROM

The repository does not include the game. With the ROM in the root as `elevator.rom` (32,768 bytes, sha1
`6cbddd118afe63e79cb8a40f8aa879df1c7590e1`), `make all` traces the code, generates the listing, assembles it again
with pasmo and checks that it gives **the same ROM byte for byte**; then the tests run. It needs `pasmo`, `z80dasm`,
`make` and Python 3.

| | |
|---|---|
| code | 13,361 bytes |
| data | 19,407 bytes |
| instructions | 6,356, of which 3,173 carry a comment (49.9%) |
| named routines | 857 |

The listing comes from `src/elevator.notes` (the names and comments), `src/elevator.entries` (the entry points the
trace cannot work out: the start and the two interrupts) and `src/elevator.nocode` (the header).

## The cartridge

A flat 32 KB from 0x4000 to 0xBFFF, no mapper. The header only has `AB` and INIT (0x4010). The first thing the start
does is look for the slot holding the second half of the cartridge and connect it at 0x8000 with ENASLT
(`busca_pagina_2`, 0x4D59): it compares `AB`, the INIT address and the first two bytes of the start, reading them
with RDSLT in every slot and subslot.

| area | what is there |
|---|---|
| 0x4010-0x7F71 | the code |
| 0x7F8D-0x8515 | the building: floors and pieces |
| 0x8516-0x93DD | the in-game patterns, colours and sprites |
| 0x949A-0x9A8E | the title: texts, compressed patterns and colours, sprites |
| 0x9A8F-0xA2EF | the sound: 19 effects and the tune |
| 0xA2F0-0xB2EE | a copy of an MSX's RAM (see [Curiosities](CURIOSITIES.html)) |
| 0xB2EF-0xBFFF | zeros and 0xFF padding |

## The BIOS it uses

WRTVDP (0x47), FILVRM (0x56), LDIRVM (0x5C), SETGRP (0x7E) and INIGRP (0x72) for the title, GTSTCK (0xD5),
GTTRIG (0xD8), SNSMAT (0x141), RDPSG (0x96), WRTPSG (0x93), GICINI (0x90), RDSLT (0x0C), ENASLT (0x24) and DCOMPR
(`rst 20h`).

## The screen mode

The title is SCREEN 2 with the BIOS tables; the game, GRAPHIC 1 (SCREEN 1) with its own tables (`vdp_modo_juego`,
0x4572): names at 0x1000, colours at 0x3FC0, patterns at 0x0000, sprite attributes at 0x3F00 and drawings at 0x2000
(or 0x2800, mirrored). 16x16 sprites.

## Two interrupts

The game hangs its routine on the H.TIMI hook (0xFD9F). On the title it is `int_titulo` (0x4C92), which dumps the
map and keeps the animation's count; when the space bar is pressed it swaps itself for `int_partida` (0x4C26). This
one, on alternate frames, sends the sprites, dumps the map if it changed, writes the score and moves the sound; on
every frame it decrements the 50 timers at 0xC09E (`temporizadores_cuadro`, 0x4DC3) and keeps the round's clock.

## The game loop

`bucle_juego` (0x4047) does on each pass: the unfolding sign, the agent, the enemies, the lifts, the bullets, the
hits, the lights, the lamp and the kick, the scroll and the sprites to the buffer. Then it checks the extra life,
whether the agent is still alive and whether he has reached the basement.

## The RAM

| where | what |
|---|---|
| 0xC000-0xC07F | the copy of the sprite table |
| 0xC080-0xC096 | flags, round, score (7 ASCII digits), lives and high score |
| 0xC09E-0xC0CF | the 50 timers |
| 0xC0D0-0xC0D3 | the scroll: bits, offset and row |
| 0xC0D8 | the agent (10 bytes) |
| 0xC0EC | the 11 lifts (10 bytes each) |
| 0xC16E | the 58 doors (5 bytes) |
| 0xC29A, 0xC2B8 | the agent's 3 bullets and the enemies' 4 |
| 0xC2E0 | the 4 enemies |
| 0xC308 | the unfolding sign |
| 0xC3A4-0xC3DB | the sound: requests, three channels and the PSG copy |
| 0xC400-0xDFFF | the building map |

## The tools

`tools/z80trace.py` traces the code, `tools/mkasm.py` builds the listing, `tools/verify_build.sh` reassembles it and
compares. `tools/z80run.py` and `tools/bios.py` are a Z80 and an MSX1 in Python used to run the ROM and its sound
engine (`tools/mapas.py`, `tools/musica.py`); `tools/guiones/mapa.tcl` is the openMSX script the map was checked with.
