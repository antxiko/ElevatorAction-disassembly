# Secrets and bugs

There are no cheats or hidden screens: the game reads no keys other than the cursors, `x`, `z` and the space bar
(table 0x4917 and `lee_mando`, 0x48CF). What there is, is unused code and three slips.

## Code nobody calls

In the whole cartridge there is not a single indirect jump (no `jp (hl)` and no addresses pushed on the stack), so a
piece of code that no `call` or `jp` leads to is never run. There are five:

| where | what it does |
|---|---|
| 0x4C0B | writes a text letter by letter with a wait between them |
| 0x4E06 | a 16-bit division and multiplication |
| 0x65D5 | checks whether a door is to the left or the right of a character |
| 0x78CD | **moves the agent and the view several floors at once**, up or down according to a table (0x7925), only once: it looks like a testing aid |
| 0x7F72 | puts a list of building pieces |

And two loose bytes at 0x5A8A (`and a` / `ret`) between two routines, which the flow jumps over.

## Bug: the lamp shifted in round 1

The drawings of the falling lamp (0xD0, 0xD4 and 0xD8) and those of the agent hanging from the cable share the same
place in VRAM (0x2680). When the cable entrance of round 1 ends, the game puts the lamp's back from 0x925C
(`cable_quita_fila`, 0x7295). But that block in the ROM starts at 0x921C with **two bytes of length in front**: the
right drawings are at 0x925E. The copy comes out two bytes off, and 26 of the 96 differ.

Checked in openMSX (`tools/guiones/mapa.tcl`): right after the cable, VRAM at 0x2680 and at 0x2E80 holds the copy
from 0x925C and not the one from 0x925E. It lasts the whole of round 1, also after losing a life; from round 2 the
round loader (`monta_edificio`) puts them right again.

## A counter nobody reads

Every time points are added, `cuenta_por_puntos` (0x6F4C) works out the tens of thousands and keeps a count at
0xC0D4. Nothing else in the cartridge reads 0xC0D4: it is only cleared when a game starts. It looks very much like
extra lives every so many points that were left half done. The only extra life is the one at 10,000
(`bucle_juego`, 0x4065), and since it only checks whether the tens-of-thousands digit is a 1, it is given once and no
more.

## A copy that goes too far

When the round's graphics are loaded, the block of the bullets and the lamp, 0x1C0 bytes, is copied to the second
sprite table with a length of **0x9C0** (`monta_edificio`, 0x474E): from 0x2E40 up to 0x3800, with whatever was in
RAM after the block. It does not show, because that VRAM (0x3000 to 0x37FF) is not used by anything.
