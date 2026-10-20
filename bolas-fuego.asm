;===========================================================================
;
;			 B O L A S   D E   F U E G O
;
;  Bolas que suben y bajan sin parar (pantallas 9, 11 y 12). Sprite
;  'bolasde_fuego': 2 bytes x 16 scanlines, 2 fotogramas para subir
;  (+0, +32) y 2 para bajar (+64, +96).
;
;  Tabla 'bolas_fuego' (var.asm), 4 bytes por bola:
;     +0 Y (H)   +1 X (L)   +2 contador animacion   +3 sentido (bit0: 1 = baja)
;  El sentido se cambia incrementando el byte +3.
;
;  Pantalla 9: 3 bolas.  Pantallas 11 y 12: 4 bolas.
;===========================================================================
BOLA_Y		equ	0
BOLA_X		equ	1
BOLA_ANIM	equ	2
BOLA_SENTIDO	equ	3

BOLA_ANIM_MAX	equ	$12		; Ciclo de animacion (0..$11)
BOLA_ANIM_MITAD	equ	$09		; Cambio de fotograma

;===========================================================================
sub_bolasfuego:
	ld	ix,bolas_fuego

	ld	b,$04
	ld	a,(nivel)
	cp	9
	jr	nz,bucle_cuantasbolas
	ld	b,$03

bucle_cuantasbolas:
	push	bc

	ld	h,(ix+BOLA_Y)
	ld	l,(ix+BOLA_X)

	ld	a,l
	add	a,$20				;Mira una fila por debajo
	ld	c,a

	;------------------------------------------ Colision con el jugador
	ld	a,(jugador_set)
	bit	6,a				;Jugador ya explotando?
	jr	nz,mueve_bolafuego

	call	colisiones_4_columnas		;jugador_x - 1 ... + 2

	;------------------------------------------ Sube o baja
mueve_bolafuego:
	bit	0,(ix+BOLA_SENTIDO)
	jr	nz,bolafuego_baja
	call	arriba_bolafuego
	jr	siguiente_bolafuego

bolafuego_baja:
	call	abajo_bolafuego

siguiente_bolafuego:
	ld	de,$0004			;Siguiente bola
	add	ix,de

	pop	bc
	djnz	bucle_cuantasbolas
	ret

;---------------------------------------------------------------------------
; SUBIENDO: sube 1 scanline; al llegar a H = $48 cambia de sentido
;---------------------------------------------------------------------------
arriba_bolafuego:
	call	decrementar_scanline
	ld	(ix+BOLA_X),l
	ld	(ix+BOLA_Y),h

	ld	a,h
	cp	$48
	call	z,bolafuego_cambia_sentido

	ld	de,bolasde_fuego
	call	dibuja_bolafuego

	call	incrementar_scanline		;Borra el scanline de debajo
	ld	(hl),$00
	inc	l
	ld	(hl),$00
	dec	l
	ret

;---------------------------------------------------------------------------
; BAJANDO: borra el scanline de arriba y baja 1; al llegar al suelo
; (tercio 3, filas $8x/$9x) cambia de sentido
;---------------------------------------------------------------------------
abajo_bolafuego:
	ld	(hl),$00
	inc	l
	ld	(hl),$00
	dec	l

	call	incrementar_scanline
	ld	(ix+BOLA_X),l
	ld	(ix+BOLA_Y),h

	ld	a,h
	cp	$50
	jr	nz,abajo_bolafuego_dibuja

	ld	a,(ix+BOLA_X)
	and	%11110000
	cp	$90
	call	z,bolafuego_cambia_sentido
	ld	a,(ix+BOLA_X)
	and	%11110000
	cp	$80
	call	z,bolafuego_cambia_sentido

abajo_bolafuego_dibuja:
	ld	de,bolasde_fuego+64
	; (sigue en dibuja_bolafuego)

;---------------------------------------------------------------------------
; Avanza la animacion y dibuja la bola (2 x 16).  DE = sprites del sentido
;---------------------------------------------------------------------------
dibuja_bolafuego:
	ld	a,(ix+BOLA_ANIM)
	inc	a
	cp	BOLA_ANIM_MAX
	jr	nz,bolafuego_guarda_anim
	xor	a
bolafuego_guarda_anim:
	ld	(ix+BOLA_ANIM),a

	cp	BOLA_ANIM_MITAD
	ld	a,32
	call	nc,suma_a_de			;2o fotograma

	ld	b,$10

bucle_dibuja_bolasfuego:
	call	dibujados_repetitivos
	dec	l
	call	incrementar_scanline
	inc	de
	djnz	bucle_dibuja_bolasfuego
	ret

;---------------------------------------------------------------------------
bolafuego_cambia_sentido:
	inc	(ix+BOLA_SENTIDO)

	ld	a,SND_DISPARO
	jp	sonido
