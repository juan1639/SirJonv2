;=============================================================================
;
;		    V A R I A B L E S  en  M E M O R I A
;                  
;-----------------------------------------------------------------------------
velocidad	defb $02	; Velocidad del juego (RAPIDO) 1,2,3...(LENTO)
num_vidas	defb $04	; Vidas del Jugador (3 por defecto)
nivel		defb $00	; Nivel actual (Para saber Partes redibujables)

contador_it	defb $00	; Contador General Iteraciones Bucle
anima_antorchas	defb $20	; Animacion (que toca) antorchas

jugador_old_x	defb $82	; Posicion 'old' X del jugador (l de hl)
jugador_old_y	defb $50	; Posicion 'old' Y del jugador (h de hl)

jugador_x	defb $82	; Posicion X del jugador (l de hl)
jugador_y	defb $50	; Posicion Y del jugador (h de hl)

jugador_rot	defb $02	; Rotacion actual del jugador

jugador_timer_idle	defb	$00	;Timer jugador esta quieto
jugador_timer_ataque	defb	$00	;Fotogramas que le quedan al golpe de espada
salto_paso		defb	$00	;0 = en el suelo; 1..SALTO_PASOS = saltando
salto_altura		defb	$00	;Scanlines por encima del suelo (se dibuja ahi)
caida_paso		defb	$00	;0 = no; 1..CAIDA_PASOS = cayendo por un hueco
caida_hueco		defb	$00	;X a la que se vuelve tras caer (antes del hueco)
attr_jugador_3filas	defb	$00	;(dibuja_attr_jugador)
espada_lista		defb	$00	;1 = ESPACIO soltado (se puede volver a golpear)
jugador_timer_invisib	defb	$07	;Timer jugador invisible tras vida menos

rota_entrepuert defb $00	; Rotacion (que toca) cuando Entre-Puertas
cont_explo_jug	defb $00	; Contador de la Explo-Jugador

show1up_y	defb $50	; Coord Y show 1up (txt)
show1up_x	defb $00	; Coord X show 1up (txt)
cont_show1up	defb $99	; Contador show1up desaparecer

flechatrap_y	defb $00	; Coordenada Y de la Flecha-Trampa
flechatrap_x	defb $00	; Coordenada X de la Flecha-Trampa
flecha_y:	defb $00	; Coordenada Y de la flecha
flecha_x:	defb $00	; Coordenada X de la flecha
rota_flecha:	defb $00	; Rotacion (que toca) de la flecha
contador_flecha defb $00	; Contador Flechas (Rapida/Lenta)

explo_arqueroy	defb $00	; Coordenada Y de la Explo-Arquero
explo_arquerox	defb $00	; Coordenada X de la Explo-Arquero
contador_explo	defb $00	; Contador de la Explo-Arquero

murcielago_y:	defb $00	; Coordenada Y del Murcielago
murcielago_x:	defb $00	; Coordenada X del Murcielago
rota_murcielago	defb $00	; Rotacion (que toca) del Murcielago
cont_murcielago defb $0a	; Contador (animacion) del Murcielago

;--------------------------- Fantasmas (estructura: ver fantasmas.asm) -----
fant1_datos:				; Fantasma 1: de derecha a izquierda
	defb	$00			; FANT_Y
	defb	$00			; FANT_X
	defb	$00			; FANT_ROT
	defb	$0a			; FANT_CONT
	defb	$ff			; FANT_DIR	(-1)
	defb	0			; FANT_MIRANDO	(dcha)
	defb	$3f			; FANT_LIMITE
	defb	2			; FANT_COL_BORRA
	defb	1			; FANT_FIN_BORRA
	defb	%00000010		; FANT_MASCARA	(settings2 bit1)
	defw	fantasma_a1giro		; FANT_SPR1
	defw	fantasma_a2giro		; FANT_SPR2

fant2_datos:				; Fantasma 2: de izquierda a derecha
	defb	$00			; FANT_Y
	defb	$00			; FANT_X
	defb	$00			; FANT_ROT
	defb	$0a			; FANT_CONT
	defb	$01			; FANT_DIR	(+1)
	defb	1			; FANT_MIRANDO	(izda)
	defb	$5d			; FANT_LIMITE
	defb	0			; FANT_COL_BORRA
	defb	0			; FANT_FIN_BORRA
	defb	%00100000		; FANT_MASCARA	(settings2 bit5)
	defw	fantasma_a1		; FANT_SPR1
	defw	fantasma_a2		; FANT_SPR2

explo_fantasmay defb $00	; Coordenada Y de la Explo-Fantasma (y Explo-Arana)
explo_fantasmax defb $00	; Coordenada X de la Explo-Fantasma (y Explo-Arana)

cont_bloque_t	defb $14	; Contador (Regresivo) Bloque Trampa
bloquet_y	defb $00	; Coordenada Y del Bloque Trampa
bloquet_x	defb $00	; Coordenada X del Bloque Trampa

;--------------------------- Gotas (estructura: ver gotas.asm) -------------
gota1:
	defb	$00		; GOTA_Y
	defb	$00		; GOTA_X
	defb	$00		; GOTA_CONT
	defb	$0a		; GOTA_HALT
	defb	%00000001	; GOTA_M_SUELO	(settings3 bit0)
	defb	%00000010	; GOTA_M_CAE	(settings3 bit1)
	defb	%00000100	; GOTA_M_TECHO	(settings3 bit2)
	defb	%00001000	; GOTA_M_INI	(settings3 bit3)
	defb	1		; GOTA_RAPIDA
	defw	tabla_x_gota1	; GOTA_TABLA_X

gota2:
	defb	$00		; GOTA_Y
	defb	$00		; GOTA_X
	defb	$00		; GOTA_CONT
	defb	$0a		; GOTA_HALT
	defb	%00010000	; GOTA_M_SUELO	(settings3 bit4)
	defb	%00100000	; GOTA_M_CAE	(settings3 bit5)
	defb	%01000000	; GOTA_M_TECHO	(settings3 bit6)
	defb	%10000000	; GOTA_M_INI	(settings3 bit7)
	defb	0		; GOTA_RAPIDA
	defw	tabla_x_gota2	; GOTA_TABLA_X

arana_y		defb $00	; Coordenada Y de la Arana
arana_x		defb $00	; Coordenada X de la Arana
cont_arana	defb $00	; Contador Arana (Animacion)

pinchos_y	defb $50	; CoordY del pincho-suelo
pinchos_x	defb $a8	; CoordX del pincho-suelo
rota_pinchos	defb $00	; Rotacion/anim del pincho
estado_pinchos	defb $00	; Pinchos subiendo o bajando

timer_flash	defb $00	; Contador timer flash

rota_indicador	defb $01	; Rotacion de la Flecha Indicadora
indica_halt	defb $07	; Contador Ralentizador Flecha Indicadora

pausa_i		defb $59	; Pausa Inicial (Preparado)...

lista_ptr	defw $0000	; Puntero de dibuja_lista (pantallas.asm)

;-----------------------------------------------------------------------------
jugador_set	defb $00	; Settings del Jugador (Bits utilizados)...

; Bit0 ... 1= Flip			| 0= No Flip
; Bit1 ... 1= Agachado			| 0= EnPie (normal)
; Bit2 ... 1= enMovimiento 		| 0= Parado
; Bit3 ... 1= Normal 			| 0= Primer Dibujado
; Bit4 ... 1= AtaqueEspada		| 0= Normal
; Bit5 ... 1= TransicionPuertas		| 0= Normal
; Bit6 ... 1= Transicion VidaMenos	| 0= Normal
; Bit7 ... 1= CambioCaracter		| 0= Normal

;-----------------------------------------------------------------------------
settings	defb $00	; Bits utilizados (Todos)
; Bit0 = 0/1 Siguiente Nivel (adelante)   ...   Bit1 = 0/1 Nivel Anterior (atras)
; Bit2 = 0/1 Explo-Arquero OFF/ON         ...   Bit3 = 0/1 Trampa Activada OFF/ON
; Bit4 = 0/1 Flecha Arquero OFF/ON        ...   Bit5 = 0/1 Arquero OFF/ON
; Bit6 = 0/1 Arquero APUNTANDO OFF/ON	  ...   Bit7 = 0/1 Aparece-Puerta OFF/ON

settings2:	defb $00	; Bits utilizados ()
; Bit0 = 0/1 Murcielago OFF/ON            ...   Bit1 = 0/1 Fantasma OFF/ON	
; Bit2 = 0/1 Explo-Fantasma OFF/ON        ...   Bit3 = 0/1 Trampa(Rapida) Activada OFF/ON 
; Bit4 = 0/1 Animacion Bloque Tr. OFF/ON  ...   Bit5 = 0/1 Fantasma (Izda-->Dcha) OFF/ON
; Bit6 = 0/1 Explo-Fantasma II OFF/ON     ...   Bit7 = 0/1 Flag pasado nivel 1

settings3:	defb $00	; bits utilizados ()
; Bit0 = 0/1 GotaSuelo OFF/ON             ...   Bit1 = 0/1 CaeGota OFF/ON
; Bit2 = 0/1 GotaTecho OFF/ON		  ...   Bit3 = 0/1 Ini-Gota por 1ra vez OFF/ON
; Bit4 = 0/1 GotaSuelo(2) OFF/ON	  ...   Bit5 = 0/1 CaeGota(2) OFF/ON
; Bit6 = 0/1 GotaTecho(2) OFF/ON          ...   Bit7 = 0/1 Ini-Gota(2) por 1ra vez OFF/ON

settings4:	defb $00	; bits utilizados ()
; Bit0 = 0/1 Need Key OFF/ON              ...   Bit1 = 0/1 Tener LLave OFF/ON
; Bit2 = 0/1 Dibuja Suelo/Techo           ...   Bit3 = 0/1 Arana OFF/ON
; Bit4 = 0/1 Arana Arriba/Abajo           ...   Bit5 = 0/1 Explo-Arana OFF/ON
; Bit6 = 0/1 Arquero SOLO 1 vez		  ...   Bit7 = 0/1 FlechaTrampa en suelo OFF/ON

settings5:	defb $00	; bits ulilizados ()
; Bit0 = 0/1 Pinchos OFF/ON		  ...	Bit1 = 0/1 Pinchos (bajando) OFF/ON
; Bit2 = 0/1 Flag Game Completed OFF/ON	  ...	Bit3 = 0/1 Flag Borrar jugador Game-comp OFF/ON

settings_ch:	defb $00	; bits utilizados ()
; Bit0 = 0/1 Flag Cheat LevelUp OFF/ON    ...   Bit1 = 0/1 Flag Vida EXTRA (solo una vez)
; Bit2 = 0/1 Show Vida EXTRA OFF/ON	  ...   Bit3 = 0/1 Flag Cheat invisible
; Bit4 = 0/1 Flag Cheat vidas inf	  ...  	Bit5 = 0/1 Flag Vida EXTRA2 (sola una vez)

bolas_fuego:
defb	$55,$6c,$00,$00
defb	$52,$11,$00,$00
defb	$50,$36,$00,$00
defb	$55,$7b,$00,$00


;-----------------------------------------------------------------------------
jugador_borrado:	defw 0		; Posicion (L = X, H = Y) del ultimo borra_jugador
truco_paso:		defb 0		; Letras de J-O-N escritas en el titulo
buffer_fondo: 		defs 64		; Fondo bajo el jugador (4 bytes x 16 scanlines)

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------

txt_pulse_continuar	defb	_BRIGHT, $01, _FLASH, $01, _PAPER, $00, _INK, $05, _AT, $03, $03, " Pulse Space para comenzar "
txt_pulse_continuar_fin:
txt_creditos	defb	_BRIGHT, $00, _FLASH, $00, _PAPER, $00, _INK, $02, _AT, $14, $06, $7f," Juan Eguia, 2026 "
txt_creditos_fin:
txt_congrats	defb	_BRIGHT, $01, _FLASH, $00, _PAPER, $01, _INK, $06, _AT, $0c, $00, " C O N G R A T U L A T I O N S! "
txt_congrats_fin:
txt_thanks_play	defb	_BRIGHT, $01, _FLASH, $00, _PAPER, $00, _INK, $04, _AT, $14, $07, " Thanks for playing "
txt_thanks_play_fin:
txt_controles	defb	_BRIGHT, $01, _FLASH, $00, _PAPER, $00, _INK, $02, _AT, $0d, $0b, "CONTROLES"
		defb	_INK, $07, _AT, $0e, $0a, "Q A O P  SPC"
txt_controles_fin:
txt_gameover_p1	defb	_BRIGHT, $00, _FLASH, $00, _PAPER, $00, _INK, $02, _AT, $0b, $0b, "           "
txt_gameover_p1_fin:
txt_gameover_p2	defb	_BRIGHT, $00, _FLASH, $00, _PAPER, $00, _INK, $02, _AT, $0d, $0b, "           "
txt_gameover_p2_fin:


