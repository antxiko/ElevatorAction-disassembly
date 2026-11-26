# The music

These are not recordings made by hand. `tools/musica.py` **runs the ROM's own sound engine** with `tools/z80run.py`:
it asks `sonido` (0x7580) for the sound with its number, runs the per-frame engine (`sonido_cuadro`, 0x75EC) and
logs what it writes to the PSG through the BIOS (WRTPSG). An AY-3-8910 synthesiser turns that into sound: with the ROM
in the root, `make musica` leaves the MP3s in `docs/audio/`. They are not published here: the music is Taito's. They
have not been checked against an openMSX recording yet.

## The engine

There is **a single tune** (0x80, the in-game background) and **19 effects** (0x00 to 0x12). The tune plays on
channel B; the effects on A, each with a priority: a new one only gets in if its priority is not lower than the one
playing (`sonido_prioridad`, 0x7643). The in-game interrupt calls the engine **one frame out of two**, so all the
sound runs at 30 steps per second.

Each note is 9 bytes: the mixer bits, the vibrato, the tone, the volume, the envelope, the noise, the vibrato speed
and the length. A byte with bit 7 set is a command: with bit 6 it ends the channel, otherwise it repeats a section
as many times as its low 5 bits say (`canal_siguiente_nota`, 0x782B).

## The long pieces

| | who asks for it | length |
|---|---|---:|
| the in-game background | `a_jugar`, 0x4042, on each life | 36.9 s and starts again |
| the round 1 cable | `entrada_cable`, 0x7174 | 4.0 s |
| the agent slides down the cable | 0x7200 | 6.6 s |
| he lands on the roof | 0x7263 | 2.8 s |
| documents and bonus | 0x508D and 0x415B | 2.9 s |
| the car drives off | `agente_al_coche`, 0x7A5E | 15.5 s |
| GAME OVER | `fin_de_partida`, 0x4242 | 6.1 s |

`make musica` writes them with these names: `musica_fondo.mp3`, `sonido_cable.mp3`, `sonido_desliza.mp3`,
`sonido_azotea.mp3`, `sonido_documentos.mp3`, `sonido_coche.mp3` and `sonido_game_over.mp3`.

## The short effects

| number | what | priority |
|---|---|---:|
| 0x00 | the lift with the agent | 3 |
| 0x01 | an enemy shoots | 4 |
| 0x02 | a bullet hits | 5 |
| 0x03 | an enemy falls | 6 |
| 0x04 | the jump | 5 |
| 0x05 | the agent shoots | 6 |
| 0x06 | a lift roof hits | 6 |
| 0x07 | the agent falls down the shaft | 10 |
| 0x08 | the agent is hit | 15 |
| 0x09 | a door opens | 6 |
| 0x0B | a step | 2 |
| 0x0F | the lamp falls | 14 |
| 0x12 | the escalator | 3 |
