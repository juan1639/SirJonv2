;===========================================================================
;
;		T E X T O   " 1 U P "   ( V I D A   E X T R A )
;
;  Al ganar una vida extra aparece "1UP" (3 x 8) encima del jugador,
;  parpadeando (blanco / blanco brillo) durante $99 fotogramas.
;  settings_ch bit2 = texto en pantalla
;===========================================================================
SHOW1UP_DURACION	equ	$99

;---------------------------------------------------------------------------
sub_inicia_show_1up:
	ld	a,(jugador_y)
	ld	(show1up_y),a

	ld	a,(jugador_x)
	sub	$44				;2 filas arriba, 4 columnas a la izda
	ld	(show1up_x),a

	ld	a,(settings_ch)
	set	2,a
	ld	(settings_ch),a

	ld	a,SHOW1UP_DURACION
	ld	(cont_show1up),a
	ret

;---------------------------------------------------------------------------
dibuja_show1up:
	call	show1up_hl

	ld	de,up1_tipografia_med
	ld	b,$08

bucle_dibuja_show1up:
	call	dibujados_repetitivos		;bytes 1 y 2

	inc	l
	inc	de
	ld	a,(de)				;byte 3
	ld	(hl),a

	dec	l
	dec	l
	inc	de
	inc	h
	djnz	bucle_dibuja_show1up

	;------------------------------------------ Atributos: parpadeo
	ld	a,h
	sub	$08
	call	cambioh_58595a
	ld	h,a

	ld	a,BLANCO			;Fotogramas pares: blanco...
	ld	c,a
	ld	a,(contador_it)
	bit	0,a
	jr	z,show1up_attr
	ld	c,BLANCO_BRILLO			;...impares: blanco brillo

show1up_attr:
	ld	(hl),c
	inc	l
	ld	(hl),c
	inc	l
	ld	(hl),c

	;------------------------------------------ Duracion
	ld	a,(cont_show1up)
	dec	a
	ld	(cont_show1up),a

	cp	SHOW1UP_DURACION - 10		;Un pitido al poco de salir
	jr	nz,show1up_comprueba_fin

	ld	a,SND_PAJARO
	call	sonido

show1up_comprueba_fin:
	ld	a,(cont_show1up)
	or	a
	ret	nz

	;------------------------------------------ Fin: lo borra
	ld	a,(settings_ch)
	res	2,a
	ld	(settings_ch),a

	call	show1up_hl
	ld	b,$08

bucle_borrado_final_show1up:
	call	borrados_repetitivos
	inc	l
	ld	(hl),$00
	dec	l
	dec	l
	inc	h
	djnz	bucle_borrado_final_show1up
	ret

;---------------------------------------------------------------------------
show1up_hl:
	ld	a,(show1up_y)
	ld	h,a
	ld	a,(show1up_x)
	ld	l,a
	ret
