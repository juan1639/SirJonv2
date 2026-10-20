org $8000

ATTR_S:	equ $5c8d	;Variable sistema: atributos (FBPPPIII)
ATTR_T:	equ $5c8f	;Variable sistema: atributos temporales
LOCATE:	equ $0dd9	;Rutina sistema: (Locate), (B = ycoord, C = xcoord)
CLS:	equ $0daf	;Rutina sistema: CLS + atributos
BORDCR:	equ $5c48	;Variable sistema (Borde)
beeper: equ $03b5	;Rutina Beeper (HL = Nota, DE = Duracion)...
			;...( Altera Registros: AF,BC,DE,HL,IX )

s_1:		EQU $0f07		; Nota (Vida menos)0d07
s1_dura:	EQU $0082 / $10		; Duracion

s_2:		EQU $066e		; Nota (Pal)
s2_dura:	EQU $0105 / $10		; Duracion

s_3:		EQU $0326		; Nota (Reb)
s3_dura:	EQU $020B / $10		; Duracion

s_4:		equ $0d0f		; Nota (Pulsa-Menus)
s4_dura:	equ $0184 / $10		; Duracion	

;--------------------------------------------------------------------------
;---		ESTABLECE BORDE & ATRIBUTOS GENERALES                   ---
;--------------------------------------------------------------------------
ld	a, $07		;Carga atributos al A (0000 1110)
ld	hl, ATTR_T	;Carga varible sistema a HL
ld	(hl), a		;Carga A en direccion(HL)

ld	hl, ATTR_S	;Lo mismo pero a la otra variable sistema
ld	(hl), a

ld	a,%00001111	; 00BBB000 (B = Borde)
ld	(BORDCR),a

call	CLS		; Llama a rutina sistema CLS
ld	a,$01		; Color del Borde
out	($fe),a		; Puerto FE

comienzo_ymp:
;call menu_principal

ld	a,$00
ld	(nivel),a

otra_pantalla:
call 	sub_cls
call 	sub_clsattr
call	marcadores
call	reset_settings

call	selecc_attr_generales
call	selecc_pantalla_dibujar

;==========================================================================
;---                                                                    ---
;---	               B U C L E    P R I N C I P A L                   ---
;---                                                                    ---
;==========================================================================
bucle_principal:
ld	a,(jugador_set)
bit	6,a		; Si Bit6=1, entonces Saltarse las Subrutinas
jr	nz,ralentizaciones

ld	a,(vidas)
or	a
jp	z,game_over

call	contadores		; SUB Contadores Iteraciones Bucle
call	selecc_redibujables	; SUB Selecc elementos redibujables (nivel?)
call	selecc_attr_redibujables ; SUB Selecc attr redibujables (nivel?)
call	selecc_jugabilidad	; SUB Selecc jugabilidad/acciones (nivel?)

call 	teclado			; SUB Leer Teclado/JoyStick
jr	cambio_nivel	; JR Evalua un posible cambio pantalla (adelante/atras)

dibujar_eljugador:
call 	dibuja_jugador		; SUB Dibuja Jugador
			
ld	a,(velocidad)
call	ralentiza		; SUB Ralentiza (halt)

jr	bucle_principal		; --------- Fin Bucle Principal -----------
jr 	$		; -------------------------------------------------

;--------------------------------------------------------------------------
cambio_nivel:
ld	a,(settings)
bit	0,a
jr	nz,otra_pantalla
jr	z,dibujar_eljugador
jr	$

;--------------------------------------------------------------------------
ralentizaciones:
call	selecc_jugabilidad
call	explo_jugador
ld	a,(velocidad)
call	ralentiza
jr	bucle_principal
jr	$

;==========================================================================
;=================        S U B R U T I N A S        ======================
;==========================================================================
;---		             SUB - DIBUJA JUGADOR                       ---
;---                                                                    ---
;---  HL---> Coordenadas Jugador        ...  B---> Bucle Scanlines      ---
;---  DE---> Puntero direcciones Sprite ...  C---> Bucle para Incr DE   ---
;--------------------------------------------------------------------------
dibuja_jugador:
ld	a,(jugador_y)
ld	h,a				; H = Coordenada Y Jugador
ld	a,(jugador_x)
ld	l,a				; L = Coordenada X Jugador

;----------------------------------------------------------------------
ld	a,(jugador_set)
bit	2,a
jp	nz,rotacion_entrepuertas

;----------------------------------------------------------------------
ld	a,(jugador_set)
bit	0,a		; Bit0= Z ... entonces salta a las animaciones...
jr	z,ala_derecha	; ...yendo a la Derecha, Si no sigue (debajo)

;----------------------------------------------------------------------
ala_izquierda:
bit	1,a		; Comprobar si estamos agachados, si Bit1=1...(Ojo JP)
jp	nz,anima_agachadoizq	; ...entonces salta a animaciones agachado-izq 

bit	4,a		; Comprobar si estamos atacando a espada, si Bit4=1...(JP)
jp	nz,anima_atacandoizda	; ...entonces salta a animaciones atacando-izda

ld	a,(anima_jugador)
bit	0,a		; Comprobar tb cual animacion toca...	
call	z,anima_unoizda		; Posicionar puntero DE en una u otra...
call	nz,anima_dosizda	; ...animacion (yendo a la Izda)
jr	rotaciones_jugador	; Salta (mas abajo)...

;----------------------------------------------------------------------
ala_derecha:
bit	1,a		; Comprobar si estamos agachados, si Bit1=1...
jp	nz,anima_agachadodcha	; ...entonces salta a animaciones agachado-dcha

bit	4,a		; Comprobar si estamos atacando a espada, si Bit4=1...
jp	nz,anima_atacandodcha	; ...entonces salta a animaciones atacando-dcha

ld	a,(anima_jugador)
bit	0,a		; Comprobar tb cual animacion toca...
call	z,anima_uno		; Posionar Puntero DE en una u otra...
call	nz,anima_dos		; ... animacion (yendo a la Dcha)

;----------------------------------------------------------------------
rotaciones_jugador:
ld	a,(rota_jugador)
or 	a			; Si cambio de Columna (Borrar yendo...
call	z,borra_jugador		; ... a la Derecha)
		
ld	a,(rota_jugador)
cp	$07			; ... (Borrar yendo a la Izquierda)
call	z,borra_jugadorizq

;----------------------------------------------------------------------
ld	a,(rota_jugador)
or	a			; Para incrementar puntero DE...	
ld	c,a			; ...C = Bucle (Dependiendo de la Rotacion)
jr	z,salta_bucleincr	; C= Z ...entonces salta el bucle (Seria 0)

bucle_incrementarjugador:
call 	incrementar_de		; Incrementar DE (2 veces)...
call	incrementar_de			
dec	c
jr	nz,bucle_incrementarjugador

;----------------------------------------------------------------------
salta_bucleincr:
ld	a,(jugador_y)
ld	h,a			; Carga H 
ld	a,(jugador_x)
ld	l,a			; Carga L 

ld	b,$10			; Bucle $10 Scanlines

bucle_dibujajugador:
ld	a,(nivel)
cp	$01
jp	z,or_con_arquero
cp	$07
jp	z,or_con_arquero

sigue_aqui:
ld	a,(jugador_set)
bit	1,a
call	z,dibujados_repetitivos		; Dibuja (Sin OR)

ld	a,(jugador_set)
bit	1,a
call	nz,dibujados_repetitivos_or	; Dibuja (con OR)

ld	a,(jugador_set)
bit	1,a
call	z,dibujados_repetitivos2 	; Dibuja (Sin OR)

ld	a,(jugador_set)
bit	1,a
call	nz,dibujados_repetitivos2_or	; Dibuja (con OR)

salta_aqui:
dec	l
dec	l
dec	l			; Vuelve al principio (Izda)

ld	a,h
and	%00000111
cp	$07			; Cambio de Linea??
jr	z,cambio_scanline

inc	h			; No, entonces solo inc H
jr	no_cambioscanline

cambio_scanline:
ld	a,h
xor	%00000111		; Poner H = 0
ld	h,a

ld	a,l
add	a,$20			; Cambio de Linea
ld	l,a

no_cambioscanline:
inc	de			; Siguiente Byte a dibujar
djnz	bucle_dibujajugador
call 	dibuja_attrjugador		; Ahora los ATTR
ret		; --------- Retorna ----------

;----------------------------------------------------------------------
;---                    A N I M A C I O N E S                       ---
;----------------------------------------------------------------------
anima_dos:
ld	de,caballero_a2		; Posiciona puntero DE en esa direccion
ret

anima_uno:
ld	de,caballero_a3		; Posiciona puntero DE en esa direccion
ret

anima_dosizda:
ld	de,caballero_a2giro	; Posiciona puntero DE en esa direccion
ret

anima_unoizda:
ld	de,caballero_a3giro	; Posiciona puntero DE en esa direccion
ret

;-------------------- animaciones agachado ----------------------------
anima_agachadoizq:
call	borra_jugador_alagacharse
ld	de,caballero_agachadoizda
jp 	rotaciones_jugador

anima_agachadodcha:
call	borra_jugador_alagacharse
ld	de,caballero_agachadodcha
jp	rotaciones_jugador

;-------------------- animaciones atacando a espada -------------------
anima_atacandoizda:
ld	de,caballero_ataca_izda
jp 	rotaciones_jugador

anima_atacandodcha:
ld	de,caballero_ataca_dcha
jp	rotaciones_jugador

;------------------- animaciones Entre-Puertas ------------------------
anima_entrep_unoizda:
ld	de,caballero_a3_entrepuertas
ret	; Retorna

anima_entrep_dosizda:
ld	de,caballero_a2_entrepuertas
ret	; Retorna

;---------------------------------------------------------------------------
;---         SUB -  D I B U J A   A T T R - J U G A D O R                ---
;---------------------------------------------------------------------------
dibuja_attrjugador:
ld	a,(jugador_y)
cp	$50
jr	z,cincuenta_ya
cp	$48
jr	z,cincuenta_ynueve
cp	$40
jr	z,cincuenta_yocho
;ret
jr	$

l_nocambia:
ld	h,a				; H = Coordenada Y Jugador
ld	a,(jugador_x)
ld	l,a				; L = Coordenada X Jugador

ld	de,caballero_a2attr
ld	b,$02

bucle_attrjugador:
ld	a,(de)
ld	(hl),a

inc	l
;inc	de
ld	a,(de)
ld	(hl),a

inc	l
;inc	de
ld	a,(de)
ld	(hl),a

inc	l
;inc	de
ld	a,(de)
ld	(hl),a

dec	l
dec	l
dec	l
ld	a,l
add	a,$20
ld	l,a

inc	de
djnz	bucle_attrjugador
ret

;------------------------------------------------------------------
cincuenta_yocho:
ld	a,$58
jr	l_nocambia

cincuenta_ynueve:
ld	a,$59
jr	l_nocambia

cincuenta_ya:
ld	a,$5a
jr	l_nocambia

;---------------------------------------------------------------------------
;---                  SUB -  B O R R A   J U G A D O R                   ---
;---------------------------------------------------------------------------
borra_jugador:
ld	a,(jugador_set)	; Si Rotacion=0 entonces Borrado pero SOLO...
bit	0,a		; ... yendo a la Derecha
ret	nz		; Retorna Inmediato... Si 'yendo a la Izquierda'

call	borrar_yendoderecha
jr	comienza_borrado	; Salta al comienzo Borrado (mas abajo)...
	
borra_jugadorizq:
ld	a,(jugador_set)	; Si Rotacion=7 entonces Borrado pero SOLO...
bit	0,a		; ... yendo a la Izquierda
ret	z		; Retorna Inmediato... Si 'yendo a la Derecha'

call	borrar_yendoizquierda

;----------------------------------------------------------------
comienza_borrado:
ld	b,$10		; Bucle $08 Scanlines

bucle_borrajugador:
ld	(hl),$00	; Borrado

ld	a,h
and	%00000111
cp	$07			; Cambio de Linea??
jr	z,cambio_scanlineb

inc	h			; No, entonces solo inc H
jr	no_cambioscanlineb

cambio_scanlineb:
ld	a,h
xor	%00000111		; Poner 'H' a 0
ld	h,a

ld	a,l
add	a,$20			; Cambio de Linea
ld	l,a

no_cambioscanlineb:
djnz	bucle_borrajugador	; Bucle Borrado
ret 		; Retorna

;--------------------------------------------------------
borrar_yendoderecha:
dec	l	; 'L' un caracter a la Izda (para borrarlo)
ret		; Retorna

borrar_yendoizquierda:
inc	l
inc	l	; 'L' incrementos a la Dcha (para borrarlo)
inc	l
inc	l
ret		; Retorna

;---------------------------------------------------------------------------
;---    S U B -  B O R R A   J U G A D O R  ***( Al agacharse )***       ---
;---------------------------------------------------------------------------
borra_jugador_alagacharse:
;ld	h,$50		; Intento de que NO borre mal...
ld	b,$10		; Bucle $08 Scanlines

bucle_borrajugador_alagacharse:
ld	(hl),$00	; Borrado

inc	l
ld	(hl),$00	; Borrado

inc	l
ld	(hl),$00	; Borrado

inc	l
ld	(hl),$00	; Borrado

dec	l
dec	l
dec	l
call 	incrementar_scanline
djnz	bucle_borrajugador_alagacharse	; Bucle Borrado

;----------------------------------------
ld	a,(jugador_y)
ld	h,a
ld	a,(jugador_x)
ld	l,a

ld	a,(settings)
bit	4,a		; Bit4 = 1 Flecha Arquero ON...
ret	z		; ... Si no Retorna Inmediato

ld	a,(jugador_set)
set	5,a		; Set... Para que la SUB flecha NO incremente rotacion
ld	(jugador_set),a
call	flecha_arquerozero	; SUB flechaArquero (especial SIN incrementar)
ld	a,(jugador_set)
res	5,a		; Res... Para que la SUB flecha incremente (normal)
ld	(jugador_set),a
ret 		; Retorna

;---------------------------------------------------------------------------
;---           JP - DIBUJA JUGADOR PERO CON ( OR Arquero )               ---
;---------------------------------------------------------------------------
or_con_arquero:
ld	a,(settings)
bit	5,a
jp	nz,sigue_aqui

ld	a,(jugador_x)
cp	$99
jp	nz,cp_9a

call	dibujados_repetitivos		; Dibuja (Sin OR)

inc	l
inc	de			; ...Siguiente Byte DCHA
ld	a,(de)
ld	(hl),a

inc	l
inc	de
ld	a,(hl)
ld	c,a
ld	a,(de)
or	c
ld	(hl),a			; ...Siguiente Byte DCHA

jp	salta_aqui

;----------------------------------------
cp_9a:
cp	$9a
jp	nz,sigue_aqui

call	dibujados_repetitivos
call	dibujados_repetitivos2_or
jp	salta_aqui

;---------------------------------------------------------------------------
;---                  JP - ROTACION ENTRE-PUERTAS                        ---
;---------------------------------------------------------------------------
rotacion_entrepuertas:
ld	a,(anima_jugador)
inc	a
bit	0,a
ld	(anima_jugador),a
call	z,anima_entrep_unoizda
call	nz,anima_entrep_dosizda

;jr	nz,salta_incr_a

ld	a,(rota_entrepuert)
inc	a			; Para incrementar puntero DE...
ld	(rota_entrepuert),a	

salta_incr_a:
ld	c,a			; ...C = Bucle (Dependiendo de la Rotacion)
cp	$0d
jr	z,ultimo_borrado

bucle_incrementar_entrepuertas:
call 	incrementar_de		; Incrementar DE (2 veces)...
call	incrementar_de			
dec	c
jr	nz,bucle_incrementar_entrepuertas
halt
halt
jp	salta_bucleincr
jr	$

;----------------------------------------
ultimo_borrado:
;inc	l
;ld	(hl),$00
;dec	l

ld	a,(jugador_set)
res	2,a
ld	(jugador_set),a

ld	h,$48
ld	a,h
ld	(jugador_y),a

ld	l,$d2
ld	a,l
ld	(jugador_x),a

ld	a,$07
ld	(rota_jugador),a
jp	salta_bucleincr

;---------------------------------------------------------------------------
incrementar_de:
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
ret		; Retorna

decrementar_de:
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
dec	de
ret		; Retorna

;===========================================================================
;---                    SUB - L E E R   T E C L A D O                    ---
;---                                                                     --- 
;---         Espadazo ---------> Cursor JoyStick Arriba                  --- 
;---         Izquierda --------> Cursor JoyStick Izquierda               ---
;---         Derecha ----------> Cursor JoyStick Derecha                 ---
;---         Agacharse --------> Cursor JoyStick Abajo                   ---
;---------------------------------------------------------------------------
teclado:
ld	a,(jugador_set)
bit	2,a		; Si Z, (Entre-Puertas OFF), entonces...
jr	z,interrogacion	; Sigue normalmente...
jr	interrogacion
;------------------------ Si NZ, Entre-Puertas ON ----------------------
ld	a,(anima_jugador)
inc	a			; ...Incrementa la animacion (pulsando)
ld	(anima_jugador),a

ld	a,(rota_jugador)	
dec	a			; ...Decrementa la Rotacion
cp	$ff
call	z,jugador_izquierda_entrepuertas    ; Z, NO Decrementa (Entre-Puertas)
ld	(rota_jugador),a
ret		; Retorna

;-------------------- Tecla ? --------------------------------------
interrogacion:
ld	a,$f7
in	a,($fe)
bit	2,a
jr	nz,agacharse	; Si 'No Pulsada' continua normal...

ld	a,(settings_ch)
bit	0,a
jp	nz,siguiente_nivel

;-------------------- Tecla Agacharse --------------------------------------
agacharse:
ld	a,$fd		
in	a,($fe)
bit	0,a
jr	nz,espada_ataque	; NZ = '6' No pulsada, salta a comprobar la siguiente...

ld	a,(jugador_set)		; Tecla 'agacharse' Pulsada! entonces...
set	1,a			; Bit1 =1 Estar agachado mientras este pulsada
ld	(jugador_set),a
ret		; Retorna

;-------------------- Tecla Espada ataque ----------------------------------
espada_ataque:
ld	a,(jugador_set)
res	1,a
ld	(jugador_set),a

ld	a,$7f		
in	a,($fe)
bit	0,a
jr	nz,tecla_izq	; NZ = '7' No pulsada, salta a comprobar la siguiente...

ld	a,$03
call	sonido

ld	a,(jugador_set)		; Tecla 'espada ataque' Pulsada! entonces...
set	4,a			; Bit4 =1 ataque Espada ON
ld	(jugador_set),a
ret		; Retorna

;-------------------- Tecla Izquierda --------------------------------------
tecla_izq:
ld	a,(jugador_set)
res	4,a
ld	(jugador_set),a

ld	a,$df			;Carg en A, puerto $fe (semifila 1...5)
in	a,($fe)			;Lee (In A) el puerto entrada $fe
bit	1,a			;Comprobamos estado del Bit4 (Tecla 5)
jr 	nz,tecla_dcha		;NZ = '5' No pulsada, salta a la siguiente...

ld	a,(jugador_set)		; Tecla 'Izquierda' pulsada! entonces...
set	0,a			; ...Bit0= 1 (Giro a la izquierda)...
ld	(jugador_set),a

ld	a,(anima_jugador)
inc	a			; ...Incrementa la animacion (pulsando)
ld	(anima_jugador),a

ld	a,(rota_jugador)	
dec	a			; ...Decrementa la Rotacion
cp	$ff
call	z,jugador_izquierda	; Z, Decrementa un caracter (moverse Izda)
ld	(rota_jugador),a
ret		; Retorna

;-------------------- Tecla Derecha --------------------------------------
tecla_dcha:
ld	a,$df			;Carg en A, puerto $ef (semifila 6...0)
in	a,($fe)			;Lee (In A) el puerto entrada $fe
bit	0,a			;Comprobamos estado del Bit2 (Tecla 8)
ret 	nz			;NZ = '8' No pulsada, Retorna ...

ld	a,(jugador_set)		; Tecla 'Derecha' pulsada! entonces...
res	0,a			; ...Bit0= 0 (Giro a la Derecha)...
ld	(jugador_set),a

ld	a,(anima_jugador)
inc	a			; Incrementa la animacion (pulsando)
ld	(anima_jugador),a

ld	a,(rota_jugador)
inc	a			; Incrementa la Rotacion
cp	$08			; Si $09... Incrementa un caracter
call	z,jugador_derecha	
ld	(rota_jugador),a
ret			; Retorna

;---------------------------------------------------------------------------
jugador_izquierda:
ld	a,(jugador_x)
dec	a			; Decrementa un caracter la Nave-Jugador
cp	$80			; Limite Izquierdo??
jr	z,limite_izquierdo
cp	$cf
jr	z,limite_izquierdo_niveles
ld	(jugador_x),a
ld	a,$07
ret		; Retorna

;----------------------------------------------
limite_izquierdo:
ld	a,$81
ld	(jugador_x),a
ld	a,$00
ret		; Retorna

;----------------------------------------------
limite_izquierdo_niveles:
ld	a,(nivel)
cp	$01
ret	nz

ld	a,(jugador_y)
cp	$48
ret	nz

ld	a,$d0
ld	(jugador_x),a
ld	a,$00
ret		; Retorna

;---------------------------------------------------------------------------
jugador_izquierda_entrepuertas:
ld	a,(jugador_set)
res	2,a
ld	(jugador_set),a

ld	h,$48
ld	a,h
ld	(jugador_y),a

ld	l,$d2
ld	a,l
ld	(jugador_x),a

ld	a,$07
ret		; Retorna

;---------------------------------------------------------------------------
jugador_derecha:
ld	a,(jugador_x)
inc	a			; Incrementa un caracter la Nave-Jugador
cp	$9d			; Limite Derecho??
jr	z,limite_derecho
ld	(jugador_x),a
ld	a,$00
ret		; Retorna

;-----------------------------------------------
limite_derecho:
ld	a,$9c
ld	(jugador_x),a
ld	a,$07
ret		; Retorna

;===========================================================================
;---    S U B -  S E L E C C I O N A R    J U G A B I L I D A D          ---
;---                                                                     ---     
;---    (Dependiendo del NIVEL)  ...  Dec A (Nivel) hasta que sea Z      ---
;---------------------------------------------------------------------------
selecc_jugabilidad:
ld	a,(nivel)
or	a
jr	z,nivel_0	; JR a Jugabilidad (Nivel 0)

dec	a
jp	z,nivel_1	; JP a Jugabilidad (Nivel 1)

dec	a
jp	z,nivel_2	; JP a Jugabilidad (Nivel 2)

dec	a
jp	z,nivel_3	; JP a Jugabilidad (Nivel 3)

dec	a
jp	z,nivel_4	; JP a Jugabilidad (Nivel 4)

dec	a
jp	z,nivel_5	; JP a Jugabilidad (Nivel 5)

dec	a
jp	z,nivel_6	; JP a Jugabilidad (Nivel 6)

dec	a
jp	z,nivel_7	; JP a Jugabilidad (Nivel 7)

dec	a
jp	z,nivel_8	; JP a Jugabilidad (Nivel 8)

dec	a
jp	z,nivel_9	; JP a Jugabilidad (Nivel 9)

dec	a
jp	z,nivel_10	; JP a Jugabilidad (Nivel 10)

dec	a
jp	z,nivel_11	; JP a Jugabilidad (Nivel 11)

dec	a
jp	z,nivel_12	; JP a Jugabilidad (Nivel 12)

dec	a
jp	z,nivel_13	; JP a Jugabilidad (Nivel 13)

dec	a
jp	z,nivel_14	; JP a Jugabilidad (Nivel 14)

dec	a
jp	z,nivel_15	; JP a Jugabilidad (Nivel 15)
ret	; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   0 )            ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_0:
ld	a,(jugador_x)
cp	$96			; CP tope derecho = Next Nivel...
jr	z,siguiente_nivel

ld	a,(contador_it)
cp	$20			; CP=$20 Inicia flechaArquero...
call	z,inicia_flecha_arquerozero
cp	$10
call	z,inicia_murcielago_zero

ld	a,(settings)
bit	4,a			; NZ = SUB flechaArquero
call	nz,flecha_arquerozero

ld	a,(settings2)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,sub_murcielago	; ... SUB Murcielago

ld	a,(settings4)
bit	5,a			; Bit5 = 1 ? ...entonces...
call	nz,explo_arana		; ...SUB Explo-Arana

ret	; Retorna

;---------------------------------------------------------------------------
;---		S I G U I E N T E   P A N T A L L A  ( Nivel )           ---
;---------------------------------------------------------------------------
siguiente_nivel:
ld	a,(settings)
set	0,a		; Bit0 = 1 = Otra Pantalla ON...
ld	(settings),a

ld	a,(nivel)
inc	a		; Incrementar UN Nivel
push	af
cp	$02
call	z,h_inicial	; H = $50 (Devolver al Jugador al 3er Tercio)
cp	$08
call	z,h_inicial	; H = $50 (Devolver al Jugador al 3er Tercio)
pop	af
ld	(nivel),a

ld	a,(jugador_x)
ld	a,$82		; Posicion Inicial JugadorX (en el siguiente Nivel)
ld	(jugador_x),a

xor	a
ld	(contador_it),a		; Resetea el Contador de Iteraciones

ld	a,$02
call	sonido
ret	; Retorna

;------------------------------------------------------
h_inicial:
ld	a,$50
ld	(jugador_y),a
ret	; Retorna

;---------------------------------------------------------------------------
;---       S U B - I N I C I A   M U R C I E L A G O  ( Nivel 0 )        ---
;---------------------------------------------------------------------------
inicia_murcielago_zero:
ld	a,(settings2)
bit	0,a		; Si Bit0 = 1 ...
ret	nz		; ... No Inicies (Ya esta), Retorna Inmediato

set	0,a		; Inicia Bit0 = 1
ld	(settings2),a	; Acutalizalo

ld	h,$40
ld	a,h
ld	(murcielago_y),a	; Inicia CoordenadaY (H)
ld	l,$00
ld	a,l
ld	(murcielago_x),a	; Inicia CoordenadaX (L)
ret		; Retorna

;---------------------------------------------------------------------------
;---                SUB -  M U R C I E L A G O  ( Nivel 0 )              ---
;---------------------------------------------------------------------------
sub_murcielago:
ld	a,(murcielago_y)
ld	h,a		; Actualiza Y (H)
ld	a,(murcielago_x)
ld	l,a		; Actualiza X (L)
ld	c,a		; Carga en C, (Para Comparar abajo)...

ld	a,(jugador_set)
bit	6,a
jr	nz,no_colision_murcielago
;bit	1,a
;jr	nz,no_colision_murcielago

;-----------------------------------------------------
ld	a,(jugador_set)
bit	4,a		; Si NO estamos atacando (espada), entonces...
jr	z,colisiones_vsmurcielago	; ... continua normalmente... 
bit	0,a		; Si estamos 'mirando DCHA'... entonces...
jp	z,comprueba_ataquedcha_mur	; ... Comprueba ataque DCHA...	
jp	nz,comprueba_ataqueizda_mur	; ... Comprueba ataque IZDA...

;-----------------------------------------------------
colisiones_vsmurcielago:
ld	a,(jugador_x)
cp	c
call	z,posible_colision_vsmurcielago

ld	a,(jugador_x)
inc	a
cp	c
call	z,posible_colision_vsmurcielago

ld	a,(jugador_x)
inc	a
inc	a
cp	c
call	z,posible_colision_vsmurcielago

ld	a,(jugador_set)
bit	6,a
call	nz,restar_una_vida

ld	a,(jugador_set)
bit	6,a
jp	nz,salta_ultimoborrado_murcielago

;-------------------------------------------
no_colision_murcielago:
ld	a,(murcielago_x)
and	%11110000
cp	$80
jp	z,fin_descenso
cp	$90
jp	z,fin_descenso

desciende:
ld	(hl),$00
inc	l
ld	(hl),$00
inc	l
ld	(hl),$00
dec	l
dec	l

call	incrementar_scanline

ld	(hl),$00
inc	l
ld	(hl),$00
inc	l
ld	(hl),$00
dec	l
dec	l

call	incrementar_scanline

ld	a,h
ld	(murcielago_y),a
ld	a,l
ld	(murcielago_x),a

;------------------------------------------------------------
quieto:
ld	a,(cont_murcielago)
dec	a
ld	(cont_murcielago),a
call	z,reinicia_cont
cp	$05
call	nc,murcielago_animacion1
call	c,murcielago_animacion2

ld	a,(rota_murcielago)
or	a
jr	z,salta_abuclem	; Si RotacionFlecha = Z ...entonces salta al Bucle

;-----------------------------------------------------------
ld	b,a		; Si no, Carga en B, A... para Bucle de Incrementos

bucle_incr_flechazero:
call	incrementa_de	; Incrementos (de 8 en 8)... 8 x 3 = 24 Incrementos 
call	incrementa_de
call	incrementa_de
djnz	bucle_incr_flechazero

;--------------------- Dibuja Murcielago -------------------
salta_abuclem:
ld	b,$08		; Bucle $08 Scanlines

bucle_dibuja_murcielago:
call	dibujados_repetitivos

inc	l
inc	de
ld	a,(de)		; Dibuja 3er Byte
ld	(hl),a

dec	l
dec	l
call	incrementar_scanline
inc	de		; Situa DE en siguiente Byte...
djnz	bucle_dibuja_murcielago

;------------------- Attr Murcielago ------------------
;push	hl
ld	a,(murcielago_y)
and 	%11110000
cp	$50
jr	nz,ultima_rotacion

ld	h,$5a
ld	a,(murcielago_x)
ld	l,a
ld	(hl),$47
inc	l
ld	(hl),$47
inc	l
ld	(hl),$47
;pop	hl

;-------------------------------------------------------
ultima_rotacion:
ld	a,(rota_murcielago)
inc	a		; Incrementa RotaFlecha
ld	(rota_murcielago),a
cp	$08		; NZ, si no es la ultima rotacion...
ret	nz		; ... Retorna inmediato, (hemos acabado)

xor	a		; Reinicia Rotacion...
ld	(rota_murcielago),a	; ... y actualizala

;------------------------ Borra Murcielago -------------------
ld	a,(murcielago_y)
ld	h,a
ld	a,(murcielago_x)
ld	l,a

ld	b,$08

bucle_borrado_murcielago:
ld	(hl),$00	; Borrado
call	incrementar_scanline
djnz	bucle_borrado_murcielago

ld	a,(murcielago_x)
ld	l,a
inc	l	; Incrementa la X del Murcielago...
ld	a,l
ld	(murcielago_x),a	; ... y actualizala
cp	$97
ret	nz	; Si no ha alcanzado el limite... Retorna Inmediato

;------------------------ Borrado final ------------------
salta_ultimoborrado_murcielago:
ld	a,(murcielago_y)
ld	h,a

ld	b,$08	

bucle_borradofinalm:
ld	(hl),$00	; Borrado
inc	l
ld	(hl),$00	; Borrado

dec	l
call	incrementar_scanline
djnz 	bucle_borradofinalm

ld	a,(settings2)
res	0,a		; Desactiva la SUB Murcielago
ld	(settings2),a
ret		; Retorna

;--------------------------------------------------------
murcielago_animacion1:
ld	de,murcielago_a1	; Situa DE en Murcielago anim1
ret	; Retorna

murcielago_animacion2:
ld	de,murcielago_a2	; Situa DE en Murcielago anim2
ret	; Retorna

;--------------------------------------------------------
reinicia_cont:
ld	a,$0a
ld	(cont_murcielago),a
ret	; Retorna

fin_descenso:
ld	a,(murcielago_y)
cp	$50
jp	z,quieto
jp	nz,desciende
jr	$

;---------------------------------------------------------------------------
;---  SUB -  P O S I B L E   C O L I S I O N   Vs   M U R C I E L A G O  ---
;--------------------------------------------------------------------------- 
posible_colision_vsmurcielago:
ld	a,h
and	%11110000
ld	c,a

ld	a,(jugador_y)
and	%11110000
cp	c
ret	nz	; No Colision... entonces Retorna Inmediato 

;ld	a,h
;cp	$48
;ret	c	; 1er Tercio = No colision... Retorna

ld	a,$03
call	sonido

xor	a
ld	(cont_explo_jug),a

ld	a,(jugador_set)
set	6,a		; Vida Menos = ON
ld	(jugador_set),a
;jp	no_colision
ret	; Retorna
jr	$

;---------------------------------------------------------------
comprueba_ataquedcha_mur2:
dec	c
dec	c
dec	c
ld	a,(jugador_x)
cp	c		; Si atacamos en la posicion del Murcielago, entonces...
call	z,inicia_exploarana	; ... Inicia Explo-Murcielago ON

inc	c
inc	c
inc	c
;ld	a,(jugador_x)
;cp	c
;jp	z,no_colisionarana	
jp	colisiones_vsmurcielago
jr	$

;---------------------------------------------------------------
comprueba_ataquedcha_mur:
ld	a,(jugador_x)
inc	a
inc	a
inc	a
cp	c		; Si atacamos en la posicion del Murcielago, entonces...
call	z,inicia_exploarana	; ... Inicia Explo-Murcielago ON

;ld	a,(jugador_x)
;cp	c
;jp	z,no_colisionarana	
jp	colisiones_vsmurcielago
jr	$

;---------------------------------------------------------------
comprueba_ataqueizda_mur:
ld	a,(jugador_x)
dec	a
cp	c		; Si atacamos en la posicion de la arana, entonces...
call	z,inicia_exploarana	; ... Inicia Explo-arana ON

;ld	a,(jugador_x)
;cp	c
;jp	z,no_colisionarana
jp	colisiones_vsmurcielago
jr	$

;---------------------------------------------------------------------------
;---             S U B - INICIA FLECHA ARQUERO ( Nivel 0 )               ---
;---------------------------------------------------------------------------
inicia_flecha_arquerozero:
ld	a,(settings)
bit	4,a		; Si Bit4 = 1 ...
ret	nz		; ... No Inicies (Ya esta), Retorna Inmediato
bit	5,a
ret	nz		; Si NO hay Arquero, Retorna Inmediato

set	4,a		; Inicia Bit4 = 1
ld	(settings),a	; Acutalizalo

ld	h,$50
ld	a,h
ld	(flecha_y),a	; Inicia CoordenadaY (H)

;----------------- Nivel?? -----
ld	a,(nivel)
or	a
jr	z,iniciaflecha_nivelz

dec	a
jr	z,iniciaflecha_nivel1

dec	a
dec	a
dec	a
dec	a
jr	z,iniciaflecha_nivel5

dec	a
jr	z,iniciaflecha_nivel6

dec	a
jr	z,iniciaflecha_nivel1	; (Nivel 7, IGUAL que la del Nivel 1)

dec	a
dec	a
dec	a
dec	a
jr	z,iniciaflecha_nivel5	; (Nivel 11, Sirve la del Nivel 5)

dec	a
jr	z,iniciaflecha_nivel5	; (Nivel 12, Sirve la del Nivel 5)

dec	a
jr	z,iniciaflecha_nivel5	; (Nivel 13, Sirve la del Nivel 5)

dec	a
jr	z,iniciaflecha_nivel5	; (Nivel 14, Sirve la del Nivel 5)
jr	$

;-------------------------------
flecha_l:
ld	a,l
ld	(flecha_x),a	; Inicia CoordenadaX (L)
ret		; Retorna

;----------------------------------------------
iniciaflecha_nivelz:
ld	l,$96
jr	flecha_l

iniciaflecha_nivel1:
ld	l,$99
ld	a,$01
call	sonido
jr	flecha_l

iniciaflecha_nivel5:
ld	l,$9e
jr	flecha_l

iniciaflecha_nivel6:
ld	l,$9e
jr	flecha_l

;---------------------------------------------------------------------------
;---                SUB - FLECHA ARQUERO ( Nivel 0 )                     ---
;---------------------------------------------------------------------------
flecha_arquerozero:
ld	a,(flecha_y)
ld	h,a		; Actualiza Y (H)
ld	a,(flecha_x)
ld	l,a		; Actualiza X (L)
ld	c,a		; Carga en C (Para Comparar abajo)...

ld	a,(jugador_set)
bit	6,a
jr	nz,no_colision_flecharquero
bit	1,a
jr	nz,no_colision_flecharquero

;-----------------------------------------------------
ld	a,(jugador_x)
cp	c
call	z,posible_colision_vsflecha

ld	a,(jugador_x)
inc	a
cp	c
call	z,posible_colision_vsflecha

ld	a,(jugador_x)
inc	a
inc	a
cp	c
call	z,posible_colision_vsflecha

ld	a,(jugador_set)
bit	6,a
call	nz,restar_una_vida

ld	a,(jugador_set)
bit	6,a
jr	nz,salta_ultimoborrado

;--------------------------------
no_colision_flecharquero:
ld	de,flechas_izda	; Situa DE en flechas Izda
ld	a,(rota_flecha)
or	a
jr	z,salta_abucle	; Si RotacionFlecha = Z ...entonces salta al Bucle

;--------------------------------
ld	b,a		; Si no, Carga en B, A... para Bucle de Incrementos

bucle_incr_murcielago:
call	incrementa_de	; Incrementos (de 8 en 8)... 8 x 3 = 24 Incrementos 
call	incrementa_de
call	incrementa_de
djnz	bucle_incr_murcielago

;--------------------------------
salta_abucle:
ld	b,$08		; Bucle $08 Scanlines

bucle_flecha_arquerozero:
call	dibujados_repetitivos

inc	l
inc	de
ld	a,(de)		; Dibuja 3er Byte
ld	(hl),a

dec	l
dec	l
inc	h
inc	de		; Situa DE en siguiente Byte...
djnz	bucle_flecha_arquerozero

;---------------------------------
push	hl
ld	h,$5a
ld	(hl),$02
inc	l
ld	(hl),$02
inc	l
ld	(hl),$02
pop	hl

;---------------------------------
ld	a,(jugador_set)
bit	5,a		
ret	nz	; Si NZ, retorna inmediato (para NO incrementar rotacion)

ld	a,(rota_flecha)
inc	a		; Incrementa RotaFlecha
ld	(rota_flecha),a
cp	$08		; NZ, si no es la ultima rotacion...
ret	nz		; ... Retorna inmediato, (hemos acabado)

xor	a		; Reinicia Rotacion...
ld	(rota_flecha),a	; ... y actualizala

inc	l
inc	l
dec	h	; Incrementos de H (para borrar preciso...
dec	h
dec	h	; ... solo el Scanline correspondiente)
dec	h
ld	(hl),$00	; Borrado
dec	l
dec	l

dec	l	; Decrementa la X de la Flecha...
ld	a,l
ld	(flecha_x),a	; ... y actualizala
;cp	$7f
cp	$80
ret	nz	; Si no ha alcanzado el limite... Retorna Inmediato

;--------------------------------------
salta_ultimoborrado:
inc	l
ld	b,$07	; $07 (ultimo NO hace falta)

bucle_borraflecha_izdadcha:
ld	(hl),$00	; Borrado
inc	l
ld	(hl),$00	; Borrado

dec	l
inc	h
djnz 	bucle_borraflecha_izdadcha

ld	a,(settings)
res	4,a		; Desactiva la SUB FlechaArquero
ld	(settings),a
ret		; Retorna

;---------------------------------------------------------
incrementa_de:
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
inc	de
ret	; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   1 )            ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_1:
ld	a,(settings)
bit	7,a			; Si Z, (Aparece-Puerta=ON), entonces...
call	nz,comprueba_entrepuertas	; ... SUB Comprueba si entras...

ld	a,(settings4)
bit	0,a			; Si Bit0 = 1 ... entonces...
call	nz,dibuja_needkey	; SUB Dibuja la LLave que se necesita

ld	a,(jugador_x)
cp	$89		; Si pisas en ladrillo $89... 
call	z,inicia_flechatrampa1	; ...activa FlechaTrampa!

ld	a,(settings)
bit	3,a			; Si NZ, entonces...
call	nz,flecha_trampa1	; SUB FlechaTrampa...

ld	a,(settings2)
bit	3,a			; Si NZ, entonces...
call	nz,flecha_trampa1_rapida ; SUB flechaTrampaRapida...

ld	a,(jugador_y)
cp	$48
call	z,compruebatb_lal

ld	a,(contador_it)
cp	$20			; CP = $20?? ...entonces...
call	z,inicia_flecha_arquerozero	; ...Inicia flechaArquero

ld	a,(contador_it)
cp	$fc			; Si Z, entonces...
call	z,borra_flechatrampa1	; Borra la Flecha-Trampa (del suelo)

ld	a,(settings)
bit	4,a			; NZ = SUB flechaArquero
call	nz,flecha_arquerozero

ld	a,(settings)
bit	5,a			; Si Z, entonces...
call	z,arquero_on		; SUB Arquero

ld	a,(settings)
bit	2,a			; Si NZ, entonces...
call	nz,explo_arquero	; ...SUB Explo-Arquero

ld	a,(settings2)
bit	4,a			; Si NZ, entonces...
call	nz,animacion_bloquetrampa   ; SUB Animacion-BloqueTrampa	

ld	a,(settings4)
bit	1,a			; Bit1= 1 ... entonces...
call	nz,inventario_llave	; Muestra Inventario Llave

ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jr	z,anterior_nivel
cp	$dd			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;---------------------------------------------------------------------------
comprueba_entrepuertas:
ld	a,(jugador_x)
cp	$91		; JugadorX = $91 ?? ...
ret	nz		; NO? Entonces, Retorna Inmediato...

ld	a,(rota_entrepuert)
or	a
ret	nz

ld	a,$02
call	sonido

ld	a,(nivel)
cp	$07
call	z,resetear_llave

call	activa_entrepuertas
ret	; Retorna

;---------------------------------------------------------------------------
resetear_llave:
ld	a,(settings4)
res	0,a
res	1,a
ld	(settings4),a

ld	hl,$401d
ld	b,$08

bucle_borrallave_inventario:
ld	(hl),$00
inc	l
ld	(hl),$00

dec	l
call	incrementar_scanline
djnz	bucle_borrallave_inventario
ret	; Retorna

;---------------------------------------------------------------------------
;---		A C T I V A R   E N T R E - P U E R T A S                ---
;---------------------------------------------------------------------------
activa_entrepuertas:
ld	a,(jugador_set)
set	2,a		; Bit2 = 1 ... EntrePuertas ON
ld	(jugador_set),a
ret		; Retorna

;----------------------------------------------
desactivar_entrepuertas:
ld	a,(jugador_set)
res	2,a		; Bit2 = 1 ... EntrePuertas OFF
ld	(jugador_set),a
ret		; Retorna

;---------------------------------------------------------------------------
;---		A N T E R I O R   P A N T A L L A  ( Nivel )             ---
;---------------------------------------------------------------------------
anterior_nivel:
ld	a,(settings)
set	0,a		; Bit1 = 1 = Otra Pantalla(anterior) ON...
ld	(settings),a

ld	a,$02
call	sonido

ld	a,(nivel)
dec	a		; Decrementar UN Nivel
ld	(nivel),a

jr	z,ir_anivelzero

cp	$01
jr	z,ir_aniveluno

cp	$02
jr	z,ir_aniveldos

cp	$03
jr	z,ir_aniveldos

cp	$04
jr	z,ir_aniveldos

cp	$05
jr	z,ir_aniveldos

cp	$06
jr	z,ir_aniveldos

cp	$07
jr	z,ir_aniveldos

cp	$08
jr	z,ir_aniveldos

cp	$09
jr	z,ir_aniveldos

cp	$0a
jr	z,ir_aniveldos

cp	$0b
jr	z,ir_aniveldos

cp	$0c
jr	z,ir_aniveldos

cp	$0d
jr	z,ir_aniveldos

cp	$0e
jr	z,ir_aniveldos
jr	$
ret	; Retorna

;-------------------------------------------------------------
ir_anivelzero:
;ld	a,(jugador_x)
ld	a,$95		; Posicion Inicial JugadorX (en el nuevo Nivel)
ld	(jugador_x),a
ret	; Retorna

;-------------------------------------------------------------
ir_aniveluno:
ld	a,$dc
ld	(jugador_x),a
ld	a,$48
ld	(jugador_y),a
ret	; Retorna

;-------------------------------------------------------------
ir_aniveldos:
ld	a,$9b
ld	(jugador_x),a
ret	; Retorna

;===========================================================================
;---    SUB - Dibuja la LLave que se Necesita ( Regresando a Nivel 1 )   ---
;---------------------------------------------------------------------------
dibuja_needkey:
ld	hl,$48f0

ld	a,(jugador_x)
cp	$d0		; Compara (arriba $48f0 = LLave )
jr	z,coge_lallave

ld	de,llave
ld	b,$08

bucle_dibujallave:
call	dibujados_repetitivos

dec	l
call	incrementar_scanline
inc	de
djnz	bucle_dibujallave
ret	; Retorna

;---------------------------------------------
coge_lallave:
ld	a,$01
call	sonido
ld	a,$02
call	sonido

ld	a,(settings4)
res	0,a
set	1,a
ld	(settings4),a

ld	a,(rota_entrepuert)
xor	a
ld	(rota_entrepuert),a

;ld	a,(settings)
;set	7,a
;ld	(settings),a
ret	; Retorna

;===========================================================================
;---             SUB - Inicia Trampa Flecha ( Nivel 1 )                  ---
;---------------------------------------------------------------------------
inicia_flechatrampa1:
ld	a,(settings)
bit	3,a		; Si NZ, entones...
ret	nz		; Retorna Inmediato (ya esta Iniciado)

ld	a,(settings2)
bit	3,a		; Si NZ, entonces...
ret	nz		; Retorna tb...

call	inicia_animacion_bloquetrampa

ld	a,(contador_flecha)
inc	a
bit	0,a			; Contador Par/Impar ...
ld	(contador_flecha),a
jr	nz,inicia_rapida	; ... Inicia Flecha Rapida...
jr	z,inicia_lenta		; ... o Flecha Lenta ...

continua_inicia:
ld	a,$01
call	sonido
	
ld	h,$40
ld	a,h
ld	(flechatrap_y),a	; Inicia FlechaY (H)

;------- Inicio FlechaX dependiendo del Nivel -------
ld	a,(nivel)
cp	$01
jr	z,flechax_niveluno

cp	$02
jr	z,flechax_niveldos

cp	$05
jr	z,flechax_nivelcinco

cp	$06
jr	z,flechax_nivelcinco

cp	$0e
jr	z,flechax_nivelcinco
jr	$
ret		; Retorna

;----------------------------------------------------
flechax_niveluno:
ld	a,(jugador_y)
cp	$50
jr	z,flechax_nivelunouno

ld	a,(jugador_x)
inc	a
inc	a
inc	a
sub	$20
ld	(flechatrap_x),a
ret	; Retorna

flechax_nivelunouno:
ld	a,(jugador_x)
inc	a
inc	a
inc	a	; Inicio Flecha a 3 Columnas el Jugador
add	a,$20
ld	(flechatrap_x),a	; Inicia FlechaX (L)
ret	; Retorna

;----------------------------------------------------
flechax_niveldos:
ld	a,$48
ld	(flechatrap_y),a

ld	a,(jugador_x)
inc	a
inc	a
inc	a	; Inicio Flecha a 3 Columnas el Jugador
sub	$20
ld	(flechatrap_x),a	; Inicia FlechaX (L)
ret	; Retorna

;----------------------------------------------------
flechax_nivelcinco:
ld	a,$48
ld	(flechatrap_y),a

ld	a,(jugador_x)
inc	a
inc	a
inc	a	; Inicio Flecha a 3 Columnas el Jugador
sub	$20
ld	(flechatrap_x),a	; Inicia FlechaX (L)
ret	; Retorna

;----------------------------------------------------
inicia_rapida:
ld	a,(settings2)
set	3,a		; Bit3 = 1 (Settings2) Rapida
ld	(settings2),a
jr	continua_inicia

inicia_lenta:
ld	a,(settings)
set	3,a		; Bit3 = 1 (Settings) Lenta
ld	(settings),a
jr	continua_inicia

;----------------------------------------------------
;--  SUB - Comprueba ahora tb la L ... ( H = $48 ) --
;----------------------------------------------------
compruebatb_lal:
ld	a,(jugador_x)
cp	$d9
ret	nz

call	inicia_flechatrampa1
ret	; Retorna

;---------------------------------------------------------------------------
;---       SUB - F L E C H A   T R A M P A  *** Lenta *** ( Nivel 1 )    ---
;---------------------------------------------------------------------------
flecha_trampa1:
ld	a,(flechatrap_y)	; Actualiza FlechaY (H)
ld	h,a
ld	a,(flechatrap_x)	; Actualiza FlechaX (L)
ld	l,a

add	a,$20
ld	c,a

ld	a,(jugador_set)
bit	6,a
jr	nz,no_colision

;-----------------------------------------------------
ld	a,(jugador_x)
cp	c
call	z,posible_colision_vsflecha

ld	a,(jugador_x)
inc	a
cp	c
call	z,posible_colision_vsflecha

ld	a,(jugador_x)
inc	a
inc	a
cp	c
call	z,posible_colision_vsflecha

ld	a,(jugador_set)
bit	6,a
call	nz,restar_una_vida

;-----------------------------------------------------
no_colision:
ld	(hl),$00	; Borra SOLO 1er Scanline... (autoborrado)

ld	de,flechas_updown	; Situa DE en FlechasUpDown

call	incrementar_scanline	; Incrementa UN Scan...
ld	a,l
ld	(flechatrap_x),a		; ...y actualiza FlechaX
ld	a,h
ld	(flechatrap_y),a		; ...y actualiza FlechaY
cp	$48			; 2do Tercio??
call	z,fin_flechatrampa11
cp	$50			; 3er Tercio??
call	z,fin_flechatrampa1	; SUB Posible Fin FlechaTrampa...

call	dibuja_flechatrampa

ld	a,(jugador_y)
cp	$48	; Segundo Tercio?? ...
call	z,re_attr_flecha48

ld	a,(jugador_y)
cp	$50	; Tercer Tercio?? ...
call	z,re_attr_flecha50
ret		; Retorna

;--------------------------------------------------
fin_flechatrampa1:
ld	a,(flechatrap_y)
cp	$50		; Tercer Tercio ?? ...
ret	nz		; ... NO? Entonces, Retorna

ld	a,(flechatrap_x)
and	%11110000	; AND para detectar el '8' (fin Flecha)
cp	$80		; $80??
jr	z,continua_fin	; NZ, entonces Retorna Inmediato (No fin Flecha)
cp	$90
jr	z,continua_fin
ret	; Retorna

continua_fin:
ld	a,(settings)
res	3,a		; Res Bit3... (Fin FlechaTrampa)
ld	(settings),a	; Actualiza

ld	a,(settings2)	
res	3,a		; ; Res Bit3 ... (Fin FlechaTrampa Settings2)
ld	(settings2),a	; Actualiza
ret		; Retorna

;--------------------------------------------------
fin_flechatrampa11:
ld	a,(flechatrap_y)
cp	$48		; Segundo Tercio?? ...
ret	nz		; No? Entonces, Retorna ...

ld	a,(nivel)
cp	$01
ret	nz

ld	a,(flechatrap_x)
and	%11110000	; AND para detectar el '8' (fin Flecha)
cp	$d0		; $d0??
ret	nz	; NZ, entonces Retorna Inmediato (No fin Flecha)

ld	a,(settings)
res	3,a		; Res Bit3... (Fin FlechaTrampa Settings)
ld	(settings),a	; Actualiza

ld	a,(settings2)
res	3,a		; Res Bit2... (Fin FlechaTrampa Settings2)
ld	(settings2),a		; Actualiza
ret		; Retorna

;---------------------------------------------------------------------------
borra_flechatrampa1:
ld	a,(settings)
bit	3,a		; Esta ON FlechaTrampa1 Settings ?? ...
ret	nz		; Z ... entonces, Retorna inmediato...

ld	a,(settings2)
bit	3,a		; Esta ON FlechaTrampa Settings2 ?? ...
ret	nz		; Z ... entonces, Retorna inmediato...

ld	hl,$508c	; Coordenadas Iniciales FlechaTrampa
ld	b,$10		; Bucle $02 Filas

bucle_borra_flechatrampa1:
ld	(hl),$00	; Borra Byte Flecha

call	incrementar_scanline	; Incrementa un Scan (para Dibujar)
djnz	bucle_borra_flechatrampa1

ret	; Retorna

;---------------------------------------------------------------------------
;---     JR - P O S I B L E   C O L I S I O N   vs   F L E C H A        ---
;---------------------------------------------------------------------------
posible_colision_vsflecha:
ld	a,h
and	%11110000
ld	c,a

ld	a,(jugador_y)
and	%11110000
cp	c
ret	nz	; No Colision... entonces Retorna Inmediato 

ld	a,h
cp	$48
ret	c	; 1er Tercio = No colision... Retorna

ld	a,$03
call	sonido

xor	a
ld	(cont_explo_jug),a

ld	a,(jugador_set)
set	6,a		; Vida Menos = ON
ld	(jugador_set),a
;jp	no_colision
ret	; Retorna
jr	$

;---------------------------------------------------------------------------
;---    SUB - F L E C H A   T R A M P A *** RAPIDA ***  ( Nivel 1 )      ---
;---------------------------------------------------------------------------
flecha_trampa1_rapida:
ld	a,(flechatrap_y)	; Actualiza FlechaY (H)
ld	h,a
ld	a,(flechatrap_x)	; Actualiza FlechaX (L)
ld	l,a

add	a,$20
ld	c,a

;-----------------------------------------------------
ld	a,(jugador_x)
cp	c
call	z,posible_colision_vsflecha

ld	a,(jugador_x)
inc	a
cp	c
call	z,posible_colision_vsflecha

ld	a,(jugador_x)
inc	a
inc	a
cp	c
call	z,posible_colision_vsflecha

ld	a,(jugador_set)
bit	6,a
call	nz,restar_una_vida

;-----------------------------------------------------
ld	b,$10

bucle_borraflechatrampa_rapida:
ld	(hl),$00	; Borra SOLO 1er Scanline... (autoborrado)
call	incrementar_scanline
djnz	bucle_borraflechatrampa_rapida

ld	de,flechas_updown	; Situa DE en FlechasUpDown

ld	a,(flechatrap_y)
add	a,$08		; Hay que Incr H (Tercio), antes de entrar en la SUB...
ld	h,a
ld	a,(flechatrap_x)
ld	l,a
	
call	incrementar_solofila	; SUB Incrementa UNA FILA...

ld	a,l
ld	(flechatrap_x),a	; ...y actualiza FlechaX
ld	a,h
ld	(flechatrap_y),a	; ...y actualiza FlechaY
cp	$48		; 2do Tercio??
call	z,fin_flechatrampa11
cp	$50		; 3er Tercio??
call	z,fin_flechatrampa1	; SUB Posible Fin FlechaTrampa...

call	dibuja_flechatrampa

ld	a,(jugador_y)
cp	$48	; Segundo Tercio?? ...
call	z,re_attr_flecha48

ld	a,(jugador_y)
cp	$50	; Tercer Tercio?? ...
call	z,re_attr_flecha50
ret		; Retorna

;---------------------------------------------------
re_attr_flecha48:
ld 	h,$59
ld	l,$dc
ld	(hl),$07	; ATTR Flecha (blanco)
ld	l,$fc
ld	(hl),$07	; ATTR Flecha (blanco)
ret		; Retorna

re_attr_flecha50:
ld 	h,$5a
ld	l,$8c
ld	(hl),$07	; ATTR Flecha (blanco)
ld	l,$ac
ld	(hl),$07	; ATTR Flecha (blanco)
ret		; Retorna

;---------------------------------------------------------------------------
;---         SUB - D I B U J A   F L E C H A   T R A M P A               ---
;---------------------------------------------------------------------------
dibuja_flechatrampa:
ld	b,$10	; Bucle $10 (16) Scanlines

bucle_flechatrampa1:
ld	a,(de)
ld	(hl),a	; Dibuja Byte Flecha

call	incrementar_scanline	; Incrementa un Scan (para Dibujar)
inc	de			; Siguiente Byte Flecha
djnz	bucle_flechatrampa1
ret		; Retorna

;---------------------------------------------------------------------------
;---           SUB - A R Q U E R O  ( ON ) - ( Nivel 1 )                 ---
;---------------------------------------------------------------------------
arquero_on:
ld	a,(jugador_x)
cp	$9b		; Colision Vs Arquero?? ...
jr	z,colision_vsarquero	; Z, entonces salta...

ld	a,(jugador_set)
bit	4,a		; Si NO estamos atacando (espada), entonces...
jr	z,no_leatacamos	; ... continua normalmente... 

ld	a,(jugador_x)
cp	$9a		; Si atacamos en la posicion del arquero, entonces...
call	z,inicia_exploarquero	; ... Inicia Explo-Arquero ON
;cp	$9a
;call	z,inicia_exploarquero

no_leatacamos:
ld	a,(settings)
bit	4,a		; Bit4 = Z Arquero NOS apunta...
call	z,arquero_apuntando
call	nz,arquero_normal

ld	hl,$509c	; Coordenadas Arquero
ld	b,$10

bucle_dibujarquero:
call	dibujados_repetitivos

inc	l
inc	de
ld	a,(de)
ld	(hl),a

dec	l
dec	l
call	incrementar_scanline
inc	de
djnz	bucle_dibujarquero

;----------------------------
ld	hl,$5a9c	; Posicion ATTR Arquero
ld	a,$02		; Rojo (arriba), Magenta (Abajo)
ld	b,$02		; Bucle $02 Filas

bucle_attr_arquero:
ld	(hl),a		; ATTR arquero (rojo+ magenta)
inc	l
ld	(hl),a		; ATTR arquero (rojo+ magenta)
inc	l
ld	(hl),a		; ATTR arquero (rojo+ magenta)

ld	a,l
add	a,$1e
ld	l,a
ld	a,$03
djnz	bucle_attr_arquero
ret

;------------------------------------------
arquero_apuntando:
ld	de,arqueros+48
ret

arquero_normal:
ld	de,arqueros
ret

;----------------------------------------------------------------
colision_vsarquero:
ld	a,$03
call	sonido

xor	a
ld	(cont_explo_jug),a

ld	a,(jugador_set)
set	6,a		; Vida Menos = ON
ld	(jugador_set),a

call	inicia_exploarquero
ret	; Retorna

;---------------------------------------------------------------------------
;---       S U B -  I N I C I A   E X P L O - A R Q U E R O              ---
;---------------------------------------------------------------------------
inicia_exploarquero:
ld	a,$04
call	sonido

ld	a,(jugador_set)
bit	6,a
call	nz,restar_una_vida

ld	a,(settings)
set	5,a		; Bit5 = 1 Arquero OFF! (OJO esta es al reves) 
set	2,a		; Bit2 = 1 Explo-Arquero ON!
set	7,a		; Bit7 = 1 Aparece-Puerta ON!
ld	(settings),a

ld	a,(nivel)
cp	$07		; Nivel 7 ?? ... entonces...
call	z,need_key	; Ademas, hace falta volver a por la Llave

xor	a
ld	(contador_explo),a

ld	hl,$509c	; Coordenadas (estaticas) del Arquero
ld	a,h
ld	(explo_arqueroy),a	; Coordenada Y inicial Explo-Arquero
ld	a,l
ld	(explo_arquerox),a	; Coordenada X inicial Explo-Arquero
ret		; Retorna

;-------------------------------------------------
need_key:
ld	a,(settings)
res	7,a
ld	(settings),a

ld	a,(settings4)
bit	1,a
ret	nz	; Retorna si TIENES ya la Llave

set	0,a
ld	(settings4),a
ret	; Retorna

;---------------------------------------------------------------------------
;---                S U B -  E X P L O - A R Q U E R O                   ---
;---                                                                     ---
;---------------------------------------------------------------------------
explo_arquero:
ld	a,(contador_explo)	; Contador Explo-Arquero
inc	a
ld	(contador_explo),a
cp	$10			; Contador = $10 ?? ...
jr	z,fin_explo_arquero	; ... Entonces, Fin Explo-Arquero

ld	de,arquero_explota
ld	b,a		; Carga en B, Bucle incrementos

bucle_incr_animaexplos:
call	incrementa_de
call	incrementa_de
call	incrementa_de
call	incrementa_de
call	incrementa_de
call	incrementa_de
djnz	bucle_incr_animaexplos

ld	hl,$509c	; Coordenadas Arquero
ld	b,$10		; Bucle $10 ... 16

bucle_exploarquero:
call	dibujados_repetitivos

inc	l
inc	de
ld	a,(de)
ld	(hl),a

ld	a,b
cp	$01
call	z,un_halt	; Ralentizaciones
cp	$05
call	z,un_halt
cp	$09
call	z,un_halt

dec	l
dec	l
call	incrementar_scanline
inc	de
djnz	bucle_exploarquero
ret		; Retorna

;-------------------------------------------
arquero_exp_anim2:
ld	de,arquero_explota+48
ret	; Retorna

arquero_exp_anim1:
ld	de,arquero_explota
ret	; Retorna

;-------------------------------------------
fin_explo_arquero:
ld	a,(settings)
res	2,a		; Bit2 = Z ... Fin Explo-Arquero
ld	(settings),a

ld	hl,$509c	; Coordenadas Arquero
ld	b,$10		; Bucle $10 ... 16

bucle_borrado_exploarquero:
ld	(hl),$00	; Borrado
inc	l
ld	(hl),$00
inc	l
ld	(hl),$00

dec	l
dec	l
call	incrementar_scanline
djnz	bucle_borrado_exploarquero
ret	; Retorna

;-----------------------------------
un_halt:
halt
ret	; Retorna

;---------------------------------------------------------------------------
;---                S U B -  E X P L O - J U G A D O R                   ---
;---                                                                     ---
;---------------------------------------------------------------------------
explo_jugador:
ld	a,(cont_explo_jug)	; Contador Explo-Jugador
inc	a
ld	(cont_explo_jug),a
cp	$08			; Contador = $10 ?? ...
jr	z,fin_explo_jugador	; ... Z = Fin Explo-Jugador 

ld	de,caballero_explota	; Situa DE en Explo-Arquero
ld	b,a			; Cargar en B, bucle de incrementos

bucle_incr_animaexplos_jug:
call	incrementa_de
call	incrementa_de
call	incrementa_de
call	incrementa_de
call	incrementa_de
call	incrementa_de
call	incrementa_de
call	incrementa_de
djnz	bucle_incr_animaexplos_jug

ld	a,(jugador_y)
ld	h,a
ld	a,(jugador_x)
ld	l,a
;ld	hl,$509c
ld	b,$10

bucle_explo_jugador:
call	dibujados_repetitivos

inc	l
inc	de
ld	a,(de)
ld	(hl),a

inc	l
inc	de
ld	a,(de)
ld	(hl),a

ld	a,b
cp	$01
call	z,un_halt	; Ralentizaciones
cp	$05
call	z,un_halt
cp	$09
call	z,un_halt

dec	l
dec	l
dec	l
call	incrementar_scanline
inc	de
djnz	bucle_explo_jugador
ret		; Retorna

;-------------------------------------------
fin_explo_jugador:
ld	a,(jugador_set)
res	6,a		; Bit6 = Z ... Fin Vida Menos 
ld	(jugador_set),a

ld	a,(jugador_y)
ld	h,a
ld	a,(jugador_x)
ld	l,a
;ld	hl,$509c
ld	b,$10		; Bucle $10 Borrado Explo-Jugador

bucle_borrado_explo_jugador:
ld	(hl),$00	; Borrado
inc	l
ld	(hl),$00
inc	l
ld	(hl),$00

dec	l
dec	l
call	incrementar_scanline
djnz	bucle_borrado_explo_jugador
ret	; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   2 )            ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_2:
ld	a,(jugador_x)
cp	$89		; Si pisas en ladrillo $89... 
call	z,inicia_flechatrampa1	; ...activa FlechaTrampa!

ld	a,(settings)
bit	3,a			; Si NZ, entonces...
call	nz,flecha_trampa1	; SUB FlechaTrampa...

ld	a,(settings2)
bit	3,a			; Si NZ, entonces...
call	nz,flecha_trampa1_rapida ; SUB flechaTrampaRapida...

ld	a,(contador_it)
cp	$fc			; Si Z, entonces...
call	z,borra_flechatrampa1	; Borra la Flecha-Trampa (del suelo)

ld	a,(settings2)
bit	4,a			; Si NZ, entonces...
call	nz,animacion_bloquetrampa  ; SUB Anima-BloqueTrampa

ld	a,(settings4)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,indicador_key	; SUB IndicadorKey (volver a por la llave)
bit	1,a
call	nz,inventario_llave

ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jp	z,anterior_nivel
cp	$9c			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;===========================================================================
;---      SUB - INICIA ANIMACION  -  B L O Q U E   T R A M P A           ---
;---------------------------------------------------------------------------
inicia_animacion_bloquetrampa:
ld	a,(settings2)
bit	4,a		; Si Bit1 = 1 ...
ret	nz		; ... No Inicies (Ya esta), Retorna Inmediato

set	4,a		; Inicia Bit1 = 1
ld	(settings2),a	; Acutalizalo

ld	a,$14
ld	(cont_bloque_t),a

ld	a,(jugador_y)
cp	$48
call	z,bloque_2dopiso

ld	(bloquet_y),a

ld	a,(jugador_x)
add	a,$40
inc	a
ld	(bloquet_x),a
ret	; Retorna

;---------------------------------------
bloque_2dopiso:
ld	a,$50
ret	; Retorna

;===========================================================================
;---      SUB -  A N I M A C I O N  -  B L O Q U E   T R A M P A         ---
;---                                                                     ---
;---------------------------------------------------------------------------
animacion_bloquetrampa:
ld	a,(cont_bloque_t)	; Contador Bloque Trampa
dec	a
ld	(cont_bloque_t),a
jr	z,fin_animabloquet	; ... Z = Fin Animacion Bloque Trampa 

cp	$0a
call	nc,anima_bloque1
call	c,anima_bloque2

ld	a,(bloquet_y)
ld	h,a
ld	a,(bloquet_x)
ld	l,a

ld	b,$08

bucle_anima_bloquet:
call	dibujados_repetitivos

dec	l
inc	h
;call	incrementar_scanline
inc	de
djnz	bucle_anima_bloquet
ret		; Retorna

;-------------------------------------------
fin_animabloquet:
ld	a,(settings2)
res	4,a		; Anima-BloqueTrampa OFF! 
ld	(settings2),a

ld	de,bloques_ladrillos
ld	a,(bloquet_y)
ld	h,a
ld	a,(bloquet_x)
ld	l,a

ld	b,$08

bucle_fin_animabloque:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h

inc	de
djnz	bucle_fin_animabloque
ret	; Retorna

;-------------------------------------------
anima_bloque1:
ld	de,bloques_anima	; Situa DE en Bloques-Animacion
ret	; Retorna

anima_bloque2:
ld	de,bloques_anima+16	; Situa DE en Bloques-Animacion2
ret	; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   3 )            ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_3:
ld	a,(contador_it)
cp	$10			; Contador = $10 ??... entonces...
call	z,inicia_fantasma	; ...Inicia Fantasma

ld	a,(contador_it)
cp	$0a			; Contador = $0a ??... entonces...
call	z,inicia_fantasma2	; ...Inicia Fantasma(2) (Izda)

ld	a,(settings2)
bit	1,a			; Bit1 = 1 ??... entonces...
call	nz,fantasma		; ...SUB Fantasma

ld	a,(settings2)
bit	5,a			; Bit5 = 1 ??... entonces...
call	nz,fantasma2		; SUB Fantasma(2) Izda

ld	a,(settings2)
bit	2,a			; Si NZ, entonces...
call	nz,explo_fantasma	; ...SUB Explo-Fantasma

ld	a,(settings4)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,indicador_key	; SUB IndicadorKey (volver a por la llave)
bit	1,a
call	nz,inventario_llave

ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jp	z,anterior_nivel
cp	$9c			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;===========================================================================
;---            S U B -  I N I C I A   F A N T A S M A                   ---
;---------------------------------------------------------------------------
inicia_fantasma:
ld	a,(settings2)
bit	1,a		; Si Bit1 = 1 ...
ret	nz		; ... No Inicies (Ya esta), Retorna Inmediato

set	1,a		; Inicia Bit1 = 1
ld	(settings2),a	; Acutalizalo

ld	h,$50
ld	a,h
ld	(fantasma_y),a	; Inicia CoordenadaY (H)

ld	l,$5d
ld	a,l
ld	(fantasma_x),a	; Inicia CoordenadaX (L)
ret		; Retorna

;===========================================================================
;---                      S U B -  F A N T A S M A                       ---
;---                                                                     ---
;---------------------------------------------------------------------------
fantasma:
ld	a,(fantasma_y)
ld	h,a		; Actualiza Y (H)
ld	a,(fantasma_x)
ld	l,a		; Actualiza X (L)

add	a,$40
dec	a
ld	c,a	; Suma + $40 ( para Comprobar Colision )

;----------------------------------------
ld	a,(jugador_x)
cp	c		; Colision Vs Fantasma?? ...
jp	z,colision_vsfantasma	; Z, entonces salta...

ld	a,(jugador_set)
bit	4,a		; Si NO estamos atacando (espada), entonces...
jr	z,no_leatacamosf	; ... continua normalmente... 
bit	0,a		; Si NO estamos 'mirando dcha'... entonces...
jr	nz,no_leatacamosf	; ... continua normalmente...	

dec	c
ld	a,(jugador_x)
cp	c		; Si atacamos en la posicion del fantasma, entonces...
call	z,inicia_explofantasma	; ... Inicia Explo-Fantasma ON

;----------------------------------------
no_leatacamosf:
ld	a,(cont_fantasma)
dec	a			; Decrementa Contador-Fantasma Anima
ld	(cont_fantasma),a
call	z,reinicia_contf	; SUB Reinicia Contador-Fantasma Anima
cp	$05
call	nc,anima_unogiro	; SUB Animacion(1)-Giro Fantasma
call	c,anima_dosgiro		; SUB Animacion(2)-Giro Fantasma

;----------------------------------------
ld	a,(rota_fantasma)
or	a
jr	z,salta_abuclef	; Si RotacionFlecha = Z ...entonces salta al Bucle

;----------------------------------------
ld	b,a		; Si no, Carga en B, A... para Bucle de Incrementos

bucle_incr_fantasma:
call	incrementa_de	; Incrementos (de 8 en 8)... 8 x 3 = 24 Incrementos 
call	incrementa_de
call	incrementa_de

call	incrementa_de
call	incrementa_de
call	incrementa_de

call	incrementa_de
call	incrementa_de
call	incrementa_de
djnz	bucle_incr_fantasma

;---------------------------------------------
salta_abuclef:
ld	b,$18		; Bucle $18 Scanlines

bucle_dibujafantasma:
call	dibujados_repetitivos

inc	l
inc	de
ld	a,(de)		; Dibuja 3er Byte
ld	(hl),a

dec	l
dec	l
call	incrementar_scanline	; Siguiente Scan/Fila/Tercio

inc	de		; Situa DE en siguiente Byte...
djnz	bucle_dibujafantasma

;---------------------- ATTR Fantasma --------
ld	a,(fantasma_x)
add	a,$40
ld	l,a	; Actualiza CoordenadaX Fantasma

ld	h,$5a
ld	a,$47	; ATTR Fantasma (Blanco)

ld	(hl),a
inc	l
ld	(hl),a
inc	l
ld	(hl),a

;push	hl
;ld	h,$5a
;ld	(hl),$05
;inc	l
;ld	(hl),$05
;inc	l
;ld	(hl),$05
;pop	hl

;---------------------------------
ld	a,(rota_fantasma)
inc	a		; Incrementa RotaFantasma
ld	(rota_fantasma),a
cp	$08		; NZ, si no es la ultima rotacion...
ret	nz		; ... Retorna inmediato, (hemos acabado)

xor	a		; Reinicia Rotacion...
ld	(rota_fantasma),a	; ... y actualizala

;------------------------------------------------------------
;---               BORRADO DEL FANTASMA                   ---
;------------------------------------------------------------
ld	a,(fantasma_y)
ld	h,a		; Actualiza Y (H)
ld	a,(fantasma_x)
ld	l,a		; Actualiza X (L)

ld	b,$18		; Bucle $18 ( 24 Scanlines)

bucle_borradof:
inc	l
inc	l
ld	(hl),$00	; Borrado

dec	l
dec	l
call	incrementar_scanline
djnz	bucle_borradof

;------------------------------------------------------------
ld	a,(fantasma_y)
ld	h,a		; Actualiza Y (H)
ld	a,(fantasma_x)
ld	l,a		; Actualiza X (L)

dec	l	; Decrementa la X del Fantasma...
ld	a,l
ld	(fantasma_x),a	; ... y actualizala
cp	$3f
ret	nz	; Si no ha alcanzado el limite... Retorna Inmediato

;--------------------------------------
inc	l
ld	b,$18	; $18 Scanlines

bucle_borradofinal_fantasma:
ld	(hl),$00	; Borrado
inc	l
ld	(hl),$00	; Borrado
inc	l
ld	(hl),$00

dec	l
dec	l
call	incrementar_scanline	; Incr Scan/Fila/Tercio
djnz 	bucle_borradofinal_fantasma

ld	a,(settings2)
res	1,a		; Desactiva la SUB Fantasma
ld	(settings2),a
ret		; Retorna

;-------------------------------------------------------
reinicia_contf:
ld	a,$0a
ld	(cont_fantasma),a
ret	; Retorna

;-------------------------------------------------------
reinicia_contf2:
ld	a,$0a
ld	(cont_fantasma2),a
ret	; Retorna

anima_unogiro:
ld	de,fantasma_a1giro
ret		; Retorna

anima_dosgiro:
ld	de,fantasma_a2giro
ret		; Retorna

;----------------------------------------------------------------
anima_unof:
ld	de,fantasma_a1
ret		; Retorna

anima_dosf:
ld	de,fantasma_a2
ret		; Retorna

;----------------------------------------------------------------
colision_vsfantasma:
ld	a,$03
call	sonido

xor	a
ld	(cont_explo_jug),a	; Inicia Contador Explosion-Jugador

ld	a,(jugador_set)
set	6,a		; Vida Menos = ON
ld	(jugador_set),a

call	inicia_explofantasma
ret	; Retorna

;---------------------------------------------------------------------------
;---       S U B -  I N I C I A   E X P L O - F A N T A S M A            ---
;---------------------------------------------------------------------------
inicia_explofantasma:
ld	a,$04
call	sonido

ld	a,(jugador_set)
bit	6,a		; Bit6 = 1 ??... entonces...
call	nz,restar_una_vida	; SUB Restar una Vida

ld	a,(settings2)
res	1,a		; Bit1 = 0 Fantasma OFF! 
set	2,a		; Bit2 = 1 Explo-Fantasma ON!
ld	(settings2),a

xor	a
ld	(contador_explo),a

ld	a,(fantasma_y)
ld	(explo_fantasmay),a	; Coordenada Y inicial Explo-Fantasma
ld	a,(fantasma_x)
ld	(explo_fantasmax),a	; Coordenada X inicial Explo-Fantasma
ret		; Retorna

;---------------------------------------------------------------------------
;---                S U B -  E X P L O - F A N T A S M A                 ---
;---                                                                     ---
;---------------------------------------------------------------------------
explo_fantasma:
ld	a,(contador_explo)	; Contador Explo
inc	a
ld	(contador_explo),a
cp	$08			; Contador = $10 ?? ...
jr	z,fin_explo_fantasma	; ... Entonces, Fin Explo-Fantasma

ld	de,fantasma_explota
ld	b,a		; Carga en B, Bucle incrementos

bucle_incr_animaexplosf:
call	incrementa_de	; Incrementa DE (8 veces)
call	incrementa_de
call	incrementa_de

call	incrementa_de
call	incrementa_de
call	incrementa_de

call	incrementa_de
call	incrementa_de
call	incrementa_de
djnz	bucle_incr_animaexplosf

;-----------------------------------------
ld	a,(explo_fantasmay)
ld	h,a			; Actualiza H
ld	a,(explo_fantasmax)
ld	l,a			; Actualiza L

ld	b,$18		; Bucle $10 ... 16

bucle_explofantasma:
call	dibujados_repetitivos

inc	l
inc	de
ld	a,(de)
ld	(hl),a

ld	a,b
cp	$01
call	z,un_halt	; Ralentizaciones
cp	$05
call	z,un_halt
cp	$09
call	z,un_halt

dec	l
dec	l
call	incrementar_scanline
inc	de
djnz	bucle_explofantasma
ret		; Retorna

;-------------------------------------------
fin_explo_fantasma:
ld	a,(settings2)
res	2,a		; Bit2 = Z ... Fin Explo-Fantasma
ld	(settings2),a

ld	a,(explo_fantasmay)
ld	h,a			; Actualiza H
ld	a,(explo_fantasmax)
ld	l,a			; Actualiza L

ld	b,$18		; Bucle $10 ... 16

bucle_borrado_explofantasma:
ld	(hl),$00	; Borrado
inc	l
ld	(hl),$00
inc	l
ld	(hl),$00

dec	l
dec	l
call	incrementar_scanline
djnz	bucle_borrado_explofantasma
ret	; Retorna

;===========================================================================
;---     S U B -  I N I C I A   F A N T A S M A  II  (De Izda a Dcha)    ---
;---------------------------------------------------------------------------
inicia_fantasma2:
ld	a,(settings2)
bit	5,a		; Si Bit5 = 1 ...
ret	nz		; ... No Inicies (Ya esta), Retorna Inmediato

set	5,a		; Inicia Bit1 = 1
ld	(settings2),a	; Acutalizalo

ld	h,$50
ld	a,h
ld	(fantasma2_y),a	; Inicia CoordenadaY (H)

ld	l,$40
ld	a,l
ld	(fantasma2_x),a	; Inicia CoordenadaX (L)
ret		; Retorna

;===========================================================================
;---           S U B -  F A N T A S M A  II  (De Izda a Dcha)            ---
;---                                                                     ---
;---------------------------------------------------------------------------
fantasma2:
ld	a,(fantasma2_y)
ld	h,a		; Actualiza Y (H)
ld	a,(fantasma2_x)
ld	l,a		; Actualiza X (L)

add	a,$40
inc	a
ld	c,a	; Suma + $40 ( para Comparar Colision con C )

;----------------------------------------
ld	a,(jugador_x)
cp	c		; Colision Vs Fantasma?? ...
jp	z,colision_vsfantasma2	; Z, entonces salta...

ld	a,(jugador_set)
bit	4,a		; Si NO estamos atacando (espada), entonces...
jr	z,no_leatacamosf2	; ... continua normalmente... 
bit	0,a		; Si NO estamos 'mirando izda'... entonces...
jr	z,no_leatacamosf2	; ... continua normalmente...

inc	c
ld	a,(jugador_x)
cp	c		; Si atacamos en la posicion del fantasma, entonces...
call	z,inicia_explofantasma2	; ... Inicia Explo-Fantasma ON

;----------------------------------------
no_leatacamosf2:
ld	a,(cont_fantasma2)
dec	a			; Decrementa Contador-Anima Fantasma2
ld	(cont_fantasma2),a
call	z,reinicia_contf2	; Reinicia Contador-Anima Fantasma2 (Izda)
cp	$05
call	nc,anima_unof	; SUB Animacion(1) Fantasma
call	c,anima_dosf	; SUB Animacion(2) Fantasma

;----------------------------------------
ld	a,(rota_fantasma2)
or	a
jr	z,salta_abuclef2   ; Si RotacionFlecha = Z ...entonces salta al Bucle

;----------------------------------------
ld	b,a		; Si no, Carga en B, A... para Bucle de Incrementos

bucle_incr_fantasma2:
call	incrementa_de	; Incrementos (de 8 en 8)... 8 x 3 = 24 Incrementos 
call	incrementa_de
call	incrementa_de

call	incrementa_de
call	incrementa_de
call	incrementa_de

call	incrementa_de
call	incrementa_de
call	incrementa_de
djnz	bucle_incr_fantasma2

;---------------------------------------------
salta_abuclef2:
ld	b,$18		; Bucle $18 Scanlines

bucle_dibujafantasma2:
call	dibujados_repetitivos

inc	l
inc	de
ld	a,(de)		; Dibuja 3er Byte
ld	(hl),a

dec	l
dec	l
call	incrementar_scanline	; Siguiente Scan/Fila/Tercio

inc	de		; Situa DE en siguiente Byte...
djnz	bucle_dibujafantasma2

;---------------------- ATTR Fantasma --------
ld	a,(fantasma2_x)
add	a,$40
ld	l,a	; Coordenada X Fantasma (+ $40)

ld	h,$5a	; Tercer Tercio
ld	a,$47	; ATTR Fantasma (Blanco)

ld	(hl),a
inc	l
ld	(hl),a
inc	l
ld	(hl),a

;push	hl
;ld	h,$5a
;ld	(hl),$05
;inc	l
;ld	(hl),$05
;inc	l
;ld	(hl),$05
;pop	hl

;---------------------------------
ld	a,(rota_fantasma2)
inc	a		; Incrementa RotaFantasma
ld	(rota_fantasma2),a
cp	$08		; NZ, si no es la ultima rotacion...
ret	nz		; ... Retorna inmediato, (hemos acabado)

xor	a		; Reinicia Rotacion...
ld	(rota_fantasma2),a	; ... y actualizala

;------------------------------------------------------------
;---               BORRADO DEL FANTASMA                   ---
;------------------------------------------------------------
ld	a,(fantasma2_y)
ld	h,a		; Actualiza Y (H)
ld	a,(fantasma2_x)
ld	l,a		; Actualiza X (L)

ld	b,$18		; Bucle $18 (24 Scanlines)

bucle_borradof2:
;inc	l
;inc	l
ld	(hl),$00	; Borrado

;dec	l
;dec	l
call	incrementar_scanline
djnz	bucle_borradof2

;------------------------------------------------------------
ld	a,(fantasma2_y)
ld	h,a		; Actualiza Y (H)
ld	a,(fantasma2_x)
ld	l,a		; Actualiza X (L)

inc	l	; Decrementa la X del Fantasma...
ld	a,l
ld	(fantasma2_x),a	; ... y actualizala
cp	$5d
ret	nz	; Si no ha alcanzado el limite... Retorna Inmediato

;--------------------------------------
;inc	l
ld	b,$18	; $18 Scanlines

bucle_borradofinal_fantasma2:
ld	(hl),$00	; Borrado
inc	l
ld	(hl),$00	; Borrado
inc	l
ld	(hl),$00

dec	l
dec	l
call	incrementar_scanline	; Incr Scan/Fila/Tercio
djnz 	bucle_borradofinal_fantasma2

ld	a,(settings2)
res	5,a		; Desactiva la SUB Fantasma
ld	(settings2),a
ret		; Retorna

;----------------------------------------------------------------
colision_vsfantasma2:
ld	a,$03
call	sonido

xor	a
ld	(cont_explo_jug),a	; Inicia Contador de la Explosion Jugador

ld	a,(jugador_set)
set	6,a		; Vida Menos = ON
ld	(jugador_set),a

call	inicia_explofantasma2
ret	; Retorna

;---------------------------------------------------------------------------
;---     S U B -  I N I C I A   E X P L O - F A N T A S M A  *** II ***  ---
;---------------------------------------------------------------------------
inicia_explofantasma2:
ld	a,$04
call	sonido

ld	a,(jugador_set)
bit	6,a		; Bit6 = 1 ?? ... 
call	nz,restar_una_vida	; SUB Restar una Vida

ld	a,(settings2)
res	5,a		; Bit5 = 0 Fantasma OFF! 
set	2,a		; Bit2 = 1 Explo-Fantasma ON!
ld	(settings2),a

xor	a
ld	(contador_explo),a	; Inicia Contador-Explosion Fantasma2

ld	a,(fantasma2_y)
ld	(explo_fantasmay),a	; Coordenada Y inicial Explo-Fantasma
ld	a,(fantasma2_x)
ld	(explo_fantasmax),a	; Coordenada X inicial Explo-Fantasma
ret		; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   4 )            ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_4:
ld	a,(contador_it)
cp	$03			; Contador = $10 ??... entonces...
call	z,inicia_1ravez		; ...Inicia CaerGota

ld	a,(settings3)
bit	1,a			; Bit1 = 1 ??... entonces...
call	nz,caer_gota		; ...SUB Caer Gota

ld	a,(settings3)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,gota_impactasuelo	; SUB Gota impacta Suelo

ld	a,(settings3)
bit	2,a			; Bit2 = 1 ??... entonces...
call	nz,gota_techo		; SUB Gota sale del techo

ld	a,(contador_it)
cp	$0a			; $0a ??... entonces...
call	z,inicia_fantasma2	; Inicia el Fantasma2 (Izda)

ld	a,(settings2)
bit	5,a			; Bit5 = 1 ??... entonces...
call	nz,fantasma2		; SUB Fantasma2 (Izda)

ld	a,(settings2)
bit	2,a			; Si NZ, entonces...
call	nz,explo_fantasma	; ...SUB Explo-Fantasma

ld	a,(settings4)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,indicador_key	; SUB IndicadorKey (volver a por la llave)
bit	1,a
call	nz,inventario_llave

ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jp	z,anterior_nivel
cp	$9c			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;===========================================================================
;---            S U B -  I N I C I A   G O T A - T E C H O               ---
;---------------------------------------------------------------------------
inicia_gotatecho:
ld	a,(settings3)
bit	2,a		; Si NZ, entones...
ret	nz		; Retorna Inmediato (ya esta Iniciado)

set	2,a		; Bit3 = 1 (Settings) Lenta
ld	(settings3),a

ld	a,$00
ld	(cont_gota),a	; Inicia Contador-Gota

ld	a,$0a
ld	(cont_halt),a	; Inicia Contador Ralentizador-Gota

ld	h,$48
ld	a,h
ld	(gota_y),a	; Inicia GotaY (H)

ld	a,$70
ld	(gota_x),a	; Inicia GotaX (L)

ld	a,(nivel)
cp	$05		; Nivel 5??... entonces...
call	z,gota_nivel5	; SUB Inicia GotaX del Nivel 5
cp	$07
call	z,gota_nivel7	; SUB Inicia GotaX del Nivel 7
cp	$0a
call	z,gota_nivel10	; SUB Inicia GotaX del Nivel 10
cp	$0d
call	z,gota_nivel13	; SUB Inicia GotaX del Nivel 13
cp	$0e
call	z,gota_nivel14	; SUB Inicia GotaX del Nivel 14
ret	; Retorna

;---------------------------------------------
inicia_1ravez:
ld	a,(settings3)
bit	3,a
ret	nz		; Si Bit3 = 1 ...Retorna (Ya esta)

set	3,a
ld	(settings3),a	; Establece Bit3 = 1 
call	inicia_gotatecho	; SUB Inicia Gota-Techo
ret	; Retorna

;---------------------------------------------
gota_nivel5:
ld	a,$6a
ld	(gota_x),a	; $6B = Coordenada GotaX (Nivel 5)
ret	; Retorna

;---------------------------------------------
gota_nivel7:
ld	a,$6d
ld	(gota_x),a	; $6B = Coordenada GotaX (Nivel 5)
ret	; Retorna

;---------------------------------------------
gota_nivel10:
ld	a,$4a
ld	(gota_x),a	; $6B = Coordenada GotaX (Nivel 5)
ret	; Retorna

;---------------------------------------------
gota_nivel13:
ld	a,$8a
ld	(gota_x),a	; $6B = Coordenada GotaX (Nivel 5)
ret	; Retorna

;---------------------------------------------
gota_nivel14:
ld	a,$6a
ld	(gota_x),a	; $6B = Coordenada GotaX (Nivel 5)
ret	; Retorna

;===========================================================================
;---                S U B -  G O T A  ( SALE DEL TECHO )                 ---
;---                                                                     ---
;---------------------------------------------------------------------------
gota_techo:
ld	a,(gota_y)	; Actualiza FlechaY (H)
ld	h,a
ld	a,(gota_x)	; Actualiza FlechaX (L)
ld	l,a

;---------------------------------------------------
ld	de,gotatecho-8		; Situa DE en GotaSuelo

ld	a,(nivel)
cp	$05
jp	z,incrementar_contgota_rapida

ld	a,(cont_halt)
dec	a
ld	(cont_halt),a
call	z,incrementar_cont_gota

comienza_losincrementos:
ld	a,(cont_gota)
ld	b,a
cp	$08
jr	z,fin_gotatecho

bucle_incr_gotatecho:
call	incrementa_de
djnz	bucle_incr_gotatecho

;--------------------------------------------------
ld	b,$08

bucle_dibuja_gotatecho:
ld	a,(de)
ld	(hl),a

call	incrementar_scanline
inc	de
djnz	bucle_dibuja_gotatecho
ret		; Retorna

;--------------------------------------------------
fin_gotatecho:
ld	a,(settings3)
res	2,a		; Set Bit0 ... (FIN Gota-Techo)
ld	(settings3),a	; Actualiza

ld	b,$08

bucle_ultimoborrado_gotatecho:
ld	(hl),$00
call	incrementar_scanline
djnz	bucle_ultimoborrado_gotatecho
call	inicia_caergota
ret		; Retorna

;===========================================================================
;---            S U B -  I N I C I A   C A E R   G O T A                 ---
;---------------------------------------------------------------------------
inicia_caergota:
ld	a,(settings3)
bit	1,a		; Si NZ, entones...
ret	nz		; Retorna Inmediato (ya esta Iniciado)

set	1,a		; Bit1 = 1 (Settings3)
ld	(settings3),a

ld	h,$48
ld	a,h
ld	(gota_y),a	; Inicia GotaY (H)

;ld	a,$70
;ld	(gota_x),a	; Inicia GotaX (L)
ret	; Retorna

;===========================================================================
;---                     S U B -  C A E R   G O T A                      ---
;---                                                                     ---
;---------------------------------------------------------------------------
caer_gota:
ld	a,(gota_y)	; Actualiza FlechaY (H)
ld	h,a
ld	a,(gota_x)	; Actualiza FlechaX (L)
ld	l,a

add	a,$20
ld	c,a

ld	a,(jugador_set)
bit	6,a
jr	nz,no_colisiongota

;-----------------------------------------------------
ld	a,(jugador_x)
cp	c
call	z,posible_colision_vsgota

ld	a,(jugador_x)
inc	a
cp	c
call	z,posible_colision_vsgota

ld	a,(jugador_x)
inc	a
inc	a
cp	c
call	z,posible_colision_vsgota

ld	a,(jugador_set)
bit	6,a
call	nz,restar_una_vida

jr	no_colisiongota

;-----------------------------------------------------
no_colisiongota:
ld	a,(nivel)
cp	$0a
jr	z,no_colisiongota_rapida
cp	$0d
jr	z,no_colisiongota_rapida

ld	(hl),$00	; Borra SOLO 1er Scanline... (autoborrado)

ld	de,gota		; Situa DE en Gota

call	incrementar_scanline	; Incrementa UN Scan...
ld	a,l
ld	(gota_x),a		; ...y actualiza GotaX
ld	a,h
ld	(gota_y),a		; ...y actualiza GotaY
cp	$50			; 3er Tercio??
call	z,fin_gota	; SUB Posible Fin FlechaTrampa...

call	dibuja_flechatrampa	; Dibuja GOTA! en este caso
ret	; Retorna

;-----------------------------------------------------
no_colisiongota_rapida:
ld	b,$08

bucle_borra_gotarapida:
ld	(hl),$00	; Borra Scanline...
call	incrementar_scanline
djnz	bucle_borra_gotarapida

ld	de,gota		; Situa DE en Gota
ld	a,(gota_y)
add	a,$08		; Hay que Incr H (Tercio), antes de entrar en la SUB...
ld	h,a

ld	a,(gota_x)
ld	l,a

call	incrementar_solofila

ld	a,l
ld	(gota_x),a		; ...y actualiza GotaX
ld	a,h
ld	(gota_y),a		; ...y actualiza GotaY
cp	$50			; 3er Tercio??
call	z,fin_gota	; SUB Posible Fin GotaRapida...

call	dibuja_flechatrampa	; Dibuja GOTA! en este caso
ret	; Retorna

;-------------------------------------------------------
fin_gota:
ld	a,(gota_x)
and	%11110000	; AND para detectar el '8' o '9' (Fin Gota)
cp	$90		; $90??
jr	z,ochenta_90	; Z, entonces (Fin Gota)
cp	$80
jr	z,ochenta_90
ret	; Retorna

ochenta_90:
ld	a,(settings3)
res	1,a		; Res Bit1 ... (Fin Gota)
set	0,a		; Set Bit0 ... (Inicia Gota-Suelo)
ld	(settings3),a	; Actualiza

ld	a,$03
call	sonido

ld	a,$00
ld	(cont_gota),a

ld	a,$0a
ld	(cont_halt),a

ld	a,(gota_x)
add	a,$20
ld	(gota_x),a
ret		; Retorna

;---------------------------------------------------------------------------
;---     JR - P O S I B L E   C O L I S I O N   vs   L A   G O T A       ---
;---------------------------------------------------------------------------
posible_colision_vsgota:
ld	a,h
and	%11110000
ld	c,a

ld	a,(jugador_y)
and	%11110000
cp	c
ret	nz	; No Colision... entonces Retorna Inmediato 

ld	a,h
cp	$48
ret	c	; 1er Tercio = No colision... Retorna

ld	a,$03
call	sonido

xor	a
ld	(cont_explo_jug),a

ld	a,(settings3)
res	0,a
res	3,a
ld	(settings3),a

ld	a,(jugador_set)
set	6,a		; Vida Menos = ON
ld	(jugador_set),a
;jp	no_colision
ret	; Retorna
jr	$

ret		; Retorna

;===========================================================================
;---                S U B -  G O T A  IMPACTA EN EL SUELO                ---
;---                                                                     ---
;---------------------------------------------------------------------------
gota_impactasuelo:
ld	a,(gota_y)	; Actualiza FlechaY (H)
ld	h,a
ld	a,(gota_x)	; Actualiza FlechaX (L)
ld	l,a

sub	$20
ld	c,a

ld	a,(jugador_set)
bit	6,a
jr	nz,no_colisiongota2

;-----------------------------------------------------
ld	a,(jugador_x)
dec	a
cp	c
call	z,posible_colision_vsgota

ld	a,(jugador_x)
cp	c
call	z,posible_colision_vsgota

ld	a,(jugador_x)
inc	a
cp	c
call	z,posible_colision_vsgota

ld	a,(jugador_x)
inc	a
inc	a
cp	c
call	z,posible_colision_vsgota

ld	a,(jugador_set)
bit	6,a
call	nz,restar_una_vida

;---------------------------------------------------
no_colisiongota2:
ld	de,gotasuelo-16		; Situa DE en GotaSuelo

ld	a,(cont_halt)
dec	a
ld	(cont_halt),a
call	z,incrementar_cont_gota

ld	a,(cont_gota)
ld	b,a
cp	$05
jr	z,fin_gotadefinitivo

bucle_incr_gotasuelo:
call	incrementa_de
call	incrementa_de
djnz	bucle_incr_gotasuelo

;--------------------------------------------------
salta_incr_gota:
ld	b,$08

bucle_dibuja_gotasuelo:
ld	a,l
sub	$20
ld	l,a
ld	(hl),$00
add	a,$20
ld	l,a

call	dibujados_repetitivos
;halt

dec	l
call	incrementar_scanline
inc	de
djnz	bucle_dibuja_gotasuelo
ret		; Retorna

;--------------------------------------------------
fin_gotadefinitivo:
ld	a,(settings3)
res	0,a		; Set Bit0 ... (FIN Gota-Suelo)
ld	(settings3),a	; Actualiza

ld	b,$08

bucle_ultimoborrado_gota:
ld	(hl),$00

inc	l
ld	(hl),$00

dec	l
call	incrementar_scanline
djnz	bucle_ultimoborrado_gota
call	inicia_gotatecho
ret		; Retorna

;------------------------------------------
incrementar_cont_gota:
ld	a,$0a
ld	(cont_halt),a

ld	a,(cont_gota)
inc	a
ld	(cont_gota),a
ret	; Retorna

;------------------------------------------
incrementar_cont_gota2:
ld	a,$0a
ld	(cont_halt2),a

ld	a,(cont_gota2)
inc	a
ld	(cont_gota2),a
ret	; Retorna

;-------------------------------------------
incrementar_contgota_rapida:
ld	a,(cont_gota)
inc	a
ld	(cont_gota),a
jp	comienza_losincrementos

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   5 )            ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_5:
ld	a,(contador_it)
cp	$02			; Contador = $10 ??... entonces...
call	z,inicia_1ravez		; ...Inicia CaerGota (por 1ra Vez)

ld	a,(contador_it)
cp	$0f			; Contador = $0f ??... entonces...
call	z,inicia_1ravez2	; ...Inicia CaerGota(2) por 1ra Vez

ld	a,(settings3)
bit	1,a			; Bit1 = 1 ??... entonces...
call	nz,caer_gota		; ...SUB Caer Gota

ld	a,(settings3)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,gota_impactasuelo	; ...SUB Gota Impacta-Suelo

ld	a,(settings3)
bit	2,a			; Bit2 = 1 ??... entonces...
call	nz,gota_techo		; ...SUB Gota sale del Techo

ld	a,(settings3)
bit	4,a			; Bit4 = 1 ?? ... entonces...
call	nz,gota_impactasuelo2	; ...SUB Gota Impacta-Suelo(2)

ld	a,(settings3)
bit	5,a			; Bit5 = 1 ?? ... entonces...
call	nz,caer_gota2		; ...SUB Caer Gota(2)

ld	a,(settings3)
bit	6,a			; Bit6 = 1 ??... entonces...
call	nz,gota_techo2		; ...SUB Gota sale del Techo(2)

ld	a,(contador_it)
cp	$03			; $03, entonces ...
call	z,inicia_flecha_arquerozero   ;...Inicia flechaArquero

ld	a,(settings)
bit	4,a			; NZ = SUB flechaArquero
call	nz,flecha_arquerozero

ld	a,(jugador_x)
cp	$89		; Si pisas en ladrillo $89... 
call	z,inicia_flechatrampa1	; ...activa FlechaTrampa!

ld	a,(settings)
bit	3,a			; Si NZ, entonces...
call	nz,flecha_trampa1	; SUB FlechaTrampa...

ld	a,(settings2)
bit	3,a			; Si NZ, entonces...
call	nz,flecha_trampa1_rapida ; SUB flechaTrampaRapida...

ld	a,(contador_it)
cp	$fc			; Si Z, entonces...
call	z,borra_flechatrampa1	; Borra la Flecha-Trampa (del suelo)

ld	a,(settings2)
bit	4,a			; Si NZ, entonces...
call	nz,animacion_bloquetrampa  ; SUB Anima-BloqueTrampa

ld	a,(settings4)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,indicador_key	; SUB IndicadorKey (volver a por la llave)
bit	1,a
call	nz,inventario_llave

ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jp	z,anterior_nivel
cp	$9c			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;===========================================================================
;---            S U B -  I N I C I A   G O T A (2) - T E C H O           ---
;---------------------------------------------------------------------------
inicia_gotatecho2:
ld	a,(settings3)
bit	6,a		; Si NZ, entones...
ret	nz		; Retorna Inmediato (ya esta Iniciado)

set	6,a		; Bit3 = 1 (Settings) Lenta
ld	(settings3),a

ld	a,$00
ld	(cont_gota2),a

ld	a,$0a
ld	(cont_halt2),a

ld	h,$48
ld	a,h
ld	(gota2_y),a	; Inicia Gota2Y (H)

ld	a,$7c
ld	(gota2_x),a	; Inicia Gota2X (L)

ld	a,(nivel)
cp	$05
call	z,gota2_nivel5
cp	$06
call	z,gota2_nivel6
cp	$0a
call	z,gota2_nivel10
cp	$0d
call	z,gota2_nivel13
cp	$0e
call	z,gota2_nivel14
ret	; Retorna

;---------------------------------------------
inicia_1ravez2:
ld	a,(settings3)
bit	7,a		; Bit7 = 1 ?? ...entonces...
ret	nz		; ...Retorna inmediato (Ya esta)

set	7,a		; Establece Bit7 = 1
ld	(settings3),a	; ... Y Actualiza
call	inicia_gotatecho2	; SUB Inicia Gota-Techo(2)
ret	; Retorna

;---------------------------------------------
gota2_nivel5:
ld	a,$76		; CoordenadaX Gota2...
ld	(gota2_x),a	; ... Actualiza	
ret	; Retorna

;---------------------------------------------
gota2_nivel6:
ld	a,$76		; CoordenadaX Gota2...
ld	(gota2_x),a	; ... Actualiza	
ret	; Retorna

;---------------------------------------------
gota2_nivel10:
ld	a,$57		; CoordenadaX Gota2...
ld	(gota2_x),a	; ... Actualiza	
ret	; Retorna

;---------------------------------------------
gota2_nivel13:
ld	a,$97		; CoordenadaX Gota2...
ld	(gota2_x),a	; ... Actualiza	
ret	; Retorna

;---------------------------------------------
gota2_nivel14:
ld	a,$78		; CoordenadaX Gota2...
ld	(gota2_x),a	; ... Actualiza	
ret	; Retorna

;===========================================================================
;---                S U B -  G O T A (2)  ( SALE DEL TECHO )             ---
;---                                                                     ---
;---------------------------------------------------------------------------
gota_techo2:
ld	a,(gota2_y)	; Actualiza FlechaY (H)
ld	h,a
ld	a,(gota2_x)	; Actualiza FlechaX (L)
ld	l,a

;---------------------------------------------------
ld	de,gotatecho-8		; Situa DE en GotaSuelo

;ld	a,(nivel)
;cp	$05
;jp	z,incrementar_contgota_rapida2

ld	a,(cont_halt2)
dec	a
ld	(cont_halt2),a
call	z,incrementar_cont_gota2

comienza_losincrementos2:
ld	a,(cont_gota2)
ld	b,a
cp	$08
jr	z,fin_gotatecho2

bucle_incr_gotatecho2:
call	incrementa_de
djnz	bucle_incr_gotatecho2

;--------------------------------------------------
ld	b,$08

bucle_dibuja_gotatecho2:
ld	a,(de)
ld	(hl),a

call	incrementar_scanline
inc	de
djnz	bucle_dibuja_gotatecho2
ret		; Retorna

;--------------------------------------------------
fin_gotatecho2:
ld	a,(settings3)
res	6,a		; Set Bit0 ... (FIN Gota-Techo)
ld	(settings3),a	; Actualiza

ld	b,$08

bucle_ultimoborrado_gotatecho2:
ld	(hl),$00
call	incrementar_scanline
djnz	bucle_ultimoborrado_gotatecho2
call	inicia_caergota2
ret		; Retorna

;===========================================================================
;---            S U B -  I N I C I A   C A E R   G O T A  (2)            ---
;---------------------------------------------------------------------------
inicia_caergota2:
ld	a,(settings3)
bit	5,a		; Si NZ, entones...
ret	nz		; Retorna Inmediato (ya esta Iniciado)

set	5,a		; Bit1 = 1 (Settings3)
ld	(settings3),a

ld	h,$48
ld	a,h
ld	(gota2_y),a	; Inicia GotaY (H)

;ld	a,$70
;ld	(gota_x),a	; Inicia GotaX (L)
ret	; Retorna

;===========================================================================
;---                     S U B -  C A E R   G O T A  (2)                 ---
;---                                                                     ---
;---------------------------------------------------------------------------
caer_gota2:
ld	a,(gota2_y)	; Actualiza FlechaY (H)
ld	h,a
ld	a,(gota2_x)	; Actualiza FlechaX (L)
ld	l,a

add	a,$20
ld	c,a

ld	a,(jugador_set)
bit	6,a
jr	nz,no_colisiongota_dos

;-----------------------------------------------------
ld	a,(jugador_x)
cp	c
call	z,posible_colision_vsgota2

ld	a,(jugador_x)
inc	a
cp	c
call	z,posible_colision_vsgota2

ld	a,(jugador_x)
inc	a
inc	a
cp	c
call	z,posible_colision_vsgota2

ld	a,(jugador_set)
bit	6,a
call	nz,restar_una_vida

jr	no_colisiongota_dos

;-----------------------------------------------------
no_colisiongota_dos:
ld	(hl),$00	; Borra SOLO 1er Scanline... (autoborrado)

ld	de,gota		; Situa DE en Gota

call	incrementar_scanline	; Incrementa UN Scan...
ld	a,l
ld	(gota2_x),a		; ...y actualiza GotaX
ld	a,h
ld	(gota2_y),a		; ...y actualiza GotaY
cp	$50			; 3er Tercio??
call	z,fin_gota2	; SUB Posible Fin FlechaTrampa...

call	dibuja_flechatrampa	; Dibuja GOTA! en este caso
ret	; Retorna

;-----------------------------------------------------
no_colisiongota_rapida2:
ld	b,$08

bucle_borra_gotarapida2:
ld	(hl),$00	; Borra Scanline...
call	incrementar_scanline
djnz	bucle_borra_gotarapida2

ld	de,gota		; Situa DE en Gota
ld	a,(gota2_y)
add	a,$08		; Hay que Incr H (Tercio), antes de entrar en la SUB...
ld	h,a

ld	a,(gota2_x)
ld	l,a

call	incrementar_solofila

ld	a,l
ld	(gota2_x),a		; ...y actualiza GotaX
ld	a,h
ld	(gota2_y),a		; ...y actualiza GotaY
cp	$50			; 3er Tercio??
call	z,fin_gota2	; SUB Posible Fin GotaRapida...

call	dibuja_flechatrampa	; Dibuja GOTA! en este caso
ret	; Retorna

;-------------------------------------------------------
fin_gota2:
ld	a,(gota2_x)
and	%11110000	; AND para detectar el '8' o '9' (Fin Gota)
cp	$90		; $90??
jr	z,ochenta_90_dos	; Z, entonces (Fin Gota)
cp	$80
jr	z,ochenta_90_dos
ret	; Retorna

ochenta_90_dos:
ld	a,(settings3)
res	5,a		; Res Bit1 ... (Fin Gota)
set	4,a		; Set Bit0 ... (Inicia Gota-Suelo)
ld	(settings3),a	; Actualiza

ld	a,$03
call	sonido

ld	a,$00
ld	(cont_gota2),a

ld	a,$0a
ld	(cont_halt2),a

ld	a,(gota2_x)
add	a,$20
ld	(gota2_x),a
ret		; Retorna

;---------------------------------------------------------------------------
;---     JR - P O S I B L E   C O L I S I O N   vs   L A   G O T A  (2)  ---
;---------------------------------------------------------------------------
posible_colision_vsgota2:
ld	a,h
and	%11110000
ld	c,a

ld	a,(jugador_y)
and	%11110000
cp	c
ret	nz	; No Colision... entonces Retorna Inmediato 

ld	a,h
cp	$48
ret	c	; 1er Tercio = No colision... Retorna

ld	a,$03
call	sonido

xor	a
ld	(cont_explo_jug),a

ld	a,(settings3)
res	4,a
res	7,a
ld	(settings3),a

ld	a,(jugador_set)
set	6,a		; Vida Menos = ON
ld	(jugador_set),a
;jp	no_colision
ret	; Retorna
jr	$

ret		; Retorna

;===========================================================================
;---                S U B -  G O T A (2) IMPACTA EN EL SUELO             ---
;---                                                                     ---
;---------------------------------------------------------------------------
gota_impactasuelo2:
ld	a,(gota2_y)	; Actualiza FlechaY (H)
ld	h,a
ld	a,(gota2_x)	; Actualiza FlechaX (L)
ld	l,a

sub	$20
ld	c,a

ld	a,(jugador_set)
bit	6,a
jr	nz,no_colisiongota_2dos

;-----------------------------------------------------
ld	a,(jugador_x)
dec	a
cp	c
call	z,posible_colision_vsgota2

ld	a,(jugador_x)
cp	c
call	z,posible_colision_vsgota2

ld	a,(jugador_x)
inc	a
cp	c
call	z,posible_colision_vsgota2

ld	a,(jugador_x)
inc	a
inc	a
cp	c
call	z,posible_colision_vsgota2

ld	a,(jugador_set)
bit	6,a
call	nz,restar_una_vida

;---------------------------------------------------
no_colisiongota_2dos:
ld	de,gotasuelo-16		; Situa DE en GotaSuelo

ld	a,(cont_halt2)
dec	a
ld	(cont_halt2),a
call	z,incrementar_cont_gota2

ld	a,(cont_gota2)
ld	b,a
cp	$05
jr	z,fin_gotadefinitivo2

bucle_incr_gotasuelo2:
call	incrementa_de
call	incrementa_de
djnz	bucle_incr_gotasuelo2

;--------------------------------------------------
salta_incr_gota2:
ld	b,$08

bucle_dibuja_gotasuelo2:
ld	a,l
sub	$20
ld	l,a
ld	(hl),$00
add	a,$20
ld	l,a

call	dibujados_repetitivos
;halt

dec	l
call	incrementar_scanline
inc	de
djnz	bucle_dibuja_gotasuelo2
ret		; Retorna

;--------------------------------------------------
fin_gotadefinitivo2:
ld	a,(settings3)
res	4,a		; Set Bit0 ... (FIN Gota-Suelo)
ld	(settings3),a	; Actualiza

ld	b,$08

bucle_ultimoborrado_gota2:
ld	(hl),$00

inc	l
ld	(hl),$00

dec	l
call	incrementar_scanline
djnz	bucle_ultimoborrado_gota2
call	inicia_gotatecho2
ret		; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   6 )            ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_6:
ld	a,(contador_it)
cp	$0f			; Contador = $0f ??... entonces...
call	z,inicia_1ravez2	; ...Inicia CaerGota(2) por 1ra Vez

ld	a,(settings3)
bit	4,a			; Bit4 = 1 ?? ... entonces...
call	nz,gota_impactasuelo2	; ...SUB Gota Impacta-Suelo(2)

ld	a,(settings3)
bit	5,a			; Bit5 = 1 ?? ... entonces...
call	nz,caer_gota2		; ...SUB Caer Gota(2)

ld	a,(settings3)
bit	6,a			; Bit6 = 1 ??... entonces...
call	nz,gota_techo2		; ...SUB Gota sale del Techo(2)

ld	a,(contador_it)
cp	$03			; $03, entonces ...
call	z,inicia_flecha_arquerozero   ;...Inicia flechaArquero

ld	a,(settings)
bit	4,a			; NZ = SUB flechaArquero
call	nz,flecha_arquerozero

ld	a,(jugador_x)
cp	$8d		; Si pisas en ladrillo $8d... 
call	z,inicia_flechatrampa1	; ...activa FlechaTrampa!

ld	a,(settings)
bit	3,a			; Si NZ, entonces...
call	nz,flecha_trampa1	; SUB FlechaTrampa...

ld	a,(settings2)
bit	3,a			; Si NZ, entonces...
call	nz,flecha_trampa1_rapida ; SUB flechaTrampaRapida...

ld	a,(contador_it)
cp	$fc			; Si Z, entonces...
call	z,borra_flechatrampa1	; Borra la Flecha-Trampa (del suelo)

ld	a,(settings2)
bit	4,a			; Si NZ, entonces...
call	nz,animacion_bloquetrampa  ; SUB Anima-BloqueTrampa

ld	a,(contador_it)
cp	$0a			; $0a ??... entonces...
call	z,inicia_fantasma2	; Inicia el Fantasma2 (Izda)

ld	a,(settings2)
bit	5,a			; Bit5 = 1 ??... entonces...
call	nz,fantasma2		; SUB Fantasma2 (Izda)

ld	a,(settings2)
bit	2,a			; Si NZ, entonces...
call	nz,explo_fantasma	; ...SUB Explo-Fantasma

ld	a,(settings4)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,indicador_key	; SUB IndicadorKey (volver a por la llave)
bit	1,a
call	nz,inventario_llave

ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jp	z,anterior_nivel
cp	$9c			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   7 )            ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_7:
ld	a,(settings4)
bit	1,a			; Si NZ (TIENES Llave), entonces...
call	nz,entrepuertas_onoff	; Comprobacion PREVIA-entrepuertas
;call	nz,comprueba_entrepuertas	; ... SUB Comprueba si entras...

ld	a,(contador_it)
cp	$20			; CP = $20?? ...entonces...
call	z,inicia_flecha_arquerozero	; ...Inicia flechaArquero

ld	a,(settings)
bit	4,a			; NZ = SUB flechaArquero
call	nz,flecha_arquerozero

ld	a,(settings)
bit	5,a			; Si Z, entonces...
call	z,arquero_on		; SUB Arquero

ld	a,(settings)
bit	2,a			; Si NZ, entonces...
call	nz,explo_arquero	; ...SUB Explo-Arquero

ld	a,(contador_it)
cp	$09			; Contador = $0a ??... entonces...
call	z,inicia_fantasma2	; ...Inicia Fantasma(2) (Izda)
cp	$90
call	z,inicia_fantasma2

ld	a,(settings2)
bit	1,a			; Bit1 = 1 ??... entonces...
call	nz,fantasma		; ...SUB Fantasma

ld	a,(settings2)
bit	5,a			; Bit5 = 1 ??... entonces...
call	nz,fantasma2		; SUB Fantasma(2) Izda

ld	a,(settings2)
bit	2,a			; Si NZ, entonces...
call	nz,explo_fantasma	; ...SUB Explo-Fantasma

ld	a,(contador_it)
cp	$03			; Contador = $10 ??... entonces...
call	z,inicia_1ravez		; ...Inicia CaerGota

ld	a,(settings3)
bit	1,a			; Bit1 = 1 ??... entonces...
call	nz,caer_gota		; ...SUB Caer Gota

ld	a,(settings3)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,gota_impactasuelo	; SUB Gota impacta Suelo

ld	a,(settings3)
bit	2,a			; Bit2 = 1 ??... entonces...
call	nz,gota_techo		; SUB Gota sale del techo

ld	a,(settings4)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,indicador_key	; SUB IndicadorKey (volver a por la llave)
bit	1,a
call	nz,inventario_llave

ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jp	z,anterior_nivel
cp	$dd			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;===========================================================================
;---    S U B  -  I N D I C A D O R   K E Y   (Vover a por la Llave)     ---
;---                                                                     ---
;---------------------------------------------------------------------------
indicador_key:
ld	hl,$5002
ld	de,llave
ld	b,$08

bucle_dibujallave_indica:
call	dibujados_repetitivos

dec	l
call	incrementar_scanline
inc	de
djnz	bucle_dibujallave_indica

;--------------- Dibuja Flecha-Retorno --------------
ld	hl,$5022
ld	de,flecha_retorno-16

;-------------------------------------
ld	a,(indica_halt)
dec	a
ld	(indica_halt),a
jr	nz,comienza_incrementos

;-------------------------------------
ld	a,$07
ld	(indica_halt),a

ld	a,(rota_indicador)
inc	a
ld	(rota_indicador),a
cp	$08
jr	nz,comienza_incrementos

ld	a,$01
ld	(rota_indicador),a

;-------------------------------------
comienza_incrementos:
ld	a,(rota_indicador)
ld	b,a

bucle_incrementos_ind:
call	incrementa_de
call	incrementa_de
djnz	bucle_incrementos_ind

;-------------------------------------
ld	b,$08

bucle_flecharetorno:
call	dibujados_repetitivos

dec	l
call 	incrementar_scanline
inc	de
djnz	bucle_flecharetorno
ret	; Retorna

;---------------------------------------------------------------------------
entrepuertas_onoff:
ld	a,(settings)
bit	5,a
call	nz,comprueba_entrepuertas
ret	; Retorna

;===========================================================================
;---             S U B -  I N V E N T A R I O   L L A V E                ---
;---------------------------------------------------------------------------
inventario_llave:
ld	hl,$401d
ld	de,llave
ld	b,$08

bucle_dibujallave_inventario:
call	dibujados_repetitivos

dec	l
call	incrementar_scanline
inc	de
djnz	bucle_dibujallave_inventario

ret	; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   8 )            ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_8:
ld	a,(contador_it)
cp	$09			; Contador = $0a ??... entonces...
call	z,inicia_fantasma2	; ...Inicia Fantasma(2) (Izda)
cp	$90
call	z,inicia_fantasma2
cp	$bc
call	z,inicia_fantasma

ld	a,(settings2)
bit	1,a			; Bit1 = 1 ??... entonces...
call	nz,fantasma		; ...SUB Fantasma

ld	a,(settings2)
bit	5,a			; Bit5 = 1 ??... entonces...
call	nz,fantasma2		; SUB Fantasma(2) Izda

ld	a,(settings2)
bit	2,a			; Si NZ, entonces...
call	nz,explo_fantasma	; ...SUB Explo-Fantasma

ld	a,(contador_it)
cp	$03			; Contador = $10 ??... entonces...
call	z,inicia_1ravez		; ...Inicia CaerGota

ld	a,(settings3)
bit	1,a			; Bit1 = 1 ??... entonces...
call	nz,caer_gota		; ...SUB Caer Gota

ld	a,(settings3)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,gota_impactasuelo	; SUB Gota impacta Suelo

ld	a,(settings3)
bit	2,a			; Bit2 = 1 ??... entonces...
call	nz,gota_techo		; SUB Gota sale del techo

ld	a,(settings4)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,indicador_key	; SUB IndicadorKey (volver a por la llave)
bit	1,a
call	nz,inventario_llave

ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jp	z,anterior_nivel
cp	$9c			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   9 )            ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_9:
ld	a,(contador_it)
cp	$90			; Contador = $0a ??... entonces...
call	z,inicia_fantasma2	; ...Inicia Fantasma(2) (Izda)
cp	$bc
call	z,inicia_fantasma

ld	a,(settings2)
bit	1,a			; Bit1 = 1 ??... entonces...
call	nz,fantasma		; ...SUB Fantasma

ld	a,(settings2)
bit	5,a			; Bit5 = 1 ??... entonces...
call	nz,fantasma2		; SUB Fantasma(2) Izda

ld	a,(settings2)
bit	2,a			; Si NZ, entonces...
call	nz,explo_fantasma	; ...SUB Explo-Fantasma

call	sub_bolasfuego

ld	a,(settings4)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,indicador_key	; SUB IndicadorKey (volver a por la llave)
bit	1,a
call	nz,inventario_llave

ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jp	z,anterior_nivel
cp	$9c			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;===========================================================================
;---                S U B -  B O L A S   D E   F U E G O                 ---
;---                                                                     ---
;---------------------------------------------------------------------------
sub_bolasfuego:
ld	de,bolas_fuego	; Situa Puntero DE en esa direccion

ld	a,(nivel)
cp	$09
call	z,tres_bolasfuego	; SUB Cargar B = $03
cp	$0b
call	z,cuatro_bolasfuego	; SUB Cargar B = $04
cp	$0c
call	z,cuatro_bolasfuego	; SUB Cargar B = $04

bucle_cuantasbolas:
ld	a,(de)	; Actualiza BolafuegoY (H)
ld	h,a

inc	de
ld	a,(de)	; Actualiza BolafuegoX (L)
ld	l,a

add	a,$20
ld	c,a

ld	a,(jugador_set)
bit	6,a
jr	nz,no_colision_bolafuego

;-----------------------------------------------------
ld	a,(jugador_x)
cp	c
call	z,posible_colision_vsbolafuego

ld	a,(jugador_x)
inc	a
cp	c
call	z,posible_colision_vsbolafuego

ld	a,(jugador_x)
inc	a
inc	a
cp	c
call	z,posible_colision_vsbolafuego

ld	a,(jugador_x)
dec	a
cp	c
call	z,posible_colision_vsbolafuego

;ld	a,(jugador_x)
;dec	a
;dec	a
;cp	c
;call	z,posible_colision_vsbolafuego

ld	a,(jugador_set)
bit	6,a
call	nz,restar_una_vida

jr	no_colision_bolafuego

;-----------------------------------------------------
no_colision_bolafuego:
inc	de
inc	de
ld	a,(de)
bit	0,a
jr	z,arriba_bolafuego
call	nz,abajo_bolafuego

sigue_z:
djnz	bucle_cuantasbolas
ret	; Retorna

;-----------------------------------------------------
arriba_bolafuego:
call	decrementar_scanline	; Incrementa UN Scan...
ld	a,l
dec	de
dec	de
ld	(de),a		; ...y actualiza GotaX

ld	a,h
dec	de
ld	(de),a		; ...y actualiza GotaY
cp	$48			; 3er Tercio??
call	z,fin_definitivo2	; SUB Posible Fin BolaFuego...

;-------------------------------------------------------
inc	de
inc	de

ld	a,(de)
inc	a
ld	(de),a

cp	$12
call	z,reinicia_ani_bf

push	de
cp	$09
call	c,anima_bolafuego3
call	nc,anima_bolafuego4

push	bc
ld	b,$10

bucle_dibuja_bolasfuego:
call	dibujados_repetitivos

dec	l
call	incrementar_scanline
inc	de
djnz	bucle_dibuja_bolasfuego

pop	bc
pop	de
inc	de
inc	de

call	incrementar_scanline
ld	(hl),$00
inc	l
ld	(hl),$00
dec	l
jr	sigue_z		; Retorna

;--------------------------------------------------------------------
abajo_bolafuego:
ld	(hl),$00	; Borra SOLO 1er Scanline... (autoborrado)
inc	l
ld	(hl),$00
dec	l

call	incrementar_scanline	; Incrementa UN Scan...
ld	a,l
dec	de
dec	de
ld	(de),a		; ...y actualiza GotaX

ld	a,h
dec	de
ld	(de),a		; ...y actualiza GotaY
cp	$50			; 3er Tercio??
call	z,fin_abajo	; SUB Posible Fin FlechaTrampa...

;-------------------------------------------------------

inc	de
inc 	de
ld	a,(de)
inc	a
ld	(de),a

cp	$12
call	z,reinicia_ani_bf

push	de
cp	$09
call	c,anima_bolafuego1
call	nc,anima_bolafuego2

push 	bc
ld	b,$10

bucle_dibuja_bolasfuego2:
call	dibujados_repetitivos

dec	l
call	incrementar_scanline
inc	de
djnz	bucle_dibuja_bolasfuego2

pop	bc
pop	de
inc	de
inc	de
ret	; Retorna

;------------------------------------------------------------------------
fin_abajo:
inc	de
ld	a,(de)
and	%11110000	; AND para detectar el 'c' o 'd' (Fin BolaFuego)
cp	$90		; $90??
call	z,fin_definitivo	; Z, entonces (Fin BolaFuego)

ld	a,(de)
and	%11110000
cp	$80
call	z,fin_definitivo
dec	de
ret	; Retorna

;--------------------------------------------
fin_definitivo:
inc	de
inc	de

ld	a,(de)
inc	a
ld	(de),a

dec	de
dec	de

ld	a,$03
call	sonido
ret		; Retorna

fin_definitivo2:
inc	de
inc	de
inc	de

ld	a,(de)
inc	a
ld	(de),a

dec	de
dec	de
dec	de

ld	a,$03
call	sonido
ret		; Retorna

;-------------------------------------------
anima_bolafuego1:
ld	de,bolasde_fuego+64
ret	; Retorna

anima_bolafuego2:
ld	de,bolasde_fuego+96
ret	; Retorna

anima_bolafuego3:
ld	de,bolasde_fuego
ret	; Retorna

anima_bolafuego4:
ld	de,bolasde_fuego+32
ret	; Retorna

reinicia_ani_bf:
xor	a
ld	(de),a
ret	; Retorna

tres_bolasfuego:
ld	b,$03
ret	; Retorna

cuatro_bolasfuego:
ld	b,$04
ret	; Retorna

;---------------------------------------------------------------------------
;--  S U B -  P O S I B L E   C O L I S I O N   vs   B O L A   F U E G O  --
;---------------------------------------------------------------------------
posible_colision_vsbolafuego:
ld	a,h
and	%11110000
ld	c,a

ld	a,(jugador_y)
and	%11110000
cp	c
ret	nz	; No Colision... entonces Retorna Inmediato 

ld	a,h
cp	$48
ret	c	; 1er Tercio = No colision... Retorna

ld	a,$03
call	sonido

xor	a
ld	(cont_explo_jug),a

ld	a,(settings3)
res	0,a
res	3,a
ld	(settings3),a

ld	a,(jugador_set)
set	6,a		; Vida Menos = ON
ld	(jugador_set),a
;jp	no_colision
ret	; Retorna
jr	$

ret		; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   10 )           ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_10:
ld	a,(contador_it)
cp	$09			; Contador = $0a ??... entonces...
call	z,inicia_fantasma2	; ...Inicia Fantasma(2) (Izda)
cp	$90
call	z,inicia_fantasma2
cp	$bc
call	z,inicia_fantasma

ld	a,(settings2)
bit	1,a			; Bit1 = 1 ??... entonces...
call	nz,fantasma		; ...SUB Fantasma

ld	a,(settings2)
bit	5,a			; Bit5 = 1 ??... entonces...
call	nz,fantasma2		; SUB Fantasma(2) Izda

ld	a,(settings2)
bit	2,a			; Si NZ, entonces...
call	nz,explo_fantasma	; ...SUB Explo-Fantasma

ld	a,(contador_it)
cp	$0f			; Contador = $10 ??... entonces...
call	z,inicia_1ravez		; ...Inicia CaerGota

ld	a,(contador_it)
cp	$02			; Contador = $0f ??... entonces...
call	z,inicia_1ravez2	; ...Inicia CaerGota(2) por 1ra Vez

ld	a,(settings3)
bit	1,a			; Bit1 = 1 ??... entonces...
call	nz,caer_gota		; ...SUB Caer Gota

ld	a,(settings3)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,gota_impactasuelo	; SUB Gota impacta Suelo

ld	a,(settings3)
bit	2,a			; Bit2 = 1 ??... entonces...
call	nz,gota_techo		; SUB Gota sale del techo

ld	a,(settings3)
bit	4,a			; Bit4 = 1 ?? ... entonces...
call	nz,gota_impactasuelo2	; ...SUB Gota Impacta-Suelo(2)

ld	a,(settings3)
bit	5,a			; Bit5 = 1 ?? ... entonces...
call	nz,caer_gota2		; ...SUB Caer Gota(2)

ld	a,(settings3)
bit	6,a			; Bit6 = 1 ??... entonces...
call	nz,gota_techo2		; ...SUB Gota sale del Techo(2)

ld	a,(settings4)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,indicador_key	; SUB IndicadorKey (volver a por la llave)
bit	1,a
call	nz,inventario_llave

ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jp	z,anterior_nivel
cp	$9c			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   11 )           ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_11:
ld	a,(contador_it)
cp	$03			; $03, entonces ...
call	z,inicia_flecha_arquerozero   ;...Inicia flechaArquero

ld	a,(settings)
bit	4,a			; NZ = SUB flechaArquero
call	nz,flecha_arquerozero

call	sub_bolasfuego

ld	a,(contador_it)
cp	$04
call	z,inicia_arana		; Z = Inicia Arana

ld	a,(settings4)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,indicador_key	; SUB IndicadorKey (volver a por la llave)
bit	1,a
call	nz,inventario_llave

ld	a,(settings4)
bit	3,a			; Bit3 = 1 ? ... entonces...
call	nz,cae_arana		; ...SUB Cae Arana

ld	a,(settings4)
bit	5,a			; Bit5 = 1 ? ...entonces...
call	nz,explo_arana		; ...SUB Explo-Arana

ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jp	z,anterior_nivel
cp	$9c			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;===========================================================================
;---                 S U B -  I N I C I A   A R A N A                    ---
;---------------------------------------------------------------------------
inicia_arana:
ld	a,(settings4)
bit	3,a		; Si NZ, entones...
ret	nz		; Retorna Inmediato (ya esta Iniciado)

set	3,a		; Bit1 = 1 ... Arana ON!
ld	(settings4),a

ld	h,$48
ld	a,h
ld	(arana_y),a	; Inicia AranaY (H)

ld	a,(nivel)
cp	$0b
jr	z,aranax_11	; ... y Retorna desde alli...
cp	$0c
jr	z,aranax_12	; ... y Retorna desde alli...
cp	$0d
jr	z,aranax_13	; ... y Retorna desde alli...
cp	$0e
jr	z,aranax_13	; ... y Retorna desde alli...
ret	; Retorna (No hace falta)

;------------------------------------------
aranax_11:
ld	a,$a6
ld	(arana_x),a	; Inicia GotaX (L)
ret	; Retorna desde aqui

aranax_12:
ld	a,$ae
ld	(arana_x),a	; Inicia GotaX (L)
ret	; Retorna desde aqui

aranax_13:
ld	a,$ba
ld	(arana_x),a	; Inicia GotaX (L)
ret	; Retorna desde aqui

;===========================================================================
;---                     S U B -  C A E   A R A N A                      ---
;---                                                                     ---
;---------------------------------------------------------------------------
cae_arana:
ld	a,(arana_y)	; Actualiza FlechaY (H)
ld	h,a
ld	a,(arana_x)	; Actualiza FlechaX (L)
ld	l,a

;add	a,$20
ld	c,a

ld	a,(jugador_set)
bit	6,a
jr	nz,no_colisionarana

;-----------------------------------------------------
ld	a,(jugador_set)
bit	4,a		; Si NO estamos atacando (espada), entonces...
jr	z,colisiones_vsarana	; ... continua normalmente... 
bit	0,a		; Si estamos 'mirando DCHA'... entonces...
jp	z,comprueba_ataquedcha	; ... Comprueba ataque DCHA...	
jp	nz,comprueba_ataqueizda	; ... Comprueba ataque IZDA...

;-----------------------------------------------------
colisiones_vsarana:
ld	a,(jugador_x)
cp	c
call	z,posible_colision_vsarana

ld	a,(jugador_x)
inc	a
cp	c
call	z,posible_colision_vsarana

ld	a,(jugador_x)
inc	a
inc	a
cp	c
call	z,posible_colision_vsarana

ld	a,(jugador_x)
dec	a
cp	c
call	z,posible_colision_vsarana

ld	a,(jugador_set)
bit	6,a
call	nz,restar_una_vida

jr	no_colisionarana

;-----------------------------------------------------
no_colisionarana:
ld	a,(cont_arana)
inc	a
ld	(cont_arana),a
cp	$08
call	c,anima_arana1
call	nc,anima_arana2
cp	$0f
call	z,reinicia_aniarana

;-----------------------------------------------------
ld	a,(settings4)
bit	4,a
jr	nz,arana_hacia_arriba

;-----------------------------------------------------
arana_hacia_abajo:
ld	(hl),$00	; Borra SOLO 1er Scanline... (autoborrado)
inc	l
ld	(hl),$10	; Siguiente Caracter (Dcha)
dec	l

call	incrementar_scanline	; Incrementa UN Scan...
ld	a,l
ld	(arana_x),a		; ...y actualiza AranaX
ld	a,h
ld	(arana_y),a		; ...y actualiza AranaY
cp	$50			; 3er Tercio??
call	z,fin_arana	; SUB Posible Fin Arana...

;------------------------------
ld	b,$08

bucle_dibuja_arana:
call	dibujados_repetitivos

dec	l
call	incrementar_scanline
inc	de
djnz	bucle_dibuja_arana
ret	; Retorna

;-----------------------------------------------------
arana_hacia_arriba:
call	decrementar_scanline	; Incrementa UN Scan...
ld	a,l
ld	(arana_x),a		; ...y actualiza AranaX
ld	a,h
ld	(arana_y),a		; ...y actualiza AranaY
cp	$48			; 3er Tercio??
call	z,fin_arana2	; SUB Posible Fin Arana...

;------------------------------
ld	b,$08

bucle_dibuja_arana2:
call	dibujados_repetitivos

dec	l
call	incrementar_scanline
inc	de
djnz	bucle_dibuja_arana2

ld	(hl),$00	; Borra SOLO 1er Scanline... (autoborrado)
inc	l
ld	(hl),$00	; Siguiente Caracter (Dcha)
dec	l
ret	; Retorna

;-------------------------------------------------------
fin_arana:
ld	a,(arana_x)
and	%11110000	; AND para detectar el '8' o '9' (Fin Arana)
cp	$90		; $90??
jr	z,ochenta_90arana	; Z, entonces (Fin Arana)
cp	$80
jr	z,ochenta_90arana
ret	; Retorna

ochenta_90arana:
ld	a,(settings4)
set	4,a		; Set Bit4 ... (Arana hacia Arriba)
ld	(settings4),a	; Actualiza

;ld	a,$00
;ld	(cont_arana),a
ret		; Retorna

;-------------------------------------------------------
fin_arana2:
ld	a,(arana_x)
and	%11110000	; AND para detectar el '8' o '9' (Fin Arana)
cp	$90		; $90??
jr	z,ochenta_90arana2	; Z, entonces (Fin Arana)
cp	$80
jr	z,ochenta_90arana2
ret	; Retorna

ochenta_90arana2:
ld	a,(settings4)
res	4,a		; Set Bit4 ... (Arana hacia Abajo)
ld	(settings4),a	; Actualiza

;ld	a,$00
;ld	(cont_arana),a
ret		; Retorna

;---------------------------------------------------------------------------
;---     JR - P O S I B L E   C O L I S I O N   vs   L A   A R A N A     ---
;---------------------------------------------------------------------------
posible_colision_vsarana:
ld	a,h
and	%11110000
ld	c,a

ld	a,(jugador_y)
and	%11110000
cp	c
ret	nz	; No Colision... entonces Retorna Inmediato 

ld	a,h
cp	$48
ret	c	; 1er Tercio = No colision... Retorna

ld	a,$03
call	sonido

xor	a
ld	(cont_explo_jug),a

;ld	a,(settings4)
;res	3,a
;ld	(settings4),a

ld	a,(jugador_set)
set	6,a		; Vida Menos = ON
ld	(jugador_set),a
;jp	no_colision
ret	; Retorna
jr	$

ret		; Retorna

;--------------------------------------------
anima_arana1:
ld	de,arana	; Situa DE en Arana
ret	; Retorna

;--------------------------------------------
anima_arana2:
ld	de,arana+16	; Situa DE en Arana
ret	; Retorna

;--------------------------------------------
reinicia_aniarana:
xor	a
ld	(cont_arana),a
ret	; Retorna

;---------------------------------------------------------------
comprueba_ataquedcha:
dec	c
dec	c
dec	c
ld	a,(jugador_x)
cp	c		; Si atacamos en la posicion de la arana, entonces...
call	z,inicia_exploarana	; ... Inicia Explo-arana ON

inc	c
inc	c
inc	c
;ld	a,(jugador_x)
;cp	c
;jp	z,no_colisionarana	
jp	colisiones_vsarana
jr	$

;---------------------------------------------------------------
comprueba_ataqueizda:
inc	c
ld	a,(jugador_x)
cp	c		; Si atacamos en la posicion de la arana, entonces...
call	z,inicia_exploarana	; ... Inicia Explo-arana ON

dec	c
;ld	a,(jugador_x)
;cp	c
;jp	z,no_colisionarana
jp	colisiones_vsarana
jr	$

;===========================================================================
;---           S U B -  I N I C I A   E X P L O - A R A N A              ---
;---------------------------------------------------------------------------
inicia_exploarana:
ld	a,h
cp	$50
ret	nz

ld	a,$04
call	sonido

ld	a,(jugador_set)
bit	6,a		; Bit6 = 1 ??... entonces...
call	nz,restar_una_vida	; SUB Restar una Vida

;-------- Murcielago o Arana ? ------
ld	a,(nivel)
or	a
call	z,toca_murcielago

ld	a,(nivel)
cp	$0b
call	z,toca_arana

xor	a
ld	(contador_explo),a
ret		; Retorna

;---------------------------------------------------
toca_arana:
ld	a,(settings4)
res	3,a		; Bit1 = 0 Arana OFF! 
set	5,a		; Bit2 = 1 Explo-Arana ON!
ld	(settings4),a

ld	a,(arana_y)
ld	(explo_fantasmay),a	; Coordenada Y inicial Explo-Arana***
ld	a,(arana_x)
ld	(explo_fantasmax),a	; Coordenada X inicial Explo-Arana***
ret	; Retorna

;---------------------------------------------------
toca_murcielago:
ld	a,(settings4)
set	5,a		; Bit2 = 1 Explo-Arana ON!
ld	(settings4),a

ld	a,(settings2)
res	0,a
ld	(settings2),a

ld	a,(murcielago_y)
ld	(explo_fantasmay),a	; Coordenada Y inicial Explo-Murcielago***
ld	a,(murcielago_x)
ld	(explo_fantasmax),a	; Coordenada X inicial Explo-Murcielago***
ret	; Retorna

;===========================================================================
;---                    S U B -  E X P L O - A R A N A                   ---
;---                                                                     ---
;---------------------------------------------------------------------------
explo_arana:
ld	a,(contador_explo)	; Contador Explo
inc	a
ld	(contador_explo),a
cp	$08			; Contador = $10 ?? ...
jr	z,fin_explo_arana	; ... Entonces, Fin Explo-Fantasma

ld	de,fantasma_explota+24
ld	b,a		; Carga en B, Bucle incrementos

bucle_incr_animaexplos_arana:
call	incrementa_de	; Incrementa DE (8 veces)
call	incrementa_de
call	incrementa_de

call	incrementa_de
call	incrementa_de
call	incrementa_de

call	incrementa_de
call	incrementa_de
call	incrementa_de
djnz	bucle_incr_animaexplos_arana

;-----------------------------------------
ld	a,(explo_fantasmay)
ld	h,a			; Actualiza H
ld	a,(explo_fantasmax)
ld	l,a			; Actualiza L

ld	b,$08		; Bucle $08

bucle_exploarana:
call	dibujados_repetitivos

ld	a,b
cp	$01
call	z,un_halt	; Ralentizaciones
cp	$05
call	z,un_halt
cp	$09
call	z,un_halt

dec	l
call	incrementar_scanline
inc	de
djnz	bucle_exploarana
ret		; Retorna

;-------------------------------------------
fin_explo_arana:
ld	a,(settings4)
res	5,a		; Bit5 = Z ... Fin Explo-Arana***
ld	(settings4),a

ld	a,(explo_fantasmay)
ld	h,a			; Actualiza H
ld	a,(explo_fantasmax)
ld	l,a			; Actualiza L
call	decrementar_scanline

ld	b,$08		; Bucle $08

bucle_borrado_exploarana:
ld	(hl),$00	; Borrado
inc	l
ld	(hl),$00

dec	l
call	incrementar_scanline
djnz	bucle_borrado_exploarana
ret	; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   12 )           ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_12:
ld	a,(contador_it)
cp	$03			; $03, entonces ...
call	z,inicia_flecha_arquerozero   ;...Inicia flechaArquero

ld	a,(settings)
bit	4,a			; NZ = SUB flechaArquero
call	nz,flecha_arquerozero

call	sub_bolasfuego

ld	a,(contador_it)
cp	$04
call	z,inicia_arana		; Z = Inicia Arana

ld	a,(settings4)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,indicador_key	; SUB IndicadorKey (volver a por la llave)
bit	1,a
call	nz,inventario_llave

ld	a,(settings4)
bit	3,a			; Bit3 = 1 ? ... entonces...
call	nz,cae_arana		; ...SUB Cae Arana

ld	a,(settings4)
bit	5,a			; Bit5 = 1 ? ...entonces...
call	nz,explo_arana		; ...SUB Explo-Arana

ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jp	z,anterior_nivel
cp	$9c			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   13 )           ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_13:
ld	a,(contador_it)
cp	$bc
call	z,inicia_fantasma

ld	a,(settings2)
bit	1,a			; Bit1 = 1 ??... entonces...
call	nz,fantasma		; ...SUB Fantasma

ld	a,(settings2)
bit	2,a			; Si NZ, entonces...
call	nz,explo_fantasma	; ...SUB Explo-Fantasma

ld	a,(contador_it)
cp	$0f			; Contador = $10 ??... entonces...
call	z,inicia_1ravez		; ...Inicia CaerGota

ld	a,(contador_it)
cp	$02			; Contador = $0f ??... entonces...
call	z,inicia_1ravez2	; ...Inicia CaerGota(2) por 1ra Vez

ld	a,(settings3)
bit	1,a			; Bit1 = 1 ??... entonces...
call	nz,caer_gota		; ...SUB Caer Gota

ld	a,(settings3)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,gota_impactasuelo	; SUB Gota impacta Suelo

ld	a,(settings3)
bit	2,a			; Bit2 = 1 ??... entonces...
call	nz,gota_techo		; SUB Gota sale del techo

ld	a,(settings3)
bit	4,a			; Bit4 = 1 ?? ... entonces...
call	nz,gota_impactasuelo2	; ...SUB Gota Impacta-Suelo(2)

ld	a,(settings3)
bit	5,a			; Bit5 = 1 ?? ... entonces...
call	nz,caer_gota2		; ...SUB Caer Gota(2)

ld	a,(settings3)
bit	6,a			; Bit6 = 1 ??... entonces...
call	nz,gota_techo2		; ...SUB Gota sale del Techo(2)

ld	a,(contador_it)
cp	$03			; $03, entonces ...
call	z,inicia_flecha_arquerozero   ;...Inicia flechaArquero

ld	a,(settings)
bit	4,a			; NZ = SUB flechaArquero
call	nz,flecha_arquerozero

ld	a,(contador_it)
cp	$04
call	z,inicia_arana		; Z = Inicia Arana

ld	a,(settings4)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,indicador_key	; SUB IndicadorKey (volver a por la llave)
bit	1,a
call	nz,inventario_llave

ld	a,(settings4)
bit	3,a			; Bit3 = 1 ? ... entonces...
call	nz,cae_arana		; ...SUB Cae Arana

ld	a,(settings4)
bit	5,a			; Bit5 = 1 ? ...entonces...
call	nz,explo_arana		; ...SUB Explo-Arana

ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jp	z,anterior_nivel
cp	$9c			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   14 )           ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_14:
ld	a,(contador_it)
cp	$f0
call	z,inicia_fantasma

ld	a,(settings2)
bit	1,a			; Bit1 = 1 ??... entonces...
call	nz,fantasma		; ...SUB Fantasma

ld	a,(settings2)
bit	2,a			; Si NZ, entonces...
call	nz,explo_fantasma	; ...SUB Explo-Fantasma

ld	a,(jugador_x)
cp	$89		; Si pisas en ladrillo $8d... 
call	z,inicia_flechatrampa1	; ...activa FlechaTrampa!

ld	a,(settings)
bit	3,a			; Si NZ, entonces...
call	nz,flecha_trampa1	; SUB FlechaTrampa...

ld	a,(settings2)
bit	3,a			; Si NZ, entonces...
call	nz,flecha_trampa1_rapida ; SUB flechaTrampaRapida...

ld	a,(contador_it)
cp	$fc			; Si Z, entonces...
call	z,borra_flechatrampa1	; Borra la Flecha-Trampa (del suelo)

ld	a,(settings2)
bit	4,a			; Si NZ, entonces...
call	nz,animacion_bloquetrampa  ; SUB Anima-BloqueTrampa

ld	a,(contador_it)
cp	$02			; Contador = $10 ??... entonces...
call	z,inicia_1ravez		; ...Inicia CaerGota

ld	a,(contador_it)
cp	$40			; Contador = $0f ??... entonces...
call	z,inicia_1ravez2	; ...Inicia CaerGota(2) por 1ra Vez

ld	a,(settings3)
bit	1,a			; Bit1 = 1 ??... entonces...
call	nz,caer_gota		; ...SUB Caer Gota

ld	a,(settings3)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,gota_impactasuelo	; SUB Gota impacta Suelo

ld	a,(settings3)
bit	2,a			; Bit2 = 1 ??... entonces...
call	nz,gota_techo		; SUB Gota sale del techo

ld	a,(settings3)
bit	4,a			; Bit4 = 1 ?? ... entonces...
call	nz,gota_impactasuelo2	; ...SUB Gota Impacta-Suelo(2)

ld	a,(settings3)
bit	5,a			; Bit5 = 1 ?? ... entonces...
call	nz,caer_gota2		; ...SUB Caer Gota(2)

ld	a,(settings3)
bit	6,a			; Bit6 = 1 ??... entonces...
call	nz,gota_techo2		; ...SUB Gota sale del Techo(2)

ld	a,(contador_it)
cp	$03			; $03, entonces ...
call	z,inicia_flecha_arquerozero   ;...Inicia flechaArquero

ld	a,(settings)
bit	4,a			; NZ = SUB flechaArquero
call	nz,flecha_arquerozero

ld	a,(contador_it)
cp	$04
call	z,inicia_arana		; Z = Inicia Arana

ld	a,(settings4)
bit	0,a			; Bit0 = 1 ??... entonces...
call	nz,indicador_key	; SUB IndicadorKey (volver a por la llave)
bit	1,a
call	nz,inventario_llave

ld	a,(settings4)
bit	3,a			; Bit3 = 1 ? ... entonces...
call	nz,cae_arana		; ...SUB Cae Arana

ld	a,(settings4)
bit	5,a			; Bit5 = 1 ? ...entonces...
call	nz,explo_arana		; ...SUB Explo-Arana

ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jp	z,anterior_nivel
cp	$9c			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;===========================================================================
;---         SUB - JUGABILIDAD / ACCIONES   ( N I V E L   15 )           ---
;---                                                                     ---     
;---------------------------------------------------------------------------
nivel_15:
ld	a,(jugador_x)
cp	$81			; CP tope Izquierdo = Anterior Nivel...
jp	z,anterior_nivel
cp	$9c			; JugadorX = $dd ?? ...
jp	z,siguiente_nivel	; Entonces 'Posible' Siguiente Nivel...
ret	; Retorna

;===========================================================================
;---    S U B -  S E L E C C I O N A R   P A N T A L L A   A  DIBUJAR    ---
;---                                                                     ---     
;---    (DEPENDIENDO del NIVEL)  ...  Dec A (Nivel) hasta encontrar Z    ---
;---------------------------------------------------------------------------
selecc_pantalla_dibujar:
ld	a,(nivel)
or	a
jp	z,pantalla_zero		; JR a dibujar Pantalla 0

dec	a
jp	z,pantalla_1		; JP a dibujar Pantalla 1

dec	a
jp	z,pantalla_2		; JP a dibujar Pantalla 2

dec	a
jp	z,pantalla_3		; JP a dibujar Pantalla 3

dec	a
jp	z,pantalla_4		; JP a dibujar Pantalla 4

dec	a
jp	z,pantalla_5		; JP a dibujar Pantalla 5

dec	a
jp	z,pantalla_6		; JP a dibujar Pantalla 6

dec	a
jp	z,pantalla_7		; JP a dibujar Pantalla 7

dec	a
jp	z,pantalla_8		; JP a dibujar Pantalla 8

dec	a
jp	z,pantalla_9		; JP a dibujar Pantalla 9

dec	a
jp	z,pantalla_10		; JP a dibujar Pantalla 10

dec	a
jp	z,pantalla_11		; JP a dibujar Pantalla 11

dec	a
jp	z,pantalla_12		; JP a dibujar Pantalla 12

dec	a
jp	z,pantalla_13		; JP a dibujar Pantalla 13

dec	a
jp	z,pantalla_14		; JP a dibujar Pantalla 14

ret	; Retorna (No hace falta)

;===========================================================================
;---      SUB - SELECCIONAR REDIBUJABLES (DEPENDIENDO del NIVEL)         ---
;---                                                                     ---
;---------------------------------------------------------------------------
selecc_redibujables:
ld	a,(nivel)
or	a
call	z,pantalla0_redibujable	; SUB Redibujables - Nivel 0
ret	z		; Retorna

dec	a
call	z,pantalla1_redibujable	; SUB Redibujables - Nivel 1
ret	z		; Retorna

dec	a
call	z,pantalla2_redibujable
ret	z

dec	a
call	z,pantalla3_redibujable
ret	z

dec	a
call	z,pantalla4_redibujable
ret	z

dec	a
call	z,pantalla5_redibujable
ret	z

dec	a
call	z,pantalla6_redibujable
ret	z

dec	a
call	z,pantalla7_redibujable
ret	z

dec	a
call	z,pantalla8_redibujable
ret	z

dec	a
;call	z,pantalla9_redibujable	; *** hay un fallo extra o? ***
;ret	z

dec	a
call	z,pantalla10_redibujable
ret	z

dec	a
call	z,pantalla11_redibujable
ret	z

dec	a
call	z,pantalla12_redibujable
ret	z

dec	a
call	z,pantalla13_redibujable
ret	z

dec	a
call	z,pantalla14_redibujable
ret	z

ret	; Retorna

;===========================================================================
;---                     SUB - P A N T A L L A   0                       ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;----------------------- Fachada exterior del Castillo ---------------------
pantalla_zero:
ld	de,bloques_ladrillos
ld	hl,$4818
ld	b,$3d

bucle_columnas:
push	bc
ld	b,$08

bucle_scanscastillo: 
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h

inc	de
djnz 	bucle_scanscastillo

ld	a,l
and	%00001111
cp	$0e
call	z,suma_2filas
cp	$0f
call	z,suma_2filas2

inc	l
inc	l
call	sub8_h

ld	de,bloques_ladrillos
pop	bc

ld	a,b
cp	$21
call	z,cambio_tercio_castillo
djnz	bucle_columnas

;-----------------------------------------
ld	de,bloques_ladrillos
ld	hl,$40d8
ld	b,$08

bucle_columnas2:
push	bc
ld	b,$08

bucle_scanscastillo2: 
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h

inc	de
djnz 	bucle_scanscastillo2

ld	a,l
and	%00001111
cp	$0e
call	z,suma_2filas
cp	$0f
call	z,suma_2filas2

inc	l
inc	l
call	sub8_h

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_columnas2

;----------------------------------------------
ld	de,bloques_ladrillos
ld	hl,$40f8

ld	b,$08

bucle_scansrectificado_01:
inc	de
ld	a,(de)
ld	(hl),a

inc	l
inc	de

inc	l
inc	de

dec	l
dec	l
inc	h
djnz	bucle_scansrectificado_01

;---------------------------------------
ld	hl,$40dc
ld	b,$10

bucle_hueco:
ld	(hl),$00
inc	l
ld	(hl),$00

dec	l
inc	h
ld	a,h
and	%00000111
jr	nz,nocambio_linea

ld	a,l
add	a,$20
ld	l,a
ld	h,$40

nocambio_linea:
djnz	bucle_hueco

;----------------------------------------------
ld	de,bloques_ladrillos
ld	hl,$4859

ld	b,$07

bucle_rectificado_fachada:
push	bc
ld	b,$08

bucle_scansrectificado_011:
inc	de
ld	a,(de)
ld	(hl),a

inc	l
inc	de

inc	l
inc	de

dec	l
dec	l
inc	h
djnz	bucle_scansrectificado_011

call	sub8_h

ld	a,l
add	a,$40
ld	l,a
call	c,cambio_tercio_castillo

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_rectificado_fachada

;--------------------------------------------
ld	hl,$4000
ld	b,$03

bucle_borrado_exterior:
push	bc
ld	b,$40

bucle_scansborradoext:
ld	(hl),$00

inc	h
ld	a,h
and	%00000111
jr	nz,nocambio_linea2

ld	a,l
add	a,$20
ld	l,a

call	sub8_h

nocambio_linea2:
djnz	bucle_scansborradoext

ld	a,h
add	a,$08
ld	h,a
	
pop	bc
djnz	bucle_borrado_exterior

;----------------------- Puente Levadizo Madera ------
ld	de,puente_madera
ld	hl,$50cf
ld	b,$05

bucle_puentemadera:
push	bc
ld	b,$08

bucle_scans_puentemadera:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h
inc	de
djnz	bucle_scans_puentemadera

call	sub8_h
inc	l
inc	l

ld	de,puente_madera
pop	bc
djnz	bucle_puentemadera

;------------------ Hierba exterior ----------------
ld	de,hierba
ld	hl,$50c0
ld	b,$10

bucle_sueloexterior:
push	bc
ld	b,$08

bucle_scans_sueloexterior:
call	dibujados_repetitivos

dec	l
inc	h
inc	de
djnz	bucle_scans_sueloexterior

call	sub8_h
inc	l
inc	l

ld	de,hierba
pop	bc

ld	a,b
cp	$09
call	z,otrafila_sueloext
ld	a,b
call	c,otra_hierba
djnz	bucle_sueloexterior
ret		;Retorna

;----------------------------------------------------------------
suma_2filas:
ld	a,l
add	a,$19
ld	l,a
ret	; Retorna
;jr	siguiente_fila

suma_2filas2:
ld	a,l
add	a,$19
ld	l,a
ret	; Retorna

;----------------------------------------------------------------
cambio_tercio_castillo:
ld	a,h
ld	a,$50
ld	h,a
ret	; Retorna

;----------------------------------------------------------------
otrafila_sueloext:
ld	a,l
add	a,$10
ld	l,a
ld	de,hierba+16
ret		; Retorna

otra_hierba:
ld	de,hierba+16
ret		; Retorna

;===========================================================================
;---     SUB - PANTALLA 0 (PARTES REFRESCABLES / REDIBUJABLES)           ---
;---                                                                     ---
;---------------------------------------------------------------------------
;---                                                                     ---
;----------------------------- Estrellas -----------------------------------
pantalla0_redibujable:
ld	de,estrellas
ld	b,$24

bucle_estrellas:
ld	a,(de)
ld	h,a

inc	de
ld	a,(de)
ld	l,a

inc	de
ld	a,(de)
ld	(hl),a

inc	de
djnz	bucle_estrellas

;------------------ Eslabones -----------------
ld	de,eslabon
ld	hl,$50b1
ld	b,$08

bucle_eslabones:
push	bc
ld	b,$08

bucle_scanseslabones:
ld	a,(de)
ld	(hl),a

inc	h
inc	de
djnz	bucle_scanseslabones

inc	l
ld	a,l
sub	$20
ld	l,a
call	nc,sub8_h
call	c,sub10_h

ld	de,eslabon
pop	bc
djnz	bucle_eslabones
ret		; Retorna

;===========================================================================
;---                     SUB - P A N T A L L A   1                       ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;------------------------ Dibuja Suelo -------------------------------------
pantalla_1:
ld	hl,$50c0		; Situa HL en 1ra posicion suelo
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$50de		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$50fe		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

;----------------------------------------- Ladrillo limite 1er Piso ---------
ld	de,bloques_ladrillos
ld	hl,$48ee
ld	b,$08		; Bucle Scanlines

bucle_scanladrillo_limite:
call	dibujados_repetitivos

inc	l
inc	de			; Incrementa bloque (DE) (vacio)

dec	l
dec	l			; Vuelve ...
inc	h			; Incrementa Scanline
	
inc	de			; Incrementa bloque (DE)
djnz 	bucle_scanladrillo_limite  ; Bucle Scanlines

;----------------------------- Dibuja Techo ---------------------------------
ld	de,bloques_ladrillos
ld	hl,$4040
ld	b,$10

bucle_techo1:
push	bc
ld	b,$08

bucle_scanstecho1:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h

inc	de
djnz	bucle_scanstecho1

inc	l
inc	l
call	sub8_h

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_techo1

;------------------------------------------------------
ld	de,bloques_ladrillos
ld	hl,$4063
ld	b,$04

bucle_arcos1:
push	bc
ld	b,$02

bucle_techo11:
push	bc
ld	b,$08

bucle_scanstecho11:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h

inc	de
djnz	bucle_scanstecho11

inc	l
inc	l
call	sub8_h

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_techo11

ld	a,l
add	a,$04
ld	l,a

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_arcos1

;------------------------------------------------------
ld	de,bloques_ladrillos
ld	hl,$4084
ld	b,$04

bucle_techo111:
push	bc
ld	b,$08

bucle_scanstecho111:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h

inc	de
djnz	bucle_scanstecho111

ld	a,l
add	a,$08
ld	l,a

call	sub8_h

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_techo111

;------------------ Dibuja Porta-antorchas ------------------
ld	hl,$40e8
ld	b,$03

bucle_cuantas_portantorchas1:
push	bc
ld	de,porta_antorcha
ld	b,$08

bucle_portantorchas1:
inc	l
inc	de

ld	a,(de)
ld	(hl),a

dec	l
inc	de

inc	h
inc	de
djnz	bucle_portantorchas1

call	sub8_h

ld	a,l
add	a,$07
ld	l,a
inc	l

pop	bc
djnz	bucle_cuantas_portantorchas1
ret	; Retorna

;--------------------------------------
trampa1:
inc	h
ld	(hl),%00101010	; Ladrillo Trampa (diferenciarlo)
inc	h
ld	(hl),%00010101	; Otro Scanline...
dec	h
dec	h
ret	; Retorna

;===========================================================================
;---     SUB - PANTALLA 1 (PARTES REFRESCABLES / REDIBUJABLES)           ---
;---                                                                     ---
;---------------------------------------------------------------------------
pantalla1_redibujable:
;----------------------- Dibuja plataforma 1er piso ------------------------
ld	de,bloques_ladrillos
ld	hl,$500e
ld	b,$09

bucle_primer_piso:
push	bc
ld	b,$08

bucle_scans_primerpiso:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h

inc	de
djnz	bucle_scans_primerpiso

call	sub8_h
ld	a,l
cp	$1a
call	z,trampa1

inc	l
inc	l

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_primer_piso

;-------------------------- Dibuja Puerta Interior -------------------------
ld	hl,$48b2
ld	de,puerta_interior
ld	b,$18

bucle_puertainterior:
ld	a,(de)
ld	(hl),a

inc	l
inc	de
ld	a,(de)
ld	(hl),a

inc	l
inc	de
ld	a,(de)
ld	(hl),a

dec	l
dec	l

call	incrementar_scanline
inc	de
djnz	bucle_puertainterior

;---------------------- Dibuja Antorchas -----------------------------------
ld	de,antorchas
ld	hl,$40a1
ld	b,$03

bucle_cuantas_antorchasdibujar1:
push	bc

ld	a,(anima_antorchas)
dec	a
call	z,reinicia_antorchas
ld	(anima_antorchas),a
cp	$0f
jr	c,anima_ant1
call	nc,anima_ant2

ani_antorchas_establecida:
ld	a,l
add	a,$07
ld	l,a
ld	b,$10

bucle_antorchas1:
call	dibujados_repetitivos

inc	l
inc	de
ld	a,(de)
ld	(hl),a

dec	l
dec	l
call	cambio_scanline_linea

inc	de
djnz	bucle_antorchas1

ld	a,l
sub	$40		; Vuelve a la 1ra fila
ld	l,a
inc	l

pop	bc
djnz	bucle_cuantas_antorchasdibujar1

call	attr_redibujables1

;------------------------- Dibuja Aparece-Puerta (ON/OFF) ------------------
ld	a,(settings)
bit	7,a
ret	z	; Retorna si Z

ld	hl,$5070
ld	de,puerta_interior
ld	b,$18

bucle_aparece_puertainterior:
ld	a,(de)
ld	(hl),a

inc	l
inc	de
ld	a,(de)
ld	(hl),a

inc	l
inc	de
ld	a,(de)
ld	(hl),a

dec	l
dec	l

call	incrementar_scanline
inc	de
djnz	bucle_aparece_puertainterior
ret		; Retorna

;------------------------------------------------
anima_ant1:
ld	de,antorchas
jr	ani_antorchas_establecida

anima_ant2:
ld	de,antorchas+48
ret

anima_ant11:
ld	de,antorchas
ret

reinicia_antorchas:
ld	a,$20
ret

;===========================================================================
;---                     SUB - P A N T A L L A   2                       ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;------------------------ Dibuja Suelo -------------------------------------
pantalla_2:
ld	hl,$50c0
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$50de		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$50fe		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

;----------------------- Dibuja Techo ----------------------------
ld	hl,$4820
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$483e		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$485e		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

call	dibuja_dos_portantorchas
ret	; Retorna

;---------------------------------------------------------------------------
;---        S U B -  PANTALLA 2   ( PARTES REDIBUJABLES )                ---
;--------------------------------------------------------------------------- 
pantalla2_redibujable:
ld	hl,$4880
ld	b,$02

call	dibuja_dos_antorchas

ld	hl,$48a5
ld	de,ventana
call	dibuja_unaventana

ld	hl,$48b2
ld	de,ventana
call	dibuja_unaventana	
ret	; Retorna

;===========================================================================
;---                     SUB - P A N T A L L A   3                       ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;------------------------ Dibuja Suelo -------------------------------------
pantalla_3:
ld	hl,$50c0
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$50de		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$50fe		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

;----------------------- Dibuja Techo ----------------------------
ld	hl,$4820
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$483e		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$485e		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

call	dibuja_dos_portantorchas
ret	; Retorna

;---------------------------------------------------------------------------
;---        S U B -  PANTALLA 3   ( PARTES REDIBUJABLES )                ---
;--------------------------------------------------------------------------- 
pantalla3_redibujable:
ld	hl,$4880
ld	b,$02

call	dibuja_dos_antorchas

;ld	hl,$48a5
;call	dibuja_unaventana

ld	hl,$48b2
ld	de,ventana
call	dibuja_unaventana	
ret	; Retorna

;================================================================
;---      SUB - Dibuja 2 Porta Antorchas ( Repetitivo )       ---
;----------------------------------------------------------------
dibuja_dos_portantorchas:
ld	hl,$48cc
ld	b,$02

bucle_dos_portantorchas2:
push	bc
ld	de,porta_antorcha
ld	b,$08

bucle_portantorchas2:
inc	l
inc	de

ld	a,(de)
ld	(hl),a

dec	l
inc	de

inc	h
inc	de
djnz	bucle_portantorchas2

call	sub8_h

ld	a,l
add	a,$0c
ld	l,a
inc	l

pop	bc
djnz	bucle_dos_portantorchas2
ret	; Retorna

;===========================================================================
;---                     SUB - P A N T A L L A   4                       ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;------------------------ Dibuja Suelo -------------------------------------
pantalla_4:
ld	hl,$50c0
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$50de		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$50fe		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

;----------------------- Dibuja Techo ----------------------------
ld	hl,$4820
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$483e		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$485e		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

call	dibuja_dos_portantorchas
ret	; Retorna

;---------------------------------------------------------------------------
;---        S U B -  PANTALLA 4   ( PARTES REDIBUJABLES )                ---
;--------------------------------------------------------------------------- 
pantalla4_redibujable:
ld	hl,$4880
ld	b,$02

call	dibuja_dos_antorchas

;ld	hl,$48a5
;call	dibuja_unaventana

ld	hl,$48b2
ld	de,ventana
call	dibuja_unaventana	
ret	; Retorna

;===========================================================================
;---                     SUB - P A N T A L L A   5                       ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;------------------------ Dibuja Suelo -------------------------------------
pantalla_5:
ld	hl,$50c0
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$50de		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$50fe		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

;----------------------- Dibuja Techo ----------------------------
ld	hl,$4820
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$483e		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$485e		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

;call	dibuja_dos_portantorchas
ret	; Retorna

;---------------------------------------------------------------------------
;---        S U B -  PANTALLA 5   ( PARTES REDIBUJABLES )                ---
;--------------------------------------------------------------------------- 
pantalla5_redibujable:
ld	hl,$4880
ld	b,$02

call	dibuja_dos_antorchas

;ld	hl,$48a5
;call	dibuja_unaventana

ld	hl,$48b2
ld	de,escudo
call	dibuja_unaventana
call	dibuja_dos_portantorchas	
ret	; Retorna

;===========================================================================
;---                     SUB - P A N T A L L A   6                       ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;------------------------ Dibuja Suelo -------------------------------------
pantalla_6:
ld	hl,$50c0
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$50de		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$50fe		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

;----------------------- Dibuja Techo ----------------------------
ld	hl,$4820
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$483e		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$485e		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

;call	dibuja_dos_portantorchas
ret	; Retorna

;---------------------------------------------------------------------------
;---        S U B -  PANTALLA 6   ( PARTES REDIBUJABLES )                ---
;--------------------------------------------------------------------------- 
pantalla6_redibujable:
ld	hl,$4880
ld	b,$02

call	dibuja_dos_antorchas

ld	hl,$48a5
ld	de,ventana
call	dibuja_unaventana

ld	hl,$48b2
ld	de,ventana
call	dibuja_unaventana
call	dibuja_dos_portantorchas	
ret	; Retorna

;===========================================================================
;---                     SUB - P A N T A L L A   7                       ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;------------------------ Dibuja Suelo -------------------------------------
pantalla_7:
ld	hl,$50c0		; Situa HL en 1ra posicion suelo
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$50de		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$50fe		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

;----------------------------------------- Ladrillo limite 1er Piso ---------
ld	de,bloques_ladrillos
ld	hl,$48ee
ld	b,$08		; Bucle Scanlines

bucle_scanladrillo_limite7:
call	dibujados_repetitivos

inc	l
inc	de			; Incrementa bloque (DE) (vacio)

dec	l
dec	l			; Vuelve ...
inc	h			; Incrementa Scanline
	
inc	de			; Incrementa bloque (DE)
djnz 	bucle_scanladrillo_limite7  ; Bucle Scanlines

;----------------------------- Dibuja Techo ---------------------------------
ld	de,bloques_ladrillos
ld	hl,$4040
ld	b,$10

bucle_techo7:
push	bc
ld	b,$08

bucle_scanstecho7:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h

inc	de
djnz	bucle_scanstecho7

inc	l
inc	l
call	sub8_h

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_techo7

;------------------------------------------------------
ld	de,bloques_ladrillos
ld	hl,$4063
ld	b,$04

bucle_arcos7:
push	bc
ld	b,$02

bucle_techo77:
push	bc
ld	b,$08

bucle_scanstecho77:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h

inc	de
djnz	bucle_scanstecho77

inc	l
inc	l
call	sub8_h

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_techo77

ld	a,l
add	a,$04
ld	l,a

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_arcos7

;------------------------------------------------------
ld	de,bloques_ladrillos
ld	hl,$4084
ld	b,$04

bucle_techo777:
push	bc
ld	b,$08

bucle_scanstecho777:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h

inc	de
djnz	bucle_scanstecho777

ld	a,l
add	a,$08
ld	l,a

call	sub8_h

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_techo777

;------------------ Dibuja Porta-antorchas ------------------
ld	hl,$40e8
ld	b,$03

bucle_cuantas_portantorchas7:
push	bc
ld	de,porta_antorcha
ld	b,$08

bucle_portantorchas7:
inc	l
inc	de

ld	a,(de)
ld	(hl),a

dec	l
inc	de

inc	h
inc	de
djnz	bucle_portantorchas7

call	sub8_h

ld	a,l
add	a,$07
ld	l,a
inc	l

pop	bc
djnz	bucle_cuantas_portantorchas7

ld	hl,$4822
ld	de,ventana
call	dibuja_unaventana

ld	hl,$480c
ld	de,escudo
call	dibuja_unaventana

ld	hl,$4814
ld	de,escudo
call	dibuja_unaventana
ret	; Retorna

;--------------------------------------
trampa7:
inc	h
ld	(hl),%00101010	; Ladrillo Trampa (diferenciarlo)
inc	h
ld	(hl),%00010101	; Otro Scanline...
dec	h
dec	h
ret	; Retorna

;===========================================================================
;---     SUB - PANTALLA 7 (PARTES REFRESCABLES / REDIBUJABLES)           ---
;---                                                                     ---
;---------------------------------------------------------------------------
pantalla7_redibujable:
;----------------------- Dibuja plataforma 1er piso ------------------------
ld	de,bloques_ladrillos
ld	hl,$500e
ld	b,$09

bucle_primer_piso7:
push	bc
ld	b,$08

bucle_scans_primerpiso7:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h

inc	de
djnz	bucle_scans_primerpiso7

call	sub8_h
;ld	a,l
;cp	$1a
;call	z,trampa7

inc	l
inc	l

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_primer_piso7

;-------------------------- Dibuja Puerta Interior -------------------------
ld	hl,$48b2
ld	de,puerta_interior
ld	b,$18

bucle_puertainterior7:
ld	a,(de)
ld	(hl),a

inc	l
inc	de
ld	a,(de)
ld	(hl),a

inc	l
inc	de
ld	a,(de)
ld	(hl),a

dec	l
dec	l

call	incrementar_scanline
inc	de
djnz	bucle_puertainterior7

;---------------------- Dibuja Antorchas -----------------------------------
ld	de,antorchas
ld	hl,$40a1
ld	b,$03

bucle_cuantas_antorchasdibujar7:
push	bc

ld	a,(anima_antorchas)
dec	a
call	z,reinicia_antorchas
ld	(anima_antorchas),a
cp	$0f
jr	c,anima_ant7
call	nc,anima_ant2

ani_antorchas_establecida7:
ld	a,l
add	a,$07
ld	l,a
ld	b,$10

bucle_antorchas7:
call	dibujados_repetitivos

inc	l
inc	de
ld	a,(de)
ld	(hl),a

dec	l
dec	l
call	cambio_scanline_linea

inc	de
djnz	bucle_antorchas7

ld	a,l
sub	$40		; Vuelve a la 1ra fila
ld	l,a
inc	l

pop	bc
djnz	bucle_cuantas_antorchasdibujar7

call	attr_redibujables7

;------------------------- Dibuja Aparece-Puerta (ON/OFF) ------------------
ld	a,(settings4)
bit	1,a
ret	z

ld	hl,$5070
ld	de,puerta_interior
ld	b,$18

bucle_aparece_puertainterior7:
ld	a,(de)
ld	(hl),a

inc	l
inc	de
ld	a,(de)
ld	(hl),a

inc	l
inc	de
ld	a,(de)
ld	(hl),a

dec	l
dec	l

call	incrementar_scanline
inc	de
djnz	bucle_aparece_puertainterior7
ret		; Retorna

;------------------------------------------------
anima_ant7:
ld	de,antorchas
jr	ani_antorchas_establecida7

;===========================================================================
;---                     SUB - P A N T A L L A   8                       ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;------------------------ Dibuja Suelo -------------------------------------
pantalla_8:
ld	hl,$50c0
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$50de		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$50fe		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

;----------------------- Dibuja Techo ----------------------------
ld	hl,$4820
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$483e		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$485e		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

;call	dibuja_dos_portantorchas
ret	; Retorna

;---------------------------------------------------------------------------
;---        S U B -  PANTALLA 8   ( PARTES REDIBUJABLES )                ---
;--------------------------------------------------------------------------- 
pantalla8_redibujable:
ld	hl,$4880
ld	b,$02

call	dibuja_dos_antorchas

ld	hl,$48a5
ld	de,ventana
call	dibuja_unaventana

ld	hl,$48b2
ld	de,ventana
call	dibuja_unaventana
call	dibuja_dos_portantorchas	
ret	; Retorna

;===========================================================================
;---                     SUB - P A N T A L L A   9                       ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;------------------------ Dibuja Suelo -------------------------------------
pantalla_9:
ld	hl,$50c0		; Situa HL en 1ra posicion suelo
call	dibuja_elsuelo

;-----------------------------------
ld	hl,$50ca
ld	de,puente_madera
ld	b,$07

call	dibuja_puente

;-----------------------------------
ld	hl,$50d8
ld	de,piedras
ld	b,$04

bucle_piedras:
push	bc
ld	a,b
cp	$04
jp	z,piedra_uno
cp	$03
jp	z,piedra_dos

ld	de,piedras+48
ld	b,$10

bucle_scans_piedras:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
call	incrementar_scanline
inc	de
djnz	bucle_scans_piedras

ld	h,$50
inc	l
inc	l
ld	a,l
add	a,$c0
ld	l,a

pop	bc
djnz	bucle_piedras

;----------------------------- Dibuja Techo ---------------------------------
ld	de,bloques_ladrillos
ld	hl,$4040
ld	b,$10

bucle_techo9:
push	bc
ld	b,$08

bucle_scanstecho9:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h

inc	de
djnz	bucle_scanstecho9

inc	l
inc	l
call	sub8_h

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_techo9

;------------------------------------------------------
ld	de,bloques_ladrillos
ld	hl,$4063
ld	b,$04

bucle_arcos9:
push	bc
ld	b,$02

bucle_techo99:
push	bc
ld	b,$08

bucle_scanstecho99:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h

inc	de
djnz	bucle_scanstecho99

inc	l
inc	l
call	sub8_h

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_techo99

ld	a,l
add	a,$04
ld	l,a

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_arcos9

;------------------------------------------------------
ld	de,bloques_ladrillos
ld	hl,$4084
ld	b,$04

bucle_techo999:
push	bc
ld	b,$08

bucle_scanstecho999:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
inc	h

inc	de
djnz	bucle_scanstecho999

ld	a,l
add	a,$08
ld	l,a

call	sub8_h

ld	de,bloques_ladrillos
pop	bc
djnz	bucle_techo999
ret	; Retorna

;-----------------------------------------------
piedra_uno:
ld	de,piedras
ld	b,$10
jp	bucle_scans_piedras

piedra_dos:
ld	de,piedras+96
ld	b,$10
jp	bucle_scans_piedras

;===========================================================================
;---     SUB - PANTALLA 9 (PARTES REFRESCABLES / REDIBUJABLES)           ---
;---                                                                     ---
;---------------------------------------------------------------------------
pantalla9_redibujable:
ld	hl,$48a5
ld	de,ventana
call	dibuja_unaventana
ret	; Retorna

;===========================================================================
;---                S U B -  D I B U J A   P U E N T E                   ---
;---------------------------------------------------------------------------
dibuja_puente:
bucle_vacios:
push	bc
ld	b,$10

bucle_scans_vacios:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l

call	incrementar_scanline
inc	de
djnz	bucle_scans_vacios

ld	h,$50
inc	l
inc	l
ld	a,l
add	a,$c0
ld	l,a

ld	de,puente_madera
pop	bc
djnz	bucle_vacios
ret	; Retorna

;===========================================================================
;---                     SUB - P A N T A L L A   10                      ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;------------------------ Dibuja Suelo -------------------------------------
pantalla_10:
ld	a,(settings4)
res	2,a
ld	(settings4),a
ld	hl,$50c0
call	dibuja_suelopiedras

;----------------------- Dibuja Techo ----------------------------
ld	a,(settings4)
set	2,a
ld	(settings4),a
ld	hl,$4800
call	dibuja_suelopiedras

;call	dibuja_dos_portantorchas
ret	; Retorna

;===========================================================================
;---        S U B -  PANTALLA 10   ( PARTES REDIBUJABLES )               ---
;--------------------------------------------------------------------------- 
pantalla10_redibujable:
ld	hl,$4880
ld	b,$02

call	dibuja_dos_antorchas
call	dibuja_dos_portantorchas	
ret	; Retorna

;===========================================================================
;---                     SUB - P A N T A L L A   11                      ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;------------------------ Dibuja Suelo -------------------------------------
pantalla_11:
ld	a,(settings4)
res	2,a
ld	(settings4),a
ld	hl,$50c0
call	dibuja_suelopiedras

;----------------------- Dibuja Techo ----------------------------
ld	a,(settings4)
set	2,a
ld	(settings4),a
ld	hl,$4800
call	dibuja_suelopiedras

ld	hl,$4848
;ld	de,piedras
call	piedra_tipouno

ld	b,$10

bucle_scans_unapiedra:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
call	incrementar_scanline
inc	de
djnz	bucle_scans_unapiedra

;---------------------- Dibuja Tela Arana -------------------------
ld	hl,$4846
ld	de,tela_arana
;call	piedra_tipouno

ld	b,$10

bucle_scans_telarana:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
call	incrementar_scanline
inc	de
djnz	bucle_scans_telarana

;----------------------- Dibuja Puente Madera --------------------
ld	hl,$50ca
ld	de,puente_madera
ld	b,$0b

call	dibuja_puente
ret	; Retorna

;===========================================================================
;---        S U B -  PANTALLA 11   ( PARTES REDIBUJABLES )               ---
;--------------------------------------------------------------------------- 
pantalla11_redibujable:
ld	hl,$4887
ld	b,$08

bucle_scans_hilo:
ld	(hl),$10

call	incrementar_scanline
djnz	bucle_scans_hilo
ret	; Retorna

;===========================================================================
;---                     SUB - P A N T A L L A   12                      ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;------------------------ Dibuja Suelo -------------------------------------
pantalla_12:
;----------------------- Dibuja Techo ----------------------------
ld	a,(settings4)
set	2,a
ld	(settings4),a

ld	hl,$4800
call	dibuja_suelopiedras

ld	hl,$4840
call	dibuja_suelopiedras

;---------------------- Dibuja Tela Arana -------------------------
ld	hl,$484e
ld	de,tela_arana

ld	b,$10

bucle_scans_telarana12:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
call	incrementar_scanline
inc	de
djnz	bucle_scans_telarana12

;----------------------- Dibuja Puente Madera --------------------
ld	hl,$50c0
ld	de,puente_madera
ld	b,$10

call	dibuja_puente
ret	; Retorna

;===========================================================================
;---        S U B -  PANTALLA 12   ( PARTES REDIBUJABLES )               ---
;--------------------------------------------------------------------------- 
pantalla12_redibujable:
ld	hl,$488f
ld	b,$08

bucle_scans_hilo12:
ld	(hl),$10

call	incrementar_scanline
djnz	bucle_scans_hilo12
ret	; Retorna

;===========================================================================
;---                     SUB - P A N T A L L A   13                      ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;------------------------ Dibuja Suelo -------------------------------------
pantalla_13:
;----------------------- Dibuja Techo ----------------------------
ld	a,(settings4)
set	2,a
ld	(settings4),a

ld	hl,$4800
call	dibuja_suelopiedras

ld	hl,$4840
call	dibuja_suelopiedras

;---------------------- Dibuja Tela Arana -------------------------
ld	hl,$485a
ld	de,tela_arana

ld	b,$10

bucle_scans_telarana13:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
call	incrementar_scanline
inc	de
djnz	bucle_scans_telarana13

;----------------------- Dibuja Suelo Ladrillos -----------------
ld	hl,$50c0		; Situa HL en 1ra posicion suelo
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$50de		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$50fe		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

;----------------------- Dibuja Puente Madera --------------------
ld	hl,$50c0
ld	de,puente_madera
ld	b,$0a

call	dibuja_puente
ret	; Retorna

;===========================================================================
;---        S U B -  PANTALLA 13   ( PARTES REDIBUJABLES )               ---
;--------------------------------------------------------------------------- 
pantalla13_redibujable:
ld	hl,$489b
ld	b,$08

bucle_scans_hilo13:
ld	(hl),$10

call	incrementar_scanline
djnz	bucle_scans_hilo13
ret	; Retorna

;===========================================================================
;---                     SUB - P A N T A L L A   14                      ---
;---                                                                     ---
;---   DE --> Puntero bloques	     ...    HL --> Puntero VRAM          ---
;---                                                                     ---     
;---------------------------------------------------------------------------
;---                                                                     ---
;------------------------ Dibuja Suelo -------------------------------------
pantalla_14:
ld	hl,$50c0
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$50de		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$50fe		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

;----------------------- Dibuja Techo ----------------------------
ld	hl,$4820
call	dibuja_elsuelo

ld	hl,$4040
call	dibuja_elsuelo
ld	hl,$4080
call	dibuja_elsuelo
ld	hl,$40c0
call	dibuja_elsuelo

ld	de,bloques_ladrillos
ld	hl,$483e		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$485e		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

ld	de,bloques_ladrillos
ld	hl,$405e		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$407e		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

ld	de,bloques_ladrillos
ld	hl,$409e		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$40be		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

ld	de,bloques_ladrillos
ld	hl,$40de		; Ultimo ladrillo 1ra fila suelo
ld	b,$08
call 	bucle_rectifica1

ld	de,bloques_ladrillos
ld	hl,$40fe		; Ultimo ladrillo 2da fila suelo
ld	b,$08
call	bucle_rectifica2

ld	hl,$4089
ld	de,ventana
call	dibuja_unaventana

ld	hl,$4096
ld	de,ventana
call	dibuja_unaventana

;call	dibuja_dos_portantorchas
ret	; Retorna

;---------------------------------------------------------------------------
;---        S U B -  PANTALLA 14   ( PARTES REDIBUJABLES )                ---
;--------------------------------------------------------------------------- 
pantalla14_redibujable:
ld	hl,$4880
ld	b,$02

call	dibuja_dos_antorchas

ld	hl,$48a5
ld	de,escudo
call	dibuja_unaventana

ld	hl,$48b2
ld	de,escudo
call	dibuja_unaventana
call	dibuja_dos_portantorchas	
ret	; Retorna

;============================================================================
;---        S U B -  D I B U J A   S U E L O   P I E D R A S              ---
;----------------------------------------------------------------------------
dibuja_suelopiedras:
ld	de,piedras
ld	b,$10

bucle_piedras2:
push	bc
ld	a,b
bit	0,b
call	z,piedra_tipouno
call	nz,piedra_tipodos

ld	b,$10

bucle_scans_piedras2:
call	dibujados_repetitivos

inc	l
inc	de

dec	l
dec	l
call	incrementar_scanline
inc	de
djnz	bucle_scans_piedras2

ld	a,(settings4)
bit	2,a
call	z,h_cincuenta
call	nz,h_cuarentayocho

inc	l
inc	l
ld	a,l
add	a,$c0
ld	l,a

pop	bc
djnz	bucle_piedras2
ret	; Retorna

;-----------------------------------------------
piedra_tipouno:
ld	de,piedras+48
ret	; Retorna

piedra_tipodos:
ld	de,piedras+96
ret	; Retorna

;-----------------------------------------------
h_cincuenta:
ld	h,$50
ret	; Retorna

h_cuarentayocho:
ld	h,$48
ret	; Retorna

;===========================================================================
;---     S U B -  D I B U J A   S U E L O   (ES MUY REPETITIVO)          ---
;---                                                                     ---
;---       ( Nivel 1 ---> $50c0, Rectificados: $50de, $50fe )            ---
;---------------------------------------------------------------------------
dibuja_elsuelo:
ld	de,bloques_ladrillos	; Situa DE en puntero bloques
;ld	hl,$50c0		; Situa HL en 1ra posicion suelo
ld	b,$20			; Bucle 2 filas de suelo entrelazado

bucle_suelo:
push	bc
ld	b,$08			; Bucle Scanlines

bucle_scansuelo:
call	dibujados_repetitivos

inc	l
inc	de			; Incrementa bloque (DE) (vacio)

dec	l
dec	l			; Vuelve ...
inc	h			; Incrementa Scanline
	
inc	de			; Incrementa bloque (DE)
djnz 	bucle_scansuelo	; Bucle Scanlines

call	sub8_h
ld	a,(nivel)
cp	$01
jr	nz,notrampa_niveluno

ld	a,l
cp	$ca
call	z,trampa1

notrampa_niveluno:
inc	l
inc	l		; Vuelve...

ld	de,bloques_ladrillos	; Reinicia DE (Bloque)
pop	bc

ld	a,b
cp	$11			; 2da fila suelo?...
jr	nz,entrelazado		; ...entonces entrelazar

dec	l			; Decrementa para ENTRELAZAR

entrelazado:
djnz	bucle_suelo	; Bucle suelo
ret	; Retorna

;---------------------------------------------------------------------------
bucle_rectifica1:
ld	a,(de)		
;ld	(hl),a		; No dibujar (parte izda del ladrillo)

inc	l
inc	de
ld	a,(de)
ld	(hl),a		; Dibujar SOLO parte dcha del ladrillo

inc	l
inc	de

dec	l
dec	l
inc	h
inc	de
djnz	bucle_rectifica1
ret			; Retorna

;---------------------------------------------------------------------------
bucle_rectifica2:
;ld	a,(de)
;ld	(hl),a

inc	l
;inc	de
ld	a,(de)		; Dibujar parte Dcha del ladrillo, PERO dibujando en
ld	(hl),a		; ... esa parte Dcha la parte Izquierda del ladrillo

inc	l
inc	de
inc	de

dec	l
dec	l
inc	h
inc	de
djnz	bucle_rectifica2
ret	; Retorna

;===========================================================================
;-   S U B -  D I B U J A   DOS   A N T O R C H A S  (ES MUY REPETITIVO)   -
;---                                                                     ---
;---------------------------------------------------------------------------
dibuja_dos_antorchas:
;---------------------- Dibuja Antorchas -----------------------------------
ld	de,antorchas

bucle_dos_antorchasdibujar1:
push	bc

ld	a,(anima_antorchas)
dec	a
call	z,reinicia_antorchas
ld	(anima_antorchas),a
cp	$0f
call	c,anima_ant11
call	nc,anima_ant2

;ani_antorchas_establecida:
ld	a,l
add	a,$0c
ld	l,a
ld	b,$10

bucle_dosantorchas1:
call	dibujados_repetitivos

inc	l
inc	de
ld	a,(de)
ld	(hl),a

dec	l
dec	l
call	cambio_scanline_linea

inc	de
djnz	bucle_dosantorchas1

ld	a,l
sub	$40		; Vuelve a la 1ra fila
ld	l,a
inc	l

pop	bc
djnz	bucle_dos_antorchasdibujar1
ret		; Retorna

;===========================================================================
;---   S U B -  D I B U J A   UNA   V E N T A N A (ES MUY REPETITIVO)    ---
;---                                                                     ---
;---------------------------------------------------------------------------
dibuja_unaventana:
;ld	de,ventana
ld	b,$18

bucle_dibujaventana:
call	dibujados_repetitivos

inc	l
inc	de
ld	a,(de)
ld	(hl),a

dec	l
dec	l
call	incrementar_scanline

inc	de
djnz	bucle_dibujaventana
ret		; Retorna

;=================================================================
;-- SUB - SELECCIONAR ATTR REDIBUJABLES (Dependiendo del Nivel) --
;-----------------------------------------------------------------
selecc_attr_redibujables:
ld	a,(nivel)
or	a
jp	z,attr_redibujables_0

dec	a
jp	z,attr_redibujables1

dec	a
jp	z,attr_redibujables2

dec	a
jp	z,attr_redibujables3

dec	a
jp	z,attr_redibujables4

dec	a
jp	z,attr_redibujables5

dec	a
jp	z,attr_redibujables6

dec	a
jp	z,attr_redibujables7

dec	a
jp	z,attr_redibujables8

dec	a
jp	z,attr_redibujables9

dec	a
jp	z,attr_redibujables10

dec	a
jp	z,attr_redibujables11

dec	a
jp	z,attr_redibujables11	; Nivel 12 en Realidad

dec	a
jp	z,attr_redibujables13

dec	a
jp	z,attr_redibujables14

ret	; Retorna (No hace falta)

;=================================================================
;---      SUB - ATTR redibujables PANTALLA 1                   ---
;---                                                           --- 
;--------------------- Attr 1er Piso -----------------------------
attr_redibujables1:
ld	hl,$5a0e
ld	a,$06
ld	b,$12

bucle_attr_primerpiso:
ld	(hl),a
inc	hl
djnz	bucle_attr_primerpiso

ld	hl,$59ee
ld	(hl),$06
inc	l
ld	(hl),$06

ld	hl,$59b2
call	attr_redibuj_puertasinterior
ld	hl,$5a90
call	attr_redibuj_puertasinterior

;--------------- Attr Antorchas ----------------------------------
ld	hl,$58a1	; Situa HL para attr antorchas
ld	b,$03		; Bucle $03 antorchas

bucle_cuantas_antorchas1:
push	bc
ld	a,l
add	a,$07		; $07 separacion entre antorchas
ld	l,a

ld	b,$02		; Bucle $02 filas antorcha

bucle_attr_antorchas1:
ld	(hl),%01000010		; Atributos (rojo)

inc	l
ld	a,b
cp	$01
jr	z,paper_rojo_amarillo

ld	(hl),%01000010		; Atributos (rojo)

sigue1:
inc	l
ld	(hl),%01000010		; Atributos (rojo)

dec	l
dec	l

ld	a,l
add	a,$20		; Incrementa una fila
ld	l,a
djnz	bucle_attr_antorchas1

ld	a,l
sub	$40		; Vuelve a la 1ra fila
ld	l,a
inc	l

pop	bc
djnz	bucle_cuantas_antorchas1
ret		; Retorna

;-------------------------------------------------------------
segunda_escalera:
inc	l
inc	l	; Situa para los attr de la 2da escalera
inc	l
ret		; Retorna

;-------------------------------------------------------------
paper_rojo_amarillo:
ld	(hl),%01010110	; Atributos (fondo rojo-amarillo)
jr	sigue1

ret	; Retorna

;-----------------------------------------------------------------
attr_redibuj_puertasinterior:
ld	b,$18

bucle_attr_puertainterior:
ld	(hl),$06
inc	l
ld	(hl),$06
inc	l
ld	(hl),$06

ld	a,l
add	a,$1e
ld	l,a
djnz	bucle_attr_puertainterior
ret	; Retorna

;=================================================================
;---             ATTR redibujables PANTALLA 0                  ---
;---                                                           --- 
;----------------------- Attr Estrellas --------------------------
attr_redibujables_0:
;ld	de,estrellas
;ld	b,$24

;bucle_attr_estrellas:
;ld	a,(de)
;call	cambioh_58595a
;ld	h,a
;ld	a,(de)
;ld	l,a
;ld	(hl),$07
;inc	de
;inc	de
;djnz	bucle_attr_estrellas
;-------------------- Attr Eslabones ---------------------------
ld	hl,$5ab1
ld	b,$08

bucle_attr_eslabones:
ld	(hl),$45

inc	l
ld	a,l
sub	$20
ld	l,a
call	c,cincuentay_nueve

djnz	bucle_attr_eslabones
ret		; Retorna

;---------------------------------
cincuentay_nueve:
ld	a,$59
ld	h,a
ret	; Retorna

;=================================================================
;---             ATTR redibujables PANTALLA 2                  ---
;---                                                           --- 
;-----------------------------------------------------------------
attr_redibujables2:
ld	hl,$59b2
call	attr_redibuj_ventana
ld	hl,$59a5
call	attr_redibuj_ventana
ret	; Retorna

;-----------------------------------------------------------------
attr_redibuj_ventana:
ld	b,$03

bucle_attr_ventana:
ld	(hl),$06
inc	l
ld	(hl),$06
inc	l
ld	(hl),$06

ld	a,l
add	a,$1e
ld	l,a
djnz	bucle_attr_ventana
ret	; Retorna

ret	; Retorna

;=================================================================
;---             ATTR redibujables PANTALLA 3                  ---
;---                                                           --- 
;-----------------------------------------------------------------
attr_redibujables3:
ld	hl,$59b2
call	attr_redibuj_ventana
;ld	hl,$59a5
;call	attr_redibuj_ventana
ret	; Retorna

;=================================================================
;---             ATTR redibujables PANTALLA 4                  ---
;---                                                           --- 
;-----------------------------------------------------------------
attr_redibujables4:
ld	hl,$59b2
call	attr_redibuj_ventana

;----------------------------
ld	hl,$5ab1
ld	(hl),$44
dec	l

ld	b,$0b

bucle_attr_gota:
ld	(hl),$44

ld	a,l
sub	$20
ld	l,a
call	c,cincuentay_nueve
djnz	bucle_attr_gota
ret	; Retorna

;=================================================================
;---             ATTR redibujables PANTALLA 5                  ---
;---                                                           --- 
;-----------------------------------------------------------------
attr_redibujables5:
ld	hl,$59b2
call	attr_redibuj_escudo
ld	hl,$59b3
call	attr_cruzescudo

;----- Aqui tienen su propia SUB-ATTR las gotas ------
ld	hl,$5aab
ld	(hl),$44
dec	l

ld	b,$0b

bucle_attr_gota_5:
ld	(hl),$44

ld	a,l
add	a,$0c
ld	l,a
ld	(hl),$43
ld	a,l
sub	$0c
ld	l,a

ld	a,l
sub	$20
ld	l,a
call	c,cincuentay_nueve
djnz	bucle_attr_gota_5

call	sub_attr_dosantorchas
ret	; Retorna

;-----------------------------------------------------------------
attr_redibuj_escudo:
ld	b,$03

bucle_attr_escudo:
ld	(hl),$42
inc	l
ld	(hl),$42
inc	l
ld	(hl),$42

ld	a,l
add	a,$1e
ld	l,a
djnz	bucle_attr_escudo
ret	; Retorna

;------------------------
attr_cruzescudo:
ld	b,$02

bucle_attr_cruzescudo:
ld	(hl),%01100010
ld	a,l
add	a,$20
ld	l,a
djnz	bucle_attr_cruzescudo
ret	; Retorna

;=================================================================
;---             ATTR redibujables PANTALLA 6                  ---
;---                                                           --- 
;-----------------------------------------------------------------
attr_redibujables6:
ld	hl,$59b2
call	attr_redibuj_ventana
ld	hl,$59a5
call	attr_redibuj_ventana
call	sub_attr_dosantorchas
ld	hl,$5ab7
call	sub_attr_gota2
ret	; Retorna

;=================================================================
;---              SUB - Attr GOTAS ( Repetitivo )              ---
;-----------------------------------------------------------------
sub_attr_gota:
ld	(hl),$44
dec	l

ld	b,$0b

bucle_attr_gota_x:
ld	(hl),$44

ld	a,l
sub	$20
ld	l,a
call	c,cincuentay_nueve
djnz	bucle_attr_gota_x
ret	; Retorna

;-----------------------------------------------------------------
sub_attr_gota2:
ld	(hl),$43
dec	l

ld	b,$0b

bucle_attr_gota2_x:
ld	(hl),$43

ld	a,l
sub	$20
ld	l,a
call	c,cincuentay_nueve
djnz	bucle_attr_gota2_x
ret	; Retorna

;=================================================================
;---        SUB - Attr DOS Antorchas ( Repetitivo )            ---
;-----------------------------------------------------------------
sub_attr_dosantorchas:
ld	hl,$5980	; Situa HL para attr antorchas
ld	b,$02		; Bucle $02 antorchas

bucle_cuantas_antorchas2:
push	bc
ld	a,l
add	a,$0c		; $07 separacion entre antorchas
ld	l,a

ld	b,$02		; Bucle $02 filas antorcha

bucle_attr_antorchas2:
ld	(hl),%01000010		; Atributos (rojo)

inc	l
ld	a,b
cp	$01
jr	z,paper_rojo_amarillo2

ld	(hl),%01000010		; Atributos (rojo)

sigue2:
inc	l
ld	(hl),%01000010		; Atributos (rojo)

dec	l
dec	l

ld	a,l
add	a,$20		; Incrementa una fila
ld	l,a
djnz	bucle_attr_antorchas2

ld	a,l
sub	$40		; Vuelve a la 1ra fila
ld	l,a
inc	l

pop	bc
djnz	bucle_cuantas_antorchas2
ret		; Retorna

;-------------------------------------------------------------
paper_rojo_amarillo2:
ld	(hl),%01010110	; Atributos (fondo rojo-amarillo)
jr	sigue2

;=================================================================
;---      SUB - ATTR redibujables PANTALLA 7                   ---
;---                                                           --- 
;--------------------- Attr 1er Piso -----------------------------
attr_redibujables7:
ld	hl,$5a0e
ld	a,$06
ld	b,$12

bucle_attr_primerpiso7:
ld	(hl),a
inc	hl
djnz	bucle_attr_primerpiso7

ld	hl,$59ee
ld	(hl),$06
inc	l
ld	(hl),$06

ld	hl,$59b2
call	attr_redibuj_puertasinterior
ld	hl,$5a90
call	attr_redibuj_puertasinterior

ld	hl,$5922
call	attr_redibuj_ventana

ld	hl,$590c
call	attr_redibuj_escudo
ld	hl,$590d
call	attr_cruzescudo
ld	hl,$5914
call	attr_redibuj_escudo
ld	hl,$5915
call	attr_cruzescudo

ld	hl,$5aae
call	sub_attr_gota

;--------------- Attr Antorchas ----------------------------------
ld	hl,$58a1	; Situa HL para attr antorchas
ld	b,$03		; Bucle $03 antorchas

bucle_cuantas_antorchas7:
push	bc
ld	a,l
add	a,$07		; $07 separacion entre antorchas
ld	l,a

ld	b,$02		; Bucle $02 filas antorcha

bucle_attr_antorchas7:
ld	(hl),%01000010		; Atributos (rojo)

inc	l
ld	a,b
cp	$01
jr	z,paper_rojo_amarillo7

ld	(hl),%01000010		; Atributos (rojo)

sigue7:
inc	l
ld	(hl),%01000010		; Atributos (rojo)

dec	l
dec	l

ld	a,l
add	a,$20		; Incrementa una fila
ld	l,a
djnz	bucle_attr_antorchas7

ld	a,l
sub	$40		; Vuelve a la 1ra fila
ld	l,a
inc	l

pop	bc
djnz	bucle_cuantas_antorchas7
ret		; Retorna

;-------------------------------------------------------------
paper_rojo_amarillo7:
ld	(hl),%01010110	; Atributos (fondo rojo-amarillo)
jr	sigue7

ret	; Retorna

;=================================================================
;---             ATTR redibujables PANTALLA 8                  ---
;---                                                           --- 
;-----------------------------------------------------------------
attr_redibujables8:
ld	hl,$59b2
call	attr_redibuj_ventana
ld	hl,$59a5
call	attr_redibuj_ventana
call	sub_attr_dosantorchas
ld	hl,$5ab1
call	sub_attr_gota
ret	; Retorna

;=================================================================
;---             ATTR redibujables PANTALLA 9                  ---
;---                                                           --- 
;-----------------------------------------------------------------
attr_redibujables9:
ld	hl,$59a5
call	attr_redibuj_ventana

;-----------------------------
ld	hl,$59ec
ld	(hl),$42
inc	l
ld	(hl),$42

ld	a,l
add	a,$04
ld	l,a
ld	(hl),$42
inc	l
ld	(hl),$42

add	a,$05
ld	l,a
ld	(hl),$42
inc	l
ld	(hl),$42

;----------------------------
ld	hl,$5a0c
ld	b,$06

bucle_attr_bolasfuego:
ld	(hl),$42
inc	l
ld	(hl),$42

ld	a,l
add	a,$04
ld	l,a
ld	(hl),$42
inc	l
ld	(hl),$42

add	a,$05
ld	l,a
ld	(hl),$42
inc	l
ld	(hl),$42

add	a,$16
ld	l,a
djnz	bucle_attr_bolasfuego

;-----------------------------
ld	hl,$5aca
ld	b,$0e
ld	a,$02

bucle_attr_puente:
ld	(hl),a
inc	l
djnz	bucle_attr_puente
ret	; Retorna

;=================================================================
;---             ATTR redibujables PANTALLA 10                 ---
;---                                                           --- 
;-----------------------------------------------------------------
attr_redibujables10:
call	sub_attr_dosantorchas
ld	hl,$5aab
call	sub_attr_gota
ld	hl,$5ab8
call	sub_attr_gota2
ld	hl,$594a
ld	(hl),$44
ld	hl,$5957
ld	(hl),$43
ret	; Retorna

;=================================================================
;---             ATTR redibujables PANTALLA 11                 ---
;---                                                           --- 
;-----------------------------------------------------------------
attr_redibujables11:
ld	hl,$59ec
ld	(hl),$42
inc	l
ld	(hl),$42

ld	a,l
add	a,$04
ld	l,a
ld	(hl),$42
inc	l
ld	(hl),$42

add	a,$05
ld	l,a
ld	(hl),$42
inc	l
ld	(hl),$42

add	a,$05
ld	l,a
ld	(hl),$42
inc	l
ld	(hl),$42

;----------------------------
call	sub_attr_cuatrobolasfuego

ld	hl,$5987
ld	(hl),$47
ret	; Retorna

;=================================================================
;---             ATTR redibujables PANTALLA 13                 ---
;---                                                           --- 
;-----------------------------------------------------------------
attr_redibujables13:
ld	hl,$5aab
call	sub_attr_gota_masabajo
ld	hl,$5ab8
call	sub_attr_gota2_masabajo
;ld	hl,$594a
;ld	(hl),$44
;ld	hl,$5957
;ld	(hl),$43
ret	; Retorna

;=================================================================
;---             ATTR redibujables PANTALLA 14                 ---
;---                                                           --- 
;-----------------------------------------------------------------
attr_redibujables14:
ld	hl,$59a5
call	attr_redibuj_escudo
ld	hl,$59a6
call	attr_cruzescudo
ld	hl,$59b2
call	attr_redibuj_escudo
ld	hl,$59b3
call	attr_cruzescudo

ld	hl,$5aab
call	sub_attr_gota
ld	hl,$5ab9
call	sub_attr_gota2

;--------------- Attr Techo (1er Tercio) -------------------------
ld	hl,$5840
ld	b,$c0

bucle_attrtecho1414:
call	ladrillo_normal
inc	hl
djnz	bucle_attrtecho1414

call	sub_attr_dosantorchas
ret	; Retorna

;=================================================================
;---   SUB - Attr GOTAS (Empiezan mas abajo) ( Repetitivo )    ---
;-----------------------------------------------------------------
sub_attr_gota_masabajo:
ld	(hl),$44
dec	l

ld	b,$0a

bucle_attr_gota_xmasabajo:
ld	(hl),$44

ld	a,l
sub	$20
ld	l,a
call	c,cincuentay_nueve
djnz	bucle_attr_gota_xmasabajo
ret	; Retorna

;-----------------------------------------------------------------
sub_attr_gota2_masabajo:
ld	(hl),$43
dec	l

ld	b,$0a

bucle_attr_gota2_xmasabajo:
ld	(hl),$43

ld	a,l
sub	$20
ld	l,a
call	c,cincuentay_nueve
djnz	bucle_attr_gota2_xmasabajo
ret	; Retorna

;===========================================================================
;---      S U B - A T T R   C U A T R O   B O L A S   F U E G O          ---
;---------------------------------------------------------------------------
sub_attr_cuatrobolasfuego:
ld	hl,$5a0c
ld	b,$06

bucle_attr_bolasfuego11:
ld	(hl),$42
inc	l
ld	(hl),$42

ld	a,l
add	a,$04
ld	l,a
ld	(hl),$42
inc	l
ld	(hl),$42

add	a,$05
ld	l,a
ld	(hl),$42
inc	l
ld	(hl),$42

add	a,$05
ld	l,a
ld	(hl),$42
inc	l
ld	(hl),$42

add	a,$11
ld	l,a
djnz	bucle_attr_bolasfuego11
ret	; Retorna

;===========================================================================
;---       S U B - CAMBIAR H a $58,59 o 5a ... ( para ATTR )             ---
;---------------------------------------------------------------------------
cambioh_58595a:
or	a
cp	$50
jr	z,cincuenta_y_a
cp	$48
jr	z,cincuenta_y_9
cp	$40
jr	z,cincuenta_y_8
jr	$

cincuenta_y_8:
ld	a,$58
ret

cincuenta_y_9:
ld	a,$59
ret

cincuenta_y_a:
ld	a,$5a
ret

;===========================================================================
;---              SUB - CAMBIO DE SCANLINE / LINEA                       ---
;---------------------------------------------------------------------------
cambio_scanline_linea:
ld	a,h
and	%00000111
cp	$07			; Cambio de Linea??
jr	z,cambio_descanline

inc	h			; No, entonces solo inc H
ret

cambio_descanline:
ld	a,h
xor	%00000111		; Poner H = 010T T...(000)
ld	h,a

ld	a,l
add	a,$20			; Cambio de Linea
ld	l,a
ret

;----------------------------------------------------------------
cambia_de_hl:
;ld	de,escalera	; Reinicia Sprite escalera (DE)
inc	l
inc	l		; Incrementa para colocar 2da parte de la escalera
inc	l
ret		; Retorna

;===========================================================================
;---      S U B -  I N C R E M E N T A R   SCANLINE / LINEA / TERCIO     ---
;---                                                                     ---
;---------------------------------------------------------------------------
incrementar_scanline:
inc	h
ld	a,h
and	%00000111	; 8tavo scanline? ...
ret	nz		; ... No, entonces retorna inmediato

incrementar_solofila:
ld	a,l		
add	a,$20		; Si 8tavo Scanline, entonces Suma una fila...
ld	l,a
ret	c		; Si hay Carry, retorna inmediato (hecho)

ld	a,h
sub	$08		; Ademas de sumar fila, Restaura el Tercio actual
ld	h,a
ret		; Retorna

;===========================================================================
;---     S U B -  D E C R E M E N T A R   SCANLINE / LINEA / TERCIO      ---
;---                                                                     ---
;---------------------------------------------------------------------------
decrementar_scanline:
ld	a,h
dec	h
and	%00000111	; Estabamos en el Scanline Zero?? ...
ret	nz		; NZ, entonces retorna inmediato... (Ya esta)

ld	a,l
sub	$20		; Entonces restar UNA Fila
ld	l,a
ret	c		; Si hay Carry, retorna Inmediato (hecho)

ld	a,h
add	a,$08		; Ademas de restar Fila... restaura el Tercio actual
ld	h,a
ret		; Retorna

;===========================================================================
;---              S U B  -  R E S T A R   U N A   V I D A                ---
;---------------------------------------------------------------------------
restar_una_vida:
ld	a,(vidas)
dec	a
ld	(vidas),a

call	marcadores
ret	; Retorna

;===========================================================================
;---                   S U B  -  M A R C A D O R E S                     ---
;---------------------------------------------------------------------------
marcadores:
push	hl
ld	hl,$4700
ld	(hl),$ff

ld	hl,$4500
ld	a,(vidas)
ld	(hl),a
pop	hl
ret	; Retorna

;===========================================================================
;---         S U B - D I B U J A D O S   R E P E T I T I V O S           ---
;---------------------------------------------------------------------------
dibujados_repetitivos:
ld	a,(de)			
ld	(hl),a			; Dibuja bloque correspondiente (DE)

inc	l
inc	de
ld	a,(de)
ld	(hl),a			; Incrementa bloque (DE)
ret

;===========================================================================
;---      S U B - D I B U J A D O S   R E P E T I T I V O S   I I        ---
;---------------------------------------------------------------------------
dibujados_repetitivos2:
inc	l
inc	de			; ...Siguiente Byte DCHA
ld	a,(de)
ld	(hl),a

inc	l
inc	de
ld	a,(de)
ld	(hl),a			; ...Siguiente Byte DCHA
ret

;---------------------------------------------------------------------------
sub8_h:
ld	a,h
sub	$08
ld	h,a		; Vuelve al 1er Scanline
ret		; Retorna

sub10_h:
ld	a,h
sub	$10
ld	h,a
ret

;===========================================================================
;---    S U B - D I B U J A D O S   R E P E T I T I V O S  *** OR ***    ---
;---------------------------------------------------------------------------
dibujados_repetitivos_or:
ld	a,(hl)
ld	c,a
ld	a,(de)		
or	c	
ld	(hl),a			; Dibuja bloque correspondiente (DE)

inc	l
inc	de
ld	a,(hl)
ld	c,a
ld	a,(de)
or	c
ld	(hl),a			; Incrementa bloque (DE)
ret		; Retorna

;===========================================================================
;--- S U B - D I B U J A D O S   R E P E T I T I V O S   II  *** OR ***  ---
;---------------------------------------------------------------------------
dibujados_repetitivos2_or:
inc	l
inc	de			; ...Siguiente Byte DCHA
ld	a,(hl)
ld	c,a
ld	a,(de)
or	c
ld	(hl),a

inc	l
inc	de
ld	a,(hl)
ld	c,a
ld	a,(de)
or	c
ld	(hl),a			; ...Siguiente Byte DCHA
ret

;===========================================================================
;---        SUB - C O N T A D O R E S   I T E R A C I O N E S            ---
;---------------------------------------------------------------------------
contadores:
ld	a,(contador_it)
inc	a
ld	(contador_it),a
ret

;===========================================================================
;---                     SUB - R A L E N T I Z A                         ---
;---------------------------------------------------------------------------
ralentiza:
dec	a
ret	z

halt			; Ralentiza tantas veces como iteraciones de bucle
jr	nz,ralentiza
ret		; No hace falta

;===========================================================================
;---               S U B -  R E S E T - S E T T I N G S                  ---
;---------------------------------------------------------------------------
reset_settings:
ld	a,(settings_ch)
xor	a
set	0,a
ld	(settings_ch),a

ld	a,(settings)
xor	a
ld	(settings),a

ld	a,(settings2)
xor	a
ld	(settings2),a

ld	a,(settings3)
xor	a
ld	(settings3),a

ld	a,(settings4)
res	2,a
res	3,a
res	4,a
res	5,a
ld	(settings4),a
ret	; Retorna

;===========================================================================
;---                   JP -  G A M E   O V E R                           ---
;---------------------------------------------------------------------------
game_over:
ld	b,$07		;Carga en B, Coord Y (Imprimir caracteres)
ld	c,$17		;Carga en C, Coord X      "         "
call	LOCATE		;Rutina del sistema para posicionar el cursor
ld	hl,msg_game_over	;Va cargando en HL, los caracteres del mensaje

bucle_msg_gameover:
inc	hl		;... Jugador CPU
ld	a,(hl)
or	a
jr	z,$
rst	$10		;Imprime chr$(A) (en locate B,C)
jr	bucle_msg_gameover
jr	$

;===========================================================================
;---                 S U B -  S E L E C C I O N A R  ...                 ---
;---                                                                     ---
;---            ... ATTR GENERALES (Dependiendo del Nivel)               ---
;---------------------------------------------------------------------------
selecc_attr_generales:
ld	a,(nivel)
or	a
jr	z,sub_attr_0	; JR a ATTR Generales - Nivel 0

dec	a
jp	z,sub_attr	; JR a ATTR Generales - Nivel 1

dec	a
jp	z,sub_attr2	; JR a ATTR Generales - Nivel 2

dec	a
jp	z,sub_attr3	; JR a ATTR Generales - Nivel 3

dec	a
jp	z,sub_attr4	; JR a ATTR Generales - Nivel 4

dec	a
jp	z,sub_attr5	; JR a ATTR Generales - Nivel 5

dec	a
jp	z,sub_attr6	; JR a ATTR Generales - Nivel 6

dec	a
jp	z,sub_attr	; JR a ATTR Generales - Nivel 7

dec	a
jp	z,sub_attr8	; JR a ATTR Generales - Nivel 8

dec	a
jp	z,sub_attr	; JR a ATTR Generales - Nivel 9

dec	a
jp	z,sub_attr10	; JR a ATTR Generales - Nivel 10

dec	a
jp	z,sub_attr11	; JR a ATTR Generales - Nivel 11

dec	a
jp	z,sub_attr12	; JR a ATTR Generales - Nivel 12

dec	a
jp	z,sub_attr13	; JR a ATTR Generales - Nivel 13

dec	a
jp	z,sub_attr14	; JR a ATTR Generales - Nivel 14

ret	; Retorna

;===========================================================================
;---  SUB - A T T R   G E N E R A L  ( MARCADORES, todas las pantallas ) ---
;---------------------------------------------------------------------------
sub_attr_marcadores:
ld	hl,$5800
ld	b,$40

bucle_attr_marcadores:
ld	(hl),$05
inc	l
djnz	bucle_attr_marcadores
ret	; Retorna

;===========================================================================
;---          SUB - A T T R   G E N E R A L  ( PANTALLA 0 )              ---
;---                                                                     ---
;---------------------------------------------------------------------------
sub_attr_0:
call	sub_attr_marcadores

ld	hl,$5898
ld	b,$14

bucle_attr_castillo_y:
push	bc
ld	b,$08

bucle_attr_castillo:
ld	(hl),$06
inc	l
djnz	bucle_attr_castillo

ld	a,l
add	a,$18
ld	l,a
cp	$18
call	z,subir_tercio_attr

pop	bc
djnz	bucle_attr_castillo_y

;------------------ Attr Suelo hierba --------------------
ld	hl,$5ac0	; Situa HL para attr del suelo
ld	b,$10		; bucle 2 filas de suelo

bucle_attr_hierba:
ld	(hl),$04		; Attr suelo (amarillo)
inc	l
djnz	bucle_attr_hierba

ld	hl,$5ae0
ld	a,%00011100
ld	b,$10

bucle_attr_hierba2:
ld	(hl),a
inc	l
djnz	bucle_attr_hierba2

;------------------- Attr Puente Madera ------------------
ld	hl,$5ad0
ld	a,$02
ld	b,$09

bucle_attr_puentemadera1:
ld	(hl),a
inc	l
djnz	bucle_attr_puentemadera1

ld	hl,$5af0
ld	a,$02
ld	b,$09

bucle_attr_puentemadera2:
ld	(hl),a
inc	l
djnz	bucle_attr_puentemadera2
ret	; Retorna

;===========================================================================
;---          SUB - A T T R   G E N E R A L  ( PANTALLA 1 )              ---
;---                                                                     ---
;---------------------------------------------------------------------------
sub_attr:
call	sub_attr_marcadores

ld	hl,$5ac0	; Situa HL para attr del suelo
ld	b,$3f		; bucle 2 filas de suelo

bucle_attrsuelo:
ld	a,l
cp	$ca
call	z,ladrillo_diferente
call	nz,ladrillo_normal

inc	hl
djnz	bucle_attrsuelo

;-------------------- Attr Techo ---------------------------------
ld	hl,$5840	; Situa HL para attr del suelo
ld	a,$06		; attr del Techo (amarillo)
ld	b,$60		; bucle 3 filas de Techo

bucle_attrtecho:
ld	(hl),a		; Attr suelo (amarillo)
inc	hl
djnz	bucle_attrtecho

ld	hl,$59f0
ld	(hl),$05
inc	l
ld	(hl),$05
ret	; Retorna

;-------------------------------------------------------------
ladrillo_normal:
ld	(hl),$06		; Attr suelo (amarillo)
ret

ladrillo_diferente:
ld	(hl),$46		; Attr difetente (Trampa)
inc	hl
ld	(hl),$46
ret

;===========================================================================
;---          SUB - A T T R   G E N E R A L  ( PANTALLA 2 )              ---
;---                                                                     ---
;---------------------------------------------------------------------------
sub_attr2:
call	sub_attr_marcadores

ld	hl,$5ac0	; Situa HL para attr del suelo
ld	b,$3f		; bucle 2 filas de suelo

bucle_attrsuelo2:
ld	a,l
cp	$ca
call	z,ladrillo_diferente
call	nz,ladrillo_normal

inc	hl
djnz	bucle_attrsuelo2

;--------------- Attr Techo --------------------------------------
ld	hl,$5920
ld	b,$40

bucle_attrtecho2:
call	ladrillo_normal
inc	hl
djnz	bucle_attrtecho2

call	sub_attr_dosantorchas
ret	; Retorna

;===========================================================================
;---          SUB - A T T R   G E N E R A L  ( PANTALLA 3 )              ---
;---                                                                     ---
;---------------------------------------------------------------------------
sub_attr3:
call	sub_attr_marcadores

ld	hl,$5ac0	; Situa HL para attr del suelo
ld	b,$40		; bucle 2 filas de suelo

bucle_attrsuelo3:
call	ladrillo_normal
inc	hl
djnz	bucle_attrsuelo3

;--------------- Attr Techo --------------------------------------
ld	hl,$5920
ld	b,$40

bucle_attrtecho3:
call	ladrillo_normal
inc	hl
djnz	bucle_attrtecho3

call	sub_attr_dosantorchas
ret	; Retorna

;===========================================================================
;---          SUB - A T T R   G E N E R A L  ( PANTALLA 4 )              ---
;---                                                                     ---
;---------------------------------------------------------------------------
sub_attr4:
call	sub_attr_marcadores

ld	hl,$5ac0	; Situa HL para attr del suelo
ld	b,$40		; bucle 2 filas de suelo

bucle_attrsuelo4:
call	ladrillo_normal
inc	hl
djnz	bucle_attrsuelo3

;--------------- Attr Techo --------------------------------------
ld	hl,$5920
ld	b,$40

bucle_attrtecho4:
call	ladrillo_normal
inc	hl
djnz	bucle_attrtecho3

call	sub_attr_dosantorchas
ret	; Retorna

;===========================================================================
;---          SUB - A T T R   G E N E R A L  ( PANTALLA 5 )              ---
;---                                                                     ---
;---------------------------------------------------------------------------
sub_attr5:
call	sub_attr_marcadores

ld	hl,$5ac0	; Situa HL para attr del suelo
ld	b,$40		; bucle 2 filas de suelo

bucle_attrsuelo5:
call	ladrillo_normal
inc	hl
djnz	bucle_attrsuelo5

;--------------- Attr Techo --------------------------------------
ld	hl,$5920
ld	b,$40

bucle_attrtecho5:
call	ladrillo_normal
inc	hl
djnz	bucle_attrtecho5

call	sub_attr_dosantorchas
ret	; Retorna

;===========================================================================
;---          SUB - A T T R   G E N E R A L  ( PANTALLA 6 )              ---
;---                                                                     ---
;---------------------------------------------------------------------------
sub_attr6:
call	sub_attr_marcadores

ld	hl,$5ac0	; Situa HL para attr del suelo
ld	b,$40		; bucle 2 filas de suelo

bucle_attrsuelo6:
call	ladrillo_normal
inc	hl
djnz	bucle_attrsuelo6

;--------------- Attr Techo --------------------------------------
ld	hl,$5920
ld	b,$40

bucle_attrtecho6:
call	ladrillo_normal
inc	hl
djnz	bucle_attrtecho6

call	sub_attr_dosantorchas
ret	; Retorna

;===========================================================================
;---          SUB - A T T R   G E N E R A L  ( PANTALLA 8 )              ---
;---                                                                     ---
;---------------------------------------------------------------------------
sub_attr8:
call	sub_attr_marcadores

ld	hl,$5ac0	; Situa HL para attr del suelo
ld	b,$40		; bucle 2 filas de suelo

bucle_attrsuelo8:
call	ladrillo_normal
inc	hl
djnz	bucle_attrsuelo8

;--------------- Attr Techo --------------------------------------
ld	hl,$5920
ld	b,$40

bucle_attrtecho8:
call	ladrillo_normal
inc	hl
djnz	bucle_attrtecho8

call	sub_attr_dosantorchas
ret	; Retorna

;===========================================================================
;---          SUB - A T T R   G E N E R A L  ( PANTALLA 10 )             ---
;---                                                                     ---
;---------------------------------------------------------------------------
sub_attr10:
call	sub_attr_marcadores

ld	hl,$5ac0	; Situa HL para attr del suelo
ld	b,$40		; bucle 2 filas de suelo

bucle_attrsuelo10:
call	ladrillo_normal
inc	hl
djnz	bucle_attrsuelo10

;--------------- Attr Techo --------------------------------------
ld	hl,$5900
ld	b,$40

bucle_attrtecho10:
call	ladrillo_normal
inc	hl
djnz	bucle_attrtecho10

call	sub_attr_dosantorchas
ret	; Retorna

;===========================================================================
;---          SUB - A T T R   G E N E R A L  ( PANTALLA 11 )             ---
;---                                                                     ---
;---------------------------------------------------------------------------
sub_attr11:
call	sub_attr_marcadores

ld	hl,$5ac0	; Situa HL para attr del suelo
ld	b,$3f		; bucle 2 filas de suelo

bucle_attrsuelo11:
call	ladrillo_normal	; ATTR Color amarillo $06

inc	hl
djnz	bucle_attrsuelo11

ld	hl,$5948
ld	(hl),$06
inc	l
ld	(hl),$06

ld	a,l
add	a,$1f
ld	l,a
ld	(hl),$06
inc	l
ld	(hl),$06

;-----------------------------------------------------
ld	hl,$5aca	; Situa HL para attr del suelo
ld	b,$16		; bucle 2 filas de suelo

bucle_attrpuente11:
ld	(hl),$02

inc	hl
djnz	bucle_attrpuente11

;-----------------------------------------------------
ld	hl,$5900	; Situa HL para attr del suelo
ld	b,$40		; bucle 2 filas de Techo

bucle_attrtecho11:
call	ladrillo_normal	; ATTR Color amarillo $06

inc	hl
djnz	bucle_attrtecho11

ret	; Retorna

;===========================================================================
;---          SUB - A T T R   G E N E R A L  ( PANTALLA 12 )             ---
;---                                                                     ---
;---------------------------------------------------------------------------
sub_attr12:
call	sub_attr_marcadores

ld	hl,$5ac0	; Situa HL para attr del Puente
ld	b,$20		; bucle 2 filas de Puente

bucle_attrpuente12:
ld	(hl),$02

inc	hl
djnz	bucle_attrpuente12

;-----------------------------------------------------
ld	hl,$5900	; Situa HL para attr del suelo
ld	b,$80		; bucle 2 filas de Techo

bucle_attrtecho12:
call	ladrillo_normal	; ATTR Color amarillo $06

inc	hl
djnz	bucle_attrtecho12

;-----------------------------------------------------
ld	hl,$594e
ld	(hl),$47
inc	l
ld	(hl),$47

ld	a,l
add	a,$1f
ld	l,a
ld	(hl),$47
inc	l
ld	(hl),$47
ret	; Retorna

;===========================================================================
;---          SUB - A T T R   G E N E R A L  ( PANTALLA 13 )             ---
;---                                                                     ---
;---------------------------------------------------------------------------
sub_attr13:
call	sub_attr_marcadores

ld	hl,$5ac0	; Situa HL para attr del Puente
ld	b,$20		; bucle 2 filas de Puente

bucle_attrpuente13:
ld	(hl),$02

inc	hl
djnz	bucle_attrpuente13

;-----------------------------------------------------
ld	hl,$5900	; Situa HL para attr del Techo
ld	b,$80		; bucle 2 filas de Techo

bucle_attrtecho13:
call	ladrillo_normal	; ATTR Color amarillo $06

inc	hl
djnz	bucle_attrtecho13

;-----------------------------------------------------
ld	hl,$5ad4	; Situa HL para attr del suelo
ld	b,$0c		; bucle 2 filas de suelo

bucle_attrsuelo13:
call	ladrillo_normal

ld	a,l
add	a,$20
ld	l,a
call	ladrillo_normal

sub	$20
ld	l,a

inc	l
djnz	bucle_attrsuelo13

;-----------------------------------------------------
ld	hl,$595a
ld	(hl),$47
inc	l
ld	(hl),$47

ld	a,l
add	a,$1f
ld	l,a
ld	(hl),$47
inc	l
ld	(hl),$47
ret	; Retorna

;===========================================================================
;---          SUB - A T T R   G E N E R A L  ( PANTALLA 14 )             ---
;---                                                                     ---
;---------------------------------------------------------------------------
sub_attr14:
call	sub_attr_marcadores

ld	hl,$5ac0	; Situa HL para attr del suelo
ld	b,$40		; bucle 2 filas de suelo

bucle_attrsuelo14:
call	ladrillo_normal
inc	hl
djnz	bucle_attrsuelo14

;--------------- Attr Techo --------------------------------------
ld	hl,$5920
ld	b,$40

bucle_attrtecho14:
call	ladrillo_normal
inc	hl
djnz	bucle_attrtecho14
ret	; Retorna

;===========================================================================
;---                   S U B - SUBIR TERCIO (ATTR)                       ---
;---------------------------------------------------------------------------
subir_tercio_attr:
inc	h
ret	; Retorna

;===========================================================================
;---                    S U B - C L S  ATRIBUTOS                         ---
;---------------------------------------------------------------------------
sub_clsattr: 
ld	a,%01000111	; Carga en A, Atributos (tinta Blanca)
ld	hl,$5800
ld	(hl),a
ld	de,$5801
ld	bc,$02ff
ldir			; Carga e Incrementa
ret			; Retorna

;==========================================================================
;---		               SUB -  C L S                             ---
;--------------------------------------------------------------------------
sub_cls:
ld	a,$00
;ld	a,%01010101
ld	hl,$4000	;Carga en Hl, (1ra posicion VRAM)
ld	(hl),a		;Carga borrado en (HL)
ld	de,$4001	;Carga en DE, (uno mas que HL)
ld	bc,$17ff	;Nro veces (bucle)
ldir			;Carga e Incrementa
ret			;retorna

;================================================================
;---		     S U B  -  S O N I D O S                  ---
;---                                                          ---
;--- ( Los sonidos son originarios del Juego PoromPong...     ---
;---   ... de Juan Antonio Rubio, canal RETROPARLA )          ---
;---                                                          ---                                              
;----------------------------------------------------------------
sonido:
push	de		; Salvaguardar DE,HL
push	hl

dec	a
jr	z,sonido_pala

dec	a
jr	z,sonido_rebote

dec	a
jr	z,sonido_vidamenos

dec	a
jr	z,sonido_pulsamenus

jr	$

sonido_pala:
ld	hl,s_2		; Carga en HL la nota
ld	de,s2_dura/$05	; Carga en DE la duracion
jr	emitir_sonido	; Salta a emitir el sonido

sonido_rebote:
ld	hl,s_3		; Carga en Hl la nota	
ld	de,s3_dura/$05	; Carga en DE la duracion
jr	emitir_sonido	; Salta a emitir el sonido

sonido_vidamenos:
ld	hl,(soni_disp)	; Carga en HL la nota
ld	de,s1_dura/$10	; Carga en DE la duracion
jr	emitir_sonido	; Salta emitir sonido

sonido_pulsamenus:
ld	hl,s_4		; Carga en HL la nota
ld	de,s4_dura	; Carga en DE la duracion
jr	emitir_sonido	; Salta a emitir sonido

jr	$

;----------------------------------------------------
emitir_sonido:
push	af		; Salvaguardar AF,BC,IX...
push	bc
push	ix
call	beeper		; SUB rutina sistema SONIDOS
pop	ix
pop	bc
pop	af

pop	hl
pop	de		; Recupera AF,BC,IX,HL,DE
ret			;Retorna

;=============================================================================
;---                           S P R I T E S                               ---
;-----------------------------------------------------------------------------
; ASM source file created by SevenuP v1.20
; SevenuP (C) Copyright 2002-2006 by Jaime Tejedor Gomez, aka Metalbrain

;GRAPHIC DATA:
;Pixel Size:      ( 32,  64)
;Char Size:       (  4,   8)
;Sort Priorities: X char, Char line, Y char
;Data Outputted:  Gfx+Attr
;Interleave:      Sprite
;Mask:            No
caballero_a1:
	DEFB	  8,  8, 48,  0,  8,  8, 48,  0
	DEFB	 11,240, 48,  0,  7,248, 48,  0
	DEFB	 15,168, 48,  0,  0,248, 48,  0
	DEFB	254,216, 48,  0,198,216, 48,  0
	DEFB	214,  0,252,  0,238,254, 48,  0
	DEFB	125,241,240,  0,124,  0, 48,  0
	DEFB	 59,236,  0,  0, 23,246,  0,  0
	DEFB	  7,246,  0,  0,  3,236,  0,  0

	DEFB	  2,  2, 12,  0,  2,  2, 12,  0
	DEFB	  2,252, 12,  0,  1,254, 12,  0
	DEFB	  3,234, 12,  0,  0, 62, 12,  0
	DEFB	 63,182, 12,  0, 49,182, 12,  0
	DEFB	 53,128, 63,  0, 59,191,140,  0
	DEFB	 31,124,124,  0, 31,  0, 12,  0
	DEFB	 14,251,  0,  0,  5,253,128,  0
	DEFB	  1,253,128,  0,  0,251,  0,  0

	DEFB	  0,128,131,  0,  0,128,131,  0
	DEFB	  0,191,  3,  0,  0,127,131,  0
	DEFB	  0,250,131,  0,  0, 15,131,  0
	DEFB	 15,237,131,  0, 12,109,131,  0
	DEFB	 13, 96, 15,192, 14,239,227,  0
	DEFB	  7,223, 31,  0,  7,192,  3,  0
	DEFB	  3,190,192,  0,  1,127, 96,  0
	DEFB	  0,127, 96,  0,  0, 62,192,  0

	DEFB	  0, 32, 32,192,  0, 32, 32,192
	DEFB	  0, 47,192,192,  0, 31,224,192
	DEFB	  0, 62,160,192,  0,  3,224,192
	DEFB	  3,251, 96,192,  3, 27, 96,192
	DEFB	  3, 88,  3,240,  3,187,248,192
	DEFB	  1,247,199,192,  1,240,  0,192
	DEFB	  0,239,176,  0,  0, 95,216,  0
	DEFB	  0, 31,216,  0,  0, 15,176,  0
caballero_a2:
	DEFB	  8,  8, 48,  0,  8,  8, 48,  0
	DEFB	 11,240, 48,  0,  7,248, 48,  0
	DEFB	 15,168, 48,  0,  0,248, 48,  0
	DEFB	254,216, 48,  0,198,216, 48,  0
	DEFB	214,  0,252,  0,238,254, 48,  0
	DEFB	125,241,240,  0,108,160, 48,  0
	DEFB	 57, 22,  0,  0, 19,  6,  0,  0
	DEFB	  7,188,  0,  0,  7,176,  0,  0

	DEFB	  4,  4, 24,  0,  4,  4, 24,  0
	DEFB	  5,248, 24,  0,  3,252, 24,  0
	DEFB	  7,212, 24,  0,  0,124, 24,  0
	DEFB	127,108, 24,  0, 99,108, 24,  0
	DEFB	107,  0,126,  0,119,127, 24,  0
	DEFB	 62,248,248,  0, 62, 80, 24,  0
	DEFB	 28,139,  0,  0,  9,131,  0,  0
	DEFB	  3,222,  0,  0,  3,216,  0,  0

	DEFB	  2,  2, 12,  0,  2,  2, 12,  0
	DEFB	  2,252, 12,  0,  1,254, 12,  0
	DEFB	  3,234, 12,  0,  0, 62, 12,  0
	DEFB	 63,182, 12,  0, 49,182, 12,  0
	DEFB	 53,128, 63,  0, 59,191,140,  0
	DEFB	 31,124,124,  0, 31, 40, 12,  0
	DEFB	 14, 69,128,  0,  4,193,128,  0
	DEFB	  1,239,  0,  0,  1,236,  0,  0

	DEFB	  1,  1,  6,  0,  1,  1,  6,  0
	DEFB	  1,126,  6,  0,  0,255,  6,  0
	DEFB	  1,245,  6,  0,  0, 31,  6,  0
	DEFB	 31,219,  6,  0, 24,219,  6,  0
	DEFB	 26,192, 31,128, 29,223,198,  0
	DEFB	 15,190, 62,  0, 15,148,  6,  0
	DEFB	  7, 34,192,  0,  2, 96,192,  0
	DEFB	  0,247,128,  0,  0,246,  0,  0

	DEFB	  0,128,131,  0,  0,128,131,  0
	DEFB	  0,191,  3,  0,  0,127,131,  0
	DEFB	  0,250,131,  0,  0, 15,131,  0
	DEFB	 15,237,131,  0, 12,109,131,  0
	DEFB	 13, 96, 15,192, 14,239,227,  0
	DEFB	  7,223, 31,  0,  7,202,  3,  0
	DEFB	  3,145, 96,  0,  1, 48, 96,  0
	DEFB	  0,123,192,  0,  0,123,  0,  0

	DEFB	  0, 64, 65,128,  0, 64, 65,128
	DEFB	  0, 95,129,128,  0, 63,193,128
	DEFB	  0,125, 65,128,  0,  7,193,128
	DEFB	  7,246,193,128,  6, 54,193,128
	DEFB	  6,176,  7,224,  7,119,241,128
	DEFB	  3,239,143,128,  3,229,  1,128
	DEFB	  1,200,176,  0,  0,152, 48,  0
	DEFB	  0, 61,224,  0,  0, 61,128,  0

	DEFB	  0, 32, 32,192,  0, 32, 32,192
	DEFB	  0, 47,192,192,  0, 31,224,192
	DEFB	  0, 62,160,192,  0,  3,224,192
	DEFB	  3,251, 96,192,  3, 27, 96,192
	DEFB	  3, 88,  3,240,  3,187,248,192
	DEFB	  1,247,199,192,  1,242,128,192
	DEFB	  0,228, 88,  0,  0, 76, 24,  0
	DEFB	  0, 30,240,  0,  0, 30,192,  0

	DEFB	  0, 16, 16, 96,  0, 16, 16, 96
	DEFB	  0, 23,224, 96,  0, 15,240, 96
	DEFB	  0, 31, 80, 96,  0,  1,240, 96
	DEFB	  1,253,176, 96,  1,141,176, 96
	DEFB	  1,172,  1,248,  1,221,252, 96
	DEFB	  0,251,227,224,  0,249, 64, 96
	DEFB	  0,114, 44,  0,  0, 38, 12,  0
	DEFB	  0, 15,120,  0,  0, 15, 96,  0
caballero_a2attr:
	defb	66,69

caballero_a3:
	DEFB	  8,  8, 48,  0,  8,  8, 48,  0
	DEFB	 11,240, 48,  0,  7,248, 48,  0
	DEFB	 15,168, 48,  0,  0,248, 48,  0
	DEFB	254,216, 48,  0,198,216, 48,  0
	DEFB	214,  0,252,  0,238,254, 48,  0
	DEFB	125,241,240,  0,124,144, 48,  0
	DEFB	 56, 64,  0,  0, 22,160,  0,  0
	DEFB	  3, 14,  0,  0,  1,190,  0,  0

	DEFB	  4,  4, 24,  0,  4,  4, 24,  0
	DEFB	  5,248, 24,  0,  3,252, 24,  0
	DEFB	  7,212, 24,  0,  0,124, 24,  0
	DEFB	127,108, 24,  0, 99,108, 24,  0
	DEFB	107,  0,126,  0,119,127, 24,  0
	DEFB	 62,248,248,  0, 62, 72, 24,  0
	DEFB	 28, 32,  0,  0, 11, 80,  0,  0
	DEFB	  1,135,  0,  0,  0,223,  0,  0

	DEFB	  2,  2, 12,  0,  2,  2, 12,  0
	DEFB	  2,252, 12,  0,  1,254, 12,  0
	DEFB	  3,234, 12,  0,  0, 62, 12,  0
	DEFB	 63,182, 12,  0, 49,182, 12,  0
	DEFB	 53,128, 63,  0, 59,191,140,  0
	DEFB	 31,124,124,  0, 31, 36, 12,  0
	DEFB	 14, 16,  0,  0,  5,168,  0,  0
	DEFB	  0,195,128,  0,  0,111,128,  0

	DEFB	  1,  1,  6,  0,  1,  1,  6,  0
	DEFB	  1,126,  6,  0,  0,255,  6,  0
	DEFB	  1,245,  6,  0,  0, 31,  6,  0
	DEFB	 31,219,  6,  0, 24,219,  6,  0
	DEFB	 26,192, 31,128, 29,223,198,  0
	DEFB	 15,190, 62,  0, 15,146,  6,  0
	DEFB	  7,  8,  0,  0,  2,212,  0,  0
	DEFB	  0, 97,192,  0,  0, 55,192,  0

	DEFB	  0,128,131,  0,  0,128,131,  0
	DEFB	  0,191,  3,  0,  0,127,131,  0
	DEFB	  0,250,131,  0,  0, 15,131,  0
	DEFB	 15,237,131,  0, 12,109,131,  0
	DEFB	 13, 96, 15,192, 14,239,227,  0
	DEFB	  7,223, 31,  0,  7,201,  3,  0
	DEFB	  3,132,  0,  0,  1,106,  0,  0
	DEFB	  0, 48,224,  0,  0, 27,224,  0

	DEFB	  0, 64, 65,128,  0, 64, 65,128
	DEFB	  0, 95,129,128,  0, 63,193,128
	DEFB	  0,125, 65,128,  0,  7,193,128
	DEFB	  7,246,193,128,  6, 54,193,128
	DEFB	  6,176,  7,224,  7,119,241,128
	DEFB	  3,239,143,128,  3,228,129,128
	DEFB	  1,194,  0,  0,  0,181,  0,  0
	DEFB	  0, 24,112,  0,  0, 13,240,  0

	DEFB	  0, 32, 32,192,  0, 32, 32,192
	DEFB	  0, 47,192,192,  0, 31,224,192
	DEFB	  0, 62,160,192,  0,  3,224,192
	DEFB	  3,251, 96,192,  3, 27, 96,192
	DEFB	  3, 88,  3,240,  3,187,248,192
	DEFB	  1,247,199,192,  1,242, 64,192
	DEFB	  0,225,  0,  0,  0, 90,128,  0
	DEFB	  0, 12, 56,  0,  0,  6,248,  0

	DEFB	  0, 16, 16, 96,  0, 16, 16, 96
	DEFB	  0, 23,224, 96,  0, 15,240, 96
	DEFB	  0, 31, 80, 96,  0,  1,240, 96
	DEFB	  1,253,176, 96,  1,141,176, 96
	DEFB	  1,172,  1,248,  1,221,252, 96
	DEFB	  0,251,227,224,  0,249, 32, 96
	DEFB	  0,112,128,  0,  0, 45, 64,  0
	DEFB	  0,  6, 28,  0,  0,  3,124,  0

caballero_a2giro:
	DEFB	  6,  8,  8,  0,  6,  8,  8,  0
	DEFB	  6,  7,232,  0,  6, 15,240,  0
	DEFB	  6, 10,248,  0,  6, 15,128,  0
	DEFB	  6, 13,191,128,  6, 13,177,128
	DEFB	 31,128, 53,128,  6, 63,187,128
	DEFB	  7,199,223,  0,  6,  2,159,  0
	DEFB	  0, 52, 78,  0,  0, 48,100,  0
	DEFB	  0, 30,240,  0,  0,  6,240,  0

	DEFB	  3,  4,  4,  0,  3,  4,  4,  0
	DEFB	  3,  3,244,  0,  3,  7,248,  0
	DEFB	  3,  5,124,  0,  3,  7,192,  0
	DEFB	  3,  6,223,192,  3,  6,216,192
	DEFB	 15,192, 26,192,  3, 31,221,192
	DEFB	  3,227,239,128,  3,  1, 79,128
	DEFB	  0, 26, 39,  0,  0, 24, 50,  0
	DEFB	  0, 15,120,  0,  0,  3,120,  0

	DEFB	  1,130,  2,  0,  1,130,  2,  0
	DEFB	  1,129,250,  0,  1,131,252,  0
	DEFB	  1,130,190,  0,  1,131,224,  0
	DEFB	  1,131,111,224,  1,131,108, 96
	DEFB	  7,224, 13, 96,  1,143,238,224
	DEFB	  1,241,247,192,  1,128,167,192
	DEFB	  0, 13, 19,128,  0, 12, 25,  0
	DEFB	  0,  7,188,  0,  0,  1,188,  0

	DEFB	  0,193,  1,  0,  0,193,  1,  0
	DEFB	  0,192,253,  0,  0,193,254,  0
	DEFB	  0,193, 95,  0,  0,193,240,  0
	DEFB	  0,193,183,240,  0,193,182, 48
	DEFB	  3,240,  6,176,  0,199,247,112
	DEFB	  0,248,251,224,  0,192, 83,224
	DEFB	  0,  6,137,192,  0,  6, 12,128
	DEFB	  0,  3,222,  0,  0,  0,222,  0

	DEFB	  0, 96,128,128,  0, 96,128,128
	DEFB	  0, 96,126,128,  0, 96,255,  0
	DEFB	  0, 96,175,128,  0, 96,248,  0
	DEFB	  0, 96,219,248,  0, 96,219, 24
	DEFB	  1,248,  3, 88,  0, 99,251,184
	DEFB	  0,124,125,240,  0, 96, 41,240
	DEFB	  0,  3, 68,224,  0,  3,  6, 64
	DEFB	  0,  1,239,  0,  0,  0,111,  0

	DEFB	  0, 48, 64, 64,  0, 48, 64, 64
	DEFB	  0, 48, 63, 64,  0, 48,127,128
	DEFB	  0, 48, 87,192,  0, 48,124,  0
	DEFB	  0, 48,109,252,  0, 48,109,140
	DEFB	  0,252,  1,172,  0, 49,253,220
	DEFB	  0, 62, 62,248,  0, 48, 20,248
	DEFB	  0,  1,162,112,  0,  1,131, 32
	DEFB	  0,  0,247,128,  0,  0, 55,128

	DEFB	  0, 24, 32, 32,  0, 24, 32, 32
	DEFB	  0, 24, 31,160,  0, 24, 63,192
	DEFB	  0, 24, 43,224,  0, 24, 62,  0
	DEFB	  0, 24, 54,254,  0, 24, 54,198
	DEFB	  0,126,  0,214,  0, 24,254,238
	DEFB	  0, 31, 31,124,  0, 24, 10,124
	DEFB	  0,  0,209, 56,  0,  0,193,144
	DEFB	  0,  0,123,192,  0,  0, 27,192

	DEFB	  0, 12, 16, 16,  0, 12, 16, 16
	DEFB	  0, 12, 15,208,  0, 12, 31,224
	DEFB	  0, 12, 21,240,  0, 12, 31,  0
	DEFB	  0, 12, 27,127,  0, 12, 27, 99
	DEFB	  0, 63,  0,107,  0, 12,127,119
	DEFB	  0, 15,143,190,  0, 12,  5, 54
	DEFB	  0,  0,104,156,  0,  0, 96,200
	DEFB	  0,  0, 61,224,  0,  0, 13,224

caballero_a3giro:
	DEFB	  6,  8,  8,  0,  6,  8,  8,  0
	DEFB	  6,  7,232,  0,  6, 15,240,  0
	DEFB	  6, 10,248,  0,  6, 15,128,  0
	DEFB	  6, 13,191,128,  6, 13,177,128
	DEFB	 31,128, 53,128,  6, 63,187,128
	DEFB	  7,199,223,  0,  6,  4,159,  0
	DEFB	  0,  1, 14,  0,  0,  2,180,  0
	DEFB	  0, 56, 96,  0,  0, 62,192,  0

	DEFB	  3,  4,  4,  0,  3,  4,  4,  0
	DEFB	  3,  3,244,  0,  3,  7,248,  0
	DEFB	  3,  5,124,  0,  3,  7,192,  0
	DEFB	  3,  6,223,192,  3,  6,216,192
	DEFB	 15,192, 26,192,  3, 31,221,192
	DEFB	  3,227,239,128,  3,  2, 79,128
	DEFB	  0,  0,135,  0,  0,  1, 90,  0
	DEFB	  0, 28, 48,  0,  0, 31, 96,  0

	DEFB	  1,130,  2,  0,  1,130,  2,  0
	DEFB	  1,129,250,  0,  1,131,252,  0
	DEFB	  1,130,190,  0,  1,131,224,  0
	DEFB	  1,131,111,224,  1,131,108, 96
	DEFB	  7,224, 13, 96,  1,143,238,224
	DEFB	  1,241,247,192,  1,129, 39,192
	DEFB	  0,  0, 67,128,  0,  0,173,  0
	DEFB	  0, 14, 24,  0,  0, 15,176,  0

	DEFB	  0,193,  1,  0,  0,193,  1,  0
	DEFB	  0,192,253,  0,  0,193,254,  0
	DEFB	  0,193, 95,  0,  0,193,240,  0
	DEFB	  0,193,183,240,  0,193,182, 48
	DEFB	  3,240,  6,176,  0,199,247,112
	DEFB	  0,248,251,224,  0,192,147,224
	DEFB	  0,  0, 33,192,  0,  0, 86,128
	DEFB	  0,  7, 12,  0,  0,  7,216,  0

	DEFB	  0, 96,128,128,  0, 96,128,128
	DEFB	  0, 96,126,128,  0, 96,255,  0
	DEFB	  0, 96,175,128,  0, 96,248,  0
	DEFB	  0, 96,219,248,  0, 96,219, 24
	DEFB	  1,248,  3, 88,  0, 99,251,184
	DEFB	  0,124,125,240,  0, 96, 73,240
	DEFB	  0,  0, 16,224,  0,  0, 43, 64
	DEFB	  0,  3,134,  0,  0,  3,236,  0

	DEFB	  0, 48, 64, 64,  0, 48, 64, 64
	DEFB	  0, 48, 63, 64,  0, 48,127,128
	DEFB	  0, 48, 87,192,  0, 48,124,  0
	DEFB	  0, 48,109,252,  0, 48,109,140
	DEFB	  0,252,  1,172,  0, 49,253,220
	DEFB	  0, 62, 62,248,  0, 48, 36,248
	DEFB	  0,  0,  8,112,  0,  0, 21,160
	DEFB	  0,  1,195,  0,  0,  1,246,  0

	DEFB	  0, 24, 32, 32,  0, 24, 32, 32
	DEFB	  0, 24, 31,160,  0, 24, 63,192
	DEFB	  0, 24, 43,224,  0, 24, 62,  0
	DEFB	  0, 24, 54,254,  0, 24, 54,198
	DEFB	  0,126,  0,214,  0, 24,254,238
	DEFB	  0, 31, 31,124,  0, 24, 18,124
	DEFB	  0,  0,  4, 56,  0,  0, 10,208
	DEFB	  0,  0,225,128,  0,  0,251,  0

	DEFB	  0, 12, 16, 16,  0, 12, 16, 16
	DEFB	  0, 12, 15,208,  0, 12, 31,224
	DEFB	  0, 12, 21,240,  0, 12, 31,  0
	DEFB	  0, 12, 27,127,  0, 12, 27, 99
	DEFB	  0, 63,  0,107,  0, 12,127,119
	DEFB	  0, 15,143,190,  0, 12,  9, 62
	DEFB	  0,  0,  2, 28,  0,  0,  5,104
	DEFB	  0,  0,112,192,  0,  0,125,128

caballero_agachadodcha:
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,192,  0,  0,  0,192,  0
	DEFB	  8,  8,192,  0,  8,  8,192,  0
	DEFB	 11,240,192,  0,  7,248,192,  0
	DEFB	254,168,192,  0,198,248,192,  0
	DEFB	214,219,240,  0,238,216,192,  0
	DEFB	125, 39,128,  0,124,242,  0,  0
	DEFB	 56,108,  0,  0, 19,238,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0, 96,  0,  0,  0, 96,  0
	DEFB	  4,  4, 96,  0,  4,  4, 96,  0
	DEFB	  5,248, 96,  0,  3,252, 96,  0
	DEFB	127, 84, 96,  0, 99,124, 96,  0
	DEFB	107,109,248,  0,119,108, 96,  0
	DEFB	 62,147,192,  0, 62,121,  0,  0
	DEFB	 28, 54,  0,  0,  9,247,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0, 48,  0,  0,  0, 48,  0
	DEFB	  2,  2, 48,  0,  2,  2, 48,  0
	DEFB	  2,252, 48,  0,  1,254, 48,  0
	DEFB	 63,170, 48,  0, 49,190, 48,  0
	DEFB	 53,182,252,  0, 59,182, 48,  0
	DEFB	 31, 73,224,  0, 31, 60,128,  0
	DEFB	 14, 27,  0,  0,  4,251,128,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0, 24,  0,  0,  0, 24,  0
	DEFB	  1,  1, 24,  0,  1,  1, 24,  0
	DEFB	  1,126, 24,  0,  0,255, 24,  0
	DEFB	 31,213, 24,  0, 24,223, 24,  0
	DEFB	 26,219,126,  0, 29,219, 24,  0
	DEFB	 15,164,240,  0, 15,158, 64,  0
	DEFB	  7, 13,128,  0,  2,125,192,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0, 12,  0,  0,  0, 12,  0
	DEFB	  0,128,140,  0,  0,128,140,  0
	DEFB	  0,191, 12,  0,  0,127,140,  0
	DEFB	 15,234,140,  0, 12,111,140,  0
	DEFB	 13,109,191,  0, 14,237,140,  0
	DEFB	  7,210,120,  0,  7,207, 32,  0
	DEFB	  3,134,192,  0,  1, 62,224,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  6,  0,  0,  0,  6,  0
	DEFB	  0, 64, 70,  0,  0, 64, 70,  0
	DEFB	  0, 95,134,  0,  0, 63,198,  0
	DEFB	  7,245, 70,  0,  6, 55,198,  0
	DEFB	  6,182,223,128,  7,118,198,  0
	DEFB	  3,233, 60,  0,  3,231,144,  0
	DEFB	  1,195, 96,  0,  0,159,112,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  3,  0,  0,  0,  3,  0
	DEFB	  0, 32, 35,  0,  0, 32, 35,  0
	DEFB	  0, 47,195,  0,  0, 31,227,  0
	DEFB	  3,250,163,  0,  3, 27,227,  0
	DEFB	  3, 91,111,192,  3,187, 99,  0
	DEFB	  1,244,158,  0,  1,243,200,  0
	DEFB	  0,225,176,  0,  0, 79,184,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  1,128,  0,  0,  1,128
	DEFB	  0, 16, 17,128,  0, 16, 17,128
	DEFB	  0, 23,225,128,  0, 15,241,128
	DEFB	  1,253, 81,128,  1,141,241,128
	DEFB	  1,173,183,224,  1,221,177,128
	DEFB	  0,250, 79,  0,  0,249,228,  0
	DEFB	  0,112,216,  0,  0, 39,220,  0

caballero_agachadoizda:
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  3,  0,  0,  0,  3,  0,  0
	DEFB	  0,  3, 16, 16,  0,  3, 16, 16
	DEFB	  0,  3, 15,208,  0,  3, 31,224
	DEFB	  0,  3, 21,127,  0,  3, 31, 99
	DEFB	  0, 15,219,107,  0,  3, 27,119
	DEFB	  0,  1,228,190,  0,  0, 79, 62
	DEFB	  0,  0, 54, 28,  0,  0,119,200

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  6,  0,  0,  0,  6,  0,  0
	DEFB	  0,  6, 32, 32,  0,  6, 32, 32
	DEFB	  0,  6, 31,160,  0,  6, 63,192
	DEFB	  0,  6, 42,254,  0,  6, 62,198
	DEFB	  0, 31,182,214,  0,  6, 54,238
	DEFB	  0,  3,201,124,  0,  0,158,124
	DEFB	  0,  0,108, 56,  0,  0,239,144

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0, 12,  0,  0,  0, 12,  0,  0
	DEFB	  0, 12, 64, 64,  0, 12, 64, 64
	DEFB	  0, 12, 63, 64,  0, 12,127,128
	DEFB	  0, 12, 85,252,  0, 12,125,140
	DEFB	  0, 63,109,172,  0, 12,109,220
	DEFB	  0,  7,146,248,  0,  1, 60,248
	DEFB	  0,  0,216,112,  0,  1,223, 32

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0, 24,  0,  0,  0, 24,  0,  0
	DEFB	  0, 24,128,128,  0, 24,128,128
	DEFB	  0, 24,126,128,  0, 24,255,  0
	DEFB	  0, 24,171,248,  0, 24,251, 24
	DEFB	  0,126,219, 88,  0, 24,219,184
	DEFB	  0, 15, 37,240,  0,  2,121,240
	DEFB	  0,  1,176,224,  0,  3,190, 64

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0, 48,  0,  0,  0, 48,  0,  0
	DEFB	  0, 49,  1,  0,  0, 49,  1,  0
	DEFB	  0, 48,253,  0,  0, 49,254,  0
	DEFB	  0, 49, 87,240,  0, 49,246, 48
	DEFB	  0,253,182,176,  0, 49,183,112
	DEFB	  0, 30, 75,224,  0,  4,243,224
	DEFB	  0,  3, 97,192,  0,  7,124,128

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0, 96,  0,  0,  0, 96,  0,  0
	DEFB	  0, 98,  2,  0,  0, 98,  2,  0
	DEFB	  0, 97,250,  0,  0, 99,252,  0
	DEFB	  0, 98,175,224,  0, 99,236, 96
	DEFB	  1,251,109, 96,  0, 99,110,224
	DEFB	  0, 60,151,192,  0,  9,231,192
	DEFB	  0,  6,195,128,  0, 14,249,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,192,  0,  0,  0,192,  0,  0
	DEFB	  0,196,  4,  0,  0,196,  4,  0
	DEFB	  0,195,244,  0,  0,199,248,  0
	DEFB	  0,197, 95,192,  0,199,216,192
	DEFB	  3,246,218,192,  0,198,221,192
	DEFB	  0,121, 47,128,  0, 19,207,128
	DEFB	  0, 13,135,  0,  0, 29,242,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  1,128,  0,  0,  1,128,  0,  0
	DEFB	  1,136,  8,  0,  1,136,  8,  0
	DEFB	  1,135,232,  0,  1,143,240,  0
	DEFB	  1,138,191,128,  1,143,177,128
	DEFB	  7,237,181,128,  1,141,187,128
	DEFB	  0,242, 95,  0,  0, 39,159,  0
	DEFB	  0, 27, 14,  0,  0, 59,228,  0

caballero_ataca_dcha:
	DEFB	  8,  8,  0,  0,  8,  8,  8,  0
	DEFB	 11,240, 12,  0, 71,248, 14,  0
	DEFB	111,168,  7,  0,119,248,  7,  0
	DEFB	 91,216,  7,  0, 77,216, 15,  0
	DEFB	 86,  0, 30,  0, 77,252,184,  0
	DEFB	123,242, 64,  0,112, 97,224,  0
	DEFB	 96,144,208,  0, 77,  8,  0,  0
	DEFB	  6,  3,  0,  0,  3,143,  0,  0

	DEFB	  4,  4,  0,  0,  4,  4,  4,  0
	DEFB	  5,248,  6,  0, 35,252,  7,  0
	DEFB	 55,212,  3,128, 59,252,  3,128
	DEFB	 45,236,  3,128, 38,236,  7,128
	DEFB	 43,  0, 15,  0, 38,254, 92,  0
	DEFB	 61,249, 32,  0, 56, 48,240,  0
	DEFB	 48, 72,104,  0, 38,132,  0,  0
	DEFB	  3,  1,128,  0,  1,199,128,  0

	DEFB	  2,  2,  0,  0,  2,  2,  2,  0
	DEFB	  2,252,  3,  0, 17,254,  3,128
	DEFB	 27,234,  1,192, 29,254,  1,192
	DEFB	 22,246,  1,192, 19,118,  3,192
	DEFB	 21,128,  7,128, 19,127, 46,  0
	DEFB	 30,252,144,  0, 28, 24,120,  0
	DEFB	 24, 36, 52,  0, 19, 66,  0,  0
	DEFB	  1,128,192,  0,  0,227,192,  0

	DEFB	  1,  1,  0,  0,  1,  1,  1,  0
	DEFB	  1,126,  1,128,  8,255,  1,192
	DEFB	 13,245,  0,224, 14,255,  0,224
	DEFB	 11,123,  0,224,  9,187,  1,224
	DEFB	 10,192,  3,192,  9,191,151,  0
	DEFB	 15,126, 72,  0, 14, 12, 60,  0
	DEFB	 12, 18, 26,  0,  9,161,  0,  0
	DEFB	  0,192, 96,  0,  0,113,224,  0

	DEFB	  0,128,128,  0,  0,128,128,128
	DEFB	  0,191,  0,192,  4,127,128,224
	DEFB	  6,250,128,112,  7,127,128,112
	DEFB	  5,189,128,112,  4,221,128,240
	DEFB	  5, 96,  1,224,  4,223,203,128
	DEFB	  7,191, 36,  0,  7,  6, 30,  0
	DEFB	  6,  9, 13,  0,  4,208,128,  0
	DEFB	  0, 96, 48,  0,  0, 56,240,  0

	DEFB	  0, 64, 64,  0,  0, 64, 64, 64
	DEFB	  0, 95,128, 96,  2, 63,192,112
	DEFB	  3,125, 64, 56,  3,191,192, 56
	DEFB	  2,222,192, 56,  2,110,192,120
	DEFB	  2,176,  0,240,  2,111,229,192
	DEFB	  3,223,146,  0,  3,131, 15,  0
	DEFB	  3,  4,134,128,  2,104, 64,  0
	DEFB	  0, 48, 24,  0,  0, 28,120,  0

	DEFB	  0, 32, 32,  0,  0, 32, 32, 32
	DEFB	  0, 47,192, 48,  1, 31,224, 56
	DEFB	  1,190,160, 28,  1,223,224, 28
	DEFB	  1,111, 96, 28,  1, 55, 96, 60
	DEFB	  1, 88,  0,120,  1, 55,242,224
	DEFB	  1,239,201,  0,  1,193,135,128
	DEFB	  1,130, 67, 64,  1, 52, 32,  0
	DEFB	  0, 24, 12,  0,  0, 14, 60,  0

	DEFB	  0, 16, 16,  0,  0, 16, 16, 16
	DEFB	  0, 23,224, 24,  0,143,240, 28
	DEFB	  0,223, 80, 14,  0,239,240, 14
	DEFB	  0,183,176, 14,  0,155,176, 30
	DEFB	  0,172,  0, 60,  0,155,249,112
	DEFB	  0,247,228,128,  0,224,195,192
	DEFB	  0,193, 33,160,  0,154, 16,  0
	DEFB	  0, 12,  6,  0,  0,  7, 30,  0

caballero_ataca_izda:
	DEFB	  0,  0, 16, 16,  0, 16, 16, 16
	DEFB	  0, 48, 15,208,  0,112, 31,226
	DEFB	  0,224, 21,246,  0,224, 31,238
	DEFB	  0,224, 27,218,  0,240, 27,178
	DEFB	  0,120,  0,106,  0, 29, 63,178
	DEFB	  0,  2, 79,222,  0,  7,134, 14
	DEFB	  0, 11,  9,  6,  0,  0, 16,178
	DEFB	  0,  0,192, 96,  0,  0,241,192

	DEFB	  0,  0, 32, 32,  0, 32, 32, 32
	DEFB	  0, 96, 31,160,  0,224, 63,196
	DEFB	  1,192, 43,236,  1,192, 63,220
	DEFB	  1,192, 55,180,  1,224, 55,100
	DEFB	  0,240,  0,212,  0, 58,127,100
	DEFB	  0,  4,159,188,  0, 15, 12, 28
	DEFB	  0, 22, 18, 12,  0,  0, 33,100
	DEFB	  0,  1,128,192,  0,  1,227,128

	DEFB	  0,  0, 64, 64,  0, 64, 64, 64
	DEFB	  0,192, 63, 64,  1,192,127,136
	DEFB	  3,128, 87,216,  3,128,127,184
	DEFB	  3,128,111,104,  3,192,110,200
	DEFB	  1,224,  1,168,  0,116,254,200
	DEFB	  0,  9, 63,120,  0, 30, 24, 56
	DEFB	  0, 44, 36, 24,  0,  0, 66,200
	DEFB	  0,  3,  1,128,  0,  3,199,  0

	DEFB	  0,  0,128,128,  0,128,128,128
	DEFB	  1,128,126,128,  3,128,255, 16
	DEFB	  7,  0,175,176,  7,  0,255,112
	DEFB	  7,  0,222,208,  7,128,221,144
	DEFB	  3,192,  3, 80,  0,233,253,144
	DEFB	  0, 18,126,240,  0, 60, 48,112
	DEFB	  0, 88, 72, 48,  0,  0,133,144
	DEFB	  0,  6,  3,  0,  0,  7,142,  0

	DEFB	  0,  1,  1,  0,  1,  1,  1,  0
	DEFB	  3,  0,253,  0,  7,  1,254, 32
	DEFB	 14,  1, 95, 96, 14,  1,254,224
	DEFB	 14,  1,189,160, 15,  1,187, 32
	DEFB	  7,128,  6,160,  1,211,251, 32
	DEFB	  0, 36,253,224,  0,120, 96,224
	DEFB	  0,176,144, 96,  0,  1, 11, 32
	DEFB	  0, 12,  6,  0,  0, 15, 28,  0

	DEFB	  0,  2,  2,  0,  2,  2,  2,  0
	DEFB	  6,  1,250,  0, 14,  3,252, 64
	DEFB	 28,  2,190,192, 28,  3,253,192
	DEFB	 28,  3,123, 64, 30,  3,118, 64
	DEFB	 15,  0, 13, 64,  3,167,246, 64
	DEFB	  0, 73,251,192,  0,240,193,192
	DEFB	  1, 97, 32,192,  0,  2, 22, 64
	DEFB	  0, 24, 12,  0,  0, 30, 56,  0

	DEFB	  0,  4,  4,  0,  4,  4,  4,  0
	DEFB	 12,  3,244,  0, 28,  7,248,128
	DEFB	 56,  5,125,128, 56,  7,251,128
	DEFB	 56,  6,246,128, 60,  6,236,128
	DEFB	 30,  0, 26,128,  7, 79,236,128
	DEFB	  0,147,247,128,  1,225,131,128
	DEFB	  2,194, 65,128,  0,  4, 44,128
	DEFB	  0, 48, 24,  0,  0, 60,112,  0

	DEFB	  0,  8,  8,  0,  8,  8,  8,  0
	DEFB	 24,  7,232,  0, 56, 15,241,  0
	DEFB	112, 10,251,  0,112, 15,247,  0
	DEFB	112, 13,237,  0,120, 13,217,  0
	DEFB	 60,  0, 53,  0, 14,159,217,  0
	DEFB	  1, 39,239,  0,  3,195,  7,  0
	DEFB	  5,132,131,  0,  0,  8, 89,  0
	DEFB	  0, 96, 48,  0,  0,120,224,  0

caballero_a2_entrepuertas:
	DEFB	 12, 16, 16,  0, 12, 16, 16,  0
	DEFB	 12, 15,208,  0, 12, 31,224,  0
	DEFB	 12, 21,240,  0, 12, 31,  0,  0
	DEFB	 12, 27,127,  0, 12, 27, 99,  0
	DEFB	 63,  0,107,  0, 12,127,119,  0
	DEFB	 15,143,190,  0, 12,  5, 62,  0
	DEFB	  0,200,156,  0,  0,192,200,  0
	DEFB	  0,121,224,  0,  0, 25,224,  0

	DEFB	 48, 64, 64,  0, 48, 64, 64,  0
	DEFB	 48, 63, 64,  0, 48,127,128,  0
	DEFB	 48, 87,192,  0, 48,124,  0,  0
	DEFB	 48,109,252,  0, 48,109,140,  0
	DEFB	252,  1,172,  0, 49,253,220,  0
	DEFB	 62, 62,248,  0, 48, 20,248,  0
	DEFB	  3, 34,112,  0,  3,  3, 32,  0
	DEFB	  1,231,128,  0,  0,103,128,  0

	DEFB	193,  1,  0,  0,193,  1,  0,  0
	DEFB	192,253,  0,  0,193,254,  0,  0
	DEFB	193, 95,  0,  0,193,240,  0,  0
	DEFB	193,183,240,  0,193,182, 48,  0
	DEFB	240,  6,176,  0,199,247,112,  0
	DEFB	248,251,224,  0,192, 83,224,  0
	DEFB	 12,137,192,  0, 12, 12,128,  0
	DEFB	  7,158,  0,  0,  1,158,  0,  0

	DEFB	  4,  4,  0,  0,  4,  4,  0,  0
	DEFB	  3,244,  0,  0,  7,248,  0,  0
	DEFB	  5,124,  0,  0,  7,192,  0,  0
	DEFB	  6,223,192,  0,  6,216,192,  0
	DEFB	192, 26,192,  0, 31,221,192,  0
	DEFB	227,239,128,  0,  1, 79,128,  0
	DEFB	 50, 39,  0,  0, 48, 50,  0,  0
	DEFB	 30,120,  0,  0,  6,120,  0,  0

	DEFB	 16, 16,  0,  0, 16, 16,  0,  0
	DEFB	 15,208,  0,  0, 31,224,  0,  0
	DEFB	 21,240,  0,  0, 31,  0,  0,  0
	DEFB	 27,127,  0,  0, 27, 99,  0,  0
	DEFB	  0,107,  0,  0,127,119,  0,  0
	DEFB	143,190,  0,  0,  5, 62,  0,  0
	DEFB	200,156,  0,  0,192,200,  0,  0
	DEFB	121,224,  0,  0, 25,224,  0,  0

	DEFB	 64, 64,  0,  0, 64, 64,  0,  0
	DEFB	 63, 64,  0,  0,127,128,  0,  0
	DEFB	 87,192,  0,  0,124,  0,  0,  0
	DEFB	109,252,  0,  0,109,140,  0,  0
	DEFB	  1,172,  0,  0,253,220,  0,  0
	DEFB	 62,248,  0,  0, 20,248,  0,  0
	DEFB	 34,112,  0,  0,  3, 32,  0,  0
	DEFB	231,128,  0,  0,103,128,  0,  0

	DEFB	  1,  0,  0,  0,  1,  0,  0,  0
	DEFB	253,  0,  0,  0,254,  0,  0,  0
	DEFB	 95,  0,  0,  0,240,  0,  0,  0
	DEFB	183,240,  0,  0,182, 48,  0,  0
	DEFB	  6,176,  0,  0,247,112,  0,  0
	DEFB	251,224,  0,  0, 83,224,  0,  0
	DEFB	137,192,  0,  0, 12,128,  0,  0
	DEFB	158,  0,  0,  0,158,  0,  0,  0

	DEFB	  4,  0,  0,  0,  4,  0,  0,  0
	DEFB	244,  0,  0,  0,248,  0,  0,  0
	DEFB	124,  0,  0,  0,192,  0,  0,  0
	DEFB	223,192,  0,  0,216,192,  0,  0
	DEFB	 26,192,  0,  0,221,192,  0,  0
	DEFB	239,128,  0,  0, 79,128,  0,  0
	DEFB	 39,  0,  0,  0, 50,  0,  0,  0
	DEFB	120,  0,  0,  0,120,  0,  0,  0

	DEFB	 16,  0,  0,  0, 16,  0,  0,  0
	DEFB	208,  0,  0,  0,224,  0,  0,  0
	DEFB	240,  0,  0,  0,  0,  0,  0,  0
	DEFB	127,  0,  0,  0, 99,  0,  0,  0
	DEFB	107,  0,  0,  0,119,  0,  0,  0
	DEFB	190,  0,  0,  0, 62,  0,  0,  0
	DEFB	156,  0,  0,  0,200,  0,  0,  0
	DEFB	224,  0,  0,  0,224,  0,  0,  0

	DEFB	 64,  0,  0,  0, 64,  0,  0,  0
	DEFB	 64,  0,  0,  0,128,  0,  0,  0
	DEFB	192,  0,  0,  0,  0,  0,  0,  0
	DEFB	252,  0,  0,  0,140,  0,  0,  0
	DEFB	172,  0,  0,  0,220,  0,  0,  0
	DEFB	248,  0,  0,  0,248,  0,  0,  0
	DEFB	112,  0,  0,  0, 32,  0,  0,  0
	DEFB	128,  0,  0,  0,128,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	240,  0,  0,  0, 48,  0,  0,  0
	DEFB	176,  0,  0,  0,112,  0,  0,  0
	DEFB	224,  0,  0,  0,224,  0,  0,  0
	DEFB	192,  0,  0,  0,128,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	192,  0,  0,  0,192,  0,  0,  0
	DEFB	192,  0,  0,  0,192,  0,  0,  0
	DEFB	128,  0,  0,  0,128,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	128,  0,  0,  0,128,  0,  0,  0
	DEFB	128,  0,  0,  0,128,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0

caballero_a3_entrepuertas:
	DEFB	 12, 16, 16,  0, 12, 16, 16,  0
	DEFB	 12, 15,208,  0, 12, 31,224,  0
	DEFB	 12, 21,240,  0, 12, 31,  0,  0
	DEFB	 12, 27,127,  0, 12, 27, 99,  0
	DEFB	 63,  0,107,  0, 12,127,119,  0
	DEFB	 15,143,190,  0, 12,  9, 62,  0
	DEFB	  0,  2, 28,  0,  0,  5,104,  0
	DEFB	  0,112,192,  0,  0,125,128,  0

	DEFB	 48, 64, 64,  0, 48, 64, 64,  0
	DEFB	 48, 63, 64,  0, 48,127,128,  0
	DEFB	 48, 87,192,  0, 48,124,  0,  0
	DEFB	 48,109,252,  0, 48,109,140,  0
	DEFB	252,  1,172,  0, 49,253,220,  0
	DEFB	 62, 62,248,  0, 48, 36,248,  0
	DEFB	  0,  8,112,  0,  0, 21,160,  0
	DEFB	  1,195,  0,  0,  1,246,  0,  0

	DEFB	193,  1,  0,  0,193,  1,  0,  0
	DEFB	192,253,  0,  0,193,254,  0,  0
	DEFB	193, 95,  0,  0,193,240,  0,  0
	DEFB	193,183,240,  0,193,182, 48,  0
	DEFB	240,  6,176,  0,199,247,112,  0
	DEFB	248,251,224,  0,192,147,224,  0
	DEFB	  0, 33,192,  0,  0, 86,128,  0
	DEFB	  7, 12,  0,  0,  7,216,  0,  0

	DEFB	  4,  4,  0,  0,  4,  4,  0,  0
	DEFB	  3,244,  0,  0,  7,248,  0,  0
	DEFB	  5,124,  0,  0,  7,192,  0,  0
	DEFB	  6,223,192,  0,  6,216,192,  0
	DEFB	192, 26,192,  0, 31,221,192,  0
	DEFB	227,239,128,  0,  2, 79,128,  0
	DEFB	  0,135,  0,  0,  1, 90,  0,  0
	DEFB	 28, 48,  0,  0, 31, 96,  0,  0

	DEFB	 16, 16,  0,  0, 16, 16,  0,  0
	DEFB	 15,208,  0,  0, 31,224,  0,  0
	DEFB	 21,240,  0,  0, 31,  0,  0,  0
	DEFB	 27,127,  0,  0, 27, 99,  0,  0
	DEFB	  0,107,  0,  0,127,119,  0,  0
	DEFB	143,190,  0,  0,  9, 62,  0,  0
	DEFB	  2, 28,  0,  0,  5,104,  0,  0
	DEFB	112,192,  0,  0,125,128,  0,  0

	DEFB	 64, 64,  0,  0, 64, 64,  0,  0
	DEFB	 63, 64,  0,  0,127,128,  0,  0
	DEFB	 87,192,  0,  0,124,  0,  0,  0
	DEFB	109,252,  0,  0,109,140,  0,  0
	DEFB	  1,172,  0,  0,253,220,  0,  0
	DEFB	 62,248,  0,  0, 36,248,  0,  0
	DEFB	  8,112,  0,  0, 21,160,  0,  0
	DEFB	195,  0,  0,  0,246,  0,  0,  0

	DEFB	  1,  0,  0,  0,  1,  0,  0,  0
	DEFB	253,  0,  0,  0,254,  0,  0,  0
	DEFB	 95,  0,  0,  0,240,  0,  0,  0
	DEFB	183,240,  0,  0,182, 48,  0,  0
	DEFB	  6,176,  0,  0,247,112,  0,  0
	DEFB	251,224,  0,  0,147,224,  0,  0
	DEFB	 33,192,  0,  0, 86,128,  0,  0
	DEFB	 12,  0,  0,  0,216,  0,  0,  0

	DEFB	  4,  0,  0,  0,  4,  0,  0,  0
	DEFB	244,  0,  0,  0,248,  0,  0,  0
	DEFB	124,  0,  0,  0,192,  0,  0,  0
	DEFB	223,192,  0,  0,216,192,  0,  0
	DEFB	 26,192,  0,  0,221,192,  0,  0
	DEFB	239,128,  0,  0, 79,128,  0,  0
	DEFB	135,  0,  0,  0, 90,  0,  0,  0
	DEFB	 48,  0,  0,  0, 96,  0,  0,  0

	DEFB	  4,  0,  0,  0,  4,  0,  0,  0
	DEFB	244,  0,  0,  0,248,  0,  0,  0
	DEFB	124,  0,  0,  0,192,  0,  0,  0
	DEFB	223,192,  0,  0,216,192,  0,  0
	DEFB	 26,192,  0,  0,221,192,  0,  0
	DEFB	239,128,  0,  0, 79,128,  0,  0
	DEFB	135,  0,  0,  0, 90,  0,  0,  0
	DEFB	 48,  0,  0,  0, 96,  0,  0,  0

	DEFB	 16,  0,  0,  0, 16,  0,  0,  0
	DEFB	208,  0,  0,  0,224,  0,  0,  0
	DEFB	240,  0,  0,  0,  0,  0,  0,  0
	DEFB	127,  0,  0,  0, 99,  0,  0,  0
	DEFB	107,  0,  0,  0,119,  0,  0,  0
	DEFB	190,  0,  0,  0, 62,  0,  0,  0
	DEFB	 28,  0,  0,  0,104,  0,  0,  0
	DEFB	192,  0,  0,  0,128,  0,  0,  0

	DEFB	 64,  0,  0,  0, 64,  0,  0,  0
	DEFB	 64,  0,  0,  0,128,  0,  0,  0
	DEFB	192,  0,  0,  0,  0,  0,  0,  0
	DEFB	252,  0,  0,  0,140,  0,  0,  0
	DEFB	172,  0,  0,  0,220,  0,  0,  0
	DEFB	248,  0,  0,  0,248,  0,  0,  0
	DEFB	112,  0,  0,  0,160,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	240,  0,  0,  0, 48,  0,  0,  0
	DEFB	176,  0,  0,  0,112,  0,  0,  0
	DEFB	224,  0,  0,  0,224,  0,  0,  0
	DEFB	192,  0,  0,  0,128,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	192,  0,  0,  0,192,  0,  0,  0
	DEFB	192,  0,  0,  0,192,  0,  0,  0
	DEFB	128,  0,  0,  0,128,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	128,  0,  0,  0,128,  0,  0,  0
	DEFB	128,  0,  0,  0,128,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0

caballero_explota:
	DEFB	  0, 32, 32,  0,  2, 32, 32,  0
	DEFB	  0,175,192, 32,  0, 31,228, 32
	DEFB	  3, 61,100,192,  7, 63,225,128
	DEFB	 15, 62,224, 32, 15,158,226,  0
	DEFB	 26,128,  0, 32, 29,146,160,176
	DEFB	 15,132,198, 16,  7,213,146,  0
	DEFB	  3,192, 32,128, 33, 72,132,192
	DEFB	  0, 34,208,  0,  4,102,  0,  0

	DEFB	  0, 32, 32,  0,  2, 32, 32,  0
	DEFB	  0,175,192, 32,  0, 31,228,  0
	DEFB	  1, 61,100, 72,  5, 63,225,136
	DEFB	 15, 62,224, 32, 15,158,226,  0
	DEFB	 26,128,  0, 36, 29,146,160,144
	DEFB	 15,128, 68, 16,  6,213, 18,  0
	DEFB	  2,196, 32,136, 33, 74,132, 64
	DEFB	  0, 32,208,  0,  4,100,  0,  0

	DEFB	  0,  0,  0,  0,  2,  0,  0,  0
	DEFB	  0,128,  0, 32,  0, 32, 36,  0
	DEFB	  0, 32, 36, 64,  4, 47,193,132
	DEFB	 13, 31,224, 32, 15,189, 98,  0
	DEFB	 18,191,224, 36, 29,174,224,160
	DEFB	 11,158,230, 16,  7, 69,146,  0
	DEFB	 19,192, 32,128, 33, 74,148, 64
	DEFB	  0, 40,194,  0,  4, 97,  0,  0


	DEFB	  0,  0,  0,  0,  2,  0,  0,  0
	DEFB	  0,128,  0, 32, 16, 16, 36,  0
	DEFB	  0,144, 36,  0,  2, 23,193,136
	DEFB	 73, 15,224, 32,  1, 29, 98,  0
	DEFB	 10,191,224,  0,  1, 30,228,160
	DEFB	 40,140,192, 20,  0, 66,146,  0
	DEFB	  5,  0, 32,146, 33, 72,132, 64
	DEFB	  0,  2,144,  0,  4,  4,  0,  0

	DEFB	  0,  0,  0,  0,  2,  0,  0, 64
	DEFB	 64,144, 32,  0,  0,  8, 36, 32
	DEFB	  0, 39,196,  4, 34, 45, 97, 32
	DEFB	  9, 47,224,  0,  4,138, 98,  0
	DEFB	 10,  0,  0,  2, 16,146,160, 64
	DEFB	  1,  4, 68, 16,  2, 85,146,  0
	DEFB	  0,128, 32,  0, 32,  8,128, 64
	DEFB	  0,  2,  0,  0,  4,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0, 64,  0
	DEFB	  0, 16,  0,  0, 16,  8,128,  0
	DEFB	  2,  5,128,  0, 68, 39,194,  0
	DEFB	  1, 13, 96, 32,  0,151,224,  0
	DEFB	  0, 14,128, 32,  8,144, 32,128
	DEFB	 32,  4, 68, 16,  0, 16, 18,  0
	DEFB	  2,129, 32,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0, 32,  0
	DEFB	  0,128,  0,  0,  0,  0,128,  0
	DEFB	  8, 17,  4,  0,  0,  0, 32,  0
	DEFB	  0,  0,  0, 32,  0, 18,130,  0
	DEFB	  8,  3,128,  0,  0, 18, 32,160
	DEFB	  0,132, 64,  0,  0, 64,  2,  0
	DEFB	  0,128, 32,128, 32,  8,132, 64
	DEFB	  0, 34, 80,  0,  0,  0,  0,  0

	DEFB	 32,  0,  0,  0,  0,  2,  0,  0
	DEFB	  0,  0,  0,  0,  0,128,  0, 32
	DEFB	  0,  0,  0,128, 64,  0, 32,  8
	DEFB	  8,  0,  0,  0,  0,130,  2,  0
	DEFB	  0,  0,  0,  0, 16, 16,  0, 32
	DEFB	  0,  0, 64,  0,  4,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  8,  4,  2
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0

fantasma_a1:
	DEFB	  0, 60,  0,  0,126,  0,  0,254
	DEFB	  0,  1,191,  0,  3, 61,  0,  3
	DEFB	 25,  0,  3, 25,  0,  3, 25,  0
	DEFB	  3,187,  0,  3,255,  0,  7,255
	DEFB	  0,  7,254,  0, 15,254,  0, 15
	DEFB	126,  0, 14,167,  0, 13,219,  0
	DEFB	 15,255,  0, 15,255,  0, 31,255
	DEFB	  0, 29,158,  0, 57,182,  0,115
	DEFB	108,  0,198,220,  0, 24,176,  0

	DEFB	  0, 30,  0,  0, 63,  0,  0,127
	DEFB	  0,  0,223,128,  1,158,128,  1
	DEFB	140,128,  1,140,128,  1,140,128
	DEFB	  1,221,128,  1,255,128,  3,255
	DEFB	128,  3,255,  0,  7,255,  0,  7
	DEFB	191,  0,  7, 83,128,  6,237,128
	DEFB	  7,255,128,  7,255,128, 15,255
	DEFB	128, 14,207,  0, 28,219,  0, 57
	DEFB	182,  0, 99,110,  0, 12, 88,  0

	DEFB	  0, 15,  0,  0, 31,128,  0, 63
	DEFB	128,  0,111,192,  0,207, 64,  0
	DEFB	198, 64,  0,198, 64,  0,198, 64
	DEFB	  0,238,192,  0,255,192,  1,255
	DEFB	192,  1,255,128,  3,255,128,  3
	DEFB	223,128,  3,169,192,  3,118,192
	DEFB	  3,255,192,  3,255,192,  7,255
	DEFB	192,  7,103,128, 14,109,128, 28
	DEFB	219,  0, 49,183,  0,  6, 44,  0

	DEFB	  0,  7,128,  0, 15,192,  0, 31
	DEFB	192,  0, 55,224,  0,103,160,  0
	DEFB	 99, 32,  0, 99, 32,  0, 99, 32
	DEFB	  0,119, 96,  0,127,224,  0,255
	DEFB	224,  0,255,192,  1,255,192,  1
	DEFB	239,192,  1,212,224,  1,187, 96
	DEFB	  1,255,224,  1,255,224,  3,255
	DEFB	224,  3,179,192,  7, 54,192, 14
	DEFB	109,128, 24,219,128,  3, 22,  0

	DEFB	  0,  3,192,  0,  7,224,  0, 15
	DEFB	224,  0, 27,240,  0, 51,208,  0
	DEFB	 49,144,  0, 49,144,  0, 49,144
	DEFB	  0, 59,176,  0, 63,240,  0,127
	DEFB	240,  0,127,224,  0,255,224,  0
	DEFB	247,224,  0,234,112,  0,221,176
	DEFB	  0,255,240,  0,255,240,  1,255
	DEFB	240,  1,217,224,  3,155, 96,  7
	DEFB	 54,192, 12,109,192,  1,139,  0

	DEFB	  0,  1,224,  0,  3,240,  0,  7
	DEFB	240,  0, 13,248,  0, 25,232,  0
	DEFB	 24,200,  0, 24,200,  0, 24,200
	DEFB	  0, 29,216,  0, 31,248,  0, 63
	DEFB	248,  0, 63,240,  0,127,240,  0
	DEFB	123,240,  0,117, 56,  0,110,216
	DEFB	  0,127,248,  0,127,248,  0,255
	DEFB	248,  0,236,240,  1,205,176,  3
	DEFB	155, 96,  6, 54,224,  0,197,128

	DEFB	  0,  0,240,  0,  1,248,  0,  3
	DEFB	248,  0,  6,252,  0, 12,244,  0
	DEFB	 12,100,  0, 12,100,  0, 12,100
	DEFB	  0, 14,236,  0, 15,252,  0, 31
	DEFB	252,  0, 31,248,  0, 63,248,  0
	DEFB	 61,248,  0, 58,156,  0, 55,108
	DEFB	  0, 63,252,  0, 63,252,  0,127
	DEFB	252,  0,118,120,  0,230,216,  1
	DEFB	205,176,  3, 27,112,  0, 98,192

	DEFB	  0,  0,120,  0,  0,252,  0,  1
	DEFB	252,  0,  3,126,  0,  6,122,  0
	DEFB	  6, 50,  0,  6, 50,  0,  6, 50
	DEFB	  0,  7,118,  0,  7,254,  0, 15
	DEFB	254,  0, 15,252,  0, 31,252,  0
	DEFB	 30,252,  0, 29, 78,  0, 27,182
	DEFB	  0, 31,254,  0, 31,254,  0, 63
	DEFB	254,  0, 59, 60,  0,115,108,  0
	DEFB	230,216,  1,141,184,  0, 49, 96

fantasma_a1giro:
	DEFB	  0, 60,  0,  0,126,  0,  0,127
	DEFB	  0,  0,253,128,  0,188,192,  0
	DEFB	152,192,  0,152,192,  0,152,192
	DEFB	  0,221,192,  0,255,192,  0,255
	DEFB	224,  0,127,224,  0,127,240,  0
	DEFB	126,240,  0,229,112,  0,219,176
	DEFB	  0,255,240,  0,255,240,  0,255
	DEFB	248,  0,121,184,  0,109,156,  0
	DEFB	 54,206,  0, 59, 99,  0, 13, 24

	DEFB	  0,120,  0,  0,252,  0,  0,254
	DEFB	  0,  1,251,  0,  1,121,128,  1
	DEFB	 49,128,  1, 49,128,  1, 49,128
	DEFB	  1,187,128,  1,255,128,  1,255
	DEFB	192,  0,255,192,  0,255,224,  0
	DEFB	253,224,  1,202,224,  1,183, 96
	DEFB	  1,255,224,  1,255,224,  1,255
	DEFB	240,  0,243,112,  0,219, 56,  0
	DEFB	109,156,  0,118,198,  0, 26, 48

	DEFB	  0,240,  0,  1,248,  0,  1,252
	DEFB	  0,  3,246,  0,  2,243,  0,  2
	DEFB	 99,  0,  2, 99,  0,  2, 99,  0
	DEFB	  3,119,  0,  3,255,  0,  3,255
	DEFB	128,  1,255,128,  1,255,192,  1
	DEFB	251,192,  3,149,192,  3,110,192
	DEFB	  3,255,192,  3,255,192,  3,255
	DEFB	224,  1,230,224,  1,182,112,  0
	DEFB	219, 56,  0,237,140,  0, 52, 96

	DEFB	  1,224,  0,  3,240,  0,  3,248
	DEFB	  0,  7,236,  0,  5,230,  0,  4
	DEFB	198,  0,  4,198,  0,  4,198,  0
	DEFB	  6,238,  0,  7,254,  0,  7,255
	DEFB	  0,  3,255,  0,  3,255,128,  3
	DEFB	247,128,  7, 43,128,  6,221,128
	DEFB	  7,255,128,  7,255,128,  7,255
	DEFB	192,  3,205,192,  3,108,224,  1
	DEFB	182,112,  1,219, 24,  0,104,192

	DEFB	  3,192,  0,  7,224,  0,  7,240
	DEFB	  0, 15,216,  0, 11,204,  0,  9
	DEFB	140,  0,  9,140,  0,  9,140,  0
	DEFB	 13,220,  0, 15,252,  0, 15,254
	DEFB	  0,  7,254,  0,  7,255,  0,  7
	DEFB	239,  0, 14, 87,  0, 13,187,  0
	DEFB	 15,255,  0, 15,255,  0, 15,255
	DEFB	128,  7,155,128,  6,217,192,  3
	DEFB	108,224,  3,182, 48,  0,209,128

	DEFB	  7,128,  0, 15,192,  0, 15,224
	DEFB	  0, 31,176,  0, 23,152,  0, 19
	DEFB	 24,  0, 19, 24,  0, 19, 24,  0
	DEFB	 27,184,  0, 31,248,  0, 31,252
	DEFB	  0, 15,252,  0, 15,254,  0, 15
	DEFB	222,  0, 28,174,  0, 27,118,  0
	DEFB	 31,254,  0, 31,254,  0, 31,255
	DEFB	  0, 15, 55,  0, 13,179,128,  6
	DEFB	217,192,  7,108, 96,  1,163,  0

	DEFB	 15,  0,  0, 31,128,  0, 31,192
	DEFB	  0, 63, 96,  0, 47, 48,  0, 38
	DEFB	 48,  0, 38, 48,  0, 38, 48,  0
	DEFB	 55,112,  0, 63,240,  0, 63,248
	DEFB	  0, 31,248,  0, 31,252,  0, 31
	DEFB	188,  0, 57, 92,  0, 54,236,  0
	DEFB	 63,252,  0, 63,252,  0, 63,254
	DEFB	  0, 30,110,  0, 27,103,  0, 13
	DEFB	179,128, 14,216,192,  3, 70,  0

	DEFB	 30,  0,  0, 63,  0,  0, 63,128
	DEFB	  0,126,192,  0, 94, 96,  0, 76
	DEFB	 96,  0, 76, 96,  0, 76, 96,  0
	DEFB	110,224,  0,127,224,  0,127,240
	DEFB	  0, 63,240,  0, 63,248,  0, 63
	DEFB	120,  0,114,184,  0,109,216,  0
	DEFB	127,248,  0,127,248,  0,127,252
	DEFB	  0, 60,220,  0, 54,206,  0, 27
	DEFB	103,  0, 29,177,128,  6,140,  0

fantasma_a2:
	DEFB	  0, 60,  0,  0,126,  0,  0,254
	DEFB	  0,  1,191,  0,  3, 61,  0,  3
	DEFB	 25,  0,  3, 25,  0,  3, 25,  0
	DEFB	  3,187,  0,  3,255,  0,  7,255
	DEFB	  0,  7,254,  0, 15,254,  0, 15
	DEFB	126,  0, 14,167,  0, 29,219,  0
	DEFB	 31,255,  0, 31,255,  0, 31,255
	DEFB	  0, 59,247,  0, 51,182,  0,119
	DEFB	102,  0,102,102,  0, 68, 68,  0

	DEFB	  0, 30,  0,  0, 63,  0,  0,127
	DEFB	  0,  0,223,128,  1,158,128,  1
	DEFB	140,128,  1,140,128,  1,140,128
	DEFB	  1,221,128,  1,255,128,  3,255
	DEFB	128,  3,255,  0,  7,255,  0,  7
	DEFB	191,  0,  7, 83,128, 14,237,128
	DEFB	 15,255,128, 15,255,128, 15,255
	DEFB	128, 29,251,128, 25,219,  0, 59
	DEFB	179,  0, 51, 51,  0, 34, 34,  0

	DEFB	  0, 15,  0,  0, 31,128,  0, 63
	DEFB	128,  0,111,192,  0,207, 64,  0
	DEFB	198, 64,  0,198, 64,  0,198, 64
	DEFB	  0,238,192,  0,255,192,  1,255
	DEFB	192,  1,255,128,  3,255,128,  3
	DEFB	223,128,  3,169,192,  7,118,192
	DEFB	  7,255,192,  7,255,192,  7,255
	DEFB	192, 14,253,192, 12,237,128, 29
	DEFB	217,128, 25,153,128, 17, 17,  0

	DEFB	  0,  7,128,  0, 15,192,  0, 31
	DEFB	192,  0, 55,224,  0,103,160,  0
	DEFB	 99, 32,  0, 99, 32,  0, 99, 32
	DEFB	  0,119, 96,  0,127,224,  0,255
	DEFB	224,  0,255,192,  1,255,192,  1
	DEFB	239,192,  1,212,224,  3,187, 96
	DEFB	  3,255,224,  3,255,224,  3,255
	DEFB	224,  7,126,224,  6,118,192, 14
	DEFB	236,192, 12,204,192,  8,136,128

	DEFB	  0,  3,192,  0,  7,224,  0, 15
	DEFB	224,  0, 27,240,  0, 51,208,  0
	DEFB	 49,144,  0, 49,144,  0, 49,144
	DEFB	  0, 59,176,  0, 63,240,  0,127
	DEFB	240,  0,127,224,  0,255,224,  0
	DEFB	247,224,  0,234,112,  1,221,176
	DEFB	  1,255,240,  1,255,240,  1,255
	DEFB	240,  3,191,112,  3, 59, 96,  7
	DEFB	118, 96,  6,102, 96,  4, 68, 64

	DEFB	  0,  1,224,  0,  3,240,  0,  7
	DEFB	240,  0, 13,248,  0, 25,232,  0
	DEFB	 24,200,  0, 24,200,  0, 24,200
	DEFB	  0, 29,216,  0, 31,248,  0, 63
	DEFB	248,  0, 63,240,  0,127,240,  0
	DEFB	123,240,  0,117, 56,  0,238,216
	DEFB	  0,255,248,  0,255,248,  0,255
	DEFB	248,  1,223,184,  1,157,176,  3
	DEFB	187, 48,  3, 51, 48,  2, 34, 32

	DEFB	  0,  0,240,  0,  1,248,  0,  3
	DEFB	248,  0,  6,252,  0, 12,244,  0
	DEFB	 12,100,  0, 12,100,  0, 12,100
	DEFB	  0, 14,236,  0, 15,252,  0, 31
	DEFB	252,  0, 31,248,  0, 63,248,  0
	DEFB	 61,248,  0, 58,156,  0,119,108
	DEFB	  0,127,252,  0,127,252,  0,127
	DEFB	252,  0,239,220,  0,206,216,  1
	DEFB	221,152,  1,153,152,  1, 17, 16

	DEFB	  0,  0,120,  0,  0,252,  0,  1
	DEFB	252,  0,  3,126,  0,  6,122,  0
	DEFB	  6, 50,  0,  6, 50,  0,  6, 50
	DEFB	  0,  7,118,  0,  7,254,  0, 15
	DEFB	254,  0, 15,252,  0, 31,252,  0
	DEFB	 30,252,  0, 29, 78,  0, 59,182
	DEFB	  0, 63,254,  0, 63,254,  0, 63
	DEFB	254,  0,119,238,  0,103,108,  0
	DEFB	238,204,  0,204,204,  0,136,136

fantasma_a2giro:
	DEFB	  0, 60,  0,  0,126,  0,  0,127
	DEFB	  0,  0,253,128,  0,188,192,  0
	DEFB	152,192,  0,152,192,  0,152,192
	DEFB	  0,221,192,  0,255,192,  0,255
	DEFB	224,  0,127,224,  0,127,240,  0
	DEFB	126,240,  0,229,112,  0,219,184
	DEFB	  0,255,248,  0,255,248,  0,255
	DEFB	248,  0,239,220,  0,109,204,  0
	DEFB	102,238,  0,102,102,  0, 34, 34

	DEFB	  0,120,  0,  0,252,  0,  0,254
	DEFB	  0,  1,251,  0,  1,121,128,  1
	DEFB	 49,128,  1, 49,128,  1, 49,128
	DEFB	  1,187,128,  1,255,128,  1,255
	DEFB	192,  0,255,192,  0,255,224,  0
	DEFB	253,224,  1,202,224,  1,183,112
	DEFB	  1,255,240,  1,255,240,  1,255
	DEFB	240,  1,223,184,  0,219,152,  0
	DEFB	205,220,  0,204,204,  0, 68, 68

	DEFB	  0,240,  0,  1,248,  0,  1,252
	DEFB	  0,  3,246,  0,  2,243,  0,  2
	DEFB	 99,  0,  2, 99,  0,  2, 99,  0
	DEFB	  3,119,  0,  3,255,  0,  3,255
	DEFB	128,  1,255,128,  1,255,192,  1
	DEFB	251,192,  3,149,192,  3,110,224
	DEFB	  3,255,224,  3,255,224,  3,255
	DEFB	224,  3,191,112,  1,183, 48,  1
	DEFB	155,184,  1,153,152,  0,136,136

	DEFB	  1,224,  0,  3,240,  0,  3,248
	DEFB	  0,  7,236,  0,  5,230,  0,  4
	DEFB	198,  0,  4,198,  0,  4,198,  0
	DEFB	  6,238,  0,  7,254,  0,  7,255
	DEFB	  0,  3,255,  0,  3,255,128,  3
	DEFB	247,128,  7, 43,128,  6,221,192
	DEFB	  7,255,192,  7,255,192,  7,255
	DEFB	192,  7,126,224,  3,110, 96,  3
	DEFB	 55,112,  3, 51, 48,  1, 17, 16

	DEFB	  3,192,  0,  7,224,  0,  7,240
	DEFB	  0, 15,216,  0, 11,204,  0,  9
	DEFB	140,  0,  9,140,  0,  9,140,  0
	DEFB	 13,220,  0, 15,252,  0, 15,254
	DEFB	  0,  7,254,  0,  7,255,  0,  7
	DEFB	239,  0, 14, 87,  0, 13,187,128
	DEFB	 15,255,128, 15,255,128, 15,255
	DEFB	128, 14,253,192,  6,220,192,  6
	DEFB	110,224,  6,102, 96,  2, 34, 32

	DEFB	  7,128,  0, 15,192,  0, 15,224
	DEFB	  0, 31,176,  0, 23,152,  0, 19
	DEFB	 24,  0, 19, 24,  0, 19, 24,  0
	DEFB	 27,184,  0, 31,248,  0, 31,252
	DEFB	  0, 15,252,  0, 15,254,  0, 15
	DEFB	222,  0, 28,174,  0, 27,119,  0
	DEFB	 31,255,  0, 31,255,  0, 31,255
	DEFB	  0, 29,251,128, 13,185,128, 12
	DEFB	221,192, 12,204,192,  4, 68, 64

	DEFB	 15,  0,  0, 31,128,  0, 31,192
	DEFB	  0, 63, 96,  0, 47, 48,  0, 38
	DEFB	 48,  0, 38, 48,  0, 38, 48,  0
	DEFB	 55,112,  0, 63,240,  0, 63,248
	DEFB	  0, 31,248,  0, 31,252,  0, 31
	DEFB	188,  0, 57, 92,  0, 54,238,  0
	DEFB	 63,254,  0, 63,254,  0, 63,254
	DEFB	  0, 59,247,  0, 27,115,  0, 25
	DEFB	187,128, 25,153,128,  8,136,128

	DEFB	 30,  0,  0, 63,  0,  0, 63,128
	DEFB	  0,126,192,  0, 94, 96,  0, 76
	DEFB	 96,  0, 76, 96,  0, 76, 96,  0
	DEFB	110,224,  0,127,224,  0,127,240
	DEFB	  0, 63,240,  0, 63,248,  0, 63
	DEFB	120,  0,114,184,  0,109,220,  0
	DEFB	127,252,  0,127,252,  0,127,252
	DEFB	  0,119,238,  0, 54,230,  0, 51
	DEFB	119,  0, 51, 51,  0, 17, 17,  0

fantasma_explota:
	DEFB	  0,120,  0,  0,252,  0,  0,254
	DEFB	 64,  1,251,  0,  1,121,128,  3
	DEFB	 49,128,  3, 49,144,  9, 49,128
	DEFB	  3,187,192,  3,255,128,  1,215
	DEFB	128,  0,255,192,  0, 36,192,  0
	DEFB	255, 96,  1,187,224,  1,115,160
	DEFB	  1,249,192,  1,170,160,  1, 46
	DEFB	 32,  0,173,176,  0,173, 16,  2
	DEFB	 68,216,  9, 36, 76,  0, 32,  4

	DEFB	  0,104,  0,  0,252,  0,  0,254
	DEFB	 64,  1,251,  0,  1,121,128,  3
	DEFB	 49,128,  3, 49,144,  9, 49,128
	DEFB	  3,187,192,  3,126,128,  1,223
	DEFB	128,  0,251,192,  0, 36,128,  0
	DEFB	247, 32,  1,187,224,  0,  3, 32
	DEFB	  0,224, 64,  1,160,160,  9, 34
	DEFB	 32,  0,141,176,  0, 13,  0,  2
	DEFB	 68,200,  9, 36, 76,  0, 32,  4

	DEFB	  0,120,  0,  0,156,  0,  0,222
	DEFB	 64,  1,248,  0,  1,121,128,  3
	DEFB	 49,128,  3, 49,144,  9, 49,128
	DEFB	  3,187,192,  3,126,128,  0, 87
	DEFB	128,  0,243,192,  8, 32,  0, 32
	DEFB	239, 64,  1,163,  0,  1,112, 32
	DEFB	 32,  1,192,  1,170,160,  1,  2
	DEFB	 32, 12,169,128,  8,173, 16,  2
	DEFB	 68, 80,  9, 36, 76,  0, 32,  4

	DEFB	  0, 56,  0,  0,156,  0,  0,206
	DEFB	 64,  9,226,  0, 33,120,128,  2
	DEFB	 49,128,  3, 49,144,  9, 17,128
	DEFB	  3,187,196,  3,254, 20,  1,151
	DEFB	  0,  0, 63,128,  2, 32,128, 34
	DEFB	231, 36,  4, 11,108,  5, 48, 32
	DEFB	  1,  9,192, 17,162,164,  5,  0
	DEFB	 32, 32,161,160,  0,173,  0,  2
	DEFB	 68,208,  9, 32, 68,  0, 32,  0

	DEFB	  0, 48,  0,  0,148,  0,  0,206
	DEFB	 64,  1,130,  0,  0,104,128,  2
	DEFB	 49,128,  3,  1, 16,  8, 49,128
	DEFB	  3,187,128,  2,124, 40,  0,199
	DEFB	128,  0,240, 64,  4, 36,  0,  0
	DEFB	 15,  0,  0,160, 32, 16, 64,160
	DEFB	  1,121,192, 33, 10,128, 49,  0
	DEFB	  0,  0,173,144,  0,173, 16,  2
	DEFB	 68,192,  9, 36, 64,  0, 32,  0

	DEFB	  0, 80,  0,  0, 12,  0,  0,130
	DEFB	 64,  0, 48,  0,  1,  8,  0,  2
	DEFB	 32,  0,  3, 48,144,  8, 33,  0
	DEFB	  2, 27,128,  3,  0,  0, 36, 64
	DEFB	128,  0,236,128,  0,  4,  0,  8
	DEFB	 96, 96,  2,136,  0, 70,  0, 32
	DEFB	  4,  8,192, 25,  8, 32,  1, 32
	DEFB	  8, 72,173,132,  8,  9,  0,  0
	DEFB	  0,208,  0,  0,  0,  0,  0,  0

	DEFB	  0,  0,  0,  0,130,  0, 36, 80
	DEFB	 66,  0,129,  0, 16,  0,  0,  0
	DEFB	 32,  0,  3,  1, 16,  8, 17,  0
	DEFB	  2,  0, 64,  1,  0,  0, 32, 16
	DEFB	 12,  8,130, 64,  0, 32,128,  0
	DEFB	130,  0, 72,  0, 72,  0, 81,128
	DEFB	  0,  0,  0,  0,136,128, 17,  0
	DEFB	 32,  0,  0, 16,  0,168,  2,  2
	DEFB	 68, 64,  0,  0,  0,  0,  0,  0

	DEFB	  0,  0,  0,  0,  8,  0,  0,  0
	DEFB	  0,  2,  0,  4,  0,  0,  0,  0
	DEFB	 32,128,  2,  0,  0, 32,  0,  0
	DEFB	  0,  0,  0,  0,  0, 16,  0,  0
	DEFB	  0,  8,  0,128,  0,128,  0,  0
	DEFB	  0,  0,  0,  2,  4,  8,  0,  0
	DEFB	  0, 32,128,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  8, 16,  0
	DEFB	 64,  0,  0,  0,  0,  0,  0,  0

arqueros:
	DEFB	  0,  7,196,  0, 15,229,  0, 10
	DEFB	233,  0, 15,234,  0, 13,244,  0
	DEFB	 13,222,  0,  0, 62,  0, 63,230
	DEFB	128,207,214, 65,  7,174, 50,103
	DEFB	 94, 15,133, 30,  0,  9, 30,  0
	DEFB	 16,156,  0,193,204,  0,241,224

	DEFB	  1,  7,196,  2, 15,229,  4, 10
	DEFB	233, 36, 15,234,104, 13,252,223
	DEFB	253,254,104,127,226, 40, 31,140
	DEFB	  4, 15,246,  4,  7, 14,  2, 14
	DEFB	 30,  1, 17, 30,  0, 32,158,  1
	DEFB	128,204,  1,225,224,  0,241,224

	DEFB	 35,224,  0,167,240,  0,151, 80
	DEFB	  0, 87,240,  0, 47,176,  0,123
	DEFB	176,  0,124,  0,  0,103,252,  0
	DEFB	107,243,  1,117,224,130,122,230
	DEFB	 76,120,161,240,120,144,  0, 57
	DEFB	  8,  0, 51,131,  0,  7,143,  0

	DEFB	 35,224,128,167,240, 64,151, 80
	DEFB	 32, 87,240, 36, 63,176, 22,127
	DEFB	191,251, 71,254, 22, 49,248, 20
	DEFB	111,248, 32,112,240, 32,120,112
	DEFB	 64,120,136,128,121,  4,  0, 51
	DEFB	  1,128,  7,135,128,  7,143,  0

arquero_explota:
	DEFB	  0,  7,196,  0, 15,229,  0, 10
	DEFB	233,  0, 15,234,  0, 13,244,  0
	DEFB	 13,222,  0,  0, 62,  0, 63,230
	DEFB	128,207,214, 65,  7,174, 50,103
	DEFB	 94, 15,133, 30,  0,  9, 30,  0
	DEFB	 16,158,  0,193,204,  0,241,224

	DEFB	  0,  0,  0,  0,  7,196,  0, 15
	DEFB	229,  0, 10,233,  0, 15,234,  0
	DEFB	 13,244,  0, 13,222,  0,  0, 62
	DEFB	  0, 63,230,128,207,214, 65,  7
	DEFB	174, 50,103, 94, 15,133, 30,  0
	DEFB	  9, 30,  0, 16,158,  0,193,204

	DEFB	  0,  0,  0,  0,  0,  0,  0,  7
	DEFB	196,  0, 15,229,  0, 10,233,  0
	DEFB	 15,234,  0, 13,244,  0, 13,222
	DEFB	  0,  0, 62,  0, 63,230,128,207
	DEFB	214, 65,  7,174, 50,103, 94, 15
	DEFB	133, 30,  0,  9, 30,  0, 16,158

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  7,196,  0, 15,229,  0
	DEFB	 10,233,  0, 15,234,  0, 13,244
	DEFB	  0, 13,222,  0,  0, 62,  0, 63
	DEFB	230,128,207,214, 65,  7,174, 50
	DEFB	103, 94, 15,133, 30,  0,  9, 30

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  7,196,  0
	DEFB	 15,229,  0, 10,233,  0, 15,234
	DEFB	  0, 13,244,  0, 13,222,  0,  0
	DEFB	 62,  0, 63,230,128,207,214, 65
	DEFB	  7,174, 50,103, 94, 15,133, 30

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  7,196,  0, 15,229,  0, 10,233
	DEFB	  0, 15,234,  0, 13,244,  0, 13
	DEFB	222,  0,  0, 62,  0, 63,230,128
	DEFB	207,214, 65,  7,174, 50,103, 94

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  7,196,  0, 15,229
	DEFB	  0, 10,233,  0, 15,234,  0, 13
	DEFB	244,  0, 13,222,  0,  0, 62,  0
	DEFB	 63,230,128,207,214, 65,  7,174

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  7,196
	DEFB	  0, 15,229,  0, 10,233,  0, 15
	DEFB	234,  0, 13,244,  0, 13,222,  0
	DEFB	  0, 62,  0, 63,230,128,207,214
arquero_explota2:
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  7,196,  0, 15,229,  0, 10
	DEFB	233,  0, 15,234,  0, 13,244,  0
	DEFB	 13,222,  0,  0, 62,  0, 63,230

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  7
	DEFB	196,  0, 15,229,  0, 10,233,  0
	DEFB	 15,234,  0, 13,244,  0, 13,222

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  7,196,  0, 15,229,  0
	DEFB	 10,233,  0, 15,234,  0, 13,244

	DEFB	  0,  0,  0,  8,  0,  0,  4,  8
	DEFB	128,  3,  0,132,  0,144,128,  0
	DEFB	152,  0, 18,  8,137, 88,  4, 10
	DEFB	 44,196,148,  2,102,160,  3,  2
	DEFB	 64,  0,144,207, 48,  9, 24, 28
	DEFB	  4, 98,  2,197,  0,  0, 18,192

	DEFB	  0,  0,  0,  0,  0,  0,  8, 66
	DEFB	  2,  0, 96, 32,  2, 16, 96,  0
	DEFB	  4, 66, 17, 20, 18,  8,128, 64
	DEFB	  2,  2,  1,  0, 34, 22, 24, 48
	DEFB	 32,  0,136,132,  1,129,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  4,  0,  0,  0,  8,  2
	DEFB	  0,  0,  0,  0, 64,  0, 16, 64
	DEFB	  0,  0,  8,  0,129,  0,  0,  4
	DEFB	 32,  0,  0,128,  0, 48,  0,  0
	DEFB	128, 32,  0,  4,  0,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  0,  4,  0,  0
	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  2, 32,  1,  0,  0,  0, 64
	DEFB	  0,  0,  0,  0,  0,  1,  0,  1
	DEFB	 16,  8,  0, 32, 64,  0,  1,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  2,  0,  0,  0
	DEFB	  2,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0,  0,  0,  0,  4,  0,  0,  0
	DEFB	 16,  0,  0,  0,  0, 64,  0,  0
	DEFB	  0, 32,  0,  8,  0,  0,  0,  0

murcielago_a1:
	DEFB	 16,  8,  0, 56, 28,  0, 57,156
	DEFB	  0,123,222,  0,125,190,  0,255
	DEFB	255,  0,251,223,  0,170, 85,  0

	DEFB	  8,  4,  0, 28, 14,  0, 28,206
	DEFB	  0, 61,239,  0, 62,223,  0,127
	DEFB	255,128,125,239,128, 85, 42,128

	DEFB	  4,  2,  0, 14,  7,  0, 14,103
	DEFB	  0, 30,247,128, 31,111,128, 63
	DEFB	255,192, 62,247,192, 42,149, 64

	DEFB	  2,  1,  0,  7,  3,128,  7, 51
	DEFB	128, 15,123,192, 15,183,192, 31
	DEFB	255,224, 31,123,224, 21, 74,160

	DEFB	  1,  0,128,  3,129,192,  3,153
	DEFB	192,  7,189,224,  7,219,224, 15
	DEFB	255,240, 15,189,240, 10,165, 80

	DEFB	  0,128, 64,  1,192,224,  1,204
	DEFB	224,  3,222,240,  3,237,240,  7
	DEFB	255,248,  7,222,248,  5, 82,168

	DEFB	  0, 64, 32,  0,224,112,  0,230
	DEFB	112,  1,239,120,  1,246,248,  3
	DEFB	255,252,  3,239,124,  2,169, 84

	DEFB	  0, 32, 16,  0,112, 56,  0,115
	DEFB	 56,  0,247,188,  0,251,124,  1
	DEFB	255,254,  1,247,190,  1, 84,170

murcielago_a2:
	DEFB	224,  7,  0,113,142,  0, 59,220
	DEFB	  0,253,191,  0,127,254,  0, 59
	DEFB	220,  0,122, 94,  0,240, 15,  0

	DEFB	112,  3,128, 56,199,  0, 29,238
	DEFB	  0,126,223,128, 61,251,  0, 29
	DEFB	238,  0, 61, 47,  0,120,  7,128

	DEFB	 56,  1,192, 28, 99,128, 14,247
	DEFB	  0, 63,111,192, 31,255,128, 14
	DEFB	247,  0, 30,151,128, 60,  3,192

	DEFB	 28,  0,224, 14, 49,192,  7,123
	DEFB	128, 31,183,224, 15,255,192,  7
	DEFB	123,128, 15, 75,192, 30,  1,224

	DEFB	 14,  0,112,  7, 24,224,  3,189
	DEFB	192, 15,219,240,  7,255,224,  3
	DEFB	189,192,  7,165,224, 15,  0,240

	DEFB	  7,  0, 56,  3,140,112,  1,222
	DEFB	224,  7,237,248,  3,255,240,  1
	DEFB	222,224,  3,210,240,  7,128,120

	DEFB	  3,128, 28,  1,198, 56,  0,239
	DEFB	112,  3,246,252,  1,255,248,  0
	DEFB	239,112,  1,233,120,  3,192, 60

	DEFB	  1,192, 14,  0,227, 28,  0,119
	DEFB	184,  1,251,126,  0,255,252,  0
	DEFB	119,184,  0,244,188,  1,224, 30

bloques_anima:
	DEFB	  0,  0,127,248,239,188,211, 20
	DEFB	132, 68,128,  4,127,248,  0,  0

	DEFB	  0,  0, 31,254, 59,239, 52,197
	DEFB	 33, 17, 32,  1, 31,254,  0,  0

bloques_ladrillos:
	DEFB	  0,  0,  0, 63,252,  0,119,222
	DEFB	  0,105,138,  0, 66, 34,  0, 64
	DEFB	  2,  0, 63,252,  0,  0,  0,  0

	DEFB	255,254,  0,255,254,  0,255,254
	DEFB	  0,255,254,  0,255,254,  0,255
	DEFB	254,  0,255,254,  0,  0,  0,  0
piedras:
	DEFB	  0,  0,  0, 15,240,  0, 63,252
	DEFB	  0,120,254,  0,119,254,  0,119
	DEFB	252,  0,127,194,  0,127,190,  0
	DEFB	111,126,  0,111,126,  0,111,246
	DEFB	  0,115,246,  0,127,236,  0, 63
	DEFB	248,  0,  6, 48,  0,  0,  0,  0

	DEFB	  0,  0,  0, 15,248,  0, 63,156
	DEFB	  0,127,230,  0,127,250,  0,123
	DEFB	250,  0,125,254,  0, 94,254,  0
	DEFB	110,254,  0,114,238,  0,125, 94
	DEFB	  0,127, 94,  0,127,188,  0, 63
	DEFB	220,  0, 15,208,  0,  0,  0,  0

	DEFB	  0,  0,  0, 31,240,  0, 59,248
	DEFB	  0, 55,228,  0,111,238,  0,111
	DEFB	 30,  0,126,222,  0,127,238,  0
	DEFB	127,238,  0,127,254,  0,120,190
	DEFB	  0,119,126,  0, 55,252,  0, 15
	DEFB	252,  0,  7,240,  0,  0,  0,  0

tela_arana:
	DEFB	175,245,  0, 90, 10,  0,165,212
	DEFB	  0, 74, 34,  0,241,209,  0,153
	DEFB	 79,  0,166,105,  0,169,153,  0
	DEFB	169,229,  0,170,157,  0,172,103
	DEFB	  0,179,201,  0, 72, 50,  0, 39
	DEFB	212,  0, 16,  8,  0, 15,240,  0

arana:
	DEFB	 96,  6, 27,216,  7,224, 63,252
	DEFB	199,227, 11,208, 18, 72, 34, 68

	DEFB	 96,  6, 27,216,  7,224, 31,248
	DEFB	103,230,139,209, 18, 72, 18, 72

gota:
	DEFB	  0,  0,  0,  0,  0, 16,  0, 16
	DEFB	 40, 24, 40, 92, 28, 92, 44, 24

gotasuelo:
	DEFB	  0,  0,  0,  0, 18,128, 41, 32
	DEFB	 23,208, 45, 96,  2,  0,  0,  0

	DEFB	 16,  0, 40,128,  1, 76, 97,150
	DEFB	160,172, 88,  0,  5, 64,  2,128

	DEFB	  0,  0,  8, 32, 16, 80,  0,  0
	DEFB	 48, 24, 81, 20, 34,142,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,  0
	DEFB	  0, 16,  0,  0,  8,  4,  1,  8

gotatecho:
	DEFB	 24,  0,  0,  0,  0,  0,  0,  0
	DEFB	 60, 24,  0,  0,  0,  0,  0,  0
	DEFB	 94, 44, 24,  0,  0,  0,  0,  0
	DEFB	 94, 94, 44, 24,  0,  0,  0,  0
	DEFB	 94, 30, 94, 44, 24,  0,  0,  0
	DEFB	 40, 92, 28, 92, 44, 24,  0,  0
	DEFB	 24, 40, 92, 28, 92, 44, 24,  0
	DEFB	 40, 24, 40, 92, 28, 92, 44, 24

antorchas:
	DEFB	  0,  4,  0,  0,152,  0,  4, 61
	DEFB	  0,  0,122, 32,  1,255,  0,  3
	DEFB	255,128,  7,191,192,  7,255,224
	DEFB	 15, 24,240, 15, 60,240, 15,126
	DEFB	240,  7,255,224,  7,255,224,  3
	DEFB	255,192,  3,126,128,  1, 60,128

	DEFB	  0, 10,  4,  2, 72, 16,  0, 20
	DEFB	 48,  0,177, 32,  3,180,224,  1
	DEFB	231, 72,  3,251,224,  7,255,192
	DEFB	 15, 24,224, 15, 28,240, 15,124
	DEFB	240,  7,254,240,  7,127,224,  3
	DEFB	255,224,  3,126,192,  1, 60,128

porta_antorcha:
	DEFB	  0,255,  0,  0, 60,  0,  0, 24
	DEFB	  0,  0,126,  0,  0, 52,  0,  0
	DEFB	 52,  0,  0, 60,  0,  0, 24,  0

ventana:
	DEFB	  0,  0,  0,253,231,191,253,195
	DEFB	191,253,129,191,  0, 60,  0,220
	DEFB	255, 59,217,195,155,219,129,219

	DEFB	  3,129,192,251,129,223,251,129
	DEFB	223,251,129,223,  3,129,192,219
	DEFB	129,219,219,129,219,219,129,219

	DEFB	  3,129,192,251,129,223,251,129
	DEFB	223,251,129,223,  3,129,192,251
	DEFB	126,223,250,255, 95,249,255,159

escudo:
	DEFB	 31,255,248, 31,129,248, 31,195
	DEFB	248, 31,231,248, 31,231,248, 31
	DEFB	102,248, 31,  0,248, 31,  0,248

	DEFB	 31,102,248, 31,231,248, 31,231
	DEFB	248, 31,231,248, 31,231,248, 31
	DEFB	231,248, 31,195,248, 31,129,248

	DEFB	 31,255,248, 15,255,240,  7,255
	DEFB	224,  3,255,192,  1,255,128,  0
	DEFB	255,  0,  0, 60,  0,  0,  0,  0

puerta_interior:
	DEFB	  0,  0,  0,253,231,191,253,231
	DEFB	191,253,129,191,  0, 60,  0,225
	DEFB	255,135,207,195,243,222,  0,123

	DEFB	 24,  0, 24,216,  0, 27,216,  0
	DEFB	 27,216,  0, 27, 24,  0, 24,216
	DEFB	  0, 27,216,  0, 27,216,  0, 27

	DEFB	 24,  0, 24,216,  0, 27,216,  0
	DEFB	 27,216,  0, 27, 24,  0, 24,216
	DEFB	  0, 27,216,  0, 27,216,  0, 27

puente_madera:
	DEFB	  0,  0,  0,255,255,  0,255,255
	DEFB	  0,  0,  0,  0,  0,255,  0,  0
	DEFB	255,  0,  0,  0,  0,  0,  0,  0
	DEFB	0,0,0,0,0,0,0,0
	DEFB	0,0,0,0,0,0,0,0
	DEFB	0,0,0,0,0,0,0,0

hierba:
	DEFB	 64,128, 37,  9,237,218,255,255
	DEFB	255,255,255,255,255,255,255,255

	DEFB	255,253,237,255,255,239,127,247
	DEFB	255,255,247,125,239,255,255,255

eslabon:
	DEFB	  1,  2, 52,104,196,140, 88, 48

llave:
	DEFB	  0, 28,  0, 62,  0, 99,127,193
	DEFB	255,193,108, 99,108, 62,108, 28

flecha_retorno:
	DEFB	  0, 16,  0, 48,  0,127,  0,255
	DEFB	  0,255,  0,127,  0, 48,  0, 16

	DEFB	  0, 32,  0, 96,  0,254,  1,254
	DEFB	  1,254,  0,254,  0, 96,  0, 32

	DEFB	  0, 64,  0,192,  1,252,  3,252
	DEFB	  3,252,  1,252,  0,192,  0, 64

	DEFB	  0,128,  1,128,  3,248,  7,248
	DEFB	  7,248,  3,248,  1,128,  0,128

	DEFB	  1,  0,  3,  0,  7,240, 15,240
	DEFB	 15,240,  7,240,  3,  0,  1,  0

	DEFB	  2,  0,  6,  0, 15,224, 31,224
	DEFB	 31,224, 15,224,  6,  0,  2,  0

	DEFB	  4,  0, 12,  0, 31,192, 63,192
	DEFB	 63,192, 31,192, 12,  0,  4,  0

bolasde_fuego:
	DEFB	  7,192, 15,224, 31,240, 59,120
	DEFB	 63,216, 52,248, 29, 88, 25,176
	DEFB	  9,160, 40,136,  0,160,  5, 40
	DEFB	  2, 64,  9, 16,  1, 64,  4,  0

	DEFB	  7,192, 15,224, 30,240, 63,120
	DEFB	 63,248, 46,232, 31, 80, 29,180
	DEFB	  8,160, 36, 72,  0, 64,  5, 72
	DEFB	  4,  0, 72, 18,  0,128,  8, 32

	DEFB	  4,  0,  1, 64,  9, 16,  2, 64
	DEFB	  5, 40,  0,160, 44,200,  9,160
	DEFB	 25,176, 29, 88, 52,248, 63,248
	DEFB	 63,120, 31,240, 15,224,  7,192

	DEFB	  8, 32,  0,128, 72, 18,  4,  0
	DEFB	  5, 72,  0, 64, 36, 72,  8,160
	DEFB	 29,180, 31, 80, 46,232, 63,248
	DEFB	 63,120, 30,240, 15,224,  7,192

flechas_dcha:
	DEFB	  0,  0,  0,  0,  0,  0, 96,  4
	DEFB	  0,112,  6,  0,143,251,  0,112
	DEFB	  6,  0, 96,  4,  0,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0, 48,  2
	DEFB	  0, 56,  3,  0, 71,253,128, 56
	DEFB	  3,  0, 48,  2,  0,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0, 24,  1
	DEFB	  0, 28,  1,128, 35,254,192, 28
	DEFB	  1,128, 24,  1,  0,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0, 12,  0
	DEFB	128, 14,  0,192, 17,255, 96, 14
	DEFB	  0,192, 12,  0,128,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  6,  0
	DEFB	 64,  7,  0, 96,  8,255,176,  7
	DEFB	  0, 96,  6,  0, 64,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  3,  0
	DEFB	 32,  3,128, 48,  4,127,216,  3
	DEFB	128, 48,  3,  0, 32,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  1,128
	DEFB	 16,  1,192, 24,  2, 63,236,  1
	DEFB	192, 24,  1,128, 16,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,192
	DEFB	  8,  0,224, 12,  1, 31,246,  0
	DEFB	224, 12,  0,192,  8,  0,  0,  0

flechas_izda:
	DEFB	  0,  0,  0,  0,  0,  0,  0, 32
	DEFB	  6,  0, 96, 14,  0,223,241,  0
	DEFB	 96, 14,  0, 32,  6,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0, 64
	DEFB	 12,  0,192, 28,  1,191,226,  0
	DEFB	192, 28,  0, 64, 12,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  0,128
	DEFB	 24,  1,128, 56,  3,127,196,  1
	DEFB	128, 56,  0,128, 24,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  1,  0
	DEFB	 48,  3,  0,112,  6,255,136,  3
	DEFB	  0,112,  1,  0, 48,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  2,  0
	DEFB	 96,  6,  0,224, 13,255, 16,  6
	DEFB	  0,224,  2,  0, 96,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  4,  0
	DEFB	192, 12,  1,192, 27,254, 32, 12
	DEFB	  1,192,  4,  0,192,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0,  8,  1
	DEFB	128, 24,  3,128, 55,252, 64, 24
	DEFB	  3,128,  8,  1,128,  0,  0,  0

	DEFB	  0,  0,  0,  0,  0,  0, 16,  3
	DEFB	  0, 48,  7,  0,111,248,128, 48
	DEFB	  7,  0, 16,  3,  0,  0,  0,  0

flechas_updown:
	DEFB	 16,108,108, 40, 16, 16, 16, 16
	DEFB	 16, 16, 16, 16, 16,108, 56, 16

	DEFB	 16, 56,108, 16, 16, 16, 16, 16
	DEFB	 16, 16, 16, 16, 40,108,108, 16

;--------------------- $24 / 36 Estrellas ------------------------------------
estrellas:						
defb	$42,$4f,2,$47,$67,8,$4a,$83,64,$55,$10,32,$50,$14,32,$4f,$28,1
defb	$56,$05,4,$40,$a0,32,$44,$3b,64,$46,$39,32,$49,$ed,16,$4d,$eb,32
defb	$46,$c2,16,$53,$11,16,$40,$67,8,$43,$98,4,$46,$0f,2,$54,$47,36
defb	$4b,$09,16,$4f,$0c,32,$41,$e4,64,$45,$28,32,$50,$04,8,$4e,$6d,4
defb	$49,$32,32,$44,$88,64,$43,$c6,16,$53,$11,8,$4a,$29,64,$4b,$06,16
defb	$4e,$87,128,$47,$68,16,$45,$72,32,$42,$91,64,$55,$0b,8,$57,$2c,32

;-----------------------------------------------------------------------------
velocidad	defb $02	; Velocidad del juego (RAPIDO) 1,2,3...(LENTO)
vidas		defb $0f	; Vidas del Jugador (3 por defecto)
nivel		defb $00	; Nivel actual (Para saber Partes redibujables)

contador_it	defb $00	; Contador General Iteraciones Bucle
anima_antorchas	defb $20	; Animacion (que toca) antorchas

jugador_y	defb $50	; Coordenada Y, 'H' del Jugador
jugador_x	defb $84	; Coordenada X, 'L' (hl) del Jugador
rota_jugador	defb $00	; Rotacion (que toca) del Jugador (1,2,3...)
anima_jugador 	defb $00	; Animacion (que toca) del Jugador (1,2,3...)
rota_entrepuert defb $00	; Rotacion (que toca) cuando Entre-Puertas
cont_explo_jug	defb $00	; Contador de la Explo-Jugador
jugador_set	defb $00	; Settings del Jugador (Bits utilizados)...
; Bit0 = 0/1 Derecha/Izquierda         ...  Bit1 = 0/1 En pie/Agachado
; Bit2 = 0/1 Entre-Puertas OFF/ON      ...  Bit3 = 0/1 (***Salto OFF/ON***)
; Bit4 = 0/1 OFF/ Ataque-Espada ON     ...  Bit5 = 0/1 Agachado-flecha OFF/ON
; Bit6 = 0/1 Vida menos OFF/ON         ...  Bit7 = 0/1

flechatrap_y	defb $00	; Coordenada Y de la Flecha-Trampa
flechatrap_x	defb $00	; Coordenada X de la Flecha-Trampa
flecha_y:	defb $00	; Coordenada Y de la flecha
flecha_x:	defb $00	; Coordenada X de la flecha
rota_flecha:	defb $00	; Rotacion (que toca) de la flecha
contador_flecha defb $00	; Contador Flechas (Rapida/Lenta)

explo_arqueroy	defb $00	; Coordenada Y de la Explo-Arquero
explo_arquerox	defb $00	; Coordenada X de la Explo-Arquero
contador_explo	defb $00	; Contador de la Explo-Arquero

murcielago_y:	defb $00	; Coordenada Y del Murcielago
murcielago_x:	defb $00	; Coordenada X del Murcielago
rota_murcielago	defb $00	; Rotacion (que toca) del Murcielago
cont_murcielago defb $0a	; Contador (animacion) del Murcielago

fantasma_y:	defb $00	; Coordenada Y del Fantasma
fantasma_x:	defb $00	; Coordenada X del Fantasma
rota_fantasma:	defb $00	; Rotacion (que toca) del Fantasma
cont_fantasma:	defb $0a	; Contador (animacion) del Fantasma
explo_fantasmay defb $00	; Coordenada Y de la Explo-Fantasma
explo_fantasmax defb $00	; Coordenada X de la Explo-Fantasma
fantasma2_y	defb $00	; Coordenada Y del 2do Fantasma

fantasma2_x	defb $00	; Coordenada X del 2do Fantasma

rota_fantasma2	defb $00	; Rotacion (que toca) del 2do Fantasma
cont_fantasma2	defb $0a	; Contador (animacion) del 2do Fantasma

cont_bloque_t	defb $14	; Contador (Regresivo) Bloque Trampa
bloquet_y	defb $00	; Coordenada Y del Bloque Trampa
bloquet_x	defb $00	; Coordenada X del Bloque Trampa

gota_y		defb $00	; Coordenada Y de la Gota
gota_x		defb $00	; Coordenada X de la Gota
cont_gota	defb $00	; Contador Frames Gota-Suelo
cont_halt	defb $0a	; Contador Ralentizador Gota-Suelo

gota2_y		defb $00	; Coordenada Y de la Gota2
gota2_x		defb $00	; Coordenada X de la Gota2
cont_gota2	defb $00	; Contador Frames Gota-Suelo2
cont_halt2	defb $0a	; Contador Ralentizador Gota-Suelo2

arana_y		defb $00	; Coordenada Y de la Arana
arana_x		defb $00	; Coordenada X de la Arana
cont_arana	defb $00	; Contador Arana (Animacion)

rota_indicador	defb $01	; Rotacion de la Flecha Indicadora
indica_halt	defb $07	; Contador Ralentizador Flecha Indicadora
		
pausa_i		defb $59	; Pausa Inicial (Preparado)...
soni_disp	defw $0f07	; Sonido del Disparo
settings	defb $00	; Bits utilizados (Todos)	 
; Bit0 = 0/1 Siguiente Nivel (adelante)   ...   Bit1 = 0/1 Nivel Anterior (atras)
; Bit2 = 0/1 Explo-Arquero OFF/ON         ...   Bit3 = 0/1 Trampa Activada OFF/ON
; Bit4 = 0/1 Flecha Arquero OFF/ON        ...   Bit5 = 0/1 Arquero OFF/ON
; Bit6 = 0/1 Arquero APUNTANDO OFF/ON	  ...   Bit7 = 0/1 Aparece-Puerta OFF/ON

settings2:	defb $00	; Bits utilizados ()
; Bit0 = 0/1 Murcielago OFF/ON            ...   Bit1 = 0/1 Fantasma OFF/ON	
; Bit2 = 0/1 Explo-Fantasma OFF/ON        ...   Bit3 = 0/1 Trampa(Rapida) Activada OFF/ON 
; Bit4 = 0/1 Animacion Bloque Tr. OFF/ON  ...   Bit5 = 0/1 Fantasma (Izda-->Dcha) OFF/ON
; Bit6 = 0/1 Explo-Fantasma II OFF/ON     ...   Bit7 = 0/1 

settings3:	defb $00	; bits utilizados ()
; Bit0 = 0/1 GotaSuelo OFF/ON             ...   Bit1 = 0/1 CaeGota OFF/ON
; Bit2 = 0/1 GotaTecho OFF/ON		  ...   Bit3 = 0/1 Ini-Gota por 1ra vez OFF/ON
; Bit4 = 0/1 GotaSuelo(2) OFF/ON	  ...   Bit5 = 0/1 CaeGota(2) OFF/ON
; Bit6 = 0/1 GotaTecho(2) OFF/ON          ...   Bit7 = 0/1 Ini-Gota(2) por 1ra vez OFF/ON

settings4:	defb $00	; bits utilizados ()
; Bit0 = 0/1 Need Key OFF/ON              ...   Bit1 = 0/1 Tener LLave OFF/ON
; Bit2 = 0/1 Dibuja Suelo/Techo           ...   Bit3 = 0/1 Arana OFF/ON
; Bit4 = 0/1 Arana Arriba/Abajo           ...   Bit5 = 0/1 Explo-Arana OFF/ON

settings_ch:	defb $00	; bits utilizados ()
; Bit0 = 0/1 Cheat LevelUp OFF/ON         ...   Bit2 = 0/1

bolas_fuego:
defb	$55,$6c,$00,$00
defb	$52,$11,$00,$00
defb	$50,$36,$00,$00
defb	$55,$7b,$00,$00
 
msg_game_over:
defm ' G A M E  O V E R ',$00

msg_needkey:
defm ' <- Necesitas Llave! ',00


