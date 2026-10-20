;===========================================================================
;
;			  P I N C H O S   D E L   S U E L O
;
;  Unos pinchos (4 bytes x 8 scanlines, en PINCHOS_POS_X del tercio 3) que
;  salen del suelo y vuelven a esconderse. 8 fotogramas de 32 bytes en
;  'pinchos' (saliendo) y 'pinchos_al_reves' (escondiendose).
;
;  estado_pinchos:
;     0 = escondidos              1 = saliendo   (pinchos_suelo)
;     2 = fuera, esperando        3 = entrando   (pinchos_suelo)
;
;  Desde jugabilidad-acc15/16/17 se llama a inicia_pinchos_suelo en
;  ciertos valores de contador_it, y cada fotograma a pinchos_suelo
;  (estados 1 y 3) o a check_col_pinchos (estado 2).
;
;  (Lo gestiona gestiona_pinchos, en jugabilidad.asm: una sola llamada
;   por fotograma segun el estado.)
;===========================================================================

;===========================================================================
;	INICIA PINCHOS:  0 -> 1 (salir),  2 -> 3 (entrar)
;	(no hace nada si el jugador esta explotando o ya se estan moviendo)
;---------------------------------------------------------------------------
inicia_pinchos_suelo:
	ld	a,(jugador_set)
	bit	6,a
	ret	nz

	ld	a,$50
	ld	(pinchos_y),a
	ld	a,PINCHOS_POS_X
	ld	(pinchos_x),a

	xor	a
	ld	(rota_pinchos),a

	;------------------------------------------------------
	ld	a,(estado_pinchos)
	cp	$01
	ret	z				;Ya saliendo
	cp	$03
	ret	z				;Ya entrando

	cp	$02
	ld	a,$03				;Fuera -> entrar
	jr	z,guarda_estado_pinchos
	ld	a,$01				;Escondidos -> salir

guarda_estado_pinchos:
	ld	(estado_pinchos),a
	ret

;===========================================================================
;	PINCHOS SALIENDO / ENTRANDO (estados 1 y 3)
;---------------------------------------------------------------------------
pinchos_suelo:
	ld	a,(pinchos_y)
	ld	h,a
	ld	a,(pinchos_x)
	ld	l,a

	call	pinchos_colisiones

	;------------------------------------------ DE = sprite + rot * 32
	ld	de,pinchos
	ld	a,(estado_pinchos)
	cp	$03
	jr	nz,pinchos_rotacion
	ld	de,pinchos_al_reves

pinchos_rotacion:
	ld	a,(rota_pinchos)
	add	a,a
	add	a,a
	add	a,a
	add	a,a
	add	a,a				;x32
	call	suma_a_de

	call	dibuja_pinchos

	ld	a,SND_PAJARO
	call	sonido

	;------------------------------------------ Siguiente fotograma
	ld	a,(rota_pinchos)
	inc	a
	ld	(rota_pinchos),a
	cp	$08
	ret	nz

	xor	a
	ld	(rota_pinchos),a

	;------------------------------------------ Cambio de estado
	ld	a,(estado_pinchos)
	cp	$01
	jr	z,cambio_a_pinchos_fuera
	cp	$03
	ret	nz

	xor	a				;3 -> 0: escondidos
	ld	(estado_pinchos),a
	ret

cambio_a_pinchos_fuera:
	ld	a,$02				;1 -> 2: fuera
	ld	(estado_pinchos),a
	ret

;===========================================================================
;	PINCHOS FUERA (estado 2): solo colisiones y redibujado
;---------------------------------------------------------------------------
check_col_pinchos:
	ld	a,(pinchos_y)
	ld	h,a
	ld	a,(pinchos_x)
	ld	l,a

	call	pinchos_colisiones

	ld	de,pinchos_al_reves		;(fotograma 0 = pinchos fuera)
	; (sigue en dibuja_pinchos)

;---------------------------------------------------------------------------
; Dibuja 4 bytes x 8 scanlines desde DE en HL, y los atributos (BLANCO)
;---------------------------------------------------------------------------
dibuja_pinchos:
	ld	b,$08

bucle_dibuja_pinchos:
	call	dibujados_repetitivos		;bytes 1 y 2
	call	dibujados_repetitivos2		;bytes 3 y 4

	dec	l
	dec	l
	dec	l
	inc	de
	inc	h
	djnz	bucle_dibuja_pinchos

	ld	h,$5a
	ld	(hl),BLANCO
	inc	l
	ld	(hl),BLANCO
	inc	l
	ld	(hl),BLANCO
	inc	l
	ld	(hl),BLANCO
	ret

;---------------------------------------------------------------------------
; Colisiones: los pinchos (una fila por encima, C = X - $20) contra las
; columnas jugador_x - 3 ... jugador_x + 2, basta la misma altura
;---------------------------------------------------------------------------
pinchos_colisiones:
	ld	a,l
	sub	$20
	ld	c,a

	ld	a,(jugador_set)
	bit	6,a				;Jugador ya explotando?
	ret	nz

	ld	a,(jugador_x)
	sub	$03
	ld	e,a
	ld	b,$06
	ld	d,$01				;Basta con estar a la misma altura
	jp	colisiones_columnas
