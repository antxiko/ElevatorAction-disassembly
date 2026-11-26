# Secretos y fallos

No hay trucos ni pantallas escondidas: el juego no lee más teclas que los cursores, `x`, `z` y la barra
(tabla 0x4917 y `lee_mando`, 0x48CF). Lo que sí hay es código que no se usa y tres descuidos.

## Código que nadie llama

En todo el cartucho no hay un solo salto indirecto (ni `jp (hl)` ni direcciones metidas en la pila), así que un
trozo de código al que ningún `call` ni `jp` lleva no se ejecuta nunca. Hay cinco:

| dónde | qué hace |
|---|---|
| 0x4C0B | escribe un texto letra a letra con una espera entre ellas |
| 0x4E06 | una división y una multiplicación de 16 bits |
| 0x65D5 | mira si una puerta queda a la izquierda o a la derecha de un personaje |
| 0x78CD | **mueve al agente y la vista varias plantas de golpe**, arriba o abajo según una tabla (0x7925), una sola vez: parece una ayuda para probar el juego |
| 0x7F72 | pone una lista de piezas del edificio |

Y dos bytes sueltos en 0x5A8A (`and a` / `ret`) entre dos rutinas, que el flujo salta.

## Fallo: la lámpara corrida en la ronda 1

Los dibujos de la lámpara que cae (0xD0, 0xD4 y 0xD8) y los del agente colgado del cable comparten sitio en la
VRAM (0x2680). Al acabar la entrada por el cable de la ronda 1, el juego repone los de la lámpara desde 0x925C
(`cable_quita_fila`, 0x7295). Pero ese bloque de la ROM empieza en 0x921C con **dos bytes de largo delante**: los
dibujos buenos están en 0x925E. La copia sale corrida dos bytes, y 26 de los 96 son distintos.

Comprobado en openMSX (`tools/guiones/mapa.tcl`): justo después del cable, la VRAM de 0x2680 y de 0x2E80 tiene la
copia de 0x925C y no la de 0x925E. Dura toda la ronda 1, también tras perder una vida; desde la ronda 2 la carga
de la ronda (`monta_edificio`) los vuelve a poner bien.

## Una cuenta que nadie lee

Cada vez que se suman puntos, `cuenta_por_puntos` (0x6F4C) calcula las decenas de millar y lleva una cuenta en
0xC0D4. Nada más en el cartucho lee 0xC0D4: solo se pone a cero al empezar la partida. Tiene toda la pinta de
unas vidas extra por cada tantos puntos que se quedaron a medias. La única vida extra es la de los 10.000
(`bucle_juego`, 0x4065), y como mira solo si la cifra de las decenas de millar es un 1, se da una vez y no más.

## Una copia que se pasa

Al cargar los gráficos de la ronda, el bloque de las balas y la lámpara, de 0x1C0 bytes, se copia a la segunda
tabla de sprites con un largo de **0x9C0** (`monta_edificio`, 0x474E): de 0x2E40 hasta 0x3800, con lo que hubiera
en la RAM detrás del bloque. No se nota, porque esa VRAM (0x3000 a 0x37FF) no la usa nada.
