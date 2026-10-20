;===========================================================================
;
;		R U T I N A S   A U X I L I A R E S
;
;  - Navegacion por la memoria de pantalla (scanlines / filas / tercios)
;  - Pausas, contadores y velocidad del juego
;  - Vidas (restar / sumar extra) y marcadores
;  - Cambio de pantalla (siguiente / anterior / entre-puertas)
;  - Textos (titulo, controles, congrats, game over...)
;  - CLS de pixeles y atributos, borde
;
;===========================================================================

;===========================================================================
;			P A N T A L L A   (direcciones)
;
; Recordatorio direccion de pantalla:  H = 010T TSSS   L = FFFC CCCC
;   T = tercio, S = scanline dentro del caracter, F = fila, C = columna
;===========================================================================

;---------------------------------------------------------------------------
; CAMBIO SCANLINE / LINEA
;   Baja HL un scanline. Si estaba en el ultimo scanline del caracter,
;   pasa al primer scanline de la fila siguiente (mismo tercio).
;   Altera: AF
;---------------------------------------------------------------------------
cambio_scanline_linea:
	ld	a,h
	and	%00000111
	cp	$07			;Ultimo scanline del caracter?
	jr	z,cambio_descanline

	inc	h			;No: solo inc H
	ret

cambio_descanline:
	ld	a,h
	xor	%00000111		;H = 010T T000 (scanline 0)
	ld	h,a

	ld	a,l
	add	a,$20			;Fila siguiente
	ld	l,a
	ret

;---------------------------------------------------------------------------
; INCREMENTAR SCANLINE  (cruza filas y tercios correctamente)
;   Altera: AF
;---------------------------------------------------------------------------
incrementar_scanline:
	inc	h
	ld	a,h
	and	%00000111		;Hemos pasado del 8o scanline?
	ret	nz			;No: hecho

incrementar_solofila:
	ld	a,l
	add	a,$20			;Si: siguiente fila...
	ld	l,a
	ret	c			;...si hay carry, cambiamos de tercio (hecho)

	ld	a,h
	sub	$08			;Si no, nos quedamos en el mismo tercio
	ld	h,a
	ret

;---------------------------------------------------------------------------
; DECREMENTAR SCANLINE  (cruza filas y tercios correctamente)
;   Altera: AF
;---------------------------------------------------------------------------
decrementar_scanline:
	ld	a,h
	dec	h
	and	%00000111		;Estabamos en el scanline 0?
	ret	nz			;No: hecho

	ld	a,l
	sub	$20			;Si: fila anterior...
	ld	l,a
	ret	c			;...si hay carry, cambiamos de tercio (hecho)

	ld	a,h
	add	a,$08			;Si no, nos quedamos en el mismo tercio
	ld	h,a
	ret

;---------------------------------------------------------------------------
; CAMBIO H -> ATRIBUTOS
;   Entrada: A = byte alto de pantalla al inicio de un tercio ($40/$48/$50)
;   Salida:  A = byte alto del atributo correspondiente ($58/$59/$5a)
;   (Antes era una cadena de 'cp' que colgaba el juego con 'jr $' si el
;    valor no era uno de los tres. Ahora se calcula: $58 + tercio)
;---------------------------------------------------------------------------
cambioh_58595a:
	rrca
	rrca
	rrca				;A = ...0 10TT
	and	%00000011		;A = tercio (0..2)
	or	$58
	ret

;---------------------------------------------------------------------------
; SUMA A DE:  DE = DE + A   (A sin signo).  Altera: AF
;---------------------------------------------------------------------------
suma_a_de:
	add	a,e
	ld	e,a
	ret	nc
	inc	d
	ret

;---------------------------------------------------------------------------
; INCREMENTA DE:  DE = DE + 8   (un caracter de 8 bytes).  No altera flags
;---------------------------------------------------------------------------
incrementa_de:
	inc	de
	inc	de
	inc	de
	inc	de
	inc	de
	inc	de
	inc	de
	inc	de
	ret

;---------------------------------------------------------------------------
; BUSCA NIVEL EN TABLA
;   Entrada: HL = tabla de parejas (nivel, valor) terminada en $ff
;   Salida:  Z  y A = valor si el nivel actual esta en la tabla
;            NZ si no esta.   Altera: AF, C, HL
;---------------------------------------------------------------------------
busca_nivel_en_tabla:
	ld	a,(nivel)
	ld	c,a

bucle_busca_nivel:
	ld	a,(hl)
	cp	$ff
	jr	z,nivel_no_encontrado
	inc	hl
	cp	c
	jr	z,nivel_encontrado
	inc	hl
	jr	bucle_busca_nivel

nivel_encontrado:
	ld	a,(hl)
	cp	a				;Z
	ret

nivel_no_encontrado:
	or	a				;NZ ($ff)
	ret

;---------------------------------------------------------------------------
; BORRA 3 COLUMNAS:  pone a 0 tres bytes x B scanlines desde HL
;   Altera: AF, B, HL
;---------------------------------------------------------------------------
borra_3_columnas:
	ld	(hl),$00
	inc	l
	ld	(hl),$00
	inc	l
	ld	(hl),$00
	dec	l
	dec	l
	call	incrementar_scanline
	djnz	borra_3_columnas
	ret

;===========================================================================
;			P A U S A S   Y   V E L O C I D A D
;===========================================================================

;---------------------------------------------------------------------------
; PAUSA:  espera A fotogramas (A halts). A=0 -> 256
;---------------------------------------------------------------------------
sub_pausa:
	halt
	dec	a
	jr	nz,sub_pausa
	ret

;---------------------------------------------------------------------------
; RALENTIZA:  espera (A-1) fotogramas.  (velocidad: 1 rapido, 2, 3... lento)
;---------------------------------------------------------------------------
ralentiza:
	dec	a
	ret	z
	halt
	jr	ralentiza

;---------------------------------------------------------------------------
un_halt:
	halt
	ret

;---------------------------------------------------------------------------
; EFECTO FLASH TEMPORAL:  A = duracion (fotogramas)
;---------------------------------------------------------------------------
sub_efecto_flash_verde:
	ld	(timer_flash),a
	ret

;===========================================================================
;				V I D A S
;===========================================================================

;---------------------------------------------------------------------------
; RESTAR UNA VIDA  (no resta con el cheat de vidas infinitas)
;---------------------------------------------------------------------------
restar_una_vida:
	ld	a,(settings_ch)
	bit	4,a			;Cheat vidas infinitas?
	ret	nz

	ld	hl,num_vidas
	dec	(hl)

	call	mostrar_marcadores
	ret

;---------------------------------------------------------------------------
; SUMAR VIDA EXTRA  (la 1a, solo una vez: flag settings_ch bit1)
;---------------------------------------------------------------------------
sumar_vida_extra:
	ld	a,(settings_ch)
	set	1,a				;Flag Vida EXTRA ya dada
	ld	(settings_ch),a
	jr	dar_vida_extra

;---------------------------------------------------------------------------
; SUMAR VIDA EXTRA II  (solo en NIVEL_VIDA_EXTRA2, flag settings_ch bit5)
;---------------------------------------------------------------------------
sumar_vida_extra2:
	ld	a,(nivel)
	cp	NIVEL_VIDA_EXTRA2
	ret	nz

	ld	a,(settings_ch)
	set	5,a				;Flag Vida EXTRA2 ya dada
	ld	(settings_ch),a
	; (sigue en dar_vida_extra)

;---------------------------------------------------------------------------
; Parte comun: +1 vida, sonidos, texto '1UP' y marcadores.  Conserva HL
;---------------------------------------------------------------------------
dar_vida_extra:
	ld	a,(num_vidas)
	inc	a				;*** Vida EXTRA! ***
	ld	(num_vidas),a

	ld	a,SND_REBOTE
	call	sonido

	ld	a,$0a
	call	sub_pausa

	ld	a,SND_LASER
	call	sonido

	call	sub_inicia_show_1up

	push	hl
	call	mostrar_marcadores
	pop	hl
	ret

;===========================================================================
;          C O N T A D O R E S   (se llama una vez por fotograma)
;
;   contador_it ............ +1 siempre
;   timer_flash ............ -1 hasta 0
;   jugador_timer_idle ..... +1, ciclico 0..7
;   jugador_timer_invisib .. -1 hasta 0 (salvo cheat invisible)
;   jugador_timer_ataque ... -1 hasta 0
;---------------------------------------------------------------------------
contadores:
	ld	hl,contador_it
	inc	(hl)

	;------------------------------------------------
	ld	a,(timer_flash)
	or	a
	jr	z,contador_idle

	dec	a
	ld	(timer_flash),a

	;------------------------------------------------
contador_idle:
	ld	a,(jugador_timer_idle)
	inc	a
	cp	$08
	jr	nz,guarda_contador_idle
	xor	a
guarda_contador_idle:
	ld	(jugador_timer_idle),a

	;-------------- Cheat invisible -----------------
	ld	a,(settings_ch)
	bit	3,a
	jr	nz,contador_ataque

	;------------------------------------------------
	ld	a,(jugador_timer_invisib)
	or	a
	jr	z,contador_ataque

	dec	a
	ld	(jugador_timer_invisib),a

	;------------------------------------------------
contador_ataque:
	ld	a,(jugador_timer_ataque)
	or	a
	ret	z

	dec	a
	ld	(jugador_timer_ataque),a
	ret

;===========================================================================
;          R E S E T   S E T T I N G S  (al entrar en una pantalla)
;---------------------------------------------------------------------------
reset_settings:
	ld	a,(settings_ch)
	res	2,a				;Show Vida-Extra OFF
	ld	(settings_ch),a

	xor	a				;Pantalla nueva: en el suelo
	ld	(salto_paso),a
	ld	(salto_altura),a
	ld	(caida_paso),a

	;---------------------------------
	xor	a
	ld	(settings),a
	ld	(settings2),a
	ld	(settings3),a
	ld	(settings5),a

	;--------------------------------- (settings4 bits 0,1,6,7 se conservan)
	ld	a,(settings4)
	and	%11000011			;Bits 2-5 a cero (suelo/techo, arana...)
	ld	(settings4),a
	ret

;===========================================================================
;		C A M B I O   D E   P A N T A L L A
;===========================================================================

;---------------------------------------------------------------------------
; SIGUIENTE PANTALLA
;---------------------------------------------------------------------------
siguiente_nivel:
	ld	a,(settings)
	set	0,a				;Bit0 = siguiente pantalla
	ld	(settings),a

	ld	a,(nivel)
	inc	a
	cp	11				;10 -> 20 (pantallas de saltos)
	jr	nz,siguiente_no_10
	ld	a,NIVEL_PLAT_A
siguiente_no_10:
	cp	NIVEL_PLAT_B + 1		;21 -> 11
	jr	nz,siguiente_guarda
	ld	a,11
siguiente_guarda:
	ld	(nivel),a

	;---- Al salir de una pantalla de 2 pisos se vuelve al suelo ----
	cp	NIVEL_DOS_PISOS_A + 1
	call	z,h_inicial

	ld	a,(nivel)
	cp	NIVEL_DOS_PISOS_B + 1
	call	z,h_inicial

	;---- La ultima pantalla necesita la llave (otra vez) ----
	ld	a,(nivel)
	cp	NIVEL_ULTIMO
	call	z,set_needkey_res_getkey

	ld	a,JUGADOR_START_POS_X		;Pos inicial X en la nueva pantalla
	ld	(jugador_x),a

	xor	a
	ld	(contador_it),a			;Reset contador de iteraciones

	ld	a,(nivel)
	cp	NIVEL_DOS_PISOS_A + 1
	call	z,set_flag_nivel1_pasado

	ld	a,SND_REBOTE
	call	sonido
	ret

;------------------------------------------------------
h_inicial:
	ld	a,JUGADOR_Y_SUELO
	ld	(jugador_y),a
	ret

;------------------------------------------------------
set_flag_nivel1_pasado:
	ld	a,(settings2)
	set	7,a
	ld	(settings2),a
	ret

;------------------------------------------------------
set_needkey_res_getkey:
	ld	a,(settings4)
	set	0,a				;Necesita llave
	res	1,a				;No tiene llave
	ld	(settings4),a
	ret

;---------------------------------------------------------------------------
; PANTALLA ANTERIOR
;   Coloca al jugador en el borde derecho de la pantalla a la que vuelve:
;   - pantalla 0 ............. X = $98
;   - pantallas de 2 pisos ... X = $dc, Y = piso alto
;   - resto .................. X = $9b
;---------------------------------------------------------------------------
anterior_nivel:
	ld	a,(settings)
	set	0,a				;Bit0 = cambio de pantalla
	ld	(settings),a

	ld	a,SND_REBOTE
	call	sonido

	ld	a,(nivel)
	cp	11				;11 -> 21
	ld	b,NIVEL_PLAT_B
	jr	z,anterior_guarda
	cp	NIVEL_PLAT_A			;20 -> 10
	ld	b,10
	jr	z,anterior_guarda
	ld	b,a
	dec	b
anterior_guarda:
	ld	a,b
	ld	(nivel),a
	or	a

	jr	z,ir_anivelzero

	cp	NIVEL_DOS_PISOS_A
	jr	z,ir_anivel_dos_pisos

	cp	NIVEL_DOS_PISOS_B
	jr	z,ir_anivel_dos_pisos

	;------------------------------------------------------------
	ld	a,$9b				;Resto de pantallas
	ld	(jugador_x),a
	ret

ir_anivelzero:
	ld	a,$98
	ld	(jugador_x),a
	ret

ir_anivel_dos_pisos:
	ld	a,$dc
	ld	(jugador_x),a

	ld	a,JUGADOR_Y_PISO_ALTO
	ld	(jugador_y),a
	ret

;===========================================================================
;	E N T R E - P U E R T A S  (de la puerta de abajo a la de arriba)
;---------------------------------------------------------------------------
comprueba_entrepuertas:
	ld	a,(jugador_x)
	cp	POS_X_ENTRE_PUERTAS_ABAJO	;Delante de la puerta de abajo?
	ret	nz

	ld	a,SND_REBOTE
	call	sonido

	ld	a,$18
	call	sub_pausa

	ld	a,(nivel)
	cp	NIVEL_DOS_PISOS_B
	jr	nz,entrepuertas_sin_sonido_llave

	ld	hl,melodia_llave
	call	toca_melodia

entrepuertas_sin_sonido_llave:
	ld	a,$18
	call	sub_pausa

	ld	a,JUGADOR_Y_PISO_ALTO
	ld	(jugador_y),a
	ld	a,POS_X_ENTRE_PUERTAS_ARRIBA
	ld	(jugador_x),a

	call	desactivar_entrepuertas

	ld	a,(settings)
	res	7,a				;Aparece-Puerta OFF
	ld	(settings),a

	;---- Se gasta la llave en la pantalla 7 y en la ultima ----
	ld	a,(nivel)
	cp	NIVEL_DOS_PISOS_B
	jr	z,entrepuertas_gasta_llave
	cp	NIVEL_ULTIMO
	ret	nz

	ld	hl,melodia_llave
	call	toca_melodia
	call	resetear_llave
	jp	game_completed_flag		;Puerta final: juego completado

entrepuertas_gasta_llave:
	jp	resetear_llave

;----------------------------------------------
desactivar_entrepuertas:
	ld	a,(jugador_set)
	res	5,a				;Bit5 = EntrePuertas OFF
	ld	(jugador_set),a
	ret

;----------------------------------------------
game_completed_flag:
	ld	a,(settings5)
	set	2,a				;Game completed
	res	3,a				;Flag 1er borrado (por si acaso)
	ld	(settings5),a
	ret

;===========================================================================
;				T E X T O S
;
; pr_string (ROM $203c): imprime BC bytes desde DE (admite codigos de
; control AT, INK, PAPER...). La longitud se calcula con la etiqueta _fin
;===========================================================================

;--------------------------------------------------------------------------
; TITULO 'Sir Jon' a doble tamano (14 x 2 caracteres, filas 8 y 9)
; con la fila de arriba amarilla y la de abajo roja, + creditos
;--------------------------------------------------------------------------
TITULO_GRANDE_POS	equ	$4809		;Fila 8, columna 9
TITULO_GRANDE_ATTR	equ	$5909
TITULO_GRANDE_ANCHO	equ	14

sub_txt_titulo:
	ld	hl,TITULO_GRANDE_POS
	ld	de,tipografia_grande
	ld	b,16				;16 scanlines
	ld	c,TITULO_GRANDE_ANCHO
	call	copia_bloque

	ld	hl,TITULO_GRANDE_ATTR		;Fila de arriba: amarillo
	ld	a,AMARILLO_BRILLO
	call	attr_titulo_grande
	ld	hl,TITULO_GRANDE_ATTR + $20	;Fila de abajo: rojo
	ld	a,ROJO_BRILLO
	call	attr_titulo_grande

	ld	de,txt_creditos
	ld	bc,txt_creditos_fin - txt_creditos
	jp	pr_string

attr_titulo_grande:
	ld	b,TITULO_GRANDE_ANCHO
bucle_attr_titulo_grande:
	ld	(hl),a
	inc	l
	djnz	bucle_attr_titulo_grande
	ret

;--------------------------------------------------------------------------
; COPIA BLOQUE: B scanlines de C bytes desde DE a la pantalla en HL
; (sin cruzar de tercio)
;--------------------------------------------------------------------------
copia_bloque:
	push	bc
	push	hl
	ex	de,hl				;HL = datos, DE = pantalla
	ld	b,0				;BC = ancho
	ldir
	ex	de,hl				;DE = siguientes datos
	pop	hl
	call	cambio_scanline_linea		;Siguiente scanline
	pop	bc
	djnz	copia_bloque
	ret

;--------------------------------------------------------------------------
; LETRAS 'SIR JON':  7 caracteres x 8 scanlines desde HL
;--------------------------------------------------------------------------
letras_sir_jon:
	ld	de,tipografia
	ld	b,$08

bucle_sirjon_tipo:
	call	dibujados_repetitivos		;byte-inc-byte
	call	dibujados_repetitivos2		;inc-byte inc-byte
	call	dibujados_repetitivos2		;inc-byte inc-byte

	inc	l
	inc	de

	ld	a,(de)
	ld	(hl),a

	ld	a,l
	sub	$06				;Vuelve a la 1a columna
	ld	l,a

	inc	h
	inc	de
	djnz	bucle_sirjon_tipo
	ret

;--------------------------------------------------------------------------
; ATTR 'SIR JON':  7 atributos C desde HL
;--------------------------------------------------------------------------
attr_letras_sj:
	ld	b,$07

bucle_attr_sirjon_tipo:
	ld	(hl),c
	inc	l
	djnz	bucle_attr_sirjon_tipo
	ret

;--------------------------------------------------------------------------
sub_txt_thanks_play:
	ld	de,txt_thanks_play
	ld	bc,txt_thanks_play_fin - txt_thanks_play
	jp	pr_string

;--------------------------------------------------------------------------
sub_txt_congrats:
	ld	de,txt_congrats
	ld	bc,txt_congrats_fin - txt_congrats
	jp	pr_string

;--------------------------------------------------------------------------
CONTROLES_POS		equ	$4889		;Fila 12, columna 9
CONTROLES_ATTR		equ	$5989
CONTROLES_ANCHO		equ	14

sub_txt_controles:
	;-------------------------- Recuadro (14 x 4 caracteres, filas 12-15)
	ld	hl,CONTROLES_POS
	ld	de,recuadro_controles
	ld	b,32
	ld	c,CONTROLES_ANCHO
	call	copia_bloque

	ld	hl,CONTROLES_ATTR		;Atributos del recuadro
	ld	c,4
bucle_attr_controles:
	ld	b,CONTROLES_ANCHO
	push	hl
bucle_attr_controles_fila:
	ld	(hl),AMARILLO
	inc	l
	djnz	bucle_attr_controles_fila
	pop	hl
	ld	de,$20
	add	hl,de
	dec	c
	jr	nz,bucle_attr_controles

	;-------------------------- Textos: CONTROLES / Q A O P SPC
	ld	de,txt_controles
	ld	bc,txt_controles_fin - txt_controles
	jp	pr_string

;--------------------------------------------------------------------------
sub_txt_pulse_continuar:
	ld	de,txt_pulse_continuar
	ld	bc,txt_pulse_continuar_fin - txt_pulse_continuar
	jp	pr_string

;--------------------------------------------------------------------------
; Espera a que se pulse ESPACIO
;--------------------------------------------------------------------------
sub_leer_teclado_pulse_continuar:
	ld	a,$7f				;Fila B-N-M-SS-SPC
	in	a,($fe)
	bit	0,a				;Espacio
	jr	nz,sub_leer_teclado_pulse_continuar
	ret

;--------------------------------------------------------------------------
; Lineas en blanco arriba y abajo del 'Game Over'
;--------------------------------------------------------------------------
sub_txt_gameover_paddings:
	ld	de,txt_gameover_p1
	ld	bc,txt_gameover_p1_fin - txt_gameover_p1
	call	pr_string

	ld	de,txt_gameover_p2
	ld	bc,txt_gameover_p2_fin - txt_gameover_p2
	jp	pr_string

;--------------------------------------------------------------------------
; 'GAME OVER' con tipografia propia (11 caracteres; cada uno: 8 bytes de
; dibujo + 1 byte de atributo)
;--------------------------------------------------------------------------
sub_txt_tipografia_gameover:
	ld	hl,$488b
	ld	de,gameover_tipografia

	ld	b,$0b

bucle_frase_gameover:
	push	bc
	ld	b,$08

bucle_tipografia_gameover:
	ld	a,(de)
	ld	(hl),a

	inc	h
	inc	de
	djnz	bucle_tipografia_gameover

	ld	a,h
	sub	$08				;Vuelve al scanline 0
	ld	h,a

	;---------- attr ------------
	push	hl

	ld	a,h
	call	cambioh_58595a
	ld	h,a

	ld	a,(de)
	ld	(hl),a

	pop	hl
	;----------------------------

	inc	de
	inc	l

	pop	bc
	djnz	bucle_frase_gameover
	ret

;===========================================================================
;			    M A R C A D O R E S
;---------------------------------------------------------------------------
mostrar_marcadores:
	;-------------------------- Recuadro medieval (filas 0-2)
	call	dibuja_marco

	;-------------------------- 'Sir Jon' arriba a la izquierda (fila 1)
	ld	hl,$4023
	call	letras_sir_jon

	ld	hl,$5823
	ld	c,VERDE				;'Sir Jon' verde (sin brillo)
	call	attr_letras_sj

	;-------------------------- Icono del caballero
	call	dibuja_vidas

	;-------------------------- Numero de vidas (tipografia propia)
	ld	hl,$4031
	ld	de,vidas_tipografia

	ld	a,(num_vidas)
	or	a
	call	z,vidas_top_zero		;0 o $ff -> se muestra como 1
	cp	$ff
	call	z,vidas_top_zero

	ld	b,a				;Avanza A digitos (16 bytes cada uno)

bucle_incr_bytes_vidas:
	call	incrementa_de
	call	incrementa_de
	djnz	bucle_incr_bytes_vidas

	;--------------------------
	ld	b,$08

bucle_dibuja_vidas_tipografia:
	ld	a,(de)
	ld	(hl),a

	inc	l
	inc	de

	ld	a,(de)
	ld	(hl),a

	dec	l
	inc	de

	inc	h
	djnz	bucle_dibuja_vidas_tipografia

	;-------------------------- Atributos del marcador de vidas
	ld	hl,$582f
	ld	(hl),ROJO			;Casco: rojo (sin brillo)
	inc	l
	ld	a,VERDE				;'x5': verde (sin brillo)
	ld	b,$04

bucle_attr_vidas_tipografia:
	ld	(hl),a
	inc	l
	djnz	bucle_attr_vidas_tipografia
	ret

;----------------------------------
vidas_top_zero:
	ld	a,$01
	ret

;---------------------------------------------------------------------------
; Icono del caballero en el marcador
;---------------------------------------------------------------------------
dibuja_vidas:
	ld	hl,$402f
	ld	de,caballero_vida

	ld	b,$08

bucle_caballero_vida:
	ld	a,(de)
	ld	(hl),a
	inc	h
	inc	de
	djnz	bucle_caballero_vida
	ret

;===========================================================================
;		      B O R D E   Y   C L S
;===========================================================================
borde:
	ld	a,%00001111			;BORDCR: 00BBB111 (B = borde)
	ld	(border_c),a

	ld	a,$01				;Color del borde = 1 (azul)
	out	($fe),a
	ret

;---------------------------------------------------------------------------
; CLS de atributos: todo a INK 6 (amarillo), PAPER 0, sin brillo ni flash
;---------------------------------------------------------------------------
sub_cls_attr:
	ld	hl,$5800
	ld	(hl),AMARILLO
	ld	de,$5801
	ld	bc,$02ff
	ldir
	ret

;---------------------------------------------------------------------------
; CLS de pixeles
;---------------------------------------------------------------------------
sub_cls:
	ld	hl,$4000
	ld	(hl),$00
	ld	de,$4001
	ld	bc,$17ff
	ldir
	ret
