;===========================================================================
;
;	P A N T A L L A   0  -  exterior del castillo (dibujado especial)
;
;  Esta pantalla no se parece a las demas (fachada, puente levadizo,
;  hierba, estrellas...) y se dibuja con codigo propio. Se usa desde
;  pantallas-datos.asm con P_CODIGO pantalla_zero / pantalla0_redibujable.
;
;===========================================================================
;			Fachada exterior del Castillo
;---------------------------------------------------------------------------
pantalla_zero:
	ld	de,bloques_ladrillos
	ld	hl,$4818
	ld	b,$3d

	bucle_columnas:
		push	bc
		ld	b,$08

	bucle_scanscastillo: 
		call	dibujados_repetitivos

		inc	l
		inc	de

		dec	l
		dec	l
		inc	h

		inc	de
		djnz 	bucle_scanscastillo

		ld	a,l
		and	%00001111
		cp	$0e
		call	z,suma_2filas
		cp	$0f
		call	z,suma_2filas2

		inc	l
		inc	l
		call	sub8_h

		ld	de,bloques_ladrillos
		pop	bc

		ld	a,b
		cp	$21
		call	z,cambio_tercio_castillo
	djnz	bucle_columnas

	;-----------------------------------------
	ld	de,bloques_ladrillos
	ld	hl,$40d8
	ld	b,$08

	bucle_columnas2:
		push	bc
		ld	b,$08

		bucle_scanscastillo2: 
			call	dibujados_repetitivos

			inc	l
			inc	de

			dec	l
			dec	l
			inc	h

			inc	de
		djnz 	bucle_scanscastillo2

		ld	a,l
		and	%00001111
		cp	$0e
		call	z,suma_2filas
		cp	$0f
		call	z,suma_2filas2

		inc	l
		inc	l
		call	sub8_h

		ld	de,bloques_ladrillos
		pop	bc
	djnz	bucle_columnas2

	;----------------------------------------------
	ld	de,bloques_ladrillos
	ld	hl,$40f8

	ld	b,$08

	bucle_scansrectificado_01:
		inc	de
		ld	a,(de)
		ld	(hl),a

		inc	l
		inc	de

		inc	l
		inc	de

		dec	l
		dec	l
		inc	h
	djnz	bucle_scansrectificado_01

	;---------------------------------------
	ld	hl,$40dc
	ld	b,$10

	bucle_hueco:
		ld	(hl),$00
		inc	l
		ld	(hl),$00

		dec	l
		inc	h
		ld	a,h
		and	%00000111
		jr	nz,nocambio_linea

		ld	a,l
		add	a,$20
		ld	l,a
		ld	h,$40

		nocambio_linea:
	djnz	bucle_hueco

	;----------------------------------------------
	ld	de,bloques_ladrillos
	ld	hl,$4859

	ld	b,$07

	bucle_rectificado_fachada:
		push	bc
		ld	b,$08

		bucle_scansrectificado_011:
			inc	de
			ld	a,(de)
			ld	(hl),a

			inc	l
			inc	de

			inc	l
			inc	de

			dec	l
			dec	l
			inc	h
		djnz	bucle_scansrectificado_011

		call	sub8_h

		ld	a,l
		add	a,$40
		ld	l,a
		call	c,cambio_tercio_castillo

		ld	de,bloques_ladrillos
		pop	bc
	djnz	bucle_rectificado_fachada

	;--------------------------------------------
	ld	hl,$4000
	ld	b,$03

	bucle_borrado_exterior:
		push	bc
		ld	b,$40

		bucle_scansborradoext:
			ld	(hl),$00

			inc	h
			ld	a,h
			and	%00000111
			jr	nz,nocambio_linea2

			ld	a,l
			add	a,$20
			ld	l,a

			call	sub8_h

			nocambio_linea2:
		djnz	bucle_scansborradoext

		ld	a,h
		add	a,$08
		ld	h,a
	
		pop	bc
	djnz	bucle_borrado_exterior

	;-------------------------------------------------
	;		Puente Levadizo Madera
	;-------------------------------------------------
	ld	de,puente_madera
	ld	hl,$50cf
	ld	b,$05

	bucle_puentemadera:
		push	bc
		ld	b,$08

		bucle_scans_puentemadera:
			call	dibujados_repetitivos

			inc	l
			inc	de

			dec	l
			dec	l
			inc	h
			inc	de
		djnz	bucle_scans_puentemadera

		call	sub8_h
		inc	l
		inc	l

		ld	de,puente_madera
		pop	bc
	djnz	bucle_puentemadera

	;-------------------------------------------------
	;		Hierba exterior
	;-------------------------------------------------
	ld	de,hierba
	ld	hl,$50c0
	ld	b,$10

	bucle_sueloexterior:
		push	bc
		ld	b,$08

		bucle_scans_sueloexterior:
			call	dibujados_repetitivos

			dec	l
			inc	h
			inc	de
		djnz	bucle_scans_sueloexterior

		call	sub8_h
		inc	l
		inc	l

		ld	de,hierba
		pop	bc

		ld	a,b
		cp	$09
		call	z,otrafila_sueloext
		ld	a,b
		call	c,otra_hierba
	djnz	bucle_sueloexterior

	;----------------------------------------------
	;	Borrado tras puente
	;----------------------------------------------
	borrado_tras_puente:
		ld	hl,$5099
		ld	a,$00
		ld	b,$07

		bucle_borrado_tras_puente:
			call sub_borrado_tras_puente
		djnz	bucle_borrado_tras_puente

		;------------------------------------
		ld	hl,$50b9
		ld	a,$00
		ld	b,$07

		bucle_borrado_tras_puente2:
			call sub_borrado_tras_puente
		djnz	bucle_borrado_tras_puente2

		;call	dos_filas_attr_jugador
ret

;---------------------------------------
sub_borrado_tras_puente:
	ld	(hl),a
	inc	h

	ld	(hl),a
	inc	h

	ld	(hl),a
	inc	h

	ld	(hl),a
	inc	h
		
	ld	(hl),a
	inc	h

	ld	(hl),a
	inc	h

	ld	(hl),a
	inc	h

	ld	(hl),a
	inc	l
	ld	h,$50
ret

;--------------------------------------------------------------
suma_2filas:
	ld	a,l
	add	a,$19
	ld	l,a
	ret
;jr	siguiente_fila

suma_2filas2:
	ld	a,l
	add	a,$19
	ld	l,a
ret

;--------------------------------------------------------------
cambio_tercio_castillo:
	ld	a,h
	ld	a,$50
	ld	h,a
ret

;--------------------------------------------------------------
otrafila_sueloext:
	ld	a,l
	add	a,$10
	ld	l,a
	ld	de,hierba+16
ret

otra_hierba:
	ld	de,hierba+16
ret

;===========================================================================
;---     SUB - PANTALLA 0 (PARTES REFRESCABLES / REDIBUJABLES)           ---
;---                                                                     ---
;---------------------------------------------------------------------------
;				Estrellas
;---------------------------------------------------------------------------
pantalla0_redibujable:
	ld	de,estrellas
	ld	b,$24

	bucle_estrellas:
		ld	a,(de)
		ld	h,a

		inc	de
		ld	a,(de)
		ld	l,a

		inc	de
		ld	a,(de)
		ld	(hl),a

		inc	de
	djnz	bucle_estrellas

	;----------------------------------------------
	;		   Eslabones
	;----------------------------------------------
	ld	de,eslabon
	ld	hl,$50b1
	ld	b,$08

	bucle_eslabones:
		push	bc
		ld	b,$08
	
		bucle_scanseslabones:
			ld	a,(de)
			ld	(hl),a

			inc	h
			inc	de
		djnz	bucle_scanseslabones
	
		;---------- attr --------------
		push	hl

		ld	a,h
		sub	$08
		call	cambioh_58595a
		ld	h,a
		ld	(hl),%01000101
	
		pop	hl

		;-----------------------------
		inc	l
		ld	a,l
		sub	$20
		ld	l,a
		call	nc,sub8_h
		call	c,sub10_h

		ld	de,eslabon
		pop	bc
	djnz	bucle_eslabones
ret

