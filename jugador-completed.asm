;===========================================================================
;
;		J U G A D O R   ( J U E G O   C O M P L E T A D O )
;
;  Caballero grande (4 bytes x 24 scanlines, 'caballero_game_completed')
;  una fila por encima de la posicion del jugador, con sus atributos:
;  2 filas ROJO_BRILLO (cabeza) y 1 AZULCLARO_BRILLO (cuerpo).
;===========================================================================
dibuja_jugador_game_completed:
	ld	a,(jugador_y)
	ld	h,a
	ld	a,(jugador_x)
	sub	$20				;Una fila mas arriba
	ld	l,a

	ld	de,caballero_game_completed
	ld	b,$18

bucle_dibuja_caballero_gc:
	call	dibujados_repetitivos		;bytes 1 y 2
	call	dibujados_repetitivos2		;bytes 3 y 4

	dec	l
	dec	l
	dec	l

	call	incrementar_scanline
	inc	de
	djnz	bucle_dibuja_caballero_gc

	;------------------------------------------ Atributos (de abajo arriba)
	ld	a,h
	sub	$08
	call	cambioh_58595a
	ld	h,a

	ld	a,l
	sub	$20
	ld	l,a
	ld	a,AZULCLARO_BRILLO		;Cuerpo
	call	attr_fila_jugador

	ld	a,l
	sub	$20
	ld	l,a
	ld	a,ROJO_BRILLO			;Cabeza
	call	attr_fila_jugador

	ld	a,l
	sub	$20
	ld	l,a
	ld	a,ROJO_BRILLO
	jp	attr_fila_jugador
