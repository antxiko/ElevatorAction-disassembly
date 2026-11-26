# Curiosidades

## Una copia de la memoria de un MSX dentro del cartucho

El juego acaba en 0xA2EF, con la última nota de la música. A partir de ahí el cartucho no está vacío: de 0xA2F0 a
0xB2EE lleva **una copia de la RAM de un MSX, de 0xF001 a 0xFFFF**, la zona de las variables del sistema. Se
reconoce porque todo cae en su sitio a la vez, con la misma diferencia de 0x4D11:

- de 0xB089 a 0xB1EE, los ganchos del sistema (0xFD9A a 0xFEFF de la RAM), todos con su `ret` (0xC9) de serie;
- en 0xA66F, las rutinas de cambio de slot que la BIOS copia a 0xF380 (`D3 A8 5E 18 03 D3 A8 73 ...`);
- en 0xAB6E, las teclas de función de 0xF87F: `color`, `auto`, `goto`, `list`, `run`, `color 15,4,7`, `cload"`,
  `cont`, `list.`.

Lo más probable es que al grabar la ROM se volcara un trozo de memoria de más del equipo con el que se hizo. Nada
del juego lo lee. Detrás hay ceros hasta 0xB3FF y relleno de 0xFF hasta el final.

## La hora punta

La interrupción cuenta los cuadros de la ronda (0xC3A0) y, a los 0x38 x 256 (unos cuatro minutos), marca 0xC39F
(`int_partida_reloj`, 0x4C50). Desde entonces los enemigos eligen postura como en la ronda 6, la más dura de la
tabla (`enemigo_decide`, 0x64E4): quedarse mucho en una ronda la vuelve más difícil.

## Las puertas rojas se sortean

Las puertas rojas no son siempre las mismas: en cada ronda se eligen al azar de tres grupos de puertas, más cuantas
más rondas (de 5 en la primera a 10 desde la sexta). El ascensor que baja hasta el coche también se sortea entre
cinco, y algunos ascensores salen dobles. Ver [El edificio](EL-EDIFICIO.html).

## Un truco para dar la vuelta a los personajes

Los dibujos de los sprites se cargan dos veces en la VRAM, una normal y otra dada la vuelta, en dos tablas de 2 KB.
Para que el agente mire al otro lado el juego no cambia ni un dibujo: cambia el registro 6 del VDP, que dice dónde
están los dibujos (`dibujos_del_lado`, 0x53C7). Los enemigos no usan el truco: sus dos lados están cargados en las
dos tablas y cada enemigo elige los suyos (0x58 o 0x90) por su cuenta.

## Los sprites parpadean en vez de desaparecer

El MSX solo enseña cuatro sprites por línea. Para que no desaparezca siempre el mismo, la interrupción manda la
tabla de sprites un cuadro en orden y el siguiente al revés (`sprites_a_vram`, 0x7937): los que sobran parpadean.

## Un esperar que no cuenta cuadros

`espera` (0x4E6C), la pausa de las entradas y las salidas, es un bucle vacío de 100 vueltas por unidad: no mira
el reloj del VDP, así que dura lo que tarde el Z80, más lo que le roben las interrupciones que entran por medio.
