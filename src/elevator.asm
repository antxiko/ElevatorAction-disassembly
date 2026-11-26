; ==========================================================================
; Elevator Action - ROM de 32 KB en 0x4000
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera: "AB", INIT 0x4010 y el resto a cero (sin STATEMENT, DEVICE
;   ni TEXT)
;   0x4000..0x4010  (16 bytes)
DATA_cabecera:
	defb 041h,042h,010h,040h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 4000  AB.@............

; ======================================================================
; CODIGO 0x4010..0x4262  (594 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  Arranque y bucle principal  =====
; ----------------------------------------------------------------------
inicio:		; INIT del cartucho: pila, RAM a cero y al titulo
	di			;4010   ; sin interrupciones mientras se monta todo
	ld sp,0f300h		;4011   ; la pila, justo debajo de las variables del sistema
	im 1		;4014   ; interrupciones en modo 1: la BIOS en 0x38
	call busca_pagina_2		;4016   ; la segunda mitad del cartucho en 0x8000
	ld hl,0c000h		;4019   ; la RAM del juego, 0xC000-0xEFFF...
	ld bc,03000h		;401c   ; ...12 KB...
	sub a			;401f   ; ...a cero
	call rellena_bc		;4020   ; 0xC000-0xEFFF a cero
al_titulo:		; Titulo y demostracion hasta que se pulsa; luego partida nueva
	call titulo		;4023   ; el titulo (vuelve al pulsar)
	call vdp_modo_juego		;4026   ; GRAPHIC 1 con las tablas del juego
	call partida_nueva		;4029   ; partida nueva: ronda 1, vidas y marcador
ronda_nueva:		; Monta el edificio de la ronda y deja al agente en la azotea
	call monta_ronda		;402c   ; pinta el edificio y baja al agente
	jr a_jugar		;402f   ; a jugar
vida_nueva:		; El agente vuelve a entrar tras perder una vida
	call agente_entra		;4031   ; el agente en el ascensor de la planta
	call suelta_ascensores		;4034   ; los ascensores, sin el bit del agente
	ld bc,0e201h		;4037   ; pantalla encendida, con interrupcion
	call escribe_vdp		;403a   ; al VDP
	ld a,001h		;403d   ; se juega
	ld (0c0d6h),a		;403f   ; 0xC0D6 = 1: la interrupcion trabaja
a_jugar:		; Musica de fondo y bucle de un cuadro
	ld a,080h		;4042   ; la musica (0x80, la unica)
	call sonido		;4044   ; pedida
bucle_juego:		; Un cuadro de partida: mueve todo y mira si se acaba la vida o la ronda
	call rotulo_cuadro		;4047   ; el rotulo que se despliega, si hay
	call agente_cuadro		;404a   ; el agente
	call enemigos_cuadro		;404d   ; los enemigos
	call ascensores_cuadro		;4050   ; los ascensores
	call balas_cuadro		;4053   ; las balas
	call balazos		;4056   ; quien recibe un balazo
	call luces_cuadro		;4059   ; las luces y la lampara que cae
	call golpes_al_enemigo		;405c   ; la lampara y la patada
	call scroll_cuadro		;405f   ; el scroll del edificio
	call sprites_al_buffer		;4062   ; los sprites al buffer
	ld a,(0c0d5h)		;4065   ; la vida extra ya dada?
	and a			;4068   ; ya dada
	jr nz,L_407C		;4069   ; si: nada
	ld a,(0c084h)		;406b   ; la cifra de los 10.000 puntos...
	cp 031h		;406e   ; ...ya es un "1"?
	jr nz,L_407C		;4070   ; todavia no
	ld a,(0c08ah)		;4072   ; una vida mas...
	inc a			;4075   ; +1
	ld (0c08ah),a		;4076   ; a las vidas
	ld (0c0d5h),a		;4079   ; ...y no se vuelve a dar
L_407C:
	ld a,(0c0d8h)		;407c   ; el agente sigue vivo?
	bit 0,a		;407f   ; bit 0: en juego
	jp z,vida_perdida		;4081   ; no: se pierde la vida
	ld a,(0c080h)		;4084   ; ha llegado al sotano?
	bit 0,a		;4087   ; bit 0 de 0xC080
	jr nz,fin_de_ronda		;4089   ; si: fin de ronda
	jr bucle_juego		;408b   ; otro cuadro
fin_de_ronda:		; El agente ha llegado al sotano: si esta muriendo, vida perdida; si no, a ras de suelo y comprueba las puertas rojas
	res 0,a		;408d   ; se quita el aviso
	ld (0c080h),a		;408f   ; del sotano
	call sonido_calla		;4092   ; silencio
	call quita_objetos		;4095   ; fuera enemigos y balas
	call sprites_al_buffer		;4098   ; los sprites como estan
	ld ix,0c0d8h		;409b   ; el agente
	bit 6,(ix+000h)		;409f   ; muriendo?
	jr z,agente_a_ras		;40a3   ; no: al coche
	ld (ix+004h),007h		;40a5   ; si: el ultimo cuadro de morir...
	ld iy,0c000h		;40a9   ; ...pintada...
	ld b,003h		;40ad   ; tres sprites
	call pon_sprites		;40af   ; ...pintado...
	ld hl,001f4h		;40b2   ; ...una pausa...
	call espera		;40b5
	jp vida_perdida		;40b8   ; ...y cuenta como vida perdida
agente_a_ras:		; Baja al agente de 8 en 8 hasta que pisa
	call que_hay_debajo		;40bb   ; mira lo que pisa
	jr z,L_40CE		;40be   ; a ras: ya esta
	cp 002h		;40c0   ; suelo?
	jr nz,L_40CE		;40c2   ; un escalon: tambien
	ld a,(ix+002h)		;40c4   ; un paso de 8 pixeles
	add a,008h		;40c7   ; baja 8...
	ld (ix+002h),a		;40c9   ; ...y otra vez
	jr agente_a_ras		;40cc   ; hasta pisar
L_40CE:
	ld (ix+003h),001h		;40ce   ; postura de pie
	ld (ix+004h),001h		;40d2   ; cuadro 1
	call baja_al_sotano		;40d6   ; el ascensor le baja hasta el coche
	call quedan_documentos		;40d9   ; queda alguna puerta roja?
	jr z,ronda_superada		;40dc   ; no: ronda superada
	push ix		;40de   ; se guarda el agente
	call busca_ascensor_agente		;40e0   ; el ascensor del agente
	ld l,(ix+003h)		;40e3   ; el sitio del ascensor en el mapa...
	ld h,(ix+004h)		;40e6
	inc hl			;40e9   ; ...una columna a la derecha...
	ld de,00020h		;40ea   ; ...dos filas por debajo...
	ld b,002h		;40ed
	bit 6,(ix+000h)		;40ef   ; ...o catorce si es doble
	jr z,L_40F7		;40f3   ; normal
	ld b,00eh		;40f5   ; 14 filas
L_40F7:
	add hl,de			;40f7   ; + 32 por fila
	djnz L_40F7		;40f8   ; B filas
	ex de,hl			;40fa   ; alli va el rotulo
	ld hl,043b8h		;40fb   ; un "?" que no da puntos: vuelta arriba
	call rotulo_y_puntos		;40fe   ; se despliega
espera_texto:		; Espera a que el texto termine de salir
	call rotulo_cuadro		;4101   ; un paso del rotulo (deja IX en su ficha)
	bit 0,(ix+000h)		;4104   ; bit 0: sigue desplegandose?
	jr nz,espera_texto		;4108   ; espera
	pop ix		;410a   ; el ascensor
	ld a,(ix+002h)		;410c   ; la fila de la planta...
	sub 002h		;410f   ; ...dos por encima
	ld (0c0d3h),a		;4111   ; nueva fila del scroll
	ld bc,00020h		;4114   ; x 32 = desplazamiento en el mapa
	ld hl,00000h		;4117
	and a			;411a   ; en la 0...
	jr z,L_4121		;411b   ; ...desplazamiento 0
L_411D:
	add hl,bc			;411d   ; +32...
	dec a			;411e   ; ...por fila
	jr nz,L_411D		;411f
L_4121:
	sub a			;4121   ; no se juega...
	ld (0c0d6h),a		;4122   ; 0xC0D6 a cero
	ld (0c080h),a		;4125   ; sin aviso del sotano
	ld bc,08201h		;4128   ; ...con la pantalla apagada
	call escribe_vdp		;412b   ; al VDP
	jp monta_tras_vida		;412e   ; se vuelve a montar desde ahi
ronda_superada:		; Bonus de fin de ronda (1000 por ronda, hasta 9000) y siguiente edificio
	call coche_arranca		;4131   ; el coche se va con el agente
	ld hl,043ach		;4134   ; el texto "BONUS 1000"..., con el tile del espacio
	ld de,0c343h		;4137   ; ...a la RAM, para cambiar la cifra
	ld bc,0000ch		;413a   ; 12 bytes
	ldir		;413d   ; copiados
	ld a,(0c081h)		;413f   ; la ronda...
	cp 00ah		;4142   ; ...cuenta hasta la 9
	jr c,L_4148		;4144   ; menos de 10: tal cual
	ld a,009h		;4146   ; si no, 9
L_4148:
	push af			;4148   ; se guarda
	call numero_a_cifras		;4149   ; a cifras
	ld a,(0c32fh)		;414c   ; la de las unidades...
	ld (0c34ah),a		;414f   ; ...en vez del "1" de "1000"
	ld hl,043a8h		;4152   ; el texto, en el mapa del edificio
	ld de,0dc6ah		;4155   ; en el sotano
	call rotulo_y_puntos		;4158   ; se despliega
	ld a,00ah		;415b   ; el sonido 0x0A
	call sonido		;415d   ; pedido
espera_bonus:		; Espera a que acabe de salir el texto
	call rotulo_cuadro		;4160   ; un paso del rotulo
	bit 0,(ix+000h)		;4163   ; sigue?
	jr nz,espera_bonus		;4167   ; espera
	pop af			;4169   ; la ronda
	ld b,a			;416a   ; cuantas veces
L_416B:
	dec b			;416b   ; ronda - 1 veces...
	jr z,L_4176		;416c   ; la ultima la da el rotulo
	ld hl,07121h		;416e   ; ...1000 puntos
	call suma_puntos		;4171   ; sumados
	jr L_416B		;4174   ; la siguiente
L_4176:
	ld hl,00064h		;4176   ; pausa de 100 cuadros
	call espera		;4179   ; de bucle
	call agente_al_coche		;417c   ; el agente anda al coche
	sub a			;417f   ; no se juega
	ld (0c0d6h),a		;4180   ; 0xC0D6 = 0
	ld bc,00007h		;4183   ; borde negro
	call escribe_vdp		;4186   ; al VDP
	ld hl,000c0h		;4189   ; el scroll arriba del todo...
	ld (0c0d1h),hl		;418c   ; desplazamiento 0xC0 (fila 6)
	ld a,006h		;418f   ; ...fila 6
	ld (0c0d3h),a		;4191   ; la fila
	ld hl,0c081h		;4194   ; ronda + 1
	inc (hl)			;4197   ; la siguiente
	jp ronda_nueva		;4198   ; otro edificio
vida_perdida:		; Muerte del agente: quita una vida y retoma unas plantas mas arriba
	call sonido_calla		;419b
	ld hl,00040h		;419e   ; pausa de 64 cuadros
	call espera		;41a1   ; de bucle
	sub a			;41a4   ; cero
	ld (0c0d6h),a		;41a5   ; no se juega
	ld (0c0d0h),a		;41a8   ; los bits del scroll a cero
	ld bc,08201h		;41ab   ; pantalla apagada...
	call escribe_vdp		;41ae   ; al VDP
	ld bc,00007h		;41b1   ; ...borde negro
	call escribe_vdp		;41b4   ; al VDP
	ld a,(0c08ah)		;41b7   ; le quedan vidas?
	and a			;41ba   ; cero?
	jr z,fin_de_partida		;41bb   ; no: fin de partida
	dec a			;41bd   ; una menos
	ld (0c08ah),a		;41be   ; guardada
	ld a,(0c0dbh)		;41c1   ; venia de la parte de abajo?
	and 040h		;41c4   ; bit 6 de la Y del agente: pasada la mitad de la pantalla
	ld b,000h		;41c6   ; no: nada
	jr z,vuelve_arriba		;41c8
	ld b,006h		;41ca   ; si: seis filas mas
vuelve_arriba:		; Redondea la fila del scroll a un multiplo de 6 (el alto de una planta)
	ld a,(0c0d3h)		;41cc   ; la fila del scroll...
	add a,b			;41cf   ; ...mas lo de antes...
	add a,003h		;41d0   ; ...mas 3
	ld b,a			;41d2   ; se guarda
	ld c,a			;41d3
resta_6:
	sub 006h		;41d4   ; menos 6...
	jr c,fila_de_planta		;41d6   ; ...hasta pasarse
	ld c,a			;41d8   ; lo que sobra
	jr resta_6		;41d9   ; otra vez
fila_de_planta:
	ld a,b			;41db   ; el total...
	sub c			;41dc   ; ...menos el resto: multiplo de 6
	ld (0c0d3h),a		;41dd   ; la fila
	ld bc,00020h		;41e0   ; 32 por fila
	ld hl,00000h		;41e3
	and a			;41e6   ; cero?
	jr nz,L_41EE		;41e7   ; no puede ser la fila 0...
	ld a,006h		;41e9   ; ...como minimo la 6
	ld (0c0d3h),a		;41eb   ; la fila 6
L_41EE:
	cp 09ch		;41ee   ; ni pasar de la 156
	jr c,por_32		;41f0   ; menos: bien
	ld a,09ch		;41f2   ; la 156...
	ld (0c0d3h),a		;41f4   ; ...como mucho
por_32:		; Fila x 32
	add hl,bc			;41f7   ; + 32
	dec a			;41f8   ; por fila
	jr nz,por_32		;41f9   ; hasta A
monta_tras_vida:		; El edificio desde esa fila: la pantalla se vuelve a dibujar entera
	ld (0c0d1h),hl		;41fb   ; desplazamiento del scroll
	sub a			;41fe   ; vuelca el mapa entero en el proximo cuadro
	set 7,a		;41ff   ; bit 7: volcar
	ld (0c0d0h),a		;4201   ; el resto de bits a cero
	call quita_objetos		;4204   ; fuera enemigos y balas
	call sprites_a_cero		;4207   ; sprites a cero
	ld bc,00406h		;420a   ; colores de los sprites
	call escribe_vdp		;420d   ; registro 6: los dibujos normales
	call puertas_repinta		;4210   ; las puertas a medias, cerradas
	ld hl,00320h		;4213   ; pausa de 800 cuadros, la ronda en pantalla
	call espera		;4216   ; de bucle
	ld bc,00d07h		;4219   ; borde azul
	call escribe_vdp		;421c   ; al VDP
	jp vida_nueva		;421f   ; el agente vuelve a entrar
fin_de_partida:		; GAME OVER, record y vuelta al titulo
	ld hl,0c080h		;4222   ; los bits de la partida
	set 1,(hl)		;4225   ; bit 1: fin de partida
	call sprites_a_cero		;4227   ; sin sprites
	ld bc,00007h		;422a   ; borde negro
	call escribe_vdp		;422d   ; al VDP
	call pantalla_en_blanco		;4230   ; la pantalla de letras en blanco
	ld hl,04262h		;4233   ; escribe "GAME OVER"
	call escribe_textos		;4236   ; en la VRAM
	ld bc,0e201h		;4239   ; pantalla encendida
	call escribe_vdp		;423c   ; al VDP
	call sonido_calla		;423f   ; silencio...
	ld a,00ch		;4242   ; ...y el sonido 0x0C, el del fin de partida
	call sonido		;4244   ; pedido
	ld a,001h		;4247   ; la interrupcion trabaja
	ld (0c0d6h),a		;4249   ; (el sonido suena)
	ld hl,00fa0h		;424c   ; cuatro mil cuadros...
	call espera		;424f   ; de bucle
	sub a			;4252   ; cero
	ld (0c0d6h),a		;4253   ; no se juega
	ld hl,0c082h		;4256   ; el record: si los puntos pasan...
	ld de,0c08fh		;4259
	call record		;425c   ; ...se copian
	jp al_titulo		;425f   ; otra vez el titulo

; ----------------------------------------------------------------------
; DATOS txt_game_over: "GAME OVER" en la fila 9: posicion (0x014B), longitud y
;   letras; 0x80 cierra
;   0x4262..0x4270  (14 bytes)
DATA_txt_game_over:
	defb 04bh,001h,009h,047h,041h,04dh,045h,000h,04fh,056h,045h,052h,000h,080h	; 4262  K..GAME.OVER..

; ======================================================================
; CODIGO 0x4270..0x43a8  (312 bytes)
; ======================================================================


monta_ronda:		; Prepara el edificio de la ronda y baja al agente por la azotea
	call monta_edificio		;4270   ; los graficos de la ronda
	call dibuja_edificio		;4273   ; el mapa del edificio
	call ascensores_nuevos		;4276   ; los 11 ascensores
	call puertas_nuevas		;4279   ; las 58 puertas y las rojas
	ld ix,0c0ech		;427c   ; el ascensor 0 (el de la azotea)...
	ld (ix+002h),000h		;4280   ; en la fila 0...
	ld (ix+005h),000h		;4284   ; ...y su recorrido empieza ahi
	ld (0c0dfh),ix		;4288   ; ...es el del agente
	sub a			;428c   ; vuelca el mapa en el proximo cuadro
	set 7,a		;428d   ; bit 7: volcar
	ld (0c0d0h),a		;428f   ; el resto a cero
	ld bc,0e201h		;4292   ; pantalla encendida
	call escribe_vdp		;4295   ; al VDP
	ld a,001h		;4298   ; se juega
	ld (0c0d6h),a		;429a   ; 0xC0D6 = 1
	ld a,(0c081h)		;429d   ; en la ronda 1...
	cp 001h		;42a0   ; la 1?
	call z,entrada_cable		;42a2   ; ...la entrada por el cable
	call agente_entra		;42a5   ; el agente en la azotea
	ld hl,001f4h		;42a8   ; pausa de 500 cuadros
	call espera		;42ab   ; de bucle
	ld ix,0c0d8h		;42ae   ; el agente...
	ld b,004h		;42b2   ; ...cuatro pasos
	call agente_anda_n		;42b4   ; andando
baja_azotea:		; El scroll baja planta a planta hasta la fila 6
	ld hl,0012ch		;42b7   ; un paso cada 300 cuadros
	call espera		;42ba   ; de bucle
	ld a,(0c0d3h)		;42bd   ; ya en la fila 6?
	cp 006h		;42c0
	jr nc,entra_azotea		;42c2   ; si: a la azotea
	ld hl,0c0d0h		;42c4   ; si no, el scroll baja
	set 6,(hl)		;42c7   ; bit 6: el scroll baja
	call scroll_cuadro		;42c9   ; una fila
	jr baja_azotea		;42cc   ; otra vez
entra_azotea:		; El agente salta de la azotea al ascensor
	ld ix,0c0d8h		;42ce
	set 7,(ix+000h)		;42d2   ; el agente de espaldas
	call dibujos_del_lado		;42d6   ; lo pinta
	ld b,004h		;42d9   ; cuatro pasos mas
	call agente_anda_n		;42db
	res 7,(ix+000h)		;42de   ; de frente
	call dibujos_del_lado		;42e2
	ld (ix+003h),001h		;42e5   ; de pie
	ld (ix+004h),001h		;42e9
	ld ix,0c0ech		;42ed   ; el ascensor de la azotea...
	ld (ix+002h),006h		;42f1   ; ...en la planta 6...
	ld (ix+005h),006h		;42f5   ; ...que es tambien su destino
	ld a,00bh		;42f9   ; temporizador 11, el del ascensor 0...
	ld b,078h		;42fb   ; ...120 cuadros quieto
	call pon_temporizador		;42fd   ; puesto
	ret			;4300   ; listo
suelta_ascensores:		; Quita a los 11 ascensores los bits de ocupado
	ld ix,0c0ech		;4301   ; los 11 ascensores
	ld b,00bh		;4305   ; 11
	ld de,0000ah		;4307   ; de 10 bytes
L_430A:
	ld a,(ix+000h)		;430a   ; deja los bits 0, 2, 5 y 6
	and 065h		;430d
	ld (ix+000h),a		;430f   ; guardado
	add ix,de		;4312   ; el siguiente
	djnz L_430A		;4314   ; los 11
	ret			;4316   ; listo
busca_ascensor_agente:		; IX = el ascensor con el bit 5 (el que lleva al agente)
	ld ix,0c0ech		;4317   ; los 11 ascensores
	ld de,0000ah		;431b   ; de 10 bytes
	ld b,00bh		;431e   ; 11
L_4320:
	bit 5,(ix+000h)		;4320   ; bit 5: el del sotano?
	jr nz,L_432A		;4324   ; encontrado
	add ix,de		;4326   ; el siguiente
	djnz L_4320		;4328   ; los 11
L_432A:
	ret			;432a   ; IX
agente_anda_n:		; El agente da B pasos de andar (dos posturas alternas)
	ld (ix+003h),002h		;432b   ; andando
L_432F:
	push bc			;432f   ; se guarda la cuenta
	ld a,(ix+004h)		;4330   ; postura 1-2-1-2...
	inc a			;4333   ; +1
	cp 003h		;4334   ; pasa de 2?
	jr c,L_433A		;4336   ; no
	ld a,001h		;4338   ; vuelve a 1
L_433A:
	ld (ix+004h),a		;433a   ; el cuadro
	call un_paso		;433d   ; 4 pixeles
	ld b,003h		;4340   ; pintado
	ld iy,0c000h		;4342   ; en el buffer
	call pon_sprites		;4346   ; los tres
	ld hl,00060h		;4349   ; pausa de 96 cuadros
	call espera		;434c
	pop bc			;434f   ; la cuenta
	djnz L_432F		;4350   ; B pasos
	ret			;4352   ; listo
baja_al_sotano:		; El ascensor del agente baja fila a fila con el dentro hasta la Y 0xA8
	ld hl,05856h		;4353   ; los dibujos de siempre del agente
	ld (0c0ddh),hl		;4356   ; puestos
	ld ix,(0c0dfh)		;4359   ; el ascensor del agente...
	res 0,(ix+000h)		;435d   ; ...baja (bit 0 = 0)
baja_sotano_paso:
	ld hl,0012ch		;4361   ; un paso cada 300 vueltas
	call espera		;4364   ; de bucle
	call ascensor_una_fila		;4367   ; la cabina baja una fila
	push ix		;436a   ; se guarda
	ld ix,0c0d8h		;436c   ; el agente
	ld a,(ix+002h)		;4370   ; la Y del agente...
	add a,008h		;4373   ; ...8 mas
	ld (ix+002h),a		;4375   ; guardada
	push af			;4378   ; se guarda
	ld b,003h		;4379   ; tres sprites
	ld iy,0c000h		;437b   ; en el buffer de sprites
	call pon_sprites		;437f   ; pintados
	pop af			;4382   ; la Y
	pop ix		;4383   ; el ascensor
	cp 0a8h		;4385   ; hasta la Y 0xA8
	jr c,baja_sotano_paso		;4387   ; otra fila
	res 7,(ix+000h)		;4389   ; el ascensor ya no lleva al agente
	ret			;438d   ; listo
quedan_documentos:		; NZ si alguna puerta roja sigue cerrada (58 puertas, bit 6)
	ld ix,0c16eh		;438e   ; la tabla de puertas
	ld b,03ah		;4392   ; 58 puertas de 5 bytes
	ld de,00005h		;4394   ; de 5 bytes
L_4397:
	bit 6,(ix+000h)		;4397   ; bit 6: roja?
	jr nz,L_43A4		;439b   ; si: queda
	add ix,de		;439d   ; la siguiente
	djnz L_4397		;439f   ; las 58
	sub a			;43a1   ; Z: ninguna
	jr L_43A6		;43a2   ; listo
L_43A4:
	ld a,001h		;43a4   ; NZ: queda alguna
L_43A6:
	and a			;43a6   ; las banderas
	ret			;43a7   ; listo

; ----------------------------------------------------------------------
; DATOS txt_bonus: "BONUS;1000" (en 0xC343 se cambia la cifra) y el "?" del
;   final
;   0x43a8..0x43bf  (23 bytes)
DATA_txt_bonus:
	defb 043h,0c3h,021h,071h,00ah,042h,04fh,04eh,055h,053h,03bh,031h,030h,030h,030h,0ffh	; 43a8  C.!q.BONUS;1000.
	defb 0bch,043h,00bh,071h,001h,03fh,0ffh	; 43b8

; ======================================================================
; CODIGO 0x43bf..0x4650  (657 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  El scroll: el edificio baja o sube de fila en fila  =====
; ----------------------------------------------------------------------
scroll_cuadro:		; Si toca (bits 5 y 6 de 0xC0D0) mueve el edificio una fila
	ld hl,0c0d0h		;43bf   ; los bits del scroll
	bit 5,(hl)		;43c2   ; bit 5: mover la fila del agente
	jr z,L_43CD		;43c4   ; no
	call scroll_con_agente		;43c6   ; el agente
	res 5,(hl)		;43c9   ; hecho
	jr scroll_vuelca		;43cb   ; a volcar
L_43CD:
	bit 6,(hl)		;43cd   ; bit 6: el scroll de la entrada
	jr nz,L_43D3		;43cf   ; si
	jr scroll_vuelca		;43d1   ; no: a volcar
L_43D3:
	call scroll_una_fila		;43d3   ; una fila
	jr nz,scroll_vuelca		;43d6   ; no se ha podido
	ld a,(0c0d8h)		;43d8   ; el agente...
	bit 2,a		;43db   ; ...en la escalera?
	jr nz,scroll_vuelca		;43dd   ; si: nada mas
	ld ix,(0c0dfh)		;43df   ; su ascensor...
	call ascensor_una_fila		;43e3   ; ...tambien se mueve
	ld a,000h		;43e6   ; el sonido 0...
	call sonido		;43e8   ; ...el del ascensor
scroll_vuelca:		; Pide volcar el mapa en el proximo cuadro
	set 7,(hl)		;43eb   ; bit 7: volcar
	res 6,(hl)		;43ed   ; el bit 6 hecho
	ret			;43ef   ; listo
scroll_con_agente:		; El scroll sigue al agente: 8 pixeles arriba o abajo
	push hl			;43f0   ; se guarda
	bit 1,(hl)		;43f1   ; bit 1: hacia arriba
	jr z,L_43FB		;43f3   ; no: baja
	res 0,(hl)		;43f5   ; bit 0 = 0: sube
	ld c,0f8h		;43f7   ; el agente, 8 mas arriba en pantalla
	jr L_43FF		;43f9   ; a mover
L_43FB:
	set 0,(hl)		;43fb   ; bit 0 = 1: baja
	ld c,008h		;43fd   ; el agente, 8 mas abajo
L_43FF:
	call scroll_una_fila		;43ff   ; mueve el edificio
	jr z,L_4406		;4402   ; se ha podido?
	ld c,0f8h		;4404   ; no: el agente no se mueve
L_4406:
	ld a,(0c0dah)		;4406   ; la Y del agente
	add a,c			;4409   ; + C
	ld (0c0dah),a		;440a   ; guardada
	pop hl			;440d   ; 0xC0D0
	ret			;440e   ; listo
scroll_una_fila:		; Mueve el edificio una fila (bit 0 de 0xC0D0: 0 baja la vista, 1 la sube); NZ si no se pudo
	push hl			;440f   ; se guardan
	push bc			;4410
	sub a			;4411   ; Z por defecto
	res 7,(hl)		;4412   ; sin volcar todavia
	bit 0,(hl)		;4414   ; que direccion?
	jr z,scroll_baja		;4416   ; bit 0 = 0: baja
scroll_sube:		; La vista sube una fila: el desplazamiento baja 32
	ld hl,(0c0d1h)		;4418   ; el desplazamiento...
	ld bc,00020h		;441b   ; ...menos una fila
	and a			;441e
	sbc hl,bc		;441f   ; resta
	jp c,L_448B		;4421   ; ya arriba del todo: nada
	ld (0c0d1h),hl		;4424   ; guardado
	ld hl,0c0d3h		;4427   ; fila - 1
	dec (hl)			;442a   ; una menos
	ld c,008h		;442b   ; los objetos bajan 8 pixeles
	push af			;442d   ; se guarda Z
	call mueve_objetos_y		;442e   ; suman 8
	pop af			;4431   ; Z
	jr L_448A		;4432   ; listo
scroll_baja:		; La vista baja una fila; en la fila 0xB6 (el sotano) se para
	ld hl,(0c0d1h)		;4434   ; el desplazamiento...
	ld bc,00020h		;4437   ; ...mas una fila
	add hl,bc			;443a   ; suma
	ld (0c0d1h),hl		;443b   ; guardado
	ld hl,0c0d3h		;443e   ; la fila
	inc (hl)			;4441   ; fila + 1
	ld a,0b6h		;4442   ; la ultima fila es la 0xB6
	cp (hl)			;4444   ; se ha pasado?
	jr c,scroll_sube		;4445   ; pasada: se deshace
	jr nz,scroll_objetos_suben		;4447   ; no es la ultima: los objetos suben
	exx			;4449   ; en la ultima: algun ascensor...
	ex af,af'			;444a
	ld hl,0c0ech		;444b   ; ...con el agente...
	ld de,0000ah		;444e   ; de 10 bytes
	ld b,00bh		;4451   ; los 11
L_4453:
	ld a,(hl)			;4453   ; ...y en el sotano (bits 5 y 7)?
	and 0a0h		;4454   ; los bits 5 y 7...
	cp 0a0h		;4456
	jr z,scroll_sotano		;4458   ; si: al sotano
	add hl,de			;445a   ; el siguiente
	djnz L_4453		;445b   ; los 11
	ex af,af'			;445d   ; ninguno: no se baja
	exx			;445e
	dec (hl)			;445f   ; la fila otra vez
	jr scroll_sube		;4460   ; y se deshace
scroll_sotano:		; El ascensor del agente llega al sotano: fin de ronda en camino
	ex af,af'			;4462   ; los registros
	exx			;4463
	ld hl,0c080h		;4464   ; bit 0 de 0xC080: el agente esta en el sotano
	set 0,(hl)		;4467   ; avisado
	ld hl,(0c0d1h)		;4469   ; desplazamiento ya en 0x1680 (fila 0xB4)?
	ld bc,01680h		;446c   ; 0x1680...
	and a			;446f
	sbc hl,bc		;4470   ; ...igual?
	jr z,L_448A		;4472   ; si: listo
	ld hl,01680h		;4474   ; si no, se fija ahi...
	ld (0c0d1h),hl		;4477   ; guardado
	ld a,(0c0dah)		;447a   ; ...y el agente baja 8
	add a,008h		;447d   ; 8 mas
	ld (0c0dah),a		;447f   ; guardada
	jr L_448A		;4482   ; listo
scroll_objetos_suben:
	ld c,0f8h		;4484   ; todo sube 8 pixeles
	call mueve_objetos_y		;4486   ; los objetos
	sub a			;4489   ; Z
L_448A:
	and a			;448a   ; las banderas
L_448B:
	pop bc			;448b   ; se recuperan
	pop hl			;448c
	ret			;448d   ; listo
mueve_objetos_y:		; Suma C a la Y de enemigos, balas y objetos al mover el edificio
	ld ix,0c2e0h		;448e   ; los 4 enemigos
	ld b,004h		;4492   ; 4
	ld de,0000ah		;4494   ; de 10 bytes
	call suma_y_tabla		;4497   ; suman C
	ld ix,0c29ah		;449a   ; las 3 balas del agente
	ld b,003h		;449e   ; 3
	ld de,0000ah		;44a0   ; de 10 bytes
	call suma_y_tabla		;44a3   ; suman C
	ld ix,0c2b8h		;44a6   ; las 4 balas enemigas
	ld b,004h		;44aa   ; 4
	ld de,0000ah		;44ac   ; de 10 bytes
	call suma_y_tabla		;44af   ; suman C
	ld a,(0c39bh)		;44b2   ; hay algo mas en pantalla (la luz que cae)?
	or a			;44b5   ; cero?
	ret z			;44b6   ; no hay
	ld a,(0c064h)		;44b7   ; su Y en los sprites 25 y 26
	add a,c			;44ba   ; + C
	ld (0c064h),a		;44bb   ; las dos mitades
	ld (0c068h),a		;44be
	ret			;44c1   ; listo
suma_y_tabla:		; Suma C a la Y (IX+2) de B fichas de 10 bytes que esten activas
	bit 0,(ix+000h)		;44c2   ; activa?
	jr z,L_44CF		;44c6   ; no: la siguiente
suma_y_sig:
	ld a,(ix+002h)		;44c8   ; la Y...
	add a,c			;44cb   ; ...+ C
	ld (ix+002h),a		;44cc
L_44CF:
	add ix,de		;44cf   ; la siguiente
	djnz suma_y_sig		;44d1   ; las B
	ret			;44d3   ; listo
sprites_al_buffer:		; Pasa el agente, enemigos y balas al buffer de atributos de 0xC000
	ld ix,0c0d8h		;44d4   ; el agente
	ld iy,0c000h		;44d8   ; su sitio en el buffer
	bit 0,(ix+000h)		;44dc   ; esta en juego?
	jp z,L_4571		;44e0   ; no: nada
	bit 2,(ix+000h)		;44e3   ; en la escalera?
	jr nz,L_44EE		;44e7   ; si: ya los pone la escalera
	ld b,003h		;44e9   ; tres sprites
	call pon_sprites		;44eb
L_44EE:
	ld ix,0c2e0h		;44ee   ; los 4 enemigos...
	ld iy,0c00ch		;44f2   ; ...desde el sprite 3
	ld b,004h		;44f6
L_44F8:
	push bc			;44f8   ; la cuenta
	ld b,002h		;44f9   ; dos sprites cada uno
	bit 0,(ix+000h)		;44fb   ; activo?
	jr z,sprites_ocultos		;44ff   ; no: escondidos
	call pon_sprites		;4501   ; los pone
	jr z,sprites_enemigo_sig		;4504   ; en pantalla: sigue
	ld l,(ix+007h)		;4506   ; fuera: su puerta...
	ld h,(ix+008h)		;4509
	bit 1,(ix+000h)		;450c   ; ...si salio de una...
	jr z,L_4514		;4510   ; no
	res 3,(hl)		;4512   ; ...queda libre
L_4514:
	bit 5,(ix+003h)		;4514   ; y si iba en ascensor...
	jr z,sprites_enemigo_sig		;4518
	res 1,(hl)		;451a   ; ...el ascensor tambien
	jr sprites_enemigo_sig		;451c
sprites_ocultos:		; Esconde B sprites (Y = 0xD1)
	call esconde_sprite		;451e
	djnz sprites_ocultos		;4521   ; los B
sprites_enemigo_sig:
	pop bc			;4523   ; la cuenta
	ld de,0000ah		;4524   ; 10 bytes
	add ix,de		;4527   ; el siguiente
	djnz L_44F8		;4529   ; los 4
	ld ix,0c29ah		;452b   ; las 3 balas del agente, desde el sprite 11
	ld iy,0c02ch		;452f   ; sprite 11
	ld b,003h		;4533   ; 3
sprites_bala_agente:
	push bc			;4535   ; la cuenta
	ld b,001h		;4536   ; un sprite
	bit 0,(ix+000h)		;4538   ; en juego?
	jr z,L_4543		;453c   ; no
	call pon_sprites		;453e   ; pintada
	jr L_4546		;4541   ; la siguiente
L_4543:
	call esconde_sprite		;4543   ; inactiva: escondida
L_4546:
	ld de,0000ah		;4546   ; 10 bytes
	add ix,de		;4549   ; la siguiente
	pop bc			;454b   ; la cuenta
	djnz sprites_bala_agente		;454c   ; las 3
	ld ix,0c2b8h		;454e   ; las 4 balas enemigas, desde el sprite 14
	ld iy,0c038h		;4552   ; sprite 14
	ld b,004h		;4556   ; 4
sprites_bala_enemiga:
	push bc			;4558   ; la cuenta
	ld b,001h		;4559   ; un sprite
	bit 0,(ix+000h)		;455b   ; en juego?
	jr z,L_4566		;455f   ; no
	call pon_sprites		;4561   ; pintada
	jr L_4569		;4564   ; la siguiente
L_4566:
	call esconde_sprite		;4566   ; escondida
L_4569:
	ld de,0000ah		;4569   ; 10 bytes
	add ix,de		;456c   ; la siguiente
	pop bc			;456e   ; la cuenta
	djnz sprites_bala_enemiga		;456f   ; las 4
L_4571:
	ret			;4571   ; listo

; ----------------------------------------------------------------------
; =====  El VDP: modo y tablas  =====
; ----------------------------------------------------------------------
vdp_modo_juego:		; GRAPHIC 1 (SCREEN 1) con las tablas propias: nombres 0x1000, colores 0x3FC0, sprites 0x3F00/0x2000
	ld hl,04856h		;4572   ; los 8 registros de 0x4856
	call vdp_ocho_registros		;4575   ; al VDP
	ld hl,01000h		;4578   ; y lo mismo en las variables del sistema: nombres
	ld (0f3c7h),hl		;457b   ; NAMBAS de GRAPHIC 1
	ld hl,03fc0h		;457e   ; colores
	ld (0f3c9h),hl		;4581   ; la de colores
	ld hl,00000h		;4584   ; patrones
	ld (0f3cbh),hl		;4587   ; la de patrones
	ld hl,03f00h		;458a   ; atributos de sprites
	ld (0f3cdh),hl		;458d   ; la de atributos
	ld hl,02000h		;4590   ; dibujos de sprites
	ld (0f3cfh),hl		;4593   ; la de dibujos
	call sprites_a_cero		;4596   ; sprites a cero
	ret			;4599   ; listo
quita_objetos:		; Desactiva enemigos (liberando su puerta) y balas
	ld ix,0c2e0h		;459a   ; los 4 enemigos
	ld b,004h		;459e   ; 4
	ld de,0000ah		;45a0   ; de 10 bytes
L_45A3:
	bit 0,(ix+000h)		;45a3   ; activo?
	jr z,L_45BB		;45a7   ; no
	res 0,(ix+000h)		;45a9   ; fuera
	bit 1,(ix+000h)		;45ad   ; salio de una puerta?
	jr z,L_45BB		;45b1   ; no
	ld l,(ix+007h)		;45b3   ; la puerta...
	ld h,(ix+008h)		;45b6
	res 3,(hl)		;45b9   ; ...libre
L_45BB:
	add ix,de		;45bb   ; el siguiente
	djnz L_45A3		;45bd   ; los 4
	ld ix,0c29ah		;45bf   ; las 3 balas del agente
	ld b,003h		;45c3   ; 3
	ld de,0000ah		;45c5   ; de 10 bytes
L_45C8:
	bit 0,(ix+000h)		;45c8   ; en juego?
	jr z,L_45D2		;45cc   ; no
	ld (ix+000h),000h		;45ce   ; fuera
L_45D2:
	add ix,de		;45d2   ; la siguiente
	djnz L_45C8		;45d4   ; las 3
	ld ix,0c2b8h		;45d6   ; las 4 balas enemigas
	ld b,004h		;45da   ; 4
	ld de,0000ah		;45dc   ; de 10 bytes
L_45DF:
	bit 0,(ix+000h)		;45df   ; en juego?
	jr z,L_45E9		;45e3   ; no
	ld (ix+000h),000h		;45e5   ; fuera
L_45E9:
	add ix,de		;45e9   ; la siguiente
	djnz L_45DF		;45eb   ; las 4
	ret			;45ed   ; listo
sprites_a_cero:		; Vacia el buffer de atributos y la tabla de la VRAM
	ld hl,0c000h		;45ee   ; los 128 bytes del buffer
	ld bc,00080h		;45f1   ; 128
	sub a			;45f4   ; ceros
	call rellena_bc		;45f5   ; en RAM
	sub a			;45f8   ; la tabla 0 de 0x4892: los atributos en la VRAM
	call vdp_rellena_tabla		;45f9   ; en la VRAM
	ret			;45fc   ; listo
partida_nueva:		; Ronda 1, 3 vidas, puntos a cero y el record inicial (10000) si no hay otro
	di			;45fd   ; pantalla apagada
	ld bc,08201h		;45fe   ; registro 1 = 0x82: sin imagen
	call escribe_vdp		;4601   ; al VDP
	sub a			;4604   ; nada en curso
	ld (0c080h),a		;4605   ; sin avisos
	ld (0c0d5h),a		;4608   ; la vida extra sin dar
	ld a,001h		;460b   ; ronda 1
	ld (0c081h),a		;460d   ; la ronda
	ld a,002h		;4610   ; dos vidas de reserva
	ld (0c08ah),a		;4612   ; las vidas de reserva
	ld a,(0c08fh)		;4615   ; hay record?
	and a			;4618   ; cero?
	jr nz,L_4630		;4619   ; no: se conserva
	ld a,030h		;461b   ; no: siete "0"...
	ld b,007h		;461d   ; 7 cifras
	ld hl,0c082h		;461f   ; de los puntos...
	call rellena_b		;4622   ; ...a "0"
	ld hl,04650h		;4625   ; ...y el record de fabrica, "0010000"
	ld de,0c08fh		;4628   ; al record
	ld bc,00007h		;462b   ; 7 cifras
	ldir		;462e   ; copiado
L_4630:
	sub a			;4630   ; la cuenta de 0xC0D4 a cero
	ld (0c0d4h),a		;4631   ; a cero
	ld hl,08d18h		;4634   ; los colores de la ronda 1
	ld de,03fc0h		;4637   ; a la tabla de colores
	ld bc,00020h		;463a   ; 32 grupos de 8 patrones
	call 0005ch		;463d   ; LDIRVM
	ld a,030h		;4640   ; los puntos: siete "0"
	ld b,007h		;4642   ; 7 cifras
	ld hl,0c082h		;4644   ; los puntos
	call rellena_b		;4647   ; a "0"
	ld hl,0c080h		;464a   ; sin fin de partida
	res 1,(hl)		;464d   ; bit 1 de 0xC080 a cero
	ret			;464f   ; listo

; ----------------------------------------------------------------------
; DATOS record_inicial: El record de fabrica: "0010000"
;   0x4650..0x4657  (7 bytes)
DATA_record_inicial:
	defb 030h,030h,031h,030h,030h,030h,030h	; 4650

; ======================================================================
; CODIGO 0x4657..0x47e1  (394 bytes)
; ======================================================================


espejo_bytes:		; Da la vuelta a DE bytes de HL (bit 7 <-> bit 0): el dibujo mirando al otro lado
	push bc			;4657   ; se guardan
	push hl			;4658
L_4659:
	ld b,008h		;4659   ; 8 bits
L_465B:
	sla (hl)		;465b   ; saca el bit alto...
	rr c		;465d   ; ...y lo mete por arriba de C
	djnz L_465B		;465f   ; los 8
	ld (hl),c			;4661   ; el byte al reves
	inc hl			;4662   ; el siguiente
	dec de			;4663   ; uno menos
	ld a,d			;4664
	or e			;4665   ; quedan?
	jr nz,L_4659		;4666   ; si
	pop hl			;4668   ; se recuperan
	pop bc			;4669
	ret			;466a   ; listo
espejo_sprites:		; Cambia de sitio las dos mitades de B sprites de 16x16 (izquierda <-> derecha)
	push bc			;466b   ; la cuenta
	ld hl,0e010h		;466c   ; la mitad derecha...
	ld de,0e800h		;466f   ; ...a la izquierda
	call copia_mitades		;4672   ; B sprites
	pop bc			;4675   ; la cuenta
	ld hl,0e000h		;4676   ; la izquierda...
	ld de,0e810h		;4679   ; ...a la derecha
	call copia_mitades		;467c   ; B sprites
	ret			;467f   ; listo
copia_mitades:		; B veces: 16 bytes de HL a DE, saltando 16
	push bc			;4680   ; la cuenta
	ld bc,00010h		;4681   ; 16 bytes...
	ldir		;4684   ; ...copiados
	ld bc,00010h		;4686   ; y 16 de salto...
	add hl,bc			;4689   ; ...en el origen...
	ex de,hl			;468a
	add hl,bc			;468b   ; ...y en el destino
	ex de,hl			;468c
	pop bc			;468d   ; la cuenta
	djnz copia_mitades		;468e   ; los B
	ret			;4690   ; listo
monta_edificio:		; Descomprime los graficos de la ronda, limpia el mapa y lo dibuja
	di			;4691   ; sin interrupciones
	ld bc,08201h		;4692   ; pantalla apagada
	call escribe_vdp		;4695   ; variables de la ronda a cero
	call ram_ronda_a_cero		;4698   ; 0xC0D6-0xC3A2 a cero
	call sprites_a_cero		;469b   ; sprites a cero
	xor a			;469e   ; el mapa del edificio, 0xC400-0xDFFF, a cero
	ld hl,0c400h		;469f   ; 0xC400...
	ld bc,01c00h		;46a2   ; ...7 KB...
	call rellena_bc		;46a5   ; ...a cero
	ld hl,08516h		;46a8   ; los patrones del edificio...
	ld de,0e000h		;46ab   ; a 0xE000
	call copia_con_largo		;46ae   ; copiados
	ld hl,0e000h		;46b1   ; ...a la VRAM 0x0000
	ld de,00000h		;46b4   ; la tabla de patrones
	ld bc,00800h		;46b7   ; 2 KB
	call 0005ch		;46ba   ; LDIRVM
	ld hl,08d98h		;46bd   ; los sprites del agente...
	ld de,0e000h		;46c0   ; a 0xE000
	call copia_con_largo		;46c3   ; copiados
	ld hl,0e000h		;46c6   ; ...a 0x2000 mirando a la derecha...
	ld de,02000h		;46c9   ; la tabla de dibujos de sprites
	ld bc,002c0h		;46cc   ; 22 sprites de 32 bytes
	call 0005ch		;46cf   ; LDIRVM
	ld hl,0e000h		;46d2   ; ...y dados la vuelta...
	ld de,002c0h		;46d5   ; sus 0x2C0 bytes
	call espejo_bytes		;46d8   ; al reves
	ld b,016h		;46db   ; ...22 sprites...
	call espejo_sprites		;46dd   ; y las mitades cambiadas a 0xE800
	ld hl,0e800h		;46e0   ; ...a 0x2800, mirando a la izquierda
	ld de,02800h		;46e3   ; la segunda tabla de dibujos (registro 6 = 5)
	ld bc,002c0h		;46e6   ; 0x2C0 bytes
	call 0005ch		;46e9   ; LDIRVM
	ld hl,0905ah		;46ec   ; los de los enemigos...
	ld de,0e000h		;46ef   ; a 0xE000
	call copia_con_largo		;46f2   ; copiados
	ld hl,0e000h		;46f5   ; ...a 0x22C0...
	ld de,022c0h		;46f8   ; detras de los del agente...
	ld bc,001c0h		;46fb   ; ...14 sprites
	call 0005ch		;46fe   ; LDIRVM
	ld hl,0e000h		;4701   ; ...y a 0x2AC0
	ld de,02ac0h		;4704   ; y en la segunda tabla
	ld bc,001c0h		;4707   ; 0x1C0 bytes
	call 0005ch		;470a   ; LDIRVM
	ld hl,0e000h		;470d   ; dados la vuelta...
	ld de,001c0h		;4710   ; 0x1C0 bytes
	call espejo_bytes		;4713   ; al reves
	ld b,00eh		;4716   ; ...14 sprites...
	call espejo_sprites		;4718   ; mitades cambiadas
	ld hl,0e800h		;471b   ; ...a 0x2480 y 0x2C80
	ld de,02480h		;471e   ; los del enemigo mirando a la izquierda...
	ld bc,001c0h		;4721   ; 0x1C0 bytes
	call 0005ch		;4724   ; LDIRVM
	ld hl,0e800h		;4727   ; los mismos...
	ld de,02c80h		;472a   ; ...en la segunda tabla
	ld bc,001c0h		;472d   ; 0x1C0 bytes
	call 0005ch		;4730   ; LDIRVM
	ld hl,0921ch		;4733   ; los del resto (balas, coche, luz)...
	ld de,0e000h		;4736   ; a 0xE000
	call copia_con_largo		;4739   ; copiados
	ld hl,0e000h		;473c   ; ...a 0x2640...
	ld de,02640h		;473f   ; detras de los del enemigo
	ld bc,001c0h		;4742   ; 0x1C0 bytes
	call 0005ch		;4745   ; LDIRVM
	ld hl,0e000h		;4748   ; ...y a 0x2E40
	ld de,02e40h		;474b   ; en la segunda tabla...
	ld bc,009c0h		;474e   ; ...0x9C0 bytes: hasta 0x3800, con lo que hubiera en 0xE1C0 y siguientes
	call 0005ch		;4751   ; LDIRVM
	ld a,002h		;4754   ; el mapa de nombres a cero (tabla 2 de 0x4892)
	call vdp_rellena_tabla		;4756   ; a cero
	ld bc,00d07h		;4759   ; borde azul
	call escribe_vdp		;475c   ; al VDP
	ld bc,00406h		;475f   ; los colores de los sprites
	call escribe_vdp		;4762   ; al VDP
	call pantalla_en_blanco		;4765   ; la pantalla en blanco
	sub a			;4768   ; cero
	ld (0c080h),a		;4769   ; sin avisos
	ld hl,0c0d0h		;476c   ; los bits del scroll a cero
	ld b,004h		;476f   ; 4 bytes
	sub a			;4771   ; a cero
	call rellena_b		;4772   ; 0xC0D0-0xC0D3
	ld hl,0c0d0h		;4775   ; se vuelca
	set 7,(hl)		;4778   ; bit 7: volcar
	call sonido_apaga		;477a   ; silencio
	call temporizadores_a_cero		;477d   ; los 50 temporizadores a cero
	ld a,(0c081h)		;4780   ; la ronda...
	push af			;4783   ; se guarda
	cp 003h		;4784   ; ...de la 3 en adelante...
	jr c,dificultad_ronda		;4786   ; menos: 4 - ronda
	ld a,001h		;4788   ; ...un solo piso de dificultad
	jr guarda_dificultad		;478a   ; guardada
dificultad_ronda:		; Ronda 1: 3, ronda 2: 2 (cuantos cuadros espera cada enemigo)
	ld b,a			;478c   ; la ronda
	ld a,004h		;478d   ; 4...
	sub b			;478f   ; ...menos la ronda
guarda_dificultad:
	ld (0c328h),a		;4790   ; la dificultad
	call marcador_fijo		;4793   ; el marcador fijo
	pop af			;4796   ; la ronda
	push af			;4797   ; se guarda otra vez
colores_ronda:		; Los colores de los patrones cambian cada ronda: tres juegos que se repiten
	dec a			;4798   ; ronda - 1...
	jr z,colores_1		;4799   ; ...1, 4, 7...
	dec a			;479b   ; ...- 1...
	jr z,colores_2		;479c   ; ...2, 5, 8...
	dec a			;479e   ; ...- 1...
	jr z,colores_3		;479f   ; ...3, 6, 9...
	jr colores_ronda		;47a1   ; y otra vuelta
colores_1:
	ld hl,08d18h		;47a3   ; los colores 1
	jr pon_colores		;47a6   ; puestos
colores_2:
	ld hl,08d38h		;47a8   ; los colores 2
	jr pon_colores		;47ab   ; puestos
colores_3:
	ld hl,08d58h		;47ad   ; los colores 3
pon_colores:
	ld (0c386h),hl		;47b0   ; se guardan para el parpadeo de las luces
	ld de,03fc0h		;47b3   ; a la tabla de colores
	ld bc,00020h		;47b6   ; 32 bytes
	call 0005ch		;47b9   ; LDIRVM
	pop af			;47bc   ; la ronda
ronda_mod_100:		; La ronda en pantalla, de 0 a 99
	cp 064h		;47bd   ; 100 o mas?
	jr c,L_47C5		;47bf   ; no
	sub 064h		;47c1   ; - 100
	jr ronda_mod_100		;47c3   ; otra vez
L_47C5:
	call numero_a_cifras		;47c5   ; a dos cifras
	ld hl,0c32fh		;47c8   ; las cifras...
	ld de,012f8h		;47cb   ; ...junto a "ROUND"
	ld bc,00002h		;47ce   ; dos cifras
	call 0005ch		;47d1   ; LDIRVM
	ld hl,047e1h		;47d4   ; "ROUND"
	ld de,012f2h		;47d7   ; en la fila de abajo
	ld bc,00005h		;47da   ; 5 letras
	call 0005ch		;47dd   ; LDIRVM
	ret			;47e0   ; listo

; ----------------------------------------------------------------------
; DATOS txt_round: "ROUND"
;   0x47e1..0x47e6  (5 bytes)
DATA_txt_round:
	defb 052h,04fh,055h,04eh,044h	; 47e1

; ======================================================================
; CODIGO 0x47e6..0x4811  (43 bytes)
; ======================================================================


marcador_fijo:		; "PLAYER" y "HI SCORE" con sus cifras, en la fila de arriba
	ld hl,04811h		;47e6   ; los rotulos
	call escribe_textos		;47e9   ; en la VRAM
	ld de,0c08fh		;47ec   ; el record...
	call cifras_sin_ceros		;47ef   ; ...a letras
	ld hl,0c339h		;47f2   ; a la VRAM
	ld de,0102ch		;47f5   ; a la derecha de la fila 1
	ld bc,00007h		;47f8   ; 7 cifras
	call 0005ch		;47fb   ; LDIRVM
	ld de,0c082h		;47fe   ; los puntos
	call cifras_sin_ceros		;4801   ; a letras
	ld hl,0c339h		;4804   ; de 0xC339...
	ld de,01022h		;4807   ; ...a la izquierda de la fila 1
	ld bc,00007h		;480a   ; 7 cifras
	call 0005ch		;480d   ; LDIRVM
	ret			;4810   ; listo

; ----------------------------------------------------------------------
; DATOS txt_marcador: "PLAYER    HI SCORE" en la fila 0 (0x1012); ';' es el
;   espacio y '@' tambien
;   0x4811..0x4828  (23 bytes)
DATA_txt_marcador:
	defb 002h,000h,012h,050h,04ch,041h,059h,045h,052h,03bh,03bh,03bh,03bh,048h,049h,040h	; 4811  ...PLAYER;;;;HI@
	defb 053h,043h,04fh,052h,045h,000h,080h	; 4821

; ======================================================================
; CODIGO 0x4828..0x4856  (46 bytes)
; ======================================================================


pantalla_en_blanco:		; Llena los 768 nombres de 0x1000 con el patron 0x3B (vacio)
	ld hl,01000h		;4828   ; la tabla de nombres...
	ld bc,00300h		;482b   ; ...768...
	ld a,03bh		;482e   ; ...del patron vacio
	call 00056h		;4830   ; FILVRM
	ret			;4833   ; listo
ram_ronda_a_cero:		; Borra las variables de 0xC0D6 a 0xC3A2
	ld hl,0c3a3h		;4834   ; el final...
	ld bc,0c0d6h		;4837   ; ...menos el principio...
	and a			;483a
	sbc hl,bc		;483b   ; ...es el largo
	push hl			;483d   ; a BC
	pop bc			;483e
	ld hl,0c0d6h		;483f   ; desde 0xC0D6
	sub a			;4842   ; ceros
	call rellena_bc		;4843   ; a cero
	ret			;4846   ; listo
vdp_ocho_registros:		; Escribe los 8 registros del VDP de la tabla HL
	ld b,008h		;4847   ; 8 registros
	ld c,000h		;4849   ; desde el 0
L_484B:
	push bc			;484b   ; se guarda la cuenta
	ld b,(hl)			;484c   ; el valor
	call escribe_vdp		;484d   ; al VDP
	pop bc			;4850   ; la cuenta
	inc hl			;4851   ; el siguiente valor
	inc c			;4852   ; el siguiente registro
	djnz L_484B		;4853   ; los 8
	ret			;4855   ; listo

; ----------------------------------------------------------------------
; DATOS vdp_registros: Registros 0-7: GRAPHIC 1, 16x16, nombres 0x1000,
;   colores 0x3FC0, patrones 0, atributos 0x3F00, sprites 0x2000, borde 1
;   0x4856..0x485e  (8 bytes)
DATA_vdp_registros:
	defb 000h,082h,004h,0ffh,000h,07eh,004h,001h	; 4856  .....~..

; ======================================================================
; CODIGO 0x485e..0x4892  (52 bytes)
; ======================================================================


escribe_textos:		; Lista de textos: posicion (2 bytes, +0x1000), longitud y letras; acaba con bit 7 en la posicion
	ld e,(hl)			;485e   ; la posicion
	inc hl			;485f   ; al byte alto
	ld d,(hl)			;4860   ; la posicion en DE
	inc hl			;4861   ; el siguiente byte
	bit 7,d		;4862   ; bit 7: se acabo
	ret nz			;4864   ; se acabo
	push hl			;4865   ; se guarda
	ld hl,01000h		;4866   ; en la tabla de nombres
	add hl,de			;4869   ; + 0x1000
	ex de,hl			;486a   ; en DE
	pop hl			;486b   ; el texto
	ld c,(hl)			;486c   ; la longitud
	inc hl			;486d   ; las letras
	ld b,000h		;486e   ; BC = largo
	push hl			;4870   ; se guardan
	push bc			;4871   ; y el largo
	call 0005ch		;4872   ; a la VRAM
	pop bc			;4875   ; el largo
	pop hl			;4876   ; las letras
	add hl,bc			;4877   ; tras ellas
	jr escribe_textos		;4878   ; el siguiente
vdp_rellena_tabla:		; Pone a cero la zona A de la tabla 0x4892 (longitud y direccion)
	ld hl,04892h		;487a   ; la tabla de zonas
	ld c,a			;487d   ; 4 bytes por zona
	ld b,000h		;487e   ; por 4
	sla c		;4880
	sla c		;4882
	add hl,bc			;4884   ; la zona
	ld c,(hl)			;4885   ; el largo
	inc hl			;4886
	ld b,(hl)			;4887
	inc hl			;4888   ; la direccion
	ld a,(hl)			;4889
	inc hl			;488a
	ld h,(hl)			;488b
	ld l,a			;488c
	sub a			;488d   ; ceros
	call 00056h		;488e   ; FILVRM
	ret			;4891   ; listo

; ----------------------------------------------------------------------
; DATOS vdp_zonas: Zonas de la VRAM (longitud, direccion): atributos 0x3F00,
;   patrones, nombres 0x1000, sprites, colores
;   0x4892..0x48a6  (20 bytes)
DATA_vdp_zonas:
	defb 080h,000h,000h,03fh,000h,008h,000h,020h,000h,003h,000h,010h,000h,008h,000h,000h	; 4892  ...?... ........
	defb 020h,000h,0c0h,03fh	; 48a2

; ======================================================================
; CODIGO 0x48a6..0x4917  (113 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  Utilidades  =====
; ----------------------------------------------------------------------
escribe_vdp:		; Registro C del VDP = B, guardando la copia del sistema (el 0 conserva los bits de modo)
	ld a,c			;48a6   ; registro 0?
	and a			;48a7   ; cero?
	jr nz,L_48B6		;48a8   ; no
	ld a,(0f3dfh)		;48aa   ; conserva los bits de arriba
	and 0fch		;48ad   ; sin los bits de modo
	or b			;48af   ; + B
	ld (0f3dfh),a		;48b0   ; RG0SAV
	ld b,a			;48b3   ; el valor
	jr L_48BE		;48b4   ; a escribir
L_48B6:
	cp 001h		;48b6   ; registro 1?
	jr nz,L_48BE		;48b8   ; no: tal cual
	ld a,b			;48ba   ; su copia
	ld (0f3e0h),a		;48bb   ; RG1SAV
L_48BE:
	call 00047h		;48be   ; WRTVDP
	ret			;48c1   ; listo
rellena_b:		; B bytes de A desde HL
	ld (hl),a			;48c2   ; un byte
	inc hl			;48c3   ; el siguiente
	djnz rellena_b		;48c4   ; los B
	ret			;48c6   ; listo
rellena_bc:		; BC bytes de A desde HL
	dec bc			;48c7   ; el primero lo pone el ld
	push hl			;48c8   ; HL...
	pop de			;48c9   ; ...a DE...
	inc de			;48ca   ; ...+1
	ld (hl),a			;48cb   ; el primero
	ldir		;48cc   ; y los demas copiandolo
	ret			;48ce   ; listo
lee_mando:		; A=0xFF: direccion (cursores o joystick 1); A<5: GTTRIG; mas: la tecla A de la tabla 0x4917
	push ix		;48cf   ; se guarda todo
	push iy		;48d1
	push hl			;48d3
	push bc			;48d4
	push de			;48d5
	cp 0ffh		;48d6   ; direccion?
	jr z,L_48E8		;48d8   ; GTSTCK
	cp 005h		;48da   ; disparo?
	jr nc,L_48E3		;48dc   ; si
	call 000d8h		;48de   ; GTTRIG
	jr L_48F4		;48e1   ; la respuesta
L_48E3:
	call lee_tecla		;48e3   ; una tecla
	jr L_48F5		;48e6   ; la respuesta
L_48E8:
	sub a			;48e8   ; los cursores
	call 000d5h		;48e9   ; GTSTCK 0
	and a			;48ec   ; algo?
	jr nz,L_48F4		;48ed   ; si
	ld a,001h		;48ef   ; y si no, el joystick 1
	call 000d5h		;48f1   ; GTSTCK 1
L_48F4:
	and a			;48f4   ; Z si nada
L_48F5:
	pop de			;48f5   ; se recupera todo
	pop bc			;48f6
	pop hl			;48f7
	pop iy		;48f8
	pop ix		;48fa
	ret			;48fc   ; listo
lee_tecla:		; Busca A en la tabla de teclas: fila de la matriz y bit; NZ si esta pulsada
	ld hl,04917h		;48fd   ; la tabla de teclas
L_4900:
	cp (hl)			;4900   ; esta?
	jr z,L_490E		;4901   ; si
	ld c,a			;4903   ; fin de tabla?
	ld a,(hl)			;4904   ; fin de tabla?
	and a			;4905
	jr z,L_4916		;4906   ; si: Z
	ld a,c			;4908   ; la tecla
	inc hl			;4909   ; la siguiente...
	inc hl			;490a
	inc hl			;490b
	jr L_4900		;490c   ; ...de 3 bytes
L_490E:
	inc hl			;490e   ; la fila
	ld a,(hl)			;490f   ; de la matriz
	call 00141h		;4910   ; SNSMAT
	cpl			;4913   ; pulsada = 1
	inc hl			;4914   ; el bit
	and (hl)			;4915   ; NZ si pulsada
L_4916:
	ret			;4916   ; listo

; ----------------------------------------------------------------------
; DATOS teclas: Dos teclas: 'x' (fila 5, bit 5) y 'z' (fila 5, bit 7); cero
;   acaba
;   0x4917..0x491e  (7 bytes)
DATA_teclas:
	defb 078h,005h,020h,07ah,005h,080h,000h	; 4917

; ======================================================================
; CODIGO 0x491e..0x4b91  (627 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  El titulo  =====
; ----------------------------------------------------------------------
titulo:		; Titulo animado en SCREEN 2 hasta que se pulsa el disparo
	ld bc,08201h		;491e   ; pantalla apagada
	call escribe_vdp		;4921   ; al VDP
	call sonido_apaga		;4924   ; silencio
	ld hl,03800h		;4927   ; las tablas de SCREEN 2: nombres 0x3800...
	ld (0f3c7h),hl		;492a   ; NAMBAS
	ld hl,02000h		;492d   ; ...colores 0x2000...
	ld (0f3c9h),hl		;4930   ; COLBAS
	ld hl,00000h		;4933   ; ...patrones 0...
	ld (0f3cbh),hl		;4936   ; CGPBAS
	ld hl,03b00h		;4939   ; ...atributos 0x3B00...
	ld (0f3cdh),hl		;493c   ; ATRBAS
	ld hl,01800h		;493f   ; ...sprites 0x1800
	ld (0f3cfh),hl		;4942   ; PATBAS
	ld a,0c3h		;4945   ; la interrupcion del titulo...
	ld (0fd9fh),a		;4947   ; jp...
	ld hl,04c92h		;494a   ; ...en H.TIMI
	ld (0fda0h),hl		;494d   ; ...0x4C92
	call 0007eh		;4950   ; SETGRP
	call 00072h		;4953   ; INIGRP
	ld bc,08201h		;4956   ; registro 1 = 0x82: sin imagen
	call escribe_vdp		;4959   ; al VDP
	ld bc,00107h		;495c   ; borde blanco
	call escribe_vdp		;495f   ; al VDP
	ld hl,0c0d6h		;4962   ; las variables a cero
	ld bc,03000h		;4965   ; 12 KB
	sub a			;4968   ; ceros
	call rellena_bc		;4969   ; a cero
	ld hl,00000h		;496c   ; la VRAM de patrones...
	ld bc,04000h		;496f   ; 16 KB
	ld (0c383h),a		;4972   ; (sin parpadeo)
	call 00056h		;4975   ; ...a cero
	ld hl,094b9h		;4978   ; los patrones del titulo...
	ld de,0e000h		;497b   ; a 0xE000
	call descomprime		;497e   ; ...descomprimidos
	ld de,00000h		;4981   ; a los tres tercios
	call a_vram_2k		;4984   ; tercio de arriba
	ld de,00800h		;4987   ; del medio
	call a_vram_2k		;498a   ; LDIRVM
	ld de,01000h		;498d   ; de abajo
	call a_vram_2k		;4990   ; LDIRVM
	ld hl,0993eh		;4993   ; los colores
	ld de,0e000h		;4996   ; a 0xE000
	call descomprime		;4999   ; descomprimidos
	ld de,02000h		;499c   ; a los tres tercios
	call a_vram_2k		;499f   ; tercio de arriba
	ld de,02800h		;49a2   ; del medio
	call a_vram_2k		;49a5   ; LDIRVM
	ld de,03000h		;49a8   ; de abajo
	call a_vram_2k		;49ab   ; LDIRVM
	ld hl,099afh		;49ae   ; los sprites del titulo
	ld de,01800h		;49b1   ; a la tabla de dibujos
	ld bc,000e0h		;49b4   ; 7 sprites
	call 0005ch		;49b7   ; LDIRVM
	ld hl,0c379h		;49ba   ; las 8 letras en su primera postura
	ld bc,00008h		;49bd   ; 8
	ld a,001h		;49c0   ; postura 1
	call rellena_bc		;49c2   ; todas
	ld hl,0949ah		;49c5   ; "(C) TAITO 1985"...
	ld de,0c6e7h		;49c8   ; ...en el mapa
	ld bc,00011h		;49cb   ; 17 bytes
	ldir		;49ce   ; copiados
	ld hl,0c357h		;49d0   ; bit 0: el titulo en marcha
	ld (hl),001h		;49d3   ; en marcha
	inc hl			;49d5   ; cada 5 cuadros
	ld (hl),005h		;49d6   ; la cuenta
	inc hl			;49d8   ; 0xC359...
	ld de,04b91h		;49d9   ; las posiciones de las 8 letras
	ex de,hl			;49dc   ; a DE
	ld bc,00010h		;49dd   ; 16 bytes
	ldir		;49e0   ; copiados
	ld hl,04bb1h		;49e2   ; cuanto espera cada letra
	ld de,0c36fh		;49e5   ; a 0xC36F
	ld b,008h		;49e8   ; 8 letras
L_49EA:
	ld a,(hl)			;49ea   ; la primera espera...
	ld (de),a			;49eb   ; ...de cada letra
	inc hl			;49ec
	inc hl			;49ed
	inc hl			;49ee
	inc hl			;49ef
	inc de			;49f0   ; la siguiente
	djnz L_49EA		;49f1   ; las 8
	ld bc,0e201h		;49f3   ; pantalla encendida
	call escribe_vdp		;49f6   ; al VDP
titulo_cuadro:		; Un paso de la animacion de las letras de ELEVATOR ACTION
	ld hl,0c357h		;49f9   ; los bits del titulo
espera_titulo:
	bit 7,(hl)		;49fc   ; paso pedido por la interrupcion?
	jr z,espera_titulo		;49fe   ; espera
	ld ix,04ba1h		;4a00   ; las direcciones de los dibujos de las letras
	res 7,(hl)		;4a04   ; se hace
	inc hl			;4a06   ; las posiciones...
	inc hl			;4a07   ; ...en 0xC359
	push hl			;4a08   ; se guardan
	ld hl,0c400h		;4a09   ; limpia el mapa...
	ld bc,002e0h		;4a0c   ; 23 filas
	xor a			;4a0f   ; ceros
	call rellena_bc		;4a10   ; a cero
	ld hl,0e000h		;4a13   ; ...y la zona de montaje
	ld bc,00600h		;4a16   ; 1,5 KB
	call rellena_bc		;4a19   ; a cero
	pop hl			;4a1c   ; las posiciones
	ld a,(0c383h)		;4a1d   ; alterna la mitad del dibujo
	xor 001h		;4a20   ; la otra mitad
	ld (0c383h),a		;4a22   ; guardada
	ld b,008h		;4a25   ; las 8 letras
titulo_letra:
	push bc			;4a27   ; la cuenta
	push hl			;4a28   ; las posiciones
	ld a,008h		;4a29   ; el numero de letra...
	sub b			;4a2b   ; ...es 8 - B
	ld de,04bd1h		;4a2c   ; las pares bajan...
	bit 0,a		;4a2f   ; par?
	jr z,L_4A36		;4a31   ; si
	ld de,04bd9h		;4a33   ; ...las impares suben
L_4A36:
	ld c,a			;4a36   ; la letra
	ld b,000h		;4a37   ; en BC
	push bc			;4a39   ; se guarda
	ld hl,0c36fh		;4a3a   ; le queda espera?
	add hl,bc			;4a3d   ; su espera
	ld a,(hl)			;4a3e   ; cuanto?
	and a			;4a3f   ; parada?
	jr z,titulo_mueve		;4a40   ; si: se mueve igual
	dec (hl)			;4a42   ; una menos
	jr nz,titulo_mueve		;4a43   ; aun no: se mueve
	push hl			;4a45   ; se guarda
	ld hl,0c379h		;4a46   ; la postura...
	add hl,bc			;4a49   ; su postura...
	inc (hl)			;4a4a   ; ...+1
	ld a,(hl)			;4a4b   ; cual?
	ld b,a			;4a4c   ; en B
	cp 005h		;4a4d   ; ...hasta la 5
	jr nz,titulo_espera_sig		;4a4f   ; no: la espera de la siguiente
	ld b,004h		;4a51   ; la ultima
	ld (hl),000h		;4a53   ; de vuelta a 0
	pop hl			;4a55   ; la espera...
	push hl			;4a56   ; ...se guarda...
	ld (hl),000h		;4a57   ; ...a cero: parada
	ld a,001h		;4a59   ; la letra 1 manda...
	cp c			;4a5b   ; es la 1?
	jr nz,titulo_espera_sig		;4a5c   ; no
	ld hl,0c357h		;4a5e   ; ...cuando llega, se acaba la animacion
	set 5,(hl)		;4a61   ; bit 5: acabado
	jp titulo_rotulo		;4a63   ; a los rotulos
titulo_espera_sig:		; La espera de la postura siguiente
	ld hl,04bb1h		;4a66   ; las esperas
	sla c		;4a69   ; 4 por letra
	sla c		;4a6b
	dec b			;4a6d   ; la postura - 1
	ld a,b			;4a6e
	add a,c			;4a6f   ; + letra x 4
	ld c,a			;4a70
	ld b,000h		;4a71   ; en BC
	add hl,bc			;4a73   ; la entrada
	ld a,(hl)			;4a74   ; la espera
	pop hl			;4a75   ; su sitio
	ld (hl),a			;4a76   ; guardada
titulo_mueve:
	pop bc			;4a77   ; la letra
	push bc			;4a78   ; se guarda
	ld hl,0c379h		;4a79   ; la postura...
	add hl,bc			;4a7c   ; su postura
	ld a,(hl)			;4a7d   ; cual?
	dec a			;4a7e   ; - 1
	add a,a			;4a7f   ; x 2
	ld c,a			;4a80   ; en C
	ld a,(0c383h)		;4a81   ; ...y la mitad
	and a			;4a84   ; la mitad 0?
	jr z,titulo_avance		;4a85   ; si
	inc c			;4a87   ; la otra
titulo_avance:
	ex de,hl			;4a88   ; la tabla de pasos
	add hl,bc			;4a89   ; la entrada
	ld a,(hl)			;4a8a   ; lo que avanza
	pop bc			;4a8b   ; la letra
	sla c		;4a8c   ; x 2
	pop hl			;4a8e   ; las posiciones
	push hl			;4a8f   ; se guardan
	add hl,bc			;4a90   ; la de esta letra
	ld e,(hl)			;4a91   ; baja
	inc hl			;4a92
	ld d,(hl)			;4a93   ; alta
	ld c,a			;4a94   ; el avance
	ex de,hl			;4a95   ; la posicion en HL
	bit 7,a		;4a96   ; hacia atras?
	jr z,titulo_pon_letra		;4a98   ; adelante
	dec b			;4a9a   ; atras: B = 0xFF
titulo_pon_letra:
	add hl,bc			;4a9b   ; se suma
	ex de,hl			;4a9c   ; en DE
	ld (hl),d			;4a9d   ; guardada
	dec hl			;4a9e
	ld (hl),e			;4a9f
	call titulo_letra_dibujo		;4aa0   ; la letra al montaje
	pop hl			;4aa3   ; las posiciones
	pop bc			;4aa4   ; la cuenta
	inc ix		;4aa5   ; el dibujo de la siguiente
	inc ix		;4aa7
	dec b			;4aa9   ; una menos
	jp nz,titulo_letra		;4aaa   ; las 8
	ld hl,0e160h		;4aad   ; el montaje...
	ld de,0c400h		;4ab0   ; ...al mapa
	ld bc,002e0h		;4ab3   ; 23 filas
	ldir		;4ab6   ; copiadas
	ld hl,0c357h		;4ab8   ; a la VRAM en el proximo cuadro
	set 6,(hl)		;4abb   ; bit 6
	bit 5,(hl)		;4abd   ; acabada la animacion?
	jp z,titulo_cuadro		;4abf   ; no: otro paso
titulo_rotulo:		; Las letras ya en su sitio: escribe los rotulos de abajo uno a uno
	pop af			;4ac2   ; fuera lo que habia en la pila
	pop af			;4ac3   ; lo de la pila
	pop af			;4ac4
	pop af			;4ac5
	inc hl			;4ac6   ; la cuenta de rotulos...
	inc hl			;4ac7
	xor a			;4ac8   ; ...a cero
	ld (hl),a			;4ac9
	ld hl,0c560h		;4aca   ; la zona de los rotulos a cero
	ld bc,00100h		;4acd   ; 256 bytes
	call rellena_bc		;4ad0   ; a cero
titulo_rotulo_sig:
	ld hl,0c357h		;4ad3   ; los bits del titulo
L_4AD6:
	bit 7,(hl)		;4ad6   ; paso pedido?
	jr z,L_4AD6		;4ad8   ; espera
	res 7,(hl)		;4ada   ; se hace
	inc hl			;4adc   ; la cuenta...
	inc hl			;4add   ; ...de rotulos
	ld c,(hl)			;4ade   ; el rotulo siguiente
	inc (hl)			;4adf   ; +1
	sla c		;4ae0   ; x 2
	ld b,000h		;4ae2   ; en BC
	ld hl,04be1h		;4ae4   ; la tabla de rotulos
	add hl,bc			;4ae7   ; la entrada
	ld a,(hl)			;4ae8   ; el puntero...
	inc hl			;4ae9
	ld h,(hl)			;4aea   ; ...al rotulo
	ld l,a			;4aeb
	ld a,(hl)			;4aec   ; alto
	inc hl			;4aed   ; +1
	ld c,(hl)			;4aee   ; ancho
	inc hl			;4aef   ; +2
	ld d,000h		;4af0   ; posicion
	ld e,(hl)			;4af2   ; en E
	push hl			;4af3   ; se guarda
	ld hl,0c560h		;4af4   ; la zona de los rotulos
	add hl,de			;4af7   ; + posicion
	ex de,hl			;4af8   ; a DE
	pop hl			;4af9   ; el rotulo
	inc hl			;4afa   ; el origen
	push af			;4afb   ; el alto
	ld a,(hl)			;4afc   ; de donde
	inc hl			;4afd   ; el byte alto del origen
	ld h,(hl)			;4afe   ; el origen en HL
	ld l,a			;4aff
	pop af			;4b00   ; el alto
	call copia_bloque		;4b01   ; a la zona
	ld hl,0c359h		;4b04   ; ya van los 6?
	ld a,(hl)			;4b07   ; la cuenta
	dec hl			;4b08   ; 0xC357
	dec hl			;4b09
	cp 006h		;4b0a   ; el sexto?
	jr z,titulo_espera_tecla		;4b0c   ; si: a esperar la tecla
	set 6,(hl)		;4b0e   ; no: a la VRAM y el siguiente
	jr titulo_rotulo_sig		;4b10   ; el siguiente
titulo_espera_tecla:		; Parpadea "PUSH SPACE KEY" hasta que se pulsa el disparo
	ld (hl),058h		;4b12   ; bit 6 + bits 3 y 4
titulo_vuelca:
	bit 6,(hl)		;4b14   ; volcado?
	jr nz,titulo_vuelca		;4b16   ; espera
	set 2,(hl)		;4b18   ; bit 2: parpadeo
	inc hl			;4b1a   ; la cuenta...
	inc hl			;4b1b
	ld (hl),000h		;4b1c   ; ...a cero
titulo_lee_disparo:
	sub a			;4b1e   ; la barra (GTTRIG 0)
	call lee_mando		;4b1f   ; la barra?
	jr nz,titulo_fin		;4b22   ; pulsada: empieza
	ld a,001h		;4b24   ; el boton del joystick 1?
	call lee_mando		;4b26   ; el boton 1
	jr nz,titulo_fin		;4b29   ; pulsado: empieza
	ld hl,0c357h		;4b2b   ; cada cuadro de parpadeo
	bit 7,(hl)		;4b2e   ; toca parpadear?
	jr z,titulo_lee_disparo		;4b30   ; no
	push hl			;4b32   ; se guarda
	ld hl,0c6a9h		;4b33   ; borra el rotulo
	ld bc,0000eh		;4b36   ; 14 letras
	xor a			;4b39   ; en blanco
	call rellena_bc		;4b3a   ; borradas
	pop hl			;4b3d   ; 0xC357
	push hl			;4b3e   ; se guarda
	inc hl			;4b3f   ; la cuenta...
	inc hl			;4b40
	ld a,001h		;4b41   ; alterna
	xor (hl)			;4b43   ; ...alterna
	ld (hl),a			;4b44   ; guardada
	jr z,titulo_parpadeo		;4b45   ; 0: borrado
	ld hl,094abh		;4b47   ; o lo escribe
	ld de,0c6a9h		;4b4a   ; en su fila
	ld bc,0000eh		;4b4d   ; 14 letras
	ldir		;4b50   ; copiadas
titulo_parpadeo:
	pop hl			;4b52   ; 0xC357
	res 7,(hl)		;4b53   ; hecho
	set 6,(hl)		;4b55   ; a volcar
	jr titulo_lee_disparo		;4b57   ; otra vez
titulo_fin:		; Pide a la interrupcion que deje el titulo y espera a que lo haga
	ld hl,0c357h		;4b59
	set 1,(hl)		;4b5c   ; bit 1: acabar
L_4B5E:
	ld a,(hl)			;4b5e   ; la interrupcion lo pone a cero
	and a			;4b5f   ; cero?
	jr nz,L_4B5E		;4b60   ; espera
	ld (0c0d6h),a		;4b62   ; no se juega
	di			;4b65   ; sin interrupciones
	ret			;4b66   ; listo
titulo_letra_dibujo:		; Copia un trozo de 2x4 de la letra a la zona de montaje
	ld hl,0e000h		;4b67   ; la zona de montaje...
	add hl,de			;4b6a   ; ...+ DE
	ld e,(ix+000h)		;4b6b   ; la posicion...
	ld d,(ix+001h)		;4b6e   ; ...de la letra
	ex de,hl			;4b71   ; el origen en HL
	ld bc,00002h		;4b72   ; 2 de ancho
	ld a,004h		;4b75   ; 4 de alto
copia_bloque:		; A filas de BC bytes de HL a DE (filas de 32)
	push bc			;4b77   ; el ancho
	push de			;4b78   ; el destino
	ldir		;4b79   ; una fila
	pop de			;4b7b   ; el destino
	ex de,hl			;4b7c
	ld bc,00020h		;4b7d   ; + 32
	add hl,bc			;4b80
	ex de,hl			;4b81   ; en DE
	pop bc			;4b82   ; el ancho
	dec a			;4b83   ; una menos
	jr nz,copia_bloque		;4b84   ; las A
	ret			;4b86   ; listo
a_vram_2k:		; Los 2 KB de 0xE000 a la VRAM DE
	ld hl,0e000h		;4b87   ; de 0xE000
	ld bc,00800h		;4b8a   ; 2 KB
	call 0005ch		;4b8d   ; LDIRVM
	ret			;4b90   ; listo

; ----------------------------------------------------------------------
; DATOS titulo_posiciones: Posicion inicial de las 8 letras
;   0x4b91..0x4ba1  (16 bytes)
DATA_titulo_posiciones:
	defb 0e5h,000h,0c8h,000h,0abh,000h,08eh,000h,071h,000h,054h,000h,037h,000h,01ah,000h	; 4b91  ........q.T.7...

; ----------------------------------------------------------------------
; DATOS titulo_dibujos: Donde estan los dibujos de cada letra
;   0x4ba1..0x4bb1  (16 bytes)
DATA_titulo_dibujos:
	defb 0deh,093h,0e6h,093h,0deh,093h,0eeh,093h,0f6h,093h,0feh,093h,006h,094h,00eh,094h	; 4ba1  ................

; ----------------------------------------------------------------------
; DATOS titulo_esperas: Las esperas de cada letra, cuatro por letra
;   0x4bb1..0x4bd1  (32 bytes)
DATA_titulo_esperas:
	defb 028h,014h,056h,000h,02ah,015h,016h,00ch,02ch,014h,052h,000h,02eh,015h,016h,008h	; 4bb1  (.V.*...,.R.....
	defb 030h,014h,04eh,000h,032h,015h,016h,004h,034h,014h,04ah,000h,036h,015h,016h,000h	; 4bc1  0.N.2...4.J.6...

; ----------------------------------------------------------------------
; DATOS titulo_pasos: Lo que avanza cada letra en cada postura (pares e
;   impares)
;   0x4bd1..0x4be1  (16 bytes)
DATA_titulo_pasos:
	defb 020h,000h,0e0h,000h,000h,000h,000h,000h,020h,000h,0e0h,0e0h,020h,000h,000h,000h	; 4bd1   ....... ... ...

; ----------------------------------------------------------------------
; DATOS titulo_rotulos: Los 6 rotulos de abajo
;   0x4be1..0x4bed  (12 bytes)
DATA_titulo_rotulos:
	defb 0edh,04bh,0f2h,04bh,0f7h,04bh,0fch,04bh,001h,04ch,006h,04ch	; 4be1  .K.K.K.K.L.L

; ----------------------------------------------------------------------
; DATOS titulo_rotulos_d: Alto, ancho, posicion y origen de cada rotulo
;   0x4bed..0x4c0b  (30 bytes)
DATA_titulo_rotulos_d:
	defb 006h,003h,047h,016h,094h,006h,003h,04ah,028h,094h,006h,003h,04dh,03ah,094h,006h	; 4bed  ..G....J(...M:..
	defb 002h,050h,04ch,094h,006h,003h,052h,058h,094h,008h,006h,015h,06ah,094h	; 4bfd  .PL...RX....j.

; ----------------------------------------------------------------------
; DATOS sin_uso_texto_lento: CODIGO SIN USO: escribe C letras de HL en DE de
;   una en una con una espera entre ellas. Nada salta a 0x4C0B: en todo el
;   cartucho no hay saltos indirectos (ni jp (hl) ni direcciones en la pila) y
;   ningun call ni jp lleva esa direccion
;   0x4c0b..0x4c26  (27 bytes)

; ----------------------------------------------------------------------
; =====  Codigo que nada alcanza (ver la cabecera de datos)  =====
; ----------------------------------------------------------------------
DATA_sin_uso_texto_lento:
	defb 0c5h,04eh,006h,000h,023h,0e5h,021h,064h,000h,0cdh,06ch,04eh,0e1h,0edh,0a0h,0e5h	; 4c0b  .N..#.!d..lN....
	defb 021h,0d0h,0c0h,0cbh,0feh,0e1h,0eah,010h,04ch,0c1h,0c9h	; 4c1b  !.......L..

; ======================================================================
; CODIGO 0x4c26..0x4d3d  (279 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  La interrupcion de la partida  =====
; ----------------------------------------------------------------------
int_partida:		; Gancho de H.TIMI en partida: en cuadros alternos vuelca el mapa y mueve lo que va a 30 por segundo; siempre los temporizadores
	di			;4c26   ; sin interrupciones
	ld a,(0c0d6h)		;4c27   ; se esta jugando?
	and a			;4c2a   ; no se juega...
	jr z,int_temporizadores		;4c2b   ; ...solo los temporizadores
	ld bc,0c201h		;4c2d   ; pantalla sin interrupcion del VDP mientras dura
	call escribe_vdp		;4c30   ; al VDP
	ld a,(0c326h)		;4c33   ; cuadro par o impar
	inc a			;4c36   ; +1
	cp 002h		;4c37   ; de 0 a 1
	ld (0c326h),a		;4c39   ; guardado
	jr c,int_partida_trabajo		;4c3c   ; 1: a trabajar
	sub a			;4c3e   ; uno de cada dos se salta
	ld (0c326h),a		;4c3f   ; a cero
	jr int_partida_reloj		;4c42   ; solo el reloj
int_partida_trabajo:
	call sprites_a_vram		;4c44   ; los sprites a la VRAM
	call vuelca_mapa		;4c47   ; el mapa a la VRAM si toca
	call marcador		;4c4a   ; los puntos y las vidas
	call sonido_cuadro		;4c4d   ; el sonido
int_partida_reloj:		; Pantalla con interrupcion otra vez; el reloj de la ronda
	ld bc,0e201h		;4c50   ; registro 1 = 0xE2: imagen e interrupcion
	call escribe_vdp		;4c53   ; al VDP
	ld a,(0c39fh)		;4c56   ; pasado el reloj de la ronda?
	and a			;4c59   ; ya?
	jr nz,int_temporizadores		;4c5a   ; si: nada
	ld hl,0c3a0h		;4c5c   ; cuadros...
	inc (hl)			;4c5f   ; +1
	jr nz,int_temporizadores		;4c60   ; sin desbordar: nada
	inc hl			;4c62   ; ...de 256 en 256
	inc (hl)			;4c63   ; +1
	ld a,038h		;4c64   ; a los 0x38 x 256 cuadros (unos 4 minutos)...
	cp (hl)			;4c66   ; llega?
	jr nc,int_temporizadores		;4c67   ; no
	ld (0c39fh),a		;4c69   ; ...se marca: los enemigos se portan como en la ronda 6
int_temporizadores:
	di			;4c6c   ; sin interrupciones
	call temporizadores_cuadro		;4c6d   ; los 50 temporizadores
	xor a			;4c70   ; cero
	ld (0c326h),a		;4c71   ; la cuenta par/impar a cero
	ei			;4c74   ; interrupciones
	ret			;4c75   ; listo
vuelca_mapa:		; Si lo pide el bit 7 de 0xC0D0: 21 filas del mapa desde el scroll a la VRAM (fila 2 en adelante)
	ld a,(0c0d0h)		;4c76   ; los bits del scroll
	bit 7,a		;4c79   ; bit 7: volcar?
	ret z			;4c7b   ; no
	res 7,a		;4c7c   ; hecho
	ld (0c0d0h),a		;4c7e   ; guardado
	ld hl,(0c0d1h)		;4c81   ; el desplazamiento del scroll
	ld bc,0c400h		;4c84   ; dentro del mapa
	add hl,bc			;4c87   ; + 0xC400
	ld de,01040h		;4c88   ; debajo de las dos filas del marcador
	ld bc,002a0h		;4c8b   ; 21 filas de 32
	call 0005ch		;4c8e   ; LDIRVM
	ret			;4c91   ; listo

; ----------------------------------------------------------------------
; =====  La interrupcion del titulo  =====
; ----------------------------------------------------------------------
int_titulo:		; Gancho de H.TIMI en el titulo: vuelca el mapa, cuenta los cuadros y los rotulos
	ld hl,0c357h		;4c92   ; los bits del titulo
	bit 2,(hl)		;4c95   ; bit 2: parpadeo de "PUSH SPACE KEY"
	jp nz,int_titulo_parpadeo		;4c97   ; si
	bit 4,(hl)		;4c9a   ; bit 4: ya con los rotulos
	jr nz,int_titulo_rotulos		;4c9c   ; si
	bit 6,(hl)		;4c9e   ; bit 6: volcar el mapa
	jr z,int_titulo_letras		;4ca0   ; no
	res 6,(hl)		;4ca2   ; hecho
	push hl			;4ca4   ; se guarda
	ld hl,0c400h		;4ca5   ; el mapa entero a 0x3800
	ld de,03800h		;4ca8   ; la tabla de nombres del titulo
	ld bc,00300h		;4cab   ; 768
	call 0005ch		;4cae   ; LDIRVM
	pop hl			;4cb1   ; 0xC357
int_titulo_letras:
	bit 5,(hl)		;4cb2   ; bit 5: animacion acabada
	jr nz,int_titulo_a_rotulos		;4cb4   ; si
	inc hl			;4cb6   ; cada 5 cuadros...
	dec (hl)			;4cb7   ; cuenta - 1
	ret nz			;4cb8   ; no toca
	ld (hl),005h		;4cb9   ; otros 5
	dec hl			;4cbb   ; 0xC357
	set 7,(hl)		;4cbc   ; ...un paso de las letras (bit 7)
	ret			;4cbe   ; listo
int_titulo_a_rotulos:
	res 5,(hl)		;4cbf   ; animacion acabada...
	set 4,(hl)		;4cc1   ; ...a los rotulos
	inc hl			;4cc3   ; la cuenta...
	ld (hl),00fh		;4cc4   ; ...a 15
	dec hl			;4cc6   ; 0xC357
int_titulo_rotulos:
	inc hl			;4cc7   ; la cuenta
	dec (hl)			;4cc8   ; cada 15 cuadros...
	jr nz,int_titulo_vuelca_rotulo		;4cc9   ; no toca
	ld (hl),00fh		;4ccb   ; otros 15
	dec hl			;4ccd   ; 0xC357
	set 7,(hl)		;4cce   ; ...un rotulo
	inc hl			;4cd0   ; la cuenta
int_titulo_vuelca_rotulo:
	dec hl			;4cd1   ; 0xC357
	bit 6,(hl)		;4cd2   ; volcar?
	jr z,L_4CFB		;4cd4   ; no
	res 6,(hl)		;4cd6   ; hecho
	push hl			;4cd8   ; se guarda
	ld hl,0c560h		;4cd9   ; las 8 filas de abajo a 0x3960
	ld de,03960h		;4cdc   ; filas 11 a 18 de la pantalla
	ld bc,00100h		;4cdf   ; 256 bytes
	call 0005ch		;4ce2   ; LDIRVM
	pop hl			;4ce5   ; 0xC357
	push hl			;4ce6   ; se guarda
	inc hl			;4ce7   ; la cuenta...
	inc hl			;4ce8   ; ...de rotulos
	ld a,(hl)			;4ce9   ; el rotulo 5...
	cp 005h		;4cea   ; el quinto?
	jr nz,int_titulo_sprites		;4cec   ; no
	ld hl,04d51h		;4cee   ; ...trae dos sprites mas
	ld de,03b14h		;4cf1   ; sprites 5 y 6
	ld bc,00008h		;4cf4   ; 8 bytes
	call 0005ch		;4cf7   ; LDIRVM
int_titulo_sprites:
	pop hl			;4cfa   ; 0xC357
L_4CFB:
	bit 3,(hl)		;4cfb   ; bit 3: los sprites del titulo
	ret z			;4cfd   ; no
	inc hl			;4cfe   ; la cuenta...
	ld (hl),01eh		;4cff   ; ...a 30
	ld hl,04d3dh		;4d01   ; siete sprites a 0x3B00
	ld de,03b00h		;4d04   ; desde el sprite 0
	ld bc,0001ch		;4d07   ; 7 sprites
	call 0005ch		;4d0a   ; LDIRVM
	ret			;4d0d   ; listo
int_titulo_parpadeo:		; "PUSH SPACE KEY" cada 30 cuadros; con el bit 1 se pasa a la interrupcion de la partida
	bit 1,(hl)		;4d0e   ; bit 1: fin del titulo
	jr z,int_titulo_rotulo_pulsa		;4d10   ; no
	ld (hl),000h		;4d12   ; todo a cero
	ld a,0c3h		;4d14   ; el otro gancho
	ld (0fd9fh),a		;4d16   ; jp...
	ld hl,int_partida		;4d19   ; ...0x4C26
	ld (0fda0h),hl		;4d1c   ; en H.TIMI
	ret			;4d1f   ; listo
int_titulo_rotulo_pulsa:
	bit 6,(hl)		;4d20   ; toca volcar?
	jr z,int_titulo_cuenta		;4d22   ; no
	res 6,(hl)		;4d24   ; hecho
	push hl			;4d26   ; se guarda
	ld hl,0c6a9h		;4d27   ; la fila de "PUSH SPACE KEY"
	ld de,03aa9h		;4d2a   ; en su sitio
	ld bc,0000eh		;4d2d   ; 14 letras
	call 0005ch		;4d30   ; LDIRVM
	pop hl			;4d33   ; 0xC357
int_titulo_cuenta:
	inc hl			;4d34   ; la cuenta
	dec (hl)			;4d35   ; - 1
	ret nz			;4d36   ; no toca
	ld (hl),01eh		;4d37   ; 30 cuadros
	dec hl			;4d39   ; 0xC357
	set 7,(hl)		;4d3a   ; bit 7: toca parpadear
	ret			;4d3c   ; listo

; ----------------------------------------------------------------------
; DATOS titulo_sprites: Siete sprites del titulo (Y, X, dibujo, color)
;   0x4d3d..0x4d51  (20 bytes)
DATA_titulo_sprites:
	defb 058h,0ach,000h,006h,068h,0ach,004h,006h,070h,0b0h,008h,004h,058h,0c0h,00ch,004h	; 4d3d  X...h...p...X...
	defb 068h,0c0h,010h,004h	; 4d4d

; ----------------------------------------------------------------------
; DATOS titulo_sprites_5: Los dos sprites que trae el rotulo 5
;   0x4d51..0x4d59  (8 bytes)
DATA_titulo_sprites_5:
	defb 077h,090h,014h,00ah,07fh,090h,018h,00ah	; 4d51  w.......

; ======================================================================
; CODIGO 0x4d59..0x4e06  (173 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  El slot de la pagina 2  =====
; ----------------------------------------------------------------------
busca_pagina_2:		; Busca en los slots la segunda mitad del cartucho (0x8000) y la conecta con ENASLT
	ld de,0fcc1h		;4d59   ; EXPTBL: slots expandidos
	ld c,000h		;4d5c   ; slot 0
L_4D5E:
	ld a,(de)			;4d5e   ; expandido?
	or c			;4d5f   ; con el numero
	ld c,a			;4d60   ; en C
	push de			;4d61   ; se guarda
L_4D62:
	ld hl,04000h		;4d62   ; los dos primeros bytes de 0x4000 de ese slot...
	call lee_dos_slot		;4d65   ; DE = sus dos primeros bytes
	push hl			;4d68   ; se guarda
	ld hl,04241h		;4d69   ; ...son "AB"?
	rst 20h			;4d6c   ; DCOMPR
	pop hl			;4d6d   ; la direccion
	jr nz,busca_sig_slot		;4d6e   ; no
	call lee_dos_slot		;4d70   ; y los de 0x4010...
	ld hl,04010h		;4d73   ; ...son los de este INIT?
	rst 20h			;4d76   ; DCOMPR
	jr nz,busca_sig_slot		;4d77   ; no
	ld hl,04010h		;4d79   ; y los de 0x4012...
	call lee_dos_slot		;4d7c   ; los dos bytes
	ld hl,031f3h		;4d7f   ; ...son "F3 31" (di / ld sp)?
	rst 20h			;4d82   ; DCOMPR
	jr z,conecta_pagina_2		;4d83   ; es el cartucho
busca_sig_slot:
	ld a,c			;4d85   ; el slot
	and a			;4d86   ; expandido?
	jp p,busca_sig_primario		;4d87   ; slot no expandido: siguiente
	add a,004h		;4d8a   ; subslot siguiente
	ld c,a			;4d8c   ; el subslot
	cp 090h		;4d8d   ; quedan?
	jr c,L_4D62		;4d8f   ; si
	and 003h		;4d91   ; el primario
	ld c,a			;4d93   ; en C
busca_sig_primario:
	pop de			;4d94   ; EXPTBL
	inc de			;4d95   ; el siguiente
	inc c			;4d96   ; el slot siguiente
	ld a,c			;4d97   ; cual?
	cp 004h		;4d98   ; hasta el 3
	jr c,L_4D5E		;4d9a   ; quedan
	pop hl			;4d9c   ; no esta: se vuelve
	ret			;4d9d   ; listo
conecta_pagina_2:
	ld a,c			;4d9e   ; el slot
	ld (0fe6bh),a		;4d9f   ; lo apunta
	ld hl,08000h		;4da2   ; ENASLT en 0x8000
	call 00024h		;4da5   ; ENASLT
	pop de			;4da8   ; lo de la pila
	ret			;4da9   ; listo
lee_dos_slot:		; DE = dos bytes de HL en el slot C (con RDSLT)
	call lee_uno_slot		;4daa   ; el primero
	ld e,d			;4dad   ; en E
lee_uno_slot:
	ld a,c			;4dae   ; el slot
	push bc			;4daf   ; se guardan
	push de			;4db0
	call 0000ch		;4db1   ; RDSLT
	pop de			;4db4   ; se recuperan
	pop bc			;4db5   ; el slot
	ld d,a			;4db6   ; el byte en D
	inc hl			;4db7   ; el siguiente
	ret			;4db8   ; listo

; ----------------------------------------------------------------------
; =====  Los temporizadores  =====
; ----------------------------------------------------------------------
temporizadores_a_cero:		; Los 50 temporizadores de 0xC09E a cero
	ld hl,0c09eh		;4db9   ; 0xC09E
	ld b,032h		;4dbc   ; 50
	sub a			;4dbe   ; ceros
	call rellena_b		;4dbf   ; a cero
	ret			;4dc2   ; listo
temporizadores_cuadro:		; En cada interrupcion, cada temporizador que no este a cero baja 1
	push hl			;4dc3   ; se guardan
	push bc			;4dc4
	ld hl,0c09eh		;4dc5   ; 0xC09E
	ld b,032h		;4dc8   ; 50
L_4DCA:
	ld a,(hl)			;4dca   ; cuanto le queda?
	and a			;4dcb   ; cero?
	jr z,temporizador_sig		;4dcc   ; si: nada
	dec (hl)			;4dce   ; - 1
temporizador_sig:
	inc hl			;4dcf   ; el siguiente
	djnz L_4DCA		;4dd0   ; los 50
	pop bc			;4dd2   ; se recuperan
	pop hl			;4dd3
	ret			;4dd4   ; listo
pon_temporizador:		; Temporizador A = B cuadros
	push hl			;4dd5   ; se guardan
	push de			;4dd6
	ld e,a			;4dd7   ; el numero...
	ld d,000h		;4dd8   ; ...en DE
	ld hl,0c09eh		;4dda   ; la tabla
	add hl,de			;4ddd   ; + numero
	ld (hl),b			;4dde   ; = B
	pop de			;4ddf   ; se recuperan
	pop hl			;4de0
	ret			;4de1   ; listo
lee_temporizador:		; NZ si el temporizador A sigue corriendo
	push hl			;4de2   ; se guardan
	push de			;4de3
	ld e,a			;4de4   ; el numero...
	ld d,000h		;4de5   ; ...en DE
	ld hl,0c09eh		;4de7   ; la tabla
	add hl,de			;4dea   ; + numero
	ld a,(hl)			;4deb   ; cuanto le queda
	and a			;4dec   ; NZ si algo
	pop de			;4ded   ; se recuperan
	pop hl			;4dee
	ret			;4def   ; listo
divide:		; H / L: D = cociente, A = resto (L = 0: nada)
	ld a,l			;4df0   ; el divisor
	and a			;4df1   ; cero?
	ret z			;4df2   ; si: nada
	xor a			;4df3   ; resto 0
	ld d,a			;4df4   ; cociente 0
	ld b,008h		;4df5   ; 8 bits
L_4DF7:
	rl h		;4df7   ; un bit del dividendo...
	rla			;4df9   ; ...al resto
	sla d		;4dfa   ; el cociente, un bit
	cp l			;4dfc   ; cabe?
	jr nc,divide_resta		;4dfd   ; si
divide_sig:
	djnz L_4DF7		;4dff   ; los 8
	ret			;4e01   ; listo
divide_resta:
	sub l			;4e02   ; se resta...
	inc d			;4e03   ; ...y un 1 en el cociente
	jr divide_sig		;4e04   ; sigue

; ----------------------------------------------------------------------
; DATOS sin_uso_aritmetica: CODIGO SIN USO: una division y una multiplicacion
;   de 16 bits (0x4E06, 0x4E21, 0x4E29). Nada las llama: el unico "cd 21 4e"
;   del cartucho esta dentro de otra instruccion (0x534F)
;   0x4e06..0x4e41  (59 bytes)
DATA_sin_uso_aritmetica:
	defb 03eh,010h,0cbh,023h,0cbh,012h,0edh,06ah,038h,009h,0edh,042h,030h,008h,009h,03dh	; 4e06  >..#...j8..B0..=
	defb 020h,0f0h,0c9h,0a7h,0edh,042h,01ch,03dh,020h,0e8h,0c9h,0c5h,0e5h,0c1h,0cdh,029h	; 4e16   ....B.= ......)
	defb 04eh,0c1h,0c9h,03eh,010h,021h,000h,000h,0cbh,03ah,0cbh,01bh,030h,001h,009h,0cbh	; 4e26  N..>.!...:..0...
	defb 01ch,0cbh,01dh,0cbh,01ah,03dh,020h,0f2h,0cbh,01bh,0c9h	; 4e36  .....= ....

; ======================================================================
; CODIGO 0x4e41..0x4eaf  (110 bytes)
; ======================================================================


azar:		; Numero al azar de 1 a B, con el registro R y la semilla de 0xC3A3
	push bc			;4e41   ; se guarda
	ld b,a			;4e42   ; el tope en B
	ld a,(0c3a3h)		;4e43   ; la semilla
	ld c,a			;4e46   ; en C
	ld a,r		;4e47   ; el refresco del Z80
	srl a		;4e49   ; / 2
	add a,c			;4e4b   ; + semilla
	sla a		;4e4c   ; x 2: el bit 7 al acarreo
	jr c,azar_bit		;4e4e   ; con acarreo
	bit 3,a		;4e50   ; bit 3?
	jr nz,azar_uno		;4e52   ; si: 1
	jr azar_cero		;4e54   ; no: 0
azar_bit:
	bit 3,a		;4e56   ; bit 3?
	jr nz,azar_cero		;4e58   ; si: 0
azar_uno:
	set 0,a		;4e5a   ; el bit 0 a 1
	jr azar_guarda		;4e5c   ; guardado
azar_cero:
	res 0,a		;4e5e   ; el bit 0 a 0
azar_guarda:
	ld (0c3a3h),a		;4e60   ; la semilla nueva
azar_modulo:
	cp b			;4e63   ; cabe?
	jr c,azar_fin		;4e64   ; si
	sub b			;4e66   ; - tope
	jr azar_modulo		;4e67   ; otra vez
azar_fin:
	inc a			;4e69   ; de 1 a B
	pop bc			;4e6a   ; se recupera
	ret			;4e6b   ; listo
espera:		; Espera de bucle: HL x 100 vueltas (no cuenta cuadros)
	push de			;4e6c   ; se guarda
espera_100:
	ld de,00064h		;4e6d   ; 100 vueltas...
espera_vuelta:
	dec de			;4e70   ; - 1
	ld a,d			;4e71
	or e			;4e72   ; cero?
	jr nz,espera_vuelta		;4e73   ; no
	dec hl			;4e75   ; ...HL veces
	ld a,h			;4e76
	or l			;4e77   ; cero?
	jr nz,espera_100		;4e78   ; no
	pop de			;4e7a   ; se recupera
	ret			;4e7b   ; listo
agente_entra:		; El agente en juego, de pie en la X 0x64 e Y 0x78, y los 8 bytes de 0x4EAF a 0xC078
	ld ix,0c0d8h		;4e7c
	ld iy,0c000h		;4e80   ; sus sprites, los primeros del buffer
	ld (ix+000h),001h		;4e84   ; bit 0: en juego
	ld (ix+001h),064h		;4e88   ; X
	ld (ix+002h),078h		;4e8c   ; Y
	ld (ix+003h),001h		;4e90   ; de pie
	ld (ix+004h),001h		;4e94   ; cuadro 1
	ld b,003h		;4e98   ; tres sprites
	ld hl,05856h		;4e9a   ; los dibujos del agente
	ld (0c0ddh),hl		;4e9d   ; puestos
	call pon_sprites		;4ea0   ; al buffer
	ld hl,04eafh		;4ea3   ; los dos sprites fijos...
	ld de,0c078h		;4ea6   ; ...a los sprites 30 y 31
	ld bc,00008h		;4ea9   ; 8 bytes
	ldir		;4eac   ; copiados
	ret			;4eae   ; listo

; ----------------------------------------------------------------------
; DATOS sprites_fijos: Dos sprites fijos (Y, X, dibujo, color) que van a
;   0xC078
;   0x4eaf..0x4eb7  (8 bytes)
DATA_sprites_fijos:
	defb 0afh,010h,0dch,006h,0b8h,010h,0e0h,00bh	; 4eaf  ........

; ======================================================================
; CODIGO 0x4eb7..0x584e  (2455 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  El agente  =====
; ----------------------------------------------------------------------
agente_cuadro:		; Un cuadro del agente: lee el mando y lo mueve segun la postura
	ex af,af'			;4eb7   ; se guarda A
	xor a			;4eb8   ; sin disparo en este cuadro
	ld (0c39ah),a		;4eb9   ; 0xC39A a cero
	ex af,af'			;4ebc   ; A otra vez
	ld ix,0c0d8h		;4ebd   ; la ficha del agente
	ld iy,0c000h		;4ec1   ; sus sprites en el buffer
	bit 0,(ix+000h)		;4ec5   ; en juego?
	jp z,agente_fin		;4ec9   ; no: nada
	ld a,000h		;4ecc   ; el temporizador 0...
	call lee_temporizador		;4ece   ; ...aun corriendo: este cuadro no se mueve
	jp nz,agente_fin		;4ed1   ; si: nada
	ld a,000h		;4ed4   ; el siguiente movimiento dentro de 7 cuadros
	ld b,007h		;4ed6   ; 7 cuadros
	call pon_temporizador		;4ed8   ; puesto
	ld a,(ix+000h)		;4edb   ; los bits
	bit 6,a		;4ede   ; bit 6: muriendo
	jr nz,agente_muere		;4ee0   ; si
	bit 2,a		;4ee2   ; bit 2: en la escalera mecanica
	jp nz,agente_en_escalera		;4ee4   ; si
	bit 3,a		;4ee7   ; bit 3: en una puerta
	jp nz,agente_en_puerta		;4ee9   ; si
	bit 4,a		;4eec   ; bit 4: saltando
	jp nz,agente_salta		;4eee   ; si
	call agente_escalera		;4ef1   ; arriba o abajo en una escalera mecanica?
	or a			;4ef4   ; se ha subido?
	ret nz			;4ef5   ; si: listo
	jp agente_mando		;4ef6   ; el mando
agente_muere:		; Las tres maneras de morir: cada una con su cuenta de cuadros
	ld a,000h		;4ef9   ; un paso cada 14 cuadros
	ld b,00eh		;4efb   ; 14 cuadros
	call pon_temporizador		;4efd   ; puesto
	ld a,(ix+003h)		;4f00   ; la postura
	bit 6,a		;4f03   ; 0x40: cae
	jr nz,agente_cae		;4f05   ; si
	bit 7,a		;4f07   ; 0x80: tiroteado
	jr nz,agente_tiroteado		;4f09   ; si
	bit 5,a		;4f0b   ; 0x20: aplastado
	jr nz,agente_aplastado		;4f0d   ; si
	jp agente_fin		;4f0f   ; ninguna: nada
agente_cae:		; Cae 16 pixeles por paso hasta que hay suelo
	inc (ix+004h)		;4f12   ; cuadro + 1
	ld a,(ix+004h)		;4f15   ; cinco pasos
	cp 005h		;4f18   ; el quinto?
	jr c,L_4F21		;4f1a   ; antes: sigue cayendo
	jr nz,agente_fuera		;4f1c   ; despues: fuera
	jp agente_comun		;4f1e   ; el quinto: quieto
L_4F21:
	call que_hay_debajo		;4f21   ; que hay debajo?
	cp 002h		;4f24   ; 0 o 1: suelo...
	jr nc,L_4F2F		;4f26   ; nada debajo: cae
	ld (ix+004h),004h		;4f28   ; ...se para
	jp agente_comun		;4f2c   ; pintado
L_4F2F:
	ld a,010h		;4f2f   ; nada: 16 mas abajo
	add a,(ix+002h)		;4f31   ; + 16
	ld (ix+002h),a		;4f34   ; guardada
	jp agente_comun		;4f37   ; pintado
agente_tiroteado:		; Ocho cuadros de caida tras el disparo
	inc (ix+004h)		;4f3a   ; cuadro + 1
	ld a,(ix+004h)		;4f3d   ; cual?
	cp 009h		;4f40   ; el noveno?
	jp c,agente_comun		;4f42   ; antes: sigue
	jp agente_fuera		;4f45   ; despues: fuera
agente_aplastado:		; El ascensor lo aplasta: cuatro cuadros
	res 5,a		;4f48   ; sin el bit de aplastado
	and a			;4f4a   ; habia otro?
	jr z,agente_aplastado_sig		;4f4b   ; la primera vez...
	ld (ix+003h),020h		;4f4d   ; ...postura 0x20 desde el cuadro 1
	ld (ix+004h),001h		;4f51   ; cuadro 1
	bit 2,a		;4f55   ; en el suelo del ascensor?
	jr z,agente_aplastado_cuadro		;4f57   ; no
	jp agente_comun		;4f59   ; si: quieto
agente_aplastado_sig:
	inc (ix+004h)		;4f5c   ; cuadro + 1
agente_aplastado_cuadro:
	ld a,(ix+004h)		;4f5f   ; cual?
	cp 003h		;4f62   ; 1 o 2?
	jr c,L_4F6D		;4f64   ; si: baja con el ascensor
	cp 005h		;4f66   ; 3 o 4?
	jp c,agente_comun		;4f68   ; si: quieto
	jr agente_fuera		;4f6b   ; el quinto: fuera
L_4F6D:
	bit 1,(ix+000h)		;4f6d   ; en un ascensor...
	jr z,L_4F7B		;4f71   ; no
	ld a,0f8h		;4f73   ; ...baja 8 con el
	add a,(ix+002h)		;4f75   ; - 8
	ld (ix+002h),a		;4f78   ; guardada
L_4F7B:
	ld l,(ix+007h)		;4f7b   ; el ascensor que le cayo encima...
	ld h,(ix+008h)		;4f7e   ; en HL
	push ix		;4f81   ; se guarda
	push hl			;4f83   ; el ascensor...
	pop ix		;4f84   ; ...en IX
	call ascensor_una_fila		;4f86   ; ...se para
	pop ix		;4f89   ; el agente
	jp agente_comun		;4f8b   ; pintado
agente_fuera:		; Fin de la muerte: deja libres el ascensor y su techo
	res 0,(ix+000h)		;4f8e   ; fuera de juego: el bucle lo vera
	ld l,(ix+007h)		;4f92   ; el ascensor...
	ld h,(ix+008h)		;4f95   ; ...en HL
	bit 1,(ix+000h)		;4f98   ; estaba en un ascensor?
	jr z,L_4FA0		;4f9c   ; no
	res 7,(hl)		;4f9e   ; ya no lleva a nadie
L_4FA0:
	bit 5,(ix+003h)		;4fa0   ; encima del techo?
	jp z,agente_fin		;4fa4   ; no
	res 1,(hl)		;4fa7   ; el techo libre
	jp agente_fin		;4fa9   ; listo
agente_salta:		; El salto: cuatro cuadros, sube 16 en los dos primeros; en el aire se puede girar
	inc (ix+004h)		;4fac   ; cuadro + 1
	ld a,(ix+004h)		;4faf   ; cuadro siguiente
	cp 005h		;4fb2   ; acabado...
	jr c,L_4FC2		;4fb4   ; no: sigue
	ld (ix+003h),001h		;4fb6   ; ...de pie
	ld (ix+004h),001h		;4fba   ; cuadro 1
	ld b,003h		;4fbe   ; tres sprites
	jr agente_salta_mueve		;4fc0   ; a moverse
L_4FC2:
	cp 003h		;4fc2   ; subiendo o bajando?
	push af			;4fc4   ; el resultado...
	ex af,af'			;4fc5   ; ...a A'...
	pop af			;4fc6   ; ...pasando por la pila
	ex af,af'			;4fc7   ; A otra vez
	jr nc,agente_salta_avanza		;4fc8   ; 3 o 4: bajando
	ld a,0f0h		;4fca   ; los dos primeros: 16 arriba
	add a,(ix+002h)		;4fcc   ; - 16
	ld (ix+002h),a		;4fcf   ; guardada
	ex af,af'			;4fd2   ; el cuadro de A'
	cp 001h		;4fd3   ; en el primero no se gira
	jr z,agente_salta_avanza		;4fd5   ; si
	ld a,0ffh		;4fd7   ; el mando
	call lee_mando		;4fd9   ; la direccion
	cp 003h		;4fdc   ; derecha...
	jr nz,agente_salta_izq		;4fde   ; no
	bit 7,(ix+000h)		;4fe0   ; ...mirando a la izquierda?
	jr z,agente_salta_avanza		;4fe4   ; no: nada
	ld a,0ffh		;4fe6   ; un disparo menos en este cuadro
	ld (0c39ah),a		;4fe8   ; 0xC39A = 0xFF
	res 7,(ix+000h)		;4feb   ; ya mira a la derecha
	jr agente_salta_giro		;4fef   ; corrige la X
agente_salta_izq:
	cp 007h		;4ff1   ; izquierda...
	jr nz,agente_salta_avanza		;4ff3   ; no
	bit 7,(ix+000h)		;4ff5   ; ya?
	jr nz,agente_salta_avanza		;4ff9   ; si: nada
	ld a,0ffh		;4ffb   ; un disparo menos en este cuadro
	ld (0c39ah),a		;4ffd   ; 0xC39A = 0xFF
	set 7,(ix+000h)		;5000   ; ya mira a la izquierda
agente_salta_giro:		; Al girarse en el aire se corrige la X 4 pixeles
	push af			;5004   ; se guarda
	ld a,(ix+009h)		;5005   ; el avance del salto
	bit 7,(ix+000h)		;5008   ; a cual?
	jr nz,agente_salta_giro_i		;500c   ; la izquierda
	or a			;500e   ; sin avance?
	jr z,agente_salta_giro_d		;500f   ; si
	jp p,agente_salta_dibujos		;5011   ; a la derecha: nada
agente_salta_giro_d:
	ld a,004h		;5014   ; +4
	jr agente_salta_corrige		;5016   ; corrige
agente_salta_giro_i:
	or a			;5018   ; sin avance?
	jp m,agente_salta_dibujos		;5019   ; a la izquierda: nada
	ld a,0fch		;501c   ; -4
agente_salta_corrige:
	add a,(ix+001h)		;501e   ; la X...
	ld (ix+001h),a		;5021   ; ...corregida
agente_salta_dibujos:
	pop af			;5024   ; lo de antes
	call dibujos_del_lado		;5025   ; los dibujos del lado que mira
agente_salta_avanza:
	ld b,002h		;5028   ; dos sprites de choque
agente_salta_mueve:
	call tile_de_los_pies		;502a   ; donde esta en el mapa
	call choca_pared		;502d   ; choca con una pared?
	jr nz,agente_salta_fin		;5030   ; pared: no avanza
	ld a,(ix+009h)		;5032   ; no: avanza
	add a,(ix+001h)		;5035   ; + avance
	ld (ix+001h),a		;5038   ; guardada
agente_salta_fin:
	ld a,(ix+004h)		;503b   ; el cuadro
	cp 001h		;503e   ; el primero otra vez?
	jr nz,L_5049		;5040   ; no
	res 4,(ix+000h)		;5042   ; aterrizado: ya no salta
	jp agente_suelo		;5046   ; al suelo
L_5049:
	cp 004h		;5049   ; el cuarto cuadro...
	jp nz,agente_comun		;504b   ; no: pintado
	call que_hay_debajo		;504e   ; ...con suelo debajo...
	cp 002h		;5051   ; nada debajo?
	jp nz,agente_comun		;5053   ; no: pintado
	ld a,010h		;5056   ; ...baja 16
	add a,(ix+002h)		;5058   ; + 16
	ld (ix+002h),a		;505b   ; guardada
	jp agente_comun		;505e   ; pintado
agente_en_puerta:		; Dentro de la puerta roja: la cierra, cobra los documentos y sale
	ld a,000h		;5061   ; un paso cada 14 cuadros
	ld b,00eh		;5063   ; 14 cuadros
	call pon_temporizador		;5065   ; puesto
	inc (ix+004h)		;5068   ; cuadro siguiente
	ld a,(ix+004h)		;506b   ; cual?
	cp 004h		;506e   ; el cuarto?
	jr c,agente_puerta_dibujo		;5070   ; antes: la puerta se abre
	jr nz,agente_en_puerta_espera		;5072   ; despues: escondido
	ld l,(ix+007h)		;5074   ; la puerta...
	ld h,(ix+008h)		;5077   ; la puerta en HL
	res 6,(hl)		;507a   ; ...ya no es roja
	push ix		;507c   ; se guarda
	push hl			;507e   ; la puerta...
	pop ix		;507f   ; ...en IX
	ld a,(ix+002h)		;5081   ; su fila...
	call sitio_en_mapa		;5084   ; ...la pinta cerrada
	ld hl,05928h		;5087   ; los 500 puntos, con su rotulo en la puerta
	call rotulo_y_puntos		;508a   ; se despliega
	ld a,00ah		;508d   ; el sonido de los documentos
	call sonido		;508f   ; pedido
	pop ix		;5092   ; el agente
	res 3,(ix+000h)		;5094   ; fuera de la puerta
	ld (ix+003h),001h		;5098   ; de pie
	ld (ix+004h),001h		;509c   ; cuadro 1
	ld a,000h		;50a0   ; el siguiente movimiento en 7 cuadros
	ld b,007h		;50a2   ; 7 cuadros
	call pon_temporizador		;50a4   ; puesto
	jp agente_suelo		;50a7   ; al suelo
agente_en_puerta_espera:		; En una puerta azul se queda escondido hasta que se mueve el mando
	cp 007h		;50aa   ; el septimo?
	jr c,agente_puerta_dibujo		;50ac   ; antes: la puerta
	jr nz,agente_escondido		;50ae   ; despues: escondido
	ld a,01bh		;50b0   ; temporizador 0x1B: 255 cuadros escondido
	ld b,0ffh		;50b2   ; 255 cuadros
	call pon_temporizador		;50b4   ; puesto
	jp agente_fin		;50b7   ; listo
agente_escondido:
	ld (ix+004h),007h		;50ba   ; quieto en el cuadro 7
	ld a,0ffh		;50be   ; el mando
	call lee_mando		;50c0   ; la direccion
	ld l,(ix+007h)		;50c3   ; la puerta...
	ld h,(ix+008h)		;50c6   ; en HL
	bit 7,(hl)		;50c9   ; ...mira a la izquierda?
	jr nz,agente_escondido_izq		;50cb   ; si
	res 7,(ix+000h)		;50cd   ; el agente a la derecha...
	cp 003h		;50d1   ; ...se sale con la derecha
	jr agente_escondido_sale		;50d3   ; sale?
agente_escondido_izq:
	set 7,(ix+000h)		;50d5   ; el agente a la izquierda
	cp 007h		;50d9   ; ...o con la izquierda
agente_escondido_sale:
	jr z,agente_sale_puerta		;50db   ; pulsado: sale
	ld a,01bh		;50dd   ; o cuando pasan los 255 cuadros
	call lee_temporizador		;50df   ; han pasado?
	jp nz,agente_fin		;50e2   ; no: sigue escondido
agente_sale_puerta:
	ld (ix+004h),001h		;50e5   ; cuadro 1
	call dibujos_del_lado		;50e9   ; los dibujos del lado
agente_puerta_dibujo:
	call puerta_animada		;50ec   ; la puerta abierta o cerrada
	jp agente_fin		;50ef   ; listo
agente_mando:		; Salto con 'x' o el segundo boton; si no, el mando
	ld a,078h		;50f2   ; 'x'?
	call lee_mando		;50f4   ; pulsada?
	jr nz,agente_quiere_saltar		;50f7   ; si
	ld a,003h		;50f9   ; el boton 2 del joystick?
	call lee_mando		;50fb   ; pulsado?
	jr nz,agente_quiere_saltar		;50fe   ; si
	sub a			;5100   ; suelto: el salto se puede repetir
	ld (0c32ah),a		;5101   ; a cero
	jp agente_direccion		;5104   ; el mando
agente_quiere_saltar:
	ld a,(0c32ah)		;5107   ; sigue pulsado desde el ultimo salto?
	and a			;510a   ; no
	jr nz,agente_direccion		;510b   ; si: no salta
	ld a,0ffh		;510d   ; se apunta
	ld (0c32ah),a		;510f   ; apuntado
	ld a,004h		;5112   ; el sonido del salto
	call sonido		;5114   ; el sonido 4
	set 4,(ix+000h)		;5117   ; bit 4: saltando
	ld (ix+004h),001h		;511b   ; cuadro 1
	ld (ix+009h),000h		;511f   ; sin avance
	ld a,0ffh		;5123   ; hacia donde?
	call lee_mando		;5125   ; la direccion
	bit 7,(ix+000h)		;5128   ; mira a la izquierda?
	jr nz,agente_salto_izq		;512c   ; si
	cp 003h		;512e   ; mirando a la derecha y pulsando derecha
	jr z,agente_salto_lado		;5130   ; si: salto largo
	jr agente_salto_quieto		;5132   ; no: corto
agente_salto_izq:
	cp 007h		;5134   ; izquierda?
	jr z,agente_salto_lado		;5136   ; si: salto largo
agente_salto_quieto:
	ld c,000h		;5138   ; sin moverse...
	bit 1,(ix+003h)		;513a   ; ...salvo si andaba
	jr z,agente_salto_empieza		;513e   ; no: salto en el sitio
agente_salto_lado:
	bit 7,(ix+000h)		;5140   ; mira a la izquierda?
	jr nz,agente_salto_lado_i		;5144   ; si
	ld a,008h		;5146   ; 8 por cuadro, 4 al saltar
	ld c,004h		;5148   ; 4 al saltar
	jr agente_salto_avance		;514a   ; guardado
agente_salto_lado_i:
	ld a,0f8h		;514c   ; -8 por cuadro...
	ld c,0fch		;514e   ; ...-4 al saltar
agente_salto_avance:
	ld (ix+009h),a		;5150   ; el avance
agente_salto_empieza:
	ld (ix+003h),008h		;5153   ; en el aire
	ld a,(ix+002h)		;5157   ; 8 arriba
	add a,0f8h		;515a   ; - 8
	ld (ix+002h),a		;515c   ; guardada
	call tile_de_los_pies		;515f   ; en un ascensor?
	jp nz,agente_comun		;5162   ; si: pintado
	ld b,003h		;5165   ; tres sprites de choque
	call choca_pared		;5167   ; choca con algo?
	jp nz,agente_comun		;516a   ; si: no avanza
	ld a,(0c0d3h)		;516d   ; por debajo de la fila 0x8A (la parte baja)...
	cp 08ah		;5170   ; 0x8A?
	jr c,agente_salto_mueve		;5172   ; antes: avanza
	ld a,(0c0d9h)		;5174   ; ...y en el borde de la pantalla...
	cp 020h		;5177   ; en el borde izquierdo...
	jr c,agente_salto_mueve		;5179   ; no
	cp 0c8h		;517b   ; ...no avanza
	jp c,agente_comun		;517d   ; si: no avanza
agente_salto_mueve:
	ld a,(ix+001h)		;5180   ; la X...
	add a,c			;5183   ; ...+ C
	ld (ix+001h),a		;5184   ; guardada
	jp agente_comun		;5187   ; pintado
agente_direccion:		; Los cursores o el joystick: arriba y abajo agachan o llaman al ascensor; los lados andan
	ld a,0ffh		;518a   ; el mando
	call lee_mando		;518c   ; cursores o joystick
	push af			;518f   ; se guarda
	and a			;5190   ; nada
	jr z,agente_sin_vertical		;5191   ; nada
	cp 003h		;5193   ; derecha
	jr z,agente_sin_vertical		;5195   ; derecha
	jr c,agente_arriba		;5197   ; arriba (1, 2) o arriba-izquierda (8)
	cp 007h		;5199   ; izquierda
	jr z,agente_sin_vertical		;519b   ; izquierda
	jr nc,agente_arriba		;519d   ; 8: arriba-izquierda
	jr agente_abajo		;519f   ; 4, 5, 6: abajo
agente_sin_vertical:
	bit 1,(ix+000h)		;51a1   ; en un ascensor?
	jr z,agente_horizontal		;51a5   ; no: los lados
	sub a			;51a7   ; si: el ascensor se para
	jr agente_mueve_ascensor		;51a8   ; A=0: parado
agente_abajo:		; Abajo: agacharse, o bajar el ascensor
	ld a,001h		;51aa   ; A=1: abajo
	bit 5,(ix+000h)		;51ac   ; encima del techo: agacharse
	jr nz,agente_agacha		;51b0   ; si
	bit 1,(ix+000h)		;51b2   ; en un ascensor: baja
	jr nz,agente_mueve_ascensor		;51b6   ; si
agente_agacha:
	ld a,001h		;51b8   ; bits...
	or 002h		;51ba   ; ...1 y 2
	and (ix+003h)		;51bc   ; de pie o andando?
	jr z,agente_horizontal		;51bf   ; no: nada
	ld (ix+003h),004h		;51c1   ; agachado
	ld (ix+004h),001h		;51c5   ; cuadro 1
	jr agente_horizontal		;51c9   ; los lados
agente_arriba:		; Arriba: levantarse, o subir el ascensor
	ld a,002h		;51cb   ; A=2: arriba
	bit 5,(ix+000h)		;51cd   ; encima del techo?
	jr nz,agente_levanta		;51d1   ; si
	bit 1,(ix+000h)		;51d3   ; en un ascensor?
	jr nz,agente_ascensor_sube		;51d7   ; si
agente_levanta:
	bit 2,(ix+003h)		;51d9   ; agachado?
	jr z,agente_horizontal		;51dd   ; no: nada
	ld (ix+003h),001h		;51df   ; de pie
	ld (ix+004h),001h		;51e3   ; cuadro 1
	jr agente_horizontal		;51e7   ; los lados
agente_ascensor_sube:
	ld l,(ix+007h)		;51e9   ; su ascensor...
	ld h,(ix+008h)		;51ec   ; en HL
	bit 1,(hl)		;51ef   ; ...tiene el techo ocupado?
	jr z,agente_mueve_ascensor		;51f1   ; libre: sube
	xor a			;51f3   ; entonces no sube
agente_mueve_ascensor:
	call mueve_ascensor		;51f4   ; el ascensor, en la direccion A
agente_horizontal:
	pop af			;51f7   ; la direccion
	cp 006h		;51f8   ; izquierda (6, 7, 8)
	jr nc,agente_izquierda		;51fa   ; si
	cp 002h		;51fc   ; 2, 3, 4: derecha
	jr c,agente_para		;51fe   ; 0 o 1: nada
	cp 005h		;5200   ; hasta la 4?
	jr c,agente_derecha		;5202   ; si: derecha
agente_para:
	bit 1,(ix+003h)		;5204   ; andaba?
	jp z,agente_suelo		;5208   ; no: nada
	ld (ix+003h),001h		;520b   ; de pie
	ld (ix+004h),001h		;520f   ; cuadro 1
	xor a			;5213   ; la cuenta de la escalera mecanica a cero
	ld (0c39eh),a		;5214   ; a cero
	jp agente_suelo		;5217   ; al suelo
agente_izquierda:
	bit 7,(ix+000h)		;521a   ; ya mira a la izquierda: anda
	jr nz,agente_anda		;521e   ; si: andar
	xor a			;5220   ; la cuenta de la escalera...
	ld (0c39eh),a		;5221   ; ...a cero
	ld bc,00506h		;5224   ; registro 6 = 5: los dibujos dados la vuelta
	set 7,(ix+000h)		;5227   ; mira a la izquierda
	ld a,0fch		;522b   ; 4 a la izquierda al girarse
	jr agente_gira		;522d   ; gira
agente_derecha:
	bit 7,(ix+000h)		;522f   ; ya mira a la derecha?
	jr z,agente_anda		;5233   ; si: andar
	xor a			;5235   ; la cuenta de la escalera...
	ld (0c39eh),a		;5236   ; ...a cero
	ld bc,00406h		;5239   ; registro 6 = 4: los dibujos normales
	res 7,(ix+000h)		;523c   ; mira a la derecha
	ld a,004h		;5240   ; +4
agente_gira:
	add a,(ix+001h)		;5242   ; la X...
	ld (ix+001h),a		;5245   ; ...corregida
	call escribe_vdp		;5248   ; al VDP
	bit 1,(ix+003h)		;524b   ; andaba?
	jr z,agente_suelo		;524f   ; no: listo
	ld (ix+003h),001h		;5251   ; de pie
	ld (ix+004h),001h		;5255   ; cuadro 1
	jr agente_suelo		;5259   ; al suelo
agente_anda:
	ld a,001h		;525b   ; bits...
	or 002h		;525d   ; ...1 y 2
	and (ix+003h)		;525f   ; de pie o andando?
	jr z,agente_suelo		;5262   ; ni de pie ni andando: nada
	and 001h		;5264   ; de pie...
	jr nz,agente_empieza_andar		;5266   ; de pie: empieza
	ld a,(ix+004h)		;5268   ; cuadro 1, 2, 1, 2...
	inc a			;526b   ; + 1
	cp 003h		;526c   ; pasa de 2?
	jr c,L_5272		;526e   ; no
	ld a,001h		;5270   ; 1
L_5272:
	ld (ix+004h),a		;5272   ; guardado
	ld a,00bh		;5275   ; el sonido del paso
	call sonido		;5277   ; pedido
	jr agente_un_paso		;527a   ; el paso
agente_empieza_andar:
	ld (ix+003h),002h		;527c   ; andando
	ld (ix+004h),002h		;5280   ; cuadro 2
agente_un_paso:
	call un_paso		;5284   ; 4 pixeles
agente_suelo:		; Mira el suelo: el scroll le sigue cuando pasa de la Y 0x78; sin suelo, cae
	call que_hay_debajo		;5287   ; que hay debajo?
	jr nz,agente_sin_suelo		;528a   ; algo raro
	ld hl,0c0d0h		;528c   ; suelo: los bits del scroll
	ld a,(ix+002h)		;528f   ; la Y
	cp 078h		;5292   ; por encima de 0x78...
	jr c,L_52A2		;5294   ; menos de 0x78
	cp 080h		;5296   ; ...0x78 a 0x7F: quieto
	jr nc,L_529C		;5298   ; 0x80 o mas
	jr agente_comun		;529a   ; en medio: nada
L_529C:
	set 5,(hl)		;529c   ; mas abajo: el edificio sube
	set 1,(hl)		;529e   ; bit 1: arriba
	jr agente_comun		;52a0   ; pintado
L_52A2:
	set 5,(hl)		;52a2   ; mas arriba: el edificio baja
	res 1,(hl)		;52a4   ; bit 1: abajo
	jr agente_comun		;52a6   ; pintado
agente_sin_suelo:
	cp 001h		;52a8   ; un escalon (1): cae como al saltar
	jr nz,agente_hueco		;52aa   ; no
	ld (ix+003h),008h		;52ac   ; en el aire...
	ld (ix+004h),004h		;52b0   ; ...cuadro 4, el de caer
	ld (ix+009h),000h		;52b4   ; sin avance
	set 4,(ix+000h)		;52b8   ; saltando
	jr agente_comun		;52bc   ; pintado
agente_hueco:
	cp 002h		;52be   ; el vacio (2)
	jr nz,agente_comun		;52c0   ; ni eso: pintado
	bit 1,(ix+000h)		;52c2   ; en un ascensor...
	jr z,agente_cae_hueco		;52c6   ; no
	bit 5,(ix+000h)		;52c8   ; ...dentro de la cabina...
	jr nz,agente_cae_hueco		;52cc   ; si
	ld a,(ix+002h)		;52ce   ; ...baja con el
	add a,008h		;52d1   ; +8
	ld (ix+002h),a		;52d3   ; guardada
	jr agente_comun		;52d6   ; pintado
agente_cae_hueco:		; Por el hueco del ascensor: se mata
	ld a,007h		;52d8   ; el sonido de caer
	call sonido		;52da   ; pedido
	ld (ix+003h),040h		;52dd   ; postura 0x40
	ld (ix+004h),001h		;52e1   ; cuadro 1
	set 6,(ix+000h)		;52e5   ; muriendo
agente_comun:		; Ascensores, techos, puertas y el disparo
	call agente_ascensor		;52e9   ; entra o sale de un ascensor
	call agente_techo		;52ec   ; un techo le aplasta?
	call agente_puerta		;52ef   ; entra en una puerta?
	jr nz,L_52F9		;52f2   ; no
	ld hl,05856h		;52f4   ; los dibujos de siempre
	jr agente_pon_dibujos		;52f7   ; puestos
L_52F9:
	ld hl,05856h		;52f9   ; los dibujos de siempre
	bit 6,(ix+000h)		;52fc   ; muriendo: no dispara
	jr nz,agente_pon_dibujos		;5300   ; si: sin disparo
	ld a,001h		;5302   ; de pie, andando o agachado...
	or 002h		;5304   ; los bits 1...
	or 004h		;5306   ; ...y 4
	and (ix+003h)		;5308   ; en la postura?
	jr nz,agente_dispara		;530b   ; si
	bit 4,(ix+000h)		;530d   ; ...o en lo alto del salto...
	jr z,agente_pon_dibujos		;5311   ; no
	ld a,(ix+004h)		;5313   ; el cuadro
	cp 002h		;5316   ; el segundo?
	jr z,agente_dispara		;5318   ; si
	cp 003h		;531a   ; el tercero?
	jr nz,agente_pon_dibujos		;531c   ; no
agente_dispara:		; Disparo con 'z' o el primer boton, uno por pulsacion
	ld a,07ah		;531e   ; 'z'?
	call lee_mando		;5320   ; pulsada?
	jr nz,agente_dispara_pulsado		;5323   ; si
	ld a,001h		;5325   ; el boton 1?
	call lee_mando		;5327   ; pulsado?
	jr nz,agente_dispara_pulsado		;532a   ; si
	sub a			;532c   ; suelto
	ld (0c329h),a		;532d   ; a cero
	jr agente_pon_dibujos		;5330   ; sin disparo
agente_dispara_pulsado:
	ld a,(0c329h)		;5332   ; ya disparo con esta pulsacion?
	and a			;5335   ; si?
	jr nz,agente_pon_dibujos		;5336   ; si: nada
	ld a,0ffh		;5338   ; apuntado
	ld (0c329h),a		;533a   ; guardado
	call bala_choca		;533d   ; le queda bala libre?
	jr nz,agente_fin		;5340   ; no: nada
	sub a			;5342   ; la bala
	call dispara		;5343   ; A=0: la del agente
	ld a,(0c3a2h)		;5346   ; ha disparado de verdad?
	and a			;5349   ; no?
	jr z,agente_fin		;534a   ; no: nada
	xor a			;534c   ; se borra
	ld (0c3a2h),a		;534d   ; el aviso
	ld hl,0584eh		;5350   ; los dibujos de disparar
agente_pon_dibujos:
	ld (0c0ddh),hl		;5353   ; los dibujos
agente_fin:
	ret			;5356   ; listo
agente_puerta:		; De pie delante de una puerta roja o azul y mirando a ella: entra
	ld a,(ix+000h)		;5357   ; los bits
	bit 6,a		;535a   ; muriendo
	jr nz,agente_puerta_no		;535c   ; si: no
	bit 1,a		;535e   ; en un ascensor
	jr nz,agente_puerta_no		;5360   ; si: no
	bit 0,(ix+003h)		;5362   ; tiene que estar de pie
	jr z,agente_puerta_no		;5366   ; no
	call busca_puerta		;5368   ; delante de una puerta?
	jr nz,agente_puerta_no		;536b   ; no
	bit 7,(iy+000h)		;536d   ; la puerta mira a la derecha...
	jr nz,agente_puerta_izq		;5371   ; si
	bit 7,(ix+000h)		;5373   ; ...y el agente a la izquierda
	jr z,agente_puerta_no		;5377   ; no
	jr agente_entra_puerta		;5379   ; entra
agente_puerta_izq:
	bit 7,(ix+000h)		;537b   ; el agente mira a la izquierda?
	jr nz,agente_puerta_no		;537f   ; si: no
agente_entra_puerta:
	push iy		;5381   ; apunta la puerta
	pop hl			;5383   ; en HL
	ld (ix+007h),l		;5384   ; guardada...
	ld (ix+008h),h		;5387   ; ...en +7/+8
	set 3,(ix+000h)		;538a   ; bit 3: en una puerta
	ld (ix+004h),004h		;538e   ; cuadro 4
	ld (ix+003h),010h		;5392   ; postura 0x10
	call puerta_animada		;5396   ; la pinta abierta
	ld a,009h		;5399   ; el sonido de la puerta
	call sonido		;539b   ; pedido
	sub a			;539e   ; Z: ha entrado
	jr L_53A3		;539f   ; listo
agente_puerta_no:
	ld a,001h		;53a1   ; NZ: no
L_53A3:
	and a			;53a3   ; las banderas
	ret			;53a4   ; listo
busca_puerta:		; IY = la puerta (de las 58) que el agente tiene delante; Z si la hay
	ld iy,0c16eh		;53a5   ; la tabla de puertas
	ld b,03ah		;53a9   ; 58
	call tile_de_los_pies		;53ab   ; donde esta el agente
L_53AE:
	bit 6,(iy+000h)		;53ae   ; solo las que estan en pantalla
	jr z,busca_puerta_sig		;53b2   ; no
	call delante_de_la_puerta		;53b4   ; coincide con el agente?
	jr nz,busca_puerta_sig		;53b7   ; no
	sub a			;53b9   ; Z: esta
	jr L_53C5		;53ba   ; listo
busca_puerta_sig:
	ld de,00005h		;53bc   ; 5 bytes
	add iy,de		;53bf   ; la siguiente
	djnz L_53AE		;53c1   ; las 58
	ld a,001h		;53c3   ; NZ: ninguna
L_53C5:
	and a			;53c5   ; las banderas
	ret			;53c6   ; listo
dibujos_del_lado:		; Registro 6 del VDP: 4 (0x2000) mirando a la derecha, 5 (0x2800) a la izquierda
	push bc			;53c7   ; se guarda
	bit 7,(ix+000h)		;53c8   ; mira a la izquierda?
	jr nz,dibujos_izquierda		;53cc   ; si
	ld bc,00406h		;53ce   ; registro 6 = 4
	jr dibujos_al_vdp		;53d1   ; a escribir
dibujos_izquierda:
	ld bc,00506h		;53d3   ; registro 6 = 5
dibujos_al_vdp:
	call escribe_vdp		;53d6
	pop bc			;53d9
	ret			;53da
agente_techo:		; Mira el techo encima de la cabeza: el ascensor que baja le aplasta
	bit 6,(ix+000h)		;53db   ; muriendo...
	jr z,L_53EA		;53df
	bit 7,(ix+003h)		;53e1   ; ...por aplastamiento: sigue
	jr nz,agente_techo_bajo		;53e5
	jp agente_techo_nada		;53e7
L_53EA:
	ld b,004h		;53ea   ; de pie: 4 filas por encima
	ld a,(ix+003h)		;53ec
	bit 0,a		;53ef   ; de pie
	jr nz,agente_techo_mira		;53f1
	bit 1,a		;53f3   ; andando
	jr nz,agente_techo_mira		;53f5
	bit 2,a		;53f7   ; agachado: 2 filas
	jr nz,agente_techo_bajo		;53f9
	ld a,(ix+004h)		;53fb
	cp 001h		;53fe
	jr z,agente_techo_mira		;5400
	cp 004h		;5402
	jr z,agente_techo_mira		;5404
agente_techo_bajo:
	ld b,002h		;5406
agente_techo_mira:
	call tile_de_los_pies		;5408   ; donde esta
	ld de,00020h		;540b
agente_techo_fila:
	and a			;540e   ; una fila arriba
	sbc hl,de		;540f
	call tile_en		;5411
	cp 060h		;5414   ; suelo de la planta?
	jr z,agente_techo_suelo		;5416
	djnz agente_techo_fila		;5418
	jr agente_techo_nada		;541a
agente_techo_suelo:
	bit 1,(ix+000h)		;541c   ; en un ascensor...
	jr z,agente_techo_cabina		;5420
	bit 5,(ix+000h)		;5422   ; ...encima del techo...
	jr z,agente_techo_nada		;5426
	ld l,(ix+007h)		;5428   ; ...y el ascensor sube?
	ld h,(ix+008h)		;542b
	bit 0,(hl)		;542e
	jr nz,agente_aplastado_por		;5430
	jr agente_techo_nada		;5432
agente_techo_cabina:
	and a			;5434   ; la fila de encima del suelo
	sbc hl,de		;5435
	call tile_en		;5437
	cp 03bh		;543a   ; el hueco de una cabina?
	jr nz,agente_techo_nada		;543c
	ld a,002h		;543e   ; que ascensor es
	call esquina_ascensor		;5440
	call busca_ascensor		;5443
	jr nz,agente_techo_nada		;5446
	bit 0,(hl)		;5448   ; baja?
	jr nz,agente_techo_nada		;544a
	ld (ix+007h),l		;544c   ; se apunta
	ld (ix+008h),h		;544f
agente_aplastado_por:
	bit 7,(ix+003h)		;5452   ; ya aplastado
	jr nz,agente_aplastado_ya		;5456
	bit 4,(ix+000h)		;5458   ; saltando: se agacha y baja
	jr z,agente_techo_ocupado		;545c
	ld (ix+004h),004h		;545e
	ld a,(ix+002h)		;5462
	add a,008h		;5465
	ld (ix+002h),a		;5467
	jr agente_techo_nada		;546a
agente_techo_ocupado:
	bit 1,(hl)		;546c   ; el techo ya tiene a alguien
	jr z,agente_techo_marca		;546e
agente_aplastado_ya:
	ld (ix+003h),020h		;5470
	ld (ix+004h),003h		;5474
	jr agente_techo_muere		;5478
agente_techo_marca:
	ld a,006h		;547a   ; el sonido del golpe
	call sonido		;547c
	set 1,(hl)		;547f   ; el techo ocupado
	set 5,(ix+003h)		;5481   ; aplastado bajo el techo
agente_techo_muere:
	set 6,(ix+000h)		;5485
	bit 7,(hl)		;5489   ; el ascensor lleva a alguien?
	jr z,agente_techo_nada		;548b
	ld a,001h		;548d
	jr L_5492		;548f
agente_techo_nada:
	sub a			;5491
L_5492:
	and a			;5492
	ret			;5493
agente_ascensor:		; Sube a un ascensor (tile 0x3B: dentro; 0x2D: encima del techo) o se baja de el
	push hl			;5494
	push de			;5495
	bit 6,(ix+000h)		;5496   ; muriendo
	jr nz,agente_ascensor_fin		;549a
	call tile_de_los_pies		;549c   ; donde esta
	ld de,00020h		;549f
	and a			;54a2
	sbc hl,de		;54a3   ; la fila de los pies
	call tile_en		;54a5
	cp 03bh		;54a8   ; la cabina?
	jr z,agente_ascensor_dentro		;54aa
	cp 02dh		;54ac   ; el hueco: el techo
	jr nz,agente_baja_ascensor		;54ae
	ld a,001h		;54b0   ; 1: encima
	jr agente_ascensor_sube_a		;54b2
agente_ascensor_dentro:
	ld a,002h		;54b4   ; 2: dentro
agente_ascensor_sube_a:
	bit 1,(ix+000h)		;54b6   ; ya esta en uno
	jr nz,agente_ascensor_fin		;54ba
	ld d,a			;54bc
	call esquina_ascensor		;54bd   ; la esquina del ascensor...
	call busca_ascensor		;54c0   ; ...cual es?
	jr nz,agente_ascensor_fin		;54c3
	set 7,(hl)		;54c5   ; bit 7: lleva al agente
	ld (ix+007h),l		;54c7   ; se apunta
	ld (ix+008h),h		;54ca
	set 1,(ix+000h)		;54cd   ; bit 1: en un ascensor
	dec d			;54d1   ; encima?
	jr nz,agente_ascensor_fin		;54d2
	set 5,(ix+000h)		;54d4   ; bit 5: encima del techo
	jr agente_ascensor_fin		;54d8
agente_baja_ascensor:
	bit 1,(ix+000h)		;54da   ; fuera del ascensor
	jr z,agente_ascensor_fin		;54de
	res 1,(ix+000h)		;54e0
	res 5,(ix+000h)		;54e4
	ld l,(ix+007h)		;54e8
	ld h,(ix+008h)		;54eb
	res 7,(hl)		;54ee   ; el ascensor ya no le lleva
	ld hl,0c0d0h		;54f0   ; el scroll no sigue al ascensor
	res 6,(hl)		;54f3
agente_ascensor_fin:
	pop de			;54f5
	pop hl			;54f6
	ret			;54f7
esquina_ascensor:		; Desde el tile HL busca la esquina de arriba a la izquierda de la cabina (A=2) o del techo (A=1); A = su planta
	push de			;54f8
	cp 001h		;54f9   ; el techo?
	jr z,esquina_techo_izq		;54fb
esquina_cabina_izq:
	dec hl			;54fd   ; a la izquierda mientras sea cabina
	call tile_en		;54fe
	cp 03bh		;5501
	jr z,esquina_cabina_izq		;5503
	inc hl			;5505
	ld de,00020h		;5506
esquina_cabina_arriba:
	and a			;5509
	sbc hl,de		;550a   ; una fila arriba
	call tile_en		;550c
	cp 03bh		;550f   ; sigue la cabina?
	jr z,esquina_cabina_arriba		;5511
	add hl,de			;5513   ; la ultima de dentro
	jr esquina_planta		;5514
esquina_techo_izq:
	dec hl			;5516   ; a la izquierda por el hueco y el cable
	call tile_en		;5517
	cp 02dh		;551a
	jr z,esquina_techo_izq		;551c
	cp 028h		;551e
	jr z,esquina_techo_izq		;5520
	inc hl			;5522
	ld de,00020h		;5523
esquina_techo_abajo:
	add hl,de			;5526
	call tile_en		;5527
	cp 02dh		;552a
	jr z,esquina_techo_abajo		;552c
	add hl,de			;552e
esquina_planta:
	call fila_en_pantalla		;552f
	pop de			;5532
	ret			;5533
busca_ascensor:		; HL = el ascensor de 11 que esta en la fila A y columna de HL; NZ si ninguno
	push de			;5534
	push bc			;5535
	push iy		;5536
	ld de,0000ah		;5538   ; 11 ascensores de 10 bytes
	ld b,00bh		;553b
	ld iy,0c0ech		;553d
	ld c,a			;5541
L_5542:
	ld a,c			;5542   ; en esa fila?
	cp (iy+002h)		;5543
	jr z,busca_ascensor_columna		;5546
	bit 6,(iy+000h)		;5548   ; o, si es doble (bit 6), 12 filas mas abajo
	jr z,busca_ascensor_sig		;554c
	sub 00ch		;554e
	cp (iy+002h)		;5550
	jr nz,busca_ascensor_sig		;5553
busca_ascensor_columna:
	call columna_de		;5555   ; la columna
	cp (iy+001h)		;5558
	jr z,busca_ascensor_si		;555b
busca_ascensor_sig:
	add iy,de		;555d
	djnz L_5542		;555f
	ld a,0ffh		;5561
	jr L_5569		;5563
busca_ascensor_si:
	sub a			;5565
	push iy		;5566
	pop hl			;5568
L_5569:
	and a			;5569
	pop iy		;556a
	pop bc			;556c
	pop de			;556d
	ret			;556e
columna_de:		; A = la columna (0-31) del tile HL del mapa
	push hl			;556f
	push de			;5570
	push bc			;5571
	ld de,00020h		;5572
	ld b,l			;5575
columna_resta:
	and a			;5576
	sbc hl,de		;5577
	jr c,columna_de_fin		;5579
	ld b,l			;557b
	jr columna_resta		;557c
columna_de_fin:
	ld a,b			;557e
	pop bc			;557f
	pop de			;5580
	pop hl			;5581
	ret			;5582
fila_en_pantalla:		; A = la fila del tile HL contada desde arriba de la pantalla, menos 8
	push hl			;5583
	push de			;5584
	push bc			;5585
	ld de,(0c0d1h)		;5586   ; el scroll...
	add hl,de			;558a   ; ...para contar desde arriba del mapa
	ld b,000h		;558b
	ld de,00020h		;558d   ; filas de 32
fila_resta:
	and a			;5590
	sbc hl,de		;5591
	jr c,fila_fin		;5593
	inc b			;5595
	jr fila_resta		;5596
fila_fin:
	ld a,b			;5598   ; las filas...
	sub 008h		;5599   ; ...menos las 8 de encima
	pop bc			;559b
	pop de			;559c
	pop hl			;559d
	ret			;559e   ; listo
un_paso:		; Avanza IX 4 pixeles hacia donde mira, si no hay pared; en la escalera mecanica un paso de cada tres
	push hl			;559f
	push de			;55a0
	push bc			;55a1
	call tile_de_los_pies		;55a2   ; donde esta
	push hl			;55a5
	ld b,003h		;55a6   ; tres sprites de choque
	call choca_pared		;55a8   ; pared?
	pop hl			;55ab
	jr nz,un_paso_fin		;55ac
	push hl			;55ae
	push ix		;55af   ; es el agente?
	pop hl			;55b1
	ld de,0c0d8h		;55b2
	and a			;55b5
	sbc hl,de		;55b6
	pop hl			;55b8
	jr nz,un_paso_mueve		;55b9
	ex af,af'			;55bb
	push af			;55bc
	ex af,af'			;55bd
	call columna_delante		;55be   ; el tile de debajo
	call tile_en		;55c1   ; el suelo...
	cp 060h		;55c4
	ex af,af'			;55c6
	pop af			;55c7
	ex af,af'			;55c8
	jr z,un_paso_mueve		;55c9
	ex af,af'			;55cb   ; ...o la escalera
	cp 02dh		;55cc
	jr nz,un_paso_mueve		;55ce
	ld a,(0c39eh)		;55d0   ; cuenta de la escalera
	or a			;55d3
	jr nz,un_paso_escalera		;55d4
	ld a,003h		;55d6
	jr un_paso_guarda		;55d8
un_paso_escalera:
	dec a			;55da
	or a			;55db
	jr z,un_paso_mueve		;55dc
un_paso_guarda:
	ld (0c39eh),a		;55de
	jr un_paso_fin		;55e1
un_paso_mueve:
	bit 7,(ix+000h)		;55e3
	jr z,un_paso_derecha		;55e7
	ld a,0fch		;55e9
	jr un_paso_suma		;55eb
un_paso_derecha:
	ld a,004h		;55ed
un_paso_suma:
	add a,(ix+001h)		;55ef
	ld (ix+001h),a		;55f2
un_paso_fin:
	pop bc			;55f5
	pop de			;55f6
	pop hl			;55f7
	ret			;55f8
choca_pared:		; NZ si en la columna de delante hay pared, tejado o cable (B filas desde los pies)
	push de			;55f9
	ld de,00020h		;55fa   ; una fila
	call columna_delante		;55fd   ; la columna de delante
L_5600:
	push af			;5600
	bit 4,(ix+000h)		;5601   ; saltando: se mira siempre
	jr nz,L_560B		;5605
	pop af			;5607
	push af			;5608
	jr nz,choca_pared_otra		;5609
L_560B:
	and a			;560b
	sbc hl,de		;560c
	call tile_en		;560e
	cp 00eh		;5611   ; el tejado (0x0E, 0x0A, 0x09, 0x2E)
	jr z,choca_si		;5613
	cp 00ah		;5615
	jr z,choca_si		;5617
	cp 009h		;5619
	jr z,choca_si		;561b
	cp 02eh		;561d
	jr z,choca_si		;561f
	cp 061h		;5621   ; las paredes (0x61, 0x64)
	jr z,choca_si		;5623
	cp 064h		;5625
	jr z,choca_si		;5627
	cp 060h		;5629   ; el suelo
	jr z,choca_si		;562b
	cp 028h		;562d   ; el cable
	jr z,choca_si		;562f
	bit 4,(ix+000h)		;5631
	jr nz,L_563F		;5635
	jr choca_sig		;5637
choca_pared_otra:
	and a			;5639
	sbc hl,de		;563a
	call tile_en		;563c
L_563F:
	cp 067h		;563f   ; la pared de la escalera
	jr z,choca_si		;5641
choca_sig:
	push af			;5643   ; el resultado de esta fila...
	ex af,af'			;5644   ; ...a A'
	pop af			;5645
	ex af,af'			;5646
	pop af			;5647
	djnz L_5600		;5648   ; las B filas
	sub a			;564a   ; Z: nada
	jr choca_fin		;564b
choca_si:
	ld d,a			;564d
	pop af			;564e
	ld a,d			;564f
choca_fin:
	and a			;5650
	pop de			;5651
	ret			;5652
columna_delante:		; HL una columna a la derecha o a la izquierda segun mire (el agente en el aire, segun el avance)
	push af			;5653
	exx			;5654
	push ix		;5655
	pop hl			;5657
	ld de,0c0d8h		;5658   ; es el agente?
	or a			;565b
	sbc hl,de		;565c
	jr nz,columna_no_agente		;565e
	ld b,0ffh		;5660
	jr columna_mira		;5662
columna_no_agente:
	ld b,000h		;5664
columna_mira:
	bit 7,(ix+000h)		;5666   ; mira a la izquierda?
	jr z,columna_mira_d		;566a
	ex af,af'			;566c
	ld a,b			;566d
	or a			;566e
	jr z,columna_izquierda		;566f
	bit 4,(ix+000h)		;5671   ; saltando...
	jr z,columna_izquierda		;5675
	ld a,(ix+009h)		;5677   ; ...con avance a la derecha: la de la derecha
	or a			;567a
	jp z,columna_izquierda		;567b
	jp p,columna_derecha		;567e
columna_izquierda:
	ex af,af'			;5681
	exx			;5682
	dec hl			;5683
	jr columna_delante_fin		;5684
columna_mira_d:
	ex af,af'			;5686
	ld a,b			;5687   ; es el agente?
	or a			;5688
	jr z,columna_derecha		;5689
	bit 4,(ix+000h)		;568b   ; saltando?
	jr z,columna_derecha		;568f
	ld a,(ix+009h)		;5691   ; el avance
	or a			;5694
	jp m,columna_izquierda		;5695   ; hacia la izquierda
columna_derecha:
	ex af,af'			;5698
	exx			;5699
	inc hl			;569a
columna_delante_fin:
	pop af			;569b
	ret			;569c
tile_de_los_pies:		; HL = posicion en pantalla (fila x 32 + columna) del tile delante de los pies de IX; A = X and 7
	push de			;569d
	push bc			;569e
	ld a,(ix+001h)		;569f
	and 007h		;56a2   ; lo que sobra dentro del tile
	push af			;56a4
	ld a,004h		;56a5   ; 4 pixeles por delante...
	bit 7,(ix+000h)		;56a7
	jr z,L_56AF		;56ab
	ld a,008h		;56ad   ; ...u 8 mirando a la izquierda
L_56AF:
	add a,(ix+001h)		;56af
	srl a		;56b2   ; / 8: la columna
	srl a		;56b4
	srl a		;56b6
	push af			;56b8
	ld a,(ix+002h)		;56b9
	sub 00ch		;56bc   ; la Y de los pies, menos 12...
	srl a		;56be   ; ...entre 8: la fila
	srl a		;56c0
	srl a		;56c2
	ld b,a			;56c4
	pop af			;56c5
	ld l,a			;56c6
	ld h,000h		;56c7
	ld de,00020h		;56c9
por_fila:
	add hl,de			;56cc   ; + 32
	djnz por_fila		;56cd   ; B filas
	pop af			;56cf
	pop bc			;56d0
	pop de			;56d1
	ret			;56d2   ; listo
tile_en:		; A = el tile del mapa en la posicion de pantalla HL (con el scroll)
	push de			;56d3
	push hl			;56d4
	push hl			;56d5
	ld hl,(0c0d1h)		;56d6   ; el scroll...
	ld de,0c400h		;56d9   ; ...dentro del mapa
	add hl,de			;56dc
	ex de,hl			;56dd
	pop hl			;56de
	add hl,de			;56df
	ld a,(hl)			;56e0
	pop hl			;56e1
	pop de			;56e2
	ret			;56e3
mueve_ascensor:		; El ascensor del agente: A=1 baja, A=2 sube, otro se para; al moverse, como mucho 20 cuadros de espera
	ld l,(ix+007h)		;56e4   ; el ascensor
	ld h,(ix+008h)		;56e7
	cp 001h		;56ea
	jr z,ascensor_baja		;56ec
	cp 002h		;56ee
	jr z,ascensor_sube		;56f0
	res 4,(hl)		;56f2   ; parado (bit 4)
	jr mueve_ascensor_fin		;56f4
ascensor_baja:
	res 0,(hl)		;56f6   ; bit 0 = 0: baja
	jr ascensor_marcha		;56f8
ascensor_sube:
	set 0,(hl)		;56fa   ; bit 0 = 1: sube
ascensor_marcha:
	set 4,(hl)		;56fc   ; en marcha
	ld de,0c0ech		;56fe   ; su numero...
	and a			;5701
	sbc hl,de		;5702
	ld de,0000ah		;5704
	ld b,00bh		;5707
ascensor_numero:
	ld a,h			;5709   ; ya en el primero?
	or l			;570a
	jr z,ascensor_espera_max		;570b   ; si: B es su numero
	sbc hl,de		;570d   ; 10 bytes menos
	dec b			;570f   ; el anterior
	jr ascensor_numero		;5710
ascensor_espera_max:
	ld a,b			;5712   ; ...es su temporizador
	call lee_temporizador		;5713
	cp 015h		;5716   ; mas de 20 cuadros?
	jr c,mueve_ascensor_fin		;5718
	ld a,b			;571a
	ld b,014h		;571b   ; se deja en 20
	call pon_temporizador		;571d
mueve_ascensor_fin:
	ret			;5720

; ----------------------------------------------------------------------
; =====  Los sprites de una ficha  =====
; ----------------------------------------------------------------------
pon_sprites:		; Pone en el buffer (IY) los B sprites de IX segun postura y cuadro; fuera de pantalla los esconde y C=1
	push hl			;5721
	push de			;5722
	push bc			;5723
	ld l,(ix+005h)		;5724   ; la tabla de dibujos
	ld h,(ix+006h)		;5727
	ld a,(ix+003h)		;572a   ; la postura: un bit
pon_sprites_postura:
	srl a		;572d   ; el bit que esta a 1...
	jr c,pon_sprites_lista		;572f
	inc hl			;5731   ; ...dice la entrada
	inc hl			;5732
	jr pon_sprites_postura		;5733
pon_sprites_lista:
	ld a,(hl)			;5735   ; la lista de cuadros de esa postura
	inc hl			;5736
	ld h,(hl)			;5737
	ld l,a			;5738
	ld a,(ix+004h)		;5739   ; el cuadro
pon_sprites_cuadro:
	dec a			;573c
	jr z,pon_sprites_cuadro_ya		;573d
	inc hl			;573f
	inc hl			;5740
	jr pon_sprites_cuadro		;5741
pon_sprites_cuadro_ya:
	ld a,(hl)			;5743
	inc hl			;5744
	ld h,(hl)			;5745
	ld l,a			;5746
	ld d,(ix+001h)		;5747   ; X
	ld e,(ix+002h)		;574a   ; Y
	ld a,e			;574d
	ld c,000h		;574e   ; dentro
	cp 028h		;5750   ; por encima de la Y 0x28 (el marcador)...
	jr c,pon_sprites_fuera		;5752
	cp 0b9h		;5754   ; ...por debajo de 0xB9...
	jr nc,pon_sprites_fuera		;5756
	ld a,d			;5758   ; ...o en la X 0xF8 y mas...
	cp 0f8h		;5759
	jr c,pon_sprites_uno		;575b
pon_sprites_fuera:		; Fuera de pantalla: la ficha se apaga y, si es un enemigo de una puerta, la puerta queda libre
	ld c,001h		;575d   ; fuera
	res 0,(ix+000h)		;575f   ; se apaga
	bit 1,(ix+000h)		;5763   ; en un ascensor: nada mas
	jr nz,pon_sprites_esconde		;5767
	ld l,(ix+007h)		;5769   ; de donde salio
	ld h,(ix+008h)		;576c
	bit 4,(hl)		;576f   ; de una puerta?
	jr z,pon_sprites_esconde		;5771
	push ix		;5773
	push iy		;5775
	push bc			;5777
	push hl			;5778
	pop ix		;5779
	and a			;577b
	ld bc,0c16eh		;577c   ; una de la tabla de puertas?
	sbc hl,bc		;577f
	jr c,pon_sprites_fuera_fin		;5781
	push ix		;5783
	pop hl			;5785
	and a			;5786
	ld bc,0c29ah		;5787
	sbc hl,bc		;578a
	jr nc,pon_sprites_fuera_fin		;578c
	jr z,pon_sprites_fuera_fin		;578e
	ld b,001h		;5790   ; la puerta se cierra
	call puerta_repinta		;5792
pon_sprites_fuera_fin:
	pop bc			;5795
	pop iy		;5796
	pop ix		;5798
	jr pon_sprites_esconde		;579a
pon_sprites_uno:		; Cada sprite: dibujo, color y desplazamiento de la Y; 0xFF acaba
	ld a,(hl)			;579c
	cp 0ffh		;579d   ; fin de la lista
	jr z,pon_sprites_esconde		;579f
	ld (iy+002h),a		;57a1   ; el dibujo
	inc hl			;57a4
	ld a,(hl)			;57a5
	ld (iy+003h),a		;57a6   ; el color
	ld (iy+001h),d		;57a9   ; la X
	inc hl			;57ac
	ld a,(hl)			;57ad   ; la Y + desplazamiento
	add a,e			;57ae
	ld (iy+000h),a		;57af
	inc hl			;57b2
	inc iy		;57b3
	inc iy		;57b5
	inc iy		;57b7
	inc iy		;57b9
	djnz pon_sprites_uno		;57bb
	ld a,(hl)			;57bd   ; sobran sprites?
	cp 0ffh		;57be
	jr z,pon_sprites_fin		;57c0
pon_sprites_esconde:
	call esconde_sprite		;57c2
	djnz pon_sprites_esconde		;57c5
pon_sprites_fin:
	ld a,c			;57c7   ; C...
	and a			;57c8   ; ...a las banderas: NZ si fuera
	pop bc			;57c9
	pop de			;57ca
	pop hl			;57cb
	ret			;57cc   ; listo
que_hay_debajo:		; Busca suelo (0x60, 0x0A tejado, 0x78 escalera) hasta 3 filas bajo los pies: 0 a ras (encaja la Y), 1 un escalon, 2 nada
	push hl			;57cd
	push de			;57ce
	push bc			;57cf
	ld b,003h		;57d0   ; tres filas
	ld de,00020h		;57d2
	call tile_de_los_pies		;57d5   ; donde esta
debajo_fila:
	call tile_en		;57d8
	cp 060h		;57db   ; suelo
	jr z,debajo_suelo		;57dd
	cp 00ah		;57df   ; tejado
	jr z,debajo_suelo		;57e1
	cp 078h		;57e3   ; arriba de la escalera
	jr z,debajo_suelo		;57e5
	add hl,de			;57e7   ; la fila siguiente
	djnz debajo_fila		;57e8
	ld a,002h		;57ea   ; nada: 2
	jr debajo_fin		;57ec
debajo_suelo:
	ld a,003h		;57ee   ; filas bajadas x 8...
	sub b			;57f0
	sla a		;57f1
	sla a		;57f3
	sla a		;57f5
	add a,(ix+002h)		;57f7   ; ...a la Y
	ld (ix+002h),a		;57fa
	ld a,b			;57fd   ; en la ultima fila?
	cp 001h		;57fe
	jr z,debajo_escalon		;5800
	sub a			;5802
	jr debajo_fin		;5803
debajo_escalon:
	ld a,001h		;5805
debajo_fin:
	pop bc			;5807
	pop de			;5808
	pop hl			;5809
	and a			;580a
	ret			;580b
esconde_sprite:		; Pone a cero el sprite IY, salvo si es de un enemigo escondido tras una puerta (bit 2)
	exx			;580c
	push iy		;580d
	pop hl			;580f
	ld a,l			;5810   ; los sprites 3 a 10...
	cp 00ch		;5811
	jr c,esconde_sprite_cero		;5813
	cp 02ch		;5815
	jr nc,esconde_sprite_cero		;5817
	ld hl,0c2e0h		;5819   ; ...son los de los enemigos
	ld de,0000ah		;581c
	ld b,004h		;581f
	sub 008h		;5821
esconde_sprite_busca:
	sub 004h		;5823   ; el sprite de la cabeza...
	jr z,esconde_sprite_enemigo		;5825
	sub 004h		;5827   ; ...o el de los pies del enemigo?
	jr z,esconde_sprite_enemigo		;5829
	add hl,de			;582b   ; el siguiente enemigo
	djnz esconde_sprite_busca		;582c   ; los 4
	jr esconde_sprite_cero		;582e
esconde_sprite_enemigo:
	bit 2,(hl)		;5830   ; tras la puerta: se deja
	jr z,esconde_sprite_cero		;5832
	exx			;5834
	jr esconde_sprite_sig		;5835
esconde_sprite_cero:
	exx			;5837
	sub a			;5838   ; cero
	ld (iy+000h),a		;5839   ; Y
	ld (iy+001h),a		;583c   ; X
	ld (iy+002h),a		;583f   ; dibujo
	ld (iy+003h),a		;5842   ; color
esconde_sprite_sig:
	inc iy		;5845
	inc iy		;5847
	inc iy		;5849
	inc iy		;584b
	ret			;584d

; ----------------------------------------------------------------------
; DATOS agente_disparo: Dibujos del agente disparando (por postura)
;   0x584e..0x5856  (8 bytes)
DATA_agente_disparo:
	defb 0a6h,058h,0a8h,058h,0ach,058h,0aeh,058h	; 584e  .X.X.X.X

; ----------------------------------------------------------------------
; DATOS agente_dibujos: Tabla de dibujos del agente: una lista por postura y
;   en cada una un puntero por cuadro
;   0x5856..0x58a6  (80 bytes)
DATA_agente_dibujos:
	defb 066h,058h,068h,058h,06ch,058h,07ch,058h,06eh,058h,084h,058h,08ch,058h,096h,058h	; 5856  fXhXlX|XnX.X.X.X
	defb 0b6h,058h,0b6h,058h,0c0h,058h,0deh,058h,027h,059h,0c0h,058h,0b6h,058h,0b6h,058h	; 5866  .X.X.X.X'Y.X.X.X
	defb 0c0h,058h,027h,059h,027h,059h,0ech,058h,0f6h,058h,0f6h,058h,0ech,058h,004h,059h	; 5876  .X'Y'Y.X.X.X.X.Y
	defb 00bh,059h,023h,059h,027h,059h,0f6h,058h,01ch,059h,0f6h,058h,023h,059h,027h,059h	; 5886  .Y#Y'Y.X.Y.X#Y'Y
	defb 012h,059h,01ch,059h,0f6h,058h,01ch,059h,0f6h,058h,01ch,059h,023h,059h,027h,059h	; 5896  .Y.Y.X.Y.X.Y#Y'Y

; ----------------------------------------------------------------------
; DATOS agente_cuadros: Los cuadros: por sprite dibujo, color y desplazamiento
;   de la Y; 0xFF acaba
;   0x58a6..0x5928  (130 bytes)
DATA_agente_cuadros:
	defb 0cah,058h,0cah,058h,0d4h,058h,0e5h,058h,0ech,058h,0fdh,058h,0fdh,058h,0ech,058h	; 58a6  .X.X.X.X.X.X.X.X
	defb 004h,006h,0e0h,008h,00bh,0e9h,00ch,006h,0f0h,0ffh,004h,006h,0e0h,008h,00bh,0e9h	; 58b6  ................
	defb 010h,006h,0f0h,0ffh,014h,006h,0e0h,018h,00bh,0e9h,01ch,006h,0f0h,0ffh,014h,006h	; 58c6  ................
	defb 0e0h,018h,00bh,0e9h,020h,006h,0f0h,0ffh,024h,006h,0f0h,028h,00bh,0f1h,0ffh,02ch	; 58d6  .... ...$..(...,
	defb 006h,0f0h,030h,00bh,0f1h,0ffh,004h,006h,0e0h,034h,00bh,0e9h,038h,006h,0f0h,0ffh	; 58e6  ..0......4..8...
	defb 034h,00bh,0f1h,03ch,006h,0f0h,0ffh,034h,00bh,0f1h,040h,006h,0f0h,0ffh,0e8h,006h	; 58f6  4..<...4..@.....
	defb 0efh,0ech,00bh,0efh,0ffh,0f0h,006h,0efh,0f4h,00bh,0efh,0ffh,044h,006h,0e0h,048h	; 5906  ............D..H
	defb 00bh,0e9h,04ch,006h,0f0h,0ffh,050h,006h,0f0h,054h,00bh,0f0h,0ffh,0e4h,00bh,0f0h	; 5916  ..L...P..T......
	defb 0ffh,0ffh	; 5926

; ----------------------------------------------------------------------
; DATOS txt_500: "500": lo que aparece en la puerta roja al coger los
;   documentos
;   0x5928..0x5930  (8 bytes)
DATA_txt_500:
	defb 02ch,059h,01dh,071h,002h,093h,094h,0ffh	; 5928  ,Y.q....

; ======================================================================
; CODIGO 0x5930..0x5a78  (328 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  Las escaleras mecanicas  =====
; ----------------------------------------------------------------------
agente_escalera:		; De pie al pie de una escalera y pulsando arriba o abajo: se sube a ella
	exx			;5930
	bit 0,(ix+003h)		;5931   ; de pie?
	jr z,agente_escalera_no		;5935
	ld a,0ffh		;5937   ; el mando
	call lee_mando		;5939
	or a			;593c
	jr z,agente_escalera_no		;593d
	cp 001h		;593f   ; arriba
	jr z,agente_escalera_arriba		;5941
	cp 005h		;5943   ; abajo
	jr nz,agente_escalera_no		;5945
	ld a,0ffh		;5947   ; 0xFF: abajo
	jr agente_escalera_planta		;5949
agente_escalera_arriba:
	xor a			;594b
agente_escalera_planta:
	ex af,af'			;594c
	ld a,(0c0d3h)		;594d   ; la fila del scroll...
	ld h,a			;5950
	ld l,006h		;5951   ; ...entre 6: la planta
	call divide		;5953
	ld a,d			;5956
	cp 00bh		;5957   ; de la 11...
	jr c,agente_escalera_no		;5959
	cp 010h		;595b   ; ...a la 15
	jr nc,agente_escalera_no		;595d
	cp 00ch		;595f
	jr c,agente_escalera_11		;5961
	cp 00eh		;5963
	jr z,agente_escalera_14		;5965
	jr nc,agente_escalera_15		;5967
	call escalera_bajar_aqui		;5969   ; las de bajar
	jr z,agente_escalera_hay		;596c
	call escalera_subir_aqui		;596e   ; o las de subir
	jr z,agente_escalera_hay		;5971
	jr agente_escalera_no		;5973
agente_escalera_11:
	call escalera_bajar_aqui		;5975
	jr z,agente_escalera_hay		;5978
	jr agente_escalera_no		;597a
agente_escalera_14:
	call escalera_subir_aqui		;597c
	jr z,agente_escalera_hay		;597f
	call escalera_bajar_planta14		;5981
	jr z,agente_escalera_hay		;5984
	jr agente_escalera_no		;5986
agente_escalera_15:
	call escalera_subir_planta15		;5988
	jr z,agente_escalera_hay		;598b
agente_escalera_no:
	xor a			;598d
	exx			;598e
	ret			;598f
agente_escalera_hay:		; La escalera tiene que ir hacia donde se pulsa
	ex af,af'			;5990
	or a			;5991
	jr nz,agente_escalera_baja		;5992   ; arriba: solo las de subir (C = 0xFF)
	inc c			;5994
	jr nz,agente_escalera_no		;5995
	jr agente_escalera_sube_a		;5997
agente_escalera_baja:
	inc c			;5999
	jr z,agente_escalera_no		;599a
agente_escalera_sube_a:
	ld a,c			;599c   ; la escalera es de bajar?
	or a			;599d
	jr nz,agente_escalera_x		;599e
	ex af,af'			;59a0   ; lo pulsado
	cp 080h		;59a1   ; la X: mitad izquierda?
	jr c,agente_escalera_izq		;59a3
	jr agente_escalera_der		;59a5
agente_escalera_x:
	ex af,af'			;59a7
	or a			;59a8
	jr nz,agente_escalera_x2		;59a9
	ld (ix+001h),004h		;59ab   ; en el borde izquierdo
	jr agente_escalera_lado		;59af
agente_escalera_x2:
	cp 0e8h		;59b1
	jr nz,agente_escalera_lado		;59b3
	ld (ix+001h),0e4h		;59b5   ; en el borde derecho
agente_escalera_lado:
	cp 080h		;59b9
	jr c,agente_escalera_der		;59bb
agente_escalera_izq:
	set 7,(ix+000h)		;59bd
	jr agente_escalera_empieza		;59c1
agente_escalera_der:
	res 7,(ix+000h)		;59c3
agente_escalera_empieza:
	call dibujos_del_lado		;59c7
	set 2,(ix+000h)		;59ca   ; bit 2: en la escalera
	ld a,e			;59ce   ; el tramo
	ld (0c38ah),a		;59cf
	ld a,002h		;59d2   ; un paso cada 2 cuadros
	ld (0c389h),a		;59d4
	ld hl,0c388h		;59d7   ; paso 0
	ld (hl),000h		;59da
	ld hl,05e5eh		;59dc   ; la X del primer paso
	call escalera_x_del_paso		;59df
	call sprite_sin_dibujo		;59e2   ; el agente sin un sprite
	ld a,e			;59e5
	cp 003h		;59e6   ; bajando: el scroll sigue
	call c,escalera_scroll		;59e8
	ld a,012h		;59eb   ; el sonido de la escalera
	call sonido		;59ed
	push ix		;59f0
	push iy		;59f2
	call piernas_fuera		;59f4   ; los enemigos que van detras
	pop iy		;59f7
	pop ix		;59f9
	exx			;59fb
	ld a,0ffh		;59fc   ; el agente se ha movido
	ld (0c399h),a		;59fe
	ret			;5a01
escalera_bajar_aqui:		; Z si la X del agente es la de arriba de una escalera de bajar (C=0)
	ld c,000h		;5a02
	ld e,001h		;5a04   ; tramo 1
	ld b,004h		;5a06
	call x_es		;5a08
	ret z			;5a0b
	bit 7,(ix+000h)		;5a0c   ; mirando a la izquierda?
	jr nz,escalera_bajar_i		;5a10
	ld b,008h		;5a12
	call x_es		;5a14
	ret z			;5a17
	jr escalera_bajar_2		;5a18
escalera_bajar_i:
	ld b,000h		;5a1a
	call x_es		;5a1c
	ret z			;5a1f
escalera_bajar_2:
	ld b,00ch		;5a20
	call x_es		;5a22
	ret z			;5a25
escalera_bajar_tramo_2:
	ld e,002h		;5a26   ; tramo 2
	ld b,0e4h		;5a28
	call x_es		;5a2a
	ret z			;5a2d
	bit 7,(ix+000h)		;5a2e
	jr z,escalera_bajar_d		;5a32
	ld b,0e0h		;5a34
	call x_es		;5a36
	ret z			;5a39
	jr escalera_bajar_ultima		;5a3a
escalera_bajar_d:
	ld b,0e8h		;5a3c
	call x_es		;5a3e
	ret z			;5a41
escalera_bajar_ultima:
	ld b,0dch		;5a42
	call x_es		;5a44
	ret			;5a47
escalera_subir_aqui:		; Z si la X es la de abajo de una escalera de subir (C=0xFF)
	ld c,0ffh		;5a48
	ld e,004h		;5a4a   ; tramo 4
	ld b,02ch		;5a4c   ; la X del pie del tramo 4
	call x_es		;5a4e
	ret z			;5a51
	bit 7,(ix+000h)		;5a52   ; mira a la izquierda?
	jr z,escalera_subir_d		;5a56
	ld b,028h		;5a58   ; la otra X
	call x_es		;5a5a
	ret z			;5a5d
	jr escalera_subir_tramo_3		;5a5e
escalera_subir_d:
	ld b,030h		;5a60
	call x_es		;5a62
	ret z			;5a65
escalera_subir_tramo_3:
	ld e,003h		;5a66   ; tramo 3
	ld b,0bch		;5a68
	call x_es		;5a6a
	ret z			;5a6d
	bit 7,(ix+000h)		;5a6e
	jr nz,$+7		;5a72
	ld b,0c0h		;5a74
	jr $+15		;5a76

; ----------------------------------------------------------------------
; DATOS escalera_ret: Un "ret" (0xC9) que el salto de 0x5A72 se salta: 0x5A72
;   va a 0x5A79 y 0x5A76 a 0x5A85
;   0x5a78..0x5a79  (1 bytes)
DATA_escalera_ret:
	defb 0c9h	; 5a78

; ======================================================================
; CODIGO 0x5a79..0x5a8a  (17 bytes)
; ======================================================================


escalera_subir_ultima:
	ld b,0b8h		;5a79
	jr x_es		;5a7b
escalera_bajar_planta14:		; Planta 14: solo la de bajar del tramo 2
	ld c,000h		;5a7d
	jr $-89		;5a7f
escalera_subir_planta15:		; Planta 15: solo la de subir del tramo 3
	ld c,0ffh		;5a81
	jr $-29		;5a83
x_es:		; Z si la X de IX es B
	ld a,(ix+001h)		;5a85
	cp b			;5a88
	ret			;5a89

; ----------------------------------------------------------------------
; DATOS sin_uso_and_ret: Dos bytes que nada alcanza: "and a / ret"
;   0x5a8a..0x5a8c  (2 bytes)
DATA_sin_uso_and_ret:
	defb 0a7h,0c9h	; 5a8a

; ======================================================================
; CODIGO 0x5a8c..0x5c57  (459 bytes)
; ======================================================================


agente_en_escalera:		; Un paso de la escalera cada 2 cuadros: 7 pasos, el agente medio escondido tras el pasamanos
	ld hl,0c389h		;5a8c   ; la cuenta de cuadros
	dec (hl)			;5a8f
	ret nz			;5a90
	ld a,0ffh		;5a91   ; el agente se ha movido
	ld (0c399h),a		;5a93
	ld (hl),002h		;5a96   ; otros 2 cuadros
	ld a,(0c38ah)		;5a98   ; el tramo
	ld e,a			;5a9b
	ld hl,0c388h		;5a9c   ; paso siguiente
	inc (hl)			;5a9f
	cp 003h		;5aa0   ; subiendo?
	ld a,(hl)			;5aa2
	jr nc,agente_escalera_sube_paso		;5aa3
	cp 002h		;5aa5
	jr z,escalera_pies_fuera		;5aa7
	jr c,escalera_paso_1		;5aa9
	cp 004h		;5aab
	jr c,escalera_paso_3		;5aad
	jr z,escalera_paso_4		;5aaf
	cp 006h		;5ab1
	jr c,escalera_paso_5		;5ab3
	jr z,escalera_paso_6		;5ab5
	jr escalera_fin		;5ab7
agente_escalera_sube_paso:
	cp 002h		;5ab9   ; el paso
	jr c,escalera_paso_1		;5abb
	jr z,escalera_paso_2b		;5abd
	cp 004h		;5abf
	jr c,escalera_pies_fuera		;5ac1
	jr z,escalera_paso_4		;5ac3
	cp 006h		;5ac5   ; los pasos 5 y 6
	jr c,escalera_paso_5		;5ac7
	jr z,escalera_paso_6		;5ac9
	jr escalera_fin		;5acb   ; el 7
escalera_pies_fuera:		; Paso 2: los tres sprites del agente sin dibujo (las piernas tras el escalon)
	ld hl,0c000h		;5acd
	ld b,003h		;5ad0
escalera_pies_sig:
	inc hl			;5ad2   ; el dibujo...
	inc hl			;5ad3
	ld (hl),000h		;5ad4   ; ...a cero
	inc hl			;5ad6
	inc hl			;5ad7
	djnz escalera_pies_sig		;5ad8   ; los tres
	jp escalera_scroll		;5ada   ; el scroll
escalera_paso_1:
	ld hl,05e68h		;5add
escalera_paso:
	call escalera_x_del_paso		;5ae0
	call sprite_sin_dibujo		;5ae3
	jr escalera_scroll		;5ae6
escalera_x_del_paso:		; B = la X del paso E de la tabla HL, y los dos sprites del agente ahi
	ld d,000h		;5ae8
	add hl,de			;5aea
	ld b,(hl)			;5aeb
	jp agente_dos_sprites		;5aec
escalera_paso_2b:
	ld hl,05e6dh		;5aef
	jr escalera_paso		;5af2
escalera_paso_3:
	ld hl,05e72h		;5af4
	jr escalera_paso		;5af7
escalera_paso_4:
	ld hl,05e77h		;5af9
	jr escalera_paso		;5afc
escalera_paso_5:
	ld hl,05e7ch		;5afe
	jr escalera_paso		;5b01
escalera_paso_6:		; Paso 6: el agente vuelve a tener piernas; los enemigos que bajaban detras siguen
	ld hl,0c398h		;5b03   ; el scroll ya no sigue
	ld (hl),000h		;5b06
	ld hl,05e81h		;5b08   ; los tres sprites
	call agente_tres_sprites		;5b0b
	exx			;5b0e
	push ix		;5b0f
	push iy		;5b11
	call piernas_dentro		;5b13
	pop iy		;5b16
	pop ix		;5b18
	exx			;5b1a
	ld a,e			;5b1b
	cp 003h		;5b1c
	ret c			;5b1e
	jr escalera_scroll		;5b1f
escalera_fin:		; Paso 7: fuera de la escalera, de pie y mirando hacia donde salio
	ld hl,0c398h		;5b21
	ld (hl),000h		;5b24
	ld hl,05e86h		;5b26
	call agente_tres_sprites		;5b29
	res 2,(ix+000h)		;5b2c   ; bit 2 fuera
	xor a			;5b30
	ld (0c389h),a		;5b31
	ld (0c38ah),a		;5b34
	ld (0c399h),a		;5b37
	ld (ix+001h),b		;5b3a   ; la X final
	push hl			;5b3d
	ld hl,05856h		;5b3e   ; los dibujos de siempre
	ld (ix+005h),l		;5b41
	ld (ix+006h),h		;5b44
	pop hl			;5b47
	ld (ix+003h),001h		;5b48   ; de pie
	ld (ix+004h),001h		;5b4c
	ld a,e			;5b50   ; subiendo, mira segun el tramo
	cp 003h		;5b51
	ret c			;5b53
	jr z,escalera_fin_izq		;5b54
	res 7,(ix+000h)		;5b56
	jr escalera_fin_lado		;5b5a
escalera_fin_izq:
	set 7,(ix+000h)		;5b5c
escalera_fin_lado:
	jp dibujos_del_lado		;5b60
escalera_scroll:		; El scroll sigue al agente: 0x64 filas bajando o 0x75 subiendo
	ld hl,0c0d0h		;5b63
	set 6,(hl)		;5b66   ; bit 6: scroll de escalera
	ld a,e			;5b68   ; bajando?
	cp 003h		;5b69
	push af			;5b6b
	jr nc,escalera_scroll_sube		;5b6c
	ld a,064h		;5b6e
	res 0,(hl)		;5b70   ; bit 0 = 0
	jr escalera_scroll_guarda		;5b72
escalera_scroll_sube:
	ld a,075h		;5b74
	set 0,(hl)		;5b76
escalera_scroll_guarda:
	ld (0c398h),a		;5b78
	pop af			;5b7b
	ret			;5b7c
agente_dos_sprites:		; Los dos primeros sprites del agente en la X B (cabeza y cuerpo, dibujos 4 y 8)
	ld hl,0c000h		;5b7d
	ld c,(hl)			;5b80   ; la Y del primero
	inc hl			;5b81
	ld (hl),b			;5b82
	inc hl			;5b83
	ld (hl),004h		;5b84
	inc hl			;5b86
	ld (hl),006h		;5b87
	inc hl			;5b89
	ld a,c			;5b8a
	add a,009h		;5b8b   ; la del segundo, 9 mas abajo
	ld (hl),a			;5b8d
	inc hl			;5b8e
	ld (hl),b			;5b8f
	inc hl			;5b90
	ld (hl),008h		;5b91
	inc hl			;5b93
	ld (hl),00bh		;5b94
	inc hl			;5b96
	ret			;5b97
agente_tres_sprites:		; Los tres sprites del agente en la X B: dibujos 4, 8 y 0x0C
	ld d,000h		;5b98   ; el paso...
	add hl,de			;5b9a
	ld b,(hl)			;5b9b   ; ...su X
	ld hl,0c000h		;5b9c   ; el primer sprite
	ld c,(hl)			;5b9f   ; su Y
	inc hl			;5ba0
	ld (hl),b			;5ba1   ; X
	inc hl			;5ba2
	ld (hl),004h		;5ba3   ; dibujo 4
	inc hl			;5ba5
	ld (hl),006h		;5ba6   ; color 6
	inc hl			;5ba8
	ld a,c			;5ba9
	add a,009h		;5baa   ; el segundo, 9 mas abajo
	ld (hl),a			;5bac
	inc hl			;5bad
	ld (hl),b			;5bae
	inc hl			;5baf
	ld (hl),008h		;5bb0
	inc hl			;5bb2
	ld (hl),00bh		;5bb3
	inc hl			;5bb5
	ld a,c			;5bb6
	add a,010h		;5bb7   ; el tercero, 16 mas abajo
	ld (hl),a			;5bb9
	inc hl			;5bba
	ld (hl),b			;5bbb
	inc hl			;5bbc
	ld (hl),00ch		;5bbd   ; dibujo 0x0C
	inc hl			;5bbf
	ld (hl),006h		;5bc0   ; color 6
	ret			;5bc2   ; listo
sprite_sin_dibujo:		; El dibujo del sprite siguiente (HL+2) a cero
	inc hl			;5bc3
	inc hl			;5bc4
	ld (hl),000h		;5bc5
	ret			;5bc7
enemigo_escalera:		; Un enemigo al pie de una escalera, si va en la direccion buena, se sube
	exx			;5bc8
	ld a,(ix+003h)		;5bc9   ; de pie o andando?
	and 003h		;5bcc
	jp z,enemigo_escalera_no		;5bce
	call hay_escalera		;5bd1   ; hay escalera?
	jp nz,enemigo_escalera_no		;5bd4
	ld a,c			;5bd7   ; de las de subir?
	or a			;5bd8
	jr z,enemigo_escalera_baja		;5bd9
	ex af,af'			;5bdb
	or a			;5bdc
	push af			;5bdd
	ex af,af'			;5bde
	pop af			;5bdf
	jp z,enemigo_escalera_no		;5be0
	jp m,enemigo_escalera_no		;5be3
	jr enemigo_escalera_sube		;5be6
enemigo_escalera_baja:
	ex af,af'			;5be8   ; lo que quiere
	or a			;5be9
	push af			;5bea
	ex af,af'			;5beb
	pop af			;5bec
	jp z,enemigo_escalera_no		;5bed   ; nada: no
	jp p,enemigo_escalera_no		;5bf0   ; arriba: no
enemigo_escalera_sube:
	push iy		;5bf3
	call cuenta_escalera_nueva		;5bf5   ; su cuenta
	pop iy		;5bf8
	ld hl,05e5eh		;5bfa   ; la X del primer paso
	ld d,000h		;5bfd
	add hl,de			;5bff
	ld b,(hl)			;5c00
	push de			;5c01
	call sprites_del_enemigo		;5c02   ; sus sprites
	pop de			;5c05
	ld a,e			;5c06   ; bajando...
	cp 003h		;5c07
	ld a,(hl)			;5c09
	jr nc,enemigo_escalera_pon		;5c0a
	add a,008h		;5c0c   ; ...8 mas abajo
	ld (hl),a			;5c0e
enemigo_escalera_pon:
	push af			;5c0f
	add a,018h		;5c10   ; los pies, 24 por debajo
	ld (ix+002h),a		;5c12
	pop af			;5c15
	inc hl			;5c16
	ld (hl),b			;5c17
	ld (ix+001h),b		;5c18
	inc hl			;5c1b
	bit 0,e		;5c1c   ; cuerpo segun el lado
	jr nz,enemigo_escalera_der		;5c1e
	ld (hl),0c8h		;5c20
	jr enemigo_escalera_color		;5c22
enemigo_escalera_der:
	ld (hl),0cch		;5c24
enemigo_escalera_color:
	inc hl			;5c26
	ld (hl),004h		;5c27   ; color azul
	inc hl			;5c29
	inc hl			;5c2a
	inc hl			;5c2b
	ld (hl),000h		;5c2c   ; el tercer sprite sin dibujo
	ld (ix+003h),001h		;5c2e   ; de pie
	ld (ix+004h),001h		;5c32
	bit 0,e		;5c36
	jr nz,enemigo_escalera_der2		;5c38
	ld de,05c57h		;5c3a   ; los dibujos de la escalera
	ld (ix+005h),e		;5c3d
	ld (ix+006h),d		;5c40
	jr enemigo_escalera_sonido		;5c43
enemigo_escalera_der2:
	ld de,05c59h		;5c45
	ld (ix+005h),e		;5c48
	ld (ix+006h),d		;5c4b
enemigo_escalera_sonido:
	ld a,012h		;5c4e   ; el sonido de la escalera
	call sonido		;5c50
	ld a,0ffh		;5c53
	exx			;5c55
	ret			;5c56

; ----------------------------------------------------------------------
; DATOS enemigo_escalera_dib: Dibujos del enemigo en la escalera (tres
;   posturas)
;   0x5c57..0x5c78  (33 bytes)
DATA_enemigo_escalera_dib:
	defb 05dh,05ch,05fh,05ch,061h,05ch,063h,05ch,06ah,05ch,071h,05ch,0c8h,004h,0e8h,000h	; 5c57  ]\_\a\c\j\q\....
	defb 000h,000h,0ffh,0cch,004h,0e8h,000h,000h,000h,0ffh,000h,004h,0e8h,000h,000h,000h	; 5c67  ................
	defb 0ffh	; 5c77

; ======================================================================
; CODIGO 0x5c78..0x5e5e  (486 bytes)
; ======================================================================


cuenta_escalera_nueva:		; Apunta a IX en la escalera: tramo E, paso 0, 2 cuadros
	set 2,(ix+000h)		;5c78
	call cuenta_escalera		;5c7c   ; su cuenta
	ld (iy+000h),e		;5c7f   ; el tramo
	ld (iy+001h),000h		;5c82   ; paso 0
	ld (iy+002h),002h		;5c86   ; 2 cuadros
	ret			;5c8a
cuenta_escalera:		; IY = la cuenta de escalera numero 0xC397 (3 bytes cada una)
	ld bc,00003h		;5c8b
	ld iy,0c38bh		;5c8e
	ld a,(0c397h)		;5c92
cuenta_escalera_sig:
	or a			;5c95
	ret z			;5c96
	add iy,bc		;5c97
	dec a			;5c99
	jr cuenta_escalera_sig		;5c9a
hay_escalera:		; Z si IX esta al pie de una escalera de esta planta (en la Y 0x78, o una planta arriba o abajo)
	ld a,(0c0d3h)		;5c9c   ; la planta del scroll
	ld h,a			;5c9f
	ld l,006h		;5ca0
	call divide		;5ca2
	ex af,af'			;5ca5
	xor a			;5ca6
	ex af,af'			;5ca7
	and a			;5ca8   ; solo en filas multiplo de 6
	ret nz			;5ca9
	ld a,(ix+002h)		;5caa   ; en la planta del agente?
	cp 078h		;5cad
	jr z,hay_escalera_planta		;5caf
	jr c,hay_escalera_arriba		;5cb1
	inc d			;5cb3   ; una planta abajo
	ex af,af'			;5cb4
	inc a			;5cb5
	ex af,af'			;5cb6
	jr hay_escalera_planta		;5cb7
hay_escalera_arriba:
	dec d			;5cb9
	ex af,af'			;5cba
	dec a			;5cbb
	ex af,af'			;5cbc
hay_escalera_planta:
	ld a,d			;5cbd   ; la planta
	cp 00bh		;5cbe   ; de la 11...
	jr c,hay_escalera_no		;5cc0
	cp 010h		;5cc2   ; ...a la 15
	jr nc,hay_escalera_no		;5cc4
	cp 00ch		;5cc6   ; 11: solo bajar
	jp c,escalera_bajar_aqui		;5cc8
	cp 00eh		;5ccb   ; 14?
	jr z,hay_escalera_14		;5ccd
	jr nc,hay_escalera_15		;5ccf
	call escalera_bajar_aqui		;5cd1   ; 12 y 13: bajar...
	ret z			;5cd4
	jp escalera_subir_aqui		;5cd5   ; ...o subir
hay_escalera_14:
	call escalera_subir_aqui		;5cd8
	ret z			;5cdb
	jp escalera_bajar_planta14		;5cdc
hay_escalera_15:
	jp escalera_subir_planta15		;5cdf
hay_escalera_no:
	ld a,0ffh		;5ce2
	or a			;5ce4
	ret			;5ce5
enemigo_escalera_no:
	exx			;5ce6
	xor a			;5ce7
	ret			;5ce8
enemigo_en_escalera:		; Un paso de la escalera del enemigo; si el agente va en ella, al mismo ritmo
	exx			;5ce9
	push iy		;5cea
	call cuenta_escalera		;5cec   ; su cuenta
	ld hl,0c0d8h		;5cef
	bit 2,(hl)		;5cf2   ; el agente en la escalera?
	jr z,enemigo_escalera_cuenta		;5cf4
	ld a,(0c399h)		;5cf6   ; se mueve con el
	or a			;5cf9
	jp z,enemigo_escalera_sale		;5cfa
	jr enemigo_escalera_paso		;5cfd
enemigo_escalera_cuenta:
	dec (iy+002h)		;5cff   ; cada 2 cuadros
	jp nz,enemigo_escalera_sale		;5d02
	ld (iy+002h),002h		;5d05
enemigo_escalera_paso:
	inc (iy+001h)		;5d09   ; paso siguiente
	call sprites_del_enemigo		;5d0c
	ld a,(iy+000h)		;5d0f   ; el tramo
	ld e,a			;5d12
	cp 003h		;5d13
	ld a,(iy+001h)		;5d15
	pop iy		;5d18
	jr nc,enemigo_escalera_sube_p		;5d1a
	cp 002h		;5d1c
	jr z,enemigo_escalera_baja8		;5d1e
	jr c,enemigo_paso_1		;5d20
	cp 004h		;5d22
	jr c,enemigo_paso_3		;5d24
	jr z,enemigo_paso_4		;5d26
	cp 006h		;5d28
	jr c,enemigo_paso_5		;5d2a
	jr z,enemigo_paso_6		;5d2c
	jr enemigo_escalera_fin		;5d2e
enemigo_escalera_sube_p:
	cp 002h		;5d30   ; el paso
	jr c,enemigo_paso_1		;5d32
	jr z,enemigo_paso_2b		;5d34
	cp 004h		;5d36
	jr c,enemigo_escalera_baja8		;5d38
	jr z,enemigo_paso_4		;5d3a
	cp 006h		;5d3c
	jr c,enemigo_paso_5		;5d3e
	jr z,enemigo_paso_6		;5d40
	jr enemigo_escalera_fin		;5d42   ; el 7
enemigo_escalera_baja8:		; Paso 2: 8 pixeles arriba o abajo y sin piernas
	ld a,e			;5d44   ; el tramo
	cp 003h		;5d45   ; subiendo?
	ld a,(hl)			;5d47
	jr c,enemigo_escalera_mas8		;5d48
	sub 008h		;5d4a   ; - 8
	jr enemigo_escalera_y		;5d4c
enemigo_escalera_mas8:
	add a,008h		;5d4e
enemigo_escalera_y:
	ld (hl),a			;5d50   ; la Y del sprite
	push af			;5d51
	add a,018h		;5d52   ; los pies, 24 mas abajo
	ld (ix+002h),a		;5d54
	pop af			;5d57
	inc hl			;5d58
	inc hl			;5d59
	ld (hl),000h		;5d5a   ; sin dibujo
	ld de,05c5bh		;5d5c   ; los dibujos sin piernas
	ld (ix+005h),e		;5d5f
	ld (ix+006h),d		;5d62
	jr enemigo_escalera_ret		;5d65
enemigo_paso_1:
	ld hl,05e68h		;5d67
	jr enemigo_escalera_x		;5d6a
enemigo_paso_2b:
	ld hl,05e6dh		;5d6c
	jr enemigo_escalera_x		;5d6f
enemigo_paso_3:
	ld hl,05e72h		;5d71
	jr enemigo_escalera_x		;5d74
enemigo_paso_4:
	ld hl,05e77h		;5d76
	jr enemigo_escalera_x		;5d79
enemigo_paso_5:
	ld hl,05e7ch		;5d7b
	jr enemigo_escalera_x		;5d7e
enemigo_paso_6:
	ld hl,05e81h		;5d80
	call enemigo_escalera_piernas		;5d83
	jr enemigo_escalera_ret		;5d86
enemigo_escalera_fin:		; Fin: fuera de la escalera; espera 10 cuadros
	ld hl,05e86h		;5d88
	call enemigo_escalera_piernas		;5d8b
	res 2,(ix+000h)		;5d8e   ; bit 2 fuera
	push iy		;5d92
	call cuenta_escalera		;5d94
	ld (iy+000h),000h		;5d97   ; la cuenta libre
	ld (iy+001h),000h		;5d9b
	ld (iy+002h),000h		;5d9f
	pop iy		;5da3
	exx			;5da5
	ld a,c			;5da6
	ld b,00ah		;5da7   ; 10 cuadros
	jp pon_temporizador		;5da9
enemigo_escalera_ret:
	exx			;5dac
	ret			;5dad
enemigo_escalera_x:		; La X del paso, los dibujos y la Y (8 arriba o abajo)
	ld d,000h		;5dae   ; la X del paso
	add hl,de			;5db0
	ld b,(hl)			;5db1
	push de			;5db2
	call sprites_del_enemigo		;5db3   ; sus sprites
	pop de			;5db6
	push de			;5db7
	bit 0,e		;5db8   ; a que lado?
	jr nz,enemigo_escalera_x_d		;5dba
	ld de,05c57h		;5dbc   ; los dibujos
	ld (ix+005h),e		;5dbf
	ld (ix+006h),d		;5dc2
	jr enemigo_escalera_x_y		;5dc5
enemigo_escalera_x_d:
	ld de,05c59h		;5dc7
	ld (ix+005h),e		;5dca
	ld (ix+006h),d		;5dcd
enemigo_escalera_x_y:
	pop de			;5dd0   ; el tramo
	ld a,e			;5dd1
	cp 003h		;5dd2   ; subiendo?
	ld a,(hl)			;5dd4
	jr c,enemigo_escalera_x_mas		;5dd5
	sub 008h		;5dd7   ; - 8
	jr enemigo_escalera_x_pon		;5dd9
enemigo_escalera_x_mas:
	add a,008h		;5ddb
enemigo_escalera_x_pon:
	ld (hl),a			;5ddd   ; la Y del sprite
	push af			;5dde
	add a,018h		;5ddf   ; los pies, 24 mas abajo
	ld (ix+002h),a		;5de1
	pop af			;5de4
	inc hl			;5de5
	ld (hl),b			;5de6   ; la X del sprite
	ld (ix+001h),b		;5de7   ; y la del enemigo
	inc hl			;5dea
	bit 0,e		;5deb   ; segun el lado...
	jr nz,enemigo_escalera_x_d2		;5ded
	ld (hl),0c8h		;5def   ; ...el dibujo del cuerpo
	jr enemigo_escalera_x_col		;5df1
enemigo_escalera_x_d2:
	ld (hl),0cch		;5df3
enemigo_escalera_x_col:
	inc hl			;5df5
	ld (hl),004h		;5df6
	ret			;5df8
enemigo_escalera_piernas:		; Pasos 6 y 7: el enemigo entero otra vez (dibujos 0x58 y 0x5C)
	ld d,000h		;5df9   ; la X del paso
	add hl,de			;5dfb
	ld b,(hl)			;5dfc
	push de			;5dfd
	push af			;5dfe
	call sprites_del_enemigo		;5dff   ; sus sprites
	pop af			;5e02
	pop de			;5e03
	cp 006h		;5e04   ; el sexto?
	jr nz,enemigo_escalera_pies		;5e06
	ld a,e			;5e08   ; subiendo?
	cp 003h		;5e09
	ld a,(hl)			;5e0b
	jr c,enemigo_escalera_pies		;5e0c
	sub 008h		;5e0e   ; - 8
	ld (hl),a			;5e10
enemigo_escalera_pies:
	ld a,(hl)			;5e11   ; la Y
	push af			;5e12
	add a,018h		;5e13   ; los pies, 24 mas abajo
	ld (ix+002h),a		;5e15
	pop af			;5e18
	inc hl			;5e19
	ld (hl),b			;5e1a   ; X
	ld (ix+001h),b		;5e1b
	inc hl			;5e1e
	ld (hl),058h		;5e1f   ; el cuerpo: dibujo 0x58
	inc hl			;5e21
	inc hl			;5e22
	add a,010h		;5e23   ; el segundo sprite, 16 mas abajo
	ld (hl),a			;5e25
	inc hl			;5e26
	ld (hl),b			;5e27
	inc hl			;5e28
	ld (hl),05ch		;5e29   ; las piernas: dibujo 0x5C
	inc hl			;5e2b
	ld (hl),004h		;5e2c
	ld (ix+003h),001h		;5e2e   ; de pie
	ld (ix+004h),001h		;5e32
	bit 0,e		;5e36   ; segun el lado...
	push de			;5e38
	jr nz,enemigo_escalera_der3		;5e39
	ld de,068a4h		;5e3b   ; ...los dibujos del enemigo
	jr enemigo_escalera_dib_pon		;5e3e
enemigo_escalera_der3:
	ld de,06894h		;5e40
enemigo_escalera_dib_pon:
	ld (ix+005h),e		;5e43
	ld (ix+006h),d		;5e46
	pop de			;5e49
	ret			;5e4a
enemigo_escalera_sale:
	pop iy		;5e4b
	exx			;5e4d
	ret			;5e4e
sprites_del_enemigo:		; HL = los sprites (8 bytes) del enemigo numero 0xC397
	ld hl,0c00ch		;5e4f
	ld de,00008h		;5e52
	ld a,(0c397h)		;5e55
sprites_del_enemigo_sig:
	or a			;5e58
	ret z			;5e59
	add hl,de			;5e5a
	dec a			;5e5b
	jr sprites_del_enemigo_sig		;5e5c

; ----------------------------------------------------------------------
; DATOS escalera_pasos: La X de cada paso de los 4 tramos de escalera (7
;   pasos)
;   0x5e5e..0x5e8b  (45 bytes)
DATA_escalera_pasos:
	defb 000h,00eh,0dah,0c2h,026h,000h,058h,058h,058h,058h,000h,016h,0d2h,0c6h,022h,000h	; 5e5e  ....&.XXXX....".
	defb 000h,000h,0cah,01eh,000h,01eh,0cah,000h,000h,000h,022h,0c6h,0d2h,016h,000h,026h	; 5e6e  .........."....&
	defb 0c2h,0dah,00eh,000h,02ch,0bch,0e4h,004h,000h,030h,0b8h,0e0h,008h	; 5e7e  ....,....0...

; ======================================================================
; CODIGO 0x5e8b..0x60db  (592 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  Los ascensores  =====
; ----------------------------------------------------------------------
ascensores_cuadro:		; Mueve los 11 ascensores: los que estan cerca de la vista van y vienen solos
	ld ix,0c0ech		;5e8b   ; los 11
	ld b,00bh		;5e8f
ascensor_uno:
	push bc			;5e91
	bit 1,(ix+000h)		;5e92   ; con el techo ocupado no se mueve
	jp nz,ascensor_sig		;5e96
	ld a,b			;5e99   ; su temporizador
	add a,000h		;5e9a
	call lee_temporizador		;5e9c
	jp nz,ascensor_sig		;5e9f
	ld a,(ix+002h)		;5ea2   ; su fila...
	bit 6,(ix+000h)		;5ea5   ; ...la de la segunda cabina, si es doble
	jr z,L_5EAD		;5ea9
	add a,00ch		;5eab
L_5EAD:
	add a,01eh		;5ead   ; respecto a la vista
	ld hl,0c0d3h		;5eaf
	sub (hl)			;5eb2
	jr c,ascensor_fuera		;5eb3   ; por encima: quieto
	cp 00dh		;5eb5   ; menos de 13 filas: hacia abajo
	jr nc,ascensor_lejos		;5eb7
	res 0,(ix+000h)		;5eb9
	jr ascensor_extremos		;5ebd
ascensor_lejos:
	bit 6,(ix+000h)		;5ebf
	jr z,L_5EC9		;5ec3
	sub 00ch		;5ec5
	jr c,ascensor_extremos		;5ec7
L_5EC9:
	cp 030h		;5ec9   ; a menos de 48 filas: sigue
	jr c,ascensor_extremos		;5ecb
	cp 048h		;5ecd   ; de 48 a 72: hacia arriba
	jr c,ascensor_sube_ya		;5ecf
	jr nz,ascensor_fuera		;5ed1
ascensor_sube_ya:
	set 0,(ix+000h)		;5ed3
	jr ascensor_extremos		;5ed7
ascensor_fuera:
	pop af			;5ed9
	push af			;5eda
	cp 00bh		;5edb   ; el ascensor 0 (el de la azotea) se mueve siempre
	jp nz,ascensor_sig		;5edd
ascensor_extremos:		; En la fila de arriba del recorrido cambia a bajar; en la de abajo, a subir
	ld a,(ix+002h)		;5ee0
	cp (ix+005h)		;5ee3   ; arriba del todo?
	jr z,ascensor_arriba		;5ee6
	cp (ix+006h)		;5ee8   ; abajo del todo?
	jr nz,ascensor_mueve		;5eeb
	ld a,(ix+000h)		;5eed
	bit 0,a		;5ef0
	jr nz,ascensor_mueve		;5ef2
	set 0,a		;5ef4
	jr ascensor_gira		;5ef6
ascensor_arriba:
	ld a,(ix+000h)		;5ef8
	bit 0,a		;5efb
	jr z,ascensor_mueve		;5efd
	res 0,a		;5eff
ascensor_gira:
	bit 7,(ix+000h)		;5f01   ; lleva al agente...
	jr z,ascensor_guarda		;5f05
	bit 4,(ix+000h)		;5f07   ; ...y en marcha: lo decide el
	jr nz,ascensor_parada		;5f0b
ascensor_guarda:
	ld (ix+000h),a		;5f0d
ascensor_mueve:
	bit 7,(ix+000h)		;5f10   ; lleva al agente?
	jr nz,ascensor_mueve_vista		;5f14
	call ascensor_una_fila		;5f16   ; no: una fila
	jr ascensor_parada		;5f19
ascensor_mueve_vista:		; Con el agente dentro, lo que se mueve es la vista (bit 6 de 0xC0D0)
	ld a,(0c0d0h)		;5f1b
	bit 0,(ix+000h)		;5f1e
	jr nz,ascensor_vista_baja		;5f22
	res 0,a		;5f24
	jr ascensor_vista		;5f26
ascensor_vista_baja:
	set 0,a		;5f28
ascensor_vista:
	set 6,a		;5f2a
	ld (0c0d0h),a		;5f2c
ascensor_parada:		; En una planta (suelo 0x60 o tejado al lado) espera 120 cuadros; si no, 20 por fila
	ld l,(ix+003h)		;5f2f   ; su sitio en el mapa
	ld h,(ix+004h)		;5f32
	dec hl			;5f35   ; la columna de su izquierda
	bit 7,(ix+000h)		;5f36
	jr z,ascensor_mira_planta		;5f3a
	ld de,00020h		;5f3c   ; con el agente, una fila mas abajo...
	add hl,de			;5f3f
	bit 0,(ix+000h)		;5f40
	jr z,L_5F4B		;5f44
	and a			;5f46   ; ...o una mas arriba si sube
	sbc hl,de		;5f47
	sbc hl,de		;5f49
L_5F4B:
	bit 4,(ix+000h)		;5f4b   ; en marcha a mano: sin parada
	jr nz,ascensor_espera_fila		;5f4f
ascensor_mira_planta:
	ld a,(hl)			;5f51
	cp 060h		;5f52
	jr z,ascensor_espera_planta		;5f54
	cp 00ah		;5f56
	jr nz,ascensor_espera_fila		;5f58
ascensor_espera_planta:
	ld b,078h		;5f5a
	jr ascensor_espera		;5f5c
ascensor_espera_fila:
	ld b,014h		;5f5e
ascensor_espera:
	pop af			;5f60
	push af			;5f61
	add a,000h		;5f62
	call pon_temporizador		;5f64
ascensor_sig:
	ld de,0000ah		;5f67   ; 10 bytes
	add ix,de		;5f6a   ; el siguiente
	pop bc			;5f6c
	dec b			;5f6d   ; uno menos
	jp nz,ascensor_uno		;5f6e   ; los 11
	ret			;5f71   ; listo
ascensor_una_fila:		; Sube o baja la cabina IX una fila y la vuelve a pintar en el mapa
	ld hl,0c0d0h		;5f72
	res 7,(hl)		;5f75   ; el mapa se vuelca despues
	push hl			;5f77
	bit 0,(ix+000h)		;5f78   ; sube?
	jr z,ascensor_baja_fila		;5f7c
	bit 3,(ix+000h)		;5f7e   ; con un enemigo dentro...
	jr z,L_5F89		;5f82
	ld a,0f8h		;5f84   ; ...8 arriba
	call enemigo_del_ascensor		;5f86
L_5F89:
	dec (ix+002h)		;5f89   ; fila - 1
	ld a,(ix+002h)		;5f8c
	dec a			;5f8f
	call sitio_en_mapa		;5f90   ; su sitio en el mapa
	ld (ix+003h),e		;5f93
	ld (ix+004h),d		;5f96
	ld hl,0610ch		;5f99   ; la cabina
	bit 6,(ix+000h)		;5f9c   ; doble: las dos
	jr z,L_5FA5		;5fa0
	ld hl,06128h		;5fa2
L_5FA5:
	call pon_tira		;5fa5
	ld a,(ix+002h)		;5fa8   ; debajo del suelo...
	inc a			;5fab
	cp (ix+006h)		;5fac
	jr z,ascensor_pintado		;5faf
	ld hl,06123h		;5fb1   ; ...el hueco
	call pon_tira		;5fb4
	jr ascensor_pintado		;5fb7
ascensor_baja_fila:
	bit 3,(ix+000h)		;5fb9
	jr z,L_5FC4		;5fbd
	ld a,008h		;5fbf   ; un enemigo dentro: 8 abajo
	call enemigo_del_ascensor		;5fc1
L_5FC4:
	inc (ix+002h)		;5fc4   ; fila + 1
	ld a,(ix+002h)		;5fc7
	dec a			;5fca
	call sitio_en_mapa		;5fcb
	ld (ix+003h),e		;5fce
	ld (ix+004h),d		;5fd1
	ld a,(ix+002h)		;5fd4   ; la de encima...
	dec a			;5fd7
	jr z,ascensor_pinta_cabina		;5fd8
	cp 006h		;5fda   ; ...salvo arriba del recorrido...
	jr z,ascensor_cable		;5fdc
	cp (ix+005h)		;5fde
	jr z,ascensor_pinta_cabina		;5fe1
ascensor_cable:
	dec a			;5fe3
	call sitio_en_mapa		;5fe4
	ld hl,06107h		;5fe7   ; ...es cable
	call pon_tira		;5fea
ascensor_pinta_cabina:
	ld hl,0610ch		;5fed
	bit 6,(ix+000h)		;5ff0
	jr z,L_5FF9		;5ff4
	ld hl,06128h		;5ff6
L_5FF9:
	call pon_tira		;5ff9
	bit 5,(ix+000h)		;5ffc   ; el del sotano...
	jr z,ascensor_pintado		;6000
	ld a,(ix+002h)		;6002   ; ...en lo mas bajo...
	cp (ix+006h)		;6005
	jr nz,ascensor_pintado		;6008
	add a,005h		;600a   ; ...5 filas mas abajo...
	bit 6,(ix+000h)		;600c
	jr z,ascensor_sotano		;6010
	add a,00ch		;6012
ascensor_sotano:
	call sitio_en_mapa		;6014
	ld hl,06163h		;6017   ; ...el suelo del sotano
	call pon_tira		;601a
ascensor_pintado:
	ld hl,0cf6fh		;601d   ; un tile fijo del sotano (0xCF6F = 0x68)
	ld (hl),068h		;6020
	pop hl			;6022   ; volcar en el proximo cuadro
	set 7,(hl)		;6023
	ret			;6025
enemigo_del_ascensor:		; Suma A a la Y del enemigo que va en el ascensor
	push iy		;6026
	push hl			;6028
	ld l,(ix+007h)		;6029   ; el ascensor...
	ld h,(ix+008h)		;602c
	push hl			;602f   ; ...en IY
	pop iy		;6030
	add a,(iy+002h)		;6032   ; su Y + A
	ld (iy+002h),a		;6035   ; guardada
	pop hl			;6038
	pop iy		;6039
	ret			;603b   ; listo
sitio_en_mapa:		; DE = 0xC400 + (A + 8) x 32 + la columna de IX
	push hl			;603c
	call fila_por_32		;603d   ; (A + 8) x 32
	ld e,(ix+001h)		;6040   ; + columna
	ld d,000h		;6043
	add hl,de			;6045
	ld de,0c400h		;6046   ; + 0xC400
	add hl,de			;6049
	ex de,hl			;604a   ; en DE
	pop hl			;604b
	ret			;604c   ; listo
fila_por_32:		; HL = (A + 8) x 32
	push bc			;604d
	add a,008h		;604e
	ld l,a			;6050
	ld h,000h		;6051
	ld b,005h		;6053
fila_por_32_sig:
	add hl,hl			;6055
	djnz fila_por_32_sig		;6056
	pop bc			;6058
	ret			;6059
ascensores_nuevos:		; Los 11 ascensores de la tabla 0x60DB; uno al azar de los cinco ultimos baja al sotano
	ld a,005h		;605a   ; uno de 5 al azar
	call azar		;605c
	ld c,a			;605f
	ld ix,0c0ech		;6060
	ld hl,060dbh		;6064   ; la tabla
	ld b,00bh		;6067
ascensor_nuevo:
	ld (ix+000h),000h		;6069
	ld a,(hl)			;606d   ; fila de arriba
	ld (ix+005h),a		;606e
	inc hl			;6071
	ld a,(hl)			;6072   ; fila de abajo
	ld (ix+006h),a		;6073
	inc hl			;6076
	ld a,(hl)			;6077   ; columna
	ld (ix+001h),a		;6078
	inc hl			;607b
	ld a,(hl)			;607c   ; fila de salida
	ld (ix+002h),a		;607d
	inc hl			;6080
	push bc			;6081
	ld a,b			;6082
	add a,000h		;6083
	ld b,078h		;6085   ; 120 cuadros antes de moverse
	call pon_temporizador		;6087
	pop bc			;608a
	ld a,b			;608b   ; de los cinco ultimos...
	cp 006h		;608c
	jr nc,ascensor_sotano_azar		;608e
	ld a,00ah		;6090   ; ...3 de cada 10...
	call azar		;6092
	cp 003h		;6095
	jr nc,ascensor_sotano_azar		;6097
	set 6,(ix+000h)		;6099   ; ...son dobles
	ld a,(ix+006h)		;609d   ; y su recorrido 12 filas mas corto
	sub 00ch		;60a0
	ld (ix+006h),a		;60a2
ascensor_sotano_azar:
	ld a,c			;60a5   ; el elegido...
	cp b			;60a6
	jr nz,ascensor_nuevo_sig		;60a7
	set 5,(ix+000h)		;60a9   ; ...baja al sotano
	call ascensor_hasta_sotano		;60ad
ascensor_nuevo_sig:
	ld de,0000ah		;60b0
	add ix,de		;60b3
	djnz ascensor_nuevo		;60b5
	ret			;60b7
ascensor_hasta_sotano:		; El recorrido se alarga una planta (6 filas) y se pinta el hueco
	push hl			;60b8
	push bc			;60b9
	ld a,(ix+006h)		;60ba
	add a,006h		;60bd   ; 6 filas mas
	ld (ix+006h),a		;60bf
	bit 6,(ix+000h)		;60c2
	jr z,ascensor_hasta_sotano_d		;60c6
	add a,00ch		;60c8
ascensor_hasta_sotano_d:
	dec a			;60ca
	call sitio_en_mapa		;60cb
	ld b,006h		;60ce   ; seis filas de hueco
ascensor_hueco_fila:
	ld hl,06123h		;60d0   ; un tramo de hueco
	call pon_tira		;60d3   ; pintado
	djnz ascensor_hueco_fila		;60d6   ; las 6 filas
	pop bc			;60d8
	pop hl			;60d9
	ret			;60da   ; listo

; ----------------------------------------------------------------------
; DATOS ascensores_tabla: Los 11 ascensores: fila de arriba, de abajo, columna
;   y fila de salida
;   0x60db..0x6107  (44 bytes)
DATA_ascensores_tabla:
	defb 000h,048h,00eh,000h,054h,060h,00eh,056h,060h,06ch,002h,065h,072h,07eh,00eh,072h	; 60db  .H..T`.V`l.er~.r
	defb 06ch,090h,01ah,073h,078h,090h,002h,07ah,090h,0b4h,016h,090h,090h,0b4h,012h,098h	; 60eb  l..sx..z........
	defb 09ch,0b4h,00eh,09ch,090h,0b4h,00ah,09ah,090h,0b4h,006h,09ch	; 60fb  ............

; ----------------------------------------------------------------------
; DATOS tira_cable: "hueco, cable, hueco" (0x2D 0x28 0x2D)
;   0x6107..0x610c  (5 bytes)
DATA_tira_cable:
	defb 003h,02dh,028h,02dh,0ffh	; 6107

; ----------------------------------------------------------------------
; DATOS tira_cabina: La cabina, 3 tiles de ancho (primer byte): techo 0x60, el
;   hueco de dentro 0x3B y suelo 0x60; 0xFF acaba
;   0x610c..0x6123  (23 bytes)
DATA_tira_cabina:
	defb 003h,060h,060h,060h,03bh,03bh,03bh,03bh,03bh,03bh,03bh,03bh,03bh,03bh,03bh,03bh	; 610c  .```;;;;;;;;;;;;
	defb 03bh,03bh,03bh,060h,060h,060h,0ffh	; 611c

; ----------------------------------------------------------------------
; DATOS tira_hueco: Tres tiles de hueco (0x2D)
;   0x6123..0x6128  (5 bytes)
DATA_tira_hueco:
	defb 003h,02dh,02dh,02dh,0ffh	; 6123

; ----------------------------------------------------------------------
; DATOS tira_doble: Las dos cabinas del ascensor doble con el cable entre
;   ellas
;   0x6128..0x6163  (59 bytes)
DATA_tira_doble:
	defb 003h,060h,060h,060h,03bh,03bh,03bh,03bh,03bh,03bh,03bh,03bh,03bh,03bh,03bh,03bh	; 6128  .```;;;;;;;;;;;;
	defb 03bh,03bh,03bh,060h,060h,060h,02dh,028h,02dh,02dh,028h,02dh,02dh,028h,02dh,02dh	; 6138  ;;;```-(--(--(--
	defb 028h,02dh,02dh,028h,02dh,060h,060h,060h,03bh,03bh,03bh,03bh,03bh,03bh,03bh,03bh	; 6148  (--(-```;;;;;;;;
	defb 03bh,03bh,03bh,03bh,03bh,03bh,03bh,060h,060h,060h,0ffh	; 6158  ;;;;;;;```.

; ----------------------------------------------------------------------
; DATOS tira_sotano: El suelo del hueco en el sotano (0x6B)
;   0x6163..0x6168  (5 bytes)
DATA_tira_sotano:
	defb 003h,06bh,06bh,06bh,0ffh	; 6163

; ======================================================================
; CODIGO 0x6168..0x6539  (977 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  Los enemigos  =====
; ----------------------------------------------------------------------
enemigos_cuadro:		; Los 4 enemigos: los que no estan en juego pueden salir por una puerta
	ld ix,0c2e0h		;6168   ; los 4
	ld b,004h		;616c
enemigo_uno:
	ld a,004h		;616e   ; su numero, para la escalera
	sub b			;6170
	ld (0c397h),a		;6171
	push bc			;6174
	bit 0,(ix+000h)		;6175   ; en juego?
	jr nz,enemigo_en_juego		;6179
	ld a,(0c308h)		;617b   ; salidas cortadas?
	bit 0,a		;617e
	jp nz,enemigo_sig		;6180
	ld a,015h		;6183   ; el temporizador de salida...
	ld c,a			;6185
	call lee_temporizador		;6186
	jp nz,enemigo_sig		;6189
	ld a,c			;618c   ; ...cada 60 cuadros...
	ld b,03ch		;618d
	call pon_temporizador		;618f
	ld a,(0c327h)		;6192   ; ...y la dificultad: 0xC327 cuentas de espera
	and a			;6195
	jr z,enemigo_sale		;6196
	dec a			;6198
	ld (0c327h),a		;6199
	jp enemigo_sig		;619c
enemigo_sale:		; Sale un enemigo por una puerta azul al azar cerca del agente
	ld a,(0c328h)		;619f   ; la cuenta vuelve a empezar
	ld (0c327h),a		;61a2
	pop bc			;61a5
	push bc			;61a6
	ld a,016h		;61a7   ; su temporizador...
	add a,b			;61a9
	dec a			;61aa
	ld b,01eh		;61ab   ; ...30 cuadros
	call pon_temporizador		;61ad
	ld a,006h		;61b0   ; una de 6 puertas
	call azar		;61b2
	call puerta_libre		;61b5   ; libre y en pantalla?
	jp nz,enemigo_sig		;61b8
	ld (ix+000h),001h		;61bb   ; en juego
	ld l,(iy+003h)		;61bf   ; la puerta...
	ld h,(iy+004h)		;61c2
	ld de,(0c0d1h)		;61c5   ; ...en la pantalla
	and a			;61c9
	sbc hl,de		;61ca
	bit 7,(iy+000h)		;61cc   ; mira a la izquierda?
	jr z,enemigo_sale_der		;61d0
	set 7,(ix+000h)		;61d2
	inc hl			;61d6
	jr enemigo_sale_sitio		;61d7
enemigo_sale_der:
	dec hl			;61d9
	dec hl			;61da
enemigo_sale_sitio:
	call a_pixeles		;61db   ; a pixeles
	ld (ix+001h),h		;61de
	ld (ix+002h),l		;61e1
	ld (ix+003h),010h		;61e4   ; saliendo de la puerta
	ld (ix+004h),001h		;61e8
	push iy		;61ec   ; su puerta
	pop hl			;61ee
	ld (ix+007h),l		;61ef
	ld (ix+008h),h		;61f2
	jp enemigo_saliendo_cuadro		;61f5
enemigo_en_juego:
	ld a,016h		;61f8
	add a,b			;61fa
	dec a			;61fb
	ld c,a			;61fc
	bit 2,(ix+000h)		;61fd   ; en la escalera...
	jr z,enemigo_mueve		;6201
	ld hl,0c0d8h		;6203   ; ...con el agente tambien en ella
	bit 2,(hl)		;6206
	jr z,enemigo_mueve		;6208
	call enemigo_en_escalera		;620a
	jp enemigo_sig		;620d
enemigo_mueve:		; Un paso cada 10 cuadros segun lo que este haciendo
	call lee_temporizador		;6210
	jp nz,enemigo_sig		;6213
	ld a,c			;6216   ; 10 cuadros
	ld b,00ah		;6217
	call pon_temporizador		;6219
	ld a,(ix+000h)		;621c
	bit 2,a		;621f   ; en la escalera
	jr z,enemigo_que_hace		;6221
	call enemigo_en_escalera		;6223
	jp enemigo_sig		;6226
enemigo_que_hace:
	bit 6,a		;6229   ; muriendo
	jr nz,enemigo_muere		;622b
	bit 1,a		;622d   ; en un ascensor
	jp nz,enemigo_en_ascensor		;622f
	bit 4,(ix+003h)		;6232   ; saliendo de la puerta
	jp nz,enemigo_saliendo		;6236
	bit 4,a		;6239   ; acaba de disparar?
	jp z,enemigo_anda		;623b
	ld a,c			;623e   ; 40 cuadros...
	ld b,028h		;623f
	call pon_temporizador		;6241
	ld a,001h		;6244   ; ...y la bala
	call dispara		;6246
	res 4,(ix+000h)		;6249
	jp enemigo_sig		;624d
enemigo_muere:		; Las muertes del enemigo: cae, tiroteado o aplastado
	ld a,c			;6250   ; un paso cada 30 cuadros
	ld b,01eh		;6251
	call pon_temporizador		;6253
	sub a			;6256
	call dibujos_enemigo		;6257   ; sus dibujos
	ld a,(ix+003h)		;625a
	bit 6,a		;625d   ; 0x40
	jr nz,enemigo_muere_cuenta		;625f
	bit 7,a		;6261   ; 0x80
	jr nz,enemigo_muere_cuenta		;6263
	bit 5,a		;6265   ; 0x20: aplastado
	jr nz,enemigo_aplastado		;6267
enemigo_muere_cuenta:
	inc (ix+004h)		;6269
	ld a,(ix+004h)		;626c
	cp 005h		;626f
	jp c,enemigo_dispara		;6271
	jr enemigo_fuera		;6274
enemigo_aplastado:
	res 5,a		;6276
	and a			;6278   ; sin otro bit?
	jr z,enemigo_aplastado_sig		;6279
	ld (ix+003h),020h		;627b   ; aplastado
	ld (ix+004h),001h		;627f   ; cuadro 1
	bit 2,a		;6283   ; en el suelo del ascensor?
	jr z,enemigo_aplastado_cuadro		;6285
	jp enemigo_sig		;6287
enemigo_aplastado_sig:
	inc (ix+004h)		;628a
enemigo_aplastado_cuadro:
	ld a,(ix+004h)		;628d   ; el cuadro
	cp 003h		;6290   ; 1 o 2?
	jr c,enemigo_aplastado_baja		;6292
	cp 005h		;6294   ; 3 o 4?
	jp c,enemigo_sig		;6296
	jr enemigo_fuera		;6299   ; el 5: fuera
enemigo_aplastado_baja:		; El ascensor que le aplasta baja una fila, y la vista con el si lleva al agente
	ld l,(ix+007h)		;629b
	ld h,(ix+008h)		;629e
	bit 7,(hl)		;62a1   ; lleva al agente?
	jr z,enemigo_aplastado_fila		;62a3
	ld c,0f8h		;62a5   ; 8 arriba...
	bit 3,(hl)		;62a7
	jr nz,enemigo_aplastado_vista		;62a9
	ld c,008h		;62ab   ; ...o abajo
enemigo_aplastado_vista:
	ld a,(0c0dah)		;62ad
	add a,c			;62b0
	ld (0c0dah),a		;62b1
enemigo_aplastado_fila:
	push ix		;62b4   ; se guarda
	push hl			;62b6
	pop ix		;62b7   ; el ascensor en IX
	call ascensor_una_fila		;62b9   ; una fila
	pop ix		;62bc   ; el enemigo
	jp enemigo_sig		;62be
enemigo_fuera:		; Se acaba: libera el ascensor y su techo
	res 0,(ix+000h)		;62c1
	ld l,(ix+007h)		;62c5
	ld h,(ix+008h)		;62c8
	bit 1,(ix+000h)		;62cb   ; en un ascensor?
	jr z,L_62D3		;62cf
	res 3,(hl)		;62d1   ; ya no lleva enemigo
L_62D3:
	bit 5,(ix+003h)		;62d3   ; aplastado?
	jp z,enemigo_sig		;62d7
	res 1,(hl)		;62da   ; techo libre
	jp enemigo_sig		;62dc
enemigo_en_ascensor:		; Dentro de un ascensor: se da la vuelta en la pared y dispara si tiene al agente delante
	call tile_de_los_pies		;62df
	ld b,003h		;62e2
	call choca_pared		;62e4   ; pared?
	jr z,enemigo_ascensor_mira		;62e7
	call da_la_vuelta		;62e9   ; se da la vuelta
enemigo_ascensor_mira:
	call a_la_altura_del_agente		;62ec   ; el agente a su altura?
	jp z,enemigo_anda_paso		;62ef
	ld (ix+003h),001h		;62f2   ; de pie
	jp enemigo_anda_paso		;62f6
enemigo_saliendo:		; Sale de la puerta: 6 cuadros con la puerta abierta
	inc (ix+004h)		;62f9
enemigo_saliendo_cuadro:
	ld a,(ix+004h)		;62fc
	cp 004h		;62ff
	jr c,enemigo_saliendo_puerta		;6301
	jr nz,enemigo_saliendo_fin		;6303
	call da_la_vuelta		;6305   ; en el cuarto, la vuelta
	jp enemigo_anda_paso		;6308
enemigo_saliendo_fin:
	cp 007h		;630b
	jr c,enemigo_saliendo_puerta		;630d
	res 0,(ix+000h)		;630f   ; en el septimo, si no ha salido, se va
	jp enemigo_sig		;6313
enemigo_saliendo_puerta:
	call puerta_animada		;6316   ; la puerta
	sub a			;6319
	call dibujos_enemigo		;631a
	jp enemigo_sig		;631d
enemigo_anda:		; En el suelo: escalera, paredes y huecos le dan la vuelta; si ve al agente decide
	bit 2,(ix+000h)		;6320
	jr nz,L_632D		;6324   ; se sube a una escalera?
	call enemigo_escalera		;6326
	or a			;6329
	jp nz,enemigo_sig		;632a
L_632D:
	call suelo_delante		;632d   ; lo que tiene delante
	jr z,enemigo_anda_mira		;6330
	cp 02dh		;6332   ; el hueco del ascensor...
	jr z,enemigo_anda_mira		;6334
	cp 03bh		;6336   ; ...o su cabina...
	jr z,enemigo_anda_mira		;6338
	call da_la_vuelta		;633a   ; ...si no, la vuelta
enemigo_anda_mira:
	call a_la_altura_del_agente		;633d   ; a la altura del agente?
	jr nz,enemigo_anda_paso		;6340
	call enemigo_decide		;6342   ; que hace ahora
	jr nz,enemigo_anda_comun		;6345
enemigo_anda_paso:
	bit 1,(ix+003h)		;6347   ; andando?
	jr nz,enemigo_anda_cuadro		;634b
	ld (ix+003h),002h		;634d   ; empieza a andar
	ld (ix+004h),001h		;6351
	jr enemigo_anda_comun		;6355
enemigo_anda_cuadro:
	ld a,(ix+004h)		;6357
	inc a			;635a   ; cuadro 1, 2, 1, 2...
	cp 003h		;635b
	jr c,L_6361		;635d
	ld a,001h		;635f
L_6361:
	ld (ix+004h),a		;6361
	call suelo_delante		;6364   ; puede avanzar?
	jr nz,enemigo_anda_comun		;6367
	call un_paso		;6369   ; el paso
	call enemigo_ascensor		;636c   ; se sube al ascensor?
enemigo_anda_comun:
	sub a			;636f
	call dibujos_enemigo		;6370   ; sus dibujos
	call agente_techo		;6373   ; un ascensor le aplasta?
	jr z,enemigo_anda_suelo		;6376
	ld hl,07119h		;6378
	call suma_puntos		;637b
enemigo_anda_suelo:
	call que_hay_debajo		;637e
	jr z,enemigo_dispara		;6381
	cp 002h		;6383   ; sin suelo...
	jr nz,enemigo_dispara		;6385
	ld (ix+003h),040h		;6387   ; ...cae
	ld (ix+004h),001h		;638b
	set 6,(ix+000h)		;638f
enemigo_dispara:		; Si le toca por la dificultad y el agente esta a su altura, se gira hacia el y dispara
	bit 6,(ix+000h)		;6393
	jr nz,enemigo_sig		;6397
	call enemigo_le_toca_disparar		;6399   ; le toca?
	jr nz,enemigo_sig		;639c
	call a_la_altura_del_agente		;639e   ; a su altura?
	jr nz,enemigo_sig		;63a1
	call mira_al_agente		;63a3   ; mirando al agente
	call bala_choca		;63a6   ; bala libre?
	jr nz,enemigo_sig		;63a9
	ld a,001h		;63ab   ; los dibujos de disparar
	call dibujos_enemigo		;63ad
	set 4,(ix+000h)		;63b0   ; bit 4: la bala sale al paso siguiente
	pop bc			;63b4
	push bc			;63b5
	ld a,016h		;63b6
	add a,b			;63b8
	dec a			;63b9
	ld b,028h		;63ba   ; 40 cuadros
	call pon_temporizador		;63bc
enemigo_sig:
	pop bc			;63bf
	ld de,0000ah		;63c0
	add ix,de		;63c3
	dec b			;63c5
	jp nz,enemigo_uno		;63c6
	xor a			;63c9
	ld (0c399h),a		;63ca   ; el agente ya no se ha movido
	ret			;63cd
puerta_animada:		; Pinta la puerta de IX (+7/+8) abriendose o cerrandose segun el cuadro (+4)
	push iy		;63ce
	push hl			;63d0
	push de			;63d1
	ld a,(ix+004h)		;63d2
	cp 004h		;63d5   ; en el cuadro 4 no se mueve
	jr z,puerta_animada_dibujo		;63d7
	push af			;63d9
	bit 7,(ix+000h)		;63da
	jr nz,puerta_animada_izq		;63de
	ld a,004h		;63e0   ; 4 hacia donde mira
	jr puerta_animada_x		;63e2
puerta_animada_izq:
	ld a,0fch		;63e4
puerta_animada_x:
	add a,(ix+001h)		;63e6
	ld (ix+001h),a		;63e9
	pop af			;63ec
puerta_animada_dibujo:
	ld l,(ix+007h)		;63ed
	ld h,(ix+008h)		;63f0
	set 4,(hl)		;63f3   ; la puerta en movimiento
	push hl			;63f5
	pop iy		;63f6
	cp 002h		;63f8   ; 2 y 5: medio abierta
	jr z,puerta_medio		;63fa
	cp 005h		;63fc
	jr z,puerta_medio		;63fe
	cp 001h		;6400   ; 1 y 4: abierta
	jr z,puerta_abierta		;6402
	cp 004h		;6404
	jr z,puerta_abierta		;6406
	res 4,(hl)		;6408   ; 3 y 6: cerrada
	bit 7,(hl)		;640a   ; mira a la izquierda?
	jr nz,puerta_cerrada_izq		;640c
	ld hl,069cbh		;640e   ; cerrada
	cp 006h		;6411
	jr z,puerta_pinta		;6413
	bit 5,(iy+000h)		;6415   ; bit 5: puerta sin dibujo (tiles 0)
	jr z,puerta_pinta		;6419
	ld hl,069dbh		;641b
	jr puerta_pinta		;641e
puerta_cerrada_izq:
	ld hl,069bbh		;6420   ; cerrada, a la izquierda
	cp 006h		;6423   ; el cuadro 6?
	jr z,puerta_pinta		;6425
	bit 5,(iy+000h)		;6427   ; bit 5: sin dibujo?
	jr z,puerta_pinta		;642b
	ld hl,069dbh		;642d   ; tiles 0
	jr puerta_pinta		;6430
puerta_medio:
	bit 7,(hl)		;6432
	jr nz,puerta_medio_izq		;6434
	ld hl,069abh		;6436
	jr puerta_pinta		;6439
puerta_medio_izq:
	ld hl,0699bh		;643b
	jr puerta_pinta		;643e
puerta_abierta:
	bit 7,(hl)		;6440
	jr nz,puerta_abierta_izq		;6442
	ld hl,0698bh		;6444
	jr puerta_pinta		;6447
puerta_abierta_izq:
	ld hl,0697bh		;6449
puerta_pinta:
	cp 003h		;644c
	jr z,puerta_pinta_ya		;644e
	bit 6,(iy+000h)		;6450   ; bit 6, roja: los dibujos rojos, 8 bytes mas alla
	jr z,puerta_pinta_ya		;6454
	ld de,00008h		;6456
	add hl,de			;6459
puerta_pinta_ya:
	ld a,(iy+002h)		;645a   ; su fila
	push ix		;645d
	push iy		;645f
	pop ix		;6461
	call sitio_en_mapa		;6463   ; en el mapa
	call pon_tira		;6466   ; la pinta
	pop ix		;6469
	push af			;646b
	bit 6,(iy+000h)		;646c   ; roja...
	jr z,puerta_animada_fin		;6470
	ld a,(ix+004h)		;6472   ; ...y abierta del todo...
	cp 003h		;6475
	jr nz,puerta_animada_fin		;6477
	bit 7,(ix+000h)		;6479
	jr z,puerta_borde_der		;647d
	dec de			;647f
	jr puerta_borde		;6480
puerta_borde_der:
	inc de			;6482
	inc de			;6483
puerta_borde:
	ld a,060h		;6484   ; ...la marca de su lado se borra (suelo 0x60)
	ld (de),a			;6486
puerta_animada_fin:
	pop af			;6487
	ld hl,0c0d0h		;6488   ; volcar
	set 7,(hl)		;648b
	pop de			;648d
	pop hl			;648e
	pop iy		;648f
	ret			;6491
puertas_repinta:		; Repinta cerradas las 58 puertas que se quedaron a medias
	ld ix,0c16eh		;6492   ; las 58 puertas
	ld b,03ah		;6496
puerta_repinta:
	push bc			;6498
	bit 4,(ix+000h)		;6499   ; a medias?
	jr z,puerta_repinta_sig		;649d
	res 4,(ix+000h)		;649f
	bit 7,(ix+000h)		;64a3   ; mira a la izquierda?
	jr nz,puerta_repinta_izq		;64a7
	ld hl,069cbh		;64a9   ; azul
	bit 5,(ix+000h)		;64ac   ; bit 5: sin dibujo
	jr z,puerta_repinta_roja		;64b0
	ld hl,069dbh		;64b2
	jr puerta_repinta_roja		;64b5
puerta_repinta_izq:
	ld hl,069bbh		;64b7
	bit 5,(ix+000h)		;64ba
	jr z,puerta_repinta_roja		;64be
	ld hl,069dbh		;64c0
puerta_repinta_roja:
	bit 6,(ix+000h)		;64c3
	jr z,puerta_repinta_ya		;64c7
	ld de,00008h		;64c9
	add hl,de			;64cc
puerta_repinta_ya:
	ld a,(ix+002h)		;64cd
	call sitio_en_mapa		;64d0
	call pon_tira		;64d3
puerta_repinta_sig:
	pop bc			;64d6   ; la cuenta
	ld de,00005h		;64d7   ; 5 bytes
	add ix,de		;64da   ; la siguiente
	djnz puerta_repinta		;64dc   ; las 58
	ld hl,0c0d0h		;64de
	set 7,(hl)		;64e1   ; volcar
	ret			;64e3
enemigo_decide:		; Cada cierto tiempo cambia de postura al azar segun la ronda (tabla 0x6539)
	push hl			;64e4
	push de			;64e5
	push bc			;64e6
	ld a,(0c39fh)		;64e7   ; hora punta?
	and a			;64ea
	jr z,enemigo_decide_ronda		;64eb
	ld a,006h		;64ed   ; como la ronda 6
	jr enemigo_decide_tabla		;64ef
enemigo_decide_ronda:
	ld a,(0c081h)		;64f1
enemigo_decide_tabla:
	ld hl,06539h		;64f4
enemigo_decide_busca:
	cp (hl)			;64f7   ; la fila de su ronda
	jr c,enemigo_decide_azar		;64f8
	ld de,00005h		;64fa
	add hl,de			;64fd
	jr enemigo_decide_busca		;64fe
enemigo_decide_azar:
	inc hl			;6500
	ld c,001h		;6501
	ld a,050h		;6503   ; de 1 a 80...
	call azar		;6505
	cp 00bh		;6508   ; ...solo por debajo de 11 cambia
	jr nc,enemigo_decide_abajo		;650a
enemigo_decide_postura:
	cp (hl)			;650c   ; los umbrales: de pie, andando, agachado, saltando
	jr c,enemigo_decide_pon		;650d
	inc hl			;650f
	sla c		;6510
	jr enemigo_decide_postura		;6512
enemigo_decide_pon:
	ld (ix+003h),c		;6514
	ld (ix+004h),001h		;6517
enemigo_decide_abajo:
	ld a,001h		;651b
	bit 1,(ix+003h)		;651d   ; andando...
	jr z,enemigo_decide_fin		;6521
	ld a,(0c0d3h)		;6523   ; ...por debajo de la fila 0x8A...
	cp 08ah		;6526
	ld a,000h		;6528
	jr c,enemigo_decide_fin		;652a
	ld (ix+003h),001h		;652c   ; ...se queda de pie
	ld (ix+004h),001h		;6530
enemigo_decide_fin:
	and a			;6534
	pop bc			;6535
	pop de			;6536
	pop hl			;6537
	ret			;6538

; ----------------------------------------------------------------------
; DATOS enemigo_posturas: Por ronda (1-5, y la 6 en adelante): umbrales de las
;   cuatro posturas al azar
;   0x6539..0x6557  (30 bytes)
DATA_enemigo_posturas:
	defb 002h,004h,008h,00ah,0ffh,003h,003h,007h,00ah,0ffh,004h,002h,006h,009h,0ffh,005h	; 6539  ................
	defb 001h,005h,009h,0ffh,006h,000h,004h,008h,0ffh,0ffh,000h,002h,005h,0ffh	; 6549  ..............

; ======================================================================
; CODIGO 0x6557..0x6572  (27 bytes)
; ======================================================================


enemigo_le_toca_disparar:		; Z si dispara: probabilidad de 20 segun la ronda (tabla 0x6572)
	push hl			;6557
	ld a,(0c081h)		;6558
	ld hl,06572h		;655b
enemigo_le_toca_busca:
	cp (hl)			;655e
	jr c,enemigo_le_toca_azar		;655f
	inc hl			;6561
	inc hl			;6562
	jr enemigo_le_toca_busca		;6563
enemigo_le_toca_azar:
	inc hl			;6565
	ld a,014h		;6566   ; de 1 a 20
	call azar		;6568
	cp (hl)			;656b   ; por debajo del umbral?
	jr nc,enemigo_le_toca_fin		;656c
	sub a			;656e   ; Z: dispara
enemigo_le_toca_fin:
	and a			;656f
	pop hl			;6570
	ret			;6571

; ----------------------------------------------------------------------
; DATOS enemigo_disparos: Rondas 1-2: 2 de 20; 3-4: 4 de 20; de la 5: 6 de 20
;   0x6572..0x6578  (6 bytes)
DATA_enemigo_disparos:
	defb 003h,002h,005h,004h,0ffh,006h	; 6572

; ======================================================================
; CODIGO 0x6578..0x65d5  (93 bytes)
; ======================================================================


da_la_vuelta:		; Cambia el lado al que mira IX y le mueve 4 hacia alli
	bit 7,(ix+000h)		;6578
	jr nz,da_la_vuelta_der		;657c
	set 7,(ix+000h)		;657e
	ld a,0fch		;6582
	jr da_la_vuelta_x		;6584
da_la_vuelta_der:
	res 7,(ix+000h)		;6586
	ld a,004h		;658a
da_la_vuelta_x:
	ld b,a			;658c
	add a,(ix+001h)		;658d
	ld (ix+001h),a		;6590
	ret			;6593
a_la_altura_del_agente:		; Z si la Y de IX cae en los 32 pixeles por encima de los pies del agente
	ld a,(0c0dah)		;6594
	add a,010h		;6597   ; los pies del agente
	cp (ix+002h)		;6599
	jr c,a_la_altura_no		;659c
	sub (ix+002h)		;659e
	cp 020h		;65a1
	jr nc,a_la_altura_no		;65a3
	sub a			;65a5
	jr a_la_altura_fin		;65a6
a_la_altura_no:
	ld a,001h		;65a8
a_la_altura_fin:
	and a			;65aa
	ret			;65ab
mira_al_agente:		; Gira a IX hacia el agente
	ld a,(0c0d9h)		;65ac   ; la X del agente
	cp (ix+001h)		;65af
	jr c,mira_al_agente_izq		;65b2
	bit 7,(ix+000h)		;65b4
	jr z,mira_al_agente_fin		;65b8
	ld a,004h		;65ba
	res 7,(ix+000h)		;65bc
	jr mira_al_agente_x		;65c0
mira_al_agente_izq:
	bit 7,(ix+000h)		;65c2
	jr nz,mira_al_agente_fin		;65c6
	ld a,0fch		;65c8
	set 7,(ix+000h)		;65ca
mira_al_agente_x:
	add a,(ix+001h)		;65ce
	ld (ix+001h),a		;65d1
mira_al_agente_fin:
	ret			;65d4

; ----------------------------------------------------------------------
; DATOS sin_uso_puerta_cerca: CODIGO SIN USO (69 bytes): mira si la puerta IY
;   queda a la izquierda o a la derecha de IX en su planta. Ningun call ni jp
;   lleva a 0x65D5 y en el cartucho no hay saltos indirectos
;   0x65d5..0x661a  (69 bytes)
DATA_sin_uso_puerta_cerca:
	defb 0c5h,0d5h,0cdh,083h,055h,03dh,03dh,03dh,0fdh,0beh,002h,020h,032h,0cdh,06fh,055h	; 65d5  ....U===... 2.oU
	defb 0ddh,0cbh,000h,07eh,020h,013h,0fdh,0cbh,000h,07eh,020h,004h,0c6h,0fdh,018h,002h	; 65e5  ...~ ....~ .....
	defb 0c6h,000h,0fdh,0beh,001h,038h,015h,018h,016h,0fdh,0cbh,000h,07eh,020h,004h,0c6h	; 65f5  .....8......~ ..
	defb 0ffh,018h,002h,0c6h,002h,0fdh,0beh,001h,030h,002h,018h,003h,097h,018h,002h,03eh	; 6605  ........0......>
	defb 001h,0a7h,0d1h,0c1h,0c9h	; 6615

; ======================================================================
; CODIGO 0x661a..0x682a  (528 bytes)
; ======================================================================


delante_de_la_puerta:		; Z si el tile de los pies de IX es el de delante de la puerta IY
	push hl			;661a
	push de			;661b
	call tile_de_los_pies		;661c
	ld de,(0c0d1h)		;661f   ; en el mapa
	add hl,de			;6623
	ld a,(iy+003h)		;6624   ; el byte bajo...
	cp l			;6627
	jr nz,delante_no		;6628
	ld a,(iy+004h)		;662a   ; ...y el alto
	cp h			;662d
	jr nz,delante_no		;662e
	sub a			;6630
	jr delante_fin		;6631
delante_no:
	ld a,001h		;6633
delante_fin:
	and a			;6635
	pop de			;6636
	pop hl			;6637
	ret			;6638
dibujos_enemigo:		; Los dibujos del enemigo segun el lado: A=0 los normales, A=1 los de disparar
	push hl			;6639
	and a			;663a
	jr nz,dibujos_enemigo_disparo		;663b
	bit 7,(ix+000h)		;663d   ; mira a la izquierda?
	jr nz,dibujos_enemigo_izq		;6641
	ld hl,06894h		;6643
	jr dibujos_enemigo_pon		;6646
dibujos_enemigo_izq:
	ld hl,068a4h		;6648
	jr dibujos_enemigo_pon		;664b
dibujos_enemigo_disparo:
	bit 7,(ix+000h)		;664d
	jr nz,dibujos_enemigo_disparo_i		;6651
	ld hl,06884h		;6653
	jr dibujos_enemigo_pon		;6656
dibujos_enemigo_disparo_i:
	ld hl,0688ch		;6658
dibujos_enemigo_pon:
	ld (ix+005h),l		;665b
	ld (ix+006h),h		;665e
	pop hl			;6661
	ret			;6662
suelo_delante:		; Z si el tile de delante de los pies es suelo (0x60) o marca de puerta roja (0x78)
	call tile_de_los_pies		;6663   ; los pies
	call columna_delante		;6666   ; la columna de delante
	call tile_en		;6669   ; el tile
	cp 060h		;666c   ; suelo?
	ret z			;666e
	cp 078h		;666f   ; o la marca de puerta roja
	ret			;6671
enemigo_ascensor:		; El enemigo se sube a un ascensor (por dentro o al techo), salvo si lleva al agente o a otro
	push iy		;6672
	push hl			;6674
	push de			;6675
	push bc			;6676
	bit 6,(ix+000h)		;6677   ; muriendo
	jp nz,enemigo_ascensor_fin		;667b
	call tile_de_los_pies		;667e
	ld de,00020h		;6681
	and a			;6684
	sbc hl,de		;6685   ; la fila de los pies
	call tile_en		;6687
	cp 03bh		;668a   ; la cabina?
	jr z,enemigo_ascensor_dentro		;668c
	cp 02dh		;668e   ; el techo?
	jr nz,enemigo_baja_ascensor		;6690
	ld a,001h		;6692
	jr enemigo_ascensor_sube		;6694
enemigo_ascensor_dentro:
	ld a,002h		;6696
enemigo_ascensor_sube:
	bit 1,(ix+000h)		;6698   ; ya en uno
	jr nz,enemigo_ascensor_fin		;669c
	ld c,a			;669e
	call esquina_ascensor		;669f   ; la esquina...
	call busca_ascensor		;66a2   ; ...el ascensor
	jr nz,enemigo_ascensor_fin		;66a5
	bit 7,(hl)		;66a7   ; lleva al agente?
	jr nz,enemigo_ascensor_no		;66a9
	bit 3,(hl)		;66ab   ; ya lleva enemigo?
	jr nz,enemigo_ascensor_no		;66ad
	call a_la_altura_del_agente		;66af   ; el agente a su altura: no sube
	jr nz,enemigo_ascensor_si		;66b2
enemigo_ascensor_no:
	call da_la_vuelta		;66b4   ; se da la vuelta
	sub a			;66b7
	call dibujos_enemigo		;66b8
	call suelo_delante		;66bb
	jr nz,enemigo_ascensor_fin		;66be
	call un_paso		;66c0
	jr enemigo_ascensor_fin		;66c3
enemigo_ascensor_si:
	set 3,(hl)		;66c5   ; lleva enemigo
	ld a,(0c0dah)		;66c7   ; el agente mas abajo...
	cp (ix+002h)		;66ca
	jr nc,enemigo_ascensor_baja		;66cd
	set 0,(hl)		;66cf   ; ...el ascensor sube...
	jr enemigo_ascensor_apunta		;66d1
enemigo_ascensor_baja:
	res 0,(hl)		;66d3   ; ...o baja
enemigo_ascensor_apunta:
	push hl			;66d5
	pop iy		;66d6
	push ix		;66d8
	pop de			;66da
	ld (iy+007h),e		;66db   ; el ascensor sabe quien lleva
	ld (iy+008h),d		;66de
	ld (ix+007h),l		;66e1   ; y el enemigo en cual va
	ld (ix+008h),h		;66e4
	set 1,(ix+000h)		;66e7   ; bit 1: en un ascensor
	dec c			;66eb   ; encima?
	jr nz,enemigo_ascensor_fin		;66ec
	set 5,(ix+000h)		;66ee
	jr enemigo_ascensor_fin		;66f2
enemigo_baja_ascensor:
	bit 1,(ix+000h)		;66f4   ; en un ascensor?
	jr z,enemigo_ascensor_fin		;66f8
	res 1,(ix+000h)		;66fa   ; ya no
	res 5,(ix+000h)		;66fe   ; ni encima
	ld l,(ix+007h)		;6702   ; el ascensor...
	ld h,(ix+008h)		;6705
	res 3,(hl)		;6708   ; ...sin enemigo
enemigo_ascensor_fin:
	pop bc			;670a
	pop de			;670b
	pop hl			;670c
	pop iy		;670d
	ret			;670f
a_pixeles:		; De la posicion HL del mapa a pixeles: H = X, L = Y (fila + 2) x 8
	push bc			;6710
	push de			;6711
	ld de,00020h		;6712
	ld c,002h		;6715
	ld b,l			;6717
a_pixeles_fila:
	and a			;6718   ; una fila menos
	sbc hl,de		;6719
	jr c,a_pixeles_fin		;671b   ; ya
	inc c			;671d   ; fila + 1
	ld b,l			;671e   ; lo que queda es la columna
	jr a_pixeles_fila		;671f
a_pixeles_fin:
	sla c		;6721   ; fila x 8
	sla c		;6723
	sla c		;6725
	sla b		;6727   ; columna x 8
	sla b		;6729
	sla b		;672b
	push bc			;672d   ; a HL
	pop hl			;672e
	pop de			;672f
	pop bc			;6730
	ret			;6731   ; listo
puerta_libre:		; IY = la C-esima puerta azul entre 4 filas por encima y 9 por debajo de la vista; NZ si no hay
	ld c,a			;6732
	ld a,(0c0d3h)		;6733   ; la vista...
	ld b,a			;6736
	sub 004h		;6737   ; ...4 filas arriba...
	ld d,a			;6739
	ld a,b			;673a
	add a,009h		;673b   ; ...9 abajo
	ld e,a			;673d
	ld iy,0c16eh		;673e   ; las 58 puertas
	ld b,03ah		;6742
puerta_libre_mira:
	ld a,(iy+002h)		;6744   ; la fila de la puerta
	cp d			;6747   ; por encima?
	jr c,puerta_libre_sig		;6748
	cp e			;674a   ; por debajo?
	jr c,puerta_libre_azul		;674b
	jr puerta_libre_sig		;674d
puerta_libre_azul:
	bit 6,(iy+000h)		;674f   ; roja: no
	jr nz,puerta_libre_sig		;6753
	dec c			;6755
	jr z,puerta_libre_fin		;6756
puerta_libre_sig:
	push de			;6758   ; se guarda
	ld de,00005h		;6759   ; 5 bytes
	add iy,de		;675c   ; la siguiente
	pop de			;675e
	djnz puerta_libre_mira		;675f   ; las 58
	ld a,001h		;6761   ; NZ: ninguna
	and a			;6763
puerta_libre_fin:
	ret			;6764
puertas_nuevas:		; Las 58 puertas de la tabla 0x69EB y las rojas de la ronda, al azar
	ld hl,069ebh		;6765   ; la tabla
	ld ix,0c16eh		;6768
	ld b,03ah		;676c
puerta_nueva:
	ld a,(hl)			;676e   ; 0xFF: acabada
	cp 0ffh		;676f
	jr z,puertas_rojas		;6771
	push bc			;6773
	push ix		;6774
	pop de			;6776
	ld bc,00003h		;6777   ; bits, columna y fila
	ldir		;677a
	push hl			;677c
	ld a,(ix+002h)		;677d   ; el tile de delante: 3 filas mas abajo...
	add a,003h		;6780
	call fila_por_32		;6782
	ld e,(ix+001h)		;6785
	ld d,000h		;6788
	add hl,de			;678a
	bit 7,(ix+000h)		;678b   ; ...y al lado que mira
	jr nz,puerta_nueva_izq		;678f
	inc hl			;6791
	inc hl			;6792
	jr puerta_nueva_guarda		;6793
puerta_nueva_izq:
	dec hl			;6795
puerta_nueva_guarda:
	ex de,hl			;6796   ; el tile, en DE
	pop hl			;6797
	ld (ix+003h),e		;6798   ; guardado...
	ld (ix+004h),d		;679b   ; ...en +3/+4
	pop bc			;679e
	ld de,00005h		;679f   ; 5 bytes
	add ix,de		;67a2   ; la siguiente
	djnz puerta_nueva		;67a4   ; hasta 58
puertas_rojas:		; Por ronda (hasta la 9) cuantas rojas salen de cada uno de los tres grupos de puertas
	ld a,(0c081h)		;67a6   ; la ronda...
	ld hl,0682ah		;67a9
	cp 00ah		;67ac   ; ...la 9 vale para las demas
	jr c,puertas_rojas_ronda		;67ae
	ld a,009h		;67b0
puertas_rojas_ronda:
	dec a			;67b2   ; 3 bytes por ronda
	ld c,a			;67b3
	add a,a			;67b4
	add a,c			;67b5
	ld c,a			;67b6
	ld b,000h		;67b7
	add hl,bc			;67b9
	ld b,003h		;67ba
puertas_rojas_grupo:
	push bc			;67bc
	push hl			;67bd
	ld a,(hl)			;67be   ; ninguna en este grupo
	and a			;67bf
	jr z,puertas_rojas_sig		;67c0
	ld a,003h		;67c2
	sub b			;67c4
	ld b,(hl)			;67c5
	add a,a			;67c6
	ld e,a			;67c7
	ld d,000h		;67c8
	ld hl,06845h		;67ca   ; la lista del grupo
	add hl,de			;67cd
	ld a,(hl)			;67ce
	inc hl			;67cf
	ld h,(hl)			;67d0
	ld l,a			;67d1
	ld a,(hl)			;67d2   ; cuantas puertas tiene
	inc hl			;67d3
puertas_rojas_una:
	push bc			;67d4
	push hl			;67d5
	push af			;67d6
	call azar		;67d7   ; una al azar...
	dec a			;67da
	ld c,a			;67db
	ld b,000h		;67dc
	add hl,bc			;67de
	ex de,hl			;67df
	ld a,(de)			;67e0
	call ficha_de_puerta		;67e1   ; ...su ficha...
	call pinta_roja		;67e4   ; ...roja
	pop af			;67e7
	pop hl			;67e8
	ld c,a			;67e9
	ld b,000h		;67ea
	add hl,bc			;67ec
	pop bc			;67ed
	djnz puertas_rojas_una		;67ee
puertas_rojas_sig:
	pop hl			;67f0
	pop bc			;67f1
	inc hl			;67f2
	djnz puertas_rojas_grupo		;67f3
	ret			;67f5
ficha_de_puerta:		; HL = la puerta numero A (desde 1)
	ld hl,0c16eh		;67f6
	ld de,00005h		;67f9
ficha_de_puerta_sig:
	dec a			;67fc
	jr z,ficha_de_puerta_fin		;67fd
	add hl,de			;67ff
	jr ficha_de_puerta_sig		;6800
ficha_de_puerta_fin:
	ret			;6802
pinta_roja:		; La puerta HL pasa a roja: bit 6, dibujo rojo y la marca 0x78 a su lado
	push hl			;6803
	pop ix		;6804
	set 6,(hl)		;6806   ; roja
	bit 7,(hl)		;6808   ; mira a la izquierda?
	push af			;680a
	jr nz,pinta_roja_izq		;680b
	ld hl,069d3h		;680d
	jr pinta_roja_ya		;6810
pinta_roja_izq:
	ld hl,069c3h		;6812
pinta_roja_ya:
	ld a,(ix+002h)		;6815   ; su fila
	call sitio_en_mapa		;6818   ; su sitio en el mapa
	call pon_tira		;681b   ; la puerta roja
	pop af			;681e
	jr nz,pinta_roja_marca_izq		;681f   ; a la izquierda?
	inc de			;6821   ; dos a la derecha
	inc de			;6822
	jr pinta_roja_marca		;6823
pinta_roja_marca_izq:
	dec de			;6825
pinta_roja_marca:
	ld a,078h		;6826
	ld (de),a			;6828
	ret			;6829

; ----------------------------------------------------------------------
; DATOS rojas_por_ronda: Rondas 1 a 9: cuantas puertas rojas salen de cada
;   grupo (3 bytes): 5, 6, 7, 8, 9 y 10 desde la 6
;   0x682a..0x6845  (27 bytes)
DATA_rojas_por_ronda:
	defb 000h,005h,000h,001h,004h,001h,001h,004h,002h,002h,004h,002h,002h,005h,002h,002h	; 682a  ................
	defb 006h,002h,002h,005h,003h,002h,004h,004h,002h,003h,005h	; 683a  ...........

; ----------------------------------------------------------------------
; DATOS rojas_grupos: Donde esta la lista de cada uno de los tres grupos
;   0x6845..0x684b  (6 bytes)
DATA_rojas_grupos:
	defb 04bh,068h,060h,068h,079h,068h	; 6845

; ----------------------------------------------------------------------
; DATOS rojas_listas: Cada lista: cuantas puertas y sus numeros
;   0x684b..0x6884  (57 bytes)
DATA_rojas_listas:
	defb 00ah,00bh,00ch,00dh,00eh,00fh,010h,011h,012h,013h,014h,001h,002h,003h,004h,005h	; 684b  ................
	defb 006h,007h,008h,009h,00ah,004h,015h,016h,017h,018h,021h,022h,023h,024h,025h,026h	; 685b  ..........!"#$%&
	defb 027h,028h,02bh,02ch,02dh,02eh,019h,01ah,01bh,01ch,01dh,01eh,01fh,020h,002h,037h	; 686b  '(+,-........ .7
	defb 038h,033h,034h,039h,03ah,035h,036h,031h,032h	; 687b  8349:5612

; ----------------------------------------------------------------------
; DATOS enemigo_dibujos_disparo: Dibujos del enemigo disparando, mirando a la
;   derecha y a la izquierda
;   0x6884..0x6894  (16 bytes)
DATA_enemigo_dibujos_disparo:
	defb 0dah,068h,0dch,068h,0e0h,068h,0bch,068h,000h,069h,002h,069h,006h,069h,0eah,068h	; 6884  .h.h.h.h.i.i.i.h

; ----------------------------------------------------------------------
; DATOS enemigo_dibujos: Dibujos del enemigo por postura, a la derecha y a la
;   izquierda
;   0x6894..0x68b4  (32 bytes)
DATA_enemigo_dibujos:
	defb 0b4h,068h,0b6h,068h,0bah,068h,0bch,068h,0beh,068h,0cah,068h,0d2h,068h,0d2h,068h	; 6894  .h.h.h.h.h.h.h.h
	defb 0e2h,068h,0e4h,068h,0e8h,068h,0eah,068h,0ech,068h,0cah,068h,0f8h,068h,0f8h,068h	; 68a4  .h.h.h.h.h.h.h.h

; ----------------------------------------------------------------------
; DATOS enemigo_cuadros: Los cuadros del enemigo: dibujo, color y
;   desplazamiento de la Y; 0xFF acaba
;   0x68b4..0x697b  (199 bytes)
DATA_enemigo_cuadros:
	defb 008h,069h,008h,069h,00fh,069h,024h,069h,02ch,069h,07ah,069h,00fh,069h,008h,069h	; 68b4  .i.i.i$i,izi.i.i
	defb 008h,069h,00fh,069h,07ah,069h,072h,069h,076h,069h,06eh,069h,07ah,069h,030h,069h	; 68c4  .i.izirivinizi0i
	defb 037h,069h,06eh,069h,07ah,069h,016h,069h,016h,069h,01dh,069h,028h,069h,03bh,069h	; 68d4  7inizi.i.i.i(i;i
	defb 03bh,069h,042h,069h,057h,069h,05fh,069h,07ah,069h,042h,069h,03bh,069h,03bh,069h	; 68e4  ;iBiWi_iziBi;i;i
	defb 042h,069h,07ah,069h,063h,069h,06ah,069h,06eh,069h,07ah,069h,049h,069h,049h,069h	; 68f4  BizicijiniziIiIi
	defb 050h,069h,05bh,069h,058h,004h,0e8h,05ch,004h,0f8h,0ffh,060h,004h,0e8h,064h,004h	; 6904  Pi[iX..\...`..d.
	defb 0f8h,0ffh,068h,004h,0e8h,05ch,004h,0f8h,0ffh,06ch,004h,0e8h,064h,004h,0f8h,0ffh	; 6914  ..h..\...l..d...
	defb 070h,004h,0f0h,0ffh,074h,004h,0f0h,0ffh,084h,004h,0f0h,0ffh,078h,004h,0e8h,07ch	; 6924  p...t.......x..|
	defb 004h,0f8h,0ffh,080h,004h,0f0h,0ffh,090h,004h,0e8h,094h,004h,0f8h,0ffh,098h,004h	; 6934  ................
	defb 0e8h,09ch,004h,0f8h,0ffh,0a0h,004h,0e8h,094h,004h,0f8h,0ffh,0a4h,004h,0e8h,09ch	; 6944  ................
	defb 004h,0f8h,0ffh,0a8h,004h,0f0h,0ffh,0ach,004h,0f0h,0ffh,0bch,004h,0f0h,0ffh,0b0h	; 6954  ................
	defb 004h,0e8h,0b4h,004h,0f8h,0ffh,0b8h,004h,0f0h,0ffh,0e4h,00bh,0f0h,0ffh,0f8h,004h	; 6964  ................
	defb 0efh,0ffh,0fch,004h,0efh,0ffh,0ffh	; 6974

; ----------------------------------------------------------------------
; DATOS puerta_dibujos: Puertas de 2 x 3 tiles: abiertas, medio y cerradas
;   (izquierda/derecha), en azul y en rojo; las de tiles 0
;   0x697b..0x69eb  (112 bytes)
DATA_puerta_dibujos:
	defb 002h,01bh,024h,01ch,01ah,01dh,01ah,0ffh,002h,083h,08ch,084h,080h,085h,080h,0ffh	; 697b  ..$.............
	defb 002h,024h,025h,01ah,026h,01ah,027h,0ffh,002h,08ch,08dh,080h,08eh,080h,08fh,0ffh	; 698b  .$%.&.'.........
	defb 002h,000h,01eh,000h,01fh,000h,020h,0ffh,002h,000h,086h,000h,087h,000h,088h,0ffh	; 699b  ...... .........
	defb 002h,021h,000h,022h,000h,023h,000h,0ffh,002h,089h,000h,08ah,000h,08bh,000h,0ffh	; 69ab  .!.".#..........
	defb 002h,090h,090h,091h,090h,090h,090h,0ffh,002h,080h,080h,081h,080h,080h,080h,0ffh	; 69bb  ................
	defb 002h,090h,090h,090h,092h,090h,090h,0ffh,002h,080h,080h,080h,082h,080h,080h,0ffh	; 69cb  ................
	defb 002h,000h,000h,000h,000h,000h,000h,0ffh,002h,000h,000h,000h,000h,000h,000h,0ffh	; 69db  ................

; ----------------------------------------------------------------------
; DATOS puertas_tabla: Las 58 puertas: bits, columna y fila; 0xFF acaba
;   0x69eb..0x6a9a  (175 bytes)
DATA_puertas_tabla:
	defb 080h,007h,008h,000h,016h,008h,080h,00ah,00eh,000h,016h,00eh,080h,007h,014h,000h	; 69eb  ................
	defb 013h,014h,080h,00ah,01ah,000h,016h,01ah,080h,007h,020h,000h,013h,020h,080h,00ah	; 69fb  .......... .. ..
	defb 026h,000h,016h,026h,080h,007h,02ch,000h,013h,02ch,080h,00ah,032h,000h,016h,032h	; 6a0b  &..&..,..,..2..2
	defb 080h,007h,038h,000h,013h,038h,080h,00ah,03eh,000h,016h,03eh,080h,007h,044h,000h	; 6a1b  ..8..8..>..>..D.
	defb 016h,044h,080h,00ah,04ah,000h,013h,04ah,080h,00ah,050h,000h,013h,050h,080h,00ah	; 6a2b  .D..J..J..P..P..
	defb 056h,000h,013h,056h,080h,00ah,05ch,000h,013h,05ch,0a0h,00ah,062h,020h,019h,062h	; 6a3b  V..V..\..\..b .b
	defb 0a0h,00dh,068h,020h,016h,068h,0a0h,00ah,06eh,020h,016h,06eh,0a0h,007h,074h,020h	; 6a4b  ..h .h..n .n..t 
	defb 016h,074h,0a0h,00ah,07ah,020h,013h,07ah,080h,007h,080h,000h,016h,080h,080h,007h	; 6a5b  .t..z .z........
	defb 086h,000h,016h,086h,080h,00ah,08ch,000h,013h,08ch,080h,002h,098h,000h,01bh,098h	; 6a6b  ................
	defb 080h,002h,09eh,000h,01bh,09eh,080h,002h,0a4h,000h,01bh,0a4h,080h,002h,0aah,000h	; 6a7b  ................
	defb 01bh,0aah,080h,002h,0b0h,000h,01bh,0b0h,080h,002h,0b6h,000h,01bh,0b6h,0ffh	; 6a8b  ...............

; ======================================================================
; CODIGO 0x6a9a..0x6ea5  (1035 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  La lampara que cae y la patada  =====
; ----------------------------------------------------------------------
golpes_al_enemigo:		; La lampara que cae mata a quien pilla debajo; la patada en el salto, al enemigo de al lado
	ld iy,0c0d8h		;6a9a   ; el agente
	ld ix,0c2e0h		;6a9e   ; los 4 enemigos
	ld b,004h		;6aa2
	ld a,(iy+000h)		;6aa4   ; en juego...
	bit 0,a		;6aa7
	jp z,golpes_fin		;6aa9
	bit 6,a		;6aac   ; ...y vivo
	jp nz,golpes_fin		;6aae
golpe_enemigo:
	push bc			;6ab1
	ex af,af'			;6ab2
	exx			;6ab3
	ld hl,0c39bh		;6ab4   ; cae una lampara?
	ld a,(hl)			;6ab7
	or a			;6ab8
	jr z,golpe_patada		;6ab9
	inc hl			;6abb   ; de que lado?
	ld a,(hl)			;6abc
	or a			;6abd
	ld a,(ix+001h)		;6abe
	jr nz,golpe_lampara_der		;6ac1
	cp 044h		;6ac3   ; izquierda: X 0x44 o 0x48
	jr z,golpe_lampara		;6ac5
	cp 048h		;6ac7
	jr z,golpe_lampara		;6ac9
	jr golpe_patada		;6acb
golpe_lampara_der:
	cp 0a0h		;6acd   ; derecha: X 0xA0 o 0xA4
	jr z,golpe_lampara		;6acf
	cp 0a4h		;6ad1
	jr z,golpe_lampara		;6ad3
	jr golpe_patada		;6ad5
golpe_lampara:		; La lampara (sprite 25) a menos de 16 pixeles por encima de la cabeza
	ld a,(0c064h)		;6ad7   ; la Y de la lampara...
	add a,018h		;6ada   ; ...mas 24
	ld b,a			;6adc
	ld a,(ix+002h)		;6add
	sub b			;6ae0
	jr c,golpe_patada		;6ae1
	cp 010h		;6ae3
	jr nc,golpe_patada		;6ae5
	bit 0,(ix+000h)		;6ae7   ; en juego
	jr z,golpe_patada		;6aeb
	bit 6,(ix+000h)		;6aed   ; vivo
	jr nz,golpe_patada		;6af1
	bit 4,(ix+003h)		;6af3   ; fuera de su puerta
	jr nz,golpe_patada		;6af7
	exx			;6af9
	ex af,af'			;6afa
	set 6,(ix+000h)		;6afb   ; muriendo...
	ld (ix+004h),001h		;6aff
	ld (ix+003h),080h		;6b03   ; ...postura 0x80
	sub a			;6b07
	call dibujos_enemigo		;6b08
	pop bc			;6b0b
	push bc			;6b0c
	ld a,016h		;6b0d   ; 30 cuadros
	add a,b			;6b0f
	dec a			;6b10
	ld b,01eh		;6b11
	call pon_temporizador		;6b13
	ld hl,07119h		;6b16   ; 300 puntos
	jr golpe_puntos		;6b19
golpe_patada:		; El agente saltando toca al enemigo: 150 (200 a oscuras o con la vista entre las filas 0x5E y 0x7A)
	exx			;6b1b
	ex af,af'			;6b1c
	bit 4,(iy+000h)		;6b1d   ; el agente salta?
	jr z,golpe_sig		;6b21
	ld a,(ix+000h)		;6b23
	bit 0,a		;6b26
	jr z,golpe_sig		;6b28
	bit 6,a		;6b2a   ; vivo
	jr nz,golpe_sig		;6b2c
	bit 4,(ix+003h)		;6b2e   ; fuera de su puerta
	jr nz,golpe_sig		;6b32
	bit 2,a		;6b34   ; ni en la escalera
	jr nz,golpe_sig		;6b36
	ld a,(ix+002h)		;6b38   ; menos de 17 de alto...
	sub (iy+002h)		;6b3b
	cp 011h		;6b3e
	jr nc,golpe_sig		;6b40
	ld a,(iy+001h)		;6b42   ; ...y de 8 a cada lado
	sub (ix+001h)		;6b45
	cp 009h		;6b48
	jr c,golpe_patada_da		;6b4a
	cp 0f9h		;6b4c
	jr c,golpe_sig		;6b4e
golpe_patada_da:
	set 6,(ix+000h)		;6b50
	ld (ix+004h),001h		;6b54
	ld (ix+003h),080h		;6b58   ; postura 0x80
	sub a			;6b5c
	call dibujos_enemigo		;6b5d
	pop bc			;6b60
	push bc			;6b61
	ld a,016h		;6b62
	add a,b			;6b64
	dec a			;6b65
	ld b,01eh		;6b66
	call pon_temporizador		;6b68
	ld hl,07111h		;6b6b   ; 150 puntos
	ld a,(0c385h)		;6b6e   ; a oscuras?
	and a			;6b71
	jr nz,golpe_patada_200		;6b72
	ld a,(0c0d3h)		;6b74   ; o con la vista en esas filas
	cp 05eh		;6b77
	jr c,golpe_puntos		;6b79
	cp 07bh		;6b7b
	jr nc,golpe_puntos		;6b7d
golpe_patada_200:
	ld hl,07115h		;6b7f   ; 200
golpe_puntos:
	call suma_puntos		;6b82
	ld a,003h		;6b85   ; el sonido del golpe
	call sonido		;6b87
golpe_sig:
	pop bc			;6b8a
	ld de,0000ah		;6b8b
	add ix,de		;6b8e
	dec b			;6b90
	jp nz,golpe_enemigo		;6b91
golpes_fin:
	ret			;6b94

; ----------------------------------------------------------------------
; =====  Las balas  =====
; ----------------------------------------------------------------------
dispara:		; Una bala de IX: A=0 del agente (3, temporizadores 0x0E-0x10), A=1 de enemigo (4, 0x11-0x14)
	push iy		;6b95
	push hl			;6b97
	push de			;6b98
	push bc			;6b99
	push af			;6b9a
	and a			;6b9b
	jr nz,dispara_enemigo		;6b9c
	inc a			;6b9e   ; el agente ha disparado
	ld (0c3a2h),a		;6b9f
	ld iy,0c29ah		;6ba2   ; las del agente
	ld b,003h		;6ba6
	ld c,00eh		;6ba8
	jr dispara_busca		;6baa
dispara_enemigo:
	ld iy,0c2b8h		;6bac   ; las de los enemigos
	ld b,004h		;6bb0
	ld c,011h		;6bb2
dispara_busca:
	bit 0,(iy+000h)		;6bb4   ; libre?
	jr z,dispara_sale		;6bb8
	ld de,0000ah		;6bba
	add iy,de		;6bbd
	djnz dispara_busca		;6bbf
	pop af			;6bc1   ; ninguna libre
	and a			;6bc2
	jr nz,dispara_fin		;6bc3
	ld (0c3a2h),a		;6bc5   ; no ha disparado
	jr dispara_fin		;6bc8
dispara_sale:
	ld a,c			;6bca
	dec a			;6bcb
	add a,b			;6bcc
	ld b,002h		;6bcd   ; un paso cada 2 cuadros
	call pon_temporizador		;6bcf
	push ix		;6bd2   ; bits, X, Y y postura del que dispara
	pop hl			;6bd4
	push iy		;6bd5
	pop de			;6bd7
	ld bc,00004h		;6bd8
	ldir		;6bdb
	ld (iy+004h),001h		;6bdd   ; cuadro 1
	bit 7,(iy+000h)		;6be1   ; hacia la izquierda?
	jr z,dispara_der		;6be5
	ld hl,06ebeh		;6be7
	jr dispara_dibujo		;6bea
dispara_der:
	ld hl,06eb6h		;6bec
dispara_dibujo:
	ld (iy+005h),l		;6bef
	ld (iy+006h),h		;6bf2
	pop af			;6bf5
	push af			;6bf6
	call bala_altura		;6bf7   ; a la altura de la pistola
	pop af			;6bfa
	ld b,005h		;6bfb   ; el sonido: 5 el agente...
	and a			;6bfd
	jr z,dispara_sonido		;6bfe
	ld b,001h		;6c00   ; ...1 un enemigo
dispara_sonido:
	ld a,b			;6c02
	call sonido		;6c03
dispara_fin:
	pop bc			;6c06
	pop de			;6c07
	pop hl			;6c08
	pop iy		;6c09
	ret			;6c0b
bala_choca:		; NZ si delante de IX hay pared o puerta; la lampara (0x77) se rompe de un tiro
	push hl			;6c0c
	push de			;6c0d
	call tile_de_los_pies		;6c0e
	call columna_delante		;6c11
	ld de,00020h		;6c14   ; una fila arriba
	and a			;6c17
	sbc hl,de		;6c18
	push hl			;6c1a
	call tile_en		;6c1b
	pop hl			;6c1e
	cp 077h		;6c1f   ; la lampara?
	jr z,lampara_tiro		;6c21
bala_choca_mira:
	cp 02ah		;6c23   ; paredes, tejado y suelo
	jr z,bala_para		;6c25
	cp 00fh		;6c27
	jr z,bala_para		;6c29
	cp 00eh		;6c2b
	jr z,bala_para		;6c2d
	cp 061h		;6c2f
	jr z,bala_para		;6c31
	cp 064h		;6c33
	jr z,bala_para		;6c35
	cp 067h		;6c37
	jr z,bala_para		;6c39
	cp 060h		;6c3b
	jr z,bala_para		;6c3d
	cp 01ah		;6c3f   ; 0x1A a 0x27
	jr c,L_6C47		;6c41
	cp 028h		;6c43
	jr c,bala_para		;6c45
L_6C47:
	cp 009h		;6c47
	jr z,bala_para		;6c49
	cp 00ah		;6c4b
	jr z,bala_para		;6c4d
	cp 0bbh		;6c4f   ; de 0xBB en adelante: nada
	jr nc,bala_libre		;6c51
	cp 0b0h		;6c53   ; 0xB0 a 0xBA: los numeros de planta
	jr nc,bala_para		;6c55
	cp 090h		;6c57   ; 0x90 a 0xAF: nada
	jr nc,bala_libre		;6c59
	cp 083h		;6c5b   ; 0x83 a 0x8F: puertas rojas
	jr nc,bala_para		;6c5d
	jr bala_libre		;6c5f
lampara_tiro:		; La primera bala que llega a una lampara la rompe: queda a oscuras y la lampara cae
	ld e,a			;6c61
	ld a,(0c385h)		;6c62   ; ya a oscuras?
	and a			;6c65
	ld d,a			;6c66
	ld a,e			;6c67
	jr nz,bala_choca_mira		;6c68
	ld a,001h		;6c6a   ; a oscuras
	ld (0c385h),a		;6c6c
	ld de,0c400h		;6c6f   ; en el mapa...
	push hl			;6c72
	ld hl,(0c0d1h)		;6c73
	add hl,de			;6c76
	ex de,hl			;6c77
	pop hl			;6c78
	add hl,de			;6c79
	ld (hl),0c0h		;6c7a   ; ...la lampara rota (0xC0)
	ld a,(ix+001h)		;6c7c   ; de que lado
	cp 080h		;6c7f
	ld d,000h		;6c81
	jr c,lampara_lado		;6c83
	inc d			;6c85
lampara_lado:
	ld a,d			;6c86
	ld (0c39ch),a		;6c87
	ld a,003h		;6c8a   ; la Y de la bala...
	sub b			;6c8c
	add a,a			;6c8d
	add a,a			;6c8e
	ld c,a			;6c8f
	ld b,000h		;6c90
	ld hl,0c02ch		;6c92
	add hl,bc			;6c95
	ld a,(hl)			;6c96
	ld (0c39dh),a		;6c97   ; ...es donde empieza a caer
	jr bala_para		;6c9a
bala_libre:
	sub a			;6c9c
	jr bala_choca_fin		;6c9d
bala_para:
	ld a,001h		;6c9f
bala_choca_fin:
	and a			;6ca1
	pop de			;6ca2
	pop hl			;6ca3
	ret			;6ca4
bala_altura:		; La bala sale a la altura de la pistola segun la postura (tablas 0x6EE3/0x6EEB) y 8 por delante
	ld hl,06ee3h		;6ca5   ; del agente
	and a			;6ca8
	jr z,bala_altura_postura		;6ca9
	ld hl,06eebh		;6cab   ; de un enemigo
bala_altura_postura:
	ld a,(iy+003h)		;6cae
bala_altura_busca:
	srl a		;6cb1
	jr c,bala_altura_pon		;6cb3
	inc hl			;6cb5
	inc hl			;6cb6
	jr bala_altura_busca		;6cb7
bala_altura_pon:
	ld a,(hl)			;6cb9   ; la tabla...
	inc hl			;6cba
	ld h,(hl)			;6cbb
	ld l,a			;6cbc
	ld a,(hl)			;6cbd   ; el desplazamiento
	ld (iy+009h),a		;6cbe   ; la guarda en +9
	add a,(iy+002h)		;6cc1   ; + la Y
	ld (iy+002h),a		;6cc4   ; guardada
	bit 7,(iy+000h)		;6cc7   ; hacia la izquierda?
	jr nz,bala_altura_izq		;6ccb
	ld a,008h		;6ccd   ; 8 a la derecha
	jr bala_altura_x		;6ccf
bala_altura_izq:
	ld a,0f8h		;6cd1
bala_altura_x:
	add a,(iy+001h)		;6cd3
	ld (iy+001h),a		;6cd6
	ret			;6cd9
balas_cuadro:		; Mueve las 3 balas del agente y las 4 de los enemigos
	ld ix,0c29ah		;6cda   ; las 3 del agente
	ld b,003h		;6cde   ; 3
	ld c,00eh		;6ce0   ; temporizadores 0x0E-0x10
	call bala_mueve		;6ce2   ; movidas
	ld ix,0c2b8h		;6ce5   ; las 4 enemigas
	ld b,004h		;6ce9   ; 4
	ld c,011h		;6ceb   ; temporizadores 0x11-0x14
	call bala_mueve		;6ced   ; movidas
	ret			;6cf0   ; listo
bala_mueve:
	push bc			;6cf1
	bit 0,(ix+000h)		;6cf2   ; en juego?
	jr z,bala_sig		;6cf6
	ld a,c			;6cf8   ; su temporizador
	add a,b			;6cf9
	dec a			;6cfa
	ld c,a			;6cfb
	call lee_temporizador		;6cfc
	jr nz,bala_sig		;6cff
	ld a,c			;6d01   ; cada 2 cuadros
	push bc			;6d02
	ld b,002h		;6d03
	call pon_temporizador		;6d05
	pop bc			;6d08
	ld a,(ix+004h)		;6d09   ; volando?
	cp 001h		;6d0c
	jr z,bala_avanza		;6d0e
	inc (ix+004h)		;6d10   ; chocada: un cuadro de choque...
	cp 002h		;6d13
	jr z,bala_sig		;6d15
	res 0,(ix+000h)		;6d17   ; ...y fuera
	jr bala_sig		;6d1b
bala_avanza:
	call bala_choca		;6d1d   ; choca?
	jr nz,bala_chocada		;6d20
	ld a,004h		;6d22   ; 4 pixeles
	bit 7,(ix+000h)		;6d24
	jr z,bala_avanza_x		;6d28
	ld a,0fch		;6d2a
bala_avanza_x:
	add a,(ix+001h)		;6d2c
	ld (ix+001h),a		;6d2f
	jr bala_sig		;6d32
bala_chocada:
	ld (ix+004h),002h		;6d34   ; el dibujo del choque...
	ld a,c			;6d38   ; ...20 cuadros
	ld b,014h		;6d39
	call pon_temporizador		;6d3b
	ld a,002h		;6d3e   ; el sonido del choque
	call sonido		;6d40
bala_sig:
	pop bc			;6d43
	ld de,0000ah		;6d44
	add ix,de		;6d47
	djnz bala_mueve		;6d49
	ret			;6d4b
balazos:		; Las balas enemigas contra el agente y las del agente contra los enemigos
	ld ix,0c0d8h		;6d4c   ; el agente...
	ld iy,0c2b8h		;6d50   ; ...contra las balas enemigas
	ld a,(ix+000h)		;6d54
	bit 0,a		;6d57
	jp z,balazos_fin		;6d59
	bit 2,(ix+000h)		;6d5c   ; en la escalera: no le dan
	jp nz,balazos_enemigos		;6d60
	bit 6,a		;6d63   ; muriendo
	jr nz,balazos_enemigos		;6d65
	bit 3,a		;6d67   ; en una puerta: escondido
	jr nz,balazos_enemigos		;6d69
	ld hl,06eb1h		;6d6b   ; su alto segun la postura
	ld a,(ix+003h)		;6d6e
balazos_postura:
	srl a		;6d71
	jr c,balazos_salto		;6d73
	inc hl			;6d75
	jr balazos_postura		;6d76
balazos_salto:
	bit 4,(ix+000h)		;6d78   ; en el aire...
	jr z,balazos_mira		;6d7c
	ld a,(ix+004h)		;6d7e
	cp 001h		;6d81
	jr z,balazos_mira		;6d83
	cp 004h		;6d85
	jr z,balazos_mira		;6d87
	inc hl			;6d89   ; ...otra fila
balazos_mira:
	ld b,(hl)			;6d8a
	ld c,004h		;6d8b   ; 4 balas
	ld hl,06ea5h		;6d8d
	call bala_da		;6d90   ; le dan?
	jr z,balazos_enemigos		;6d93
	ld hl,05856h		;6d95   ; los dibujos de siempre
	ld (0c0ddh),hl		;6d98
	ld a,000h		;6d9b   ; 30 cuadros
	ld b,01eh		;6d9d
	call pon_temporizador		;6d9f
	ld a,008h		;6da2   ; el sonido del balazo
	call sonido		;6da4
	bit 4,(ix+000h)		;6da7   ; saltando...
	jr z,balazos_enemigos		;6dab
	call que_hay_debajo		;6dad   ; ...sobre el vacio...
	jr z,balazos_enemigos		;6db0
	cp 002h		;6db2
	jr nz,balazos_enemigos		;6db4
	ld a,(ix+002h)		;6db6   ; ...cae 24
	add a,018h		;6db9
	ld (ix+002h),a		;6dbb
balazos_enemigos:		; Las 3 balas del agente contra los 4 enemigos
	ld ix,0c2e0h		;6dbe
	ld iy,0c29ah		;6dc2
	ld b,004h		;6dc6
balazo_enemigo:
	push bc			;6dc8
	ld a,(ix+000h)		;6dc9
	bit 0,a		;6dcc
	jr z,balazo_sig		;6dce
	bit 2,(ix+000h)		;6dd0   ; en la escalera no
	jp nz,balazo_sig		;6dd4
	bit 6,a		;6dd7
	jr nz,balazo_sig		;6dd9
	bit 4,(ix+003h)		;6ddb   ; saliendo de la puerta no
	jr nz,balazo_sig		;6ddf
	ld hl,06eadh		;6de1   ; su alto
	ld a,(ix+003h)		;6de4
balazo_postura:
	srl a		;6de7
	jr c,balazo_mira		;6de9
	inc hl			;6deb
	jr balazo_postura		;6dec
balazo_mira:
	ld b,(hl)			;6dee
	ld c,003h		;6def
	ld hl,06ea9h		;6df1
	call bala_da		;6df4   ; le da?
	jr z,balazo_sig		;6df7
	sub a			;6df9   ; dibujos de caer
	call dibujos_enemigo		;6dfa
	pop bc			;6dfd
	push bc			;6dfe
	ld a,016h		;6dff
	add a,b			;6e01
	dec a			;6e02
	ld b,01eh		;6e03
	call pon_temporizador		;6e05
	ld hl,0710dh		;6e08   ; 100 puntos
	ld a,(0c385h)		;6e0b   ; a oscuras...
	and a			;6e0e
	jr nz,balazo_150		;6e0f
	ld a,(0c0d3h)		;6e11   ; ...o con la vista en esas filas...
	cp 05eh		;6e14
	jr c,balazo_puntos		;6e16
	cp 07bh		;6e18
	jr nc,balazo_puntos		;6e1a
balazo_150:
	ld hl,07111h		;6e1c   ; ...150
balazo_puntos:
	call suma_puntos		;6e1f
	ld a,003h		;6e22   ; el sonido del golpe
	call sonido		;6e24
balazo_sig:
	pop bc			;6e27
	ld de,0000ah		;6e28
	add ix,de		;6e2b
	djnz balazo_enemigo		;6e2d
balazos_fin:
	ret			;6e2f
bala_da:		; NZ si alguna de las C balas de IY da a IX (B filas de 8 desde los pies); la bala choca e IX cae (postura 0x80)
	push iy		;6e30
	push de			;6e32
	ld e,000h		;6e33
bala_da_una:
	push bc			;6e35
	bit 0,(iy+000h)		;6e36   ; en juego?
	jr z,bala_da_sig		;6e3a
	ld a,(iy+004h)		;6e3c   ; volando?
	cp 002h		;6e3f
	jr nc,bala_da_sig		;6e41
	ld a,(ix+001h)		;6e43   ; a 4 pixeles o menos
	sub (iy+001h)		;6e46
	cp 005h		;6e49
	jr c,L_6E51		;6e4b
	cp 0fch		;6e4d
	jr c,bala_da_sig		;6e4f
L_6E51:
	call altura_bala		;6e51   ; la altura de la bala
	ld d,a			;6e54
	ld a,(ix+002h)		;6e55
bala_da_fila:
	cp d			;6e58
	jr z,bala_da_si		;6e59
	add a,0f8h		;6e5b
	djnz bala_da_fila		;6e5d
	jr bala_da_sig		;6e5f
bala_da_si:
	set 6,(iy+000h)		;6e61   ; la bala choca
	ld (iy+004h),003h		;6e65
	set 6,(ix+000h)		;6e69   ; IX muriendo
	ld (ix+003h),080h		;6e6d   ; postura 0x80
	ld (ix+004h),001h		;6e71
	ld e,001h		;6e75
bala_da_sig:
	push de			;6e77   ; se guarda
	ld de,0000ah		;6e78   ; 10 bytes
	add iy,de		;6e7b   ; la siguiente bala
	pop de			;6e7d
	pop bc			;6e7e
	dec c			;6e7f   ; una menos
	jr nz,bala_da_una		;6e80   ; las C
	ld a,e			;6e82   ; E: 1 si alguna dio
	and a			;6e83   ; NZ si dio
	pop de			;6e84
	pop iy		;6e85
	ret			;6e87   ; listo
altura_bala:		; A = la Y de la bala sin el desplazamiento de la postura, segun la tabla HL
	push hl			;6e88
	push bc			;6e89
	ld a,(iy+003h)		;6e8a
altura_bala_busca:
	srl a		;6e8d
	jr c,altura_bala_y		;6e8f
	inc hl			;6e91
	jr altura_bala_busca		;6e92
altura_bala_y:
	ld a,(iy+002h)		;6e94
	sub (iy+009h)		;6e97
	ld b,(hl)			;6e9a
altura_bala_resta:
	dec b			;6e9b
	jr z,altura_bala_fin		;6e9c
	add a,0f8h		;6e9e
	jr altura_bala_resta		;6ea0
altura_bala_fin:
	pop bc			;6ea2
	pop hl			;6ea3
	ret			;6ea4

; ----------------------------------------------------------------------
; DATOS altos: Cuantas filas de 8 ocupa cada postura (agente y enemigos)
;   0x6ea5..0x6eb1  (12 bytes)
DATA_altos:
	defb 003h,003h,002h,001h,003h,003h,002h,002h,003h,003h,002h,001h	; 6ea5  ............

; ----------------------------------------------------------------------
; DATOS altos_agente: Las del agente
;   0x6eb1..0x6eb6  (5 bytes)
DATA_altos_agente:
	defb 003h,003h,002h,003h,002h	; 6eb1

; ----------------------------------------------------------------------
; DATOS bala_dibujos: Dibujos de las balas por postura (derecha e izquierda)
;   0x6eb6..0x6ec6  (16 bytes)
DATA_bala_dibujos:
	defb 0c6h,06eh,0c6h,06eh,0c6h,06eh,0c6h,06eh,0cch,06eh,0cch,06eh,0cch,06eh,0cch,06eh	; 6eb6  .n.n.n.n.n.n.n.n

; ----------------------------------------------------------------------
; DATOS bala_cuadros: Los cuadros de la bala: volando y el choque
;   0x6ec6..0x6ee3  (29 bytes)
DATA_bala_cuadros:
	defb 0d2h,06eh,0d6h,06eh,0e2h,06eh,0dah,06eh,0deh,06eh,0e2h,06eh,088h,009h,0f0h,0ffh	; 6ec6  .n.n.n.n.n.n....
	defb 08ch,00fh,0f5h,0ffh,0c0h,009h,0f0h,0ffh,0c4h,00fh,0f5h,0ffh,0ffh	; 6ed6  .............

; ----------------------------------------------------------------------
; DATOS bala_alturas: Donde esta la pistola en cada postura (agente y enemigo)
;   0x6ee3..0x6ef3  (16 bytes)
DATA_bala_alturas:
	defb 0f3h,06eh,0f3h,06eh,0f4h,06eh,0f5h,06eh,0f3h,06eh,0f3h,06eh,0f4h,06eh,0f6h,06eh	; 6ee3  .n.n.n.n.n.n.n.n

; ----------------------------------------------------------------------
; DATOS bala_alturas_d: Los desplazamientos: -13, -6, 0
;   0x6ef3..0x6ef7  (4 bytes)
DATA_bala_alturas_d:
	defb 0f3h,0fah,0fdh,000h	; 6ef3

; ======================================================================
; CODIGO 0x6ef7..0x710b  (532 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  Los puntos  =====
; ----------------------------------------------------------------------
suma_puntos:		; Suma a los 7 digitos ASCII de 0xC082 la lista HL (cuantas cifras y luego las cifras, de las unidades arriba)
	push ix		;6ef7
	push iy		;6ef9
	push bc			;6efb
	push de			;6efc
	ld b,(hl)			;6efd   ; cuantas cifras
	inc hl			;6efe
	ld ix,0c080h		;6eff   ; las unidades estan en 0xC088
suma_cifra:
	ld a,(ix+008h)		;6f03
	add a,(hl)			;6f06
	cp 03ah		;6f07   ; pasa de 9?
	jr c,suma_cifra_guarda		;6f09
	sub 00ah		;6f0b
	inc (ix+007h)		;6f0d   ; me llevo una
suma_cifra_guarda:
	ld (ix+008h),a		;6f10   ; la cifra
	dec b			;6f13   ; una menos
	jr z,suma_acarreos		;6f14   ; acabadas: los acarreos
	inc hl			;6f16   ; la siguiente cifra a sumar
	dec ix		;6f17   ; la cifra de la izquierda
	jr suma_cifra		;6f19
suma_acarreos:		; Propaga lo que quede por encima de 9
	ld ix,0c080h		;6f1b
	ld b,006h		;6f1f
suma_acarreo:
	ld a,(ix+008h)		;6f21
	cp 03ah		;6f24
	jr c,suma_acarreo_guarda		;6f26
	sub 00ah		;6f28
	inc (ix+007h)		;6f2a
suma_acarreo_guarda:
	ld (ix+008h),a		;6f2d
	dec ix		;6f30
	dec b			;6f32
	jr nz,suma_acarreo		;6f33
	ld ix,0c080h		;6f35
	ld a,(ix+002h)		;6f39   ; la cifra de los millones...
	cp 03ah		;6f3c   ; ...pasada de 9...
	jr c,suma_fin		;6f3e
	ld a,030h		;6f40   ; ...vuelve a 0
suma_fin:
	call cuenta_por_puntos		;6f42   ; la cuenta de 0xC0D4
	pop de			;6f45
	pop bc			;6f46
	pop iy		;6f47
	pop ix		;6f49
	ret			;6f4b   ; listo
cuenta_por_puntos:		; Lleva en 0xC0D4 una cuenta segun las decenas de millar; nada mas la lee
	ld hl,0c082h		;6f4c   ; las decenas de millar...
	ld b,003h		;6f4f
	call cifras_a_numero		;6f51   ; ...como numero
	srl d		;6f54   ; / 4
	rr e		;6f56
	srl d		;6f58
	rr e		;6f5a
	ld b,000h		;6f5c
	ld a,(0c0d4h)		;6f5e   ; la primera vez...
	and a			;6f61
	jr nz,cuenta_por_puntos_mas		;6f62
	or d			;6f64   ; ...sin nada, nada
	or e			;6f65
	jr z,cuenta_por_puntos_fin		;6f66
	inc b			;6f68
	ld a,001h		;6f69
cuenta_por_puntos_mas:
	srl d		;6f6b   ; / 2
	rr e		;6f6d
	dec a			;6f6f   ; A - 1
	cp e			;6f70   ; mayor?
	jr nc,cuenta_por_puntos_suma		;6f71
	ld d,a			;6f73   ; la diferencia...
	ld a,e			;6f74
	sub d			;6f75
	add a,b			;6f76   ; ...a B
	ld b,a			;6f77
cuenta_por_puntos_suma:
	ld a,b			;6f78   ; cuanto?
	and a			;6f79
	jr z,cuenta_por_puntos_fin		;6f7a   ; nada
	ld a,(0c0d4h)		;6f7c   ; + B
	add a,b			;6f7f
	ld (0c0d4h),a		;6f80   ; guardada
cuenta_por_puntos_fin:
	ret			;6f83
cifras_a_numero:		; DE = las B cifras ASCII de HL como numero
	ld de,00000h		;6f84
cifras_a_numero_sig:
	ld a,(hl)			;6f87   ; la cifra...
	sub 030h		;6f88   ; ...de ASCII a numero
	push hl			;6f8a
	ex de,hl			;6f8b
	add hl,hl			;6f8c   ; x 10
	ld e,l			;6f8d   ; DE = x 2
	ld d,h			;6f8e
	add hl,hl			;6f8f   ; x 4
	add hl,hl			;6f90   ; x 8
	add hl,de			;6f91   ; x 10
	ld e,a			;6f92
	ld d,000h		;6f93
	add hl,de			;6f95   ; + la cifra
	ex de,hl			;6f96
	pop hl			;6f97
	inc hl			;6f98
	djnz cifras_a_numero_sig		;6f99
	ret			;6f9b

; ----------------------------------------------------------------------
; =====  El marcador  =====
; ----------------------------------------------------------------------
marcador:		; Los puntos y las vidas a la VRAM (no despues del fin de partida)
	ld a,(0c080h)		;6f9c   ; fin de partida?
	bit 1,a		;6f9f
	jr nz,marcador_fin		;6fa1
	ld de,0c082h		;6fa3   ; los puntos...
	call cifras_sin_ceros		;6fa6   ; ...sin ceros a la izquierda...
	ld hl,0c339h		;6fa9   ; ...a la fila de arriba
	ld de,01022h		;6fac
	ld bc,00007h		;6faf
	call 0005ch		;6fb2
	ld a,(0c08ah)		;6fb5   ; las vidas...
	call numero_a_cifras		;6fb8
	ld hl,0c32fh		;6fbb
	ld de,012e4h		;6fbe   ; ...abajo a la izquierda
	ld bc,00002h		;6fc1
	call 0005ch		;6fc4
marcador_fin:
	ret			;6fc7
cifras_sin_ceros:		; Copia 6 cifras de DE a 0xC339 cambiando los ceros de la izquierda por espacios, y un 0 al final
	ld hl,0c339h		;6fc8
	ld b,006h		;6fcb
cifras_cero:
	ld a,(de)			;6fcd   ; la cifra
	cp 030h		;6fce   ; "0"?
	jr nz,cifras_copia		;6fd0   ; no: el resto tal cual
	ld (hl),03bh		;6fd2   ; un espacio
	inc hl			;6fd4
	inc de			;6fd5
	djnz cifras_cero		;6fd6   ; las B
	jr cifras_fin		;6fd8
cifras_copia:
	ld a,(de)			;6fda
	ld (hl),a			;6fdb
	inc hl			;6fdc
	inc de			;6fdd
	djnz cifras_copia		;6fde
cifras_fin:
	ld (hl),030h		;6fe0
	ret			;6fe2
rotulo_y_puntos:		; Saca un rotulo que se despliega (lista HL: el rotulo y los puntos que da al acabar)
	push ix		;6fe3
	ld ix,0c308h		;6fe5   ; la ficha del rotulo
	ld a,(hl)			;6fe9   ; el rotulo
	inc hl			;6fea
	push hl			;6feb
	ld h,(hl)			;6fec
	ld l,a			;6fed
	call rotulo_saca		;6fee
	pop hl			;6ff1
	inc hl			;6ff2
	ld a,(hl)			;6ff3   ; los puntos que da al final
	inc hl			;6ff4
	ld h,(hl)			;6ff5
	ld l,a			;6ff6
	ld (ix+004h),l		;6ff7
	ld (ix+005h),h		;6ffa
	pop ix		;6ffd
	ret			;6fff
rotulo_saca:		; Empieza a sacar el rotulo HL en el mapa DE; cada 30 cuadros un paso, 6 pasos
	push ix		;7000
	ld ix,0c308h		;7002
	set 0,(ix+000h)		;7006   ; en marcha (corta las salidas de enemigos)
	ld (ix+001h),001h		;700a   ; paso 1
	ld (ix+002h),e		;700e   ; donde va
	ld (ix+003h),d		;7011
	call pon_bloque_guardando		;7014   ; el primer paso a 0xE000
	ld hl,0e000h		;7017   ; y guardado lo que habia
	ld de,0c30eh		;701a
	ld bc,00014h		;701d
	ldir		;7020
	ld a,01ah		;7022   ; temporizador 0x1A...
	ld b,01eh		;7024   ; ...30 cuadros
	call pon_temporizador		;7026
	pop ix		;7029
	ret			;702b
rotulo_cuadro:		; Avanza el rotulo; al sexto paso lo quita y suma sus puntos
	ld ix,0c308h		;702c
	bit 0,(ix+000h)		;7030   ; hay rotulo?
	jr z,rotulo_ret		;7034
	ld a,01ah		;7036   ; toca paso?
	call lee_temporizador		;7038
	jr nz,rotulo_ret		;703b
	ld a,01ah		;703d
	ld b,01eh		;703f
	call pon_temporizador		;7041
	inc (ix+001h)		;7044   ; paso siguiente
	ld a,(ix+001h)		;7047
	cp 007h		;704a   ; hasta el 6
	jr nc,rotulo_fin		;704c
	ld hl,0c30eh		;704e
	ld e,(ix+002h)		;7051
	ld d,(ix+003h)		;7054
	call pon_bloque_guardando		;7057
	ld hl,0e000h		;705a
	ld de,0c30eh		;705d
	ld bc,00014h		;7060
	ldir		;7063
	jr rotulo_ret		;7065
rotulo_fin:
	res 0,(ix+000h)		;7067   ; se acabo
	ld l,(ix+004h)		;706b   ; sus puntos
	ld h,(ix+005h)		;706e
	call suma_puntos		;7071
rotulo_ret:
	ret			;7074
record:		; Si los 7 digitos de DE son mas que el record HL, se copian; NZ si hay record nuevo
	push hl			;7075
	push de			;7076
	ld b,007h		;7077
record_cifra:
	ld a,(de)			;7079
	cp (hl)			;707a
	jr c,record_si		;707b
	jr z,record_igual		;707d
	jr record_no		;707f
record_igual:
	inc hl			;7081
	inc de			;7082
	djnz record_cifra		;7083
record_no:
	sub a			;7085
	pop de			;7086
	pop hl			;7087
	jr record_fin		;7088
record_si:
	pop de			;708a
	pop hl			;708b
	ld bc,00007h		;708c
	ldir		;708f
	ld a,001h		;7091
record_fin:
	and a			;7093
	ret			;7094
numero_a_cifras:		; A (0-99) a dos cifras ASCII en 0xC32F; por debajo de 10, la segunda es un espacio
	cp 00ah		;7095
	jr nc,dos_cifras		;7097
una_cifra:
	or 030h		;7099
	ld (0c32fh),a		;709b
	ld a,03bh		;709e
	ld (0c330h),a		;70a0
	jr numero_fin		;70a3
dos_cifras:
	cp 064h		;70a5   ; 100 o mas...
	jr c,dos_cifras_cuenta		;70a7
	sub a			;70a9   ; ...0
	jr una_cifra		;70aa
dos_cifras_cuenta:
	ld b,000h		;70ac
dos_cifras_decenas:
	ld c,a			;70ae
	sub 00ah		;70af
	jr c,dos_cifras_pon		;70b1
	inc b			;70b3
	jr dos_cifras_decenas		;70b4
dos_cifras_pon:
	ld a,b			;70b6   ; las decenas...
	or 030h		;70b7   ; ...en ASCII
	ld (0c32fh),a		;70b9
	ld a,c			;70bc   ; las unidades...
	or 030h		;70bd   ; ...en ASCII
	ld (0c330h),a		;70bf
numero_fin:
	ret			;70c2
pon_bloque_guardando:		; Pone en el mapa DE el bloque HL (ancho y filas hasta 0xFF) y guarda en 0xE000 lo que tapa
	push ix		;70c3
	push iy		;70c5
	ld iy,0e000h		;70c7   ; lo tapado
	ld c,(hl)			;70cb   ; el ancho
	ld b,000h		;70cc
	ld (iy+000h),c		;70ce
	inc iy		;70d1
	inc hl			;70d3
pon_bloque_fila:
	ld a,(hl)			;70d4
	cp 0ffh		;70d5   ; 0xFF acaba
	jr z,pon_bloque_fin		;70d7
	push bc			;70d9
	push hl			;70da
	push de			;70db
	ex de,hl			;70dc
	push iy		;70dd
	pop de			;70df
	push iy		;70e0
	push bc			;70e2
	ldir		;70e3   ; guarda la fila del mapa
	pop bc			;70e5
	pop iy		;70e6
	add iy,bc		;70e8
	pop de			;70ea
	pop hl			;70eb
	pop bc			;70ec
	push hl			;70ed
	push bc			;70ee
	push de			;70ef
	ldir		;70f0   ; y pone la del bloque
	pop de			;70f2
	ld hl,00020h		;70f3
	add hl,de			;70f6
	ex de,hl			;70f7
	pop bc			;70f8
	pop hl			;70f9
	add hl,bc			;70fa
	jr pon_bloque_fila		;70fb
pon_bloque_fin:
	ld (iy+000h),0ffh		;70fd
	ld hl,0c0d0h		;7101   ; volcar
	set 7,(hl)		;7104
	pop iy		;7106
	pop ix		;7108
	ret			;710a

; ----------------------------------------------------------------------
; DATOS puntos_tablas: Puntos (cuantas cifras y las cifras de las unidades
;   arriba): 0, 100, 150, 200, 300, 500 y 1000
;   0x710b..0x7126  (27 bytes)
DATA_puntos_tablas:
	defb 001h,000h,003h,000h,000h,001h,003h,000h,005h,001h,003h,000h,000h,002h,003h,000h	; 710b  ................
	defb 000h,003h,003h,000h,000h,005h,004h,000h,000h,000h,001h	; 711b  ...........

; ======================================================================
; CODIGO 0x7126..0x72e9  (451 bytes)
; ======================================================================


copia_con_largo:		; Copia a DE los bytes de HL precedidos de su largo (dos bytes); largo 0, nada
	ld c,(hl)			;7126   ; el largo
	inc hl			;7127
	ld b,(hl)			;7128
	inc hl			;7129
	ld a,c			;712a
	or b			;712b   ; cero?
	ret z			;712c   ; si: nada
	ldir		;712d   ; copiados
	ret			;712f   ; listo
descomprime:		; RLE con dos corrientes: los codigos (n: copiar n; 0x80+n: repetir n veces) y los bytes
	push ix		;7130
	ld c,(hl)			;7132   ; largo de los codigos
	inc hl			;7133
	ld b,(hl)			;7134
	inc hl			;7135
	push hl			;7136   ; los codigos en IX...
	pop ix		;7137
	add hl,bc			;7139   ; ...y los bytes detras
descomprime_codigo:
	ld a,(ix+000h)		;713a
	or a			;713d   ; 0: acabado
	jr z,descomprime_fin		;713e
	jp p,descomprime_copia		;7140   ; menos de 0x80: copia
	and 07fh		;7143   ; repetir n veces...
	ld c,a			;7145
	ld b,000h		;7146
	ld a,(hl)			;7148   ; ...el byte siguiente
	push bc			;7149
	ex de,hl			;714a
	push hl			;714b
	push de			;714c
	ld (hl),a			;714d
	dec c			;714e
	jr z,descomprime_repetido		;714f
	push hl			;7151
	pop de			;7152
	inc de			;7153
	ldir		;7154
descomprime_repetido:
	pop de			;7156   ; se recuperan
	pop hl			;7157
	pop bc			;7158
	add hl,bc			;7159   ; + n en el destino
	ex de,hl			;715a
	inc hl			;715b   ; el byte siguiente
	inc ix		;715c   ; el codigo siguiente
	jr descomprime_codigo		;715e   ; sigue
descomprime_copia:
	ld c,a			;7160
	ld b,000h		;7161
	ldir		;7163
	inc ix		;7165
	jr descomprime_codigo		;7167
descomprime_fin:
	pop ix		;7169
	ret			;716b

; ----------------------------------------------------------------------
; =====  La entrada de la ronda 1: el agente baja por el cable  =====
; ----------------------------------------------------------------------
entrada_cable:		; Solo en la ronda 1: se tiende el cable hasta la azotea y el agente se desliza por el
	xor a			;716c   ; paso 0
	ld (0c384h),a		;716d
	inc a			;7170   ; se juega (la interrupcion trabaja)
	ld (0c0d6h),a		;7171
	ld a,00dh		;7174   ; el sonido 0x0D
	call sonido		;7176
cable_paso:		; 8 pasos: el cable crece desde la esquina
	call espera_8		;7179   ; 8 cuadros
	ld a,(0c384h)		;717c
	cp 008h		;717f   ; acabado?
	jr z,cable_tendido		;7181
	inc a			;7183
	ld (0c384h),a		;7184
	ld hl,073e7h		;7187   ; el dibujo del paso
	add a,a			;718a
	ld c,a			;718b
	ld b,000h		;718c
	add hl,bc			;718e
	ld a,(hl)			;718f
	inc hl			;7190
	ld h,(hl)			;7191
	ld l,a			;7192
	ld c,(hl)			;7193   ; ancho
	inc hl			;7194
	ld a,(hl)			;7195   ; alto
	inc hl			;7196
	ld de,0c460h		;7197   ; arriba a la izquierda del mapa
	call copia_bloque		;719a
	ld hl,0c0d0h		;719d
	set 7,(hl)		;71a0
	jr cable_paso		;71a2
cable_tendido:		; El cable entero y el agente colgado: sus dibujos propios a 0x2680/0x2E80
	call espera_8		;71a4
	ld de,0c460h		;71a7   ; tres trozos del gancho
	ld hl,072f5h		;71aa
	call pon_bloque_3x4		;71ad
	ld de,0c483h		;71b0
	ld hl,07301h		;71b3
	call pon_bloque_3x4		;71b6
	ld de,0c4a6h		;71b9
	ld hl,0730dh		;71bc
	call pon_bloque_3x4		;71bf
	ld de,0c4a9h		;71c2   ; y el ultimo de 5 x 4
	ld hl,07315h		;71c5
	ld bc,00005h		;71c8
	ld a,004h		;71cb
	call pon_bloque_y_vuelca		;71cd
	di			;71d0
	ld bc,0c201h		;71d1   ; pantalla sin interrupcion
	call escribe_vdp		;71d4
	ld hl,07329h		;71d7   ; el agente colgado...
	ld de,02680h		;71da
	ld bc,00060h		;71dd
	push bc			;71e0
	call 0005ch		;71e1
	ld hl,07389h		;71e4   ; ...y dado la vuelta
	ld de,02e80h		;71e7
	pop bc			;71ea
	call 0005ch		;71eb
	ld bc,0e201h		;71ee
	call escribe_vdp		;71f1
	ei			;71f4
	ld de,0c000h		;71f5   ; sus tres sprites
	ld hl,072e9h		;71f8
	ld bc,0000ch		;71fb
	ldir		;71fe
	ld a,010h		;7200   ; el sonido 0x10
	call sonido		;7202
	ld b,00eh		;7205   ; 14 pasos
cable_baja:
	push bc			;7207
	call cable_desliza		;7208
	pop bc			;720b
	djnz cable_baja		;720c
	ld b,00ah		;720e
cable_baja_mirando:		; 10 pasos mas cambiando de lado (el registro 6 alterna)
	push bc			;7210   ; la cuenta
	call cable_desliza		;7211   ; un paso
	ld bc,00506h		;7214   ; registro 6 = 5: dados la vuelta
	call escribe_vdp		;7217
	ld b,004h		;721a   ; 4 cuadros
	call espera_b		;721c
	ld bc,00406h		;721f   ; registro 6 = 4
	call escribe_vdp		;7222
	pop bc			;7225   ; la cuenta
	djnz cable_baja_mirando		;7226   ; los 10
	ld hl,0c002h		;7228   ; los dibujos de soltarse
	ld de,00004h		;722b
	ld (hl),024h		;722e   ; los dibujos de caer
	inc hl			;7230
	inc hl			;7231
	inc (hl)			;7232
	inc hl			;7233
	inc hl			;7234
	ld (hl),028h		;7235
	add hl,de			;7237
	ld (hl),000h		;7238
cable_suelta:		; El agente cae a la azotea hasta la Y 0x70
	call espera_8		;723a   ; 8 cuadros
	ld hl,0c000h		;723d   ; el primer sprite
	ld a,(hl)			;7240
	add a,008h		;7241   ; 8 mas abajo
	cp 070h		;7243   ; llega a 0x70?
	jr z,cable_quita		;7245
	ld (hl),a			;7247   ; su Y
	add hl,de			;7248   ; el segundo...
	inc a			;7249
	ld (hl),a			;724a   ; ...un pixel por debajo
	jr cable_suelta		;724b   ; otra vez
cable_quita:		; Se borra el cable del mapa
	ld hl,0c481h		;724d
	ld de,00022h		;7250
	xor a			;7253
	ld (hl),a			;7254
	ld b,003h		;7255
L_7257:
	add hl,de			;7257
	ld (hl),a			;7258
	inc hl			;7259
	inc hl			;725a
	ld (hl),a			;725b
	djnz L_7257		;725c
	ld hl,0c0d0h		;725e
	set 7,(hl)		;7261
	ld a,011h		;7263   ; el sonido 0x11
	call sonido		;7265
	ld b,010h		;7268   ; 16 cuadros
	call espera_b		;726a
	ld bc,00506h		;726d   ; dado la vuelta...
	call escribe_vdp		;7270
	ld b,018h		;7273   ; ...24 cuadros
	call espera_b		;7275
	ld bc,00406h		;7278   ; normal
	call escribe_vdp		;727b
	ld hl,0c480h		;727e
	xor a			;7281
	ld b,003h		;7282
	ld de,00022h		;7284
cable_quita_fila:
	ld (hl),a			;7287   ; un tile del cable...
	inc hl			;7288
	inc hl			;7289
	ld (hl),a			;728a   ; ...y el de al lado, a cero
	add hl,de			;728b   ; la fila siguiente
	djnz cable_quita_fila		;728c   ; las 3
	ld (hl),a			;728e
	ld hl,0c0d0h		;728f
	set 7,(hl)		;7292   ; volcar
	di			;7294
	ld hl,0925ch		;7295   ; los dibujos normales...
	ld de,02680h		;7298   ; ...a 0x2680
	ld bc,00060h		;729b
	push hl			;729e
	push bc			;729f
	call 0005ch		;72a0
	di			;72a3
	pop bc			;72a4
	pop hl			;72a5
	ld de,02e80h		;72a6
	call 0005ch		;72a9
	ld b,010h		;72ac   ; 16 cuadros
	call espera_b		;72ae
	ret			;72b1
cable_desliza:		; Seis cuadros y los B sprites 1 abajo y 4 a la derecha
	ld b,006h		;72b2
	call espera_b		;72b4
	ld hl,0c000h		;72b7
	ld de,00003h		;72ba
cable_desliza_uno:
	ld a,001h		;72bd   ; Y + 1
	add a,(hl)			;72bf
	ld (hl),a			;72c0
	inc hl			;72c1
	ld a,004h		;72c2   ; X + 4
	add a,(hl)			;72c4
	ld (hl),a			;72c5
	add hl,de			;72c6   ; el siguiente
	djnz cable_desliza_uno		;72c7   ; los B
	ret			;72c9   ; listo
pon_bloque_3x4:		; Un bloque de 4 x 3 en el mapa y a volcar
	ld bc,00004h		;72ca
	ld a,003h		;72cd
pon_bloque_y_vuelca:
	call copia_bloque		;72cf
	ld hl,0c0d0h		;72d2
	set 7,(hl)		;72d5
espera_8:		; Espera 8 cuadros con el temporizador 0
	ld b,008h		;72d7
espera_b:		; Espera B cuadros con el temporizador 0
	xor a			;72d9
	call pon_temporizador		;72da
espera_b_sig:
	xor a			;72dd   ; el temporizador 0
	call lee_temporizador		;72de
	jr nz,espera_b_sig		;72e1   ; espera
	ld hl,0c0d0h		;72e3
	res 7,(hl)		;72e6   ; sin volcar
	ret			;72e8   ; listo

; ----------------------------------------------------------------------
; DATOS cable_sprites: Los tres sprites del agente colgado (Y, X, dibujo,
;   color)
;   0x72e9..0x72f5  (12 bytes)
DATA_cable_sprites:
	defb 030h,000h,0d0h,006h,030h,000h,0d4h,00bh,030h,000h,0d8h,006h	; 72e9  0...0...0...

; ----------------------------------------------------------------------
; DATOS cable_gancho: El gancho del cable en la azotea, en tres trozos y uno
;   de 5 x 4
;   0x72f5..0x7329  (52 bytes)
DATA_cable_gancho:
	defb 000h,000h,000h,000h,0a8h,0a9h,0aah,000h,000h,000h,000h,0a6h,000h,000h,000h,000h	; 72f5  ................
	defb 0aeh,0a8h,0a9h,0a7h,000h,000h,000h,000h,0aah,000h,000h,000h,000h,0aeh,0a8h,0adh	; 7305  ................
	defb 000h,000h,000h,000h,000h,0a9h,0aah,000h,000h,000h,000h,000h,0aeh,0abh,0ach,000h	; 7315  ................
	defb 000h,000h,000h,000h	; 7325

; ----------------------------------------------------------------------
; DATOS cable_dibujos: El agente colgado: tres sprites de 16 x 16 mirando a
;   cada lado
;   0x7329..0x73e9  (192 bytes)
DATA_cable_dibujos:
	defb 000h,000h,03fh,03fh,01fh,011h,010h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 7329  ..??............
	defb 000h,000h,0c0h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 7339  ................
	defb 0c0h,0c0h,000h,000h,00ah,00ah,00fh,00eh,004h,000h,000h,000h,000h,000h,000h,000h	; 7349  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 7359  ................
	defb 000h,000h,0c0h,0c0h,0e0h,0e0h,060h,070h,071h,03bh,03fh,01fh,01fh,007h,000h,000h	; 7369  ......`pq;?.....
	defb 018h,00ch,00ch,07eh,0fdh,0f1h,0e1h,0e3h,0dfh,0ffh,0ffh,0f0h,0f0h,0e0h,000h,000h	; 7379  ...~............
	defb 000h,000h,047h,0c7h,0c2h,082h,080h,080h,000h,000h,000h,000h,000h,000h,000h,000h	; 7389  ..G.............
	defb 000h,000h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 7399  ................
	defb 018h,018h,000h,000h,004h,004h,01ch,01eh,01ch,018h,000h,000h,000h,000h,000h,000h	; 73a9  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 73b9  ................
	defb 000h,000h,038h,038h,030h,071h,062h,060h,0e0h,0e4h,0ffh,0ffh,0ffh,07fh,07fh,01eh	; 73c9  ..880qb`........
	defb 030h,018h,01ch,01ch,038h,038h,070h,070h,0e0h,0f1h,0fdh,0ffh,0ffh,0c6h,082h,000h	; 73d9  0...88pp........

; ----------------------------------------------------------------------
; DATOS cable_pasos: Los 8 dibujos del cable creciendo
;   0x73e9..0x73f9  (16 bytes)
DATA_cable_pasos:
	defb 0f9h,073h,003h,074h,017h,074h,02eh,074h,054h,074h,07eh,074h,0bch,074h,0ffh,074h	; 73e9  .s.t.t.tTt~t.t.t

; ----------------------------------------------------------------------
; DATOS cable_pasos_d: Cada dibujo: ancho, alto y tiles
;   0x73f9..0x7555  (348 bytes)
DATA_cable_pasos_d:
	defb 004h,002h,000h,000h,098h,099h,0a5h,09ah,09bh,0a3h,006h,003h,000h,000h,098h,099h	; 73f9  ................
	defb 000h,000h,0a5h,09ah,09bh,09ch,09eh,09fh,000h,000h,000h,09dh,0a1h,0a0h,007h,003h	; 7409  ................
	defb 000h,000h,098h,099h,000h,000h,000h,0a5h,09ah,09bh,09ch,000h,098h,099h,000h,000h	; 7419  ................
	defb 000h,0afh,09ah,09bh,0a3h,009h,004h,000h,000h,098h,099h,000h,000h,000h,000h,000h	; 7429  ................
	defb 0a5h,09ah,09bh,09ch,000h,098h,099h,000h,000h,000h,000h,000h,0afh,09ah,09bh,09ch	; 7439  ................
	defb 09eh,09fh,000h,000h,000h,000h,000h,000h,09dh,0a1h,0a0h,00ah,004h,000h,000h,098h	; 7449  ................
	defb 099h,000h,000h,000h,000h,000h,000h,0a5h,09ah,09bh,09ch,000h,098h,099h,000h,000h	; 7459  ................
	defb 000h,000h,000h,000h,0afh,09ah,09bh,09ch,000h,098h,099h,000h,000h,000h,000h,000h	; 7469  ................
	defb 000h,0afh,09ah,09bh,0a3h,00ch,005h,000h,000h,098h,099h,000h,000h,000h,000h,000h	; 7479  ................
	defb 000h,000h,000h,0a5h,09ah,09bh,09ch,000h,098h,099h,000h,000h,000h,000h,000h,000h	; 7489  ................
	defb 000h,000h,0afh,09ah,09bh,09ch,000h,098h,099h,000h,000h,000h,000h,000h,000h,000h	; 7499  ................
	defb 000h,0afh,09ah,09bh,09ch,09eh,09fh,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 74a9  ................
	defb 09dh,0a1h,0a0h,00dh,005h,000h,000h,098h,099h,000h,000h,000h,000h,000h,000h,000h	; 74b9  ................
	defb 000h,000h,0a5h,09ah,09bh,09ch,000h,098h,099h,000h,000h,000h,000h,000h,000h,000h	; 74c9  ................
	defb 000h,000h,0afh,09ah,09bh,09ch,000h,098h,099h,000h,000h,000h,000h,000h,000h,000h	; 74d9  ................
	defb 000h,000h,0afh,09ah,09bh,09ch,000h,098h,099h,000h,000h,000h,000h,000h,000h,000h	; 74e9  ................
	defb 000h,000h,0afh,09ah,09bh,0a3h,00eh,006h,000h,000h,098h,099h,000h,000h,000h,000h	; 74f9  ................
	defb 000h,000h,000h,000h,000h,000h,0a5h,09ah,09bh,09ch,000h,098h,099h,000h,000h,000h	; 7509  ................
	defb 000h,000h,000h,000h,000h,000h,000h,0afh,09ah,09bh,09ch,000h,098h,099h,000h,000h	; 7519  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0afh,09ah,09bh,09ch,000h,098h,099h,000h	; 7529  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,0afh,09ah,09bh,09ch,09eh,000h,000h	; 7539  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,09dh,0a1h	; 7549  ............

; ======================================================================
; CODIGO 0x7555..0x78cd  (888 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  El sonido  =====
; ----------------------------------------------------------------------
sonido_apaga:		; Silencio: guarda los bits altos del registro 7 del PSG y para los tres canales
	ld a,007h		;7555
	call 00096h		;7557   ; RDPSG 7
	and 0c0h		;755a   ; los de los puertos de E/S
	ld (0c3dah),a		;755c
	call 00090h		;755f   ; GICINI
sonido_calla:		; Para los tres canales
	di			;7562
	ld iy,0c3ach		;7563   ; canal A
	ld c,000h		;7567
	call canal_silencio		;7569
	ld iy,0c3b6h		;756c   ; canal B
	ld c,001h		;7570
	call canal_silencio		;7572
	ld iy,0c3c0h		;7575   ; canal C
	ld c,002h		;7579
	call canal_silencio		;757b
	ei			;757e
	ret			;757f
sonido:		; Pide el sonido A: con el bit 7, una musica (tabla 0x9AB5, tres canales); si no, un efecto (0x9A8F) con prioridad
	push ix		;7580
	push iy		;7582
	push hl			;7584
	push de			;7585
	push bc			;7586
	ld ix,0c3a4h		;7587   ; la peticion
	bit 7,a		;758b   ; musica?
	jr nz,sonido_musica		;758d
	ld hl,09a8fh		;758f   ; los efectos
	call tabla_puntero		;7592
	call sonido_prioridad		;7595   ; mas prioridad que el que suena?
	jr nz,sonido_fin		;7598
	di			;759a
	ld hl,0c3abh		;759b   ; al canal A
	set 0,(hl)		;759e
	ei			;75a0
	jr sonido_fin		;75a1
sonido_musica:
	res 7,a		;75a3
	ld hl,09ab5h		;75a5   ; las musicas
	call tabla_puntero		;75a8
	ld de,0c3a7h		;75ab   ; sus tres canales
	ld bc,00004h		;75ae
	di			;75b1
	ldir		;75b2
	ei			;75b4
	ld l,(ix+003h)		;75b5   ; hay canal B?
	ld h,(ix+004h)		;75b8
	ld a,l			;75bb
	or h			;75bc
	jr z,sonido_musica_c		;75bd
	di			;75bf
	ld hl,0c3abh		;75c0
	set 1,(hl)		;75c3
	ei			;75c5
sonido_musica_c:
	ld l,(ix+005h)		;75c6   ; hay canal C?
	ld h,(ix+006h)		;75c9
	ld a,l			;75cc
	or h			;75cd
	jr z,sonido_fin		;75ce
	di			;75d0
	ld hl,0c3abh		;75d1
	set 2,(hl)		;75d4
	ei			;75d6
sonido_fin:
	pop bc			;75d7   ; se recupera todo
	pop de			;75d8
	pop hl			;75d9
	pop iy		;75da
	pop ix		;75dc
	ret			;75de   ; listo
tabla_puntero:		; HL = el puntero A de la tabla HL
	push de			;75df   ; se guarda
	ld e,a			;75e0   ; A...
	ld d,000h		;75e1
	sla e		;75e3   ; ...x 2
	add hl,de			;75e5   ; la entrada
	ld e,(hl)			;75e6   ; el puntero
	inc hl			;75e7
	ld d,(hl)			;75e8
	ex de,hl			;75e9   ; en HL
	pop de			;75ea
	ret			;75eb   ; listo
sonido_cuadro:		; En la interrupcion: arranca lo pedido, escribe el PSG y avanza las notas
	call sonido_arranca		;75ec
	call psg_escribe		;75ef
	call canales_cuadro		;75f2
	ret			;75f5
sonido_arranca:		; Los canales pedidos (bits de 0xC3AB) empiezan su lista
	ld ix,0c3a4h		;75f6
	ld a,(0c3abh)		;75fa   ; los pedidos
	ld b,a			;75fd
	srl b		;75fe
	push bc			;7600
	jr nc,sonido_arranca_b		;7601
	ld l,(ix+001h)		;7603   ; el canal A
	ld h,(ix+002h)		;7606
	ld c,000h		;7609
	call canal_nota		;760b
	ld a,002h		;760e
	ld (0c3dbh),a		;7610
sonido_arranca_b:
	pop bc			;7613   ; los pedidos
	srl b		;7614   ; el bit del canal B
	push bc			;7616
	jr nc,sonido_arranca_c		;7617   ; no
	ld l,(ix+003h)		;7619   ; su lista
	ld h,(ix+004h)		;761c
	ld c,001h		;761f   ; canal 1
	call canal_nota		;7621   ; la primera nota
	ld a,002h		;7624   ; a escribir todo
	ld (0c3dbh),a		;7626
sonido_arranca_c:
	pop bc			;7629   ; los pedidos
	srl b		;762a   ; el bit del canal C
	jr nc,sonido_arranca_fin		;762c   ; no
	ld l,(ix+005h)		;762e   ; su lista
	ld h,(ix+006h)		;7631
	ld c,002h		;7634   ; canal 2
	call canal_nota		;7636   ; la primera nota
	ld a,002h		;7639   ; a escribir todo
	ld (0c3dbh),a		;763b
sonido_arranca_fin:
	sub a			;763e
	ld (0c3abh),a		;763f
	ret			;7642
sonido_prioridad:		; Copia la peticion si su prioridad no es menor que la del efecto que suena; NZ si no
	push de			;7643
	push bc			;7644
	ld de,0c3a4h		;7645   ; lo que suena
	ld a,(de)			;7648   ; su prioridad
	and a			;7649   ; nada?
	jr z,sonido_prioridad_si		;764a   ; si: entra
	dec a			;764c   ; - 1
	cp (hl)			;764d   ; contra la nueva
	ld a,001h		;764e
	jr nc,sonido_prioridad_fin		;7650   ; menor la nueva: no
sonido_prioridad_si:
	ld bc,00003h		;7652
	di			;7655
	ldir		;7656
	ei			;7658
	sub a			;7659
sonido_prioridad_fin:
	and a			;765a
	pop bc			;765b
	pop de			;765c
	ret			;765d
psg_escribe:		; La copia del PSG (0xC3CA) a los registros que toque segun 0xC3DB
	ld a,(0c3dbh)		;765e   ; nada que escribir
	and a			;7661
	ret z			;7662
	cp 001h		;7663
	jr z,psg_escribe_todo		;7665
	cp 003h		;7667
	jr z,psg_escribe_todo		;7669
	ld a,(0c3dah)		;766b   ; todo apagado antes
	or 03fh		;766e
	ld e,a			;7670
	ld a,007h		;7671
	call 00093h		;7673
psg_escribe_todo:
	ld hl,0c3cah		;7676
	xor a			;7679
psg_escribe_reg:
	ld e,(hl)			;767a
	call 00093h		;767b   ; WRTPSG
	inc hl			;767e
	inc a			;767f
	cp 007h		;7680
	jr z,psg_escribe_vol		;7682
	cp 00eh		;7684
	jr nz,psg_escribe_reg		;7686
	ld a,(0c3d1h)		;7688   ; el registro 7, con los bits de E/S
	and 03fh		;768b
	ld e,a			;768d
	ld a,(0c3dah)		;768e
	or e			;7691
	ld e,a			;7692
	ld a,007h		;7693
	call 00093h		;7695
psg_escrito:
	xor a			;7698
	ld (0c3dbh),a		;7699
	ret			;769c
psg_escribe_vol:
	ld a,(0c3dbh)		;769d   ; que hay que escribir?
	cp 001h		;76a0   ; 1: solo el tono
	jr z,psg_escrito		;76a2
	cp 003h		;76a4   ; 3: tono y volumen del canal A
	jr nz,psg_escribe_sig		;76a6
	inc hl			;76a8   ; los volumenes...
	inc hl			;76a9
	ld a,009h		;76aa   ; ...del registro 9...
	ld e,(hl)			;76ac
	call 00093h		;76ad   ; WRTPSG
	inc hl			;76b0
	inc a			;76b1   ; ...y el 10
	ld e,(hl)			;76b2
	call 00093h		;76b3   ; WRTPSG
	jr psg_escrito		;76b6
psg_escribe_sig:
	inc hl			;76b8
	ld a,008h		;76b9
	jr psg_escribe_reg		;76bb
canal_nota:		; Pone en el canal C la nota HL: tono, ruido, volumen, envolvente, duracion y vibrato
	push bc			;76bd   ; se guardan
	push ix		;76be
	ld a,(0c3dbh)		;76c0   ; lo que habia que escribir
	push af			;76c3
	sub a			;76c4   ; nada mientras
	ld (0c3dbh),a		;76c5
	ld a,c			;76c8   ; el canal
	ld iy,0c3ach		;76c9   ; el canal A
	and a			;76cd
	jr z,canal_nota_ya		;76ce
	ld iy,0c3b6h		;76d0   ; el canal B
	cp 001h		;76d4
	jr z,canal_nota_ya		;76d6
	ld iy,0c3c0h		;76d8   ; el canal C
canal_nota_ya:
	ld a,h			;76dc
	or l			;76dd
	jr nz,canal_nota_lee		;76de   ; sin nota: silencio
	call canal_silencio		;76e0
	jp canal_nota_fin		;76e3
canal_nota_lee:
	ld (iy+000h),l		;76e6   ; donde va
	ld (iy+001h),h		;76e9
	ld a,(hl)			;76ec   ; los bits del mezclador
	and 03fh		;76ed
	ld (iy+003h),a		;76ef
	inc hl			;76f2
	ld a,(hl)			;76f3   ; el vibrato
	ld (iy+002h),a		;76f4
	inc hl			;76f7
	ld a,(hl)			;76f8   ; el tono bajo
	ld ix,0c3cah		;76f9
	ld b,000h		;76fd
	rlc c		;76ff
	add ix,bc		;7701
	rrc c		;7703
	ld (ix+000h),a		;7705
	inc hl			;7708
	ld a,(hl)			;7709   ; el alto y el volumen
	ld d,a			;770a
	and 0f0h		;770b
	rrca			;770d
	rrca			;770e
	rrca			;770f
	rrca			;7710
	ld (ix+001h),a		;7711
	inc hl			;7714
	ld e,(hl)			;7715   ; la envolvente
	inc hl			;7716
	ld a,d			;7717
	and 00fh		;7718
	ld ix,0c3cah		;771a
	bit 5,(hl)		;771e   ; con envolvente?
	jr z,canal_volumen		;7720
	ld (ix+00ch),e		;7722
	push bc			;7725
	rrc c		;7726
	rrc c		;7728
	or c			;772a
	pop bc			;772b
	ld (ix+00dh),a		;772c
	and 03fh		;772f
	set 7,(iy+009h)		;7731
	set 4,a		;7735
canal_volumen:
	set 3,c		;7737   ; el volumen
	add ix,bc		;7739
	ld (ix+000h),a		;773b
	ld a,(iy+003h)		;773e
	and 038h		;7741   ; con ruido?
	cp 038h		;7743
	ld a,(hl)			;7745
	jr z,canal_vibrato		;7746
	ld (0c3d0h),a		;7748   ; el ruido
canal_vibrato:
	inc hl			;774b
	ld a,(hl)			;774c   ; la velocidad del vibrato
	bit 7,(iy+002h)		;774d
	jr z,canal_vibrato_pon		;7751
	ld a,(iy+002h)		;7753
	and 01fh		;7756
canal_vibrato_pon:
	ld (iy+004h),a		;7758
	ld (iy+005h),a		;775b
	inc hl			;775e
	ld a,(hl)			;775f   ; la duracion
	ld (iy+006h),a		;7760
	inc hl			;7763
	ld a,(hl)			;7764
	ld (iy+007h),a		;7765
	call mezclador		;7768
canal_nota_fin:
	pop af			;776b
	ld (0c3dbh),a		;776c
	pop ix		;776f
	pop bc			;7771
	ret			;7772
canal_silencio:		; El canal C a cero; si los tres callan, se apaga todo
	push iy		;7773   ; la ficha del canal
	pop hl			;7775
	ld a,(0c3dah)		;7776   ; los bits de E/S...
	or 03fh		;7779   ; ...y todo apagado
	ld b,a			;777b
	push bc			;777c   ; se guarda
	xor a			;777d
	ld bc,0000ah		;777e   ; 10 bytes
	call rellena_bc		;7781   ; a cero
	pop bc			;7784
	ld (iy+003h),b		;7785   ; el mezclador del canal
	rlc c		;7788   ; x 2
	ld b,a			;778a
	ld hl,0c3cah		;778b   ; su tono a cero
	add hl,bc			;778e
	ld (hl),a			;778f
	inc hl			;7790
	ld (hl),a			;7791
	rrc c		;7792
	set 3,c		;7794
	ld b,a			;7796
	ld hl,0c3cah		;7797
	add hl,bc			;779a
	res 4,(hl)		;779b
	ld hl,0c3cah		;779d   ; quedan canales sonando?
	ld b,002h		;77a0
canal_silencio_mira:
	or (hl)			;77a2   ; algun volumen?
	inc hl			;77a3
	djnz canal_silencio_mira		;77a4   ; los tres
	and a			;77a6   ; si
	jr nz,canal_silencio_fin		;77a7   ; algun canal suena
	ld hl,0c3a4h		;77a9   ; no: las peticiones a cero
	ld bc,00003h		;77ac   ; 3 bytes
	call rellena_bc		;77af   ; la peticion a cero
	sub a			;77b2
	ld (0c3d2h),a		;77b3   ; los volumenes...
	ld (0c3d6h),a		;77b6   ; ...a cero
	ld a,(0c3dah)		;77b9   ; el registro 7...
	ld b,a			;77bc
	ld a,(0c3d1h)		;77bd
	and 03fh		;77c0
	or b			;77c2
	or 009h		;77c3   ; ...con todo apagado
	ld (0c3d1h),a		;77c5
canal_silencio_fin:
	ld a,002h		;77c8
	ld (0c3dbh),a		;77ca
	ret			;77cd
canales_cuadro:		; Cada canal: baja la duracion; al acabar, la nota siguiente; si no, el vibrato
	ld bc,00000h		;77ce
	ld iy,0c3ach		;77d1   ; canal A
canal_cuadro:
	push bc			;77d5
	ld hl,0c3cah		;77d6
	ld e,(iy+006h)		;77d9   ; la duracion
	ld a,(iy+007h)		;77dc
	ld d,a			;77df
	or e			;77e0
	jp z,canal_sig		;77e1   ; parado
	dec de			;77e4
	ld (iy+007h),d		;77e5
	ld (iy+006h),e		;77e8
	ld a,d			;77eb
	or e			;77ec
	jr z,canal_siguiente_nota		;77ed   ; acabada: la siguiente
	ld a,(iy+002h)		;77ef   ; con vibrato?
	and 0e0h		;77f2
	jp z,canal_sig		;77f4
	bit 7,(iy+002h)		;77f7
	call nz,canal_vibrato_paso		;77fb
	dec (iy+005h)		;77fe   ; su cuenta
	jr nz,canal_sig		;7801
	ld a,(iy+004h)		;7803
	ld (iy+005h),a		;7806
	bit 7,(iy+002h)		;7809   ; de ida y vuelta?
	jr z,canal_vibra		;780d
	ld a,(iy+002h)		;780f
	xor 060h		;7812
	ld (iy+002h),a		;7814
	jr canal_sig		;7817
canal_vibra:
	call canal_vibrato_paso		;7819
canal_sig:
	pop bc			;781c   ; el canal
	inc c			;781d   ; el siguiente
	ld a,003h		;781e
	cp c			;7820   ; los tres?
	jr z,canales_fin		;7821
	ld de,0000ah		;7823   ; 10 bytes
	add iy,de		;7826   ; la ficha siguiente
	jr canal_cuadro		;7828   ; otro
canales_fin:
	ret			;782a
canal_siguiente_nota:		; La nota siguiente esta 9 bytes despues; con el bit 7, una orden: fin o repetir
	ld l,(iy+000h)		;782b   ; la nota que suena...
	ld h,(iy+001h)		;782e
	push bc			;7831
	ld bc,00009h		;7832   ; ...9 bytes despues
	add hl,bc			;7835
	pop bc			;7836
L_7837:
	ld a,(hl)			;7837
	rlca			;7838   ; orden?
	jr c,canal_orden		;7839
	push iy		;783b
	push hl			;783d
	call canal_nota		;783e   ; la nota
	pop hl			;7841
	pop iy		;7842
	pop bc			;7844
	push bc			;7845
	ld a,c			;7846
	and a			;7847
	jr z,canal_siguiente_a		;7848
	ld a,(0c3dbh)		;784a
	cp 002h		;784d
	jr z,canal_sig		;784f
	ld a,003h		;7851
	ld (0c3dbh),a		;7853
	jr canal_sig		;7856
canal_siguiente_a:
	ld a,002h		;7858
	ld (0c3dbh),a		;785a
	jr canal_sig		;785d
canal_orden:
	rlca			;785f   ; bit 6: fin del canal
	jr nc,canal_repite		;7860
	push bc			;7862
	call canal_silencio		;7863
	call mezclador		;7866
	pop bc			;7869
	jr canal_sig		;786a
canal_repite:		; Repite el tramo (puntero de 2 bytes) las veces de los 5 bits bajos
	inc (iy+008h)		;786c   ; una vuelta mas
	ld a,(hl)			;786f   ; cuantas
	and 01fh		;7870
	cp (iy+008h)		;7872   ; acabadas?
	jr z,canal_repite_fin		;7875
	inc hl			;7877   ; el puntero...
	ld a,(hl)			;7878
	inc hl			;7879
	ld h,(hl)			;787a
	ld l,a			;787b   ; ...del tramo
	jr L_7837		;787c   ; sigue alli
canal_repite_fin:
	xor a			;787e
	ld (iy+008h),a		;787f   ; la cuenta a cero
	inc hl			;7882   ; tras la orden
	inc hl			;7883
	inc hl			;7884
	jr L_7837		;7885   ; sigue
canal_vibrato_paso:		; Suma o resta el vibrato al tono del canal
	ld a,(iy+002h)		;7887   ; el vibrato...
	and 01fh		;788a   ; ...cuanto
	ld e,a			;788c
	ld d,000h		;788d
	rlc c		;788f   ; el canal x 2
	add hl,bc			;7891   ; su tono
	push hl			;7892
	ld a,(hl)			;7893   ; el valor
	inc hl			;7894
	ld h,(hl)			;7895
	ld l,a			;7896
	bit 6,(iy+002h)		;7897   ; sube o baja?
	jr z,canal_vibrato_resta		;789b
	add hl,de			;789d   ; sube
	jr canal_vibrato_pon_tono		;789e
canal_vibrato_resta:
	sbc hl,de		;78a0
canal_vibrato_pon_tono:
	ex de,hl			;78a2   ; el tono nuevo
	pop hl			;78a3
	ld (hl),e			;78a4   ; guardado
	inc hl			;78a5
	ld (hl),d			;78a6
	dec hl			;78a7
	rrc c		;78a8   ; el canal
	ld a,(0c3dbh)		;78aa   ; ya hay que escribir?
	and a			;78ad
	ret nz			;78ae
	ld a,001h		;78af   ; 1: solo el tono
	ld (0c3dbh),a		;78b1
	ret			;78b4   ; listo
mezclador:		; El registro 7: los canales con tono y ruido de los tres juntos
	ld a,(0c3afh)		;78b5   ; el mezclador del canal A
	ld b,a			;78b8
	ld a,(0c3b9h)		;78b9   ; el del B
	ld c,a			;78bc
	ld a,(0c3c3h)		;78bd   ; el del C
	and b			;78c0   ; juntos
	and c			;78c1
	and 03fh		;78c2
	ld b,a			;78c4
	ld a,(0c3dah)		;78c5   ; los bits de E/S
	or b			;78c8
	ld (0c3d1h),a		;78c9   ; el registro 7
	ret			;78cc   ; listo

; ----------------------------------------------------------------------
; DATOS sin_uso_salto_planta: CODIGO SIN USO (88 bytes): lleva al agente y la
;   vista unas plantas arriba o abajo segun la tabla 0x7925 (una sola vez por
;   0xC36E). Nada salta a 0x78CD y en el cartucho no hay saltos indirectos
;   0x78cd..0x7925  (88 bytes)
DATA_sin_uso_salto_planta:
	defb 0ddh,021h,0d8h,0c0h,0ddh,0cbh,000h,04eh,0c2h,020h,079h,0ddh,0cbh,000h,056h,0c0h	; 78cd  .!.....N. y...V.
	defb 03ah,06eh,0c3h,0a7h,0c0h,03ch,032h,06eh,0c3h,03ah,0d3h,0c0h,0f5h,067h,02eh,006h	; 78dd  :n...<2n.:...g..
	defb 0cdh,0f0h,04dh,021h,025h,079h,04fh,087h,081h,04fh,006h,000h,009h,046h,03ah,0dah	; 78ed  ..M!%yO..O...F:.
	defb 0c0h,080h,032h,0dah,0c0h,023h,046h,023h,04eh,0f1h,080h,032h,0d3h,0c0h,021h,000h	; 78fd  ..2..#F#N..2..!.
	defb 000h,011h,020h,000h,047h,019h,03dh,020h,0fch,022h,0d1h,0c0h,03ah,06eh,0c3h,0cdh	; 790d  .. .G.= ."..:n..
	defb 08eh,044h,0c9h,0afh,032h,06eh,0c3h,0c9h	; 791d  .D..2n..

; ----------------------------------------------------------------------
; DATOS sin_uso_salto_tabla: Su tabla: Y, fila y vista para cada caso
;   0x7925..0x7937  (18 bytes)
DATA_sin_uso_salto_tabla:
	defb 000h,000h,000h,0f8h,0ffh,008h,0f0h,0feh,010h,0e8h,0fdh,018h,010h,002h,0f0h,008h	; 7925  ................
	defb 001h,0f8h	; 7935

; ======================================================================
; CODIGO 0x7937..0x79dd  (166 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  Los sprites a la VRAM  =====
; ----------------------------------------------------------------------
sprites_a_vram:		; Los 32 sprites a 0x3F00: un cuadro en orden, el siguiente al reves, para que parpadeen en vez de desaparecer
	ld a,(0c0d7h)		;7937   ; cuadro par o impar
	and a			;793a
	jr nz,sprites_en_orden		;793b
	inc a			;793d
	ld (0c0d7h),a		;793e
	ld de,0df7fh		;7941   ; al reves, en 0xDF80
	ld hl,0c003h		;7944
	ld a,020h		;7947
	ld bc,00008h		;7949
sprites_al_reves:
	push bc			;794c   ; la cuenta
	ld c,004h		;794d   ; 4 bytes
	lddr		;794f   ; hacia atras
	pop bc			;7951
	dec a			;7952   ; uno menos
	jr z,sprites_al_reves_fin		;7953
	add hl,bc			;7955   ; al sprite anterior
	jr sprites_al_reves		;7956   ; otro
sprites_en_orden:
	xor a			;7958
	ld (0c0d7h),a		;7959
	ld hl,0c000h		;795c
	jr sprites_copia		;795f
sprites_al_reves_fin:
	inc de			;7961
	ex de,hl			;7962
sprites_copia:
	ld bc,00080h		;7963
	ld de,03f00h		;7966
	call 0005ch		;7969
	ret			;796c

; ----------------------------------------------------------------------
; =====  El coche del sotano  =====
; ----------------------------------------------------------------------
coche_arranca:		; Guarda el trozo del mapa del sotano y anima el coche
	push iy		;796d
	ld hl,0dca0h		;796f   ; tres filas del mapa...
	ld de,0df80h		;7972   ; ...a 0xDF80
	ld bc,00060h		;7975
	ldir		;7978
	call coche_anima		;797a
	pop iy		;797d
	ret			;797f
coche_anima:		; Los dibujos del coche a 0x2100/0x2900 y 7 pasos del coche saliendo
	di			;7980
	ld bc,0c201h		;7981   ; registro 1 = 0xC2: sin interrupcion
	call escribe_vdp		;7984
	ld hl,07c67h		;7987   ; los dibujos
	ld de,02100h		;798a   ; a 0x2100
	ld bc,00100h		;798d   ; 256 bytes
	push hl			;7990
	push bc			;7991
	call 0005ch		;7992   ; LDIRVM
	pop bc			;7995
	pop hl			;7996
	ld de,02900h		;7997   ; y a 0x2900
	call 0005ch		;799a   ; LDIRVM
	ld bc,0e201h		;799d   ; imagen e interrupcion
	call escribe_vdp		;79a0
	ei			;79a3
	ld bc,00000h		;79a4
coche_paso:
	push bc			;79a7   ; el paso
	ld hl,07bf3h		;79a8   ; el trozo del paso
	sla c		;79ab   ; x 2
	add hl,bc			;79ad
	ld a,(hl)			;79ae   ; el puntero
	inc hl			;79af
	ld h,(hl)			;79b0
	ld l,a			;79b1
	ld de,0dca0h		;79b2   ; en el sotano
	pop bc			;79b5
	push bc			;79b6
	inc c			;79b7   ; su ancho
	ld a,003h		;79b8   ; 3 filas
	call pon_bloque_mezcla		;79ba   ; mezclado con el sotano
	pop bc			;79bd
	push bc			;79be
	ld hl,079ddh		;79bf   ; sus tres sprites
	ld de,0c020h		;79c2
	ld a,c			;79c5
	add a,a			;79c6
	add a,a			;79c7
	ld c,a			;79c8
	add a,a			;79c9
	add a,c			;79ca
	ld c,a			;79cb
	add hl,bc			;79cc
	ld bc,0000ch		;79cd
	ldir		;79d0
	call vuelca_y_espera		;79d2
	pop bc			;79d5
	ld a,006h		;79d6
	cp c			;79d8
	ret z			;79d9
	inc c			;79da
	jr coche_paso		;79db

; ----------------------------------------------------------------------
; DATOS coche_sprites: Los sprites del coche en cada paso (12 bytes)
;   0x79dd..0x7a31  (84 bytes)
DATA_coche_sprites:
	defb 09eh,015h,030h,081h,000h,000h,000h,000h,000h,000h,000h,000h,09eh,01dh,030h,081h	; 79dd  ..0...........0.
	defb 000h,000h,000h,000h,000h,000h,000h,000h,09eh,025h,030h,081h,092h,018h,028h,08fh	; 79ed  .........%0...(.
	defb 000h,000h,000h,000h,09eh,02dh,030h,081h,092h,020h,028h,08fh,000h,000h,000h,000h	; 79fd  .....-0.. (.....
	defb 09eh,035h,030h,081h,092h,028h,028h,08fh,0a0h,018h,02ch,081h,09eh,03dh,030h,081h	; 7a0d  .50..((...,..=0.
	defb 092h,030h,028h,08fh,0a0h,020h,02ch,081h,09eh,025h,030h,001h,092h,018h,028h,00fh	; 7a1d  .0(.. ,..%0...(.
	defb 0a0h,008h,02ch,001h	; 7a2d

; ======================================================================
; CODIGO 0x7a31..0x7bc9  (408 bytes)
; ======================================================================


vuelca_y_espera:		; Vuelca el mapa y espera 8 cuadros
	ld hl,0c0d0h		;7a31
	set 7,(hl)		;7a34
	xor a			;7a36
	ld b,008h		;7a37
	call pon_temporizador		;7a39
vuelca_espera:
	xor a			;7a3c
	call lee_temporizador		;7a3d
	and a			;7a40
	jr nz,vuelca_espera		;7a41
	ret			;7a43
agente_al_coche:		; Fin de ronda: el agente anda hasta el coche, se sube y el coche se va
	push ix		;7a44
	ld ix,0c0d8h		;7a46
	ld a,(0c001h)		;7a4a   ; la X del agente...
	srl a		;7a4d   ; ...en pasos de 4...
	srl a		;7a4f
	sub 008h		;7a51   ; ...menos 8: los pasos que le faltan
	ld b,a			;7a53
	set 7,(ix+000h)		;7a54   ; mirando a la izquierda
	call dibujos_del_lado		;7a58
	call agente_anda_n		;7a5b   ; andando
	ld a,00eh		;7a5e   ; el sonido 0x0E
	call sonido		;7a60
	xor a			;7a63
	ld (0c384h),a		;7a64
	ld hl,0c000h		;7a67   ; los sprites a cero
	ld bc,0000ch		;7a6a
	call rellena_bc		;7a6d
	ld de,0c02ch		;7a70   ; los del coche
	ld hl,07be3h		;7a73
	ld bc,00008h		;7a76
	ldir		;7a79
	res 7,(ix+000h)		;7a7b   ; mirando a la derecha
	call dibujos_del_lado		;7a7f
coche_avanza:		; 25 pasos de 8 cuadros: el coche entra por la izquierda con el agente dentro
	push bc			;7a82
	call espera_8		;7a83
	call piernas_fuera		;7a86   ; el dibujo de las piernas
	pop bc			;7a89
	inc c			;7a8a
	ld a,01ah		;7a8b   ; hasta el paso 26
	cp c			;7a8d
	jr z,coche_se_va		;7a8e
	ld hl,0df80h		;7a90   ; el trozo del sotano...
	ld de,0dca0h		;7a93   ; ...como estaba
	push bc			;7a96
	ld bc,00060h		;7a97
	ldir		;7a9a
	pop bc			;7a9c
	push bc			;7a9d
	ld de,07c43h		;7a9e   ; el coche...
	ld hl,0dca0h		;7aa1   ; ...un tile mas a la derecha
	add hl,bc			;7aa4
	ex de,hl			;7aa5
	ld bc,00006h		;7aa6
	ld a,003h		;7aa9
	call pon_bloque_mezcla		;7aab
	ld a,(0c384h)		;7aae   ; las ruedas giran
	xor 001h		;7ab1
	ld (0c384h),a		;7ab3
	pop bc			;7ab6
	push bc			;7ab7
	ld a,c			;7ab8   ; desde el segundo paso...
	cp 001h		;7ab9
	jr z,coche_vuelca		;7abb
	ld hl,0c021h		;7abd   ; ...los sprites 8 a la derecha
	ld de,00004h		;7ac0
	ld b,006h		;7ac3
coche_sprites_avanzan:
	ld a,008h		;7ac5
	add a,(hl)			;7ac7
	ld (hl),a			;7ac8
	add hl,de			;7ac9
	djnz coche_sprites_avanzan		;7aca
coche_vuelca:
	ld hl,0c0d0h		;7acc
	set 7,(hl)		;7acf
	pop bc			;7ad1
	ld a,002h		;7ad2   ; desde el tercero...
	cp c			;7ad4
	jr nc,coche_avanza		;7ad5
	ld hl,0c034h		;7ad7   ; ...el humo del tubo de escape
	ld (hl),09eh		;7ada
	inc hl			;7adc
	ld a,c			;7add
	dec a			;7ade
	add a,a			;7adf
	add a,a			;7ae0
	add a,a			;7ae1
	sub 008h		;7ae2
	ld (hl),a			;7ae4
	ld a,020h		;7ae5
	bit 0,c		;7ae7
	jr nz,coche_humo		;7ae9
	ld a,024h		;7aeb
coche_humo:
	inc hl			;7aed
	ld (hl),a			;7aee
	inc hl			;7aef
	ld (hl),00fh		;7af0
	jp coche_avanza		;7af2
coche_se_va:		; El coche, ya con el agente, sale por la derecha
	set 7,(ix+000h)		;7af5
	call dibujos_del_lado		;7af9
	ld hl,0c034h		;7afc   ; sin humo
	ld (hl),000h		;7aff
	inc hl			;7b01
	ld (hl),000h		;7b02
	inc hl			;7b04
	ld (hl),000h		;7b05
	ld hl,0c021h		;7b07   ; cinco sprites del agente en el coche
	ld de,00003h		;7b0a
	ld ix,07bd9h		;7b0d
	ld b,005h		;7b11
coche_se_va_sprite:
	ld a,(ix+000h)		;7b13   ; Y
	ld (hl),a			;7b16   ; a su sprite
	inc ix		;7b17
	inc hl			;7b19
	ld a,(ix+000h)		;7b1a   ; X
	ld (hl),a			;7b1d   ; a su sprite
	add hl,de			;7b1e   ; el siguiente
	inc ix		;7b1f
	djnz coche_se_va_sprite		;7b21   ; los 5
	ld hl,0c02eh		;7b23
coche_se_va_paso:
	push bc			;7b26
	call espera_8		;7b27
	pop bc			;7b2a
	dec c			;7b2b   ; hasta que la cuenta llega a 0
	jr z,coche_fin		;7b2c
	push bc			;7b2e
	ld hl,0df80h		;7b2f   ; el sotano como estaba
	ld de,0dca0h		;7b32
	push bc			;7b35
	ld bc,00060h		;7b36
	ldir		;7b39
	pop bc			;7b3b
	ld de,07c55h		;7b3c   ; el coche...
	ld hl,0dca0h		;7b3f
	add hl,bc			;7b42
	ex de,hl			;7b43
	ld bc,00006h		;7b44
	ld a,003h		;7b47
	call pon_bloque_mezcla		;7b49
	ld a,(0c384h)		;7b4c   ; las ruedas
	xor 001h		;7b4f
	ld (0c384h),a		;7b51
	ld hl,0c021h		;7b54   ; los sprites, 8 a la izquierda
	ld b,005h		;7b57
	ld de,00004h		;7b59
coche_se_va_sprites:
	ld a,0f8h		;7b5c   ; - 8
	add a,(hl)			;7b5e
	ld (hl),a			;7b5f   ; guardada
	add hl,de			;7b60   ; el siguiente
	djnz coche_se_va_sprites		;7b61   ; los 5
	ld hl,0c0d0h		;7b63
	set 7,(hl)		;7b66   ; volcar
	pop bc			;7b68
	jr coche_se_va_paso		;7b69
coche_fin:
	pop ix		;7b6b
	ret			;7b6d
pon_bloque_mezcla:		; Pone el bloque HL (A filas de C) en DE; donde el bloque tiene 0 o el mapa no esta vacio, se mezcla (+0x20)
	ld b,c			;7b6e
pon_bloque_mezcla_fila:
	push af			;7b6f
	push bc			;7b70
	push de			;7b71
pon_bloque_mezcla_tile:
	ld a,(de)			;7b72
	ld c,a			;7b73
	ld a,(hl)			;7b74
	ld (de),a			;7b75
	cp 0e0h		;7b76   ; tiles 0xE0 a 0xE7: tal cual
	jr c,pon_bloque_mezcla_vacio		;7b78
	cp 0e8h		;7b7a
	jr c,pon_bloque_mezcla_sig		;7b7c
pon_bloque_mezcla_vacio:
	ld a,c			;7b7e
	cp 03bh		;7b7f   ; encima de un vacio (0x3B)...
	jr nz,pon_bloque_mezcla_sig		;7b81
	ld a,(hl)			;7b83
	cp 070h		;7b84   ; ...0x70 pasa a 0x1B...
	jr nz,pon_bloque_mezcla_suma		;7b86
	ld a,01bh		;7b88
pon_bloque_mezcla_suma:
	add a,020h		;7b8a   ; ...y se le suma 0x20
	ld (de),a			;7b8c
pon_bloque_mezcla_sig:
	inc hl			;7b8d   ; el siguiente
	inc de			;7b8e
	djnz pon_bloque_mezcla_tile		;7b8f   ; la fila
	pop de			;7b91
	ld bc,00020h		;7b92   ; + 32
	push hl			;7b95
	ex de,hl			;7b96
	add hl,bc			;7b97
	ex de,hl			;7b98
	pop hl			;7b99
	pop bc			;7b9a
	pop af			;7b9b
	dec a			;7b9c   ; una fila menos
	cp 001h		;7b9d   ; queda la ultima?
	jr nz,pon_bloque_mezcla_fila		;7b9f
pon_bloque_ultima_fila:
	ld a,(hl)			;7ba1   ; la ultima tal cual
	ld (de),a			;7ba2
	inc hl			;7ba3
	inc de			;7ba4
	djnz pon_bloque_ultima_fila		;7ba5   ; las B
	ret			;7ba7   ; listo
piernas_fuera:		; Dos bytes de los dibujos de las piernas a 0x204E y 0x285E: el agente sin piernas (tras el escalon o en el coche)
	ld hl,07bebh		;7ba8
	jr piernas_al_vdp		;7bab
piernas_dentro:		; Las piernas otra vez
	ld hl,07befh		;7bad
piernas_al_vdp:
	ld de,0204eh		;7bb0   ; en la tabla normal
	ld bc,00002h		;7bb3   ; 2 bytes
	push hl			;7bb6
	push bc			;7bb7
	di			;7bb8
	call 0005ch		;7bb9   ; LDIRVM
	di			;7bbc
	pop bc			;7bbd
	pop hl			;7bbe
	inc hl			;7bbf
	inc hl			;7bc0
	ld de,0285eh		;7bc1   ; y en la dada la vuelta
	call 0005ch		;7bc4   ; LDIRVM
	ei			;7bc7   ; interrupciones
	ret			;7bc8

; ----------------------------------------------------------------------
; DATOS coche_resto: Restos sin leer de la tabla de sprites del coche
;   0x7bc9..0x7bd9  (16 bytes)
DATA_coche_resto:
	defb 0a4h,008h,028h,00fh,0a4h,01ch,028h,00fh,0a0h,02eh,02ch,00fh,090h,018h,020h,00fh	; 7bc9  ..(...(...,... .

; ----------------------------------------------------------------------
; DATOS coche_agente: El agente en el coche: 5 pares (Y, X)
;   0x7bd9..0x7be3  (10 bytes)
DATA_coche_agente:
	defb 0d2h,03ch,0e0h,034h,0f0h,038h,0e4h,004h,0e4h,008h	; 7bd9  .<.4.8....

; ----------------------------------------------------------------------
; DATOS coche_sprites_0: Los dos sprites del coche al entrar
;   0x7be3..0x7beb  (8 bytes)
DATA_coche_sprites_0:
	defb 090h,014h,004h,006h,098h,014h,008h,00bh	; 7be3  ........

; ----------------------------------------------------------------------
; DATOS piernas_bytes: Los dos bytes de las piernas: sin y con
;   0x7beb..0x7bf3  (8 bytes)
DATA_piernas_bytes:
	defb 000h,000h,000h,000h,00ch,004h,030h,020h	; 7beb  ......0 

; ----------------------------------------------------------------------
; DATOS coche_trozos: Los 7 dibujos del coche entrando (puntero a cada uno)
;   0x7bf3..0x7c01  (14 bytes)
DATA_coche_trozos:
	defb 001h,07ch,004h,07ch,00ah,07ch,013h,07ch,01fh,07ch,043h,07ch,02eh,07ch	; 7bf3  .|.|.|.|.|C|.|

; ----------------------------------------------------------------------
; DATOS coche_trozos_d: Los dibujos: ancho, alto y tiles
;   0x7c01..0x7c67  (102 bytes)
DATA_coche_trozos_d:
	defb 070h,0ceh,0d4h,0cfh,070h,0cdh,0ceh,0d3h,0d4h,0cbh,0cfh,070h,0e0h,0cdh,0ceh,0d2h	; 7c01  p...p......p....
	defb 0d3h,0d4h,0cah,0cbh,0cfh,070h,0e1h,0e0h,0cdh,0ceh,0d2h,0d2h,0d3h,0d4h,0c9h,0cah	; 7c11  .....p..........
	defb 0cbh,0cfh,070h,0e0h,0e1h,0e0h,0cdh,0ceh,0d1h,0d2h,0d2h,0d3h,0d4h,070h,0c8h,0c9h	; 7c21  ..p..........p..
	defb 0cah,0cbh,0cfh,070h,070h,0cch,0e0h,0e1h,0e0h,0cdh,0ceh,06bh,0d0h,0d1h,0d2h,0d2h	; 7c31  ...pp......k....
	defb 0d3h,0d4h,0c8h,0c9h,0cah,0cbh,0cfh,070h,0cch,0e0h,0e1h,0e0h,0cdh,0ceh,0d0h,0d1h	; 7c41  .......p........
	defb 0d2h,0d2h,0d3h,0d4h,070h,0dfh,0dbh,0dah,0d9h,0d8h,0deh,0ddh,0e2h,0e3h,0e2h,0dch	; 7c51  ....p...........
	defb 0d5h,0d6h,0d2h,0d2h,0d7h,0f0h	; 7c61

; ----------------------------------------------------------------------
; DATOS coche_dibujos: 8 sprites de 16 x 16 del coche: humo y ruedas
;   0x7c67..0x7d67  (256 bytes)
DATA_coche_dibujos:
	defb 007h,00ch,028h,040h,04dh,019h,019h,038h,06ch,066h,030h,01ch,000h,000h,000h,000h	; 7c67  ..(@M..8lf0.....
	defb 000h,080h,000h,0e0h,090h,000h,00fh,040h,097h,08ch,0c0h,070h,000h,000h,000h,000h	; 7c77  .......@...p....
	defb 000h,001h,003h,004h,000h,003h,006h,004h,006h,003h,000h,000h,000h,000h,000h,000h	; 7c87  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 7c97  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,080h	; 7ca7  ................
	defb 000h,000h,000h,000h,000h,000h,040h,000h,000h,000h,000h,000h,006h,001h,000h,000h	; 7cb7  ......@.........
	defb 000h,000h,000h,000h,000h,000h,000h,0e3h,0e6h,00ch,00ch,00ch,006h,003h,000h,000h	; 7cc7  ................
	defb 000h,000h,000h,000h,000h,000h,000h,0c0h,060h,030h,030h,030h,060h,0c0h,000h,000h	; 7cd7  ........`000`...
	defb 000h,0c0h,060h,000h,000h,000h,000h,000h,000h,003h,006h,00ch,00ch,00ch,006h,003h	; 7ce7  ..`.............
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,0c7h,067h,030h,030h,030h,060h,0c0h	; 7cf7  ..........g000`.
	defb 000h,000h,000h,000h,000h,000h,002h,000h,000h,000h,000h,000h,060h,080h,000h,001h	; 7d07  ............`...
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h	; 7d17  ................
	defb 000h,000h,000h,000h,000h,000h,000h,003h,006h,00ch,00ch,00ch,006h,003h,000h,000h	; 7d27  ................
	defb 000h,000h,000h,000h,000h,000h,000h,0c7h,067h,030h,030h,030h,060h,0c0h,000h,000h	; 7d37  ........g000`...
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,0e3h,0e6h,00ch,00ch,00ch,006h,003h	; 7d47  ................
	defb 000h,003h,006h,000h,000h,000h,000h,000h,000h,0c0h,060h,030h,030h,030h,060h,0c0h	; 7d57  ..........`000`.

; ======================================================================
; CODIGO 0x7d67..0x7f03  (412 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; =====  Las luces y la lampara  =====
; ----------------------------------------------------------------------
luces_cuadro:		; Lampara rota: cae (0xC39B), y a los 10 cuadros el edificio se queda a oscuras 240 cuadros
	ld a,(0c385h)		;7d67   ; 0xC385: 0 con luz, 1 rota, 2 cayendo, 3 a oscuras
	and a			;7d6a
	ret z			;7d6b
	cp 002h		;7d6c
	jr z,luces_apaga		;7d6e
	jr nc,luces_vuelven		;7d70
	ld a,002h		;7d72   ; empieza a caer
	ld (0c385h),a		;7d74
	dec a			;7d77
	ld (0c39bh),a		;7d78
	ld a,01eh		;7d7b   ; temporizador 0x1E: 10 cuadros
	ld b,00ah		;7d7d
	call pon_temporizador		;7d7f
	ret			;7d82
luces_apaga:
	ld a,01eh		;7d83
	call lee_temporizador		;7d85
	jr nz,luces_lampara		;7d88
	ld bc,0c201h		;7d8a
	call escribe_vdp		;7d8d
	ld hl,08d78h		;7d90   ; los colores de oscuras
	ld de,03fc0h		;7d93
	ld bc,00020h		;7d96
	call 0005ch		;7d99
	ld bc,0e201h		;7d9c
	call escribe_vdp		;7d9f
	ld a,003h		;7da2   ; a oscuras...
	ld (0c385h),a		;7da4
	ld a,01eh		;7da7   ; ...240 cuadros
	ld b,0f0h		;7da9
	call pon_temporizador		;7dab
luces_lampara:
	ld a,(0c39bh)		;7dae   ; la lampara cae?
	and a			;7db1
	call nz,lampara_cae		;7db2
	ret			;7db5
luces_vuelven:
	ld a,01eh		;7db6
	call lee_temporizador		;7db8
	jr nz,luces_lampara		;7dbb
	ld bc,0c201h		;7dbd
	call escribe_vdp		;7dc0
	ld hl,(0c386h)		;7dc3   ; los colores de la ronda
	ld de,03fc0h		;7dc6
	ld bc,00020h		;7dc9
	call 0005ch		;7dcc
	ld bc,0e201h		;7dcf
	call escribe_vdp		;7dd2
	xor a			;7dd5   ; con luz
	ld (0c385h),a		;7dd6
	ret			;7dd9
lampara_cae:		; La lampara cae en 4 pasos de 16 cuadros, 8 pixeles cada uno (sprites 25 y 26)
	ld ix,0c39bh		;7dda
	ld iy,0c064h		;7dde   ; sus sprites
	ld a,(ix+000h)		;7de2
	cp 001h		;7de5   ; el primer paso?
	jr z,lampara_empieza		;7de7
	ld a,01fh		;7de9   ; temporizador 0x1F
	call lee_temporizador		;7deb
	ret nz			;7dee
	ld a,(ix+000h)		;7def
	cp 005h		;7df2   ; el quinto: se acaba
	jp z,lampara_fin		;7df4
	jr lampara_paso		;7df7
lampara_empieza:
	ld a,01fh		;7df9
	ld b,010h		;7dfb
	call pon_temporizador		;7dfd
	ld c,(ix+002h)		;7e00   ; la Y de la bala que la rompio...
	ld a,008h		;7e03
	add a,c			;7e05
	ld c,a			;7e06
	ld a,(ix+001h)		;7e07   ; de que lado
	or a			;7e0a
	jr nz,lampara_der		;7e0b
	ld e,048h		;7e0d   ; X 0x48
	jr lampara_sprites		;7e0f
lampara_der:
	ld e,0a8h		;7e11   ; X 0xA8
lampara_sprites:
	ld (iy+000h),c		;7e13   ; Y
	ld (iy+001h),e		;7e16   ; X
	ld (iy+002h),0d8h		;7e19   ; dibujo 0xD8
	ld (iy+003h),009h		;7e1d   ; color 9
	ld (iy+004h),c		;7e21   ; el otro sprite, en el mismo sitio
	ld (iy+005h),e		;7e24
	ld (iy+006h),0d0h		;7e27   ; dibujo 0xD0
	ld (iy+007h),00dh		;7e2b   ; color 0x0D
	ld a,00fh		;7e2f   ; el sonido 0x0F
	call sonido		;7e31   ; pedido
	jr lampara_paso_sig		;7e34   ; el paso siguiente
lampara_paso:
	ld a,01fh		;7e36   ; temporizador 0x1F...
	ld b,010h		;7e38   ; ...16 cuadros
	call pon_temporizador		;7e3a
	ld a,(ix+001h)		;7e3d   ; de que lado
	or a			;7e40
	jr nz,lampara_paso_der		;7e41
	ld e,048h		;7e43   ; X 0x48
	jr lampara_paso_dibujo		;7e45
lampara_paso_der:
	ld e,0a8h		;7e47
lampara_paso_dibujo:
	bit 0,(ix+000h)		;7e49   ; dos dibujos alternos
	jr z,lampara_paso_dibujo2		;7e4d
	ld d,0d8h		;7e4f
	jr lampara_paso_baja		;7e51
lampara_paso_dibujo2:
	ld d,0d4h		;7e53
lampara_paso_baja:
	ld a,008h		;7e55   ; 8 mas abajo
	add a,(iy+000h)		;7e57
	ld (iy+000h),a		;7e5a
	ld (iy+001h),e		;7e5d
	ld (iy+002h),d		;7e60
	ld (iy+003h),009h		;7e63
	ld (iy+004h),a		;7e67
	ld (iy+005h),e		;7e6a
	ld (iy+006h),0d0h		;7e6d
	ld (iy+007h),00dh		;7e71
lampara_paso_sig:
	inc (ix+000h)		;7e75
lampara_ret:
	ret			;7e78
lampara_fin:
	ld (ix+000h),000h		;7e79
	ld (ix+001h),000h		;7e7d
	ld (ix+002h),000h		;7e81
	ld b,008h		;7e85
lampara_borra:
	ld (iy+000h),000h		;7e87
	inc iy		;7e8b
	djnz lampara_borra		;7e8d
	jr lampara_ret		;7e8f

; ----------------------------------------------------------------------
; =====  El edificio  =====
; ----------------------------------------------------------------------
dibuja_edificio:		; El mapa entero del edificio: la antena y el tejado, las plantas (tabla 0x7F8D), el sotano y los numeros de planta
	ld hl,0c400h		;7e91   ; las primeras filas, vacias
	sub a			;7e94
	ld bc,000eeh		;7e95
	call rellena_bc		;7e98
	ld hl,07f03h		;7e9b   ; la antena
	ld bc,00004h		;7e9e
	ldir		;7ea1
	sub a			;7ea3
	push de			;7ea4
	pop hl			;7ea5
	ld bc,0000eh		;7ea6
	call rellena_bc		;7ea9
	ld hl,07f8dh		;7eac   ; las piezas del edificio
	call pon_piezas		;7eaf
	call fila_de_suelo		;7eb2   ; una fila de suelo
	ld a,00ah		;7eb5   ; dos filas de tejado (0x0A)
	ld bc,00040h		;7eb7
	push de			;7eba
	pop hl			;7ebb
	call rellena_bc		;7ebc
	ld a,06ah		;7ebf   ; la pared del sotano (0x6A)...
	ld de,00020h		;7ec1
	ld hl,0cc84h		;7ec4   ; ...tres filas
	ld b,003h		;7ec7
pared_sotano:
	ld (hl),a			;7ec9
	add hl,de			;7eca
	djnz pared_sotano		;7ecb
	ld hl,0c5d8h		;7ecd   ; el numero 30 (tiles 0xB3, 0xB0)...
	ld bc,009b9h		;7ed0
	ld de,000bfh		;7ed3
	ld (hl),0b3h		;7ed6
	inc hl			;7ed8
	ld (hl),0b0h		;7ed9
	ld a,0b2h		;7edb
numero_planta:		; Los numeros de planta: decenas y unidades bajando de 6 en 6 filas
	add hl,de			;7edd   ; 6 filas mas abajo
	ld (hl),0b2h		;7ede
	inc hl			;7ee0
	ld (hl),c			;7ee1
	dec c			;7ee2
	djnz numero_planta		;7ee3
	ld hl,0cd5dh		;7ee5   ; las plantas de la derecha
numeros_lado:
	cp 0bah		;7ee8   ; hasta la 1
	ret z			;7eea
	ld (hl),a			;7eeb
	inc hl			;7eec
	ld (hl),0b0h		;7eed
	dec a			;7eef
	cp 0b0h		;7ef0
	jr nz,numeros_decena		;7ef2
	ld a,0bah		;7ef4
numeros_decena:
	ld bc,009b9h		;7ef6
numeros_unidad:
	add hl,de			;7ef9   ; 6 filas mas abajo
	ld (hl),a			;7efa   ; las decenas
	inc hl			;7efb
	ld (hl),c			;7efc   ; las unidades
	dec c			;7efd   ; una menos
	djnz numeros_unidad		;7efe   ; las 9
	add hl,de			;7f00
	jr numeros_lado		;7f01   ; la decena siguiente

; ----------------------------------------------------------------------
; DATOS antena: La antena del tejado
;   0x7f03..0x7f07  (4 bytes)
DATA_antena:
	defb 02bh,00ah,00ah,02ch	; 7f03

; ======================================================================
; CODIGO 0x7f07..0x7f72  (107 bytes)
; ======================================================================


pon_piezas:		; Lista de piezas (cuantas veces, y cuantas y cuales); cada vuelta 5 filas mas abajo; 0xFF acaba
	push bc			;7f07
pon_piezas_lista:
	ld a,(hl)			;7f08   ; cuantas veces
	cp 0ffh		;7f09   ; fin?
	jr z,pon_piezas_fin		;7f0b
	ld c,a			;7f0d   ; en C
	sub a			;7f0e
	inc hl			;7f0f   ; la lista
pon_piezas_vuelta:
	push hl			;7f10
	ld b,(hl)			;7f11
pon_piezas_una:
	push bc			;7f12   ; la cuenta
	inc hl			;7f13
	ld c,(hl)			;7f14   ; la pieza
	inc hl			;7f15
	ld b,(hl)			;7f16
	push hl			;7f17
	push bc			;7f18
	pop hl			;7f19
	call pon_pieza		;7f1a   ; puesta
	pop hl			;7f1d
	pop bc			;7f1e
	djnz pon_piezas_una		;7f1f   ; las B
	push hl			;7f21
	ld hl,000a0h		;7f22   ; 5 filas mas abajo
	add hl,de			;7f25
	ex de,hl			;7f26
	dec c			;7f27
	jr z,pon_piezas_sig		;7f28
	pop hl			;7f2a
	pop hl			;7f2b
	jr pon_piezas_vuelta		;7f2c
pon_piezas_sig:
	pop hl			;7f2e
	inc hl			;7f2f
	pop bc			;7f30
	jp pon_piezas_lista		;7f31
pon_piezas_fin:
	pop bc			;7f34
	ret			;7f35
fila_de_suelo:		; 32 piezas de suelo (0x850E) y 5 filas mas abajo
	ld b,020h		;7f36
fila_de_suelo_sig:
	ld hl,0850eh		;7f38   ; la pieza de suelo
	call pon_pieza		;7f3b   ; puesta
	djnz fila_de_suelo_sig		;7f3e   ; las 32
	ld hl,000a0h		;7f40   ; 5 filas mas abajo
	add hl,de			;7f43
	ex de,hl			;7f44
	ret			;7f45   ; listo
pon_pieza:		; Pone la pieza HL en DE y avanza DE su ancho
	push de			;7f46   ; se guarda
	call pon_tira		;7f47   ; la tira
	pop de			;7f4a
	ld l,a			;7f4b   ; el ancho...
	ld h,000h		;7f4c
	add hl,de			;7f4e   ; ...se suma a DE
	ex de,hl			;7f4f
	ret			;7f50   ; listo
pon_tira:		; Pone en DE una pieza: ancho y filas hasta 0xFF
	push bc			;7f51
	ld a,(hl)			;7f52   ; el ancho
	cp 0ffh		;7f53   ; nada?
	jr z,pon_tira_fin		;7f55
	ld c,a			;7f57   ; en BC
	ld b,000h		;7f58
	push bc			;7f5a
	inc hl			;7f5b
pon_tira_fila:
	push bc			;7f5c   ; el ancho
	ldir		;7f5d   ; una fila
	ex de,hl			;7f5f
	ld bc,00020h		;7f60   ; + 32...
	add hl,bc			;7f63
	pop bc			;7f64
	and a			;7f65
	sbc hl,bc		;7f66   ; ...- el ancho
	ex de,hl			;7f68
	ld a,(hl)			;7f69   ; otra?
	cp 0ffh		;7f6a
	jr nz,pon_tira_fila		;7f6c   ; si
pon_tira_fin:
	pop bc			;7f6e
	ld a,c			;7f6f
	pop bc			;7f70
	ret			;7f71

; ----------------------------------------------------------------------
; DATOS sin_uso_pon_lista: CODIGO SIN USO (27 bytes): pone una lista de piezas
;   con pon_tira. Nada salta a 0x7F72 y no hay saltos indirectos
;   0x7f72..0x7f8d  (27 bytes)
DATA_sin_uso_pon_lista:
	defb 07eh,0feh,0ffh,028h,015h,047h,0c5h,0e5h,023h,04eh,023h,046h,0c5h,0e1h,0cdh,051h	; 7f72  ~..(.G..#N#F...Q
	defb 07fh,0e1h,0c1h,010h,0f1h,023h,023h,023h,018h,0e6h,0c9h	; 7f82  .....###...

; ----------------------------------------------------------------------
; DATOS edificio_plantas: Las plantas del edificio: por tramo, cuantas veces
;   se repite y las piezas que lleva
;   0x7f8d..0x83ee  (1121 bytes)
DATA_edificio_plantas:
	defb 001h,01ch,076h,083h,076h,083h,076h,083h,076h,083h,0b6h,083h,0deh,083h,0deh,083h	; 7f8d  ..v.v.v.v.......
	defb 0deh,083h,0deh,083h,0deh,083h,0deh,083h,0deh,083h,0aeh,083h,0aeh,083h,0aeh,083h	; 7f9d  ................
	defb 0e6h,083h,0deh,083h,0deh,083h,0deh,083h,0deh,083h,0deh,083h,0deh,083h,0cah,083h	; 7fad  ................
	defb 076h,083h,076h,083h,076h,083h,076h,083h,076h,083h,001h,018h,076h,083h,076h,083h	; 7fbd  v.v.v.v.v...v.v.
	defb 076h,083h,076h,083h,0f6h,083h,012h,084h,032h,084h,022h,084h,032h,084h,012h,084h	; 7fcd  v.v.....2.".2...
	defb 012h,084h,09ah,083h,012h,084h,012h,084h,040h,084h,022h,084h,040h,084h,012h,084h	; 7fdd  ........@.".@...
	defb 004h,084h,076h,083h,076h,083h,076h,083h,076h,083h,076h,083h,008h,018h,076h,083h	; 7fed  ..v.v.v.v.v...v.
	defb 076h,083h,076h,083h,076h,083h,0f6h,083h,012h,084h,032h,084h,022h,084h,032h,084h	; 7ffd  v.v.v.....2.".2.
	defb 012h,084h,012h,084h,09ah,083h,012h,084h,012h,084h,040h,084h,022h,084h,040h,084h	; 800d  ..........@.".@.
	defb 012h,084h,004h,084h,076h,083h,076h,083h,076h,083h,076h,083h,076h,083h,001h,015h	; 801d  ....v.v.v.v.v...
	defb 0b6h,083h,0deh,083h,0deh,083h,0eeh,083h,012h,084h,032h,084h,022h,084h,032h,084h	; 802d  ..........2.".2.
	defb 012h,084h,012h,084h,09ah,083h,012h,084h,012h,084h,040h,084h,022h,084h,040h,084h	; 803d  ..........@.".@.
	defb 012h,084h,004h,084h,0deh,083h,0deh,083h,0cah,083h,001h,015h,0eeh,083h,0feh,084h	; 804d  ................
	defb 056h,084h,064h,084h,012h,084h,032h,084h,022h,084h,032h,084h,012h,084h,012h,084h	; 805d  V.d...2.".2.....
	defb 09ah,083h,012h,084h,012h,084h,032h,084h,04eh,084h,040h,084h,012h,084h,0aah,084h	; 806d  ......2.N.@.....
	defb 0b8h,084h,0feh,084h,004h,084h,001h,017h,0eeh,083h,0feh,084h,072h,084h,080h,084h	; 807d  ............r...
	defb 01ah,084h,032h,084h,022h,084h,032h,084h,012h,084h,012h,084h,02ah,084h,02ah,084h	; 808d  ..2.".2.....*.*.
	defb 02ah,084h,012h,084h,012h,084h,040h,084h,022h,084h,040h,084h,01ah,084h,0c6h,084h	; 809d  *.....@.".@.....
	defb 0d4h,084h,0feh,084h,004h,084h,001h,015h,0eeh,083h,0feh,084h,072h,084h,080h,084h	; 80ad  ............r...
	defb 01ah,084h,032h,084h,022h,084h,032h,084h,012h,084h,032h,084h,04eh,084h,040h,084h	; 80bd  ..2.".2...2.N.@.
	defb 012h,084h,040h,084h,022h,084h,040h,084h,01ah,084h,0c6h,084h,0d4h,084h,0feh,084h	; 80cd  ..@.".@.........
	defb 004h,084h,001h,015h,0eeh,083h,012h,084h,09ch,084h,08eh,084h,01ah,084h,032h,084h	; 80dd  ..............2.
	defb 022h,084h,032h,084h,012h,084h,012h,084h,09ah,083h,012h,084h,012h,084h,040h,084h	; 80ed  ".2...........@.
	defb 022h,084h,040h,084h,01ah,084h,0c6h,084h,0d4h,084h,0feh,084h,004h,084h,001h,016h	; 80fd  ".@.............
	defb 0eeh,083h,012h,084h,012h,084h,012h,084h,032h,084h,012h,084h,032h,084h,022h,084h	; 810d  ........2...2.".
	defb 032h,084h,012h,084h,012h,084h,09ah,083h,012h,084h,012h,084h,040h,084h,022h,084h	; 811d  2...........@.".
	defb 040h,084h,01ah,084h,0e2h,084h,0f0h,084h,012h,084h,004h,084h,001h,01dh,0eeh,083h	; 812d  @...............
	defb 02ah,084h,086h,083h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h	; 813d  *...*.*.*.*.*.*.
	defb 02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h	; 814d  *.*.*.*.*.*.*.*.
	defb 02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h	; 815d  *.*.*.*.*.*.*.*.
	defb 02ah,084h,02ah,084h,02ah,084h,004h,084h,001h,01dh,0eeh,083h,02ah,084h,09ah,083h	; 816d  *.*.*.......*...
	defb 02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h	; 817d  *.*.*.*.*.*.*.*.
	defb 02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h	; 818d  *.*.*.*.*.*.*.*.
	defb 02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h	; 819d  *.*.*.*.*.*.*.*.
	defb 02ah,084h,004h,084h,001h,01dh,0eeh,083h,02ah,084h,02ah,084h,02ah,084h,02ah,084h	; 81ad  *.......*.*.*.*.
	defb 02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h	; 81bd  *.*.*.*.*.*.*.*.
	defb 02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h	; 81cd  *.*.*.*.*.*.*.*.
	defb 02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,086h,083h,02ah,084h,004h,084h	; 81dd  *.*.*.*.*...*...
	defb 001h,01bh,0eeh,083h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h	; 81ed  ....*.*.*.*.*.*.
	defb 02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,09ah,083h	; 81fd  *.*.*.*.*.*.*...
	defb 02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h	; 820d  *.*.*.*.*.*.*.*.
	defb 02ah,084h,086h,083h,02ah,084h,004h,084h,001h,019h,0eeh,083h,02ah,084h,086h,083h	; 821d  *...*.......*...
	defb 02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h	; 822d  *.*.*.*.*.*.*.*.
	defb 02ah,084h,09ah,083h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h,02ah,084h	; 823d  *...*.*.*.*.*.*.
	defb 02ah,084h,02ah,084h,02ah,084h,09ah,083h,02ah,084h,004h,084h,001h,017h,0eeh,083h	; 824d  *.*.*...*.......
	defb 012h,084h,09ah,083h,012h,084h,012h,084h,032h,084h,022h,084h,032h,084h,012h,084h	; 825d  ........2.".2...
	defb 012h,084h,02ah,084h,02ah,084h,02ah,084h,012h,084h,012h,084h,040h,084h,022h,084h	; 826d  ..*.*.*.....@.".
	defb 040h,084h,012h,084h,012h,084h,09ah,083h,012h,084h,004h,084h,002h,015h,0eeh,083h	; 827d  @...............
	defb 012h,084h,09ah,083h,012h,084h,012h,084h,032h,084h,022h,084h,032h,084h,012h,084h	; 828d  ........2.".2...
	defb 032h,084h,012h,084h,040h,084h,012h,084h,040h,084h,022h,084h,040h,084h,012h,084h	; 829d  2...@...@.".@...
	defb 012h,084h,09ah,083h,012h,084h,004h,084h,001h,017h,0eeh,083h,012h,084h,02ah,084h	; 82ad  ..............*.
	defb 02ah,084h,02ah,084h,012h,084h,086h,083h,012h,084h,086h,083h,012h,084h,012h,084h	; 82bd  *.*.............
	defb 012h,084h,012h,084h,012h,084h,086h,083h,012h,084h,09ah,083h,012h,084h,02ah,084h	; 82cd  ..............*.
	defb 02ah,084h,02ah,084h,012h,084h,004h,084h,001h,015h,0eeh,083h,012h,084h,032h,084h	; 82dd  *.*...........2.
	defb 012h,084h,012h,084h,086h,083h,012h,084h,086h,083h,012h,084h,012h,084h,012h,084h	; 82ed  ................
	defb 012h,084h,012h,084h,086h,083h,012h,084h,09ah,083h,012h,084h,012h,084h,040h,084h	; 82fd  ..............@.
	defb 012h,084h,004h,084h,004h,013h,0eeh,083h,012h,084h,032h,084h,012h,084h,012h,084h	; 830d  ..........2.....
	defb 09ah,083h,012h,084h,09ah,083h,012h,084h,09ah,083h,012h,084h,09ah,083h,012h,084h	; 831d  ................
	defb 09ah,083h,012h,084h,012h,084h,040h,084h,012h,084h,004h,084h,001h,01dh,0eeh,083h	; 832d  ......@.........
	defb 012h,084h,032h,084h,012h,084h,012h,084h,02ah,084h,02ah,084h,02ah,084h,012h,084h	; 833d  ..2.....*.*.*...
	defb 02ah,084h,02ah,084h,02ah,084h,012h,084h,02ah,084h,02ah,084h,02ah,084h,012h,084h	; 834d  *.*.*...*.*.*...
	defb 02ah,084h,02ah,084h,02ah,084h,012h,084h,02ah,084h,02ah,084h,02ah,084h,012h,084h	; 835d  *.*.*...*.*.*...
	defb 012h,084h,040h,084h,012h,084h,004h,084h,0ffh,001h,000h,000h,000h,000h,000h,000h	; 836d  ..@.............
	defb 0ffh,001h,028h,028h,028h,028h,028h,060h,0ffh,003h,02dh,028h,02dh,02dh,028h,02dh	; 837d  ..(((((`..-(--(-
	defb 02dh,028h,02dh,02dh,028h,02dh,02dh,028h,02dh,02dh,028h,02dh,0ffh,003h,02dh,02dh	; 838d  -(--(--(--(-..--
	defb 02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh	; 839d  ----------------
	defb 0ffh,001h,03bh,03bh,03bh,03bh,03bh,060h,0ffh,003h,000h,000h,000h,000h,000h,000h	; 83ad  ..;;;;;`........
	defb 000h,000h,000h,000h,000h,008h,000h,008h,009h,00bh,00ah,00ah,0ffh,003h,000h,000h	; 83bd  ................
	defb 000h,000h,000h,000h,000h,000h,000h,00ch,000h,000h,009h,00ch,000h,00ah,00ah,00dh	; 83cd  ................
	defb 0ffh,001h,02eh,02eh,02eh,009h,009h,00ah,0ffh,001h,02ah,02ah,02ah,00eh,00eh,00fh	; 83dd  ..........***...
	defb 0ffh	; 83ed

; ----------------------------------------------------------------------
; DATOS edificio_piezas: Las piezas: ancho, alto y tiles
;   0x83ee..0x850e  (288 bytes)
DATA_edificio_piezas:
	defb 001h,064h,064h,064h,064h,064h,065h,0ffh,002h,06ah,064h,06ah,064h,06ah,064h,06ah	; 83ee  .ddddde..jdjdjdj
	defb 064h,06ah,064h,06ah,065h,0ffh,002h,061h,06ah,061h,06ah,061h,06ah,061h,06ah,061h	; 83fe  djdje..ajajajaja
	defb 06ah,062h,06ah,0ffh,001h,070h,070h,070h,070h,070h,060h,0ffh,001h,070h,070h,070h	; 840e  jbj..ppppp`..ppp
	defb 070h,070h,078h,0ffh,001h,077h,070h,070h,070h,070h,060h,0ffh,001h,000h,000h,000h	; 841e  ppx..wpppp`.....
	defb 000h,000h,060h,0ffh,002h,071h,076h,070h,070h,090h,090h,091h,090h,090h,090h,060h	; 842e  ..`..qvpp......`
	defb 060h,0ffh,002h,071h,076h,070h,070h,090h,090h,090h,092h,090h,090h,060h,060h,0ffh	; 843e  `..qvpp......``.
	defb 001h,067h,067h,067h,067h,067h,068h,0ffh,002h,070h,070h,000h,003h,000h,004h,000h	; 844e  .gggggh..pp.....
	defb 000h,03ah,016h,060h,060h,0ffh,002h,070h,070h,070h,070h,070h,070h,003h,070h,004h	; 845e  .:.``..pppppp.p.
	defb 070h,060h,060h,0ffh,002h,075h,03ah,000h,015h,000h,014h,000h,000h,03ah,016h,060h	; 846e  p``..u:......:.`
	defb 060h,0ffh,002h,016h,000h,017h,000h,03ah,016h,015h,017h,014h,03ah,060h,060h,0ffh	; 847e  `......:....:``.
	defb 002h,016h,000h,017h,000h,03ah,016h,074h,017h,075h,03ah,060h,060h,0ffh,002h,075h	; 848e  .....:.t.u:``..u
	defb 03ah,070h,074h,070h,075h,070h,070h,070h,070h,060h,060h,0ffh,002h,070h,070h,070h	; 849e  :ptpupppp``..ppp
	defb 070h,070h,070h,070h,001h,070h,002h,060h,060h,0ffh,002h,070h,070h,001h,000h,002h	; 84ae  pppp.p.``..pp...
	defb 000h,000h,000h,011h,03ah,060h,060h,0ffh,002h,000h,011h,000h,010h,011h,03ah,010h	; 84be  ....:``.......:.
	defb 012h,03ah,013h,060h,060h,0ffh,002h,03ah,073h,012h,000h,013h,000h,000h,000h,011h	; 84ce  .:.``..:s.......
	defb 03ah,060h,060h,0ffh,002h,000h,011h,000h,010h,011h,03ah,010h,072h,03ah,073h,060h	; 84de  :``.......:.r:s`
	defb 060h,0ffh,002h,03ah,073h,072h,070h,073h,070h,070h,070h,070h,070h,060h,060h,0ffh	; 84ee  `..:srpsppppp``.
	defb 001h,070h,000h,000h,000h,000h,078h,0ffh,001h,000h,000h,000h,000h,000h,078h,0ffh	; 84fe  .p....x.......x.

; ----------------------------------------------------------------------
; DATOS pieza_suelo: La pieza de suelo
;   0x850e..0x8516  (8 bytes)
DATA_pieza_suelo:
	defb 001h,029h,029h,029h,070h,070h,06bh,0ffh	; 850e  .)))ppk.

; ----------------------------------------------------------------------
; DATOS patrones_edificio: Los 256 patrones del edificio (largo 0x0800 y los
;   bytes): letras, cifras, paredes, puertas, ascensores
;   0x8516..0x8d18  (2050 bytes)
DATA_patrones_edificio:
	defb 000h,008h,000h,000h,000h,000h,000h,000h,000h,000h,0feh,0feh,0fch,0fch,0f8h,0f8h	; 8516  ................
	defb 0f0h,0f0h,0e0h,0e0h,0c0h,0c0h,080h,080h,000h,000h,07fh,07fh,03fh,03fh,01fh,01fh	; 8526  ............??..
	defb 00fh,00fh,007h,007h,003h,003h,001h,001h,000h,000h,000h,000h,000h,000h,000h,000h	; 8536  ................
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h	; 8546  ................
	defb 000h,000h,003h,000h,00fh,000h,03fh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h	; 8556  ......?.........
	defb 0ffh,000h,0ffh,000h,0ffh,000h,0ffh,0ffh,0ffh,0ffh,003h,000h,00fh,000h,03fh,07fh	; 8566  ..............?.
	defb 0ffh,0ffh,0c0h,000h,0f0h,000h,0fch,000h,0ffh,000h,0c0h,000h,0f0h,000h,0fch,0feh	; 8576  ................
	defb 0ffh,0ffh,0ffh,0f0h,0ffh,0f0h,0ffh,0f0h,0ffh,0f0h,0ffh,0f0h,0ffh,0f0h,0ffh,0ffh	; 8586  ................
	defb 0ffh,0ffh,00fh,00fh,01fh,01fh,03fh,03fh,07fh,07fh,000h,000h,001h,001h,003h,003h	; 8596  ......??........
	defb 007h,007h,0feh,0feh,0fch,0fch,0f8h,0f8h,0f0h,0f0h,0e0h,0e0h,0c0h,0c0h,080h,080h	; 85a6  ................
	defb 000h,000h,007h,007h,003h,003h,001h,001h,000h,000h,07fh,07fh,03fh,03fh,01fh,01fh	; 85b6  ............??..
	defb 00fh,00fh,000h,000h,080h,080h,0c0h,0c0h,0e0h,0e0h,0f0h,0f0h,0f8h,0f8h,0fch,0fch	; 85c6  ................
	defb 0feh,0feh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 85d6  ................
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,07fh,07fh,07fh,07fh,07fh	; 85e6  ................
	defb 07fh,07fh,07fh,07fh,07fh,06fh,06fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; 85f6  .....oo.........
	defb 07fh,07fh,000h,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,06fh,06fh,07fh	; 8606  .............oo.
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,000h,0feh,0feh,0feh,0feh,0feh	; 8616  ................
	defb 0feh,0feh,0feh,0feh,0feh,0f6h,0f6h,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh	; 8626  ................
	defb 0feh,0feh,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,0feh,0feh,0feh,0feh,0feh	; 8636  ................
	defb 0feh,0feh,0feh,0feh,0feh,0f6h,0f6h,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh	; 8646  ................
	defb 0feh,0feh,018h,018h,018h,018h,018h,018h,018h,018h,07eh,05ah,07eh,07eh,07eh,05ah	; 8656  ..........~Z~~~Z
	defb 07eh,000h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,01fh,000h,03fh,000h,07fh,0ffh	; 8666  ~...........?...
	defb 0ffh,0ffh,0c0h,000h,0e0h,000h,0f0h,0f8h,0f8h,0f8h,000h,000h,000h,000h,000h,000h	; 8676  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8686  ................
	defb 000h,000h,07ch,08eh,08eh,08eh,08eh,08eh,07ch,000h,078h,038h,038h,038h,038h,038h	; 8696  ..|.....|.x88888
	defb 038h,000h,07ch,0feh,08eh,00eh,03ch,060h,0feh,000h,07ch,08eh,00eh,03ch,00eh,08eh	; 86a6  8.|...<`..|..<..
	defb 07ch,000h,03ch,05ch,09ch,09ch,09ch,0feh,01ch,000h,0feh,080h,0bch,0feh,00eh,08eh	; 86b6  |.<\............
	defb 07ch,000h,03ch,060h,0fch,0feh,0e6h,0e6h,07ch,000h,07eh,0feh,006h,008h,030h,070h	; 86c6  |.<`....|.~...0p
	defb 070h,000h,07ch,0ceh,0ceh,07ch,0ceh,0ceh,07ch,000h,07ch,0feh,0ceh,0ceh,07eh,00eh	; 86d6  p.|..|..|.|...~.
	defb 07ch,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h	; 86e6  |...............
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0c0h,0c0h,038h,044h,0bah,0aah,0b2h,0aah	; 86f6  ..........8D....
	defb 044h,038h,03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,033h,077h,077h,066h,044h,000h	; 8706  D8<B....B<3wwfD.
	defb 0cch,0cch,000h,000h,000h,0fch,0fch,000h,000h,000h,07ch,08eh,08eh,0feh,08eh,08eh	; 8716  ..........|.....
	defb 08eh,000h,07ch,0e2h,0e2h,0fch,0e2h,0e2h,0fch,000h,07ch,0e2h,0e0h,0e0h,0e0h,0e2h	; 8726  ..|.......|.....
	defb 07ch,000h,07ch,0e2h,0e2h,0e2h,0e2h,0e2h,0fch,000h,07eh,0e0h,0e0h,0feh,0e0h,0e0h	; 8736  |.|.......~.....
	defb 0feh,000h,07eh,0e0h,0e0h,0feh,0e0h,0e0h,0e0h,000h,07ch,0e6h,0e0h,0eeh,0e2h,0e2h	; 8746  ..~.......|.....
	defb 07ch,000h,062h,0e2h,0e2h,0feh,0e2h,0e2h,0e2h,000h,018h,038h,038h,038h,038h,038h	; 8756  |.b........88888
	defb 038h,000h,006h,00eh,00eh,00eh,00eh,08eh,07ch,000h,062h,0e4h,0e8h,0f0h,0e8h,0e4h	; 8766  8.......|.b.....
	defb 0e2h,000h,060h,0e0h,0e0h,0e0h,0e0h,0e0h,0feh,000h,07ch,0feh,0eah,0eah,0eah,0eah	; 8776  ..`.......|.....
	defb 0eah,000h,072h,0f2h,0fah,0eeh,0e6h,0e6h,0e2h,000h,07ch,0e2h,0e2h,0e2h,0e2h,0e2h	; 8786  ..r.......|.....
	defb 07ch,000h,07ch,0e2h,0e2h,0e2h,0fch,0e0h,0e0h,000h,07ch,0e2h,0e2h,0e2h,0eah,0e6h	; 8796  |.|.......|.....
	defb 07eh,000h,07ch,0e2h,0e2h,0fch,0e2h,0e2h,0e2h,000h,07ch,0e2h,0e0h,07ch,00eh,08eh	; 87a6  ~.|.......|..|..
	defb 07ch,000h,0feh,038h,038h,038h,038h,038h,038h,000h,062h,0e2h,0e2h,0e2h,0e2h,0e2h	; 87b6  |..888888.b.....
	defb 07ch,000h,062h,0e2h,0e2h,0e2h,0e6h,0fch,078h,000h,06ah,0eah,0eah,0eah,0eah,0eah	; 87c6  |.b.....x.j.....
	defb 07ch,000h,0c6h,0eeh,07ch,038h,07ch,0eeh,0c6h,000h,0e2h,0e2h,0e2h,07ch,038h,038h	; 87d6  |...|8|......|88
	defb 038h,000h,0feh,00eh,00ch,038h,070h,0f0h,0feh,000h,000h,000h,000h,000h,000h,000h	; 87e6  8....8p.........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 87f6  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8806  ................
	defb 000h,000h,000h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh,00fh,00fh,00fh,00fh,00fh,00fh	; 8816  ................
	defb 00fh,00fh,08fh,04fh,02fh,01fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f0h,0f0h	; 8826  ...O/...........
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f1h,0f2h,0f4h,0f8h,0ffh,0ffh	; 8836  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00fh,00fh,00fh,00fh,0dbh,0dbh,0dbh,0dbh,0dbh,0dbh	; 8846  ................
	defb 0dbh,0dbh,0dbh,05ah,03ch,018h,0ffh,0ffh,0ffh,0ffh,0aah,055h,0aah,055h,0ffh,0ffh	; 8856  ...Z<......U.U..
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h	; 8866  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8876  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8886  ................
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0fch,0fch,0ffh,0ffh,0ffh,0ffh	; 8896  ................
	defb 0ffh,0ffh,001h,001h,003h,003h,007h,007h,00fh,00fh,01fh,01fh,03fh,03fh,07fh,07fh	; 88a6  ............??..
	defb 0ffh,0ffh,080h,080h,0c0h,0c0h,0e0h,0e0h,0f0h,0f0h,0f8h,0f8h,0fch,0fch,0feh,0feh	; 88b6  ................
	defb 0ffh,0ffh,03fh,03fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0e7h,0e7h,0e7h,0c3h,0c3h,000h	; 88c6  ..??............
	defb 081h,0c3h,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 88d6  ................
	defb 0ffh,0ffh,03fh,07fh,0ffh,0ffh,0ffh,0ffh,07fh,03fh,0fch,0feh,0ffh,0ffh,0ffh,0ffh	; 88e6  ..?......?......
	defb 0feh,0fch,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,07fh,0feh,0ffh,0ffh,0ffh,0ffh,0ffh	; 88f6  ................
	defb 0ffh,0feh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8906  ................
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0bfh,0bfh,0ffh	; 8916  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0fdh,0fdh,0ffh,0ffh,0ffh,000h,07fh,07fh,07fh,07fh,07fh	; 8926  ................
	defb 07fh,07fh,07fh,07fh,07fh,06fh,06fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; 8936  .....oo.........
	defb 07fh,07fh,000h,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,06fh,06fh,07fh	; 8946  .............oo.
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,000h,0feh,0feh,0feh,0feh,0feh	; 8956  ................
	defb 0feh,0feh,0feh,0feh,0feh,0f6h,0f6h,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh	; 8966  ................
	defb 0feh,0feh,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,0feh,0feh,0feh,0feh,0feh	; 8976  ................
	defb 0feh,0feh,0feh,0feh,0feh,0f6h,0f6h,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh	; 8986  ................
	defb 0feh,0feh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0bfh,0bfh,0ffh	; 8996  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0fdh,0fdh,0ffh,0ffh,0ffh,0ffh,084h,0bdh,0bdh,085h,0f5h	; 89a6  ................
	defb 0b5h,084h,0ffh,021h,0adh,0adh,0adh,0adh,0adh,021h,000h,000h,000h,000h,000h,000h	; 89b6  ...!.....!......
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 89c6  ................
	defb 000h,000h,000h,000h,000h,000h,000h,01eh,021h,040h,000h,000h,000h,000h,000h,000h	; 89d6  ........!@......
	defb 080h,040h,000h,001h,002h,004h,0c8h,030h,000h,000h,080h,000h,000h,000h,000h,000h	; 89e6  .@.....0........
	defb 000h,000h,040h,040h,040h,060h,010h,010h,010h,010h,018h,004h,004h,004h,004h,002h	; 89f6  ..@@@`..........
	defb 002h,003h,000h,000h,000h,000h,000h,001h,007h,009h,000h,000h,000h,000h,0c0h,0c0h	; 8a06  ................
	defb 000h,0c0h,0c0h,000h,000h,000h,000h,000h,000h,000h,011h,010h,020h,020h,040h,040h	; 8a16  ............  @@
	defb 080h,000h,080h,000h,000h,000h,000h,000h,000h,000h,040h,040h,040h,060h,026h,02eh	; 8a26  ..........@@@`&.
	defb 038h,02eh,026h,010h,010h,008h,008h,004h,004h,003h,0c0h,030h,00ch,030h,000h,000h	; 8a36  8.&........0.0..
	defb 000h,000h,0f8h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0f0h,010h	; 8a46  ................
	defb 010h,018h,000h,000h,0f0h,00fh,000h,000h,000h,000h,000h,000h,000h,000h,0f0h,00fh	; 8a56  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0f0h,00fh,000h,000h,0f0h,00eh,001h,000h	; 8a66  ................
	defb 000h,000h,000h,000h,000h,000h,000h,0f1h,00fh,001h,000h,000h,000h,000h,000h,000h	; 8a76  ................
	defb 0c0h,038h,0f0h,00fh,000h,000h,000h,000h,000h,000h,004h,004h,004h,003h,000h,000h	; 8a86  .8..............
	defb 000h,000h,07ch,08eh,08eh,08eh,08eh,08eh,07ch,000h,078h,038h,038h,038h,038h,038h	; 8a96  ..|.....|.x88888
	defb 038h,000h,07ch,0feh,08eh,00eh,03ch,060h,0feh,000h,07ch,08eh,00eh,03ch,00eh,08eh	; 8aa6  8.|...<`..|..<..
	defb 07ch,000h,03ch,05ch,09ch,09ch,09ch,0feh,01ch,000h,0feh,080h,0bch,0feh,00eh,08eh	; 8ab6  |.<\............
	defb 07ch,000h,03ch,060h,0fch,0feh,0e6h,0e6h,07ch,000h,07eh,0feh,006h,008h,030h,070h	; 8ac6  |.<`....|.~...0p
	defb 070h,000h,07ch,0ceh,0ceh,07ch,0ceh,0ceh,07ch,000h,07ch,0feh,0ceh,0ceh,07eh,00eh	; 8ad6  p.|..|..|.|...~.
	defb 07ch,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8ae6  |...............
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8af6  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8b06  ................
	defb 000h,000h,0e7h,0e7h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h	; 8b16  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8b26  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8b36  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8b46  ................
	defb 000h,000h,000h,001h,002h,004h,004h,008h,008h,010h,0ffh,003h,003h,003h,003h,003h	; 8b56  ................
	defb 003h,003h,0ffh,000h,000h,000h,000h,000h,000h,000h,080h,020h,010h,008h,004h,002h	; 8b66  ........... ....
	defb 001h,000h,01fh,03fh,03fh,03fh,07fh,07fh,07fh,07fh,0f0h,0feh,0ffh,0ffh,0ffh,0ffh	; 8b76  ...???..........
	defb 0ffh,0ffh,000h,000h,0c0h,0e0h,0f0h,0f0h,0f0h,0f0h,000h,000h,000h,000h,000h,000h	; 8b86  ................
	defb 000h,080h,019h,073h,073h,033h,001h,000h,000h,000h,09fh,0cfh,0cfh,0cfh,080h,000h	; 8b96  ...ss3..........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,0cch,09eh,09eh,09eh,00ch,000h	; 8ba6  ................
	defb 000h,000h,0c0h,070h,070h,078h,000h,000h,000h,000h,003h,00eh,00eh,01eh,000h,000h	; 8bb6  ...ppx..........
	defb 000h,000h,033h,079h,079h,079h,030h,000h,000h,000h,0f9h,0f3h,0f3h,0f3h,001h,000h	; 8bc6  ..3yyy0.........
	defb 000h,000h,000h,080h,040h,020h,020h,010h,010h,008h,0ffh,0c0h,0c0h,0c0h,0c0h,0c0h	; 8bd6  ....@  .........
	defb 0c0h,0c0h,0ffh,000h,000h,000h,000h,000h,000h,000h,001h,004h,008h,010h,020h,040h	; 8be6  .............. @
	defb 080h,000h,0f8h,0fch,0fch,0fch,0feh,0feh,0feh,038h,00fh,07fh,0ffh,0ffh,0ffh,0ffh	; 8bf6  .........8......
	defb 0ffh,017h,000h,000h,003h,007h,00fh,00fh,00fh,003h,000h,000h,000h,000h,000h,000h	; 8c06  ................
	defb 000h,001h,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0ffh,01fh,0ffh,0ffh,0ffh,0ffh	; 8c16  ................
	defb 0ffh,0ffh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,0ffh,0f8h,0ffh,0ffh,0ffh,0ffh	; 8c26  ................
	defb 0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8c36  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8c46  ................
	defb 000h,000h,000h,001h,002h,004h,004h,008h,008h,010h,0ffh,003h,003h,003h,003h,003h	; 8c56  ................
	defb 003h,003h,0ffh,000h,000h,000h,000h,000h,000h,000h,080h,020h,010h,008h,004h,002h	; 8c66  ........... ....
	defb 001h,000h,01fh,03fh,03fh,03fh,07fh,07fh,07fh,07fh,0f0h,0feh,0ffh,0ffh,0ffh,0ffh	; 8c76  ...???..........
	defb 0ffh,0ffh,000h,000h,0c0h,0e0h,0f0h,0f0h,0f0h,0f0h,000h,000h,000h,000h,000h,000h	; 8c86  ................
	defb 000h,080h,098h,0ceh,0ceh,0cch,010h,000h,000h,000h,09fh,0cfh,0cfh,0cfh,080h,000h	; 8c96  ................
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,0cch,09eh,09eh,09eh,00ch,000h	; 8ca6  ................
	defb 000h,000h,0c0h,070h,070h,078h,000h,000h,000h,000h,003h,00eh,00eh,01eh,000h,000h	; 8cb6  ...ppx..........
	defb 000h,000h,033h,079h,079h,079h,030h,000h,000h,000h,0f9h,0f3h,0f3h,0f3h,001h,000h	; 8cc6  ..3yyy0.........
	defb 000h,000h,000h,080h,040h,020h,020h,010h,010h,008h,0ffh,0c0h,0c0h,0c0h,0c0h,0c0h	; 8cd6  ....@  .........
	defb 0c0h,0c0h,0ffh,000h,000h,000h,000h,000h,000h,000h,001h,004h,008h,010h,020h,040h	; 8ce6  .............. @
	defb 080h,000h,0f8h,0fch,0fch,0fch,0feh,0feh,0feh,038h,00fh,07fh,0ffh,0ffh,0ffh,0ffh	; 8cf6  .........8......
	defb 0ffh,017h,000h,000h,003h,007h,00fh,00fh,00fh,003h,000h,000h,000h,000h,000h,000h	; 8d06  ................
	defb 000h,001h	; 8d16

; ----------------------------------------------------------------------
; DATOS colores_1: Colores de los patrones, rondas 1, 4, 7...
;   0x8d18..0x8d38  (32 bytes)
DATA_colores_1:
	defb 071h,051h,0f1h,0cfh,0cfh,051h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,05eh,05eh,07fh,065h	; 8d18  qQ...Q......^^.e
	defb 08fh,08fh,0cfh,0f1h,0f1h,0f1h,0f1h,0f1h,07fh,047h,0feh,047h,04eh,040h,0feh,040h	; 8d28  .........G.GN@.@

; ----------------------------------------------------------------------
; DATOS colores_2: Rondas 2, 5, 8...
;   0x8d38..0x8d58  (32 bytes)
DATA_colores_2:
	defb 0b1h,051h,0f1h,0cfh,0cfh,051h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,05eh,05eh,0bfh,065h	; 8d38  .Q...Q......^^.e
	defb 08fh,08fh,0cfh,0f1h,0f1h,0f1h,0f1h,0f1h,0bfh,04bh,0feh,04bh,04eh,040h,0feh,040h	; 8d48  .........K.KN@.@

; ----------------------------------------------------------------------
; DATOS colores_3: Rondas 3, 6, 9...
;   0x8d58..0x8d78  (32 bytes)
DATA_colores_3:
	defb 031h,051h,0f1h,0cfh,0cfh,051h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,05eh,05eh,03fh,065h	; 8d58  1Q...Q......^^?e
	defb 08fh,08fh,0cfh,0f1h,0f1h,0f1h,0f1h,0f1h,03fh,043h,0feh,043h,04eh,040h,0feh,040h	; 8d68  ........?C.CN@.@

; ----------------------------------------------------------------------
; DATOS colores_oscuras: Los de la luz apagada
;   0x8d78..0x8d98  (32 bytes)
DATA_colores_oscuras:
	defb 011h,051h,0f1h,0cfh,0cfh,051h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,05eh,05eh,01fh,065h	; 8d78  .Q...Q......^^.e
	defb 08fh,08fh,0cfh,0f1h,0f1h,0f1h,0f1h,0f1h,01fh,041h,0feh,04fh,04eh,040h,0feh,040h	; 8d88  .........A.ON@.@

; ----------------------------------------------------------------------
; DATOS sprites_agente: Los sprites del agente (largo y bytes)
;   0x8d98..0x905a  (706 bytes)
DATA_sprites_agente:
	defb 0c0h,002h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8d98  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8da8  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,003h,007h,00fh,00fh,00dh,00ch	; 8db8  ................
	defb 00ch,006h,000h,000h,000h,000h,000h,000h,000h,000h,0fch,0f8h,0f0h,050h,040h,000h	; 8dc8  .............P@.
	defb 000h,000h,000h,000h,000h,002h,003h,003h,001h,000h,000h,000h,000h,000h,000h,000h	; 8dd8  ................
	defb 00ch,004h,000h,000h,0a0h,0a0h,0f0h,0e0h,0c0h,000h,000h,000h,000h,000h,000h,000h	; 8de8  ................
	defb 000h,000h,006h,00eh,00fh,00fh,01fh,01fh,01fh,012h,01ah,00eh,00eh,006h,006h,006h	; 8df8  ................
	defb 006h,007h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8e08  ................
	defb 000h,000h,006h,00eh,00fh,01fh,01fh,01fh,03fh,033h,03bh,01fh,01fh,01dh,039h,070h	; 8e18  ........?3;...9p
	defb 060h,030h,000h,000h,000h,000h,000h,000h,000h,000h,000h,080h,080h,080h,0c0h,0c0h	; 8e28  `0..............
	defb 0c0h,0e0h,000h,000h,000h,000h,000h,000h,000h,000h,003h,007h,00fh,00fh,00dh,00ch	; 8e38  ................
	defb 00ch,006h,000h,000h,000h,000h,000h,000h,000h,000h,0fch,0f8h,0f0h,050h,040h,000h	; 8e48  .............P@.
	defb 000h,00fh,000h,000h,000h,002h,003h,003h,001h,000h,000h,000h,000h,000h,000h,000h	; 8e58  ................
	defb 00ch,004h,000h,000h,0a0h,0a0h,0f0h,0e0h,0c0h,000h,00eh,00ch,00ch,000h,000h,000h	; 8e68  ................
	defb 000h,000h,006h,00eh,00fh,00fh,01fh,01fh,01fh,012h,01ah,00eh,00eh,006h,006h,006h	; 8e78  ................
	defb 006h,007h,000h,030h,0f0h,0f0h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 8e88  ...0............
	defb 000h,000h,006h,00eh,00fh,01fh,01fh,01fh,03fh,033h,03bh,01fh,01fh,01dh,039h,070h	; 8e98  ........?3;...9p
	defb 060h,030h,000h,030h,0f0h,0f0h,0c0h,000h,000h,000h,000h,080h,080h,080h,0c0h,0c0h	; 8ea8  `0.0............
	defb 0c0h,0e0h,000h,01fh,03fh,07fh,07ah,06ah,060h,038h,01fh,03fh,07fh,073h,017h,05fh	; 8eb8  ....?.zj`8.?.s._
	defb 0fch,0bch,000h,0e0h,0c0h,080h,080h,000h,000h,000h,000h,000h,000h,080h,0c0h,0c0h	; 8ec8  ................
	defb 0c0h,0e0h,000h,000h,000h,005h,015h,01fh,007h,000h,000h,000h,00ch,008h,000h,000h	; 8ed8  ................
	defb 000h,000h,000h,000h,000h,000h,080h,080h,000h,000h,000h,000h,000h,000h,000h,000h	; 8ee8  ................
	defb 000h,000h,000h,01fh,03fh,07fh,07ah,06ah,060h,038h,01fh,03fh,07fh,073h,017h,05fh	; 8ef8  ....?.zj`8.?.s._
	defb 0fch,0bch,000h,0e0h,0c0h,080h,080h,000h,01eh,020h,060h,0e0h,0c0h,080h,0c0h,0c0h	; 8f08  ......... `.....
	defb 0c0h,0e0h,000h,000h,000h,005h,015h,01fh,007h,000h,000h,000h,00ch,008h,000h,000h	; 8f18  ................
	defb 000h,000h,000h,000h,000h,000h,080h,080h,01ch,018h,018h,000h,000h,000h,000h,000h	; 8f28  ................
	defb 000h,000h,000h,000h,000h,002h,003h,003h,001h,000h,000h,000h,000h,000h,000h,000h	; 8f38  ................
	defb 000h,000h,000h,000h,0a0h,0b0h,0f8h,0f0h,0e0h,000h,000h,00eh,00ch,00ch,000h,000h	; 8f48  ................
	defb 000h,000h,006h,00eh,00fh,01fh,01fh,01fh,00fh,00fh,00fh,007h,000h,000h,000h,000h	; 8f58  ................
	defb 000h,000h,000h,000h,080h,0f0h,0f0h,000h,000h,080h,0c0h,0c0h,0c0h,0c0h,060h,070h	; 8f68  ..............`p
	defb 000h,000h,003h,007h,00fh,00fh,00dh,00ch,00ch,006h,006h,00fh,00fh,01fh,01fh,01fh	; 8f78  ................
	defb 00fh,007h,0fch,0f8h,0f0h,050h,040h,000h,000h,000h,000h,000h,080h,0f0h,0f1h,0fdh	; 8f88  .....P@.........
	defb 0efh,0c3h,003h,007h,00fh,00fh,00dh,00ch,00ch,006h,006h,00fh,00fh,01fh,01fh,01fh	; 8f98  ................
	defb 00fh,007h,0fch,0f8h,0f0h,050h,040h,000h,000h,000h,000h,00fh,080h,0f0h,0f1h,0fdh	; 8fa8  .....P@.........
	defb 0efh,0c3h,000h,000h,000h,000h,000h,000h,000h,000h,03fh,07fh,0ffh,0fbh,0d4h,0cah	; 8fb8  ..........?.....
	defb 0c0h,060h,000h,000h,000h,000h,000h,000h,000h,000h,0c0h,080h,000h,000h,000h,000h	; 8fc8  .`..............
	defb 000h,000h,000h,000h,004h,02bh,035h,03eh,01ch,008h,000h,000h,000h,000h,000h,000h	; 8fd8  .....+5>........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,020h,038h,038h,000h,000h,000h,000h,000h	; 8fe8  ........ 88.....
	defb 000h,000h,030h,03fh,03fh,03fh,01ch,01eh,01fh,00fh,007h,001h,001h,003h,003h,002h	; 8ff8  ..0???..........
	defb 002h,000h,0c0h,0c0h,0c0h,000h,000h,000h,000h,080h,0c0h,0c0h,0c0h,0e0h,0e0h,0e0h	; 9008  ................
	defb 060h,070h,000h,000h,080h,0c0h,0e0h,0e0h,0e8h,0d0h,0e8h,0f1h,0e3h,07fh,03dh,000h	; 9018  `p............=.
	defb 000h,000h,000h,000h,000h,007h,063h,063h,063h,0e7h,0c7h,0ceh,0eeh,0feh,0fch,0fch	; 9028  ......ccc.......
	defb 07ch,038h,000h,000h,000h,00ch,00eh,016h,02eh,016h,00eh,01ch,000h,000h,000h,000h	; 9038  |8..............
	defb 000h,000h,060h,060h,0e0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9048  ..``............
	defb 000h,000h	; 9058

; ----------------------------------------------------------------------
; DATOS sprites_enemigo: Los del enemigo
;   0x905a..0x921c  (450 bytes)
DATA_sprites_enemigo:
	defb 0c0h,001h,00dh,00fh,00fh,03fh,001h,001h,000h,000h,008h,00ch,00fh,00fh,01fh,01fh	; 905a  .....?..........
	defb 01fh,012h,080h,080h,080h,0e0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 906a  ................
	defb 000h,000h,01ah,00eh,00eh,006h,006h,006h,006h,007h,000h,000h,000h,000h,000h,000h	; 907a  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 908a  ................
	defb 000h,000h,006h,007h,007h,01fh,000h,000h,000h,000h,004h,006h,00fh,00fh,01fh,01fh	; 909a  ................
	defb 03fh,039h,0c0h,0c0h,0c0h,0f0h,080h,080h,000h,000h,000h,000h,000h,000h,000h,000h	; 90aa  ?9..............
	defb 000h,000h,03bh,01fh,01fh,01dh,039h,070h,060h,030h,000h,000h,000h,000h,000h,000h	; 90ba  ..;...9p`0......
	defb 000h,000h,000h,080h,080h,080h,0c0h,0c0h,0c0h,0e0h,000h,000h,000h,000h,000h,000h	; 90ca  ................
	defb 000h,000h,00dh,00fh,00fh,03fh,001h,001h,000h,000h,008h,00ch,00fh,00fh,01fh,01fh	; 90da  .....?..........
	defb 01fh,012h,080h,080h,080h,0e0h,000h,000h,000h,00fh,000h,030h,0f0h,0f0h,0c0h,000h	; 90ea  ...........0....
	defb 000h,000h,006h,007h,007h,01fh,000h,000h,000h,000h,004h,006h,00fh,00fh,01fh,01fh	; 90fa  ................
	defb 03fh,039h,0c0h,0c0h,0c0h,0f0h,080h,080h,000h,00fh,000h,030h,0f0h,0f0h,0c0h,000h	; 910a  ?9.........0....
	defb 000h,000h,01bh,01fh,01fh,07fh,002h,002h,000h,018h,01eh,03fh,07fh,073h,017h,05fh	; 911a  ...........?.s._
	defb 0fch,0bch,000h,000h,000h,0c0h,000h,000h,000h,000h,000h,000h,000h,080h,0c0h,0c0h	; 912a  ................
	defb 0c0h,0e0h,01bh,01fh,01fh,07fh,002h,002h,000h,018h,01fh,03fh,07fh,073h,017h,05fh	; 913a  ...........?.s._
	defb 0fch,0bch,000h,000h,000h,0c0h,000h,000h,01eh,020h,060h,0e0h,0c0h,080h,0c0h,0c0h	; 914a  ......... `.....
	defb 0c0h,0e0h,036h,03eh,03eh,0ffh,00ah,004h,00ah,000h,020h,030h,03fh,03fh,03fh,01eh	; 915a  ..6>>..... 0???.
	defb 01fh,01fh,000h,000h,000h,080h,000h,000h,000h,000h,000h,0c0h,0c0h,0c0h,080h,000h	; 916a  ................
	defb 080h,0c0h,00fh,003h,003h,007h,006h,004h,004h,000h,000h,000h,000h,000h,000h,000h	; 917a  ................
	defb 000h,000h,0e0h,0e0h,0e0h,060h,060h,060h,030h,038h,000h,000h,000h,000h,000h,000h	; 918a  .....```08......
	defb 000h,000h,000h,000h,000h,020h,020h,0f4h,0e8h,0f4h,060h,0e1h,0e3h,0e7h,023h,020h	; 919a  .....  ...`...# 
	defb 000h,000h,000h,000h,000h,007h,063h,063h,063h,063h,0e7h,0f7h,0ffh,0feh,0feh,0feh	; 91aa  ......cccc......
	defb 07ch,030h,000h,000h,000h,000h,000h,000h,000h,000h,003h,01bh,03fh,03ch,03ch,05ch	; 91ba  |0..........?<<\
	defb 0f8h,0b1h,000h,000h,000h,000h,000h,000h,000h,000h,060h,0e0h,0f8h,040h,057h,018h	; 91ca  ..........`..@W.
	defb 008h,038h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,003h,001h,000h,000h	; 91da  .8..............
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,080h,0c0h,080h,000h,000h	; 91ea  ................
	defb 000h,000h,002h,011h,008h,084h,042h,060h,012h,001h,012h,060h,042h,084h,008h,010h	; 91fa  ......B`...`B...
	defb 001h,002h,040h,000h,020h,010h,000h,040h,020h,000h,000h,020h,040h,010h,020h,000h	; 920a  ..@. ..@ .. @. .
	defb 000h,040h	; 921a

; ----------------------------------------------------------------------
; DATOS sprites_resto: Balas, lampara y lo demas
;   0x921c..0x925c  (64 bytes)
DATA_sprites_resto:
	defb 0c0h,001h,000h,000h,00dh,00fh,00fh,03fh,001h,001h,000h,000h,000h,000h,000h,000h	; 921c  .......?........
	defb 000h,000h,000h,000h,080h,080h,080h,0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; 922c  ................
	defb 000h,000h,000h,000h,001h,001h,001h,007h,000h,000h,000h,000h,000h,000h,000h,000h	; 923c  ................
	defb 000h,000h,000h,000h,0b0h,0b0h,0f0h,0fch,080h,080h,000h,000h,000h,000h,000h,000h	; 924c  ................

; ----------------------------------------------------------------------
; DATOS sprites_agente_2: Los del agente que tapa la entrada por el cable
;   0x925c..0x949a  (574 bytes)
DATA_sprites_agente_2:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,03ch,03ch,000h,000h,000h,000h,000h,000h	; 925c  ........<<......
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 926c  ................
	defb 000h,000h,010h,008h,010h,020h,010h,010h,000h,000h,0ffh,07eh,03ch,000h,000h,000h	; 927c  ..... .....~<...
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 928c  ................
	defb 000h,000h,010h,020h,010h,008h,010h,010h,000h,000h,0ffh,07eh,03ch,000h,000h,000h	; 929c  ... .......~<...
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 92ac  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,003h,007h,00fh,00fh,00dh,00ch	; 92bc  ................
	defb 00ch,006h,000h,000h,000h,000h,000h,000h,000h,000h,0fch,0f8h,0f0h,050h,040h,000h	; 92cc  .............P@.
	defb 000h,000h,000h,000h,000h,002h,003h,003h,001h,000h,000h,000h,000h,000h,000h,000h	; 92dc  ................
	defb 00ch,004h,000h,000h,0a0h,0a0h,0f0h,0e0h,0c0h,000h,000h,000h,000h,000h,000h,000h	; 92ec  ................
	defb 000h,000h,000h,000h,010h,008h,004h,000h,001h,03ch,001h,000h,004h,008h,010h,000h	; 92fc  .........<......
	defb 000h,000h,080h,080h,084h,088h,090h,000h,040h,09eh,040h,000h,090h,088h,084h,080h	; 930c  ........@.@.....
	defb 080h,000h,00fh,00bh,005h,002h,000h,038h,03ch,03fh,007h,007h,007h,00fh,01eh,01eh	; 931c  .......8<?......
	defb 01ch,03ch,0f0h,0d0h,0a0h,040h,000h,01ch,03ch,0fch,0e0h,0e0h,0e0h,0f0h,078h,078h	; 932c  .<...@..<.....xx
	defb 038h,03ch,004h,00ah,00dh,047h,0c7h,0c3h,0c0h,000h,000h,000h,000h,000h,000h,000h	; 933c  8<...G..........
	defb 000h,000h,020h,050h,0b0h,0e2h,0e3h,0c3h,003h,000h,000h,000h,000h,000h,000h,000h	; 934c  .. P............
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,01fh,013h,006h,030h,03fh,01fh	; 935c  .............0?.
	defb 07eh,0fch,000h,000h,000h,000h,000h,000h,000h,000h,0f8h,0c8h,060h,00ch,0fch,0f8h	; 936c  ~...........`...
	defb 07eh,03fh,000h,000h,000h,000h,000h,000h,000h,000h,000h,00ch,009h,0cfh,0c0h,000h	; 937c  ~?..............
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,030h,098h,0f3h,003h,000h	; 938c  ...........0....
	defb 000h,000h,006h,007h,01fh,004h,002h,038h,03ch,03fh,007h,007h,007h,00fh,01eh,01eh	; 939c  .......8<?......
	defb 01ch,03ch,060h,0e0h,0f8h,020h,040h,01ch,03ch,0fch,0e0h,0e0h,0e0h,0f0h,078h,078h	; 93ac  .<`.. @.<.....xx
	defb 038h,03ch,000h,000h,000h,000h,000h,000h,000h,000h,00eh,03fh,008h,076h,078h,007h	; 93bc  8<.........?.vx.
	defb 07fh,0f0h,000h,000h,000h,000h,000h,000h,000h,000h,070h,0fch,010h,06eh,01eh,0e0h	; 93cc  ..........p..n..
	defb 0feh,00fh,001h,002h,00fh,010h,01ch,01dh,027h,028h,003h,004h,011h,000h,011h,01eh	; 93dc  ........'(......
	defb 029h,028h,005h,006h,012h,013h,01fh,020h,02ah,02bh,007h,008h,014h,015h,021h,022h	; 93ec  )(..... *+....!"
	defb 02ch,02ch,009h,00ah,016h,017h,023h,024h,02dh,02eh,00bh,00ch,018h,019h,018h,019h	; 93fc  ,,....#$-.......
	defb 02fh,030h,00dh,00eh,01ah,01bh,025h,026h,031h,032h,033h,034h,000h,03fh,040h,000h	; 940c  /0....%&1234.?@.
	defb 04ch,04dh,000h,059h,05ah,05bh,063h,064h,065h,06eh,06fh,070h,035h,036h,037h,041h	; 941c  LM.YZ[cdenop567A
	defb 042h,043h,04eh,04fh,050h,05ch,05dh,05eh,066h,067h,043h,071h,072h,073h,038h,038h	; 942c  BCNOP\]^fgCqrs88
	defb 039h,044h,045h,046h,051h,052h,053h,05fh,052h,000h,068h,069h,000h,074h,075h,000h	; 943c  9DEFQRS_R.hi.tu.
	defb 03ah,03bh,047h,048h,054h,055h,054h,055h,06ah,06bh,076h,077h,03ch,03dh,03eh,049h	; 944c  :;GHTUTUjkvw<=>I
	defb 04ah,04bh,056h,057h,058h,060h,061h,062h,06ch,09fh,06dh,078h,079h,07ah,000h,07bh	; 945c  JKVWX`abl.mxyz.{
	defb 07ch,07dh,000h,000h,07eh,07fh,080h,081h,082h,0abh,083h,084h,085h,086h,087h,088h	; 946c  |}..~...........
	defb 089h,08ah,08bh,08ch,08dh,08eh,08fh,090h,091h,092h,093h,094h,000h,09fh,095h,096h	; 947c  ................
	defb 097h,000h,098h,09fh,099h,09ah,09fh,000h,09bh,09ch,09dh,000h,09eh,000h	; 948c  ..............

; ----------------------------------------------------------------------
; DATOS txt_taito: "(C) TAITO 1985" del titulo
;   0x949a..0x94ab  (17 bytes)
DATA_txt_taito:
	defb 0ach,000h,0c0h,0adh,0b5h,0c0h,0bbh,000h,0afh,0bbh,0beh,0bch,0aah,0a1h,0a9h,0a8h	; 949a  ................
	defb 0a5h	; 94aa

; ----------------------------------------------------------------------
; DATOS txt_pulsa: "PUSH SPACE KEY"
;   0x94ab..0x94b9  (14 bytes)
DATA_txt_pulsa:
	defb 0bch,0c1h,0bfh,0b4h,000h,0bfh,0bch,0adh,0afh,0b1h,000h,0b7h,0b1h,0c5h	; 94ab  ..............

; ----------------------------------------------------------------------
; DATOS titulo_patrones: Los patrones del titulo, comprimidos
;   0x94b9..0x993e  (1157 bytes)
DATA_titulo_patrones:
	defb 049h,001h,088h,085h,003h,086h,002h,086h,002h,086h,002h,086h,002h,086h,002h,084h	; 94b9  I...............
	defb 084h,084h,084h,085h,003h,085h,013h,083h,00dh,086h,006h,084h,08dh,003h,086h,004h	; 94c9  ................
	defb 083h,083h,002h,083h,083h,002h,086h,002h,086h,088h,088h,085h,003h,085h,005h,086h	; 94d9  ................
	defb 084h,004h,086h,002h,085h,083h,003h,083h,003h,084h,083h,001h,084h,083h,088h,088h	; 94e9  ................
	defb 002h,086h,006h,083h,002h,085h,002h,086h,002h,086h,084h,084h,084h,084h,001h,087h	; 94f9  ................
	defb 001h,087h,001h,087h,012h,086h,009h,087h,001h,087h,005h,083h,009h,086h,002h,087h	; 9509  ................
	defb 001h,087h,001h,086h,002h,086h,006h,083h,002h,086h,005h,083h,001h,087h,001h,087h	; 9519  ................
	defb 084h,088h,004h,088h,003h,083h,004h,086h,083h,083h,003h,087h,001h,087h,084h,084h	; 9529  ................
	defb 084h,004h,084h,084h,001h,087h,001h,083h,083h,001h,084h,004h,084h,084h,084h,004h	; 9539  ................
	defb 084h,084h,088h,084h,084h,088h,088h,084h,004h,084h,084h,084h,005h,086h,003h,085h	; 9549  ................
	defb 002h,087h,004h,084h,008h,085h,083h,088h,085h,083h,00ah,083h,083h,001h,086h,001h	; 9559  ................
	defb 087h,002h,086h,003h,086h,001h,087h,087h,001h,087h,001h,087h,001h,087h,002h,083h	; 9569  ................
	defb 084h,001h,083h,084h,001h,086h,002h,086h,002h,086h,001h,083h,005h,086h,002h,083h	; 9579  ................
	defb 002h,083h,001h,086h,002h,086h,002h,086h,002h,086h,001h,083h,005h,086h,002h,083h	; 9589  ................
	defb 003h,089h,001h,086h,002h,087h,00bh,083h,006h,083h,003h,085h,002h,086h,002h,084h	; 9599  ................
	defb 005h,083h,00dh,084h,003h,083h,083h,002h,086h,002h,086h,015h,085h,008h,086h,006h	; 95a9  ................
	defb 084h,083h,009h,083h,001h,085h,003h,085h,003h,085h,008h,083h,008h,087h,001h,087h	; 95b9  ................
	defb 001h,087h,007h,083h,086h,001h,087h,002h,086h,009h,088h,001h,085h,003h,086h,013h	; 95c9  ................
	defb 083h,02ah,087h,016h,083h,00bh,083h,004h,085h,00eh,083h,00dh,083h,002h,086h,002h	; 95d9  .*..............
	defb 084h,00ch,085h,004h,085h,00ah,085h,003h,083h,005h,083h,008h,083h,00ah,086h,002h	; 95e9  ................
	defb 085h,003h,083h,005h,085h,00ah,083h,001h,083h,009h,000h,000h,0ffh,0fch,07ch,03ch	; 95f9  ..............|<
	defb 0feh,07eh,03eh,0ffh,07fh,03eh,080h,000h,000h,0ffh,07eh,03eh,07fh,03eh,01ch,007h	; 9609  .~>..>....~>.>..
	defb 00fh,0c0h,0e0h,0ffh,0f7h,0e7h,0c7h,0feh,0deh,0ceh,0c6h,00fh,01fh,03fh,03fh,07fh	; 9619  .............??.
	defb 07eh,0fch,0fch,0e0h,0f0h,0f8h,0f8h,0fch,07ch,03eh,03eh,0ffh,0feh,0fch,0fch,07ch	; 9629  ~.......|>>....|
	defb 03ch,0c0h,0e0h,0f0h,0f8h,078h,078h,07ch,07ch,03ch,03fh,03fh,01eh,00eh,000h,000h	; 9639  <....xx||<??....
	defb 0c0h,03eh,03fh,01fh,01fh,01ch,03ch,03ch,00fh,00fh,01eh,01ch,0e0h,0e0h,0f0h,070h	; 9649  .>?...<<.......p
	defb 0c7h,0c7h,007h,0c6h,0c6h,0c0h,0fch,03eh,03ch,03eh,03fh,03fh,07ch,0f8h,0f8h,0f0h	; 9659  .......><>??|...
	defb 03fh,03fh,03ch,0c0h,000h,000h,00eh,00eh,000h,00eh,01eh,01fh,00fh,03ch,03ch,0bch	; 9669  ??<..........<<.
	defb 0b8h,0f8h,0f8h,01ch,03fh,038h,070h,0f8h,038h,007h,0c0h,03fh,03dh,03ch,0e0h,0f0h	; 9679  ....?8p.8..?=<..
	defb 0f8h,078h,07ch,07ch,03ch,07ch,0fch,0ffh,03eh,07eh,0feh,03eh,07eh,0ffh,00fh,007h	; 9689  .x||<|..>~.>~...
	defb 0f8h,0f0h,07ch,0feh,00fh,01fh,0e0h,0f0h,0fch,0fch,07eh,07fh,03fh,03fh,01fh,00fh	; 9699  ..|.......~.??..
	defb 03eh,03eh,07ch,0fch,0f8h,0f8h,0f0h,0e0h,03ch,07eh,0ffh,03ch,03ch,03dh,03fh,03fh	; 96a9  >>|.....<~.<<=??
	defb 01fh,01eh,00ch,000h,001h,000h,0fch,000h,001h,007h,00fh,01fh,03fh,000h,0c0h,0f0h	; 96b9  ............?...
	defb 0f8h,0f8h,0fch,0fch,0ffh,000h,070h,0f0h,000h,0ffh,000h,0f0h,000h,0ffh,03fh,000h	; 96c9  ......p.......?.
	defb 0fch,0f0h,000h,000h,001h,003h,007h,00fh,000h,07fh,0ffh,000h,000h,0c0h,0e0h,0f0h	; 96d9  ................
	defb 0f8h,001h,003h,0fch,0feh,07fh,0ffh,0dfh,0dfh,08fh,08fh,0f0h,0ffh,0ffh,0f1h,0e1h	; 96e9  ................
	defb 0c1h,0c1h,0ffh,0ffh,0f8h,0f0h,070h,030h,030h,03fh,01fh,0f0h,0e0h,01fh,03fh,0ffh	; 96f9  ......p00?....?.
	defb 0f7h,0f7h,0e3h,0e3h,0fch,0feh,003h,007h,0feh,0ffh,09fh,08fh,0ffh,0c0h,0e0h,0f0h	; 9709  ................
	defb 0f8h,007h,000h,0f0h,0e0h,0c0h,080h,000h,0c1h,001h,0f8h,030h,000h,01fh,0e0h,07fh	; 9719  ...........0....
	defb 070h,078h,07ch,07eh,0c1h,000h,0ffh,007h,00fh,01fh,03fh,007h,00fh,00eh,00fh,00fh	; 9729  px|~......?.....
	defb 0ffh,003h,000h,080h,0fch,0feh,0fch,0fch,0f8h,001h,003h,001h,001h,020h,070h,0f8h	; 9739  ............. p.
	defb 0fch,000h,0f0h,001h,07fh,07eh,000h,080h,000h,000h,008h,01ch,03eh,07fh,07fh,0ffh	; 9749  .....~......>...
	defb 07fh,03fh,00eh,01eh,03fh,003h,007h,080h,0c0h,0e0h,0fbh,0ffh,07fh,0feh,0ffh,001h	; 9759  .?..?...........
	defb 003h,0f8h,0fch,01fh,03fh,0e0h,0f0h,03eh,03fh,01fh,0bfh,0feh,0fch,03fh,0ffh,000h	; 9769  ....?..>?....?..
	defb 007h,08fh,000h,0e0h,0f8h,000h,03fh,01fh,00fh,007h,001h,000h,0ffh,0fch,000h,0e0h	; 9779  ......?.........
	defb 0c0h,080h,000h,003h,00fh,000h,0fch,0ffh,000h,03fh,0ffh,000h,0f0h,0fch,000h,00fh	; 9789  .........?......
	defb 007h,003h,001h,000h,000h,0ffh,07fh,000h,0f8h,0f0h,0e0h,0c0h,000h,0c5h,000h,040h	; 9799  ...............@
	defb 080h,000h,002h,001h,000h,002h,002h,000h,000h,001h,003h,000h,060h,0ffh,079h,036h	; 97a9  ............`.y6
	defb 03ch,000h,000h,080h,0c0h,040h,040h,002h,001h,003h,002h,000h,0e0h,000h,002h,003h	; 97b9  <....@@.........
	defb 001h,000h,000h,0bch,0bfh,0fdh,0fbh,0f4h,0ffh,060h,0e0h,0f0h,0f8h,0b8h,0c0h,000h	; 97c9  .........`......
	defb 0c0h,002h,001h,002h,003h,002h,000h,00ch,00fh,00fh,000h,0c0h,0e0h,001h,007h,007h	; 97d9  ................
	defb 0dfh,0dfh,0efh,0f1h,0feh,0c1h,0e3h,0f7h,080h,0c0h,0c0h,080h,000h,000h,0e0h,0f0h	; 97e9  ................
	defb 003h,002h,003h,000h,00fh,00fh,01fh,03fh,03fh,01fh,00fh,007h,0e0h,0c0h,080h,007h	; 97f9  .......??.......
	defb 007h,001h,001h,000h,080h,0a2h,0e3h,0f7h,0f7h,0ffh,0f8h,0fch,0fch,0feh,0ffh,01fh	; 9809  ................
	defb 000h,080h,0c0h,0c0h,0ffh,03fh,03fh,01fh,0e0h,080h,080h,000h,00fh,00fh,007h,003h	; 9819  .....??.........
	defb 001h,000h,0e0h,0f0h,0f8h,0f8h,0fch,0feh,0ffh,0ffh,01fh,0ffh,000h,001h,000h,080h	; 9829  ................
	defb 03fh,01fh,00fh,00fh,007h,003h,001h,007h,000h,0ffh,000h,080h,0e0h,000h,0ffh,07fh	; 9839  ?...............
	defb 03fh,03fh,01fh,01fh,00fh,000h,0ffh,07ch,08eh,07ch,000h,078h,038h,000h,07ch,0feh	; 9849  ??.....|.|.x8.|.
	defb 08eh,00eh,03ch,060h,0feh,000h,07ch,08eh,00eh,03ch,00eh,08eh,07ch,000h,03ch,05ch	; 9859  ..<`..|..<..|.<\
	defb 09ch,0feh,01ch,000h,0feh,080h,0bch,0feh,00eh,08eh,07ch,000h,03ch,060h,0fch,0feh	; 9869  ..........|.<`..
	defb 0e6h,0e6h,07ch,000h,07eh,0feh,006h,008h,030h,070h,070h,000h,07ch,0ceh,0ceh,07ch	; 9879  ..|.~...0pp.|..|
	defb 0ceh,0ceh,07ch,000h,07ch,0feh,0ceh,0ceh,07eh,00eh,07ch,000h,0c0h,0c0h,038h,044h	; 9889  ..|.|...~.|...8D
	defb 0bah,0aah,0b2h,0aah,044h,038h,03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,07ch,08eh	; 9899  ....D8<B....B<|.
	defb 08eh,0feh,08eh,000h,07ch,0e2h,0e2h,0fch,0e2h,0e2h,0fch,000h,07ch,0e2h,0e0h,0e2h	; 98a9  ....|.......|...
	defb 07ch,000h,07ch,0e2h,0fch,000h,07eh,0e0h,0e0h,0feh,0e0h,0e0h,0feh,000h,07eh,0e0h	; 98b9  |.|...~.......~.
	defb 0e0h,0feh,0e0h,000h,07ch,0e6h,0e0h,0eeh,0e2h,0e2h,07ch,000h,062h,0e2h,0e2h,0feh	; 98c9  ....|.....|.b...
	defb 0e2h,000h,018h,038h,000h,006h,00eh,08eh,07ch,000h,062h,0e4h,0e8h,0f0h,0e8h,0e4h	; 98d9  ...8....|.b.....
	defb 0e2h,000h,060h,0e0h,0feh,000h,07ch,0feh,0eah,000h,072h,0f2h,0fah,0eeh,0e6h,0e6h	; 98e9  ..`...|...r.....
	defb 0e2h,000h,07ch,0e2h,07ch,000h,07ch,0e2h,0fch,0e0h,0e0h,000h,07ch,0e2h,0eah,0e6h	; 98f9  ..|.|.|.....|...
	defb 07eh,000h,07ch,0e2h,0e2h,0fch,0e2h,000h,07ch,0e2h,0e0h,07ch,00eh,08eh,07ch,000h	; 9909  ~.|.....|..|..|.
	defb 0feh,038h,000h,062h,0e2h,07ch,000h,062h,0e2h,0e6h,0fch,078h,000h,06ah,0eah,07ch	; 9919  .8.b.|.b...x.j.|
	defb 000h,0c6h,0eeh,07ch,038h,07ch,0eeh,0c6h,000h,0e2h,07ch,038h,000h,0feh,00eh,00ch	; 9929  ...|8|....|8....
	defb 038h,070h,0f0h,0feh,000h	; 9939

; ----------------------------------------------------------------------
; DATOS titulo_colores: Sus colores, comprimidos
;   0x993e..0x99af  (113 bytes)
DATA_titulo_colores:
	defb 036h,000h,088h,0ffh,0ffh,0ffh,093h,0f8h,088h,0b8h,088h,098h,090h,084h,084h,0b0h	; 993e  6...............
	defb 090h,098h,088h,084h,084h,098h,090h,098h,001h,087h,088h,0a8h,001h,0efh,09eh,089h	; 994e  ................
	defb 001h,087h,091h,098h,088h,086h,001h,08fh,002h,085h,003h,086h,002h,088h,083h,08dh	; 995e  ................
	defb 088h,088h,0f0h,088h,0ffh,0ffh,0bah,000h,000h,020h,020h,020h,020h,080h,08ah,080h	; 996e  .........    ...
	defb 08ah,080h,08ah,080h,0a0h,080h,08ah,080h,08ah,00ah,08ah,080h,08ah,080h,08ah,080h	; 997e  ................
	defb 08ah,080h,08ah,080h,0f0h,0b0h,0f0h,0b0h,0f0h,0b0h,0f0h,0b0h,0bfh,0b0h,080h,080h	; 998e  ................
	defb 0b0h,0bfh,08fh,08fh,0b0h,080h,080h,0f0h,0bfh,0b0h,080h,08fh,080h,088h,0f0h,0f0h	; 999e  ................
	defb 0f0h	; 99ae

; ----------------------------------------------------------------------
; DATOS titulo_sprites_d: Los dibujos de los sprites del titulo
;   0x99af..0x9a8f  (224 bytes)
DATA_titulo_sprites_d:
	defb 000h,000h,000h,000h,000h,01fh,03fh,073h,06fh,0f9h,0d0h,0d0h,0f0h,0f8h,0ech,0cch	; 99af  ......?so.......
	defb 000h,000h,000h,000h,000h,0fch,0fah,0a6h,0feh,0fch,000h,000h,000h,000h,000h,000h	; 99bf  ................
	defb 0c4h,0c4h,0c4h,0c4h,0c0h,0e0h,070h,070h,060h,020h,000h,000h,000h,000h,000h,000h	; 99cf  ......pp` ......
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 99df  ................
	defb 000h,000h,000h,000h,000h,041h,063h,077h,07fh,077h,063h,041h,000h,000h,000h,000h	; 99ef  .....Acw.wcA....
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 99ff  ................
	defb 000h,000h,000h,000h,000h,000h,000h,001h,005h,000h,000h,000h,000h,000h,000h,001h	; 9a0f  ................
	defb 000h,000h,000h,000h,000h,000h,000h,0c0h,0c0h,080h,080h,080h,080h,080h,000h,0e0h	; 9a1f  ................
	defb 001h,000h,000h,000h,000h,001h,000h,001h,000h,005h,000h,002h,000h,000h,000h,000h	; 9a2f  ................
	defb 0f0h,0f8h,0feh,0f2h,0f2h,0f2h,030h,0f0h,030h,0f0h,020h,080h,080h,000h,000h,000h	; 9a3f  ......0.0. .....
	defb 000h,000h,000h,000h,00fh,007h,003h,001h,000h,000h,000h,000h,000h,000h,000h,000h	; 9a4f  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9a5f  ................
	defb 000h,000h,000h,000h,000h,001h,001h,001h,001h,000h,000h,000h,000h,000h,000h,000h	; 9a6f  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9a7f  ................

; ----------------------------------------------------------------------
; DATOS efectos_tabla: Los 19 efectos de sonido (0x00-0x12): donde esta la
;   ficha de cada uno
;   0x9a8f..0x9ab5  (38 bytes)
DATA_efectos_tabla:
	defb 0b7h,09ah,0bah,09ah,0bdh,09ah,0c0h,09ah,0c3h,09ah,0c6h,09ah,0c9h,09ah,0cch,09ah	; 9a8f  ................
	defb 0cfh,09ah,0d2h,09ah,0d5h,09ah,0d8h,09ah,0dbh,09ah,0deh,09ah,0e7h,09ah,0eah,09ah	; 9a9f  ................
	defb 0e1h,09ah,0e4h,09ah,0edh,09ah	; 9aaf

; ----------------------------------------------------------------------
; DATOS musicas_tabla: La tabla de musicas (una sola, la 0x80) y el principio
;   de las fichas de efectos
;   0x9ab5..0x9abb  (6 bytes)
DATA_musicas_tabla:
	defb 0f0h,09ah,003h,0f4h,09ah,004h	; 9ab5

; ----------------------------------------------------------------------
; DATOS efectos_fichas: 19 efectos: prioridad y donde empiezan sus notas (3
;   bytes)
;   0x9abb..0x9af0  (53 bytes)
DATA_efectos_fichas:
	defb 0feh,09ah,005h,008h,09bh,006h,012h,09bh,005h,02eh,09bh,006h,041h,09bh,006h,054h	; 9abb  ............A..T
	defb 09bh,00ah,08bh,09bh,00fh,09eh,09bh,006h,0d5h,09bh,006h,003h,09ch,002h,028h,09ch	; 9acb  ..............(.
	defb 00fh,04dh,09ch,00dh,0c3h,09ch,00eh,0e8h,09ch,00fh,035h,09dh,00fh,042h,09dh,00eh	; 9adb  .M........5..B..
	defb 055h,09dh,003h,090h,09dh	; 9aeb

; ----------------------------------------------------------------------
; DATOS musica_canales: La unica musica: sus canales B y C (el C a cero: solo
;   suena uno)
;   0x9af0..0x9af4  (4 bytes)
DATA_musica_canales:
	defb 09ah,09dh,000h,000h	; 9af0

; ----------------------------------------------------------------------
; DATOS efectos_notas: Las notas de los efectos: 9 bytes por nota (mezclador,
;   vibrato, tono, volumen, envolvente, ruido, velocidad y duracion); 0x8n
;   repite, 0xC0 acaba
;   0x9af4..0x9d9a  (678 bytes)
DATA_efectos_notas:
	defb 03eh,024h,0ffh,01eh,001h,020h,002h,017h,000h,0c0h,03eh,0a0h,047h,000h,010h,020h	; 9af4  >$... ....>.G.. 
	defb 010h,00bh,000h,0c0h,03eh,0a0h,035h,000h,005h,020h,000h,003h,000h,0c0h,03eh,0a9h	; 9b04  ....>.5.. ....>.
	defb 022h,010h,010h,020h,001h,01bh,000h,036h,0a3h,0b0h,020h,000h,000h,003h,01dh,000h	; 9b14  ".. ...6.. .....
	defb 03eh,0a0h,0b0h,000h,005h,020h,002h,005h,000h,0c0h,03eh,0a3h,080h,000h,010h,020h	; 9b24  >.... ....>.... 
	defb 001h,012h,000h,03eh,025h,070h,008h,005h,020h,001h,015h,000h,0c0h,036h,023h,0a0h	; 9b34  ...>%p.. ....6#.
	defb 000h,00bh,03fh,001h,009h,000h,037h,03fh,0a0h,000h,007h,03fh,001h,008h,000h,0c0h	; 9b44  ..?...7?...?....
	defb 03eh,02fh,0ffh,0b0h,004h,020h,001h,004h,000h,03eh,02fh,0a5h,09ch,008h,020h,001h	; 9b54  >/... ...>/... .
	defb 007h,000h,03eh,02fh,0ffh,0b0h,004h,020h,001h,004h,000h,03eh,02fh,0a5h,09ch,008h	; 9b64  ..>/... ...>/...
	defb 020h,001h,007h,000h,03eh,03ah,0ffh,08dh,030h,020h,001h,016h,000h,03eh,0a2h,000h	; 9b74   ...>:..0 ...>..
	defb 010h,003h,020h,001h,010h,000h,0c0h,03eh,047h,080h,00ah,000h,000h,004h,032h,000h	; 9b84  .. ....>G.....2.
	defb 03eh,0a2h,050h,000h,003h,020h,001h,010h,000h,0c0h,03eh,026h,0e0h,008h,003h,020h	; 9b94  >.P.. ....>&... 
	defb 004h,013h,000h,03eh,0a0h,090h,000h,003h,020h,000h,00bh,000h,03eh,024h,0ffh,01eh	; 9ba4  ...>.... ...>$..
	defb 001h,020h,002h,015h,000h,03eh,025h,03fh,01eh,001h,020h,002h,015h,000h,03eh,023h	; 9bb4  . ...>%?.. ...>#
	defb 006h,01eh,001h,020h,00ah,020h,000h,03eh,0a2h,050h,000h,003h,020h,001h,010h,000h	; 9bc4  ... . .>.P.. ...
	defb 0c0h,03eh,0a3h,05ah,03bh,000h,000h,002h,00ah,000h,03eh,0a3h,049h,02ah,000h,000h	; 9bd4  .>.Z;.....>.I*..
	defb 002h,006h,000h,03eh,0a3h,0fch,02bh,000h,000h,002h,00ah,000h,03eh,0a3h,05fh,02ah	; 9be4  ...>..+.....>._*
	defb 000h,000h,002h,006h,000h,03eh,0a3h,0a9h,02bh,000h,000h,002h,00bh,000h,0c0h,03eh	; 9bf4  .....>..+......>
	defb 0a1h,0a0h,000h,007h,020h,003h,00bh,000h,03eh,0a1h,095h,000h,015h,020h,005h,020h	; 9c04  .... ...>.... . 
	defb 000h,03eh,0a1h,0a0h,000h,007h,020h,003h,00bh,000h,03eh,0a1h,095h,000h,015h,020h	; 9c14  .>.... ...>.... 
	defb 005h,020h,000h,0c0h,03eh,0a1h,0ddh,029h,000h,000h,001h,003h,000h,03eh,0a1h,0ddh	; 9c24  . ..>..).....>..
	defb 020h,000h,000h,001h,002h,000h,03eh,0a1h,0ddh,018h,000h,000h,001h,003h,000h,03eh	; 9c34   .....>........>
	defb 0a1h,0ddh,010h,000h,000h,001h,002h,000h,0c0h,03eh,0afh,05ah,034h,002h,020h,001h	; 9c44  .........>.Z4. .
	defb 009h,000h,03eh,030h,0f0h,024h,002h,020h,001h,009h,000h,03eh,0afh,05ah,034h,002h	; 9c54  ..>0.$. ...>.Z4.
	defb 020h,001h,009h,000h,03eh,030h,0f0h,024h,002h,020h,001h,009h,000h,03eh,0afh,03dh	; 9c64   ...>0.$. ...>.=
	defb 024h,002h,020h,001h,009h,000h,03eh,030h,01dh,024h,002h,020h,001h,009h,000h,03eh	; 9c74  $. ...>0.$. ...>
	defb 0afh,03dh,024h,002h,020h,001h,009h,000h,03eh,030h,01dh,024h,002h,020h,001h,009h	; 9c84  .=$. ...>0.$. ..
	defb 000h,03eh,0afh,0ach,014h,002h,020h,001h,009h,000h,03eh,030h,082h,014h,002h,020h	; 9c94  .>.... ...>0... 
	defb 001h,009h,000h,03eh,0afh,0ach,014h,002h,020h,001h,009h,000h,03eh,030h,082h,014h	; 9ca4  ...>.... ...>0..
	defb 002h,020h,001h,009h,000h,03eh,045h,044h,019h,000h,000h,003h,04ah,000h,0c0h,03eh	; 9cb4  . ...>ED....J..>
	defb 043h,080h,00ah,000h,000h,006h,044h,000h,036h,028h,000h,01bh,005h,027h,003h,00dh	; 9cc4  C.....D.6(...'..
	defb 000h,03eh,0a2h,068h,010h,000h,000h,001h,020h,000h,03eh,0a2h,031h,00bh,000h,000h	; 9cd4  .>.h.... .>.1...
	defb 001h,007h,000h,0c0h,03eh,0a2h,0b3h,00bh,000h,000h,001h,007h,000h,03eh,0a2h,0b3h	; 9ce4  ....>........>..
	defb 009h,000h,000h,001h,007h,000h,03eh,0a2h,0beh,00ah,000h,000h,001h,00bh,000h,03eh	; 9cf4  ......>........>
	defb 0a2h,0beh,009h,000h,000h,001h,010h,000h,03eh,0a2h,0beh,008h,000h,000h,001h,015h	; 9d04  ........>.......
	defb 000h,03eh,0a2h,0beh,010h,000h,000h,001h,012h,000h,03eh,0a2h,0b3h,00bh,000h,000h	; 9d14  .>........>.....
	defb 001h,00ah,000h,03eh,0a2h,0beh,00ah,000h,000h,001h,007h,000h,087h,01eh,09dh,0c0h	; 9d24  ...>............
	defb 000h,036h,041h,0a0h,008h,01eh,021h,000h,01ch,000h,083h,035h,09dh,0c0h,03eh,0aah	; 9d34  .6A...!....5..>.
	defb 0ffh,0aeh,001h,020h,00fh,0e0h,000h,03eh,0a2h,0ffh,0bdh,010h,020h,001h,0f0h,000h	; 9d44  ... ...>.... ...
	defb 0c0h,03eh,044h,090h,008h,030h,020h,001h,030h,000h,03eh,032h,0b0h,00ch,001h,020h	; 9d54  .>D..0 .0.>2... 
	defb 001h,015h,000h,0c0h,03eh,0a1h,0a0h,000h,006h,020h,002h,006h,000h,03eh,0a1h,07fh	; 9d64  ....>.... ...>..
	defb 000h,005h,020h,002h,005h,000h,03eh,0a1h,07fh,000h,005h,020h,002h,005h,000h,03eh	; 9d74  .. ...>.... ...>
	defb 0a1h,0a0h,000h,005h,020h,002h,005h,000h,085h,068h,09dh,0c0h,03eh,0aah,010h,07bh	; 9d84  .... ....h..>..{
	defb 000h,000h,001h,060h,000h,0c0h	; 9d94

; ----------------------------------------------------------------------
; DATOS musica_notas: Las 151 notas de la musica de fondo, con sus
;   repeticiones
;   0x9d9a..0xa2f0  (1366 bytes)
DATA_musica_notas:
	defb 03dh,0a1h,03dh,028h,000h,000h,001h,00ah,000h,03dh,0a1h,03dh,020h,000h,000h,001h	; 9d9a  =.=(.....=.= ...
	defb 002h,000h,03dh,0a1h,03dh,029h,000h,000h,001h,00ah,000h,03dh,0a1h,03dh,020h,000h	; 9daa  ..=.=).....=.= .
	defb 000h,001h,00ah,000h,03dh,0a1h,0c6h,018h,000h,000h,001h,014h,000h,03dh,0a1h,0c6h	; 9dba  ....=........=..
	defb 010h,000h,000h,001h,002h,000h,03dh,0a1h,082h,018h,000h,000h,001h,014h,000h,03dh	; 9dca  ......=........=
	defb 0a1h,082h,010h,000h,000h,001h,002h,000h,03dh,0a1h,054h,018h,000h,000h,001h,00ah	; 9dda  ........=.T.....
	defb 000h,03dh,0a1h,054h,010h,000h,000h,001h,002h,000h,03dh,0a1h,041h,018h,000h,000h	; 9dea  .=.T......=.A...
	defb 001h,00ah,000h,03dh,0a1h,041h,010h,000h,000h,001h,002h,000h,03dh,0a1h,054h,018h	; 9dfa  ...=.A......=.T.
	defb 000h,000h,001h,00ah,000h,03dh,0a1h,054h,010h,000h,000h,001h,002h,000h,03dh,0a1h	; 9e0a  .....=.T......=.
	defb 082h,018h,000h,000h,001h,00ah,000h,03dh,0a1h,082h,010h,000h,000h,001h,002h,000h	; 9e1a  .......=........
	defb 03dh,0a1h,094h,018h,000h,000h,001h,00ah,000h,03dh,0a1h,094h,010h,000h,000h,001h	; 9e2a  =........=......
	defb 002h,000h,03dh,0a1h,082h,019h,000h,000h,001h,014h,000h,03dh,0a1h,082h,018h,000h	; 9e3a  ..=........=....
	defb 000h,001h,007h,000h,03dh,0a1h,082h,017h,000h,000h,001h,003h,000h,03dh,0a1h,082h	; 9e4a  ....=........=..
	defb 010h,000h,000h,001h,002h,000h,03dh,0a1h,03dh,028h,000h,000h,001h,00ah,000h,03dh	; 9e5a  ......=.=(.....=
	defb 0a1h,03dh,020h,000h,000h,001h,002h,000h,03dh,0a1h,03dh,029h,000h,000h,001h,00ah	; 9e6a  .= .....=.=)....
	defb 000h,03dh,0a1h,03dh,020h,000h,000h,001h,00ah,000h,03dh,0a1h,0c6h,018h,000h,000h	; 9e7a  .=.= .....=.....
	defb 001h,014h,000h,03dh,0a1h,0c6h,010h,000h,000h,001h,002h,000h,03dh,0a1h,082h,018h	; 9e8a  ...=........=...
	defb 000h,000h,001h,014h,000h,03dh,0a1h,082h,010h,000h,000h,001h,002h,000h,03dh,0a1h	; 9e9a  .....=........=.
	defb 054h,018h,000h,000h,001h,00ah,000h,03dh,0a1h,054h,010h,000h,000h,001h,002h,000h	; 9eaa  T......=.T......
	defb 03dh,0a1h,041h,018h,000h,000h,001h,00ah,000h,03dh,0a1h,041h,010h,000h,000h,001h	; 9eba  =.A......=.A....
	defb 002h,000h,03dh,0a1h,054h,018h,000h,000h,001h,00ah,000h,03dh,0a1h,054h,010h,000h	; 9eca  ..=.T......=.T..
	defb 000h,001h,002h,000h,03dh,0a1h,082h,018h,000h,000h,001h,00ah,000h,03dh,0a1h,082h	; 9eda  ....=........=..
	defb 010h,000h,000h,001h,002h,000h,03dh,0a1h,0c6h,018h,000h,000h,001h,00ah,000h,03dh	; 9eea  ......=........=
	defb 0a1h,0c6h,010h,000h,000h,001h,002h,000h,03dh,0a1h,03dh,028h,000h,000h,001h,014h	; 9efa  ........=.=(....
	defb 000h,03dh,0a1h,03dh,027h,000h,000h,001h,007h,000h,03dh,0a1h,03dh,026h,000h,000h	; 9f0a  .=.='.....=.=&..
	defb 001h,003h,000h,03dh,0a1h,03dh,010h,000h,000h,001h,00ah,000h,03dh,0a1h,03dh,028h	; 9f1a  ...=.=......=.=(
	defb 000h,000h,001h,00ah,000h,03dh,0a1h,03dh,020h,000h,000h,001h,002h,000h,03dh,0a1h	; 9f2a  .....=.= .....=.
	defb 03dh,029h,000h,000h,001h,00ah,000h,03dh,0a1h,03dh,020h,000h,000h,001h,00ah,000h	; 9f3a  =).....=.= .....
	defb 03dh,0a1h,0c6h,018h,000h,000h,001h,014h,000h,03dh,0a1h,0c6h,010h,000h,000h,001h	; 9f4a  =........=......
	defb 002h,000h,03dh,0a1h,082h,018h,000h,000h,001h,014h,000h,03dh,0a1h,082h,010h,000h	; 9f5a  ..=........=....
	defb 000h,001h,002h,000h,03dh,0a1h,054h,018h,000h,000h,001h,00ah,000h,03dh,0a1h,054h	; 9f6a  ....=.T......=.T
	defb 010h,000h,000h,001h,002h,000h,03dh,0a1h,041h,018h,000h,000h,001h,00ah,000h,03dh	; 9f7a  ......=.A......=
	defb 0a1h,041h,010h,000h,000h,001h,002h,000h,03dh,0a1h,054h,018h,000h,000h,001h,00ah	; 9f8a  .A......=.T.....
	defb 000h,03dh,0a1h,054h,010h,000h,000h,001h,002h,000h,03dh,0a1h,082h,018h,000h,000h	; 9f9a  .=.T......=.....
	defb 001h,00ah,000h,03dh,0a1h,082h,010h,000h,000h,001h,002h,000h,03dh,0a1h,094h,018h	; 9faa  ...=........=...
	defb 000h,000h,001h,00ah,000h,03dh,0a1h,094h,010h,000h,000h,001h,002h,000h,03dh,0a1h	; 9fba  .....=........=.
	defb 082h,019h,000h,000h,001h,014h,000h,03dh,0a1h,082h,018h,000h,000h,001h,007h,000h	; 9fca  .......=........
	defb 03dh,0a1h,082h,017h,000h,000h,001h,003h,000h,03dh,0a1h,082h,010h,000h,000h,001h	; 9fda  =........=......
	defb 002h,000h,03dh,0a1h,03dh,028h,000h,000h,001h,00ah,000h,03dh,0a1h,03dh,020h,000h	; 9fea  ..=.=(.....=.= .
	defb 000h,001h,002h,000h,03dh,0a1h,03dh,029h,000h,000h,001h,00ah,000h,03dh,0a1h,03dh	; 9ffa  ....=.=).....=.=
	defb 020h,000h,000h,001h,00ah,000h,03dh,0a1h,0c6h,018h,000h,000h,001h,014h,000h,03dh	; a00a   .....=........=
	defb 0a1h,0c6h,010h,000h,000h,001h,002h,000h,03dh,0a1h,082h,018h,000h,000h,001h,014h	; a01a  ........=.......
	defb 000h,03dh,0a1h,082h,010h,000h,000h,001h,002h,000h,03dh,0a1h,054h,018h,000h,000h	; a02a  .=........=.T...
	defb 001h,00ah,000h,03dh,0a1h,054h,010h,000h,000h,001h,002h,000h,03dh,0a1h,041h,018h	; a03a  ...=.T......=.A.
	defb 000h,000h,001h,00ah,000h,03dh,0a1h,041h,010h,000h,000h,001h,002h,000h,03dh,0a1h	; a04a  .....=.A......=.
	defb 054h,018h,000h,000h,001h,00ah,000h,03dh,0a1h,054h,010h,000h,000h,001h,002h,000h	; a05a  T......=.T......
	defb 03dh,0a1h,082h,018h,000h,000h,001h,00ah,000h,03dh,0a1h,082h,010h,000h,000h,001h	; a06a  =........=......
	defb 002h,000h,03dh,0a1h,0c6h,018h,000h,000h,001h,00ah,000h,03dh,0a1h,0c6h,010h,000h	; a07a  ..=........=....
	defb 000h,001h,002h,000h,03dh,0a1h,03dh,028h,000h,000h,001h,014h,000h,03dh,0a1h,03dh	; a08a  ....=.=(.....=.=
	defb 020h,000h,000h,001h,002h,000h,03dh,0a1h,0a9h,028h,000h,000h,001h,007h,000h,03dh	; a09a   .....=..(.....=
	defb 0a1h,0a9h,020h,000h,000h,001h,002h,000h,03dh,0a1h,03dh,028h,000h,000h,001h,007h	; a0aa  .. .....=.=(....
	defb 000h,03dh,0a1h,03dh,020h,000h,000h,001h,002h,000h,03dh,0a1h,0fdh,018h,000h,000h	; a0ba  .=.= .....=.....
	defb 001h,007h,000h,03dh,0a1h,0fdh,010h,000h,000h,001h,002h,000h,03dh,0a1h,0e1h,018h	; a0ca  ...=........=...
	defb 000h,000h,001h,010h,000h,03dh,0a1h,0e1h,010h,000h,000h,001h,002h,000h,03dh,0a1h	; a0da  .....=........=.
	defb 0c6h,018h,000h,000h,001h,005h,000h,03dh,0a1h,0c6h,010h,000h,000h,001h,002h,000h	; a0ea  .......=........
	defb 03dh,0a1h,0e1h,018h,000h,000h,001h,010h,000h,03dh,0a1h,0e1h,010h,000h,000h,001h	; a0fa  =........=......
	defb 002h,000h,03dh,0a1h,0c6h,018h,000h,000h,001h,005h,000h,03dh,0a1h,0c6h,010h,000h	; a10a  ..=........=....
	defb 000h,001h,002h,000h,03dh,0a1h,082h,018h,000h,000h,001h,010h,000h,03dh,0a1h,082h	; a11a  ....=........=..
	defb 010h,000h,000h,001h,002h,000h,03dh,0a1h,0ach,018h,000h,000h,001h,005h,000h,03dh	; a12a  ......=........=
	defb 0a1h,0ach,010h,000h,000h,001h,002h,000h,03dh,0a1h,0c6h,018h,000h,000h,001h,010h	; a13a  ........=.......
	defb 000h,03dh,0a1h,0c6h,010h,000h,000h,001h,002h,000h,03dh,0a1h,03dh,018h,000h,000h	; a14a  .=........=.=...
	defb 001h,005h,000h,03dh,0a1h,03dh,010h,000h,000h,001h,002h,000h,03dh,0a1h,0c6h,018h	; a15a  ...=.=......=...
	defb 000h,000h,001h,010h,000h,03dh,0a1h,0c6h,010h,000h,000h,001h,002h,000h,03dh,0a1h	; a16a  .....=........=.
	defb 0ach,018h,000h,000h,001h,005h,000h,03dh,0a1h,0ach,010h,000h,000h,001h,002h,000h	; a17a  .......=........
	defb 03dh,0a1h,0c6h,018h,000h,000h,001h,010h,000h,03dh,0a1h,0c6h,010h,000h,000h,001h	; a18a  =........=......
	defb 002h,000h,03dh,0a1h,082h,018h,000h,000h,001h,005h,000h,03dh,0a1h,082h,010h,000h	; a19a  ..=........=....
	defb 000h,001h,002h,000h,03dh,0a1h,082h,017h,000h,000h,001h,010h,000h,03dh,0a1h,082h	; a1aa  ....=........=..
	defb 010h,000h,000h,001h,002h,000h,03dh,0a1h,082h,017h,000h,000h,001h,005h,000h,03dh	; a1ba  ......=........=
	defb 0a1h,082h,010h,000h,000h,001h,002h,000h,03dh,0a1h,082h,018h,000h,000h,001h,007h	; a1ca  ........=.......
	defb 000h,03dh,0a1h,082h,010h,000h,000h,001h,003h,000h,03dh,0a1h,054h,018h,000h,000h	; a1da  .=........=.T...
	defb 001h,007h,000h,03dh,0a1h,054h,010h,000h,000h,001h,002h,000h,03dh,0a1h,041h,018h	; a1ea  ...=.T......=.A.
	defb 000h,000h,001h,007h,000h,03dh,0a1h,041h,010h,000h,000h,001h,002h,000h,03dh,0a1h	; a1fa  .....=.A......=.
	defb 01eh,019h,000h,000h,001h,014h,000h,03dh,0a1h,01eh,010h,000h,000h,001h,002h,000h	; a20a  .......=........
	defb 03dh,0a1h,0e2h,008h,000h,000h,001h,010h,000h,03dh,0a1h,0e2h,000h,000h,000h,001h	; a21a  =........=......
	defb 003h,000h,03dh,0a1h,0d5h,008h,000h,000h,001h,010h,000h,03dh,0a1h,0d5h,000h,000h	; a22a  ..=........=....
	defb 000h,001h,003h,000h,03dh,0a1h,0e2h,008h,000h,000h,001h,009h,000h,03dh,0a1h,0e2h	; a23a  ....=........=..
	defb 000h,000h,000h,001h,003h,000h,03dh,0a1h,01eh,018h,000h,000h,001h,010h,000h,03dh	; a24a  ......=........=
	defb 0a1h,01eh,010h,000h,000h,001h,003h,000h,03dh,0a1h,082h,018h,000h,000h,001h,005h	; a25a  ........=.......
	defb 000h,03dh,0a1h,082h,010h,000h,000h,001h,002h,000h,03dh,0a1h,01eh,018h,000h,000h	; a26a  .=........=.....
	defb 001h,007h,000h,03dh,0a1h,01eh,010h,000h,000h,001h,002h,000h,03dh,0a1h,02fh,018h	; a27a  ...=........=./.
	defb 000h,000h,001h,007h,000h,03dh,0a1h,02fh,010h,000h,000h,001h,002h,000h,03dh,0a1h	; a28a  .....=./......=.
	defb 082h,018h,000h,000h,001h,007h,000h,03dh,0a1h,082h,010h,000h,000h,001h,002h,000h	; a29a  .......=........
	defb 03dh,0a1h,02fh,018h,000h,000h,001h,014h,000h,03dh,0a1h,02fh,010h,000h,000h,001h	; a2aa  =./......=./....
	defb 002h,000h,03dh,0a1h,01eh,017h,000h,000h,001h,007h,000h,03dh,0a1h,01eh,018h,000h	; a2ba  ..=........=....
	defb 000h,001h,00dh,000h,03dh,0a1h,01eh,017h,000h,000h,001h,00ah,000h,03dh,0a1h,01eh	; a2ca  ....=........=..
	defb 016h,000h,000h,001h,00ah,000h,03dh,0a1h,01eh,010h,000h,000h,001h,014h,000h,082h	; a2da  ......=.........
	defb 09ah,09dh,082h,09ah,09dh,0ffh	; a2ea

; ----------------------------------------------------------------------
; DATOS copia_de_la_ram: Restos: una copia de la RAM del MSX de 0xF001 a
;   0xFFFF que se colo al grabar el cartucho (los ganchos, todos "ret", caen
;   en 0xFD9A; las rutinas de slot, en 0xF380; las teclas de funcion "color",
;   "auto", "goto", en 0xF87F)
;   0xa2f0..0xb2ef  (4095 bytes)
DATA_copia_de_la_ram:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a2f0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a300  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a310  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; a320  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a330  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a340  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0c0h,0ffh,084h	; a350  ................
	defb 002h,0ffh,0ffh,0ffh,0ffh,0c0h,0ffh,084h,002h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a360  ................
	defb 0ffh,024h,012h,0c0h,0ffh,084h,002h,0ffh,0ffh,042h,001h,000h,001h,092h,0f3h,010h	; a370  .$.......B......
	defb 000h,0a3h,07dh,001h,000h,004h,040h,0dah,0fch,0c2h,0fch,017h,07dh,000h,000h,0ffh	; a380  ..}...@.....}...
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a390  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; a3a0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a3b0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a3c0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a3d0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0ffh	; a3e0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a3f0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a400  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a410  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; a420  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a430  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a440  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,06eh,0f1h,077h,0f2h,0efh,0a2h,000h	; a450  .........n.w....
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0ffh	; a460  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a470  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a480  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a490  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; a4a0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a4b0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a4c0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a4d0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0ffh	; a4e0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a4f0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a500  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a510  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; a520  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a530  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a540  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a550  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0ffh	; a560  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a570  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a580  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a590  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; a5a0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a5b0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a5c0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a5d0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0ffh	; a5e0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a5f0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a600  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a610  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; a620  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a630  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a640  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,094h,07eh,064h	; a650  ..............~d
	defb 001h,0c8h,000h,0cfh,07ch,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0d3h	; a660  ....|...........
	defb 0a8h,05eh,018h,003h,0d3h,0a8h,073h,07ah,0d3h,0a8h,0c9h,0d3h,0a8h,008h,0cdh,098h	; a670  .^....sz........
	defb 0f3h,008h,0f1h,0d3h,0a8h,008h,0c9h,0ddh,0e9h,05ah,047h,05ah,047h,05ah,047h,05ah	; a680  .........ZGZGZGZ
	defb 047h,05ah,047h,05ah,047h,05ah,047h,05ah,047h,05ah,047h,05ah,047h,027h,01dh,01dh	; a690  GZGZGZGZGZGZG'..
	defb 018h,00eh,000h,000h,000h,000h,000h,008h,000h,000h,000h,000h,000h,018h,000h,020h	; a6a0  ............... 
	defb 000h,000h,000h,01bh,000h,038h,000h,018h,000h,020h,000h,000h,000h,01bh,000h,038h	; a6b0  .....8... .....8
	defb 000h,008h,000h,000h,000h,000h,000h,01bh,000h,038h,001h,00fh,001h,000h,000h,0e0h	; a6c0  .........8......
	defb 006h,080h,000h,036h,007h,007h,09fh,0f1h,00fh,004h,007h,0c3h,0efh,0a2h,0c3h,0efh	; a6d0  ...6............
	defb 0a2h,00fh,059h,0f9h,0ffh,001h,001h,0f0h,0fbh,0f0h,0fbh,053h,05ch,026h,02dh,00fh	; a6e0  ..Y........S\&-.
	defb 025h,02dh,00eh,016h,01fh,053h,05ch,026h,02dh,00fh,000h,001h,000h,001h,03ah,0efh	; a6f0  %-...S\&-.....:.
	defb 0a2h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,03ah,0efh,0a2h	; a700  .............:..
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a710  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a720  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a730  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a740  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a750  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a760  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a770  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a780  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a790  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a7a0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a7b0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a7c0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a7d0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a7e0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a7f0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a800  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a810  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a820  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a830  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,02ch,000h,000h,000h	; a840  ............,...
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a850  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a860  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a870  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a880  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a890  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a8a0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a8b0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a8c0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a8d0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a8e0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a8f0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a900  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a910  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a920  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a930  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a940  ................
	defb 000h,000h,003h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a950  ................
	defb 000h,068h,0f1h,0a0h,0f0h,001h,0c0h,07ah,0f6h,01dh,0fdh,07eh,000h,000h,000h,000h	; a960  .h.....z...~....
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a970  ................
	defb 000h,000h,000h,000h,000h,000h,000h,01dh,0fdh,07eh,068h,0f1h,000h,000h,000h,000h	; a980  .........~h.....
	defb 000h,000h,000h,000h,000h,000h,000h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h	; a990  ................
	defb 09eh,0f0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a9a0  ................
	defb 000h,003h,0c0h,003h,0c0h,003h,0c0h,000h,0c0h,008h,008h,008h,008h,008h,008h,008h	; a9b0  ................
	defb 008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h,008h	; a9c0  ................
	defb 008h,008h,008h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a9d0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a9e0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a9f0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aa00  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aa10  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aa20  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0e4h,0e5h,0a3h,000h,000h	; aa30  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aa40  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aa50  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aa60  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aa70  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aa80  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aa90  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aaa0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aab0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aac0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aad0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,07ah,0f6h,000h,000h,000h,000h,000h,000h,000h	; aae0  .......z........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aaf0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ab00  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ab10  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ab20  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ab30  ................
	defb 000h,000h,000h,000h,000h,000h,000h,040h,064h,096h,051h,037h,023h,058h,001h,06ah	; ab40  .......@d.Q7#X.j
	defb 0f1h,077h,0f1h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ab50  .w..............
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,063h,06fh	; ab60  ..............co
	defb 06ch,06fh,072h,020h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,061h,075h	; ab70  lor ..........au
	defb 074h,06fh,020h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,067h,06fh	; ab80  to ...........go
	defb 074h,06fh,020h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,06ch,069h	; ab90  to ...........li
	defb 073h,074h,020h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,072h,075h	; aba0  st ...........ru
	defb 06eh,00dh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,063h,06fh	; abb0  n.............co
	defb 06ch,06fh,072h,020h,031h,035h,02ch,034h,02ch,037h,00dh,000h,000h,000h,063h,06ch	; abc0  lor 15,4,7....cl
	defb 06fh,061h,064h,022h,0efh,0a2h,000h,000h,000h,000h,000h,000h,000h,000h,063h,06fh	; abd0  oad"..........co
	defb 06eh,074h,00dh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,06ch,069h	; abe0  nt............li
	defb 073h,074h,02eh,00dh,01eh,01eh,000h,000h,000h,000h,000h,000h,000h,000h,00ch,072h	; abf0  st.............r
	defb 075h,06eh,00dh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0bfh	; ac00  un..............
	defb 01bh,000h,018h,000h,000h,000h,038h,000h,01bh,000h,000h,000h,000h,000h,000h,000h	; ac10  ......8.........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ac20  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ac30  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,07fh,075h,0f9h,000h,000h	; ac40  ............u...
	defb 000h,07fh,0f5h,0f9h,000h,000h,000h,07fh,075h,0fah,0efh,0a2h,000h,000h,000h,000h	; ac50  ........u.......
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ac60  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ac70  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ac80  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ac90  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aca0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; acb0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; acc0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; acd0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ace0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; acf0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ad00  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ad10  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ad20  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ad30  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ad40  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ad50  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ad60  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ad70  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ad80  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ad90  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ada0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; adb0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; adc0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; add0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ade0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; adf0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ae00  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ae10  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ae20  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,004h	; ae30  ................
	defb 004h,078h,088h,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ae40  .x..............
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ae50  ................
	defb 000h,000h,000h,000h,004h,004h,078h,088h,0ffh,000h,000h,000h,000h,000h,000h,000h	; ae60  ......x.........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ae70  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,004h,004h,078h,088h,0ffh,000h,000h	; ae80  ...........x....
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ae90  ................
	defb 000h,018h,017h,016h,015h,014h,013h,012h,011h,010h,00fh,00eh,00dh,00ch,00bh,00ah	; aea0  ................
	defb 009h,008h,007h,006h,005h,004h,003h,002h,001h,000h,000h,000h,000h,000h,000h,000h	; aeb0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; aec0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; aed0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aee0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aef0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af00  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af10  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af20  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0c0h,080h,0f3h,000h,000h,000h,000h,000h	; af30  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af40  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af50  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af60  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af70  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0e4h,0efh,0a2h	; af80  ................
	defb 000h,01ch,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,001h	; af90  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; afa0  ................
	defb 000h,000h,000h,000h,00fh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; afb0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; afc0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; afd0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; afe0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aff0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b000  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b010  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b020  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b030  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b040  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b050  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b060  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b070  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b080  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b090  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b0a0  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b0b0  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b0c0  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b0d0  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b0e0  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b0f0  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b100  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b110  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b120  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b130  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b140  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b150  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b160  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b170  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b180  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b190  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b1a0  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b1b0  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b1c0  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h	; b1d0  ................
	defb 0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c9h,0c3h	; b1e0  ................
	defb 021h,06ah,0c3h,0f2h,06ah,0c3h,091h,06bh,0c3h,09ch,06bh,0c3h,0a8h,06bh,0c3h,0dfh	; b1f0  !j..j..k..k..k..
	defb 06bh,0c3h,01ch,06ch,0c3h,053h,06ch,0c3h,0deh,06bh,0c3h,01bh,06ch,0c3h,052h,06ch	; b200  k..l.Sl..k..l.Rl
	defb 079h,0feh,01bh,020h,009h,03ah,0fbh,06ah,0b7h,0cah,0e5h,06ah,018h,005h,0feh,018h	; b210  y.. .:.j...j....
	defb 0cah,0ceh,06ah,03ah,0fah,06ah,0b7h,0c8h,0cbh,07fh,028h,021h,021h,021h,06bh,07eh	; b220  ..j:.j....(!!!k~
	defb 0b9h,028h,009h,0b7h,0cah,0ceh,06ah,023h,023h,023h,018h,0f3h,032h,0ffh,06ah,023h	; b230  .(....j###..2.j#
	defb 07eh,047h,032h,0fah,06ah,023h,07eh,032h,0fch,06ah,078h,018h,008h,02ah,0fdh,06ah	; b240  ~G2.j#~2.jx..*.j
	defb 071h,023h,022h,0fdh,06ah,0e1h,03dh,032h,0fah,06ah,0c0h,03ah,0ffh,06ah,0feh,049h	; b250  q#".j.=2.j.:.j.I
	defb 028h,004h,0feh,046h,020h,01fh,03ah,0fbh,06ah,0b7h,020h,015h,03dh,032h,0fbh,06ah	; b260  (..F .:.j. .=2.j
	defb 079h,0d6h,020h,028h,00ch,038h,00ah,0feh,021h,038h,002h,03eh,020h,032h,0fah,06ah	; b270  y. (.8..!8.> 2.j
	defb 0c9h,0afh,032h,0fbh,06ah,021h,000h,06bh,03ah,0fch,06ah,0b7h,03ah,0ffh,06ah,0cah	; b280  ..2.j!.k:.j.:.j.
	defb 02dh,040h,03ah,0fch,06ah,0cbh,04fh,03ah,0ffh,06ah,028h,015h,0feh,06eh,020h,00eh	; b290  -@:.j.O:.j(..n .
	defb 03ah,000h,06bh,0feh,034h,028h,00ah,0feh,039h,028h,006h,03ah,0ffh,06ah,0cdh,012h	; b2a0  :.k.4(..9(.:.j..
	defb 071h,03ah,0fch,06ah,0cbh,047h,03ah,0ffh,06ah,0c2h,015h,051h,0c9h,0cdh,0f2h,06ah	; b2b0  q:.j.G:.j..Q...j
	defb 0e1h,0feh,018h,0c8h,022h,0dfh,06ah,022h,0e3h,06ah,0c5h,00eh,01bh,0cdh,0efh,0a2h	; b2c0  ....".j".j......
	defb 0c1h,0c3h,0efh,0a2h,03eh,080h,032h,0fah,06ah,021h,000h,06bh,022h,0fdh,06ah,0e1h	; b2d0  ....>.2.j!.k".j.
	defb 0c9h,0afh,032h,0fah,06ah,032h,0fbh,06ah,0c9h,000h,000h,000h,000h,06bh,000h	; b2e0  ..2.j2.j.....k.

; ----------------------------------------------------------------------
; DATOS ceros: Ceros
;   0xb2ef..0xb400  (273 bytes)
DATA_ceros:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b2ef  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b2ff  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b30f  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b31f  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b32f  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b33f  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b34f  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b35f  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b36f  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b37f  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b38f  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b39f  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b3af  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b3bf  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b3cf  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b3df  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b3ef  ................
	defb 000h	; b3ff

; ----------------------------------------------------------------------
; DATOS relleno_ff: Relleno: 0xFF hasta el final
;   0xb400..0xc000  (3072 bytes)
DATA_relleno_ff:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b400  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b410  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b420  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b430  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b440  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b450  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b460  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b470  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b480  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b490  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b4a0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b4b0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b4c0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b4d0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b4e0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b4f0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b500  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b510  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b520  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b530  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b540  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b550  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b560  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b570  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b580  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b590  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b5a0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b5b0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b5c0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b5d0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b5e0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b5f0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b600  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b610  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b620  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b630  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b640  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b650  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b660  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b670  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b680  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b690  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b6a0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b6b0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b6c0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b6d0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b6e0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b6f0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b700  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b710  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b720  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b730  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b740  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b750  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b760  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b770  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b780  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b790  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b7a0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b7b0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b7c0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b7d0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b7e0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b7f0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b800  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b810  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b820  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b830  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b840  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b850  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b860  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b870  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b880  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b890  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b8a0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b8b0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b8c0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b8d0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b8e0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b8f0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b900  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b910  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b920  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b930  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b940  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b950  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b960  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b970  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b980  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b990  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b9a0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b9b0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b9c0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b9d0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b9e0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b9f0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ba00  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ba10  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ba20  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ba30  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ba40  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ba50  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ba60  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ba70  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ba80  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ba90  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; baa0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bab0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bac0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bad0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bae0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; baf0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bb00  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bb10  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bb20  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bb30  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bb40  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bb50  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bb60  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bb70  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bb80  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bb90  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bba0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bbb0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bbc0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bbd0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bbe0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bbf0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bc00  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bc10  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bc20  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bc30  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bc40  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bc50  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bc60  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bc70  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bc80  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bc90  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bca0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bcb0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bcc0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bcd0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bce0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bcf0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bd00  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bd10  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bd20  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bd30  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bd40  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bd50  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bd60  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bd70  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bd80  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bd90  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bda0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bdb0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bdc0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bdd0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bde0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bdf0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; be00  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; be10  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; be20  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; be30  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; be40  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; be50  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; be60  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; be70  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; be80  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; be90  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bea0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; beb0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bec0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bed0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bee0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bef0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bf00  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bf10  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bf20  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bf30  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bf40  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bf50  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bf60  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bf70  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bf80  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bf90  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfa0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfb0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfc0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfd0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfe0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bff0  ................
