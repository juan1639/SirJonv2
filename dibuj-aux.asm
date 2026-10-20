;===========================================================================
;---  S U B - D I B U J A D O S   R E P E T I T I V O S  (2 bytes)       ---
;---------------------------------------------------------------------------
dibujados_repetitivos:
	ld	a,(de)			
	ld	(hl),a

	inc	l
	inc	de

	ld	a,(de)
	ld	(hl),a
ret

;===========================================================================
; SUB - D I B U J A D O S   R E P E T I T I V O S   I I (inc-byte inc-byte)
;---------------------------------------------------------------------------
dibujados_repetitivos2:
	inc	l
	inc	de

	ld	a,(de)
	ld	(hl),a

	inc	l
	inc	de

	ld	a,(de)
	ld	(hl),a
ret

;==========================================================================
sub8_h:
ld	a,h
sub	$08
ld	h,a
ret

;--------------------------------------------------------------------------
sub10_h:
ld	a,h
sub	$10
ld	h,a
ret

;===========================================================================
;	   SUB - BORRADOS REPETITIVOS (2bytes) (borrado con $00)
;---------------------------------------------------------------------------
borrados_repetitivos:			
	ld	(hl),$00
	inc	l
	ld	(hl),$00
ret

;===========================================================================
;---     S U B -  D I B U J A   S U E L O   (ES MUY REPETITIVO)          ---
;---                                                                     ---
;---       ( Nivel 1 ---> $50c0, Rectificados: $50de, $50fe )            ---
;---------------------------------------------------------------------------
dibuja_elsuelo:
	ld	de,bloques_ladrillos	; Situa DE en puntero bloques
	;ld	hl,$50c0		; Situa HL en 1ra posicion suelo
	ld	b,$20			; Bucle 2 filas de suelo entrelazado

	bucle_suelo:
		push	bc
		ld	b,$08			; Bucle Scanlines

		bucle_scansuelo:
			call	dibujados_repetitivos

			inc	l
			inc	de		;Incrementa bloque (DE) (vacio)

			dec	l
			dec	l
			inc	h
	
			inc	de		;Incrementa bloque (DE)
		djnz 	bucle_scansuelo

		call	sub8_h
		ld	a,(nivel)
		cp	$01
		jr	nz,notrampa_niveluno

		ld	a,l
		cp	$ca
		call	z,trampa1

		notrampa_niveluno:
		inc	l
		inc	l				;Vuelve...

		ld	de,bloques_ladrillos		;Reinicia DE (Bloque)
		pop	bc

		ld	a,b
		cp	$11				;2da fila suelo?...
		jr	nz,entrelazado			;...entonces entrelazar

		dec	l				;Decrementa para ENTRELAZAR

		entrelazado:
	djnz	bucle_suelo
ret

;---------------------------------------------------------------------------
bucle_rectifica1:
	ld	a,(de)		
	;ld	(hl),a			;No dibujar (parte izda del ladrillo)

	inc	l
	inc	de
	ld	a,(de)
	ld	(hl),a			;Dibujar SOLO parte dcha del ladrillo

	inc	l
	inc	de

	dec	l
	dec	l
	inc	h
	inc	de
djnz	bucle_rectifica1
ret

;---------------------------------------------------------------------------
bucle_rectifica2:
	;ld	a,(de)
	;ld	(hl),a

	inc	l
	;inc	de
	ld	a,(de)		;Dibujar parte Dcha del ladrillo, PERO dibujando en
	ld	(hl),a		;... esa parte Dcha la parte Izquierda del ladrillo

	inc	l
	inc	de
	inc	de

	dec	l
	dec	l
	inc	h
	inc	de
djnz	bucle_rectifica2
ret

;===========================================================================
;-   S U B -  D I B U J A   U N A   A N T O R C H A 			 ---   
;---                                                                     ---
;---------------------------------------------------------------------------
dibuja_antorcha:
	ld	a,(anima_antorchas)		;Contador de la animacion (32..1)
	dec	a
	jr	nz,antorcha_guarda_contador
	ld	a,$20
antorcha_guarda_contador:
	ld	(anima_antorchas),a

	ld	de,antorchas			;Fotograma 1 (contador < 15)...
	cp	$0f
	jr	c,antorcha_dibuja
	ld	de,antorchas+48			;...o fotograma 2

antorcha_dibuja:
	ld	b,$10

	bucle_dibuja_antorcha:
		call	dibujados_repetitivos

		inc	l
		inc	de
		ld	a,(de)
		ld	(hl),a

		dec	l
		dec	l
		call	cambio_scanline_linea

		inc	de
	djnz	bucle_dibuja_antorcha
ret

;------------------------------------------------
; Ladrillo-trampa de la pantalla 1 (lo usa dibuja_elsuelo)
;------------------------------------------------
trampa1:
	inc	h
	ld	(hl),%00101010			;Ladrillo trampa (diferenciarlo)
	inc	h
	ld	(hl),%00010101			;Otro scanline...
	dec	h
	dec	h
	ret

;================================================================
;---        SUB - DIBUJA PORTA-ANTORCHAS ( Repetitivo )       ---
;----------------------------------------------------------------
dibuja_portantorcha:
	ld	de,porta_antorcha
	ld	b,$08

	bucle_dibuja_portantorcha:
		inc	l
		inc	de

		ld	a,(de)
		ld	(hl),a

		dec	l
		inc	de

		inc	h
		inc	de
	djnz	bucle_dibuja_portantorcha
ret

;===========================================================================
;---   S U B -  D I B U J A   UNA   V E N T A N A (ES MUY REPETITIVO)    ---
;---                                                                     ---
;---------------------------------------------------------------------------
dibuja_unaventana:
	;ld	de,ventana
	ld	b,$18

	bucle_dibujaventana:
		call	dibujados_repetitivos

		inc	l
		inc	de
		ld	a,(de)
		ld	(hl),a

		dec	l
		dec	l
		call	incrementar_scanline

		inc	de
	djnz	bucle_dibujaventana
ret

;==========================================================================
;	SUB - DIBUJA PUERTAS INTERIORES
;
;    (LA DE ABAJO NECESITAS O LLAVE O MINIMO ELIMINAR AL ARQUERO...)
;--------------------------------------------------------------------------
dibuja_puertas_interior:
	ld	a,(nivel)
	cp	$13
	jr	z,confirmado_aparece_puerta_interior

	;-------------------------- Dibuja Puerta Interior ---------------
	ld	h,$48
	ld	l,PUERTA_INTERIOR_ARRIBA_POS_X
	
	ld	de,puerta_interior
	
	ld	b,$18

	bucle_puertainterior:
		ld	a,(de)
		ld	(hl),a
		
		inc	l
		inc	de

		ld	a,(de)
		ld	(hl),a
		
		inc	l
		inc	de
		ld	a,(de)
		ld	(hl),a
		
		dec	l
		dec	l

		call	incrementar_scanline
		inc	de
	djnz	bucle_puertainterior

	ld	h,$59
	ld	l,PUERTA_INTERIOR_ARRIBA_POS_X
	call	attr_puertas_interiores
	
	;---------------------------------------------------------------------------
	;------------------------- Dibuja Aparece-Puerta (ON/OFF) ------------------
	;---------------------------------------------------------------------------
	ld	a,(nivel)
	cp	$01
	jr	z,aparece_puerta_nivel1

	cp	$07
	jr	z,aparece_puerta_nivel7

	confirmado_aparece_puerta_interior:
		ld	h,$50
		ld	l,PUERTA_INTERIOR_ABAJO_POS_X
	
		ld	de,puerta_interior

		ld	b,$18

		bucle_aparece_puertainterior:
			ld	a,(de)
			ld	(hl),a

			inc	l
			inc	de

			ld	a,(de)
			ld	(hl),a

			inc	l
			inc	de
			ld	a,(de)
			ld	(hl),a

			dec	l
			dec	l

			call	incrementar_scanline
			inc	de
		djnz	bucle_aparece_puertainterior

		ld	h,$5a
		ld	l,PUERTA_INTERIOR_ABAJO_POS_X
		call	attr_puertas_interiores
ret

;---------------------------------------------
aparece_puerta_nivel1:
	ld	a,(settings)
	bit	7,a
	jr	nz,confirmado_aparece_puerta_interior	
ret

;---------------------------------------------
aparece_puerta_nivel7:
	ld	a,(settings4)
	bit	1,a
	jr	nz,confirmado_aparece_puerta_interior	
ret

;---------------------------------------------
attr_puertas_interiores:
	ld	(hl),%00000110		;attr-amarillo

	inc	l
	ld	(hl),%00000110

	inc	l
	ld	(hl),%00000110

	ld	a,l
	add	a,$20
	ld	l,a
		
	ld	(hl),%00000110

	dec	l
	ld	(hl),%00000110

	dec	l
	ld	(hl),%00000110

	ld	a,l
	add	a,$20
	ld	l,a
		
	ld	(hl),%00000110

	inc	l
	ld	(hl),%00000110

	inc	l
	ld	(hl),%00000110
ret

;===========================================================================
;---                S U B -  D I B U J A   P U E N T E                   ---
;---------------------------------------------------------------------------
dibuja_puente:
	bucle_vacios:
		push	bc
		ld	b,$10

		bucle_scans_vacios:
			call	dibujados_repetitivos

			inc	l
			inc	de

			dec	l
			dec	l

			call	incrementar_scanline
			inc	de
		djnz	bucle_scans_vacios

		ld	h,$50
		inc	l
		inc	l
		ld	a,l
		add	a,$c0
		ld	l,a

		ld	de,puente_madera
		pop	bc
	djnz	bucle_vacios
ret

;============================================================================
;---        S U B -  D I B U J A   T E L A   A R A N A                    ---
;----------------------------------------------------------------------------
dibuja_tela_arana:
	ld	de,tela_arana
	;call	piedra_tipouno

	ld	b,$10

	bucle_scans_telarana:
		call	dibujados_repetitivos

		inc	l
		inc	de

		dec	l
		dec	l
		call	incrementar_scanline
		inc	de
	djnz	bucle_scans_telarana
ret

;============================================================================
;---        S U B -  D I B U J A   H I L O   (1ER CARACTER SOLO)          ---
;----------------------------------------------------------------------------
dibuja_hilo_primer:
	;--------------- Hilo (Primer caracter) ------------ 
	ld	b,$08

	bucle_scans_hilo:
		ld	(hl),$10

		call	incrementar_scanline
	djnz	bucle_scans_hilo
ret

;============================================================================
;---        S U B -  D I B U J A   S U E L O   P I E D R A S              ---
;----------------------------------------------------------------------------
dibuja_suelopiedras:
	ld	de,piedras
	ld	b,$10

	bucle_piedras2:
		push	bc
		ld	a,b
		bit	0,b
		call	z,piedra_tipouno
		call	nz,piedra_tipodos

		ld	b,$10

		bucle_scans_piedras2:
			call	dibujados_repetitivos

			inc	l
			inc	de

			dec	l
			dec	l
			call	incrementar_scanline
			inc	de
		djnz	bucle_scans_piedras2

		ld	a,(settings4)
		bit	2,a
		call	z,h_cincuenta
		call	nz,h_cuarentayocho

		inc	l
		inc	l
		ld	a,l
		add	a,$c0
		ld	l,a

		pop	bc
	djnz	bucle_piedras2
ret

;--------------------------------------------------
piedra_tipouno:
	ld	de,piedras+48
ret

piedra_tipodos:
	ld	de,piedras+96
ret

;--------------------------------------------------
h_cincuenta:
	ld	h,$50
ret

h_cuarentayocho:
	ld	h,$48
ret




