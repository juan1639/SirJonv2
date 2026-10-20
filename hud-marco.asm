;===========================================================================
;
;		    M A R C O   D E L   M A R C A D O R
;
;  Recuadro 'medieval' (muralla con almenas y dos torres con aspilleras)
;  en las filas 0-2 de la pantalla. Los textos van en la fila 1.
;
;  mapa_marco: 3 filas x 32 columnas, numero de tile (0 = vacio).
;  En la fila 2 solo se dibujan los 3 primeros scanlines (cornisa), para no
;  tapar lo que haya en la pantalla (techos de ladrillo).
;
;  (Datos generados con un script: tiles de 8 bytes.)
;===========================================================================
ATTR_MARCO	equ	AMARILLO

dibuja_marco:
	ld	hl,mapa_marco
	ld	de,$4000			;Fila 0
	call	marco_fila
	ld	de,$4020			;Fila 1
	call	marco_fila
	ld	de,$4040			;Fila 2
	; (sigue en marco_fila)

;---------------------------------------------------------------------------
; 32 tiles de la fila: HL = mapa, DE = pantalla (scanline 0 de la fila)
;---------------------------------------------------------------------------
marco_fila:
	ld	b,32
bucle_marco_fila:
	ld	a,(hl)
	inc	hl
	or	a
	jr	z,marco_siguiente		;Vacio: no se toca

	push	hl
	push	de
	push	bc
	dec	a
	ld	l,a
	ld	h,0
	add	hl,hl
	add	hl,hl
	add	hl,hl				;Tile * 8
	ld	bc,tiles_marco
	add	hl,bc
	ex	de,hl				;HL = pantalla, DE = tile

	ld	b,8
	ld	a,h
	cp	$40
	jr	nz,bucle_marco_tile
	ld	a,l
	cp	$40
	jr	c,bucle_marco_tile
	ld	b,3				;Fila 2: solo la cornisa
bucle_marco_tile:
	ld	a,(de)
	ld	(hl),a
	inc	de
	inc	h
	djnz	bucle_marco_tile

	pop	bc
	pop	de
	ex	de,hl				;Atributo: $58 + (fila * 32 + col)
	ld	h,$58
	ld	(hl),ATTR_MARCO
	ld	h,$40
	ex	de,hl
	pop	hl
marco_siguiente:
	inc	e
	djnz	bucle_marco_fila
	ret

mapa_marco:
	defb	 1, 2, 3, 4, 5, 3, 4, 5, 3, 4, 5, 3, 4, 5, 3, 4
	defb	 5, 3, 4, 5, 3, 4, 5, 3, 4, 5, 3, 4, 5, 3, 6, 7
	defb	 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	defb	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,10,11
	defb	12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12
	defb	12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12

tiles_marco:
	defb	230,230,255,144,144,255,159,153	;1
	defb	113,113,241, 17, 31,240,159,144	;2
	defb	248,  8,  8,  8,255, 16,255,  0	;3
	defb	 31, 16, 16, 16,255, 16,255,  0	;4
	defb	129,129,129,129,255, 16,255,  0	;5
	defb	 14, 14, 15,  9,249, 31,249,  9	;6
	defb	103,103,255,  1,  1,255,249,153	;7
	defb	249,144,153,249,153,159,255,144	;8
	defb	240,144,144,240,144,144,240, 16	;9
	defb	 15,  9,  9, 15,  9,  9, 15,  9	;10
	defb	159,  9,153,159,153,249,255,  1	;11
	defb	255, 16,255,  0,  0,  0,  0,  0	;12
