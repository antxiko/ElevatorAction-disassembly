# The sprites

The sprites are 16x16 (VDP register 1 = 0xE2) and their drawings are loaded when each round is set up
(`monta_edificio`, 0x4691): the agent (22 drawings, 0x8D98), the enemy (14, 0x905A) and the rest (bullets, lamp,
0x921C). Each block is copied twice, once as it is to the table at 0x2000 and once mirrored to the table at 0x2800
(`espejo_bytes`, 0x4657, and `espejo_sprites`, 0x466B): to face the other way the game does not change drawings, it
changes **VDP register 6** from 4 to 5 (`dibujos_del_lado`, 0x53C7). That only works for the agent: the enemy
carries both of its sides in both tables (the normal one from 0x58 and the mirrored one from 0x90) and its own table
for each side.

Each character carries in its record a pointer to its drawing table. The pose is a bit (1 standing, 2 walking,
4 ducking, 8 in the air, 0x10 in a door, 0x20 crushed, 0x40 falling, 0x80 shot) and the frame a number; each frame
is a list of sprites with their drawing, colour and how far down the Y goes, ending in 0xFF (`pon_sprites`, 0x5721).

## The agent (table 0x5856, and 0x584E when shooting)

| pose | frames | drawings | shooting |
|---|---|---|---|
| standing | 1 | 0x04, 0x08, 0x0C | 0x14, 0x18, 0x1C |
| walking | 2 | 0x04, 0x08, 0x0C / 0x04, 0x08, 0x10 | 0x14, 0x18, 0x1C / 0x14, 0x18, 0x20 |
| ducking | 1 | 0x24, 0x28 | 0x2C, 0x30 |
| in the air | 4 | 0x04, 0x34, 0x38 / 0x34, 0x3C (x2) / 0x04, 0x34, 0x38 | 0x34, 0x40 in the middle ones |
| going into a door | 6 | the walking ones, and empty while opening and closing | |
| crushed | 3 | 0xE8, 0xEC / 0xF0, 0xF4 / 0xE4 | |
| falling | 4 | 0x34, 0x3C / 0x50, 0x54 / 0x34, 0x3C / 0xE4 | |
| shot | 4 | 0x44, 0x48, 0x4C / 0x50, 0x54 / 0x34, 0x3C / 0x50, 0x54 | |

On the escalator the table is not used: `agente_dos_sprites` (0x5B7D) and `agente_tres_sprites` (0x5B98) put drawings
0x04, 0x08 and 0x0C by hand, and to hide the legs behind the step `piernas_fuera` (0x7BA8) changes two bytes of the
drawings themselves in VRAM.

## The enemy (tables 0x6894 facing right and 0x68A4 facing left; 0x6884 and 0x688C shooting)

| pose | frames | facing right | shooting | facing left | shooting |
|---|---|---|---|---|---|
| standing | 1 | 0x58, 0x5C | 0x68, 0x5C | 0x90, 0x94 | 0xA0, 0x94 |
| walking | 2 | 0x58, 0x5C / 0x60, 0x64 | 0x68, 0x5C / 0x6C, 0x64 | 0x90, 0x94 / 0x98, 0x9C | 0xA0, 0x94 / 0xA4, 0x9C |
| ducking | 1 | 0x70 | 0x74 | 0xA8 | 0xAC |
| in the air | 1 | 0x84 | | 0xBC | |
| coming out of a door | 6 | the walking ones | | the walking ones | |
| crushed | 3 | 0xF8 / 0xFC / 0xE4 | | the same | |
| falling and shot | 3 | 0x78, 0x7C / 0x80 / 0xE4 | | 0xB0, 0xB4 / 0xB8 / 0xE4 | |

On the escalator it puts 0xC8 or 0xCC (the body for each side) and, at the end of the flight, 0x58 and 0x5C
(`enemigo_escalera_piernas`, 0x5DF9).

## The rest

| what | drawings | who |
|---|---|---|
| the bullets, flying and on impact | 0x88 and 0x8C (the agent's), 0xC0 and 0xC4 (the enemies') | table 0x6EB6 |
| the falling lamp | 0xD0, 0xD4 and 0xD8 | `lampara_sprites`, 0x7E13 |
| two fixed sprites, bottom left | 0xDC and 0xE0 | `agente_entra`, 0x4E7C (table 0x4EAF) |
| the agent hanging from the cable (round 1) | 0xD0, 0xD4 and 0xD8: its drawings (0x7329) are loaded over the lamp's and put back afterwards (0x925C) | `entrada_cable`, 0x716C |
| the car in the basement | 0x20 to 0x3C, loaded at 0x2100 when the round ends | `coche_anima`, 0x7980 |

The car is loaded over the agent's drawings because by then the agent is no longer drawn with them: he is inside the
car, made of five sprites from the table at 0x7BD9.
