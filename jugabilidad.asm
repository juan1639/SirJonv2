;===========================================================================
;
;			  J U G A B I L I D A D
;
;  Una rutina nivel_N por pantalla. Se llama una vez por fotograma
;  (selecc_jugabilidad, en main.asm) y decide que enemigos y trampas
;  salen, los mueve y comprueba las salidas de la pantalla.
;
;  Patron habitual:
;     ld   a,(contador_it)          ; en ciertos fotogramas...
;     cp   N
;     call z,inicia_xxx             ; ...aparece un enemigo
;     call mueve_xxx / si_xxx       ; y cada fotograma se mueve si esta activo
;
;  Las rutinas 'si_xxx', 'mueve_xxx' y 'gestiona_xxx' del final agrupan
;  las comprobaciones que se repiten en muchas pantallas.
;
;  OJO: en algunas cadenas 'cp N / call z,... / cp M / call z,...' el
;  segundo 'cp' compara el valor de A que DEVUELVE la rutina llamada (no
;  se recarga A). En las que quedan no cambia nada (las rutinas devuelven
;  valores que no coinciden), pero al escribir pantallas nuevas es mejor
;  recargar A antes de cada 'cp'.
;===========================================================================

;===========================================================================
;  PANTALLA 0: exterior (murcielago y flechas)
;---------------------------------------------------------------------------
nivel_0:
	ld	a,(contador_it)
	cp	$20
	call	z,inicia_flecha_arquerozero
	cp	$10
	call	z,inicia_murcielago_zero

	call	si_flecha_arquero
	call	si_murcielago
	call	si_explo_arana			;(explosion del murcielago)
	call	si_show1up

	ld	a,(jugador_x)
	cp	JUGADOR_LIMITE_DE		;Solo hay salida a la derecha
	jp	z,siguiente_nivel
	ret

;===========================================================================
;  PANTALLA 1: sala de las puertas (arquero, flecha-trampa, llave)
;---------------------------------------------------------------------------
nivel_1:
	ld	a,(settings)
	bit	7,a				;Puerta abierta?
	call	nz,comprueba_entrepuertas

	ld	a,(settings4)
	bit	0,a				;Hace falta la llave?
	call	nz,dibuja_needkey

	ld	a,(jugador_x)
	cp	$89				;Ladrillo-trampa
	call	z,inicia_flechatrampa1
	call	mueve_flechas_trampa

	ld	a,(jugador_y)
	cp	JUGADOR_Y_PISO_ALTO
	call	z,compruebatb_lal		;Trampa del piso de arriba

	ld	a,(contador_it)
	cp	$20
	call	z,inicia_flecha_arquerozero

	call	borra_flecha_clavada
	call	si_flecha_arquero
	call	gestiona_arquero
	call	si_bloque_trampa

	ld	a,(settings4)
	bit	1,a				;Tienes la llave?
	call	nz,inventario_llave

	ld	a,(jugador_x)
	cp	JUGADOR_LIMITE_IZ + 1
	jp	z,anterior_nivel
	cp	JUGADOR_LIMITE_DE_1_7		;(salida por el piso de arriba)
	jp	z,siguiente_nivel
	ret

;===========================================================================
;  PANTALLA 2: flecha-trampa
;---------------------------------------------------------------------------
nivel_2:
	ld	a,(jugador_x)
	cp	$89				;Ladrillo-trampa
	call	z,inicia_flechatrampa1
	call	mueve_flechas_trampa
	call	borra_flecha_clavada
	call	si_bloque_trampa

	call	gestiona_llave
	jp	salidas_pasillo

;===========================================================================
;  PANTALLA 3: dos fantasmas
;---------------------------------------------------------------------------
nivel_3:
	ld	a,(contador_it)
	cp	$10
	call	z,inicia_fantasma

	ld	a,(contador_it)
	cp	$0a
	call	z,inicia_fantasma2

	call	mueve_fantasmas

	call	gestiona_llave
	jp	salidas_pasillo

;===========================================================================
;  PANTALLA 4: gota y fantasma
;---------------------------------------------------------------------------
nivel_4:
	ld	a,(contador_it)
	cp	$03
	call	z,inicia_1ravez
	call	mueve_gota1

	ld	a,(contador_it)
	cp	$0a
	call	z,inicia_fantasma2
	call	si_fantasma2
	call	si_explo_fantasma

	call	gestiona_llave
	jp	salidas_pasillo

;===========================================================================
;  PANTALLA 5: dos gotas, flecha del arquero y flecha-trampa
;---------------------------------------------------------------------------
nivel_5:
	ld	a,(contador_it)
	cp	$02
	call	z,inicia_1ravez

	ld	a,(contador_it)
	cp	$0f
	call	z,inicia_1ravez2

	call	mueve_gota1
	call	mueve_gota2

	ld	a,(contador_it)
	cp	$03
	call	z,inicia_flecha_arquerozero
	call	si_flecha_arquero

	ld	a,(jugador_x)
	cp	$89				;Ladrillo-trampa
	call	z,inicia_flechatrampa1
	call	mueve_flechas_trampa
	call	borra_flecha_clavada
	call	si_bloque_trampa

	call	gestiona_llave
	jp	salidas_pasillo

;===========================================================================
;  PANTALLA 6: gota, flecha del arquero, flecha-trampa y fantasma
;---------------------------------------------------------------------------
nivel_6:
	ld	a,(contador_it)
	cp	$0f
	call	z,inicia_1ravez2
	call	mueve_gota2

	ld	a,(contador_it)
	cp	$03
	call	z,inicia_flecha_arquerozero
	call	si_flecha_arquero

	ld	a,(jugador_x)
	cp	$8d				;Ladrillo-trampa (aqui en $8d)
	call	z,inicia_flechatrampa1
	call	mueve_flechas_trampa

	ld	a,(contador_it)			;Borra la flecha clavada
	cp	$02				;(aqui en $02 en vez de $fc)
	call	z,borra_flechatrampa1
	cp	$55
	call	z,borra_flechatrampa1
	cp	$aa
	call	z,borra_flechatrampa1

	call	si_bloque_trampa

	ld	a,(contador_it)
	cp	$0a
	call	z,inicia_fantasma2
	call	si_fantasma2
	call	si_explo_fantasma

	call	gestiona_llave
	jp	salidas_pasillo

;===========================================================================
;  PANTALLA 7: sala de las puertas con llave (arquero, fantasma, gota)
;---------------------------------------------------------------------------
nivel_7:
	ld	a,(settings4)
	bit	1,a				;Con la llave se puede subir
	call	nz,comprueba_entrepuertas

	ld	a,(contador_it)
	cp	$20
	call	z,inicia_flecha_arquerozero
	call	si_flecha_arquero
	call	gestiona_arquero

	ld	a,(contador_it)
	cp	$09
	call	z,inicia_fantasma2
	cp	$90
	call	z,inicia_fantasma2
	call	si_fantasma2
	call	si_explo_fantasma

	ld	a,(contador_it)
	cp	$03
	call	z,inicia_1ravez
	call	mueve_gota1

	;------------------------------------------ Llave
	ld	a,(settings4)
	bit	0,a
	call	nz,indicador_key
	ld	a,(settings4)
	bit	1,a
	call	nz,indicador_key
	bit	1,a				;(A devuelto por indicador_key)
	call	nz,inventario_llave

	ld	a,(jugador_x)
	cp	JUGADOR_LIMITE_IZ + 1
	jp	z,anterior_nivel
	cp	JUGADOR_LIMITE_DE_1_7		;(salida por el piso de arriba)
	jp	z,siguiente_nivel
	ret

;===========================================================================
;  PANTALLA 8: dos fantasmas y gota
;---------------------------------------------------------------------------
nivel_8:
	ld	a,(contador_it)
	cp	$09
	call	z,inicia_fantasma2
	cp	$90
	call	z,inicia_fantasma2
	cp	$bc
	call	z,inicia_fantasma
	call	mueve_fantasmas

	ld	a,(contador_it)
	cp	$03
	call	z,inicia_1ravez
	call	mueve_gota1

	call	gestiona_llave
	jp	salidas_pasillo

;===========================================================================
;  PANTALLA 9: dos fantasmas y bolas de fuego
;---------------------------------------------------------------------------
nivel_9:
	ld	a,(contador_it)
	cp	$90
	call	z,inicia_fantasma2
	cp	$bc
	call	z,inicia_fantasma
	call	mueve_fantasmas

	call	sub_bolasfuego

	call	gestiona_llave
	jp	salidas_pasillo

;===========================================================================
;  PANTALLA 10: dos fantasmas y dos gotas
;---------------------------------------------------------------------------
nivel_10:
	ld	a,(contador_it)
	cp	$09
	call	z,inicia_fantasma2
	cp	$90
	call	z,inicia_fantasma2
	cp	$bc
	call	z,inicia_fantasma
	call	mueve_fantasmas

	ld	a,(contador_it)
	cp	$0f
	call	z,inicia_1ravez

	ld	a,(contador_it)
	cp	$02
	call	z,inicia_1ravez2

	call	mueve_gota1
	call	mueve_gota2

	call	gestiona_llave
	jp	salidas_pasillo

;===========================================================================
;  PANTALLAS 20 y 21 (v2): huecos en el suelo y dos fantasmas, uno por
;  cada lado (fantasma 1: de derecha a izquierda; fantasma 2: al reves)
;---------------------------------------------------------------------------
nivel_20:
	ld	a,(contador_it)
	cp	$30
	call	z,inicia_fantasma		;Por la derecha
	ld	a,(contador_it)
	cp	$a0
	call	z,inicia_fantasma2		;Por la izquierda
	call	mueve_fantasmas

	ld	hl,huecos_20
	jr	nivel_saltos

nivel_21:
	ld	a,(contador_it)
	cp	$20
	call	z,inicia_fantasma2		;Por la izquierda
	ld	a,(contador_it)
	cp	$70
	call	z,inicia_fantasma		;Por la derecha
	call	mueve_fantasmas

	ld	hl,huecos_21

nivel_saltos:
	call	comprueba_huecos
	call	gestiona_llave
	jp	salidas_pasillo

;---------------------------------------------------------------------------
; Huecos: X inicial y final (byte bajo de pantalla en el suelo, $80 +
; columna), terminados en 0. Deben coincidir con los P_HUECO de
; pantallas-datos.asm.
;---------------------------------------------------------------------------
huecos_20:
	defb	$80 + 8, $80 + 11
	defb	$80 + 18, $80 + 21
	defb	0

huecos_21:
	defb	$80 + 10, $80 + 13
	defb	$80 + 20, $80 + 23
	defb	0

;---------------------------------------------------------------------------
; COMPRUEBA HUECOS (HL = tabla): si el caballero esta en el suelo con las
; columnas X+1 y X+2 sobre un hueco, empieza a caer (caida_paso, en
; teclado.asm). Al terminar la caida vuelve justo antes del hueco, segun
; hacia donde miraba.
;---------------------------------------------------------------------------
comprueba_huecos:
	ld	a,(salto_paso)
	or	a
	ret	nz				;Saltando: no se cae
	ld	a,(caida_paso)
	or	a
	ret	nz				;Ya esta cayendo
	ld	a,(jugador_set)
	bit	6,a
	ret	nz				;Explotando
	ld	a,(jugador_y)
	cp	JUGADOR_Y_SUELO
	ret	nz

bucle_huecos:
	ld	a,(hl)
	or	a
	ret	z				;Fin de la tabla
	ld	d,a				;D = X inicial del hueco
	inc	hl
	ld	e,(hl)				;E = X final
	inc	hl

	ld	a,(jugador_x)
	inc	a				;X + 1 dentro del hueco?
	cp	d
	jr	c,bucle_huecos
	inc	a				;X + 2 dentro del hueco?
	ld	b,a
	ld	a,e
	cp	b
	jr	c,bucle_huecos

	;------------------------------------------ Cae
	ld	a,(jugador_set)
	bit	0,a				;Mirando a la izquierda?
	jr	z,hueco_vuelve_izda
	ld	a,e
	inc	a				;Venia de la dcha: a la dcha del hueco
	jr	hueco_guarda_vuelta
hueco_vuelve_izda:
	ld	a,d
	sub	4				;Venia de la izda: a la izda del hueco
hueco_guarda_vuelta:
	ld	(caida_hueco),a
	ld	a,1
	ld	(caida_paso),a
	ld	a,SND_PALA
	jp	sonido

;===========================================================================
;  PANTALLAS 11 y 12: flecha del arquero, bolas de fuego y arana
;---------------------------------------------------------------------------
nivel_11:
nivel_12:
	ld	a,(contador_it)
	cp	$03
	call	z,inicia_flecha_arquerozero
	call	si_flecha_arquero

	call	sub_bolasfuego

	ld	a,(contador_it)
	cp	$04
	call	z,inicia_arana

	call	gestiona_llave
	call	gestiona_arana
	jp	salidas_pasillo

;===========================================================================
;  PANTALLA 13: fantasma, dos gotas, flecha del arquero y arana
;---------------------------------------------------------------------------
nivel_13:
	ld	a,(contador_it)
	cp	$bc
	call	z,inicia_fantasma
	call	si_fantasma1
	call	si_explo_fantasma

	ld	a,(contador_it)
	cp	$0f
	call	z,inicia_1ravez

	ld	a,(contador_it)
	cp	$02
	call	z,inicia_1ravez2

	call	mueve_gota1
	call	mueve_gota2

	ld	a,(contador_it)
	cp	$03
	call	z,inicia_flecha_arquerozero
	call	si_flecha_arquero

	ld	a,(contador_it)
	cp	$04
	call	z,inicia_arana

	call	gestiona_llave
	call	gestiona_arana
	jp	salidas_pasillo

;===========================================================================
;  PANTALLA 14: flecha-trampa, dos gotas, flecha del arquero y arana
;---------------------------------------------------------------------------
nivel_14:
	ld	a,(jugador_x)
	cp	$89				;Ladrillo-trampa
	call	z,inicia_flechatrampa1
	call	mueve_flechas_trampa
	call	borra_flecha_clavada
	call	si_bloque_trampa

	ld	a,(contador_it)
	cp	$02
	call	z,inicia_1ravez

	ld	a,(contador_it)
	cp	$40
	call	z,inicia_1ravez2

	call	mueve_gota1
	call	mueve_gota2

	ld	a,(contador_it)
	cp	$03
	call	z,inicia_flecha_arquerozero
	call	si_flecha_arquero

	ld	a,(contador_it)
	cp	$04
	call	z,inicia_arana

	call	gestiona_llave
	call	gestiona_arana
	jp	salidas_pasillo

;===========================================================================
;  PANTALLAS 15 y 16: pinchos, gota y flecha del arquero
;---------------------------------------------------------------------------
nivel_15:
nivel_16:
	call	gestiona_pinchos

	ld	a,(contador_it)
	cp	$40
	call	z,inicia_1ravez2
	call	mueve_gota2

	ld	a,(contador_it)
	cp	$03
	call	z,inicia_flecha_arquerozero
	call	si_flecha_arquero

	call	gestiona_llave
	jp	salidas_pasillo

;===========================================================================
;  PANTALLA 17: murcielago, pinchos y flechas del arquero
;---------------------------------------------------------------------------
nivel_17:
	ld	a,(contador_it)
	cp	$90
	call	z,inicia_murcielago_zero
	cp	$fa
	call	z,inicia_murcielago_zero
	call	si_murcielago
	call	si_explo_arana			;(explosion del murcielago)

	call	gestiona_pinchos

	ld	a,(contador_it)
	cp	$03
	call	z,inicia_flecha_arquerozero
	cp	$90
	call	z,inicia_flecha_arquerozero
	cp	$f1
	call	z,inicia_flecha_arquerozero
	call	si_flecha_arquero

	call	si_show1up

	call	gestiona_llave
	jp	salidas_pasillo

;===========================================================================
;  PANTALLA 18: gota, arana y flecha del arquero
;---------------------------------------------------------------------------
nivel_18:
	ld	a,(contador_it)
	cp	$03
	call	z,inicia_1ravez
	call	mueve_gota1

	call	gestiona_llave

	ld	a,(contador_it)
	cp	$04
	call	z,inicia_arana
	call	gestiona_arana

	ld	a,(contador_it)
	cp	$10
	call	z,inicia_flecha_arquerozero
	call	si_flecha_arquero

	jp	salidas_pasillo

;===========================================================================
;  PANTALLA 19: la ultima (arquero, arana y puerta final)
;---------------------------------------------------------------------------
nivel_19:
	ld	a,(settings4)
	bit	1,a				;Con la llave se puede subir
	call	nz,comprueba_entrepuertas	;(y terminar el juego)

	ld	a,(contador_it)
	cp	$20
	call	z,inicia_flecha_arquerozero
	cp	$50
	call	z,inicia_flecha_arquerozero
	cp	$90
	call	z,inicia_flecha_arquerozero
	cp	$ee
	call	z,inicia_flecha_arquerozero
	call	si_flecha_arquero
	call	gestiona_arquero

	ld	a,(contador_it)
	cp	$01
	call	z,inicia_arana

	ld	a,(settings4)
	bit	3,a
	call	nz,cae_arana
	ld	a,(settings4)
	bit	5,a
	call	nz,explo_arana
	bit	1,a				;(A devuelto por explo_arana)
	call	nz,inventario_llave

	ld	a,(settings4)
	bit	0,a				;Hace falta la llave?
	call	nz,dibuja_needkey

	ld	a,(jugador_x)
	cp	JUGADOR_LIMITE_IZ + 1		;Solo hay salida a la izquierda
	jp	z,anterior_nivel
	ret

;===========================================================================
;
;		C O M P R O B A C I O N E S   C O M U N E S
;
;===========================================================================

;------------------------------------------- Salidas izquierda / derecha
salidas_pasillo:
	ld	a,(jugador_x)
	cp	JUGADOR_LIMITE_IZ + 1
	jp	z,anterior_nivel
	cp	JUGADOR_LIMITE_DE
	jp	z,siguiente_nivel
	ret

;------------------------------------------- Llave (indicador e inventario)
gestiona_llave:
	ld	a,(settings4)
	bit	0,a				;Hace falta la llave?
	call	nz,indicador_key
	bit	1,a				;(A devuelto por indicador_key)
	ret	z
	jp	inventario_llave

;------------------------------------------- Gota 1: cae, salpica, techo
mueve_gota1:
	ld	a,(settings3)
	bit	1,a
	call	nz,caer_gota
	ld	a,(settings3)
	bit	0,a
	call	nz,gota_impactasuelo
	ld	a,(settings3)
	bit	2,a
	ret	z
	jp	gota_techo

;------------------------------------------- Gota 2: salpica, cae, techo
mueve_gota2:
	ld	a,(settings3)
	bit	4,a
	call	nz,gota_impactasuelo2
	ld	a,(settings3)
	bit	5,a
	call	nz,caer_gota2
	ld	a,(settings3)
	bit	6,a
	ret	z
	jp	gota_techo2

;------------------------------------------- Flecha-trampa lenta y rapida
mueve_flechas_trampa:
	ld	a,(settings)
	bit	3,a
	call	nz,flecha_trampa1
	ld	a,(settings2)
	bit	3,a
	ret	z
	jp	flecha_trampa1_rapida

;------------------------------------------- Quita la flecha clavada
borra_flecha_clavada:
	ld	a,(contador_it)
	cp	$fc
	call	z,borra_flechatrampa1
	cp	$55
	call	z,borra_flechatrampa1
	cp	$aa
	ret	nz
	jp	borra_flechatrampa1

;------------------------------------------- Animacion del ladrillo-trampa
si_bloque_trampa:
	ld	a,(settings2)
	bit	4,a
	ret	z
	jp	animacion_bloquetrampa

;------------------------------------------- Flecha del arquero
si_flecha_arquero:
	ld	a,(settings)
	bit	4,a
	ret	z
	jp	flecha_arquerozero

;------------------------------------------- Arquero (vivo / explotando)
gestiona_arquero:
	ld	a,(settings)
	bit	5,a				;(0 = vivo)
	call	z,arquero_on
	ld	a,(settings)
	bit	2,a
	ret	z
	jp	explo_arquero

;------------------------------------------- Fantasmas
mueve_fantasmas:
	call	si_fantasma1
	call	si_fantasma2
	; (sigue en si_explo_fantasma)

si_explo_fantasma:
	ld	a,(settings2)
	bit	2,a
	ret	z
	jp	explo_fantasma

si_fantasma1:
	ld	a,(settings2)
	bit	1,a
	ret	z
	jp	fantasma

si_fantasma2:
	ld	a,(settings2)
	bit	5,a
	ret	z
	jp	fantasma2

;------------------------------------------- Arana
gestiona_arana:
	ld	a,(settings4)
	bit	3,a
	call	nz,cae_arana
	; (sigue en si_explo_arana)

si_explo_arana:
	ld	a,(settings4)
	bit	5,a
	ret	z
	jp	explo_arana

;------------------------------------------- Murcielago
si_murcielago:
	ld	a,(settings2)
	bit	0,a
	ret	z
	jp	sub_murcielago

;------------------------------------------- Texto '1UP' (vida extra)
si_show1up:
	ld	a,(settings_ch)
	bit	2,a
	ret	z
	jp	dibuja_show1up

;------------------------------------------- Pinchos del suelo
gestiona_pinchos:
	ld	a,(contador_it)
	cp	10
	jr	z,gestiona_pinchos_inicia
	cp	100
	jr	z,gestiona_pinchos_inicia
	cp	140
	jr	z,gestiona_pinchos_inicia
	cp	230
	jr	nz,gestiona_pinchos_estado

gestiona_pinchos_inicia:
	call	inicia_pinchos_suelo

gestiona_pinchos_estado:			;Una sola accion por fotograma
	ld	a,(estado_pinchos)
	cp	$01
	jp	z,pinchos_suelo			;Saliendo
	cp	$03
	jp	z,pinchos_suelo			;Entrando
	cp	$02
	jp	z,check_col_pinchos		;Fuera
	ret
