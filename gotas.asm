;===========================================================================
;
;				G O T A S
;
;  Hay 2 gotas (gota1 y gota2) y el mismo codigo sirve para las dos:
;  todas las rutinas trabajan con IX apuntando a la estructura de la gota
;  (ver var.asm). Las rutinas 'publicas' de siempre (gota_techo, caer_gota2,
;  ...) solo cargan IX y saltan a la rutina comun.
;
;  Ciclo de una gota (flags en settings3, cada gota usa su nibble):
;
;     TECHO  -> se forma en el techo (8 fases, 'gotatecho')
;     CAE    -> cae scanline a scanline (o fila a fila si es 'rapida')
;     SUELO  -> salpica en el suelo (5 fases, 'gotasuelo') y vuelve a TECHO
;
;             gota1 (bits)   gota2 (bits)
;     SUELO        0              4
;     CAE          1              5
;     TECHO        2              6
;     INI          3              7     (ya iniciada la 1a vez)
;
;  Diferencias entre las dos gotas (campo GOTA_RAPIDA):
;     gota1: en la pantalla 5 se forma mas rapido en el techo y en las
;            pantallas 10 y 13 cae fila a fila (8 scanlines de golpe).
;     gota2: siempre a velocidad normal.
;
;  Los flags se ponen / quitan con mascaras guardadas en la estructura:
;     poner:  ld a,(settings3) / or (ix+MASCARA)
;     quitar: ld a,(settings3) / or (ix+MASCARA) / xor (ix+MASCARA)
;===========================================================================

;----------------------- Estructura de una gota ----------------------------
GOTA_Y		equ	0	; Byte alto de pantalla (H)
GOTA_X		equ	1	; Byte bajo de pantalla (L)
GOTA_CONT	equ	2	; Fase de la animacion
GOTA_HALT	equ	3	; Ralentizador de la animacion (cuenta atras)
GOTA_M_SUELO	equ	4	; Mascara (settings3) flag SUELO
GOTA_M_CAE	equ	5	; Mascara (settings3) flag CAE
GOTA_M_TECHO	equ	6	; Mascara (settings3) flag TECHO
GOTA_M_INI	equ	7	; Mascara (settings3) flag INI
GOTA_RAPIDA	equ	8	; 1 = gota1 (rapida en pantallas 5, 10 y 13)
GOTA_TABLA_X	equ	9	; (2 bytes) tabla de X inicial segun pantalla

GOTA_HALT_INI	equ	$0a	; Fotogramas por fase de animacion

;===========================================================================
;	Puntos de entrada (los que se llaman desde jugabilidad-accN)
;===========================================================================
inicia_1ravez:
	ld	ix,gota1
	jr	gota_inicia_1ravez

inicia_1ravez2:
	ld	ix,gota2
	jr	gota_inicia_1ravez

gota_techo:
	ld	ix,gota1
	jp	gota_en_techo

gota_techo2:
	ld	ix,gota2
	jp	gota_en_techo

caer_gota:
	ld	ix,gota1
	jp	gota_cae

caer_gota2:
	ld	ix,gota2
	jp	gota_cae

gota_impactasuelo:
	ld	ix,gota1
	jp	gota_en_suelo

gota_impactasuelo2:
	ld	ix,gota2
	jp	gota_en_suelo

;===========================================================================
;	INICIA LA GOTA POR 1a VEZ (solo una vez por pantalla)
;---------------------------------------------------------------------------
gota_inicia_1ravez:
	ld	a,(settings3)
	and	(ix+GOTA_M_INI)
	ret	nz				;Ya iniciada

	ld	a,(settings3)
	or	(ix+GOTA_M_INI)
	ld	(settings3),a
	; (sigue en gota_inicia_techo)

;===========================================================================
;	INICIA GOTA-TECHO
;---------------------------------------------------------------------------
gota_inicia_techo:
	ld	a,(settings3)
	and	(ix+GOTA_M_TECHO)
	ret	nz				;Ya esta en el techo

	ld	a,(settings3)
	or	(ix+GOTA_M_TECHO)
	ld	(settings3),a

	ld	(ix+GOTA_CONT),$00
	ld	(ix+GOTA_HALT),GOTA_HALT_INI
	ld	(ix+GOTA_Y),$48			;Techo: tercio central

	;------------------------------------------------------------
	; X inicial segun la pantalla. Tabla: X por defecto, y luego
	; parejas (nivel, X) terminadas en $ff
	;------------------------------------------------------------
	ld	l,(ix+GOTA_TABLA_X)
	ld	h,(ix+GOTA_TABLA_X+1)

	ld	a,(hl)				;X por defecto
	ld	(ix+GOTA_X),a
	inc	hl

	call	busca_nivel_en_tabla
	ret	nz
	ld	(ix+GOTA_X),a
	ret

;------------------------------------------------------- X inicial gota1
tabla_x_gota1:
	defb	$70				;Por defecto
	defb	5,$6a,  7,$6d,  10,$4a,  13,$8a,  14,$6a,  19,$6d
	defb	$ff

;------------------------------------------------------- X inicial gota2
tabla_x_gota2:
	defb	$7c				;Por defecto
	defb	5,$76,  6,$76,  10,$57,  13,$97,  14,$78,  15,$78
	defb	$ff

;===========================================================================
;	GOTA EN EL TECHO (se va formando: 8 fases de 8 bytes)
;---------------------------------------------------------------------------
gota_en_techo:
	ld	h,(ix+GOTA_Y)
	ld	l,(ix+GOTA_X)

	ld	de,gotatecho

	;-------------------- gota1 en la pantalla 5: una fase por fotograma
	ld	a,(ix+GOTA_RAPIDA)
	or	a
	jr	z,techo_velocidad_normal

	ld	a,(nivel)
	cp	5
	jr	nz,techo_velocidad_normal

	inc	(ix+GOTA_CONT)
	jr	techo_fase

techo_velocidad_normal:
	dec	(ix+GOTA_HALT)
	call	z,gota_siguiente_fase

techo_fase:
	ld	a,(ix+GOTA_CONT)
	cp	$08
	jr	z,fin_gota_techo

	add	a,a
	add	a,a
	add	a,a				;Fase * 8 bytes
	call	suma_a_de

	ld	b,$08

bucle_dibuja_gotatecho:
	ld	a,(de)
	ld	(hl),a
	call	incrementar_scanline
	inc	de
	djnz	bucle_dibuja_gotatecho
	ret

;---------------------------------------------------------
fin_gota_techo:
	ld	a,(settings3)
	or	(ix+GOTA_M_TECHO)
	xor	(ix+GOTA_M_TECHO)		;Fin gota-techo
	ld	(settings3),a

	ld	b,$08

bucle_borrado_gotatecho:
	ld	(hl),$00
	call	incrementar_scanline
	djnz	bucle_borrado_gotatecho

	;------------------------------------------ Inicia la caida
	ld	a,(settings3)
	and	(ix+GOTA_M_CAE)
	ret	nz				;(ya estaba cayendo)

	ld	a,(settings3)
	or	(ix+GOTA_M_CAE)
	ld	(settings3),a

	ld	(ix+GOTA_Y),$48
	ret

;===========================================================================
;	GOTA CAYENDO
;---------------------------------------------------------------------------
gota_cae:
	ld	h,(ix+GOTA_Y)
	ld	l,(ix+GOTA_X)

	ld	a,l
	add	a,$20				;La gota mira una fila por debajo
	ld	c,a

	ld	a,(jugador_set)
	bit	6,a				;Jugador ya explotando?
	jr	nz,gota_cae_mover

	;------------------------------------------ Colision con el jugador
	call	colisiones_3_columnas
	call	gota_si_impacto

	;------------------------------------------ Mover
gota_cae_mover:
	ld	a,(ix+GOTA_RAPIDA)
	or	a
	jr	z,gota_cae_lenta

	ld	a,(nivel)
	cp	10
	jr	z,gota_cae_rapida
	cp	13
	jr	z,gota_cae_rapida

	;------------------------------------------ Lenta: 1 scanline
gota_cae_lenta:
	ld	(hl),$00			;Borra SOLO el 1er scanline (autoborrado)

	ld	de,gota

	call	incrementar_scanline
	ld	(ix+GOTA_X),l
	ld	(ix+GOTA_Y),h

	ld	a,h
	cp	$50				;3er tercio?
	call	z,gota_comprueba_suelo

	jp	dibuja_flechatrampa		;(dibuja la gota)

	;------------------------------------------ Rapida: 1 fila entera
gota_cae_rapida:
	ld	b,$08

bucle_borra_gotarapida:
	ld	(hl),$00
	call	incrementar_scanline
	djnz	bucle_borra_gotarapida

	ld	de,gota
	ld	a,(ix+GOTA_Y)
	add	a,$08				;incrementar_solofila resta 8 a H
	ld	h,a
	ld	l,(ix+GOTA_X)

	call	incrementar_solofila

	ld	(ix+GOTA_X),l
	ld	(ix+GOTA_Y),h

	ld	a,h
	cp	$50				;3er tercio?
	call	z,gota_comprueba_suelo

	jp	dibuja_flechatrampa		;(dibuja la gota)

;---------------------------------------------------------------------------
; Ha llegado al suelo? (filas $8x / $9x del 3er tercio). Conserva HL, DE, BC
;---------------------------------------------------------------------------
gota_comprueba_suelo:
	ld	a,(ix+GOTA_X)
	and	%11110000
	cp	$90
	jr	z,gota_llega_suelo
	cp	$80
	ret	nz

gota_llega_suelo:
	ld	a,(settings3)
	or	(ix+GOTA_M_CAE)
	xor	(ix+GOTA_M_CAE)			;Fin caida
	or	(ix+GOTA_M_SUELO)		;Empieza salpicadura
	ld	(settings3),a

	ld	a,SND_DISPARO
	call	sonido

	ld	(ix+GOTA_CONT),$00
	ld	(ix+GOTA_HALT),GOTA_HALT_INI

	ld	a,(ix+GOTA_X)
	add	a,$20				;Una fila mas abajo
	ld	(ix+GOTA_X),a
	ret

;---------------------------------------------------------------------------
; Si la gota ha dado al jugador (jugador_set bit6), deja de estar en el
; suelo y se podra volver a iniciar (flag INI a 0)
;---------------------------------------------------------------------------
gota_si_impacto:
	ld	a,(jugador_set)
	bit	6,a
	ret	z

	ld	a,(settings3)
	or	(ix+GOTA_M_SUELO)
	xor	(ix+GOTA_M_SUELO)
	or	(ix+GOTA_M_INI)
	xor	(ix+GOTA_M_INI)
	ld	(settings3),a
	ret

;===========================================================================
;	GOTA SALPICANDO EN EL SUELO (5 fases de 16 bytes)
;---------------------------------------------------------------------------
gota_en_suelo:
	ld	h,(ix+GOTA_Y)
	ld	l,(ix+GOTA_X)

	ld	a,l
	sub	$20
	ld	c,a

	ld	a,(jugador_set)
	bit	6,a				;Jugador ya explotando?
	jr	nz,gota_suelo_animacion

	;------------------------------------------ Colision con el jugador
	call	colisiones_4_columnas
	call	gota_si_impacto

	;---------------------------------------------------
gota_suelo_animacion:
	ld	de,gotasuelo

	dec	(ix+GOTA_HALT)
	call	z,gota_siguiente_fase

	ld	a,(ix+GOTA_CONT)
	cp	$05
	jr	z,fin_gota_suelo

	add	a,a
	add	a,a
	add	a,a
	add	a,a				;Fase * 16 bytes
	call	suma_a_de

	ld	b,$08

bucle_dibuja_gotasuelo:
	ld	a,l
	sub	$20				;Borra el byte de la fila de arriba
	ld	l,a
	ld	(hl),$00
	add	a,$20
	ld	l,a

	call	dibujados_repetitivos		;2 bytes

	dec	l
	call	incrementar_scanline
	inc	de
	djnz	bucle_dibuja_gotasuelo
	ret

;---------------------------------------------------------
fin_gota_suelo:
	ld	a,(settings3)
	or	(ix+GOTA_M_SUELO)
	xor	(ix+GOTA_M_SUELO)		;Fin salpicadura
	ld	(settings3),a

	ld	b,$08

bucle_borrado_gotasuelo:
	ld	(hl),$00
	inc	l
	ld	(hl),$00
	dec	l
	call	incrementar_scanline
	djnz	bucle_borrado_gotasuelo

	jp	gota_inicia_techo		;Vuelta a empezar el ciclo

;---------------------------------------------------------------------------
; Siguiente fase de la animacion (y reinicia el ralentizador)
;---------------------------------------------------------------------------
gota_siguiente_fase:
	ld	(ix+GOTA_HALT),GOTA_HALT_INI
	inc	(ix+GOTA_CONT)
	ret
