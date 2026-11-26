#!/usr/bin/env python3
"""EL CONTENIDO de la web de esta ROM: lo unico que es de este juego.

jekyll.py y make_web.py son la maquinaria y no llevan dentro el nombre de
ningun juego: lo leen de aqui.

Todas las cifras de aqui estan medidas sobre esta ROM, con las herramientas
de tools/: CODIGO y DATOS los imprime tools/presupuesto.py (make sanity),
INSTRUCCIONES, COMENTARIOS y RUTINAS los da tools/densidad.py (make densidad:
"de N" rutinas, "N instrucciones, M comentarios").
"""

NOMBRE = "Elevator Action"
EDITOR = "Taito"
ANIO = 1985
REPOSITORIO = "https://github.com/antxiko/ElevatorAction-disassembly"
SHA1 = "6cbddd118afe63e79cb8a40f8aa879df1c7590e1"

CODIGO = 13361
DATOS = 19407
RUTINAS = 857
INSTRUCCIONES = 6356
COMENTARIOS = 3173


def densidad(idioma):
    """El porcentaje comentado, con la coma o el punto de cada idioma."""
    d = "%.1f" % (100.0 * COMENTARIOS / INSTRUCCIONES)
    return d.replace(".", ",") if idioma == "es" else d


PIE_LEGAL = {
    "es": "<em>Elevator Action</em> es un juego de Taito para MSX, de 1985, en un cartucho de 32 KB. Todos los "
          "derechos sobre el juego siguen siendo de sus titulares. Este trabajo es de preservaci&oacute;n, estudio y "
          "documentaci&oacute;n, y la imagen de la ROM no se distribuye.",
    "en": "<em>Elevator Action</em> is a 1985 Taito game for the MSX, on a 32 KB cartridge. All rights in the game "
          "remain with their holders. This is preservation, study and documentation work, and the ROM image is not "
          "distributed.",
}

PORTADA = {
    "es": dict(
        titulo="Elevator Action - desensamblado comentado",
        claim="Un esp&iacute;a baja un rascacielos de treinta plantas, de la azotea al coche del s&oacute;tano, "
              "recogiendo los documentos de las puertas rojas y esquivando a los agentes que salen de las azules. "
              "El edificio sale de ejecutar la ROM, cotejado con openMSX tile a tile; la m&uacute;sica, de su propio "
              "motor de sonido.",
        ficha=["Taito - <b>(c) 1985</b>",
               "Cartucho de <b>32 KB</b> (cabecera en 0x4000)",
               "<b>MSX</b>", "Volcado <b>6cbddd11...</b>"],
        aviso="<b>Aqu&iacute; no hay capturas del juego.</b> El edificio sale de <b>ejecutar la ROM</b> en un Z80 "
              "escrito en Python y <b>c&oacute;digo nuestro lo pinta</b>; se ha cotejado con la RAM de openMSX.",
    ),
    "en": dict(
        titulo="Elevator Action - commented disassembly",
        claim="A spy works his way down a thirty-storey building, from the roof to the car in the basement, picking "
              "up the documents behind the red doors and dodging the agents who come out of the blue ones. The "
              "building comes from running the ROM, checked against openMSX tile by tile; the music, from its own "
              "sound engine.",
        ficha=["Taito - <b>(c) 1985</b>",
               "<b>32 KB</b> cartridge (header at 0x4000)",
               "<b>MSX</b>", "Dump <b>6cbddd11...</b>"],
        aviso="<b>There are no screenshots of the game here.</b> The building comes from <b>running the ROM</b> on a "
              "Z80 written in Python and <b>our own code paints it</b>; it has been checked against openMSX's RAM.",
    ),
}

PAGINAS = [
    [("THE-GAME.html", "LA-PARTIDA.html", "The game", "La partida",
      "the controls, the rounds, the doors, the lifts, the escalators, the points and the ways to die",
      "los mandos, las rondas, las puertas, los ascensores, las escaleras, los puntos y las maneras de morir"),
     ("THE-BUILDING.html", "EL-EDIFICIO.html", "The building", "El edificio",
      "the thirty floors and the basement, run from the ROM; the eleven lifts and the 58 doors",
      "las treinta plantas y el s&oacute;tano, ejecutando la ROM; los once ascensores y las 58 puertas"),
     ("THE-SPRITES.html", "LOS-SPRITES.html", "The sprites", "Los sprites",
      "every drawing, who puts it on screen and in which pose", "cada dibujo, qui&eacute;n lo pone y en qu&eacute; postura"),
     ("THE-TEXTS.html", "LOS-TEXTOS.html", "The texts", "Los textos",
      "every text in the ROM", "todos los textos de la ROM"),
     ("THE-MUSIC.html", "LA-MUSICA.html", "The music", "La m&uacute;sica",
      "the tune and the jingles, from its own sound engine", "la m&uacute;sica y las melod&iacute;as, de su propio motor")],
    [("CURIOSITIES.html", "CURIOSIDADES.html", "Curiosities", "Curiosidades",
      "a copy of an MSX's memory inside the cartridge, the rush hour, the red doors drawn by lot",
      "una copia de la memoria de un MSX dentro del cartucho, la hora punta, las puertas rojas a sorteo"),
     ("SECRETS-AND-BUGS.html", "SECRETOS-Y-FALLOS.html", "Secrets and bugs", "Secretos y fallos",
      "code nobody calls, a counter nobody reads and a copy that goes too far",
      "c&oacute;digo que nadie llama, una cuenta que nadie lee y una copia que se pasa")],
    [("UNDER-THE-HOOD.html", "POR-DENTRO.html", "Under the hood", "Por dentro",
      "rebuilding the ROM, the cartridge, the BIOS it uses, the loop, the RAM and the tools",
      "rehacer la ROM, el cartucho, la BIOS que usa, el bucle, la RAM y las herramientas")],
]

# Repositorio nuevo: no hay paginas viejas que redirigir.
VIEJAS = {}

LOGOTIPO = "edificio_cabecera.png"
