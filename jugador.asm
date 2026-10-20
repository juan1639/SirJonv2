;==========================================================================
;
;			    J U G A D O R
;
;  Sprite del caballero: 4 bytes de ancho x 16 scanlines (24x16 px util,
;  el 4o byte recoge el desplazamiento). Hay 4 'rotaciones' prerotadas
;  (desplazamientos de 2 px), cada una de 64 bytes (16 filas x 4 bytes):
;
;     sprite + jugador_rot * 64
;
;  Posicion:  jugador_y = byte alto (H) de la direccion de pantalla
;             jugador_x = byte bajo (L)
;
;  Dibujado:  pixel = sprite OR fondo_guardado (buffer_fondo), de modo
;             que el caballero no borra lo que hay detras.
;
;  Bits de jugador_set:  ver var.asm
;
;==========================================================================

;==========================================================================
;---		             DIBUJA JUGADOR                             ---
;
;  Dos versiones (mismo resultado en pantalla):
;
;  guarda_y_dibuja_jugador  (bucle principal): guarda en buffer_fondo lo
;     que hay en pantalla bajo el jugador y lo dibuja (sprite OR fondo).
;     Una sola pasada; antes eran guarda_fondo + dibuja_jugador.
;
;  dibuja_jugador: sprite OR buffer_fondo (el fondo guardado antes).
;
;  Registros: HL = pantalla, DE = sprite, BC = buffer_fondo,
;             A' = contador de scanlines.
;--------------------------------------------------------------------------
; En el original habia aqui un "ret si esta parado" que
; nunca llegaba a ejecutarse (se hacia 'set 3,a' sin guardar el valor en
; jugador_set). Se ha quitado ese codigo muerto.
; Fase 2, punto 12: se ha reescrito sin IX (mas rapido), con el cambio de
; scanline en linea y guardar+dibujar en una sola pasada.
;--------------------------------------------------------------------------
guarda_y_dibuja_jugador:
	call	jugador_hl_de
	ld	bc,buffer_fondo
	ld	a,$10

bucle_guarda_dibuja:
	ex	af,af'
	ld	a,(hl)
	ld	(bc),a				;fondo -> buffer
	inc	bc
	ex	de,hl
	or	(hl)				;OR sprite
	inc	hl
	ex	de,hl
	ld	(hl),a
	inc	l
	ld	a,(hl)
	ld	(bc),a				;fondo -> buffer
	inc	bc
	ex	de,hl
	or	(hl)				;OR sprite
	inc	hl
	ex	de,hl
	ld	(hl),a
	inc	l
	ld	a,(hl)
	ld	(bc),a				;fondo -> buffer
	inc	bc
	ex	de,hl
	or	(hl)				;OR sprite
	inc	hl
	ex	de,hl
	ld	(hl),a
	inc	l
	ld	a,(hl)
	ld	(bc),a				;fondo -> buffer
	inc	bc
	ex	de,hl
	or	(hl)				;OR sprite
	inc	hl
	ex	de,hl
	ld	(hl),a

	dec	l
	dec	l
	dec	l

	inc	h				;Siguiente scanline (como
	ld	a,h				; cambio_scanline_linea)
	and	%00000111
	jr	nz,gdj_mismo_caracter
	ld	a,h
	sub	$08
	ld	h,a
	ld	a,l
	add	a,$20
	ld	l,a
gdj_mismo_caracter:

	ex	af,af'
	dec	a
	jr	nz,bucle_guarda_dibuja
	jp	dibuja_attr_jugador

;--------------------------------------------------------------------------
dibuja_jugador:
	call	jugador_hl_de
	ld	bc,buffer_fondo
	ld	a,$10

bucle_dibuja_jugador:
	ex	af,af'
	ld	a,(bc)				;fondo guardado
	inc	bc
	ex	de,hl
	or	(hl)				;OR sprite
	inc	hl
	ex	de,hl
	ld	(hl),a
	inc	l
	ld	a,(bc)				;fondo guardado
	inc	bc
	ex	de,hl
	or	(hl)				;OR sprite
	inc	hl
	ex	de,hl
	ld	(hl),a
	inc	l
	ld	a,(bc)				;fondo guardado
	inc	bc
	ex	de,hl
	or	(hl)				;OR sprite
	inc	hl
	ex	de,hl
	ld	(hl),a
	inc	l
	ld	a,(bc)				;fondo guardado
	inc	bc
	ex	de,hl
	or	(hl)				;OR sprite
	inc	hl
	ex	de,hl
	ld	(hl),a

	dec	l
	dec	l
	dec	l

	inc	h				;Siguiente scanline (como
	ld	a,h				; cambio_scanline_linea)
	and	%00000111
	jr	nz,dj_mismo_caracter
	ld	a,h
	sub	$08
	ld	h,a
	ld	a,l
	add	a,$20
	ld	l,a
dj_mismo_caracter:

	ex	af,af'
	dec	a
	jr	nz,bucle_dibuja_jugador
	jp	dibuja_attr_jugador

;--------------------------------------------------------------------------
; HL = posicion del jugador en pantalla, DE = sprite (con su rotacion)
;--------------------------------------------------------------------------
jugador_hl_de:
	call	jugador_pos_hl
	call	check_flip			;DE = sprite segun direccion/accion
	; (sigue en sumar_rotacion_de)

;--------------------------------------------------------------------------
; SUMAR ROTACION:  DE += jugador_rot * 64   (jugador_rot = 0..3)
;   Altera: AF
;--------------------------------------------------------------------------
sumar_rotacion_de:
	ld	a,(jugador_rot)
	rrca
	rrca				;A = rot * 64  (rot 0..3 -> $00,$40,$80,$c0)
	jp	suma_a_de

;--------------------------------------------------------------------------
; CHECK FLIP:  DE = sprite segun jugador_set
;
;              mirando DCHA                  mirando IZDA (flip)
;   normal     sprites                       caballero_flip
;   agachado   caballero_new_agachado        caballero_new_agachado_flip
;   atacando   caballero_ataca_dcha          caballero_ataca_izda
;--------------------------------------------------------------------------
check_flip:
	ld	a,(jugador_set)
	bit	0,a
	jr	z,flip_false

	;---------------------------------------  Mirando a la IZDA
	ld	de,caballero_new_agachado_flip
	bit	1,a
	ret	nz

	ld	de,caballero_ataca_izda
	bit	4,a
	ret	nz

	ld	de,caballero_flip
	ret

flip_false:	;-------------------------------  Mirando a la DCHA
	ld	de,caballero_new_agachado
	bit	1,a
	ret	nz

	ld	de,caballero_ataca_dcha
	bit	4,a
	ret	nz

	ld	de,sprites
	ret

;==========================================================================
; POSICION DEL JUGADOR EN PANTALLA: HL = (jugador_y, jugador_x) subido
; salto_altura scanlines (el salto no cambia jugador_x / jugador_y).
; Altera AF.
;--------------------------------------------------------------------------
jugador_pos_hl:
	ld	a,(jugador_y)
	ld	h,a
	ld	a,(jugador_x)
	ld	l,a
	ld	a,(caida_paso)			;Cayendo por un hueco: mas abajo
	or	a
	jr	nz,pos_caida
	ld	a,(salto_altura)
	or	a
	ret	z
	push	bc
	ld	b,a
bucle_pos_salto:
	call	decrementar_scanline
	djnz	bucle_pos_salto
	pop	bc
	ret

pos_caida:
	push	bc
	add	a,a				;2 scanlines por paso
	ld	b,a
bucle_pos_caida:
	call	incrementar_scanline
	djnz	bucle_pos_caida
	pop	bc
	ret

;==========================================================================
; BORRA JUGADOR:  pone a cero los 4x16 bytes de pantalla del jugador
;
; borra_jugador_si_movido: el bucle principal borra al jugador antes y
; despues de leer el teclado. El segundo borrado NO sobra: si el jugador
; se ha movido, limpia la zona de la nueva posicion (sin el, quedan restos
; del sprite y de los enemigos junto al caballero). Pero si sigue en el
; mismo sitio, esa zona ya esta a cero y no hace falta repetirlo.
;--------------------------------------------------------------------------
borra_jugador_si_movido:
	call	jugador_pos_hl			;(en pantalla, con el salto)
	ex	de,hl
	ld	hl,(jugador_borrado)		;Posicion borrada la ultima vez
	or	a
	sbc	hl,de
	ret	z				;Mismo sitio: ya esta borrado
	ex	de,hl
	jr	borra_jugador_hl

borra_jugador:
	call	jugador_pos_hl
borra_jugador_hl:
	ld	(jugador_borrado),hl

	ld	bc,$1000			;B = 16 scanlines, C = 0

bucle_borra_jugador:
	ld	(hl),c
	inc	l
	ld	(hl),c
	inc	l
	ld	(hl),c
	inc	l
	ld	(hl),c

	dec	l
	dec	l
	dec	l

	inc	h				;Siguiente scanline (como
	ld	a,h				; cambio_scanline_linea)
	and	%00000111
	jr	nz,bj_mismo_caracter
	ld	a,h
	sub	$08
	ld	h,a
	ld	a,l
	add	a,$20
	ld	l,a
bj_mismo_caracter:

	djnz	bucle_borra_jugador
	ret

;===========================================================================
;			E X P L O - J U G A D O R
;
; Se llama cada fotograma mientras jugador_set bit6 = 1 (vida menos).
; 8 fases de explosion (sprite caballero_explota, 64 bytes por fase,
; 4 bytes x 16 scanlines). Al terminar se resta una vida.
;---------------------------------------------------------------------------
explo_jugador:
	;------------ No importa que esto se haga muchas veces --------
	ld	a,DURACION_INVISIBLE_AL_REVIVIR
	ld	(jugador_timer_invisib),a

	;--------------------------------------------------------------
	ld	a,(cont_explo_jug)		;Contador Explo-Jugador
	inc	a
	ld	(cont_explo_jug),a
	cp	$08				;8 fases?...
	jr	z,fin_explo_jugador		;...fin de la explosion

	;------------ DE = caballero_explota + fase * 64 --------------
	ld	l,a
	ld	h,$00
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl				;HL = fase * 64
	ld	de,caballero_explota
	add	hl,de
	ex	de,hl

	;--------------------------------------------------------------
	ld	a,(jugador_y)
	ld	h,a
	ld	a,(jugador_x)
	ld	l,a

	ld	b,$10

bucle_explo_jugador:
	call	dibujados_repetitivos		;bytes 1 y 2

	inc	l
	inc	de
	ld	a,(de)				;byte 3
	ld	(hl),a

	inc	l
	inc	de
	ld	a,(de)				;byte 4
	ld	(hl),a

	ld	a,b				;Ralentiza en los scanlines 9, 5 y 1
	cp	$09
	call	z,un_halt
	cp	$05
	call	z,un_halt
	cp	$01
	call	z,un_halt

	dec	l
	dec	l
	dec	l
	call	incrementar_scanline
	inc	de
	djnz	bucle_explo_jugador
	ret

;-------------------------------------------
fin_explo_jugador:
	ld	a,(jugador_set)
	res	6,a				;Fin transicion vida menos
	ld	(jugador_set),a

	ld	a,(jugador_y)
	ld	h,a
	ld	a,(jugador_x)
	ld	l,a

	call	borra_jugador			;Borra los 4 bytes x 16 de la explosion

	jp	restar_una_vida

;===========================================================================
;			A T R I B U T O S   J U G A D O R
;
;  2 filas x 4 columnas: fila de arriba (cabeza) y fila de abajo (cuerpo).
;
;  Normal:      cabeza ROJO_BRILLO, cuerpo AZULCLARO_BRILLO
;  Invisible (tras perder vida, jugador_timer_invisib > 0), parpadea:
;               fotogramas impares -> BLANCO
;               fotogramas pares   -> rojo / azul claro SIN brillo
;---------------------------------------------------------------------------
dibuja_attr_jugador:
	call	jugador_pos_hl
	ld	a,h
	and	%00000111
	ld	(attr_jugador_3filas),a		;Scanline de arriba (0 = alineado)
	ld	a,h
	call	cambioh_58595a
	ld	h,a				;H = fila de atributos del tercio
					;L = misma columna/fila que pixeles

	;--------------------------------------------- Cabeza (fila 1)
	ld	c,ROJO_BRILLO
	call	color_intermitente
	call	attr_fila_jugador
	ld	b,a				;B = color cabeza

	ld	c,AZULCLARO_BRILLO
	call	color_intermitente		;A = color cuerpo
	ld	c,a				;C = color cuerpo

	ld	a,l
	add	a,$20				;Fila 2
	ld	l,a

	;--------------------------------------------- En el suelo: fila 2 = cuerpo
	; Saltando ocupa 3 filas: la 2 es de la cabeza si la mayor parte de la
	; cabeza cae en ella (desplazamiento >= 4) y la 3 es del cuerpo.
	ld	a,(attr_jugador_3filas)
	or	a
	ld	a,c
	jr	z,attr_fila_jugador		;Alineado: 2 filas

	ld	a,(attr_jugador_3filas)
	cp	4
	ld	a,c
	jr	c,attr_fila2_cuerpo
	ld	a,b
attr_fila2_cuerpo:
	call	attr_fila_jugador

	ld	a,l
	add	a,$20				;Fila 3: cuerpo
	ld	l,a
	ld	a,c
	; (sigue en attr_fila_jugador)

;---------------------------------------------------------------------------
; 4 atributos A desde HL (HL no cambia)
;---------------------------------------------------------------------------
attr_fila_jugador:
	ld	(hl),a
	inc	l
	ld	(hl),a
	inc	l
	ld	(hl),a
	inc	l
	ld	(hl),a
	dec	l
	dec	l
	dec	l
	ret

;---------------------------------------------------------------------------
; COLOR INTERMITENTE
;   Entrada: C = color normal (con brillo)
;   Salida:  A = C si no es invisible; si lo es, BLANCO (fotogramas
;            impares) o C sin brillo (pares)
;---------------------------------------------------------------------------
color_intermitente:
	ld	a,(jugador_timer_invisib)
	or	a
	jr	z,color_normal

	ld	a,(contador_it)
	bit	0,a
	jr	z,color_sin_brillo

	ld	a,BLANCO
	ret

color_sin_brillo:
	ld	a,c
	and	%10111111			;Quita el brillo
	ret

color_normal:
	ld	a,c
	ret
