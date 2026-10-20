;===========================================================================
;
;		A N I M A C I O N   D E L   L A D R I L L O - T R A M P A
;
;  Al pisar el ladrillo-trampa, el ladrillo de debajo del jugador se
;  "mueve" durante 20 fotogramas (2 fotogramas de 'bloques_anima') y
;  luego se vuelve a dibujar el ladrillo normal.
;
;  settings2 bit4 = animacion en marcha
;===========================================================================

;---------------------------------------------------------------------------
inicia_animacion_bloquetrampa:
	ld	a,(settings2)
	bit	4,a
	ret	nz				;Ya esta en marcha

	set	4,a
	ld	(settings2),a

	ld	a,$14				;20 fotogramas
	ld	(cont_bloque_t),a

	ld	a,(jugador_y)			;El ladrillo esta en el tercio
	cp	JUGADOR_Y_PISO_ALTO		;del jugador (o en el 3 si el
	jr	nz,bloque_guarda_y		;jugador esta en el piso alto)
	ld	a,$50
bloque_guarda_y:
	ld	(bloquet_y),a

	ld	a,(jugador_x)
	add	a,$41				;2 filas mas abajo, 1 columna a la dcha
	ld	(bloquet_x),a
	ret

;---------------------------------------------------------------------------
animacion_bloquetrampa:
	ld	a,(cont_bloque_t)
	dec	a
	ld	(cont_bloque_t),a
	jr	z,fin_animabloquet

	ld	de,bloques_anima		;Fotograma 1 (contador >= 10)...
	cp	$0a
	jr	nc,anima_bloque_dibuja
	ld	de,bloques_anima+16		;...o fotograma 2

anima_bloque_dibuja:
	call	bloque_trampa_hl

	ld	b,$08

bucle_anima_bloquet:
	call	dibujados_repetitivos
	dec	l
	inc	h
	inc	de
	djnz	bucle_anima_bloquet
	ret

;--------------------------------------------------------
; Fin: vuelve a dibujar el ladrillo normal
;--------------------------------------------------------
fin_animabloquet:
	ld	a,(settings2)
	res	4,a
	ld	(settings2),a

	call	bloque_trampa_hl
	ld	b,$01
	ld	c,$02
	jp	dibuja_ladrillos

;--------------------------------------------------------
bloque_trampa_hl:
	ld	a,(bloquet_y)
	ld	h,a
	ld	a,(bloquet_x)
	ld	l,a
	ret
