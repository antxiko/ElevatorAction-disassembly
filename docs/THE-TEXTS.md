# The texts

The game has very little text, all of it in English. It is written with three different sets of letters: the ASCII
letters in the building's pattern set (0x41 to 0x5A), the title's tiles and two tiles drawn for the 500 points.

| text | where it is | who writes it | how |
|---|---|---|---|
| `PLAYER    HI SCORE` | 0x4814 | `marcador_fijo`, 0x47E6 | screen row 0; `;` and `@` are blank tiles |
| `ROUND` and its number | 0x47E1 | `monta_edificio`, 0x47D4 | bottom row; the round on screen goes from 0 to 99 |
| `GAME OVER` | 0x4265 | `fin_de_partida`, 0x4233 | on the emptied screen, row 10 |
| `BONUS 1000` | 0x43AD | `ronda_superada`, 0x4134 | copied to RAM (0xC343) and the thousands digit is swapped for the round's |
| `?` | 0x43BC | `fin_de_ronda`, 0x40FB | the sign shown on reaching the basement without all the documents; it gives no points |
| `500` | 0x592C | `agente_en_puerta`, 0x5087 | two drawn tiles (0x93 and 0x94) where the red door was |
| `© TAITO CORP.1985` | 0x949A | `titulo`, 0x49C5 | with the title's tiles (0xAC is the ©) |
| `PUSH SPACE KEY` | 0x94AB | `titulo_lee_disparo`, 0x4B47 | blinks every 30 frames until the space bar is pressed |

## The signs that unfold

`BONUS`, the `?` and the `500` are not written all at once: `rotulo_saca` (0x7000) puts them on the map in six steps
of 30 frames, saving what they cover, and on the sixth it removes them and adds the points they carry
(`rotulo_cuadro`, 0x702C). While a sign is unfolding no new enemy comes out.

## What is not the game's

Between 0xA2F0 and 0xB2EE there is more text, `color`, `auto`, `goto`, `list`, `run`, `color 15,4,7`, `cload"`,
`cont`. Nobody writes it: those are the function keys of a copy of an MSX's memory that slipped into the cartridge
(see [Curiosities](CURIOSITIES.html)).
