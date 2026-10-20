;===========================================================================
;
;				M U S I C A
;
;  Melodias con el BEEPER de la ROM. Cada nota: defw nota, duracion
;  (los mismos valores que espera beeper: HL = 437500 / f - 30,
;   DE = f * segundos). Nota 1 = silencio de 'duracion' fotogramas.
;  Nota 0 = fin. Entre nota y nota hay un HALT (20 ms) para separarlas.
;
;  toca_melodia:   HL = melodia (no se puede cortar)
;  melodia_gameover / melodia_titulo (tambien al completar el juego)
;  musica_titulo:  la del titulo; se corta al pulsar ESPACIO y mientras
;                  suena se sigue vigilando el truco J-O-N
;===========================================================================
musica_titulo:
	ld	hl,melodia_titulo
	ld	a,1
	jr	toca_melodia_a

toca_melodia:
	xor	a				;No se puede cortar
toca_melodia_a:
	ld	(melodia_cortable),a

bucle_melodia:
	ld	e,(hl)
	inc	hl
	ld	d,(hl)				;DE = nota
	inc	hl
	ld	a,d
	or	e
	ret	z				;Fin

	ld	c,(hl)
	inc	hl
	ld	b,(hl)				;BC = duracion
	inc	hl
	push	hl

	ld	a,d				;Nota 1 = silencio
	or	a
	jr	nz,melodia_nota
	ld	a,e
	dec	a
	jr	nz,melodia_nota

melodia_silencio:
	halt
	dec	c
	jr	nz,melodia_silencio
	jr	melodia_siguiente

melodia_nota:
	ex	de,hl				;HL = nota
	ld	d,b
	ld	e,c				;DE = duracion
	push	ix
	call	beeper
	pop	ix
	halt					;Separacion entre notas

melodia_siguiente:
	ld	a,(melodia_cortable)
	or	a
	jr	z,melodia_continua

	call	comprueba_trucos
	ld	a,FILA_SPACE
	in	a,($fe)
	bit	0,a				;ESPACIO: se corta la musica
	jr	nz,melodia_continua
	pop	hl
	ret

melodia_continua:
	pop	hl
	jr	bucle_melodia

melodia_cortable:	defb	0

;---------------------------------------------------------------------------
melodia_titulo:		; Musica del titulo
	defw	964, 53		;A4
	defw	964, 53		;A4
	defw	634, 171		;E5
	defw	715, 70		;D5
	defw	806, 63		;C5
	defw	715, 153		;D5
	defw	634, 356		;E5
	defw	806, 63		;C5
	defw	715, 70		;D5
	defw	634, 79		;E5
	defw	528, 94		;G5
	defw	467, 229		;A5
	defw	528, 94		;G5
	defw	634, 79		;E5
	defw	715, 317		;D5
	defw	634, 79		;E5
	defw	715, 70		;D5
	defw	806, 63		;C5
	defw	856, 59		;B4
	defw	964, 114		;A4
	defw	1297, 86		;E4
	defw	964, 361		;A4
	defw	0			;fin

melodia_llave:		; Al coger la llave
	defw	388, 63		;C6
	defw	302, 79		;E6
	defw	249, 94		;G6
	defw	179, 126		;C7
	defw	136, 158		;E7
	defw	109, 188		;G7
	defw	179, 42		;C7
	defw	109, 63		;G7
	defw	179, 42		;C7
	defw	109, 63		;G7
	defw	179, 42		;C7
	defw	109, 63		;G7
	defw	216, 254		;C8
	defw	0			;fin

melodia_gameover:		; Game over (triste, ~4,5 s)
	defw	634, 218		;E5
	defw	806, 173		;C5
	defw	964, 145		;A4
	defw	1, 9		;silencio
	defw	715, 194		;D5
	defw	856, 163		;B4
	defw	1023, 137		;G#4
	defw	1, 9		;silencio
	defw	964, 68		;A4
	defw	1023, 64		;G#4
	defw	964, 68		;A4
	defw	1297, 51		;E4
	defw	1959, 227		;A3
	defw	0			;fin
