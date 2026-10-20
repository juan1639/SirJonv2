;===========================================================================
;
;				 A R A N A
;
;  La arana baja desde el techo (tercio 2) colgada de su hilo hasta el
;  suelo y vuelve a subir, sin parar. Sprite 'arana': 2 bytes x 8 scanlines,
;  2 fotogramas de animacion.
;
;  settings4 bit3 = arana activa      bit4 = subiendo (0 = bajando)
;  settings4 bit5 = explosion (arana o murcielago) en marcha
;
;  Aqui esta tambien la explosion de la arana y del murcielago
;  (inicia_exploarana / explo_arana).
;===========================================================================

;===========================================================================
;	INICIA ARANA
;---------------------------------------------------------------------------
inicia_arana:
	ld	a,(settings4)
	bit	3,a
	ret	nz				;Ya esta

	set	3,a				;Arana ON
	ld	(settings4),a

	ld	a,$48
	ld	(arana_y),a			;Empieza en el tercio 2

	;------------------------------- X segun la pantalla (si no esta en la
	ld	hl,tabla_x_arana		;tabla, se queda la X que tenia)
	call	busca_nivel_en_tabla
	ret	nz
	ld	(arana_x),a
	ret

tabla_x_arana:
	defb	11,$a6,  12,$ae,  13,$ba,  14,$ba,  18,$b7,  19,$a6
	defb	$ff

;===========================================================================
;	MUEVE / DIBUJA LA ARANA
;---------------------------------------------------------------------------
cae_arana:
	ld	a,(arana_y)
	ld	h,a
	ld	a,(arana_x)
	ld	l,a
	ld	c,a				;C = columna de la arana

	ld	a,(jugador_set)
	bit	6,a				;Jugador ya explotando?
	jr	nz,arana_animacion

	;------------------------------------------ Ataque con la espada
	bit	4,a
	jr	z,colisiones_vsarana		;No atacamos

	bit	0,a
	jr	nz,comprueba_ataqueizda

	;------------------ Mirando a la derecha: la espada llega a X + 3
	dec	c
	dec	c
	dec	c
	ld	a,(jugador_x)
	cp	c
	call	z,inicia_exploarana
	inc	c
	inc	c
	inc	c
	jr	colisiones_vsarana

	;------------------ Mirando a la izquierda: la espada llega a X - 1
comprueba_ataqueizda:
	inc	c
	ld	a,(jugador_x)
	cp	c
	call	z,inicia_exploarana
	dec	c

	;------------------------------------------ Colision con el jugador
colisiones_vsarana:
	call	colisiones_4_columnas		;jugador_x - 1 ... + 2

	;------------------------------------------ Animacion (2 fotogramas)
	; cont_arana 0..7 -> fotograma 1,  8..14 -> fotograma 2
arana_animacion:
	ld	de,arana
	ld	a,(cont_arana)
	inc	a
	ld	(cont_arana),a
	cp	$08
	jr	c,arana_reinicia_anim
	ld	de,arana+16

arana_reinicia_anim:
	cp	$0f
	jr	nz,arana_mueve
	xor	a
	ld	(cont_arana),a

arana_mueve:
	ld	a,(settings4)
	bit	4,a
	jr	nz,arana_hacia_arriba

;---------------------------------------------------------------------------
; Bajando: borra el scanline de arriba (dejando el hilo), baja 1 scanline
;---------------------------------------------------------------------------
	ld	(hl),$00			;Borra el 1er scanline...
	inc	l
	ld	(hl),$10			;...pero deja el hilo (columna dcha)
	dec	l

	call	incrementar_scanline
	call	arana_guarda_posicion

	cp	$50				;Tercio 3?
	jr	nz,dibuja_arana

	call	arana_en_extremo		;En el suelo?
	jr	nz,dibuja_arana

	ld	a,(settings4)
	set	4,a				;Ahora sube
	ld	(settings4),a
	; (sigue en dibuja_arana)

;---------------------------------------------------------------------------
dibuja_arana:
	ld	b,$08

bucle_dibuja_arana:
	call	dibujados_repetitivos
	dec	l
	call	incrementar_scanline
	inc	de
	djnz	bucle_dibuja_arana
	ret

;---------------------------------------------------------------------------
; Subiendo: sube 1 scanline, dibuja y borra el scanline de debajo
;---------------------------------------------------------------------------
arana_hacia_arriba:
	call	decrementar_scanline
	call	arana_guarda_posicion

	cp	$48				;Tercio 2?
	jr	nz,arana_sube_dibuja

	call	arana_en_extremo		;Arriba del todo?
	jr	nz,arana_sube_dibuja

	ld	a,(settings4)
	res	4,a				;Ahora baja
	ld	(settings4),a

arana_sube_dibuja:
	call	dibuja_arana

	ld	(hl),$00			;Borra el scanline de debajo
	inc	l
	ld	(hl),$00
	dec	l
	ret

;---------------------------------------------------------------------------
; Guarda HL en arana_y / arana_x.  Sale con A = H
;---------------------------------------------------------------------------
arana_guarda_posicion:
	ld	a,l
	ld	(arana_x),a
	ld	a,h
	ld	(arana_y),a
	ret

;---------------------------------------------------------------------------
; Z si la arana esta en las filas $8x / $9x del tercio (extremo del hilo)
;---------------------------------------------------------------------------
arana_en_extremo:
	ld	a,(arana_x)
	and	%11110000
	cp	$90
	ret	z
	cp	$80
	ret

;===========================================================================
;	INICIA EXPLOSION DE LA ARANA / DEL MURCIELAGO
;
;  Se llama al darles con la espada; solo si estan en el tercio 3.
;  inicia_exploarana la llama la arana (cae_arana) y
;  inicia_explomurcielago el murcielago (que ademas da vidas extra).
;---------------------------------------------------------------------------
inicia_exploarana:
	ld	a,h
	cp	$50
	ret	nz

	call	sonido_explosion
	call	toca_arana
	jr	reinicia_contador_explo

inicia_explomurcielago:
	ld	a,h
	cp	$50
	ret	nz

	call	sonido_explosion
	call	toca_murcielago

reinicia_contador_explo:
	xor	a
	ld	(contador_explo),a
	ret

sonido_explosion:
	ld	a,SND_BEEP
	jp	sonido

;---------------------------------------------------
toca_arana:
	ld	a,(settings4)
	res	3,a				;Arana OFF
	set	5,a				;Explosion ON
	ld	(settings4),a

	ld	a,(arana_y)
	ld	(explo_fantasmay),a
	ld	a,(arana_x)
	ld	(explo_fantasmax),a
	ret

;---------------------------------------------------
toca_murcielago:
	ld	a,(settings4)
	set	5,a				;Explosion ON
	ld	(settings4),a

	ld	a,(settings2)
	res	0,a				;Murcielago OFF
	ld	(settings2),a

	ld	a,(settings_ch)
	bit	1,a
	call	z,sumar_vida_extra		;1a vida extra (una sola vez)

	ld	a,(settings_ch)
	bit	5,a
	call	z,sumar_vida_extra2		;2a vida extra (solo pantalla 17)

	ld	a,(murcielago_y)
	ld	(explo_fantasmay),a
	ld	h,a
	ld	a,(murcielago_x)
	ld	(explo_fantasmax),a
	ld	l,a
	jp	borra_murcielago		;Borra los 3 bytes de ancho (la
						;explosion solo ocupa 2)

;===========================================================================
;	EXPLOSION ARANA / MURCIELAGO
;	(8 fases de 24 bytes de 'murcielago_explo'; se dibujan 2 x 8)
;---------------------------------------------------------------------------
explo_arana:
	ld	a,(contador_explo)
	inc	a
	ld	(contador_explo),a
	cp	$08
	jr	z,fin_explo_arana

	ld	de,murcielago_explo
	ld	b,a
	add	a,a
	add	a,b				;x3
	add	a,a
	add	a,a
	add	a,a				;x24
	call	suma_a_de

	;-----------------------------------------
	ld	a,(explo_fantasmay)
	ld	h,a
	ld	a,(explo_fantasmax)
	ld	l,a

	ld	b,$08

bucle_exploarana:
	call	dibujados_repetitivos

	ld	a,b				;Ralentiza en los scanlines 5 y 1
	cp	$05
	call	z,un_halt
	cp	$01
	call	z,un_halt

	dec	l
	call	incrementar_scanline
	inc	de
	djnz	bucle_exploarana
	ret

;-------------------------------------------
fin_explo_arana:
	ld	a,(settings4)
	res	5,a				;Fin explosion
	ld	(settings4),a

	ld	a,(explo_fantasmay)
	ld	h,a
	ld	a,(explo_fantasmax)
	ld	l,a

	ld	b,$08

bucle_borrado_exploarana:
	ld	(hl),$00
	inc	l
	ld	(hl),$00
	dec	l
	call	incrementar_scanline
	djnz	bucle_borrado_exploarana
	ret
