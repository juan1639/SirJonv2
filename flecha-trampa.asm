;===========================================================================
;
;			F L E C H A - T R A M P A
;
;  Al pisar el ladrillo-trampa cae una flecha desde el techo (sprite
;  'flechas_updown', 1 byte x 16 scanlines). Se alternan dos tipos:
;
;     lenta  (settings  bit3): baja 1 scanline por fotograma
;     rapida (settings2 bit3): baja 1 fila (8 scanlines) por fotograma
;
;  Al llegar al suelo se queda clavada (settings4 bit7) hasta que
;  borra_flechatrampa1 la quita.
;
;  Aqui esta tambien colision_proyectil, que usan todas las flechas y las
;  gotas, y dibuja_flechatrampa, que tambien dibuja las gotas.
;===========================================================================

;===========================================================================
;	INICIA FLECHA-TRAMPA
;---------------------------------------------------------------------------
inicia_flechatrampa1:
	ld	a,(settings)
	bit	3,a
	ret	nz				;Ya hay una flecha lenta

	ld	a,(settings2)
	bit	3,a
	ret	nz				;Ya hay una flecha rapida

	call	inicia_animacion_bloquetrampa

	;------------------------------------------ Alterna lenta / rapida
	ld	a,(contador_flecha)
	inc	a
	ld	(contador_flecha),a
	bit	0,a
	jr	z,inicia_lenta

	ld	a,(settings2)
	set	3,a				;Rapida
	ld	(settings2),a
	jr	inicia_flecha_posicion

inicia_lenta:
	ld	a,(settings)
	set	3,a				;Lenta
	ld	(settings),a

	;------------------------------------------ Posicion inicial
	; Sale 3 columnas a la derecha del jugador:
	;   pantalla 1 ........ tercio 1, una fila POR DEBAJO del jugador (X+$20)
	;   pantallas 2,5,6,14  tercio 2, una fila POR ENCIMA del jugador (X-$20)
inicia_flecha_posicion:
	ld	a,SND_PALA
	call	sonido

	ld	a,(nivel)
	cp	NIVEL_DOS_PISOS_A
	jr	nz,flecha_desde_tercio2

	ld	a,$40
	ld	(flechatrap_y),a

	ld	a,(jugador_x)
	add	a,$03 + $20
	ld	(flechatrap_x),a
	ret

flecha_desde_tercio2:
	ld	a,$48
	ld	(flechatrap_y),a

	ld	a,(jugador_x)
	add	a,$03 - $20
	ld	(flechatrap_x),a
	ret

;---------------------------------------------------------------------------
; Pantalla 1, piso de arriba: la trampa esta en X = $d9
; (solo hasta que se ha pasado de pantalla; settings2 bit7)
;---------------------------------------------------------------------------
compruebatb_lal:
	ld	a,(jugador_x)
	cp	$d9
	ret	nz

	ld	a,(settings2)
	bit	7,a
	ret	nz
	jr	inicia_flechatrampa1

;===========================================================================
;	MUEVE LA FLECHA-TRAMPA LENTA (1 scanline)
;---------------------------------------------------------------------------
flecha_trampa1:
	call	flechatrampa_posicion

	ld	a,(jugador_set)
	bit	6,a				;Si el jugador ya explota...
	call	z,colisiones_3_columnas	;...no se comprueba

	ld	(hl),$00			;Borra SOLO el 1er scanline (autoborrado)
	ld	de,flechas_updown
	call	incrementar_scanline
	jr	flechatrampa_actualiza

;===========================================================================
;	MUEVE LA FLECHA-TRAMPA RAPIDA (1 fila)
;---------------------------------------------------------------------------
flecha_trampa1_rapida:
	call	flechatrampa_posicion

	ld	a,(jugador_set)
	bit	6,a				;Si el jugador ya explota...
	call	z,colisiones_3_columnas		;...no se comprueba

	ld	b,$10

bucle_borraflechatrampa_rapida:
	ld	(hl),$00			;Borra la flecha entera
	call	incrementar_scanline
	djnz	bucle_borraflechatrampa_rapida

	ld	de,flechas_updown

	ld	a,(flechatrap_y)
	add	a,$08				;incrementar_solofila resta 8 a H
	ld	h,a
	ld	a,(flechatrap_x)
	ld	l,a

	call	incrementar_solofila
	; (sigue en flechatrampa_actualiza)

;---------------------------------------------------------------------------
; Guarda la nueva posicion, comprueba si ha llegado, dibuja y repone
; los atributos del ladrillo-trampa
;---------------------------------------------------------------------------
flechatrampa_actualiza:
	ld	a,l
	ld	(flechatrap_x),a
	ld	a,h
	ld	(flechatrap_y),a

	cp	$48				;Tercio 2?
	call	z,fin_flechatrampa_piso_alto

	ld	a,(flechatrap_y)
	cp	$50				;Tercio 3?
	call	z,fin_flechatrampa_suelo

	call	dibuja_flechatrampa

	ld	a,(jugador_y)
	cp	JUGADOR_Y_PISO_ALTO
	jr	z,re_attr_flecha48
	cp	JUGADOR_Y_SUELO
	ret	nz

;---------------------------------------------------
re_attr_flecha50:
	ld 	h,$5a
	ld	l,$8c
	ld	(hl),AMARILLO
	ld	l,$ac
	ld	(hl),AMARILLO
	ret

re_attr_flecha48:
	ld 	h,$59
	ld	l,$dc
	ld	(hl),AMARILLO
	ld	l,$fc
	ld	(hl),AMARILLO
	ret

;---------------------------------------------------------------------------
; HL = posicion de la flecha, C = X + $20 (fila de abajo, para colisiones)
;---------------------------------------------------------------------------
flechatrampa_posicion:
	ld	a,(flechatrap_y)
	ld	h,a
	ld	a,(flechatrap_x)
	ld	l,a
	add	a,$20
	ld	c,a
	ret

;---------------------------------------------------------------------------
; Llega al suelo (tercio 3, filas $8x / $9x): se queda clavada
;---------------------------------------------------------------------------
fin_flechatrampa_suelo:
	ld	a,(flechatrap_x)
	and	%11110000
	cp	$80
	jr	z,flechatrampa_clavada
	cp	$90
	ret	nz

flechatrampa_clavada:
	call	flechatrampa_off

	ld	a,(settings4)
	set	7,a				;Flecha clavada en el suelo
	ld	(settings4),a
	ret

;---------------------------------------------------------------------------
; Pantalla 1: la del piso de arriba termina en las filas $dx del tercio 2
;---------------------------------------------------------------------------
fin_flechatrampa_piso_alto:
	ld	a,(nivel)
	cp	NIVEL_DOS_PISOS_A
	ret	nz

	ld	a,(flechatrap_x)
	and	%11110000
	cp	$d0
	ret	nz
	; (sigue en flechatrampa_off)

flechatrampa_off:
	ld	a,(settings)
	res	3,a				;Lenta OFF
	ld	(settings),a

	ld	a,(settings2)
	res	3,a				;Rapida OFF
	ld	(settings2),a
	ret

;===========================================================================
;	BORRA LA FLECHA-TRAMPA CLAVADA EN EL SUELO
;---------------------------------------------------------------------------
borra_flechatrampa1:
	ld	a,(settings)
	bit	3,a
	ret	nz				;Hay una flecha cayendo

	ld	a,(settings2)
	bit	3,a
	ret	nz

	ld	a,(settings4)
	bit	7,a
	ret	z				;No hay flecha clavada

	res	7,a
	ld	(settings4),a

	ld	h,$50
	ld	a,(flechatrap_x)
	ld	l,a

	ld	b,$10

bucle_borra_flechatrampa1:
	ld	(hl),$00
	call	incrementar_scanline
	djnz	bucle_borra_flechatrampa1
	ret

;===========================================================================
;	C O L I S I O N E S   C O N   E L   J U G A D O R
;
;  Todos los enemigos comprueban la colision igual: si su columna (C)
;  coincide con alguna de las columnas del jugador, se llama a una de
;  estas rutinas con HL = posicion del enemigo:
;
;   colision_proyectil ..... misma altura (H AND $f0) y no en el tercio 1
;                            (flechas, gotas, arana, bolas de fuego)
;   colision_misma_altura .. solo misma altura (murcielago, pinchos)
;
;  Si el jugador es invisible, o esta en lo alto de un salto, no hay
;  colision.
;  Salida: Carry = 1 si ha habido colision (jugador muere).
;  OJO: si el jugador no es invisible, C se pierde (C = H AND $f0), igual
;  que en el original; por eso, tras un impacto, ninguna otra columna
;  vuelve a coincidir.
;===========================================================================
colision_proyectil:
	call	colision_comprueba_altura
	jr	nz,sin_colision
	ld	a,h
	cp	$48
	jr	c,sin_colision			;Tercio 1: no hay colision
	jr	jugador_muere

colision_misma_altura:
	call	colision_comprueba_altura
	jr	nz,sin_colision
	; (sigue en jugador_muere)

;---------------------------------------------------------------------------
; JUGADOR MUERE: sonido, empieza la explosion del jugador. Carry = 1
;---------------------------------------------------------------------------
jugador_muere:
	ld	a,SND_DISPARO
	call	sonido

	xor	a
	ld	(cont_explo_jug),a
	ld	(salto_paso),a			;Si estaba saltando, cae al suelo
	ld	(salto_altura),a
	ld	(caida_paso),a

	ld	a,(jugador_set)
	set	6,a				;Vida menos ON
	ld	(jugador_set),a

	scf
	ret

sin_colision:
	or	a				;Carry = 0
	ret

;---------------------------------------------------------------------------
; Z si el jugador no es invisible y esta a la altura de H.  C = H AND $f0
;---------------------------------------------------------------------------
colision_comprueba_altura:
	ld	a,(jugador_timer_invisib)
	or	a
	ret	nz				;Invisible

	ld	a,(salto_altura)
	cp	SALTO_ESQUIVA
	jr	c,colision_en_el_suelo
	or	a				;Saltando alto: lo esquiva (NZ)
	ret

colision_en_el_suelo:

	ld	a,h
	and	%11110000
	ld	c,a

	ld	a,(jugador_y)
	and	%11110000
	cp	c
	ret

;---------------------------------------------------------------------------
; COLISIONES COLUMNAS: compara las columnas E, E+1 ... (B columnas) con C
;   D = 0 -> colision_proyectil, D <> 0 -> colision_misma_altura
;   Altera: A, B, C, E
;---------------------------------------------------------------------------
colisiones_columnas:
	ld	a,e
	cp	c
	call	z,colision_segun_tipo
	inc	e
	djnz	colisiones_columnas
	ret

colision_segun_tipo:
	ld	a,d
	or	a
	jr	z,colision_proyectil
	jr	colision_misma_altura

;---------------------------------------------------------------------------
; Colision con las 3 columnas del jugador (jugador_x .. +2), proyectil
;---------------------------------------------------------------------------
colisiones_3_columnas:
	ld	a,(jugador_x)
	ld	e,a
	ld	b,$03
	ld	d,$00
	jr	colisiones_columnas

;---------------------------------------------------------------------------
; Colision con 4 columnas (jugador_x - 1 .. +2), proyectil
;---------------------------------------------------------------------------
colisiones_4_columnas:
	ld	a,(jugador_x)
	dec	a
	ld	e,a
	ld	b,$04
	ld	d,$00
	jr	colisiones_columnas

;===========================================================================
;	DIBUJA FLECHA-TRAMPA (o gota):  16 bytes desde DE en HL
;---------------------------------------------------------------------------
dibuja_flechatrampa:
	ld	b,$10

bucle_flechatrampa1:
	ld	a,(de)
	ld	(hl),a
	call	incrementar_scanline
	inc	de
	djnz	bucle_flechatrampa1
	ret
