"""Lo que se afirma de la ROM, comprobado contra sus bytes.

Corre con la ROM delante y sin ella: cuando no esta, la imagen se rehace desde
las filas defb/defw del listado, que si viaja con el repositorio. Sin la ROM
solo se comprueba lo que cae en datos.
"""

import os
import re
import subprocess
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "elevator.rom")
ASM = os.path.join(RAIZ, "src", "elevator.asm")
NOTAS = os.path.join(RAIZ, "src", "elevator.notes")
ORG = 0x4000
TAM = 32768

FILA = re.compile(r"^\s+def(b|w)\s+([0-9a-fA-F,h ]+)\s*;\s*([0-9a-f]{4})")


def imagen_desde_el_listado():
    img = bytearray(TAM)
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = FILA.match(ln)
            if not m:
                continue
            ancho, cuerpo, dirr = m.group(1), m.group(2), int(m.group(3), 16)
            p = dirr - ORG
            for tok in cuerpo.split(","):
                tok = tok.strip().rstrip("h")
                if not tok:
                    continue
                v = int(tok, 16)
                if ancho == "b":
                    img[p] = v
                    p += 1
                else:
                    img[p] = v & 0xFF
                    img[p + 1] = v >> 8
                    p += 2
    return bytes(img)


def lee():
    if os.path.exists(ROM):
        with open(ROM, "rb") as f:
            return f.read()
    return imagen_desde_el_listado()


def b(a):
    return lee()[a - ORG]


def w(a):
    rom = lee()
    return rom[a - ORG] | (rom[a - ORG + 1] << 8)


def instruccion(dirr):
    """La instruccion del listado en esa direccion (sin el comentario)."""
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = re.match(r"^	(\S.*?)\s*;([0-9a-f]{4})", ln)
            if m and int(m.group(2), 16) == dirr:
                return m.group(1).replace("	", " ").strip()


def texto(a, n):
    """Casilla = letra - 0x30 (el orden de la fuente de la BIOS); 0x10 es el espacio."""
    return "".join(" " if c == 0x10 else chr(c + 0x30) for c in lee()[a - ORG:a - ORG + n])




KANA1 = "をぁぃぅぇぉゃゅょっ・あいうえおかきくけこさしすせそ"
KANA2 = "たちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわん"


def kana(a, n):
    """Las casillas 0x86-0x9F y 0xE0-0xFD son las letras de la BIOS con su mismo numero (final_letras)."""
    out = ""
    for c in lee()[a - ORG:a - ORG + n]:
        if 0x86 <= c <= 0x9F:
            out += KANA1[c - 0x86]
        elif 0xE0 <= c <= 0xFD:
            out += KANA2[c - 0xE0]
        elif c == 0xBE:
            out += "゛"
        elif c == 0x10:
            out += " "
        else:
            out += chr(c + 0x30)
    return out


class Cabecera(unittest.TestCase):
    def test_ab_e_init_en_0x4010(self):
        rom = lee()
        self.assertEqual(rom[:2], b"AB")
        self.assertEqual(w(0x4002), 0x4010)

    def test_son_32_kb(self):
        self.assertEqual(len(lee()), TAM)

    def test_busca_la_segunda_mitad(self):
        # INIT conecta la pagina 2 buscando "AB" en los slots con RDSLT
        self.assertEqual(instruccion(0x4016), "call busca_pagina_2")
        self.assertEqual(instruccion(0x4DA5), "call 00024h")


class LasInterrupciones(unittest.TestCase):
    def test_dos_ganchos_en_h_timi(self):
        self.assertEqual(instruccion(0x494A), "ld hl,04c92h")
        self.assertEqual(instruccion(0x4D19), "ld hl,int_partida")
        self.assertEqual(instruccion(0x494D), "ld (0fda0h),hl")


class LosTextos(unittest.TestCase):
    def test_game_over_y_marcador(self):
        self.assertEqual(bytes(lee()[0x4265 - ORG:0x4265 - ORG + 9]), b"GAME\x00OVER")
        self.assertEqual(bytes(lee()[0x4814 - ORG:0x4814 - ORG + 6]), b"PLAYER")
        self.assertEqual(bytes(lee()[0x47E1 - ORG:0x47E1 - ORG + 5]), b"ROUND")
        self.assertEqual(bytes(lee()[0x4650 - ORG:0x4650 - ORG + 7]), b"0010000")


class ElEdificio(unittest.TestCase):
    def test_once_ascensores_y_58_puertas(self):
        self.assertEqual(instruccion(0x6067), "ld b,00bh")
        self.assertEqual(instruccion(0x676C), "ld b,03ah")
        self.assertEqual(lee()[0x6A99 - ORG], 0xFF)

    def test_puertas_rojas_por_ronda(self):
        t = lee()[0x682A - ORG:0x682A - ORG + 27]
        self.assertEqual([sum(t[3 * k:3 * k + 3]) for k in range(9)], [5, 6, 7, 8, 9, 10, 10, 10, 10])

    def test_puntos(self):
        def puntos(a):
            n = lee()[a - ORG]
            return sum(lee()[a - ORG + 1 + k] * 10 ** k for k in range(n))
        self.assertEqual([puntos(a) for a in (0x710B, 0x710D, 0x7111, 0x7115, 0x7119, 0x711D, 0x7121)],
                         [0, 100, 150, 200, 300, 500, 1000])


class Sonido(unittest.TestCase):
    def test_19_efectos_y_una_musica(self):
        for k in range(19):
            self.assertTrue(0x9AB7 <= w(0x9A8F + 2 * k) < 0x9AF0)
        self.assertEqual(w(0x9AB5), 0x9AF0)
        self.assertEqual(w(0x9AF2), 0)


class LosRestos(unittest.TestCase):
    def test_copia_de_la_ram(self):
        rom = lee()
        # los ganchos de 0xFD9A a 0xFEFF, todos "ret", 0x4D11 bytes por debajo
        self.assertTrue(all(rom[a - ORG] == 0xC9 for a in range(0xFD9A - 0x4D11, 0xFF00 - 0x4D11)))
        self.assertEqual(bytes(rom[0xF87F - 0x4D11 - ORG:0xF87F - 0x4D11 - ORG + 5]), b"color")

    def test_relleno(self):
        self.assertTrue(all(b == 0xFF for b in lee()[0xB400 - ORG:]))


class ElListado(unittest.TestCase):
    def test_densidad_y_flojas(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "densidad.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        m = re.search(r"(\d+) instrucciones, (\d+) comentarios", salida)
        self.assertGreaterEqual(int(m.group(2)) * 100, 40 * int(m.group(1)))
        self.assertIn("---- 0 rutinas por debajo del 10 %", salida)

    def test_ningun_call_sin_nombre(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "sin_bautizar.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        self.assertTrue(salida.startswith("0 rutinas sin bautizar"), salida[:200])

    def test_cada_comentario_en_su_instruccion(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "valida_c.py"), ASM, NOTAS],
            capture_output=True, text=True, check=True).stdout
        self.assertIn("0 fuera de sitio, 0 repetidos", salida)


if __name__ == "__main__":
    unittest.main()
