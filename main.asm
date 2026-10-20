;==========================================================================
;
;		S I R   J O N   -   ZX Spectrum 48K  (Z80 asm, Pasmo)
;
;			      Juan Eguia, 2026
;
;  Compilar:  pasmo --tapbas main.asm sirjon.tap
;
;  Este fichero contiene:
;    - Arranque / reinicio de partida
;    - Bucle principal del juego
;    - Bucles de "game completed"
;    - Despacho por nivel (tablas de saltos)
;    - Los 'include' de todos los modulos
;
;==========================================================================
	org	$8000

;==========================================================================
;---			C O M I E N Z O   P R O G R A M A		---
;---									---
;---			   (reset de la partida)			---
;--------------------------------------------------------------------------
comienzo_programa:
	;---------------- Reset nivel, contador, settings4 -----
	xor	a
	ld	(nivel),a
	ld	(contador_it),a
	ld	(settings4),a		;Settings4 hay que resetearlo entero

	ld	a,VIDAS_INICIALES
	ld	(num_vidas),a

	xor	a				;Espada: hay que soltar ESPACIO (el
	ld	(espada_lista),a		;del titulo) antes del primer golpe
	ld	(jugador_timer_ataque),a

	ld	a,$07
	ld	(jugador_timer_invisib),a

	;---------------- Posicion inicial del jugador ---------
	ld	a,JUGADOR_LIMITE_IZ + 2
	ld	(jugador_x),a

	ld	a,JUGADOR_Y_SUELO
	ld	(jugador_y),a

	;---------------- Cheats y flags de vida extra ---------
	; Bits 0-5 a cero: LevelUp, VidaExtra, ShowVidaExtra,
	; Invisible, VidasInf, VidaExtra2  (ver var.asm)
	ld	a,(settings_ch)
	and	%11000000
	ld	(settings_ch),a

	;---------------- Pantalla de titulo -------------------
	call	sub_cls
	call 	sub_cls_attr
	call	borde

	call	selecc_pantalla_dibujar
	call	selecc_redibujables

	call	sub_txt_titulo
	call	sub_txt_controles
	call	sub_txt_pulse_continuar
	call	espera_titulo			;ESPACIO (J, O, N antes = trucos)

	ld	a,SND_PULSA_MENUS
	call	sonido

;==========================================================================
;---	          P R E - B U C L E   (cada vez que se entra             ---
;---                       en una pantalla nueva)                       ---
;--------------------------------------------------------------------------
otra_pantalla:
	call	reset_settings

	call	sub_cls
	call 	sub_cls_attr

	call	selecc_pantalla_dibujar

	call	mostrar_marcadores

	call	dibuja_jugador

;==========================================================================
;---                                                                    ---
;---	               B U C L E    P R I N C I P A L                   ---
;---                                                                    ---
;==========================================================================
bucle_principal:
	;------------------ Transicion vida menos? -----------------
	ld	a,(jugador_set)
	bit	6,a				;Bit6=1: jugador explotando
	jr	nz,ralentizaciones

	;------------------ Game over? -----------------------------
	ld	a,(num_vidas)
	or	a
	jp	z,game_over

	call	contadores			;Contadores de iteraciones del bucle

	call	borra_jugador			;Borrar el jugador
	call	leer_teclado			;Detectar pulsaciones teclado

	ld	a,(num_vidas)			;(se puede perder la ultima vida
	or	a				; al caer por un hueco: game over
	jp	z,game_over			; sin volver a dibujar al caballero)
	call	borra_jugador_si_movido		;Y otra vez si leer_teclado lo ha movido

	ld	a,(jugador_set)
	bit	4,a
	call	nz,dibuja_jugador		;Dibujado especial (bug ataque-espada)

	call	selecc_redibujables		;Dibujar fondos que necesitan refresco
	call	selecc_jugabilidad		;Acciones especificas de cada pantalla

	call	guarda_y_dibuja_jugador		;Guarda el fondo y dibuja al jugador

	;------------------ Otra pantalla? -------------------------
	ld	a,(settings)
	and	%00000011			;Bit0 = siguiente, Bit1 = anterior
	jr	nz,otra_pantalla

	;------------------ Game completed? ------------------------
	ld	a,(settings5)
	bit	2,a
	jr	nz,game_completed

	;------------------ Velocidad del juego --------------------
	ld	a,(velocidad)
	call	ralentiza
	jr	bucle_principal

;--------------------------------------------------------------------------
;	Bucle mientras el jugador explota (vida menos)
;--------------------------------------------------------------------------
ralentizaciones:
	call	selecc_jugabilidad
	call	explo_jugador

	ld	a,(velocidad)
	call	ralentiza

	halt					;Halt extra
	jr	bucle_principal

;==========================================================================
;			BUCLE - GAME COMPLETED
;--------------------------------------------------------------------------
game_completed:
	call	sub_txt_congrats
	call	sub_txt_thanks_play

	ld	hl,melodia_titulo		;La musica del titulo, como fanfarria
	call	toca_melodia			;de victoria

	xor	a
	ld	(contador_it),a

bucle_game_completed:
	call	dibuja_jugador_game_completed

	ld	a,(contador_it)
	inc	a
	cp	$ff
	jr	z,pulse_continuar
	ld	(contador_it),a

	ld	a,(velocidad)
	call	ralentiza
	jr	bucle_game_completed

pulse_continuar:
	call	sub_txt_pulse_continuar
	call	sub_leer_teclado_pulse_continuar
	jp	comienzo_programa

;==========================================================================
;=====                                                                =====
;=====    C A R G A   R E C U R S O S   D E   C A D A   N I V E L     =====
;=====                                                                =====
;==========================================================================
; Cada pantalla tiene:
;   pantallaN        -> lista de piezas: atributos + fondo (al entrar)
;   pantallaN_redib  -> lista de piezas que se redibujan cada fotograma
;   nivel_N          -> rutina de jugabilidad (enemigos, trampas, salidas)
;
; Las listas estan en pantallas-datos.asm (tablas tabla_pantallas y
; tabla_redibujables) y las dibuja dibuja_lista (pantallas.asm).
; Si nivel >= NUM_NIVELES no se hace nada.
;--------------------------------------------------------------------------
selecc_pantalla_dibujar:
	ld	hl,tabla_pantallas
	jr	dibuja_lista_del_nivel

selecc_redibujables:
	ld	hl,tabla_redibujables

dibuja_lista_del_nivel:
	call	lee_tabla_nivel
	ret	c
	jp	dibuja_lista

selecc_jugabilidad:
	ld	hl,tabla_jugabilidad
	call	lee_tabla_nivel
	ret	c
	jp	(hl)

;--------------------------------------------------------------------------
; LEE TABLA NIVEL
;   Entrada: HL = tabla de direcciones (defw), una por nivel
;   Salida:  HL = tabla[nivel].  Carry = 1 si el nivel esta fuera de rango
;   Altera: AF, DE, HL
;--------------------------------------------------------------------------
lee_tabla_nivel:
	ld	a,(nivel)
	cp	NUM_NIVELES
	ccf
	ret	c				;Nivel fuera de rango

	add	a,a				;Cada entrada ocupa 2 bytes
	ld	e,a
	ld	d,$00
	add	hl,de				;(Carry = 0)

	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	ret

;--------------------------------------------------------------------------
tabla_jugabilidad:
	defw	nivel_0,  nivel_1,  nivel_2,  nivel_3,  nivel_4
	defw	nivel_5,  nivel_6,  nivel_7,  nivel_8,  nivel_9
	defw	nivel_10, nivel_11, nivel_12, nivel_13, nivel_14
	defw	nivel_15, nivel_16, nivel_17, nivel_18, nivel_19
	defw	nivel_20, nivel_21

;==========================================================================
;			    M O D U L O S
;
; OJO: se mantiene el orden original de los include para no mover
; sprites ni datos de sitio (fase 1 = mismo comportamiento).
;==========================================================================
include "sprites.asm"
include "var.asm"
include "const.asm"
include "audio.asm"
include "jugador.asm"
include "teclado.asm"

;---------------------- Pantallas (datos e interprete) -------------------
include "pantallas.asm"
include "pantallas-datos.asm"
include "pantalla0.asm"

include "rutaux.asm"

;---------------------- Pantallas (jugabilidad) ---------------------------
include "jugabilidad.asm"

;---------------------- Enemigos, trampas, objetos y graficos -------------
include "arana.asm"
include "murcielago.asm"
include "flecha-arquero.asm"
include "flecha-trampa.asm"
include "arquero.asm"
include "anima-bloquetrampa.asm"
include "fantasmas.asm"
include "gotas.asm"
include "llave-indicador.asm"
include "dibuj-aux.asm"
include "attr-aux.asm"
include "gameover.asm"
include "bolas-fuego.asm"
include "show1up.asm"
include "pinchos.asm"
include "jugador-completed.asm"
include "hud-marco.asm"
include "musica.asm"

;--------------------------------------------------------------------------
	end	$8000
