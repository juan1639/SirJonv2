;===========================================================================
;
;		A T R I B U T O S   D E   L A S   G O T A S
;
;  (El resto de atributos de las pantallas esta ahora en
;   pantallas-datos.asm)
;
;  Cada gota tiene una columna de atributos por la que cae: se pinta en
;  la direccion HL y luego, desde HL - 1, hacia arriba (11 filas; 12 en
;  la pantalla 10 y 10 en la 13). Se usa desde las listas _redib con
;  P_ATTR_GOTA / P_ATTR_GOTA2.
;===========================================================================
ATTR_GOTA1	equ	%01000100		; Verde brillo
ATTR_GOTA2	equ	%01000011		; Magenta brillo

;---------------------------------------------------------------------------
sub_attr_gota:
	ld	c,ATTR_GOTA1
	jr	attr_columna_gota

;---------------------------------------------------------------------------
sub_attr_gota2:
	ld	c,ATTR_GOTA2
	; (sigue en attr_columna_gota)

;---------------------------------------------------------------------------
; Columna de atributos C: en HL y, desde HL - 1, B filas hacia arriba
;---------------------------------------------------------------------------
attr_columna_gota:
	ld	(hl),c
	dec	l

	ld	b,11
	ld	a,(nivel)
	cp	10
	jr	nz,attr_gota_no_10
	ld	b,12
attr_gota_no_10:
	cp	13
	jr	nz,bucle_attr_gota
	ld	b,10

bucle_attr_gota:
	ld	(hl),c
	ld	a,l
	sub	$20				;Fila de arriba...
	ld	l,a
	jr	nc,attr_gota_mismo_tercio
	ld	h,$59				;...que esta en el tercio 2
attr_gota_mismo_tercio:
	djnz	bucle_attr_gota
	ret
