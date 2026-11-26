# Los textos

El juego tiene muy poco texto, y todo en inglés. Se escribe con tres juegos de letras distintos: las letras ASCII
del juego de patrones del edificio (de 0x41 a 0x5A), los tiles del título y dos tiles dibujados para los 500 puntos.

| texto | dónde está | quién lo escribe | cómo |
|---|---|---|---|
| `PLAYER    HI SCORE` | 0x4814 | `marcador_fijo`, 0x47E6 | fila 0 de la pantalla; `;` y `@` son tiles vacíos |
| `ROUND` y su número | 0x47E1 | `monta_edificio`, 0x47D4 | fila de abajo; la ronda en pantalla va de 0 a 99 |
| `GAME OVER` | 0x4265 | `fin_de_partida`, 0x4233 | en la pantalla vaciada, fila 10 |
| `BONUS 1000` | 0x43AD | `ronda_superada`, 0x4134 | se copia a la RAM (0xC343) y la cifra de las unidades de mil se cambia por la de la ronda |
| `?` | 0x43BC | `fin_de_ronda`, 0x40FB | el rótulo de cuando se llega al sótano sin todos los documentos; no da puntos |
| `500` | 0x592C | `agente_en_puerta`, 0x5087 | dos tiles dibujados (0x93 y 0x94) en el sitio de la puerta roja |
| `© TAITO CORP.1985` | 0x949A | `titulo`, 0x49C5 | con los tiles del título (0xAC es la ©) |
| `PUSH SPACE KEY` | 0x94AB | `titulo_lee_disparo`, 0x4B47 | parpadea cada 30 cuadros hasta que se pulsa la barra |

## Los rótulos que se despliegan

`BONUS`, el `?` y el `500` no se escriben de golpe: `rotulo_saca` (0x7000) los pone en el mapa en seis pasos de 30
cuadros guardando lo que tapan, y al sexto los quita y suma los puntos que llevan asociados
(`rotulo_cuadro`, 0x702C). Mientras un rótulo está en marcha no sale ningún enemigo nuevo.

## Lo que no es del juego

Entre 0xA2F0 y 0xB2EE hay más texto, `color`, `auto`, `goto`, `list`, `run`, `color 15,4,7`, `cload"`, `cont`.
No lo escribe nadie: son las teclas de función de una copia de la memoria de un MSX que se coló en el cartucho
(ver [Curiosidades](CURIOSIDADES.html)).
