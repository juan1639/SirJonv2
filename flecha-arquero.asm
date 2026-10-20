;===========================================================================
;
;		    F L E C H A   D E L   A R Q U E R O
;
;  Una flecha que entra por la derecha (en el suelo, tercio 3) y va
;  hacia la izquierda hasta FLECHA_ARQU_END_POS_X.
;
;  Sprite 'flechas_izda': 3 bytes x 8 scanlines, 8 rotaciones de 24 bytes.
;  Cada 8 rotaciones avanza un byte. En las pantallas 16-19 va siempre en
;  la rotacion 7, es decir, avanza un byte por fotograma (flecha rapida).
;
;  settings bit4 = flecha activa
;  settings bit5 = 0 -> el arquero esta vivo (OJO: al reves)
;===========================================================================

;===========================================================================
;	INICIA FLECHA ARQUERO
;
;  Pantallas 1, 7 y 19 (las que tienen arquero en el suelo): solo dispara
;  si estas en el suelo y el arquero esta vivo; en la 7 ademas si no
;  tienes la llave. En el resto de pantallas dispara siempre.
;---------------------------------------------------------------------------
inicia_flecha_arquerozero:
	ld	a,(nivel)
	cp	NIVEL_DOS_PISOS_A
	jr	z,pantalla_con_arquero
	cp	NIVEL_DOS_PISOS_B
	jr	z,pantalla_con_arquero
	cp	NIVEL_ULTIMO
	jr	nz,pantalla_sin_arquero

pantalla_con_arquero:
	ld	a,(jugador_y)
	cp	JUGADOR_Y_SUELO
	ret	nz				;Solo si estas en el suelo...

	ld	a,(nivel)
	cp	NIVEL_DOS_PISOS_B
	jr	nz,comprueba_arquero_vivo

	ld	a,(settings4)
	bit	1,a				;...en la 7, sin la llave...
	ret	nz

comprueba_arquero_vivo:
	ld	a,(settings)
	bit	5,a				;...y si el arquero sigue vivo
	ret	nz

pantalla_sin_arquero:
	ld	a,(settings)
	bit	4,a
	ret	nz				;Ya hay una flecha

	set	4,a				;Flecha ON
	ld	(settings),a

	ld	a,$50
	ld	(flecha_y),a			;Tercio 3

	;----------------------------------- X inicial y sonido segun pantalla
	ld	a,(nivel)
	cp	NIVEL_DOS_PISOS_A
	jr	z,flecha_desde_arquero
	cp	NIVEL_DOS_PISOS_B
	jr	z,flecha_desde_arquero
	cp	NIVEL_ULTIMO
	jr	z,flecha_desde_arquero

	cp	16				;Pantallas 16, 17 y 18: con 'beep'
	jr	c,flecha_desde_borde

	ld	a,SND_BEEP
	call	sonido

flecha_desde_borde:
	ld	a,$9d				;Sale del borde derecho
	ld	(flecha_x),a
	ret

flecha_desde_arquero:
	ld	a,SND_PALA
	call	sonido

	ld	a,$99				;Sale de delante del arquero
	ld	(flecha_x),a
	ret

;===========================================================================
;	MUEVE / DIBUJA LA FLECHA DEL ARQUERO
;---------------------------------------------------------------------------
flecha_arquerozero:
	ld	a,(flecha_y)
	ld	h,a
	ld	a,(flecha_x)
	ld	l,a
	ld	c,a				;C = X (para las colisiones)

	;------------------------------------------ Colision con el jugador
	; (no si ya explota, si esta agachado o si no esta en el suelo)
	ld	a,(jugador_set)
	bit	6,a
	jr	nz,flecha_arquero_dibuja
	bit	1,a
	jr	nz,flecha_arquero_dibuja

	ld	a,(jugador_y)
	cp	JUGADOR_Y_SUELO
	jr	nz,flecha_arquero_dibuja

	call	colisiones_3_columnas

	ld	a,(jugador_set)
	bit	6,a				;Nos ha dado?
	jr	nz,flecha_arquero_impacto

	;------------------------------------------ Dibuja
flecha_arquero_dibuja:
	ld	de,flechas_izda

	ld	a,(nivel)
	cp	16				;Pantallas 16-19: flecha rapida
	jr	c,flecha_arquero_rotacion

	ld	a,$07
	ld	(rota_flecha),a

flecha_arquero_rotacion:
	ld	a,(rota_flecha)
	ld	b,a
	add	a,a
	add	a,b				;x3
	add	a,a
	add	a,a
	add	a,a				;x24 bytes por rotacion
	call	suma_a_de

	ld	b,$08

bucle_flecha_arquerozero:
	call	dibujados_repetitivos		;bytes 1 y 2

	inc	l
	inc	de
	ld	a,(de)				;byte 3
	ld	(hl),a

	dec	l
	dec	l
	inc	h
	inc	de
	djnz	bucle_flecha_arquerozero

	;------------------------------------------ Atributos (rojo brillo)
	push	hl
	ld	h,$5a
	ld	(hl),ROJO_BRILLO
	inc	l
	ld	(hl),ROJO_BRILLO
	inc	l
	ld	(hl),ROJO_BRILLO
	pop	hl

	;------------------------------------------ Siguiente rotacion
	ld	a,(rota_flecha)
	inc	a
	ld	(rota_flecha),a
	cp	$08
	ret	nz

	xor	a
	ld	(rota_flecha),a

	;------------------------------------------ Avanza un byte:
	; borra el byte que queda atras (solo el scanline 4, el del asta)
	ld	a,h
	sub	$04				;H = scanline 4 del caracter
	ld	h,a
	inc	l
	inc	l
	ld	(hl),$00
	dec	l
	dec	l

	dec	l				;X - 1
	ld	a,l
	ld	(flecha_x),a
	cp	FLECHA_ARQU_END_POS_X
	ret	nz				;Aun no ha llegado al final

	;------------------------------------------ Fin del recorrido
	ld	h,$50
	ld	l,FLECHA_ARQU_ULTIMO_BORRADO_POS_X
	jr	borra_flecha_arquero

	;------------------------------------------ Ha dado al jugador
flecha_arquero_impacto:
	inc	l

borra_flecha_arquero:
	ld	b,$07				;(el 8o scanline no hace falta)

bucle_borra_flecha_arquero:
	ld	(hl),$00
	inc	l
	ld	(hl),$00
	dec	l
	inc	h
	djnz 	bucle_borra_flecha_arquero

	ld	a,(settings)
	res	4,a				;Flecha OFF
	ld	(settings),a
	ret
