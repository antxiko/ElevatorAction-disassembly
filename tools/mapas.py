#!/usr/bin/env python3
"""El edificio EJECUTANDO la ROM: monta_edificio (0x4691) carga patrones y colores, dibuja_edificio (0x7E91) pinta
el mapa en 0xC400, ascensores_nuevos (0x605A) y puertas_nuevas (0x6765) ponen ascensores y puertas rojas (al azar,
con el registro R: es una ronda posible). Se pinta el mapa entero con los patrones de la VRAM y cada juego de colores
(0x8D18 rondas 1-4-7, 0x8D38 2-5-8, 0x8D58 3-6-9, 0x8D78 a oscuras). Cotejado con openMSX (tools/guiones/mapa.tcl):
lo fijo sale igual tile a tile; cambia solo lo sorteado.

Uso: mapas.py <carpeta>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bios import Msx  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAL = [(0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120), (84, 85, 237), (125, 118, 252), (212, 82, 77),
       (66, 235, 245), (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128), (33, 176, 59),
       (201, 91, 186), (204, 204, 204), (255, 255, 255)]
COLORES = [(0x8D18, "edificio_colores_1"), (0x8D38, "edificio_colores_2"), (0x8D58, "edificio_colores_3"),
           (0x8D78, "edificio_a_oscuras")]
FILAS = (6, 214)          # de la antena al sotano


def monta(ronda=1):
    rom = open(os.path.join(RAIZ, "elevator.rom"), "rb").read()
    m = Msx(rom, 0x4000)
    m.mem[0xC081] = ronda
    for r in (0x4691, 0x7E91, 0x605A, 0x6765):
        m.llama(r)
    return rom, bytes(m.mem[0xC400:0xE000]), bytes(m.vdp.vram)


def pinta(mapa, vram, colores, f0=FILAS[0], f1=FILAS[1]):
    from PIL import Image
    img = Image.new("RGB", (256, (f1 - f0) * 8))
    px = img.load()
    for f in range(f0, f1):
        for c in range(32):
            t = mapa[f * 32 + c]
            col = colores[t // 8]
            for y in range(8):
                b = vram[t * 8 + y]
                for x in range(8):
                    px[c * 8 + x, (f - f0) * 8 + y] = PAL[col >> 4] if b & (0x80 >> x) else PAL[col & 15]
    return img


def main(salida):
    os.makedirs(salida, exist_ok=True)
    rom, mapa, vram = monta()
    for d, nombre in COLORES:
        col = rom[d - 0x4000:d - 0x4000 + 32]
        img = pinta(mapa, vram, col)
        img.save(os.path.join(salida, nombre + ".png"))
        print(nombre, img.size)
        if nombre == "edificio_colores_1":
            # la cabecera de la web: la antena, el tejado y las plantas 30 a 28
            cab = img.crop((0, 0, 256, 160)).resize((512, 320), 0)
            cab.save(os.path.join(salida, "edificio_cabecera.png"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "docs/imagenes"))
