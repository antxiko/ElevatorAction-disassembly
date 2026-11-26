# Elevator Action - desensamblado comentado

*(Also [in English](README.md).)*

El desensamblado comentado de **Elevator Action** (Taito, 1985) para MSX: un cartucho de 32 KB con la cabecera en 0x4000.

- **100 %** del binario explicado: 13.361 bytes de código y 19.407 de datos con nombre, ni un byte sin asignar.
- **49,9 %** del listado comentado, 857 rutinas y etiquetas, ninguna por debajo del 10 % de comentarios.
- El listado se reensambla en la ROM original **byte a byte**.
- El edificio sale de ejecutar la ROM, cotejado con la RAM de openMSX tile a tile; la música y los efectos, de su propio motor de sonido (`make musica`).
- Las puertas rojas y el ascensor del sótano se sortean en cada ronda, y el cartucho lleva dentro una copia de la memoria del MSX con el que se grabó.

La web: <https://antxiko.github.io/ElevatorAction-disassembly/es/>
(en inglés: <https://antxiko.github.io/ElevatorAction-disassembly/>).

## Reproducirlo

La imagen de la ROM no se distribuye. Pon la tuya en la raíz como `elevator.rom` (el volcado `[!]` de GoodMSX, sha1 `6cbddd11...`) y ejecuta `make`. El detalle, en [POR DENTRO](docs/es/POR-DENTRO.md).

## Legal

El juego es de Taito y de sus titulares. La licencia de `LICENSE` cubre solo las herramientas, los comentarios, el análisis y la documentación de aquí. Mira [AVISO-LEGAL.md](AVISO-LEGAL.md).
