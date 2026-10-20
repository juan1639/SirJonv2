;===========================================================================
;
;			  L E E R   T E C L A D O
;
;   O ............ izquierda
;   P ............ derecha
;   A ............ agacharse
;   ESPACIO ...... espada (un golpe por pulsacion)
;   3 ............ truco: siguiente pantalla (solo con los trucos activados)
;   Q ............ saltar (con O/P a la vez: salto hacia ese lado)
;
;   Prioridad (solo se atiende una): truco > agachar > espada > izq > dcha
;
;   TRUCOS: en la pantalla de titulo, escribir J, O, N (una tras otra, no
;   hace falta mantenerlas) antes de pulsar ESPACIO. Se activan vidas
;   infinitas, invisibilidad y la tecla 3 para pasar de pantalla (suena un
;   laser y el borde se pone rojo).
;
;   Teclado: 'in a,($fe)' con A = fila (semifila). Bit a 0 = pulsada.
;---------------------------------------------------------------------------
FILA_QWERT	equ	$fb		; bit0=Q bit1=W ...
FILA_12345	equ	$f7		; bit0=1 bit1=2 bit2=3 bit3=4 bit4=5
FILA_ASDFG	equ	$fd		; bit0=A ...
FILA_POIUY	equ	$df		; bit0=P bit1=O ...
FILA_HJKL	equ	$bf		; bit0=ENTER bit1=L bit2=K bit3=J bit4=H
FILA_SPACE	equ	$7f		; bit0=SPACE bit1=SS bit2=M bit3=N bit4=B

TRUCOS		equ	%00011001	; settings_ch: pasar pantalla (bit0),
					; invisible (bit3), vidas infinitas (bit4)

;===========================================================================
leer_teclado:
	ld	a,(caida_paso)			;Cayendo por un hueco: no se
	or	a				;atiende el teclado
	jp	nz,caida_en_curso

	;---------------------- Por defecto: parado y de pie ---
	ld	a,(jugador_set)
	res	1,a				;No agachado
	res	2,a				;No en movimiento
	res	4,a				;No atacando
	ld	(jugador_set),a

;-------------------------------------------------------------
; Tecla 3: cheat siguiente pantalla
;-------------------------------------------------------------
	ld	a,FILA_12345
	in	a,($fe)
	bit	2,a
	jr	nz,tecla_saltar			;'3' no pulsada

	ld	a,(settings_ch)
	bit	0,a				;Cheat LevelUp activado?
	jp	nz,siguiente_nivel

;-------------------------------------------------------------
; Tecla Q: saltar
;   El salto es solo visual y para esquivar: el caballero sube y baja
;   (tabla_salto, en scanlines) sin cambiar jugador_x / jugador_y; se
;   dibuja salto_altura scanlines mas arriba. Mientras dura, solo se
;   atienden O / P (se puede saltar hacia delante o hacia atras), ni
;   espada ni agacharse. Con salto_altura >= SALTO_ESQUIVA no hay
;   colisiones (ver colision_comprueba_altura).
;-------------------------------------------------------------
SALTO_PASOS	equ	22
SALTO_ESQUIVA	equ	8
SALTO_LIMITE_X0	equ	$94		;Pantalla 0: el castillo empieza en la columna 24;
					;el caballero (4 columnas) no puede saltar mas alla
					;de la columna 20 (sino borraria la fachada)

tecla_saltar:
	ld	a,(salto_paso)
	or	a
	jr	nz,salto_en_curso

	ld	a,FILA_QWERT
	in	a,($fe)
	bit	0,a
	jp	nz,tecla_agachar		;'Q' no pulsada

	call	salto_permitido
	jp	nz,tecla_agachar		;Delante del castillo: no se salta

	ld	a,SND_PALA
	call	sonido
	ld	a,1				;Empieza el salto
	ld	(salto_paso),a

salto_en_curso:
	call	reset_timer_idle

	ld	a,(salto_paso)			;1..SALTO_PASOS
	ld	e,a
	ld	d,0
	ld	hl,tabla_salto - 1
	add	hl,de
	ld	a,(hl)
	ld	(salto_altura),a

	ld	a,(salto_paso)
	inc	a
	cp	SALTO_PASOS + 1
	jr	c,salto_guarda_paso
	xor	a				;Fin del salto
salto_guarda_paso:
	ld	(salto_paso),a
	jp	tecla_izq			;En el aire: solo O / P

;-------------------------------------------------------------
; Z si se puede saltar / avanzar en el aire. En la pantalla 0 no, si el
; caballero esta ya junto al castillo (jugador_x > SALTO_LIMITE_X0).
;-------------------------------------------------------------
salto_permitido:
	ld	a,(nivel)
	or	a
	jr	z,salto_pantalla0
	xor	a				;Otras pantallas: siempre (Z)
	ret
salto_pantalla0:
	ld	a,(jugador_x)
salto_permitido_x:				;(A = columna a comprobar)
	ld	c,a
	ld	a,(nivel)
	or	a
	ld	a,c
	jr	z,salto_compara_x
	xor	a
	ret
salto_compara_x:
	cp	SALTO_LIMITE_X0 + 1
	jr	nc,salto_no_permitido
	xor	a				;Z
	ret
salto_no_permitido:
	or	1				;NZ
	ret

tabla_salto:	; altura (scanlines) en cada paso; la ultima a 0 (en el suelo)
	defb	3, 6, 9, 11, 13, 14, 15, 16, 16, 16, 16
	defb	16, 16, 16, 15, 14, 13, 11, 9, 6, 3, 0

;-------------------------------------------------------------
; CAIDA POR UN HUECO (pantallas de saltos, comprueba_huecos)
;   El caballero se hunde en el hueco 2 scanlines por fotograma
;   (CAIDA_PASOS fotogramas = 16 px); luego pierde una vida y reaparece
;   antes del hueco, invisible un rato (como al revivir).
;-------------------------------------------------------------
CAIDA_PASOS	equ	8

caida_en_curso:
	inc	a
	cp	CAIDA_PASOS + 1
	jr	nc,caida_fin
	ld	(caida_paso),a
	jp	redibuja_suelo_saltos		;(el borrado del caballero se lo come)

caida_fin:
	call	redibuja_suelo_saltos
	xor	a
	ld	(caida_paso),a
	ld	a,(caida_hueco)			;Vuelve antes del hueco
	ld	(jugador_x),a
	xor	a
	ld	(jugador_rot),a
	ld	a,DURACION_INVISIBLE_AL_REVIVIR
	ld	(jugador_timer_invisib),a
	ld	a,SND_DISPARO
	call	sonido
	jp	restar_una_vida

;-------------------------------------------------------------
; Redibuja el suelo (con sus huecos) de la pantalla de saltos actual
;-------------------------------------------------------------
redibuja_suelo_saltos:
	ld	hl,suelo_20
	ld	a,(nivel)
	cp	NIVEL_PLAT_A
	jp	z,dibuja_lista
	ld	hl,suelo_21
	jp	dibuja_lista

;-------------------------------------------------------------
; Tecla A: agacharse
;-------------------------------------------------------------
tecla_agachar:
	ld	a,FILA_ASDFG
	in	a,($fe)
	bit	0,a
	jr	nz,tecla_espada			;'A' no pulsada

	call	reset_timer_idle

	ld	a,(jugador_set)
	set	1,a				;Agachado
	ld	(jugador_set),a
	ret

;-------------------------------------------------------------
; ESPACIO: espada
;   Cada pulsacion da UN golpe de ESPADA_DURACION fotogramas (aunque se
;   suelte antes). Para volver a golpear hay que soltar ESPACIO: dejarla
;   pulsada ya no ataca sin parar. Mientras se mantiene pulsada tras el
;   golpe, el caballero puede andar normalmente.
;   jugador_timer_ataque = fotogramas que le quedan al golpe (contadores
;   lo descuenta); espada_lista = 1 si se ha soltado ESPACIO.
;-------------------------------------------------------------
ESPADA_DURACION	equ	6

tecla_espada:
	ld	a,FILA_SPACE
	in	a,($fe)
	bit	0,a
	jr	z,espada_pulsada

	ld	a,1				;Soltado (aunque el golpe siga)
	ld	(espada_lista),a

espada_pulsada:
	ld	a,(jugador_timer_ataque)
	or	a
	jr	nz,espada_atacando		;Golpe en curso: sigue

	ld	a,FILA_SPACE
	in	a,($fe)
	bit	0,a
	jr	nz,tecla_izq			;Espacio no pulsado

	ld	a,(espada_lista)
	or	a
	jr	z,tecla_izq			;Sigue pulsado del golpe anterior

	xor	a				;Nuevo golpe
	ld	(espada_lista),a

	ld	a,SND_DISPARO
	call	sonido

	ld	a,ESPADA_DURACION
	ld	(jugador_timer_ataque),a

espada_atacando:
	call	reset_timer_idle

	ld	a,(jugador_set)
	set	4,a				;Atacando
	ld	(jugador_set),a
	ret

;-------------------------------------------------------------
; O: izquierda
;   Primero se "rota" el sprite (jugador_rot 3..0, 2 px cada vez);
;   cuando la rotacion llega a 0 se mueve un byte (jugador_x - 1)
;   y la rotacion vuelve a 3.
;-------------------------------------------------------------
tecla_izq:
	ld	a,FILA_POIUY
	in	a,($fe)
	bit	1,a
	jr	nz,tecla_dcha			;'O' no pulsada

	call	reset_timer_idle

	ld 	a,(jugador_set)
	set	0,a				;Flip = mirando a la izquierda
	set	2,a				;En movimiento
	ld	(jugador_set),a

	ld	a,(jugador_rot)
	or 	a
	jr	z,mover_caracter_izda

	dec	a				;Solo rotar
	ld	(jugador_rot),a
	ret

mover_caracter_izda:
	ld	a,(jugador_x)
	ld	(jugador_old_x),a
	cp	JUGADOR_LIMITE_IZ		;Tope izquierdo
	ret	z
	cp	JUGADOR_LIMITE_IZ_1_7		;Tope del piso alto (pantallas 1 y 7)
	jr	z,check_tope_piso_alto

se_puede_ir_izda:
	dec	a				;Mover a la izquierda
	ld	(jugador_x),a

	ld	a,JUGADOR_ROT_MAX - 1
	ld	(jugador_rot),a
	ret

;--------------------------------------------------
; En el piso alto no se puede pasar de JUGADOR_LIMITE_IZ_1_7
;--------------------------------------------------
check_tope_piso_alto:
	ld	a,(jugador_y)
	cp	JUGADOR_Y_PISO_ALTO
	ret	z

	ld	a,JUGADOR_LIMITE_IZ_1_7
	jr	se_puede_ir_izda

;-------------------------------------------------------------
; P: derecha
;   Se "rota" el sprite (jugador_rot 0..3); al pasar de 3 se mueve
;   un byte (jugador_x + 1) y la rotacion vuelve a 0.
;-------------------------------------------------------------
tecla_dcha:
	ld	a,FILA_POIUY
	in	a,($fe)
	bit	0,a
	ret	nz				;'P' no pulsada

	call	reset_timer_idle

	ld 	a,(jugador_set)
	res	0,a				;Mirando a la derecha
	set	2,a				;En movimiento
	ld	(jugador_set),a

	ld	a,(jugador_rot)
	inc	a
	ld	(jugador_rot),a
	cp	JUGADOR_ROT_MAX
	ret	nz				;Solo rotar

	ld	a,JUGADOR_ROT_MAX - 1		;(se queda en 3 si estamos en el tope)
	ld	(jugador_rot),a

	ld	a,(salto_paso)			;En el aire en la pantalla 0: no se
	or	a				;avanza hasta el castillo
	jr	z,dcha_sin_salto
	ld	a,(jugador_x)
	inc	a				;(la siguiente columna)
	call	salto_permitido_x
	ret	nz
dcha_sin_salto:

	ld	a,(jugador_x)
	ld	(jugador_old_x),a
	cp	JUGADOR_LIMITE_DE		;Tope derecho
	ret	z

	inc	a				;Mover a la derecha
	ld	(jugador_x),a

	xor	a				;Rotacion a 0
	ld	(jugador_rot),a
	ret

;--------------------------------------------------
reset_timer_idle:
	xor	a
	ld	(jugador_timer_idle),a
	ret
;===========================================================================
; ESPERA TITULO: espera ESPACIO en la pantalla de titulo, vigilando
; mientras tanto si se escribe J, O, N para activar los trucos.
;---------------------------------------------------------------------------
espera_titulo:
	xor	a
	ld	(truco_paso),a

	call	musica_titulo			;(se corta con ESPACIO)

bucle_espera_titulo:
	call	comprueba_trucos

	ld	a,FILA_SPACE
	in	a,($fe)
	bit	0,a				;ESPACIO?
	jr	nz,bucle_espera_titulo
	ret

;---------------------------------------------------------------------------
; COMPRUEBA TRUCOS: truco_paso = cuantas letras de J-O-N van bien.
; Cuando se pulsa la siguiente letra se avanza; con las 3, se activan.
; (Las teclas se leen por separado: no hace falta pulsar varias a la vez,
;  que muchos teclados de PC no detectan.)
;---------------------------------------------------------------------------
comprueba_trucos:
	ld	a,(truco_paso)
	cp	$03
	ret	z				;Ya activados

	ld	hl,tabla_truco			;HL = tabla_truco + paso * 2
	add	a,a
	add	a,l
	ld	l,a
	jr	nc,truco_tecla
	inc	h

truco_tecla:
	ld	a,(hl)				;Fila
	in	a,($fe)
	inc	hl
	and	(hl)				;Bit de la tecla
	ret	nz				;No pulsada

	ld	hl,truco_paso
	inc	(hl)
	ld	a,(hl)
	cp	$03
	ret	nz

	;------------------------------------- J-O-N completo: trucos ON
	ld	a,(settings_ch)
	or	TRUCOS
	ld	(settings_ch),a

	ld	a,SND_LASER
	call	sonido

	ld	a,ROJO				;Borde rojo = trucos activados
	out	($fe),a
	ret

tabla_truco:
	defb	FILA_HJKL,  %00001000		;J
	defb	FILA_POIUY, %00000010		;O
	defb	FILA_SPACE, %00001000		;N
