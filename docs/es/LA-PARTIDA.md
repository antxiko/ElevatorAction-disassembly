# La partida

Un espía entra por la azotea de un edificio de treinta plantas y tiene que llegar al coche que le espera en el sótano.
Por el camino hay puertas rojas con documentos: si llega abajo sin haberlas abierto todas, un ascensor le sube otra
vez a por ellas. De las puertas azules salen agentes enemigos que disparan, saltan y se agachan.

## Los mandos

| tecla | qué hace | dónde se lee |
|---|---|---|
| cursores o joystick | andar, agacharse, mover el ascensor arriba o abajo | `agente_direccion`, 0x518A |
| `x` o el segundo botón | saltar | `agente_mando`, 0x50F2 |
| `z` o el primer botón | disparar (una bala por pulsación, tres a la vez como mucho) | `agente_dispara`, 0x531E |
| barra | empezar, en el título | `titulo_lee_disparo`, 0x4B1E |

Las teclas `x` y `z` se leen directamente de la matriz del teclado con SNSMAT (tabla 0x4917: fila 5, bits 5 y 7).

## Una ronda

En la ronda 1 el agente llega por un cable tendido hasta la azotea (`entrada_cable`, 0x716C); en las demás aparece ya
arriba. Baja andando hasta el ascensor del tejado y desde ahí el edificio se recorre con:

- **Ascensores.** Dentro de la cabina, arriba y abajo la mueven; también se puede ir de pie encima del techo, y un
  ascensor que baja aplasta a quien esté debajo.
- **Escaleras mecánicas.** Solo en las plantas 20 a 16. Se suben o se bajan pulsando arriba o abajo al pie de cada
  tramo, en siete pasos.
- **Puertas.** Delante de una puerta y mirándola, el agente entra. En una roja recoge los documentos (500 puntos) y la
  puerta pasa a ser azul; en una azul se queda escondido hasta que se mueve el mando o pasan 255 cuadros.

Al llegar al sótano con todas las puertas rojas abiertas, el agente sube al coche y se va: **bonus de 1000 puntos por
ronda**, hasta 9.000 a partir de la novena. La ronda siguiente es el mismo edificio con otros colores y otras puertas
rojas.

## Los puntos

| qué | puntos | dónde |
|---|---:|---|
| un enemigo de un disparo | 100 (150 a oscuras, o con la vista entre las filas 0x5E y 0x7A del mapa) | 0x6E08 |
| un enemigo de una patada en el salto | 150 (200 en los mismos casos) | 0x6B6B |
| un enemigo bajo la lámpara que cae, o aplastado por un ascensor | 300 | 0x6B16, 0x6378 |
| los documentos de una puerta roja | 500 | 0x5087 |
| el bonus de la ronda | 1000 por ronda, como mucho 9000 | 0x416B |

La vida extra sale una sola vez, al llegar a 10.000 (`bucle_juego`, 0x4065). La partida empieza con dos vidas de
reserva.

## Las maneras de morir

Tres, cada una con su postura (`agente_muere`, 0x4EF9): caer por el hueco de un ascensor, recibir un disparo y que un
ascensor le baje encima. Al perder una vida el agente vuelve unas plantas más arriba, en una fila múltiplo de seis
(`vida_perdida`, 0x419B). Sin vidas, GAME OVER y, si hay récord, se guarda.

## La lámpara

Una bala que llega a una lámpara del techo la rompe: la lámpara cae en cuatro pasos y mata al enemigo que pille debajo,
y a los diez cuadros el edificio se queda a oscuras durante 240 cuadros con otros colores (`luces_cuadro`, 0x7D67).
