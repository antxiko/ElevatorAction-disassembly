# Por dentro

## Rehacer la ROM

El repositorio no trae el juego. Con la ROM en la raíz como `elevator.rom` (32.768 bytes, sha1
`6cbddd118afe63e79cb8a40f8aa879df1c7590e1`), `make all` traza el código, genera el listado, lo vuelve a
ensamblar con pasmo y comprueba que sale **la misma ROM byte a byte**; después pasan los tests. Hace falta
`pasmo`, `z80dasm`, `make` y Python 3.

| | |
|---|---|
| código | 13.361 bytes |
| datos | 19.407 bytes |
| instrucciones | 6.356, de las que 3.173 llevan comentario (49,9 %) |
| rutinas con nombre | 857 |

El listado sale de `src/elevator.notes` (los nombres y comentarios), `src/elevator.entries` (los puntos de
entrada que el trazado no deduce: el arranque y las dos interrupciones) y `src/elevator.nocode` (la cabecera).

## El cartucho

32 KB planos de 0x4000 a 0xBFFF, sin mapper. La cabecera solo tiene `AB` e INIT (0x4010). Lo primero que hace el
arranque es buscar en qué slot está la segunda mitad del cartucho y conectarla en 0x8000 con ENASLT
(`busca_pagina_2`, 0x4D59): compara `AB`, la dirección de INIT y los dos primeros bytes del arranque leyéndolos
con RDSLT en cada slot y subslot.

| zona | qué hay |
|---|---|
| 0x4010-0x7F71 | el código |
| 0x7F8D-0x8515 | el edificio: plantas y piezas |
| 0x8516-0x93DD | los patrones, los colores y los sprites de la partida |
| 0x949A-0x9A8E | el título: textos, patrones y colores comprimidos, sprites |
| 0x9A8F-0xA2EF | el sonido: 19 efectos y la música |
| 0xA2F0-0xB2EE | una copia de la RAM de un MSX (ver [Curiosidades](CURIOSIDADES.html)) |
| 0xB2EF-0xBFFF | ceros y relleno de 0xFF |

## La BIOS que usa

WRTVDP (0x47), FILVRM (0x56), LDIRVM (0x5C), SETGRP (0x7E) e INIGRP (0x72) para el título, GTSTCK (0xD5),
GTTRIG (0xD8), SNSMAT (0x141), RDPSG (0x96), WRTPSG (0x93), GICINI (0x90), RDSLT (0x0C), ENASLT (0x24) y
DCOMPR (`rst 20h`).

## El modo de pantalla

El título es SCREEN 2 con las tablas de la BIOS; la partida, GRAPHIC 1 (SCREEN 1) con tablas propias
(`vdp_modo_juego`, 0x4572): nombres en 0x1000, colores en 0x3FC0, patrones en 0x0000, atributos de sprites en
0x3F00 y dibujos en 0x2000 (o 0x2800, dados la vuelta). Sprites de 16x16.

## Dos interrupciones

El juego cuelga su rutina del gancho H.TIMI (0xFD9F). En el título es `int_titulo` (0x4C92), que vuelca el mapa y
lleva la cuenta de la animación; al pulsar la barra se cambia a sí misma por `int_partida` (0x4C26). Esta, en
cuadros alternos, manda los sprites, vuelca el mapa si ha cambiado, escribe el marcador y mueve el sonido; en todos,
baja los 50 temporizadores de 0xC09E (`temporizadores_cuadro`, 0x4DC3) y lleva el reloj de la ronda.

## El bucle de la partida

`bucle_juego` (0x4047) hace en cada vuelta: el rótulo que se despliega, el agente, los enemigos, los ascensores,
las balas, los balazos, las luces, la lámpara y la patada, el scroll y los sprites al buffer. Después mira la vida
extra, si el agente sigue vivo y si ha llegado al sótano.

## La RAM

| dónde | qué |
|---|---|
| 0xC000-0xC07F | la copia de la tabla de sprites |
| 0xC080-0xC096 | avisos, ronda, puntos (7 cifras ASCII), vidas y récord |
| 0xC09E-0xC0CF | los 50 temporizadores |
| 0xC0D0-0xC0D3 | el scroll: bits, desplazamiento y fila |
| 0xC0D8 | el agente (10 bytes) |
| 0xC0EC | los 11 ascensores (10 bytes cada uno) |
| 0xC16E | las 58 puertas (5 bytes) |
| 0xC29A, 0xC2B8 | las 3 balas del agente y las 4 de los enemigos |
| 0xC2E0 | los 4 enemigos |
| 0xC308 | el rótulo que se despliega |
| 0xC3A4-0xC3DB | el sonido: peticiones, tres canales y la copia del PSG |
| 0xC400-0xDFFF | el mapa del edificio |

## Las herramientas

`tools/z80trace.py` traza el código, `tools/mkasm.py` monta el listado, `tools/verify_build.sh` lo reensambla y
compara. `tools/z80run.py` y `tools/bios.py` son un Z80 y un MSX1 en Python con los que se ejecutan la ROM y su
motor de sonido (`tools/mapas.py`, `tools/musica.py`); `tools/guiones/mapa.tcl` es el guion de openMSX con el que
se ha cotejado el mapa.
