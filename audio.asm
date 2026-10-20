;===========================================================================
;
;				S O N I D O S
;
;  call sonido con A = numero de sonido (SND_xxx en const.asm, 1..7).
;  Usa la rutina BEEPER de la ROM ($03b5: HL = nota, DE = duracion),
;  que detiene el juego mientras suena (pendiente para la v2).
;
;  Conserva todos los registros salvo AF, y sale con A = 0 (como el
;  original). Un numero de sonido no valido no hace nada.
;===========================================================================
sonido:
	or	a
	ret	z				;Sonido 0: no valido
	cp	NUM_SONIDOS + 1
	ret	nc				;Sonido > 7: no valido

	push	de
	push	hl

	;------------------------------------------ HL = nota, DE = duracion
	dec	a
	add	a,a
	add	a,a				;4 bytes por sonido
	ld	e,a
	ld	d,$00
	ld	hl,tabla_sonidos
	add	hl,de

	ld	e,(hl)
	inc	hl
	ld	d,(hl)				;DE = nota
	inc	hl
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a				;HL = duracion
	ex	de,hl				;HL = nota, DE = duracion

	;------------------------------------------ (A = 0 y flags de 'dec a')
	ld	a,$01
	dec	a

	push	af
	push	bc
	push	ix
	call	beeper				;ROM: altera AF, BC, DE, HL, IX
	pop	ix
	pop	bc
	pop	af

	pop	hl
	pop	de
	ret

;---------------------------------------------------------------------------
; Nota y duracion de cada sonido (en el orden de SND_xxx)
;---------------------------------------------------------------------------
NUM_SONIDOS	equ	7

tabla_sonidos:
	defw	s_2, s2_dura / $05		;1 SND_PALA
	defw	s_3, s3_dura / $05		;2 SND_REBOTE
	defw	s_1, s1_dura / $10		;3 SND_DISPARO (vida menos, espada)
	defw	s_4, s4_dura			;4 SND_PULSA_MENUS
	defw	s_5, s5_dura			;5 SND_PAJARO
	defw	s_6, s6_dura			;6 SND_BEEP
	defw	s_7, s7_dura			;7 SND_LASER
