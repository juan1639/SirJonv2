;===========================================================================
;
;			     F A N T A S M A S
;
;  Hay 2 fantasmas y el mismo codigo sirve para los dos: las rutinas
;  trabajan con IX apuntando a la estructura del fantasma (ver var.asm).
;
;     fantasma 1: aparece por la derecha y va hacia la IZQUIERDA
;                (settings2 bit1; se le mata mirando a la derecha)
;     fantasma 2: aparece por la izquierda y va hacia la DERECHA
;                (settings2 bit5; se le mata mirando a la izquierda)
;
;  Sprite: 3 bytes x 24 scanlines, con 8 rotaciones (1 px cada una) de
;  72 bytes. Cada 8 rotaciones el fantasma avanza un byte (X +/- 1).
;
;  La explosion (explo_fantasma) es comun a los dos (y la usa tambien la
;  arana): coordenadas en explo_fantasmay / explo_fantasmax.
;===========================================================================

;------------------------ Estructura de un fantasma ------------------------
FANT_Y		equ	0	; Byte alto de pantalla (H)
FANT_X		equ	1	; Byte bajo de pantalla (L)
FANT_ROT	equ	2	; Rotacion actual (0..7)
FANT_CONT	equ	3	; Contador de la animacion (cuenta atras)
FANT_DIR	equ	4	; Direccion: $ff = izquierda, $01 = derecha
FANT_MIRANDO	equ	5	; Hacia donde debe mirar el jugador para matarlo
				; (bit0 de jugador_set: 0 = dcha, 1 = izda)
FANT_LIMITE	equ	6	; X donde desaparece
FANT_COL_BORRA	equ	7	; Columna (0..2) que se borra al avanzar un byte
FANT_FIN_BORRA	equ	8	; Desplazamiento X del borrado final
FANT_MASCARA	equ	9	; Mascara del flag 'activo' en settings2
FANT_SPR1	equ	10	; (2 bytes) sprite animacion 1
FANT_SPR2	equ	12	; (2 bytes) sprite animacion 2

FANT_CONT_INI	equ	$0a

;===========================================================================
;	Puntos de entrada (los que se llaman desde jugabilidad-accN)
;===========================================================================
fantasma:
	ld	ix,fant1_datos
	jr	fantasma_mueve

fantasma2:
	ld	ix,fant2_datos
	jr	fantasma_mueve

;===========================================================================
;	INICIA FANTASMA 1 (por la derecha, hacia la izquierda)
;---------------------------------------------------------------------------
inicia_fantasma:
	ld	a,(settings2)
	bit	1,a
	ret	nz				;Ya esta

	set	1,a				;Fantasma 1 ON
	ld	(settings2),a

	ld	a,$50
	ld	(fant1_datos+FANT_Y),a
	ld	a,FANTASMA_START_POS_X
	ld	(fant1_datos+FANT_X),a
	ret

;===========================================================================
;	INICIA FANTASMA 2 (por la izquierda, hacia la derecha)
;
;  En la pantalla 7 solo sale si: no tienes la llave, estas en el suelo
;  y el arquero no esta activo (settings bit5 = 0)
;---------------------------------------------------------------------------
inicia_fantasma2:
	ld	a,(nivel)
	cp	NIVEL_DOS_PISOS_B
	jr	nz,inicia_fant2

	ld	a,(settings4)
	bit	1,a				;Tienes la llave?
	ret	nz

	ld	a,(jugador_y)
	cp	JUGADOR_Y_SUELO
	ret	nz

	ld	a,(settings)
	bit	5,a
	ret	nz

inicia_fant2:
	ld	a,(settings2)
	bit	5,a
	ret	nz				;Ya esta

	set	5,a				;Fantasma 2 ON
	ld	(settings2),a

	ld	a,$50
	ld	(fant2_datos+FANT_Y),a
	ld	a,$40
	ld	(fant2_datos+FANT_X),a
	ret

;===========================================================================
;	MUEVE / DIBUJA UN FANTASMA  (IX = fantasma)
;---------------------------------------------------------------------------
fantasma_mueve:
	ld	h,(ix+FANT_Y)
	ld	l,(ix+FANT_X)

	;------------------------------------------ Colision con el jugador
	ld	a,l
	add	a,$40				;2 filas mas abajo...
	add	a,(ix+FANT_DIR)			;...y un byte en la direccion de avance
	ld	c,a

	ld	a,(jugador_x)
	cp	c
	jp	z,colision_vsfantasma

	;------------------------------------------ Le atacamos con la espada?
	ld	a,(jugador_set)
	bit	4,a				;Atacando?
	jr	z,fantasma_animacion

	and	%00000001			;Hacia donde mira el jugador
	cp	(ix+FANT_MIRANDO)
	jr	nz,fantasma_animacion

	ld	a,c
	add	a,(ix+FANT_DIR)			;Un byte mas alla
	ld	c,a
	ld	a,(jugador_x)
	cp	c
	call	z,inicia_explofantasma

	;------------------------------------------ Animacion (2 sprites)
fantasma_animacion:
	ld	a,(ix+FANT_CONT)
	dec	a
	jr	nz,fantasma_guarda_cont
	ld	a,FANT_CONT_INI
fantasma_guarda_cont:
	ld	(ix+FANT_CONT),a

	ld	e,(ix+FANT_SPR1)
	ld	d,(ix+FANT_SPR1+1)
	cp	$05
	jr	nc,fantasma_rotacion
	ld	e,(ix+FANT_SPR2)
	ld	d,(ix+FANT_SPR2+1)

	;------------------------------------------ DE += rotacion * 72
fantasma_rotacion:
	push	hl
	ld	a,(ix+FANT_ROT)
	call	de_mas_a_por_72
	pop	hl

	;------------------------------------------ Dibuja 3 x 24
	ld	b,$18

bucle_dibujafantasma:
	call	dibujados_repetitivos		;bytes 1 y 2

	inc	l
	inc	de
	ld	a,(de)				;byte 3
	ld	(hl),a

	dec	l
	dec	l
	call	incrementar_scanline

	inc	de
	djnz	bucle_dibujafantasma

	;------------------------------------------ Atributos
	ld	a,(ix+FANT_X)
	call	attr_fantasmas

	;------------------------------------------ Siguiente rotacion
	ld	a,(ix+FANT_ROT)
	inc	a
	ld	(ix+FANT_ROT),a
	cp	$08
	ret	nz

	ld	(ix+FANT_ROT),$00

	;------------------------------------------ Avanza un byte:
	; borra la columna que queda atras...
	ld	h,(ix+FANT_Y)
	ld	a,(ix+FANT_X)
	add	a,(ix+FANT_COL_BORRA)
	ld	l,a

	ld	b,$18

bucle_borradof:
	ld	(hl),$00
	call	incrementar_scanline
	djnz	bucle_borradof

	; ...y mueve X
	ld	a,(ix+FANT_X)
	add	a,(ix+FANT_DIR)
	ld	(ix+FANT_X),a
	cp	(ix+FANT_LIMITE)
	ret	nz				;Aun no ha llegado al final

	;------------------------------------------ Fin del recorrido
	add	a,(ix+FANT_FIN_BORRA)
	ld	l,a
	ld	h,(ix+FANT_Y)
	ld	b,$18
	call	borra_3_columnas

	ld	a,(settings2)
	or	(ix+FANT_MASCARA)
	xor	(ix+FANT_MASCARA)		;Fantasma OFF
	ld	(settings2),a
	ret

;---------------------------------------------------------------------------
; DE = DE + A * 72   (A = 0..7, rotacion o fase).  Altera AF, HL
;---------------------------------------------------------------------------
de_mas_a_por_72:
	ld	l,a
	ld	h,$00
	add	hl,hl
	add	hl,hl
	add	hl,hl				;HL = A * 8
	push	hl
	add	hl,hl
	add	hl,hl
	add	hl,hl				;HL = A * 64
	add	hl,de
	pop	de
	add	hl,de				;HL = DE_original + A*64 + A*8
	ex	de,hl
	ret

;===========================================================================
;	COLISION FANTASMA - JUGADOR  (IX = fantasma)
;---------------------------------------------------------------------------
colision_vsfantasma:
	ld	a,(jugador_timer_invisib)
	or	a				;Invisible: no hay colision
	ret	nz

	call	jugador_muere
	; (sigue en inicia_explofantasma: el fantasma tambien explota)

;===========================================================================
;	INICIA EXPLO-FANTASMA  (IX = fantasma)
;---------------------------------------------------------------------------
inicia_explofantasma:
	ld	a,SND_BEEP
	call	sonido

	ld	a,(settings2)
	or	(ix+FANT_MASCARA)
	xor	(ix+FANT_MASCARA)		;Fantasma OFF
	set	2,a				;Explo-fantasma ON
	ld	(settings2),a

	xor	a
	ld	(contador_explo),a

	ld	a,(ix+FANT_Y)
	ld	(explo_fantasmay),a
	ld	a,(ix+FANT_X)
	ld	(explo_fantasmax),a
	ret

;===========================================================================
;	EXPLO-FANTASMA  (8 fases de 72 bytes; tambien la usa la arana)
;---------------------------------------------------------------------------
explo_fantasma:
	ld	a,(contador_explo)
	inc	a
	ld	(contador_explo),a
	cp	$08
	jr	z,fin_explo_fantasma

	ld	de,fantasma_explota
	call	de_mas_a_por_72

	;-----------------------------------------------------
	ld	a,(explo_fantasmay)
	ld	h,a
	ld	a,(explo_fantasmax)
	ld	l,a

	ld	b,$18

bucle_explofantasma:
	call	dibujados_repetitivos		;bytes 1 y 2

	inc	l
	inc	de
	ld	a,(de)				;byte 3
	ld	(hl),a

	ld	a,b				;Ralentiza en los scanlines 9, 5 y 1
	cp	$09
	call	z,un_halt
	cp	$05
	call	z,un_halt
	cp	$01
	call	z,un_halt

	dec	l
	dec	l
	call	incrementar_scanline
	inc	de
	djnz	bucle_explofantasma
	ret

;---------------------------------------------------------
fin_explo_fantasma:
	ld	a,(settings2)
	res	2,a				;Fin explo-fantasma
	ld	(settings2),a

	ld	a,(explo_fantasmay)
	ld	h,a
	ld	a,(explo_fantasmax)
	ld	l,a
	ld	b,$18
	jp	borra_3_columnas

;===========================================================================
;	ATRIBUTOS FANTASMA:  3 x 3 BLANCO_BRILLO desde la X en A (tercio 3)
;---------------------------------------------------------------------------
attr_fantasmas:
	ld	l,a
	ld	h,$5a

	ld	b,$03				;3 filas

bucle_attr_fantasma:
	ld	(hl),BLANCO_BRILLO
	inc	l
	ld	(hl),BLANCO_BRILLO
	inc	l
	ld	(hl),BLANCO_BRILLO

	dec	l
	dec	l

	ld	a,l
	add	a,$20
	ld	l,a
	djnz	bucle_attr_fantasma
	ret
