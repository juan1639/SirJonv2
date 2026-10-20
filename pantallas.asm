;===========================================================================
;
;		P A N T A L L A S   C O M O   D A T O S
;
;  Cada pantalla se describe con dos listas de "piezas" (ver
;  pantallas-datos.asm):
;
;     pantallaN ........ se dibuja una vez al entrar (atributos + fondo)
;     pantallaN_redib .. se redibuja cada fotograma (antorchas, puertas...)
;
;  Una lista es una secuencia de piezas terminada en P_FIN. Cada pieza es
;  un byte (codigo de pieza) seguido de sus parametros. Las piezas se
;  escriben con las macros de abajo, por ejemplo:
;
;     P_SUELO      $50c0                 ; suelo de ladrillos completo
;     P_VENTANA    $48b2, escudo         ; ventana/escudo (sprite 3 x 24)
;     P_RECT       $5920, 32, 2, AMARILLO ; rectangulo de atributos
;
;  dibuja_lista recorre la lista y llama, para cada pieza, a su rutina
;  'pz_...', que lee sus parametros con lee_hl / lee_de / lee_byte.
;
;  Para anadir un tipo de pieza: una entrada en tabla_piezas, su rutina
;  pz_... y su macro.
;===========================================================================

;===========================================================================
;			C O D I G O S   D E   P I E Z A
;===========================================================================
PZ_FIN			equ	$ff
PZ_LISTA		equ	0
PZ_CODIGO		equ	1
PZ_SUELO		equ	2
PZ_SUELO_SIMPLE		equ	3
PZ_LADRILLOS		equ	4
PZ_VENTANA		equ	5
PZ_PORTANTORCHA		equ	6
PZ_ANTORCHA		equ	7
PZ_PIEDRAS_ABAJO	equ	8
PZ_PIEDRAS_ARRIBA	equ	9
PZ_PIEDRA		equ	10
PZ_PUENTE		equ	11
PZ_TELARANA		equ	12
PZ_HILO			equ	13
PZ_PUERTAS		equ	14
PZ_ATTR			equ	15
PZ_RECT			equ	16
PZ_RELLENA		equ	17
PZ_ATTR_GOTA		equ	18
PZ_ATTR_GOTA2		equ	19
PZ_GRAFICO		equ	20
PZ_HUECO		equ	21

tabla_piezas:
	defw	pz_lista, pz_codigo, pz_suelo, pz_suelo_simple
	defw	pz_ladrillos, pz_ventana, pz_portantorcha, pz_antorcha
	defw	pz_piedras_abajo, pz_piedras_arriba, pz_piedra, pz_puente
	defw	pz_telarana, pz_hilo, pz_puertas, pz_attr
	defw	pz_rect, pz_rellena, pz_attr_gota, pz_attr_gota2
	defw	pz_grafico, pz_hueco

;===========================================================================
;				M A C R O S
;===========================================================================
;---------------------------------------------------------------- Control
P_FIN		MACRO			; Fin de la lista
		defb	PZ_FIN
		ENDM

P_LISTA		MACRO	lista		; Dibuja otra lista (sub-lista)
		defb	PZ_LISTA
		defw	lista
		ENDM

P_CODIGO	MACRO	rutina		; Llama a una rutina (casos especiales)
		defb	PZ_CODIGO
		defw	rutina
		ENDM

;---------------------------------------------------------------- Fondo
P_SUELO		MACRO	dir		; 2 filas de ladrillos (32 x 16 px) rectificadas
		defb	PZ_SUELO
		defw	dir
		ENDM

P_SUELO_SIMPLE	MACRO	dir		; Igual, sin rectificar el borde derecho
		defb	PZ_SUELO_SIMPLE
		defw	dir
		ENDM

P_LADRILLOS	MACRO	dir, n, paso	; n ladrillos (2 x 8 px) separados 'paso' bytes
		defb	PZ_LADRILLOS
		defw	dir
		defb	n, paso
		ENDM

P_VENTANA	MACRO	dir, sprite	; Ventana o escudo (3 x 24 px)
		defb	PZ_VENTANA
		defw	dir
		defw	sprite
		ENDM

P_PORTANTORCHA	MACRO	dir
		defb	PZ_PORTANTORCHA
		defw	dir
		ENDM

P_ANTORCHA	MACRO	dir		; Antorcha animada (en las listas _redib)
		defb	PZ_ANTORCHA
		defw	dir
		ENDM

P_PIEDRAS_ABAJO	MACRO	dir		; Suelo de piedras (dibuja_suelopiedras)
		defb	PZ_PIEDRAS_ABAJO	; con settings4 bit2 = 0
		defw	dir
		ENDM

P_PIEDRAS_ARRIBA MACRO	dir		; Idem con settings4 bit2 = 1
		defb	PZ_PIEDRAS_ARRIBA
		defw	dir
		ENDM

P_PIEDRA	MACRO	dir, sprite	; Una piedra (2 x 16 px)
		defb	PZ_PIEDRA
		defw	dir
		defw	sprite
		ENDM

P_PUENTE	MACRO	dir, n		; Puente de madera de n tramos
		defb	PZ_PUENTE
		defw	dir
		defb	n
		ENDM

P_TELARANA	MACRO	dir
		defb	PZ_TELARANA
		defw	dir
		ENDM

P_HILO		MACRO	dir		; Primer caracter del hilo de la arana
		defb	PZ_HILO
		defw	dir
		ENDM

P_GRAFICO	MACRO	dir, sprite, alto ; Grafico decorativo de 4 bytes de ancho
		defb	PZ_GRAFICO	; y 'alto' scanlines (rejilla 24, estandarte 32)
		defw	dir
		defw	sprite
		defb	alto
		ENDM

P_HUECO		MACRO	dir, ancho	; Hueco en el suelo: borra 16 scanlines
		defb	PZ_HUECO	; de 'ancho' bytes desde dir (pantallas de saltos)
		defw	dir
		defb	ancho
		ENDM

P_PUERTAS	MACRO			; Puertas interiores (pantallas 1, 7, 19)
		defb	PZ_PUERTAS
		ENDM

;---------------------------------------------------------------- Atributos
P_ATTR		MACRO	dir, color	; Un atributo
		defb	PZ_ATTR
		defw	dir
		defb	color
		ENDM

P_RECT		MACRO	dir, ancho, alto, color	; Rectangulo de atributos
		defb	PZ_RECT
		defw	dir
		defb	ancho, alto, color
		ENDM

P_RELLENA	MACRO	dir, n, color	; n atributos seguidos (1..255)
		defb	PZ_RELLENA
		defw	dir
		defb	n, color
		ENDM

P_ATTR_GOTA	MACRO	dir		; Columna de atributos de la gota 1
		defb	PZ_ATTR_GOTA
		defw	dir
		ENDM

P_ATTR_GOTA2	MACRO	dir		; Columna de atributos de la gota 2
		defb	PZ_ATTR_GOTA2
		defw	dir
		ENDM

;------------------------------------------- Atributos compuestos (macros)
A_MARCADORES	MACRO			; Las 2 filas de arriba (marcadores)
		P_RECT	$5800, 32, 2, AMARILLO_BRILLO
		ENDM

A_ANTORCHA	MACRO	dir		; Antorcha 3 x 2 (con el papel de la llama)
		P_RECT	dir, 3, 2, ROJO_BRILLO
		P_ATTR	dir + $21, %01010110
		ENDM

A_ESCUDO	MACRO	dir		; Escudo 3 x 3 rojo con la cruz
		P_RECT	dir, 3, 3, ROJO_BRILLO
		P_RECT	dir + 1, 1, 2, %01100010
		ENDM

A_REJILLA	MACRO	dir		; Rastrillo: todo amarillo
		P_RECT	dir, 4, 3, AMARILLO
		ENDM

A_ESTANDARTE	MACRO	dir, color	; Estandarte: lanza y mastil amarillos,
		P_RECT	dir, 4, 1, AMARILLO	; tela 'color'
		P_RECT	dir + $20, 4, 2, color
		P_RECT	dir + $60, 4, 1, AMARILLO
		ENDM

A_VENTANA	MACRO	dir		; Ventana 3 x 3 amarilla
		P_RECT	dir, 3, 3, AMARILLO
		ENDM

A_PORTANTORCHA	MACRO	dir
		P_ATTR	dir, BLANCO_BRILLO
		ENDM

A_TELARANA	MACRO	dir		; Tela 2 x 2 + nudo + hilo de 8 filas
		P_RECT	dir + $41, 1, 1, BLANCO_BRILLO
		P_RECT	dir + $60, 2, 8, BLANCO_BRILLO
		P_RECT	dir, 2, 2, BLANCO_BRILLO
		ENDM

;===========================================================================
;			I N T E R P R E T E
;===========================================================================

;---------------------------------------------------------------------------
; DIBUJA LISTA:  HL = lista de piezas.  Altera todos los registros
;---------------------------------------------------------------------------
dibuja_lista:
	ld	(lista_ptr),hl

siguiente_pieza:
	ld	hl,(lista_ptr)
	ld	a,(hl)				;Codigo de pieza
	inc	hl
	ld	(lista_ptr),hl

	cp	PZ_FIN
	ret	z

	add	a,a
	ld	l,a
	ld	h,$00
	ld	de,tabla_piezas
	add	hl,de

	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl				;HL = rutina de la pieza

	ld	de,siguiente_pieza		;Al terminar vuelve al bucle
	push	de
	jp	(hl)

;---------------------------------------------------------------------------
; Lectura de parametros
;---------------------------------------------------------------------------
lee_hl:					;HL = word de la lista.  Altera DE
	ld	hl,(lista_ptr)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	(lista_ptr),hl
	ex	de,hl
	ret

lee_de:					;DE = word de la lista
	push	hl
	call	lee_hl
	ex	de,hl
	pop	hl
	ret

lee_byte:				;A = byte de la lista
	push	hl
	ld	hl,(lista_ptr)
	ld	a,(hl)
	inc	hl
	ld	(lista_ptr),hl
	pop	hl
	ret

;===========================================================================
;			R U T I N A S   D E   P I E Z A
;===========================================================================
pz_lista:
	call	lee_hl
	ld	de,(lista_ptr)			;Guarda donde ibamos...
	push	de
	call	dibuja_lista
	pop	de
	ld	(lista_ptr),de			;...y sigue por ahi
	ret

pz_codigo:
	call	lee_hl
	jp	(hl)

pz_suelo:
	call	lee_hl
	jp	dibuja_suelo_completo

pz_suelo_simple:
	call	lee_hl
	jp	dibuja_elsuelo

pz_ladrillos:
	call	lee_hl
	call	lee_byte
	ld	b,a
	call	lee_byte
	ld	c,a
	jp	dibuja_ladrillos

pz_ventana:
	call	lee_hl
	call	lee_de
	jp	dibuja_unaventana

pz_portantorcha:
	call	lee_hl
	jp	dibuja_portantorcha

pz_antorcha:
	call	lee_hl
	jp	dibuja_antorcha

pz_piedras_abajo:
	ld	a,(settings4)
	res	2,a
	ld	(settings4),a
	call	lee_hl
	jp	dibuja_suelopiedras

pz_piedras_arriba:
	ld	a,(settings4)
	set	2,a
	ld	(settings4),a
	call	lee_hl
	jp	dibuja_suelopiedras

pz_piedra:
	call	lee_hl
	call	lee_de
	jp	dibuja_piedra

pz_puente:
	call	lee_hl
	call	lee_byte
	ld	b,a
	ld	de,puente_madera
	jp	dibuja_puente

pz_telarana:
	call	lee_hl
	jp	dibuja_tela_arana

pz_hilo:
	call	lee_hl
	jp	dibuja_hilo_primer

pz_puertas:
	jp	dibuja_puertas_interior

pz_attr:
	call	lee_hl
	call	lee_byte
	ld	(hl),a
	ret

pz_hueco:
	call	lee_hl
	call	lee_byte
	ld	c,a				;C = ancho
	ld	b,16

bucle_pz_hueco:
	push	bc
	push	hl
	ld	b,c
bucle_pz_hueco_fila:
	ld	(hl),0
	inc	l
	djnz	bucle_pz_hueco_fila
	pop	hl
	call	incrementar_scanline
	pop	bc
	djnz	bucle_pz_hueco
	ret

pz_grafico:
	call	lee_hl
	call	lee_de
	call	lee_byte			;A = alto (scanlines)
	ld	b,a
	; (sigue en dibuja_grafico)

;---------------------------------------------------------------------------
; GRAFICO DECORATIVO: 4 bytes x B scanlines desde DE en HL
;---------------------------------------------------------------------------
dibuja_grafico:

bucle_dibuja_grafico:
	push	bc
	push	hl
	ex	de,hl
	ld	bc,4
	ldir					;(HL) -> (DE), 4 bytes
	ex	de,hl				;DE = siguiente scanline del sprite
	pop	hl
	call	incrementar_scanline
	pop	bc
	djnz	bucle_dibuja_grafico
	ret

pz_rect:
	call	lee_hl
	call	lee_byte
	ld	c,a				;C = ancho
	call	lee_byte
	ld	b,a				;B = alto
	call	lee_byte			;A = color

bucle_rect_filas:
	push	bc
	push	hl
	ld	b,c

bucle_rect_columnas:
	ld	(hl),a
	inc	hl
	djnz	bucle_rect_columnas

	pop	hl
	ld	de,$0020			;Fila siguiente
	add	hl,de
	pop	bc
	djnz	bucle_rect_filas
	ret

pz_rellena:
	call	lee_hl
	call	lee_byte
	ld	b,a				;B = cuantos
	call	lee_byte			;A = color

bucle_rellena:
	ld	(hl),a
	inc	hl
	djnz	bucle_rellena
	ret

pz_attr_gota:
	call	lee_hl
	jp	sub_attr_gota

pz_attr_gota2:
	call	lee_hl
	jp	sub_attr_gota2

;===========================================================================
;		P I E Z A S   D E   D I B U J O   N U E V A S
;===========================================================================

;---------------------------------------------------------------------------
; SUELO COMPLETO: dibuja_elsuelo + rectificado del ultimo ladrillo de cada
; fila (HL + $1e y HL + $3e)
;---------------------------------------------------------------------------
dibuja_suelo_completo:
	push	hl
	call	dibuja_elsuelo
	pop	hl

	push	hl
	ld	a,l
	add	a,$1e
	ld	l,a
	ld	de,bloques_ladrillos
	ld	b,$08
	call	bucle_rectifica1
	pop	hl

	ld	a,l
	add	a,$3e
	ld	l,a
	ld	de,bloques_ladrillos
	ld	b,$08
	jp	bucle_rectifica2

;---------------------------------------------------------------------------
; LADRILLOS: B ladrillos (2 x 8 px) desde HL, separados C bytes
;---------------------------------------------------------------------------
dibuja_ladrillos:
	push	bc
	ld	de,bloques_ladrillos
	ld	b,$08

bucle_scans_ladrillo:
	call	dibujados_repetitivos		;2 bytes

	inc	l
	inc	de
	dec	l
	dec	l
	inc	h
	inc	de				;(el sprite tiene 4 bytes por scanline)
	djnz	bucle_scans_ladrillo

	call	sub8_h
	pop	bc
	ld	a,l
	add	a,c				;Siguiente ladrillo
	ld	l,a
	djnz	dibuja_ladrillos
	ret

;---------------------------------------------------------------------------
; PIEDRA: 2 x 16 px desde DE (3 bytes por scanline) en HL
;---------------------------------------------------------------------------
dibuja_piedra:
	ld	b,$10

bucle_scans_piedra:
	call	dibujados_repetitivos

	inc	l
	inc	de
	dec	l
	dec	l
	call	incrementar_scanline
	inc	de
	djnz	bucle_scans_piedra
	ret
