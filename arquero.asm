;===========================================================================
;
;				A R Q U E R O
;
;  Esta quieto a la derecha (ARQUERO_POS_Y/X) y dispara flechas
;  (flecha-arquero.asm). Sprite 'arqueros': 3 bytes x 16 scanlines;
;  cuando no hay flecha en el aire se dibuja 'apuntando'.
;
;  settings bit5 = 1 -> arquero muerto (OJO: al reves)
;  settings bit2 = explosion del arquero en marcha
;  Al matarlo aparece la puerta (settings bit7) y no vuelve a disparar
;  (settings4 bit6).
;===========================================================================

;===========================================================================
;	ARQUERO (se llama cada fotograma mientras esta vivo)
;
;  En las pantallas 1 y 7 solo aparece si estas en el suelo y no tienes
;  la llave.
;---------------------------------------------------------------------------
arquero_on:
	ld	a,(nivel)
	cp	NIVEL_DOS_PISOS_B
	jr	z,check_si_llave_retornar
	cp	NIVEL_DOS_PISOS_A
	jr	z,check_si_llave_retornar

no_llave_arquero_confirmado:
	ld	a,(jugador_x)
	cp	ARQUERO_POS_X - 1		;Pegado al arquero?
	jr	z,colision_vsarquero

	;------------------------------------------ Ataque con la espada
	ld	a,(jugador_set)
	bit	4,a
	jr	z,dibuja_arquero

	ld	a,(jugador_x)
	cp	ARQUERO_POS_X - 2
	call	z,inicia_exploarquero

	cp	ARQUERO_POS_X - 3		;(OJO: A puede venir de inicia_exploarquero,
	call	z,inicia_exploarquero		; como en el original)

	;------------------------------------------ Dibuja
dibuja_arquero:
	ld	de,arqueros+48			;Apuntando (no hay flecha en el aire)
	ld	a,(settings)
	bit	4,a
	jr	z,dibuja_arquero_sprite
	ld	de,arqueros			;Normal

dibuja_arquero_sprite:
	ld	h,ARQUERO_POS_Y
	ld	l,ARQUERO_POS_X

	ld	b,$10

bucle_dibujarquero:
	call	dibujados_repetitivos		;bytes 1 y 2

	inc	l
	inc	de
	ld	a,(de)				;byte 3
	ld	(hl),a

	dec	l
	dec	l
	call	incrementar_scanline
	inc	de
	djnz	bucle_dibujarquero

	;------------------------------------------ Atributos
	; fila de arriba ROJO, fila de abajo MAGENTA
	ld	hl,$5a9c
	ld	a,ROJO
	ld	b,$02

bucle_attr_arquero:
	ld	(hl),a
	inc	l
	ld	(hl),a
	inc	l
	ld	(hl),a

	ld	a,l
	add	a,$1e				;Fila de abajo
	ld	l,a
	ld	a,ROJO + 1			;Magenta
	djnz	bucle_attr_arquero
	ret

;----------------------------------------------------------------
; Pantallas 1 y 7: solo si estas en el suelo y sin la llave
;----------------------------------------------------------------
check_si_llave_retornar:
	ld	a,(jugador_y)
	cp	JUGADOR_Y_SUELO
	ret	nz

	ld	a,(settings4)
	bit 	1,a
	jr	z,no_llave_arquero_confirmado
	ret

;----------------------------------------------------------------
; Tocar al arquero: el jugador muere y el arquero tambien explota
;----------------------------------------------------------------
colision_vsarquero:
	ld	a,(jugador_timer_invisib)
	or	a				;Invisible: no hay colision
	ret	nz

	call	jugador_muere
	; (sigue en inicia_exploarquero)

;===========================================================================
;	INICIA EXPLO-ARQUERO (solo una vez y si estas en el suelo)
;---------------------------------------------------------------------------
inicia_exploarquero:
	ld	a,(settings)
	bit	2,a
	ret	nz				;Ya esta explotando

	ld	a,(jugador_y)
	cp	JUGADOR_Y_SUELO
	ret	nz

	ld	a,SND_BEEP
	call	sonido

	;---------------------------------------------------------------
	ld	a,(settings4)
	set	6,a				;Ya no salen mas flechas
	ld	(settings4),a

	ld	a,(settings)
	set	5,a				;Arquero muerto (OJO: al reves)
	set	2,a				;Explo-arquero ON
	set	7,a				;Aparece la puerta
	ld	(settings),a

	ld	a,(nivel)
	cp	NIVEL_DOS_PISOS_B
	call	z,need_key			;En la 7 ademas hace falta la llave

	;---------------------------------------------------------------
	xor	a
	ld	(contador_explo),a

	ld	a,ARQUERO_POS_Y
	ld	(explo_arqueroy),a
	ld	a,ARQUERO_POS_X
	ld	(explo_arquerox),a
	ret

;--------------------------------------------------------------------------
; Pantalla 7: la puerta no aparece hasta tener la llave
;--------------------------------------------------------------------------
need_key:
	ld	a,(settings)
	res	7,a				;Sin puerta (todavia)
	ld	(settings),a

	ld	a,(settings4)
	bit	1,a
	ret	nz				;Ya tienes la llave

	set	0,a				;Necesitas la llave
	ld	(settings4),a
	ret

;===========================================================================
;	EXPLO-ARQUERO  (8 fases de 48 bytes de 'arqueros_explo', 3 x 16)
;---------------------------------------------------------------------------
explo_arquero:
	ld	a,(contador_explo)
	inc	a
	ld	(contador_explo),a
	cp	$08
	jr	z,fin_explo_arquero

	;------------------------------------------ DE = arqueros_explo + fase*48
	ld	l,a
	ld	h,$00
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl				;HL = fase * 16
	ld	d,h
	ld	e,l
	add	hl,hl
	add	hl,de				;HL = fase * 48
	ld	de,arqueros_explo
	add	hl,de
	ex	de,hl

	;------------------------------------------------------------
	ld	h,ARQUERO_POS_Y
	ld	l,ARQUERO_POS_X

	ld	b,$10

bucle_exploarquero:
	call	dibujados_repetitivos		;bytes 1 y 2

	inc	l
	inc	de
	ld	a,(de)				;byte 3
	ld	(hl),a

	ld	a,b				;Ralentiza en los scanlines 9 y 5
	cp	$09
	call	z,un_halt
	cp	$05
	call	z,un_halt

	dec	l
	dec	l
	call	incrementar_scanline
	inc	de
	djnz	bucle_exploarquero
	ret

;----------------------------------------------
fin_explo_arquero:
	ld	a,(settings)
	res	2,a				;Fin explo-arquero
	ld	(settings),a

	ld	h,ARQUERO_POS_Y
	ld	l,ARQUERO_POS_X
	ld	b,$10
	jp	borra_3_columnas
