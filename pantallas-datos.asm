;===========================================================================
;
;		  D A T O S   D E   L A S   P A N T A L L A S
;
;  Por cada pantalla N:
;     pantallaN ........ atributos + fondo (se dibuja al entrar)
;     pantallaN_redib .. lo que se redibuja cada fotograma
;
;  Piezas y macros: ver pantallas.asm
;  Recordatorio de direcciones:
;     pixeles   $4000-$57ff  (H = 010T TSSS, L = FFFC CCCC)
;     atributos $5800-$5aff  ($5800 + fila * 32 + columna)
;===========================================================================

tabla_pantallas:
	defw	pantalla0,  pantalla1,  pantalla2,  pantalla3,  pantalla4
	defw	pantalla5,  pantalla6,  pantalla7,  pantalla8,  pantalla9
	defw	pantalla10, pantalla11, pantalla12, pantalla13, pantalla14
	defw	pantalla15, pantalla16, pantalla17, pantalla18, pantalla19
	defw	pantalla20, pantalla21

tabla_redibujables:
	defw	pantalla0_redib,  pantalla1_redib,  pantalla2_redib,  pantalla3_redib
	defw	pantalla4_redib,  pantalla5_redib,  pantalla6_redib,  pantalla7_redib
	defw	pantalla8_redib,  pantalla9_redib,  pantalla10_redib, pantalla11_redib
	defw	pantalla12_redib, pantalla13_redib, pantalla14_redib, pantalla15_redib
	defw	pantalla16_redib, pantalla17_redib, pantalla18_redib, pantalla19_redib
	defw	pantalla20_redib, pantalla21_redib

;===========================================================================
;			P I E Z A S   C O M U N E S
;===========================================================================

;------------------------------------------- Suelo con ladrillo-trampa (attr)
attr_suelo_trampa:
	P_RECT		$5ac0, 32, 2, AMARILLO
	P_RECT		$5aca, 2, 1, AMARILLO_BRILLO	;Ladrillo-trampa
	P_FIN

;------------------------------------------- Suelo y techo de ladrillo (attr)
attr_suelo_y_techo:
	P_RECT		$5ac0, 32, 2, AMARILLO
	P_RECT		$5920, 32, 2, AMARILLO
	P_FIN

;------------------------------------------- Pasillo: suelo y techo de ladrillo
suelo_y_techo:
	P_SUELO		$50c0
	P_SUELO		$4820
	P_FIN

;------------------------------------------- Dos portaantorchas (tercio 2)
portantorchas_pasillo:
	P_PORTANTORCHA	$48cc
	P_PORTANTORCHA	$48d9
	A_PORTANTORCHA	$59cd
	A_PORTANTORCHA	$59da
	P_FIN

;------------------------------------------- Sus dos antorchas (attr y redib)
attr_antorchas_pasillo:
	A_ANTORCHA	$598c
	A_ANTORCHA	$5999
	P_FIN

antorchas_pasillo:
	P_ANTORCHA	$488c
	P_ANTORCHA	$4899
	P_FIN

;------------------------------------------- Ladrillo-trampa (redib)
attr_flecha_trampa:
	P_ATTR		$5a8c, AMARILLO_BRILLO
	P_ATTR		$5aac, AMARILLO_BRILLO
	P_FIN

;------------------------------------------- Techo alto con arcos (1, 7, 9, 19)
techo_con_arcos:
	P_LADRILLOS	$4040, 16, 2
	P_LADRILLOS	$4063, 2, 2
	P_LADRILLOS	$406b, 2, 2
	P_LADRILLOS	$4073, 2, 2
	P_LADRILLOS	$407b, 2, 2
	P_LADRILLOS	$4084, 4, 8
	P_FIN

;===========================================================================
;  PANTALLA 0: exterior del castillo (dibujado especial, ver pantalla0.asm)
;===========================================================================
pantalla0:
	A_MARCADORES
	P_RELLENA	$5800, 255, BLANCO_BRILLO	;Cielo (estrellas)
	P_RELLENA	$5900, 255, BLANCO_BRILLO
	P_RELLENA	$5a00, 255, BLANCO_BRILLO
	P_RECT		$5898, 8, 20, AMARILLO		;Castillo
	P_RELLENA	$5ac0, 16, VERDE		;Hierba
	P_RELLENA	$5ae0, 16, %00011100
	P_RELLENA	$5ad0, 9, ROJO			;Puente
	P_RELLENA	$5af0, 9, ROJO
	P_CODIGO	pantalla_zero
	P_FIN

pantalla0_redib:
	P_CODIGO	pantalla0_redibujable		;Estrellas y cadena
	P_FIN

;===========================================================================
;  PANTALLAS 1, 7 y 19: sala de las puertas (dos pisos)
;===========================================================================
attr_sala_puertas:
	A_MARCADORES
	P_LISTA		attr_suelo_trampa
	P_RECT		$5840, 32, 3, AMARILLO		;Techo
	A_ANTORCHA	$58a8
	A_ANTORCHA	$58b0
	P_FIN

sala_puertas:
	P_SUELO		$50c0
	P_LADRILLOS	$500e, 9, 2			;Plataforma del 1er piso
	P_LADRILLOS	$48ee, 1, 2			;Ladrillo limite
	P_LISTA		techo_con_arcos
	P_PORTANTORCHA	$40e8
	P_PORTANTORCHA	$40f0
	P_PORTANTORCHA	$40f8
	A_PORTANTORCHA	$58e9
	A_PORTANTORCHA	$58f1
	A_PORTANTORCHA	$58f9
	P_FIN

escudos_sala_puertas:
	P_VENTANA	$480c, escudo
	P_VENTANA	$4814, escudo
	P_FIN

;------------------------------------------- Pantalla 1
pantalla1:
	P_LISTA		attr_sala_puertas
	A_ANTORCHA	$58b8
	P_LISTA		sala_puertas
	P_FIN

pantalla1_redib:
	P_PUERTAS
	P_ANTORCHA	$40a8
	P_ANTORCHA	$40b0
	P_ANTORCHA	$40b8
	P_LISTA		attr_flecha_trampa
	P_FIN

;------------------------------------------- Pantalla 7
pantalla7:
	P_LISTA		attr_sala_puertas
	A_ANTORCHA	$58b8
	A_ESCUDO	$590c
	A_ESCUDO	$5914
	P_LISTA		sala_puertas
	P_LISTA		escudos_sala_puertas
	P_VENTANA	$4822, ventana
	P_FIN

pantalla7_redib:
	P_PUERTAS
	P_ANTORCHA	$40a8
	P_ANTORCHA	$40b0
	P_ANTORCHA	$40b8
	P_ATTR_GOTA	$5aae
	P_FIN

;------------------------------------------- Pantalla 19 (la ultima)
pantalla19:
	P_LISTA		attr_sala_puertas		;(solo 2 antorchas)
	A_ESCUDO	$590c
	A_ESCUDO	$5914
	A_TELARANA	$5946
	P_LISTA		sala_puertas
	P_LISTA		escudos_sala_puertas
	P_TELARANA	$4846
	P_HILO		$4887
	P_VENTANA	$4823, ventana
	P_GRAFICO	$4898, estandarte, 32
	A_ESTANDARTE $5998, ROJO_BRILLO
	P_FIN

pantalla19_redib:
	P_PUERTAS
	P_ANTORCHA	$40a8
	P_ANTORCHA	$40b0
	P_FIN

;===========================================================================
;  PANTALLAS 2 a 6 y 8: pasillos
;===========================================================================
pantalla2:
	A_MARCADORES
	P_LISTA		attr_suelo_trampa
	P_RECT		$5920, 32, 2, AMARILLO
	P_LISTA		attr_antorchas_pasillo
	P_LISTA		suelo_y_techo
	P_VENTANA	$48a5, ventana
	P_VENTANA	$48b2, ventana
	P_LISTA		portantorchas_pasillo
	P_GRAFICO	$40a5, estandarte, 32	;Decoracion
	A_ESTANDARTE	$58a5, ROJO_BRILLO
	P_GRAFICO	$40ce, rejilla, 24	;Decoracion
	A_REJILLA	$58ce
	P_GRAFICO	$40b7, estandarte, 32	;Decoracion
	A_ESTANDARTE	$58b7, ROJO_BRILLO
	P_FIN

pantalla2_redib:
	P_LISTA		antorchas_pasillo
	P_LISTA		attr_flecha_trampa
	P_FIN

;------------------------------------------- Pantallas 3 y 4
pantalla3:
pantalla4:
	A_MARCADORES
	P_LISTA		attr_suelo_y_techo
	P_LISTA		attr_antorchas_pasillo
	P_LISTA		suelo_y_techo
	P_VENTANA	$48b2, ventana
	P_LISTA		portantorchas_pasillo
	P_GRAFICO	$40c6, rejilla, 24	;Decoracion
	A_REJILLA	$58c6
	P_GRAFICO	$40d6, rejilla, 24	;Decoracion
	A_REJILLA	$58d6
	P_FIN

pantalla3_redib:
	P_LISTA		antorchas_pasillo
	P_FIN

pantalla4_redib:
	P_LISTA		antorchas_pasillo
	P_ATTR_GOTA	$5ab1
	P_FIN

;------------------------------------------- Pantalla 5
pantalla5:
	A_MARCADORES
	P_LISTA		attr_suelo_y_techo
	P_LISTA		attr_antorchas_pasillo
	P_LISTA		suelo_y_techo
	P_VENTANA	$48b2, escudo
	A_ESCUDO	$59b2
	P_LISTA		portantorchas_pasillo
	P_GRAFICO	$40a9, estandarte, 32	;Decoracion
	A_ESTANDARTE	$58a9, VERDE
	P_GRAFICO	$40b3, estandarte, 32	;Decoracion
	A_ESTANDARTE	$58b3, VERDE
	P_FIN

pantalla5_redib:
	P_LISTA		antorchas_pasillo
	P_ATTR_GOTA2	$5ab7
	P_ATTR_GOTA	$5aab
	P_LISTA		attr_flecha_trampa
	P_FIN

;------------------------------------------- Pantallas 6 y 8
pantalla6:
pantalla8:
	A_MARCADORES
	P_LISTA		attr_suelo_y_techo
	P_LISTA		attr_antorchas_pasillo
	P_LISTA		suelo_y_techo
	P_VENTANA	$48a5, ventana
	P_VENTANA	$48b2, ventana
	P_LISTA		portantorchas_pasillo
	P_GRAFICO	$40ce, rejilla, 24	;Decoracion
	A_REJILLA	$58ce
	P_FIN

pantalla6_redib:
	P_LISTA		antorchas_pasillo
	P_ATTR_GOTA2	$5ab7
	P_ATTR		$5a90, AMARILLO_BRILLO		;Ladrillo-trampa
	P_ATTR		$5ab0, AMARILLO_BRILLO
	P_FIN

pantalla8_redib:
	P_LISTA		antorchas_pasillo
	P_ATTR_GOTA	$5ab1
	P_FIN

;===========================================================================
;  PANTALLA 9: foso con puente y bolas de fuego (sin atributos fijos)
;===========================================================================
pantalla9:
	P_SUELO_SIMPLE	$50c0
	P_PUENTE	$50ca, 7
	P_PIEDRA	$50d8, piedras			;4 piedras en el suelo
	P_PIEDRA	$50da, piedras+96
	P_PIEDRA	$50dc, piedras+48
	P_PIEDRA	$50de, piedras+48
	P_LISTA		techo_con_arcos
	P_VENTANA	$48a5, ventana
	P_FIN

pantalla9_redib:
	A_VENTANA	$59a5
	P_RECT		$59ec, 2, 7, ROJO_BRILLO	;Columnas de fuego
	P_RECT		$59f1, 2, 7, ROJO_BRILLO
	P_RECT		$59f6, 2, 7, ROJO_BRILLO
	P_RELLENA	$5aca, 14, ROJO			;Puente
	P_FIN

;===========================================================================
;  PANTALLA 10: suelo y techo de piedra
;===========================================================================
pantalla10:
	A_MARCADORES
	P_RECT		$5ac0, 32, 2, AMARILLO
	P_RECT		$5900, 32, 2, AMARILLO
	P_LISTA		attr_antorchas_pasillo
	P_PIEDRAS_ABAJO	$50c0
	P_PIEDRAS_ARRIBA $4800
	P_LISTA		portantorchas_pasillo
	P_FIN

pantalla10_redib:
	P_LISTA		antorchas_pasillo
	P_ATTR_GOTA2	$5ab8
	P_ATTR_GOTA	$5aab
	P_FIN

;===========================================================================
;  PANTALLAS 11 y 12: arana y bolas de fuego
;===========================================================================
pantalla11:
	A_MARCADORES
	P_RELLENA	$5ac0, 63, AMARILLO
	P_RECT		$5948, 2, 2, AMARILLO		;Piedra suelta
	P_RELLENA	$5aca, 22, ROJO			;Puente
	P_RECT		$5900, 32, 2, AMARILLO
	A_TELARANA	$5946
	P_PIEDRAS_ABAJO	$50c0
	P_PIEDRAS_ARRIBA $4800
	P_PIEDRA	$4848, piedras+48
	P_TELARANA	$4846
	P_HILO		$4887
	P_PUENTE	$50ca, 11
	P_FIN

pantalla11_redib:
pantalla12_redib:
	P_RECT		$59ec, 2, 7, ROJO_BRILLO	;Columnas de fuego
	P_RECT		$59f1, 2, 7, ROJO_BRILLO
	P_RECT		$59f6, 2, 7, ROJO_BRILLO
	P_RECT		$59fb, 2, 7, ROJO_BRILLO
	P_ATTR		$5aa7, BLANCO_BRILLO
	P_ATTR		$5aa6, BLANCO_BRILLO
	P_FIN

pantalla12:
	A_MARCADORES
	P_RELLENA	$5ac0, 32, ROJO			;Puente
	P_RECT		$5900, 32, 4, AMARILLO
	A_TELARANA	$594e
	P_PIEDRAS_ARRIBA $4800
	P_PIEDRAS_ARRIBA $4840
	P_TELARANA	$484e
	P_HILO		$488f
	P_PUENTE	$50c0, 16
	P_FIN

;===========================================================================
;  PANTALLA 13
;===========================================================================
pantalla13:
	A_MARCADORES
	P_RELLENA	$5ac0, 32, ROJO			;Puente
	P_RECT		$5900, 32, 4, AMARILLO
	P_RECT		$5ad4, 12, 2, AMARILLO		;Suelo de ladrillo
	A_TELARANA	$595a
	P_PIEDRAS_ARRIBA $4800
	P_PIEDRAS_ARRIBA $4840
	P_TELARANA	$485a
	P_HILO		$489b
	P_SUELO		$50c0
	P_PUENTE	$50c0, 10
	P_FIN

pantalla13_redib:
	P_ATTR_GOTA	$5aab
	P_ATTR_GOTA2	$5ab8
	P_FIN

;===========================================================================
;  PANTALLA 14
;===========================================================================
pantalla14:
	A_MARCADORES
	P_RECT		$5ac0, 32, 2, AMARILLO
	A_TELARANA	$595a
	P_LISTA		suelo_y_techo
	P_VENTANA	$4067, ventana
	P_VENTANA	$406f, ventana
	P_VENTANA	$4077, ventana
	P_TELARANA	$485a
	P_HILO		$489b
	P_FIN

pantalla14_redib:
	P_VENTANA	$48a5, ventana
	P_VENTANA	$48b2, ventana
	P_ATTR_GOTA	$5aab
	P_ATTR_GOTA2	$5ab9
	P_FIN

;===========================================================================
;  PANTALLAS 15 y 16: escudos y pinchos
;===========================================================================
pantalla15:
	A_MARCADORES
	P_RECT		$5ac0, 32, 2, AMARILLO
	P_LISTA		attr_antorchas_pasillo
	P_LISTA		suelo_y_techo
	P_VENTANA	$4067, ventana
	P_VENTANA	$406f, ventana
	P_VENTANA	$4077, ventana
	P_VENTANA	$48a5, escudo
	P_VENTANA	$48b2, escudo
	A_ESCUDO	$59b2
	A_ESCUDO	$59a5
	P_LISTA		portantorchas_pasillo
	P_FIN

pantalla15_redib:
	P_LISTA		antorchas_pasillo
	P_ATTR_GOTA2	$5ab9
	A_ANTORCHA	$598c
	P_FIN

pantalla16:
	A_MARCADORES
	P_LISTA		attr_suelo_y_techo
	P_LISTA		attr_antorchas_pasillo
	P_LISTA		suelo_y_techo
	P_VENTANA	$406f, ventana
	P_VENTANA	$48a5, escudo
	P_VENTANA	$48b2, escudo
	A_ESCUDO	$59b2
	A_ESCUDO	$59a5
	P_LISTA		portantorchas_pasillo
	P_FIN

pantalla16_redib:
	P_LISTA		antorchas_pasillo
	P_ATTR_GOTA2	$5abd
	P_FIN

;===========================================================================
;  PANTALLA 17: ventanales (murcielago y pinchos)
;===========================================================================
pantalla17:
	A_MARCADORES
	P_LISTA		attr_suelo_y_techo
	P_LISTA		suelo_y_techo
	P_VENTANA	$4067, ventana
	P_VENTANA	$4074, ventana
	P_VENTANA	$48a5, ventana
	P_VENTANA	$48b2, ventana
	P_FIN

pantalla17_redib:
	P_FIN

;===========================================================================
;  PANTALLA 18
;===========================================================================
pantalla18:
	A_MARCADORES
	P_LISTA		attr_suelo_y_techo
	A_TELARANA	$5957
	P_LISTA		attr_antorchas_pasillo
	P_LISTA		suelo_y_techo
	P_TELARANA	$4857
	P_HILO		$4898
	P_VENTANA	$48b2, ventana
	P_LISTA		portantorchas_pasillo
	P_GRAFICO	$40c6, rejilla, 24	;Decoracion
	A_REJILLA	$58c6
	P_GRAFICO	$40b6, estandarte, 32	;Decoracion
	A_ESTANDARTE	$58b6, ROJO_BRILLO
	P_FIN

pantalla18_redib:
	P_LISTA		antorchas_pasillo
	P_ATTR_GOTA	$5ab1
	P_FIN

;===========================================================================
;  PANTALLAS 20 y 21 (v2): como la 10, con huecos en el suelo que hay que
;  saltar. Van entre la 10 y la 11 (10 -> 20 -> 21 -> 11).
;  Los huecos (4 columnas = 2 piedras) estan tambien en jugabilidad.asm
;  (huecos_20 / huecos_21): si se cambian aqui, hay que cambiarlos alli.
;===========================================================================
pantalla20:
	A_MARCADORES
	P_RECT		$5ac0, 32, 2, AMARILLO
	P_RECT		$5900, 32, 2, AMARILLO
	P_LISTA		attr_antorchas_pasillo
	P_LISTA		suelo_20
	P_PIEDRAS_ARRIBA $4800
	P_LISTA		portantorchas_pasillo
	P_FIN

pantalla21:
	A_MARCADORES
	P_RECT		$5ac0, 32, 2, AMARILLO
	P_RECT		$5900, 32, 2, AMARILLO
	P_LISTA		attr_antorchas_pasillo
	P_LISTA		suelo_21
	P_PIEDRAS_ARRIBA $4800
	P_LISTA		portantorchas_pasillo
	P_FIN

;------------------------------------------- Suelo con huecos (tambien se
;  redibuja mientras el caballero cae por un hueco: redibuja_suelo_saltos)
suelo_20:
	P_RECT		$5ac0, 32, 2, AMARILLO	;(colores del suelo, por si la caida los cambia)
	P_PIEDRAS_ABAJO	$50c0
	P_HUECO		$50c8, 4			;Columnas 8-11
	P_HUECO		$50d2, 4			;Columnas 18-21
	P_FIN

suelo_21:
	P_RECT		$5ac0, 32, 2, AMARILLO	;(colores del suelo, por si la caida los cambia)
	P_PIEDRAS_ABAJO	$50c0
	P_HUECO		$50ca, 4			;Columnas 10-13
	P_HUECO		$50d4, 4			;Columnas 20-23
	P_FIN

pantalla20_redib:
pantalla21_redib:
	P_LISTA		antorchas_pasillo
	P_FIN

