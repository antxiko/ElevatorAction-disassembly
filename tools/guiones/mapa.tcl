# mapa.tcl - la ronda 1 montada, para cotejar el mapa del edificio. Sacado del listado:
# el titulo solo lee la barra (titulo_lee_disparo, 0x4B1E) cuando ya parpadea "PUSH SPACE KEY": el bit 2 de 0xC357.
# Se mira cada medio segundo y entonces se pulsa. El volcado se hace al pasar por 0x42A5 (monta_ronda, justo
# antes de agente_entra): el edificio, los ascensores, las puertas rojas y el cable ya estan en el mapa.
# Se vuelca la RAM 0xC000-0xDFFF y la VRAM entera, y se sale.
set throttle off
set ::pulsada 0
set ::log [open "$::env(SALIDA).log" w]
proc apunta {t} { puts $::log "[machine_info time] $t"; flush $::log }
proc mira {} {
    apunta "C357=[peek 0xC357] C0D6=[peek 0xC0D6] PC=[reg PC]"
    if {!$::pulsada && ([peek 0xC357] & 0x04)} {
        set ::pulsada 1
        apunta pulsa
        keymatrixdown 8 0x01
        after time 0.3 { keymatrixup 8 0x01 }
        return
    }
    after time 0.5 mira
}
after time 1 mira
proc vuelca {} {
    apunta vuelca
    set f [open $::env(SALIDA) wb]
    puts -nonewline $f [debug read_block memory 0xC000 0x2000]
    puts -nonewline $f [debug read_block VRAM 0x0000 0x4000]
    close $f
    exit
}
debug set_bp 0x42A5 {} vuelca
after time 120 { apunta tiempo; exit }
