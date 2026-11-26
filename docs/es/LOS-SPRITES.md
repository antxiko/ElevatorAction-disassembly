# Los sprites

Los sprites son de 16x16 (registro 1 del VDP = 0xE2) y sus dibujos se cargan al montar cada ronda
(`monta_edificio`, 0x4691): el agente (22 dibujos, 0x8D98), el enemigo (14, 0x905A) y el resto (balas, lámpara,
0x921C). Cada bloque se copia dos veces, una tal cual a la tabla 0x2000 y otra dada la vuelta a la tabla 0x2800
(`espejo_bytes`, 0x4657, y `espejo_sprites`, 0x466B): para mirar al otro lado, el juego no cambia de dibujo, cambia el
**registro 6 del VDP** de 4 a 5 (`dibujos_del_lado`, 0x53C7). Eso solo vale para el agente: el enemigo lleva sus
dos lados en las dos tablas (el normal desde 0x58 y el dado la vuelta desde 0x90) y su propia tabla para cada lado.

Cada personaje lleva en su ficha un puntero a su tabla de dibujos. La postura es un bit (1 de pie, 2 andando,
4 agachado, 8 en el aire, 0x10 en una puerta, 0x20 aplastado, 0x40 cayendo, 0x80 tiroteado) y el cuadro, un
número; cada cuadro es una lista de sprites con su dibujo, su color y lo que se baja la Y, hasta 0xFF
(`pon_sprites`, 0x5721).

## El agente (tabla 0x5856, y 0x584E disparando)

| postura | cuadros | dibujos | disparando |
|---|---|---|---|
| de pie | 1 | 0x04, 0x08, 0x0C | 0x14, 0x18, 0x1C |
| andando | 2 | 0x04, 0x08, 0x0C / 0x04, 0x08, 0x10 | 0x14, 0x18, 0x1C / 0x14, 0x18, 0x20 |
| agachado | 1 | 0x24, 0x28 | 0x2C, 0x30 |
| en el aire | 4 | 0x04, 0x34, 0x38 / 0x34, 0x3C (x2) / 0x04, 0x34, 0x38 | 0x34, 0x40 en los del medio |
| entrando en una puerta | 6 | los de andar, y vacío al abrir y cerrar | |
| aplastado | 3 | 0xE8, 0xEC / 0xF0, 0xF4 / 0xE4 | |
| cayendo | 4 | 0x34, 0x3C / 0x50, 0x54 / 0x34, 0x3C / 0xE4 | |
| tiroteado | 4 | 0x44, 0x48, 0x4C / 0x50, 0x54 / 0x34, 0x3C / 0x50, 0x54 | |

En la escalera mecánica no se usa la tabla: `agente_dos_sprites` (0x5B7D) y `agente_tres_sprites` (0x5B98) ponen a
mano los dibujos 0x04, 0x08 y 0x0C, y para esconder las piernas tras el escalón `piernas_fuera` (0x7BA8) cambia dos
bytes de los propios dibujos en la VRAM.

## El enemigo (tablas 0x6894 a la derecha y 0x68A4 a la izquierda; 0x6884 y 0x688C disparando)

| postura | cuadros | a la derecha | disparando | a la izquierda | disparando |
|---|---|---|---|---|---|
| de pie | 1 | 0x58, 0x5C | 0x68, 0x5C | 0x90, 0x94 | 0xA0, 0x94 |
| andando | 2 | 0x58, 0x5C / 0x60, 0x64 | 0x68, 0x5C / 0x6C, 0x64 | 0x90, 0x94 / 0x98, 0x9C | 0xA0, 0x94 / 0xA4, 0x9C |
| agachado | 1 | 0x70 | 0x74 | 0xA8 | 0xAC |
| en el aire | 1 | 0x84 | | 0xBC | |
| saliendo de una puerta | 6 | los de andar | | los de andar | |
| aplastado | 3 | 0xF8 / 0xFC / 0xE4 | | los mismos | |
| cayendo y tiroteado | 3 | 0x78, 0x7C / 0x80 / 0xE4 | | 0xB0, 0xB4 / 0xB8 / 0xE4 | |

En la escalera mecánica pone 0xC8 o 0xCC (el cuerpo según el lado) y, al final del tramo, 0x58 y 0x5C
(`enemigo_escalera_piernas`, 0x5DF9).

## Lo demás

| qué | dibujos | quién |
|---|---|---|
| las balas, volando y al chocar | 0x88 y 0x8C (del agente), 0xC0 y 0xC4 (de los enemigos) | tabla 0x6EB6 |
| la lámpara que cae | 0xD0, 0xD4 y 0xD8 | `lampara_sprites`, 0x7E13 |
| dos sprites fijos, abajo a la izquierda | 0xDC y 0xE0 | `agente_entra`, 0x4E7C (tabla 0x4EAF) |
| el agente colgado del cable (ronda 1) | 0xD0, 0xD4 y 0xD8: sus dibujos (0x7329) se cargan encima de los de la lámpara y luego se reponen (0x925C) | `entrada_cable`, 0x716C |
| el coche del sótano | 0x20 a 0x3C, cargados a 0x2100 al acabar la ronda | `coche_anima`, 0x7980 |

El coche se carga encima de los dibujos del agente porque en ese momento el agente ya no se pinta con ellos: va
dentro del coche, hecho con cinco sprites de la tabla 0x7BD9.
