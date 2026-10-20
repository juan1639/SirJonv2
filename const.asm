;==========================================================================
;			   C O N S T A N T E S
;
; (Las 'equ' no generan codigo: este fichero no ocupa memoria)
;--------------------------------------------------------------------------
	NUM_NIVELES			equ	22	; Pantallas 0..21
	NIVEL_PLAT_A			equ	20	; Pantallas de saltos (v2): van
	NIVEL_PLAT_B			equ	21	; entre la 10 y la 11 (10-20-21-11)
	NIVEL_ULTIMO			equ	19	; Ultima pantalla (puerta final)

	; Pantallas con 2 pisos (se puede subir al piso de arriba)
	NIVEL_DOS_PISOS_A		equ	1
	NIVEL_DOS_PISOS_B		equ	7

	NIVEL_VIDA_EXTRA2		equ	17	; Pantalla de la 2a vida extra

	JUGADOR_Y_SUELO			equ	$50	; Tercio inferior (suelo)
	JUGADOR_Y_PISO_ALTO		equ	$48	; Tercio central (1er piso)

	VIDAS_INICIALES			equ	$04
	DURACION_INVISIBLE_AL_REVIVIR	equ	$50

	JUGADOR_LIMITE_IZ		equ	$80
	JUGADOR_LIMITE_DE		equ	$9c

	JUGADOR_LIMITE_IZ_1_7		equ	$d0
	JUGADOR_LIMITE_DE_1_7		equ	$dd

	JUGADOR_START_POS_X		equ	$82

	JUGADOR_ROT_MAX			equ	$04

	ANTORCHA2_POS_INI		equ	$80
	ANTORCHA2_OFFSET		equ	$0c

	ANTORCHA3_POS_INI		equ	$a1
	ANTORCHA3_OFFSET		equ	$07

	PORTA_ANTORCHA2_POS_INI		equ	$cd
	PORTA_ANTORCHA3_POS_INI		equ	$e9

	MURCIELAGO_START_POS_Y		equ	$40
	MURCIELAGO_START_POS_X		equ	$60	;Fila 3 (debajo del marcador)
	MURCIELAGO_END_POS_X		equ	$9d

	MURCIELAGO_START_POS_Y_T3	equ	$50

	FLECHA_ARQU_END_POS_X		equ	$80
	FLECHA_ARQU_ULTIMO_BORRADO_POS_X  equ	$81

	ARQUERO_POS_Y			equ	$50
	ARQUERO_POS_X			equ	$9c

	POS_X_ENTRE_PUERTAS_ABAJO	equ	$90
	POS_X_ENTRE_PUERTAS_ARRIBA	equ	$d2

	LLAVE_ITEM_POS_X		equ	$f0
	LLAVE_ITEM_POS_X_NIVEL19	equ	$b8

	LLAVE_INVENTARIO_POS_X		equ	$3b

	LLAVE_INDICADOR_POS_X		equ	$02
	LLAVE_FLECHA_POS_X		equ	$22

	FANTASMA_START_POS_X 		equ	$5d

	PINCHOS_POS_X			equ	$b4

	PUERTA_INTERIOR_ARRIBA_POS_X	equ	$b2
	PUERTA_INTERIOR_ABAJO_POS_X	equ	$70

;--------------------------------------------------------------------------
	ROJO				equ	%00000010
	ROJO_BRILLO			equ	%01000010
	VERDE				equ	%00000100
	VERDE_BRILLO			equ	%01000100
	AZULCLARO			equ	%00000101
	AZULCLARO_BRILLO		equ	%01000101
	AMARILLO			equ	%00000110
	AMARILLO_BRILLO			equ	%01000110
	BLANCO				equ	%00000111
	BLANCO_BRILLO			equ	%01000111

;--------------------------------------------------------------------------
border_c	equ 	$5c48	;Variable sistema (Borde)

locate		equ 	$0dd9	;Rutina sistema: (Locate), (B = ycoord, C = xcoord)
pr_string	equ	$203c	;Rutina sistema para imprimir textos
out_num		equ	$1a1b	;Rutina sistema para imprimir numeros (0-9999)

;--------------------------------------------------------------------------
_CR         	equ 	$0d
_INK        	equ 	$10
_PAPER      	equ 	$11
_FLASH      	equ 	$12
_BRIGHT     	equ 	$13
_INVERSE    	equ 	$14
_OVER       	equ 	$15
_AT        	equ 	$16
_TAB   		equ 	$17

;-------------------------------------------------------------------------
beeper: equ $03b5	;Rutina Beeper (HL = Nota, DE = Duracion)...

;  		...( Altera Registros: AF,BC,DE,HL,IX )
;
;-------------------------------------------------------------------------
;			S O N I D O S
;-------------------------------------------------------------------------

s_1:		EQU $0f07		; Nota (Vida menos)0d07
s1_dura:	EQU $0082 / $10		; Duracion

s_2:		EQU $066e		; Nota (Pal)
s2_dura:	EQU $0105 / $10		; Duracion

s_3:		EQU $0326		; Nota (Reb)
s3_dura:	EQU $020B / $10		; Duracion

s_4:		equ $0d0f		; Nota (Pulsa-Menus)
s4_dura:	equ $0184 / $10		; Duracion

s_5:		equ $10			; Nota (Pajaro agudo)
s5_dura:	equ $f0			; Duracion ($a0)

s_6:		equ $20			; Nota (Beep)
s6_dura:	equ $ff			; Duracion

s_7:		equ $05			; Nota (Pulsa-Menus)
s7_dura:	equ $ff			; Duracion ($60)

;-------------------------------------------------------------------------
;	Numero de sonido para 'call sonido' (A = numero)
;-------------------------------------------------------------------------
SND_PALA	equ	1
SND_REBOTE	equ	2		; Tambien: cambio de pantalla, vida extra
SND_DISPARO	equ	3		; Espada / vida menos
SND_PULSA_MENUS	equ	4
SND_PAJARO	equ	5		; Llave
SND_BEEP	equ	6
SND_LASER	equ	7

