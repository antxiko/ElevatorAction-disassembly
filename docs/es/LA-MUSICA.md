# La música

No son grabaciones hechas a mano. `tools/musica.py` **ejecuta el motor de sonido de la propia ROM** con
`tools/z80run.py`: pide el sonido con su número a `sonido` (0x7580), corre el motor de cada cuadro
(`sonido_cuadro`, 0x75EC) y apunta lo que escribe en el PSG por la BIOS (WRTPSG). Un sintetizador del
AY-3-8910 lo convierte en sonido: con la ROM puesta en la raíz, `make musica` deja los MP3 en `docs/audio/`. Aquí no
se publican: la música es de Taito. No se han cotejado todavía con una grabación de openMSX.

## El motor

Hay **una sola música** (la 0x80, la de fondo de la partida) y **19 efectos** (0x00 a 0x12). La música va por el
canal B; los efectos, por el A, y cada uno lleva una prioridad: uno nuevo solo entra si la suya no es menor que la
del que suena (`sonido_prioridad`, 0x7643). La interrupción de la partida llama al motor **un cuadro de cada dos**,
así que todo el sonido va a 30 pasos por segundo.

Cada nota son 9 bytes: los bits del mezclador, el vibrato, el tono, el volumen, la envolvente, el ruido, la
velocidad del vibrato y la duración. Un byte con el bit 7 es una orden: con el bit 6 acaba el canal, y si no,
repite un tramo las veces que digan sus 5 bits bajos (`canal_siguiente_nota`, 0x782B).

## Las piezas largas

| | quién la pide | dura |
|---|---|---:|
| el fondo de la partida | `a_jugar`, 0x4042, en cada vida | 36,9 s y vuelve a empezar |
| el cable de la ronda 1 | `entrada_cable`, 0x7174 | 4,0 s |
| el agente baja por el cable | 0x7200 | 6,6 s |
| llega a la azotea | 0x7263 | 2,8 s |
| documentos y bonus | 0x508D y 0x415B | 2,9 s |
| el coche se va | `agente_al_coche`, 0x7A5E | 15,5 s |
| GAME OVER | `fin_de_partida`, 0x4242 | 6,1 s |

`make musica` los genera con estos nombres: `musica_fondo.mp3`, `sonido_cable.mp3`, `sonido_desliza.mp3`,
`sonido_azotea.mp3`, `sonido_documentos.mp3`, `sonido_coche.mp3` y `sonido_game_over.mp3`.

## Los efectos cortos

| número | qué | prioridad |
|---|---|---:|
| 0x00 | el ascensor con el agente | 3 |
| 0x01 | un enemigo dispara | 4 |
| 0x02 | una bala choca | 5 |
| 0x03 | un enemigo cae | 6 |
| 0x04 | el salto | 5 |
| 0x05 | el agente dispara | 6 |
| 0x06 | un techo de ascensor golpea | 6 |
| 0x07 | el agente cae por el hueco | 10 |
| 0x08 | al agente le dan | 15 |
| 0x09 | se abre una puerta | 6 |
| 0x0B | un paso | 2 |
| 0x0F | cae la lámpara | 14 |
| 0x12 | la escalera mecánica | 3 |
