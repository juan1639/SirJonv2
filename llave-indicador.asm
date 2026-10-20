;===========================================================================
;
;				L A L L A V E
;
;  settings4 bit0 = hace falta la llave (hay que volver a por ella)
;  settings4 bit1 = tienes la llave
;
;  dibuja_needkey .... la llave como objeto (pantallas 1 y 19); al
;                      tocarla se coge
;  indicador_key ..... llave + flecha animada en el suelo que indican
;                      que hay que volver atras a por la llave
;  inventario_llave .. la llave en el marcador (arriba a la derecha)
;  resetear_llave .... se gasta la llave (al usar la puerta)
;===========================================================================
LLAVE_DESPL_CON_LLAVE	equ	$52	; Desplazamiento del indicador si ya
					; tienes la llave
ATTR_LLAVE		equ	%01000100	; Verde brillo

;===========================================================================
;	INDICADOR "VUELVE A POR LA LLAVE"
;
;  OJO: sale con A = settings4; los que la llaman hacen 'bit 1,a' justo
;  despues (sin recargar A).
;---------------------------------------------------------------------------
indicador_key:
	;------------------------------------------ Llave
	ld	h,$50
	ld	l,LLAVE_INDICADOR_POS_X
	call	indicador_ajusta_x

	ld	de,llave
	call	dibuja_2x8_scanlines

	ld	h,$5a
	ld	l,LLAVE_INDICADOR_POS_X
	call	indicador_ajusta_x
	call	attr_2_blanco

	;------------------------------------------ Flecha de retorno animada
	; rota_indicador: 1..7, cambia cada 7 fotogramas
	ld	a,(indica_halt)
	dec	a
	ld	(indica_halt),a
	jr	nz,indicador_dibuja_flecha

	ld	a,$07
	ld	(indica_halt),a

	ld	a,(rota_indicador)
	inc	a
	cp	$08
	jr	nz,indicador_guarda_rota
	ld	a,$01
indicador_guarda_rota:
	ld	(rota_indicador),a

indicador_dibuja_flecha:
	ld	de,flecha_retorno - 16
	ld	a,(rota_indicador)
	add	a,a
	add	a,a
	add	a,a
	add	a,a				;16 bytes por fotograma
	call	suma_a_de

	ld	h,$50
	ld	l,LLAVE_FLECHA_POS_X
	call	indicador_ajusta_x
	call	dibuja_2x8_scanlines

	ld	h,$5a
	ld	l,LLAVE_FLECHA_POS_X
	call	indicador_ajusta_x
	call	attr_2_blanco

	ld	a,(settings4)			;(A = settings4 al salir)
	ret

;---------------------------------------------------------------------------
; Si ya tienes la llave, el indicador se dibuja mas a la derecha
;---------------------------------------------------------------------------
indicador_ajusta_x:
	ld	a,(settings4)
	bit	1,a
	ret	z
	ld	a,l
	add	a,LLAVE_DESPL_CON_LLAVE
	ld	l,a
	ret

;---------------------------------------------------------------------------
; 2 atributos BLANCO_BRILLO en HL, HL+1
;---------------------------------------------------------------------------
attr_2_blanco:
	ld	(hl),BLANCO_BRILLO
	inc	l
	ld	(hl),BLANCO_BRILLO
	ret

;---------------------------------------------------------------------------
; 2 x 8 desde DE (2 bytes por scanline) en HL, con incrementar_scanline
;---------------------------------------------------------------------------
dibuja_2x8_scanlines:
	ld	b,$08

bucle_dibuja_2x8:
	call	dibujados_repetitivos
	dec	l
	call	incrementar_scanline
	inc	de
	djnz	bucle_dibuja_2x8
	ret

;===========================================================================
;	LLAVE EN EL MARCADOR (parpadea al cogerla y en la pantalla 7)
;---------------------------------------------------------------------------
inventario_llave:
	ld	h,$40
	ld	l,LLAVE_INVENTARIO_POS_X
	ld	de,llave
	call	dibuja_2x8_scanlines

	ld	c,ATTR_LLAVE
	ld	a,(timer_flash)
	or	a
	jr	nz,inventario_llave_flash

	ld	a,(nivel)
	cp	NIVEL_DOS_PISOS_B
	jr	nz,inventario_llave_attr

inventario_llave_flash:
	ld	c,ATTR_LLAVE | %10000000	;Con FLASH

inventario_llave_attr:
	ld	h,$58
	ld	l,LLAVE_INVENTARIO_POS_X
	ld	(hl),c
	inc	l
	ld	(hl),c
	ret

;===========================================================================
;	SE GASTA LA LLAVE (al cruzar la puerta)
;---------------------------------------------------------------------------
resetear_llave:
	ld	a,(settings4)
	res	0,a				;Ya no hace falta...
	res	1,a				;...ni la tienes
	ld	(settings4),a

	;------------------------------------------ Borra la del marcador
	ld	h,$40
	ld	l,LLAVE_INVENTARIO_POS_X
	ld	b,$08

bucle_borrallave_inventario:
	ld	(hl),$00
	inc	l
	ld	(hl),$00
	dec	l
	call	incrementar_scanline
	djnz	bucle_borrallave_inventario

	ld	h,$58
	ld	l,LLAVE_INVENTARIO_POS_X
	ld	(hl),ATTR_LLAVE
	inc	l
	ld	(hl),ATTR_LLAVE

	;------------------------------------------ Borra el indicador
	ld	h,$50
	ld	l,LLAVE_INDICADOR_POS_X + LLAVE_DESPL_CON_LLAVE
	ld	b,$10

bucle_borrado_excepcion:
	ld	(hl),$00
	inc	l
	ld	(hl),$00
	dec	l
	call	incrementar_scanline
	djnz	bucle_borrado_excepcion
	ret

;===========================================================================
;	LA LLAVE COMO OBJETO (pantalla 1 en el piso de arriba; pantalla 19)
;---------------------------------------------------------------------------
dibuja_needkey:
	ld	h,$48
	ld	l,LLAVE_ITEM_POS_X

	ld	a,(nivel)
	cp	NIVEL_ULTIMO
	jr	nz,needkey_comprueba

	ld	h,$50
	ld	l,LLAVE_ITEM_POS_X_NIVEL19

	;------------------------------------------ La tocamos?
needkey_comprueba:
	ld	a,(jugador_x)
	add	a,$20				;(una fila por debajo)
	cp	l
	jr	z,coge_lallave
	inc	a
	inc	a
	cp	l
	jr	z,coge_lallave

	;------------------------------------------ Dibuja la llave
	ld	de,llave
	ld	b,$08

bucle_dibujallave:
	call	dibujados_repetitivos
	dec	l
	inc	h
	inc	de
	djnz	bucle_dibujallave

	ld	a,h
	sub	$08
	call	cambioh_58595a
	ld	h,a
	ld	(hl),ATTR_LLAVE
	inc	l
	ld	(hl),ATTR_LLAVE
	ret

;---------------------------------------------
; COGER LA LLAVE (HL = posicion de la llave en pantalla)
;   1. Se borra la llave del suelo y se dibuja al caballero (en este punto
;      del fotograma esta borrado) para que se vea durante la animacion.
;   2. La llave 'vuela' hasta el marcador (vuelo_llave).
;   3. Aparece en el inventario (parpadeando) y suena la fanfarria.
;---------------------------------------------
coge_lallave:
	push	bc
	push	de
	push	hl

	push	hl
	call	borra_2x8			;Quita la llave del suelo
	call	guarda_y_dibuja_jugador		;Que se vea el caballero
	pop	hl
	call	vuelo_llave

	ld	a,(settings4)
	res	0,a				;Ya no hace falta...
	set	1,a				;...porque la tienes
	ld	(settings4),a

	xor	a
	ld	(rota_entrepuert),a

	ld	a,$f0
	call	sub_efecto_flash_verde
	call	inventario_llave		;Ya en el marcador

	ld	hl,melodia_llave		;Fanfarria aguda (~1,4 s, el juego
	call	toca_melodia			; se detiene mientras suena)

	call	borra_jugador			;(como estaba: el bucle lo redibuja)

	pop	hl
	pop	de
	pop	bc
	ret

;---------------------------------------------------------------------------
; Pone a cero 2 bytes x 8 scanlines desde HL (dentro de un caracter)
;---------------------------------------------------------------------------
borra_2x8:
	ld	b,$08
bucle_borra_2x8:
	ld	(hl),$00
	inc	l
	ld	(hl),$00
	dec	l
	inc	h
	djnz	bucle_borra_2x8
	ret

;===========================================================================
;	V U E L O   D E   L A   L L A V E   A L   M A R C A D O R
;
;  Sale 2 filas por encima de la llave (por encima del caballero) y va en
;  linea recta hasta su sitio en el marcador, en VUELO_PASOS fotogramas.
;  Posicion en coma fija 8.8: X en columnas (bytes), Y en scanlines.
;  Se dibuja con XOR (al repetirlo se borra) y con los atributos en verde,
;  guardando y restaurando los que habia.
;  Entrada: HL = posicion de la llave en pantalla.
;---------------------------------------------------------------------------
VUELO_PASOS	equ	32			;(potencia de 2: se divide con desplazamientos)
VUELO_DESTINO_X	equ	LLAVE_INVENTARIO_POS_X & $1f
VUELO_DESTINO_Y	equ	(LLAVE_INVENTARIO_POS_X / $20) * 8

vuelo_llave:
	push	ix
	call	vuelo_llave_ix
	pop	ix
	ret

vuelo_llave_ix:
	;------------------------------------------ Origen
	ld	a,l
	and	$1f
	ld	b,a				;B = columna
	ld	a,l
	rlca
	rlca
	rlca
	and	$07
	ld	c,a
	ld	a,h
	and	$18
	or	c				;A = fila (0..23)
	sub	2				;2 filas mas arriba
	add	a,a
	add	a,a
	add	a,a				;A = scanline de salida
	ld	c,a				;C = Y0

	ld	h,b
	ld	l,0
	ld	(vuelo_x),hl			;X = X0.0
	ld	h,c
	ld	(vuelo_y),hl			;Y = Y0.0

	;------------------------------------------ Incrementos (destino - origen) * 256 / 32
	ld	e,b
	ld	a,VUELO_DESTINO_X
	call	vuelo_incremento
	ld	(vuelo_dx),hl
	ld	e,c
	ld	a,VUELO_DESTINO_Y
	call	vuelo_incremento
	ld	(vuelo_dy),hl

	;------------------------------------------ Vuelo
	ld	b,VUELO_PASOS + 1

bucle_vuelo_llave:
	push	bc
	call	vuelo_attr_guarda
	call	vuelo_xor			;Dibuja
	halt
	call	vuelo_xor			;Borra
	call	vuelo_attr_restaura

	ld	hl,(vuelo_x)
	ld	de,(vuelo_dx)
	add	hl,de
	ld	(vuelo_x),hl
	ld	hl,(vuelo_y)
	ld	de,(vuelo_dy)
	add	hl,de
	ld	(vuelo_y),hl
	pop	bc
	djnz	bucle_vuelo_llave
	ret

;---------------------------------------------------------------------------
; HL = (A - E) * 8   (con signo: (destino - origen) * 256 / 32)
;---------------------------------------------------------------------------
vuelo_incremento:
	ld	l,a
	ld	h,0
	ld	d,0
	or	a
	sbc	hl,de
	add	hl,hl
	add	hl,hl
	add	hl,hl
	ret

;---------------------------------------------------------------------------
; Dibuja/borra (XOR) la llave (2 x 8) en la posicion actual
;---------------------------------------------------------------------------
vuelo_xor:
	ld	a,(vuelo_x + 1)
	ld	c,a				;C = columna
	ld	a,(vuelo_y + 1)			;A = scanline
	ld	de,llave
	ld	b,$08

bucle_vuelo_xor:
	push	af
	call	direccion_pixel			;HL = (A, C)
	ld	a,(de)
	xor	(hl)
	ld	(hl),a
	inc	de
	inc	l
	ld	a,(de)
	xor	(hl)
	ld	(hl),a
	inc	de
	pop	af
	inc	a				;Siguiente scanline
	djnz	bucle_vuelo_xor
	ret

;---------------------------------------------------------------------------
; HL = direccion de pantalla de la scanline A, columna C.  Altera AF.
;---------------------------------------------------------------------------
direccion_pixel:
	push	bc
	ld	b,a
	and	$07
	ld	h,a
	ld	a,b
	rrca
	rrca
	rrca
	and	$18
	or	h
	or	$40
	ld	h,a
	ld	a,b
	add	a,a
	add	a,a
	and	$e0
	or	c
	ld	l,a
	pop	bc
	ret

;---------------------------------------------------------------------------
; Atributos bajo la llave: 2 columnas x 2 filas (la de arriba y la de
; abajo de la llave; pueden ser la misma). Se guardan y se ponen en verde.
;---------------------------------------------------------------------------
vuelo_attr_guarda:
	call	vuelo_attr_dirs
	ld	de,vuelo_attrs
	ld	b,4
bucle_vuelo_guarda:
	pop	hl				;(vuelo_attr_dirs deja 4 direcciones
	ld	a,(hl)				; en la pila)
	ld	(de),a
	inc	de
	ld	(hl),ATTR_LLAVE
	djnz	bucle_vuelo_guarda
	ret

vuelo_attr_restaura:
	call	vuelo_attr_dirs
	ld	de,vuelo_attrs + 3		;En orden inverso (si se repite
	ld	b,4				; una celda queda la original)
bucle_vuelo_restaura:
	pop	hl
	ld	a,(de)
	ld	(hl),a
	dec	de
	djnz	bucle_vuelo_restaura
	ret

;---------------------------------------------------------------------------
; Deja en la pila las 4 direcciones de atributo (para quien la llama):
; las saca en el orden (abajo,dcha) (abajo,izda) (arriba,dcha) (arriba,izda)
; ...al reves de como se apilan.
;---------------------------------------------------------------------------
vuelo_attr_dirs:
	pop	ix				;Direccion de retorno
	ld	a,(vuelo_y + 1)
	call	vuelo_attr_fila			;HL = atributo (fila de arriba, col)
	push	hl
	inc	l
	push	hl
	ld	a,(vuelo_y + 1)
	add	a,7
	call	vuelo_attr_fila			;(fila de abajo)
	push	hl
	inc	l
	push	hl
	jp	(ix)

vuelo_attr_fila:				;A = scanline -> HL = $5800 + fila*32 + col
	and	$f8
	ld	l,a
	ld	h,0
	add	hl,hl
	add	hl,hl				;fila*32 = (scanline/8)*32 = scanline*4
	ld	a,(vuelo_x + 1)
	add	a,l
	ld	l,a
	ld	a,h
	adc	a,$58
	ld	h,a
	ret

vuelo_x:	defw	0
vuelo_y:	defw	0
vuelo_dx:	defw	0
vuelo_dy:	defw	0
vuelo_attrs:	defs	4
