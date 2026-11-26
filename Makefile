# Elevator Action - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# La ROM no se distribuye: hace falta en la raiz como elevator.rom, y
# `make comprueba` verifica su sha256.

JUEGO    = elevator
ROM      = $(JUEGO).rom
SHA      = 9d1fd065ec5c0453acf7c06e66e9c5d1aaf4026972fde73f862fbda9715b4f0b
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = Elevator Action - ROM de 32 KB en 0x4000

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Elevator Action (Taito, 1985) para MSX, 32768 bytes."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -destinos de saltos indirectos- estan declarados en el
# .entries, cada uno con su justificacion.
$(WORK)/$(JUEGO).trace.json: $(ROM) $(SRC)/$(JUEGO).entries $(SRC)/$(JUEGO).nocode
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/$(JUEGO).entries \
	        $(WORK)/$(JUEGO) $(SRC)/$(JUEGO).nocode

trace: $(WORK)/$(JUEGO).trace.json

listado: $(WORK)/$(JUEGO).trace.json $(SRC)/$(JUEGO).notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/$(JUEGO).trace.json \
	        $(SRC)/$(JUEGO).notes work/msx.sym $(SRC)/$(JUEGO).asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable: el listado da la ROM.
verify: $(SRC)/$(JUEGO).asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/$(JUEGO).asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/$(JUEGO).trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/$(JUEGO).trace.json $(SRC)/$(JUEGO).nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/$(JUEGO).entries $(SRC)/$(JUEGO).notes \
	        $(SRC)/$(JUEGO).nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 tools/densidad.py $(SRC)/$(JUEGO).asm

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

clean:
	rm -rf $(WORK)/$(JUEGO).trace.json $(WORK)/$(JUEGO).blocks

.PHONY: all comprueba trace listado verify sanity test densidad clean


