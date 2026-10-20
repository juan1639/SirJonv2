;===========================================================================
;
;			      M U R C I E L A G O
;
;  Entra por la izquierda y vuela hacia la derecha bajando en diagonal
;  (2 scanlines por fotograma) hasta llegar al suelo; ahi sigue en
;  horizontal hasta MURCIELAGO_END_POS_X.
;
;  Sprite: 3 bytes x 8 scanlines, 8 rotaciones de 24 bytes, 2 animaciones.
;  settings2 bit0 = murcielago activo.
;  Al matarlo explota como la arana (inicia_explomurcielago) y da vidas extra.
;===========================================================================

;===========================================================================
;	INICIA MURCIELAGO
;---------------------------------------------------------------------------
inicia_murcielago_zero:
	ld	a,(settings2)
	bit	0,a
	ret	nz				;Ya esta

	set	0,a				;Murcielago ON
	ld	(settings2),a

	ld	a,MURCIELAGO_START_POS_X
	ld	(murcielago_x),a

	ld	a,MURCIELAGO_START_POS_Y	;Tercio 1...
	ld	(murcielago_y),a

	;---------------------------------- ...o tercio 3 en las pantallas 17 y 19
	ld	a,(nivel)
	cp	17
	call	z,murcielago_start_tercio3

	ld	a,(nivel)
	cp	NIVEL_ULTIMO
	ret	nz

murcielago_start_tercio3:
	ld	a,MURCIELAGO_START_POS_Y_T3
	ld	(murcielago_y),a
	ret

;===========================================================================
;	MUEVE / DIBUJA EL MURCIELAGO
;---------------------------------------------------------------------------
sub_murcielago:
	ld	a,(murcielago_y)
	ld	h,a
	ld	a,(murcielago_x)
	ld	l,a
	ld	c,a				;C = columna del murcielago

	ld	a,(jugador_set)
	bit	6,a				;Jugador ya explotando?
	jr	nz,murcielago_mueve

	;------------------------------------------ Ataque con la espada
	bit	4,a
	jr	z,colisiones_vsmurcielago	;No atacamos

	bit	0,a
	ld	a,(jugador_x)
	jr	nz,ataque_izda_murcielago

	add	a,$03				;Mirando a la dcha: espada en X + 3
	jr	ataque_murcielago

ataque_izda_murcielago:
	dec	a				;Mirando a la izda: espada en X - 1

ataque_murcielago:
	cp	c
	jr	nz,colisiones_vsmurcielago
	call	inicia_explomurcielago
	ld	a,(settings2)
	bit	0,a				;Muerto? ya no se mueve ni se dibuja
	ret	z				;(lo ha borrado toca_murcielago)

	;------------------------------------------ Colision con el jugador
colisiones_vsmurcielago:
	ld	a,(jugador_x)
	ld	e,a
	ld	b,$03
	ld	d,$01				;Basta con estar a la misma altura
	call	colisiones_columnas

	ld	a,(jugador_set)
	bit	6,a				;Nos ha dado?
	jp	nz,fin_murcielago

	;------------------------------------------ Baja en diagonal...
murcielago_mueve:
	ld	a,(murcielago_x)
	and	%11110000
	cp	$80
	jr	z,murcielago_en_suelo
	cp	$90
	jr	nz,murcielago_baja

murcielago_en_suelo:
	ld	a,(murcielago_y)
	cp	$50
	jr	z,murcielago_dibuja		;...hasta llegar al suelo

murcielago_baja:
	call	borra_3_bytes			;Borra los 2 scanlines de arriba
	call	incrementar_scanline
	call	borra_3_bytes
	call	incrementar_scanline

	ld	a,h
	ld	(murcielago_y),a
	ld	a,l
	ld	(murcielago_x),a

	;------------------------------------------ Animacion (2 sprites)
murcielago_dibuja:
	ld	a,(cont_murcielago)
	dec	a
	jr	nz,murcielago_guarda_cont
	ld	a,$0a
murcielago_guarda_cont:
	ld	(cont_murcielago),a

	ld	de,murcielago_a1
	cp	$05
	jr	nc,murcielago_rotacion
	ld	de,murcielago_a2

	;------------------------------------------ DE += rotacion * 24
murcielago_rotacion:
	ld	a,(rota_murcielago)
	ld	b,a
	add	a,a
	add	a,b
	add	a,a
	add	a,a
	add	a,a
	call	suma_a_de

	ld	b,$08

bucle_dibuja_murcielago:
	call	dibujados_repetitivos		;bytes 1 y 2

	inc	l
	inc	de
	ld	a,(de)				;byte 3
	ld	(hl),a

	dec	l
	dec	l
	call	incrementar_scanline
	inc	de
	djnz	bucle_dibuja_murcielago

	;------------------------------------------ Atributos (en el tercio 3)
	ld	a,(murcielago_y)
	and 	%11110000
	cp	$50
	jr	nz,murcielago_siguiente_rotacion

	ld	h,$5a
	ld	a,(murcielago_x)
	ld	l,a
	ld	(hl),BLANCO_BRILLO
	inc	l
	ld	(hl),BLANCO_BRILLO
	inc	l
	ld	(hl),BLANCO_BRILLO

	;------------------------------------------ Siguiente rotacion
murcielago_siguiente_rotacion:
	ld	a,(rota_murcielago)
	inc	a
	ld	(rota_murcielago),a
	cp	$08
	ret	nz

	xor	a
	ld	(rota_murcielago),a

	;------------------------------------------ Avanza un byte a la dcha:
	; borra la columna de la izquierda
	ld	a,(murcielago_y)
	ld	h,a
	ld	a,(murcielago_x)
	ld	l,a

	ld	b,$08

bucle_borrado_murcielago:
	ld	(hl),$00
	call	incrementar_scanline
	djnz	bucle_borrado_murcielago

	ld	a,(murcielago_x)
	inc	a
	ld	(murcielago_x),a
	ld	l,a
	cp	MURCIELAGO_END_POS_X
	ret	nz				;Aun no ha llegado al final

	;------------------------------------------ Fin (o nos ha dado)
fin_murcielago:
	ld	a,(murcielago_y)
	ld	h,a

	call	borra_murcielago

	ld	a,(settings2)
	res	0,a				;Murcielago OFF
	ld	(settings2),a
	ret

;---------------------------------------------------------------------------
; Borra el murcielago entero (3 bytes x 8 scanlines) en HL.
; Conserva HL y BC.
;---------------------------------------------------------------------------
borra_murcielago:
	push	hl
	push	bc
	ld	b,$08
bucle_borra_murcielago:
	call	borra_3_bytes
	call	incrementar_scanline
	djnz	bucle_borra_murcielago
	pop	bc
	pop	hl
	ret

;---------------------------------------------------------------------------
; Pone a 0 tres bytes desde HL (HL no cambia)
;---------------------------------------------------------------------------
borra_3_bytes:
	ld	(hl),$00
	inc	l
	ld	(hl),$00
	inc	l
	ld	(hl),$00
	dec	l
	dec	l
	ret
