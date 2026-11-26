#!/usr/bin/env python3
"""El sonido del cartucho EJECUTANDO su propio motor (ver motor_musica.py).

`sonido` (0x7580) pide: con el bit 7 la musica (solo hay una, la 0x80, en los canales B y C), si no un efecto del
canal A (0x00-0x12) con su prioridad. `sonido_cuadro` (0x75EC) es el motor: la interrupcion de la partida lo llama
un cuadro de cada dos, asi que corre a 30 por segundo. Escribe el PSG con WRTPSG (0x0093), que se atrapa.
`sonido_apaga` (0x7555) va antes, como en el juego.

Uso:  musica.py registros N [cuadros] | mp3 N f.mp3 | todas docs/audio | lista
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (numero, fichero, quien la pide)
MUSICAS = [
    (0x80, "musica_fondo.mp3", "la partida (0x4042), en cada vida"),
    (0x0D, "sonido_cable.mp3", "la entrada de la ronda 1: el cable (0x7174)"),
    (0x10, "sonido_desliza.mp3", "el agente baja por el cable (0x7200)"),
    (0x11, "sonido_azotea.mp3", "el agente llega a la azotea (0x7263)"),
    (0x0A, "sonido_documentos.mp3", "los documentos de una puerta roja (0x508D) y el bonus (0x415B)"),
    (0x0E, "sonido_coche.mp3", "el agente sube al coche (0x7A5E)"),
    (0x0C, "sonido_game_over.mp3", "GAME OVER (0x4242)"),
]


def cfg():
    return dict(rom="elevator.rom", org=0x4000, sp=0xF300, frame=0x75EC, pide=0x7580,
                init=[(0x7555, {})], ram=(0xC3A4, 0xC3DC), hz=30, max_s=200, cuadros_previos=0)


def rom():
    return open(os.path.join(RAIZ, "elevator.rom"), "rb").read()


def sonando(z):
    """Algun canal con nota: las tres fichas (0xC3AC, 0xC3B6, 0xC3C0) con duracion."""
    return any(z.mem[f + 6] or z.mem[f + 7] for f in (0xC3AC, 0xC3B6, 0xC3C0))


def ejecuta(numero, maximo=None):
    import hashlib
    c = cfg()
    maximo = maximo or c["hz"] * c["max_s"]
    z = motor_musica.arranca(c, rom(), numero)
    a, b = c["ram"]
    cuadros, vistos = [], {}
    for k in range(maximo):
        cuadros.append(motor_musica.cuadro(z))
        h = hashlib.sha1(bytes(z.mem[a:b])).digest()
        if h in vistos:
            return cuadros, (None if vistos[h] == k else vistos[h])
        vistos[h] = k + 1
        if k > 2 and not sonando(z):
            return cuadros, None
    return cuadros, None


def mp3(numero, ruta):
    hz = cfg()["hz"]
    cuadros, vuelta = ejecuta(numero)
    todo, fundido = motor_musica.desarrolla(cuadros, vuelta, hz)
    motor_musica.a_mp3(motor_musica.sintetiza(todo, hz), ruta, fundido, hz)
    print("%-24s %4d cuadros (%.1f s), vuelve al %s" % (os.path.basename(ruta), len(cuadros),
                                                        len(cuadros) / hz, vuelta))


def main(argv):
    if argv and argv[0] == "lista":
        for n in list(range(0x13)) + [0x80]:
            cuadros, vuelta = ejecuta(n)
            print("0x%02X %4d cuadros (%.1f s) vuelta %s" % (n, len(cuadros), len(cuadros) / 30, vuelta))
        return 0
    if argv and argv[0] == "todas":
        os.makedirs(argv[1], exist_ok=True)
        for numero, fichero, _ in MUSICAS:
            mp3(numero, os.path.join(argv[1], fichero))
        return 0
    if argv and argv[0] == "mp3":
        mp3(int(argv[1], 0), argv[2])
        return 0
    if argv and argv[0] == "registros":
        cuadros, vuelta = ejecuta(int(argv[1], 0), int(argv[2]) if len(argv) > 2 else None)
        for i, escr in enumerate(cuadros):
            print("%5d %s" % (i, " ".join("%X=%02X" % rv for rv in escr)))
        print("cuadros: %d, vuelve al %s" % (len(cuadros), vuelta))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
