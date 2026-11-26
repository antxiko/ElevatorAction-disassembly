# mapa.tcl - la ronda 1 montada, para cotejar el mapa del edificio. Sacado del listado:
# el titulo solo lee la barra en titulo_lee_disparo (0x4B1E), cuando ya parpadea "PUSH SPACE KEY". La barra se
# baja la primera vez que el Z80 pasa por ahi y se suelta en titulo_fin (0x4B59). El volcado se hace al pasar
# por 0x42A5 (monta_ronda, justo antes de agente_entra): el edificio, los ascensores, las puertas rojas y el
# cable ya estan en el mapa. Se vuelca la RAM 0xC000-0xDFFF y la VRAM entera, y se sale.
set throttle off
set ::log [open "$::env(SALIDA).log" w]
proc apunta {t} { puts $::log "[machine_info time] $t"; flush $::log }
set ::pulsada 0
proc pulsa {} {
    if {$::pulsada} return
    set ::pulsada 1
    apunta "pulsa en [format %04X [reg PC]]"
    keymatrixdown 8 0x01
}
proc suelta {} { apunta suelta; keymatrixup 8 0x01 }
proc vuelca {} {
    apunta vuelca
    set f [open $::env(SALIDA) wb]
    puts -nonewline $f [debug read_block memory 0xC000 0x2000]
    puts -nonewline $f [debug read_block VRAM 0x0000 0x4000]
    close $f
    exit
}
debug set_bp 0x4B1E {} pulsa
debug set_bp 0x4B59 {} suelta
debug set_bp 0x42A5 {} vuelca
after time 120 { apunta tiempo; exit }
