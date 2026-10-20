;===========================================================================
;
;			    G A M E   O V E R
;
;  Se llega con 'jp game_over' desde el bucle principal (sin vidas).
;  Muestra el texto, toca la melodia de game over, hace una pausa y
;  vuelve al titulo al pulsar ESPACIO.
;===========================================================================
game_over:
	call	sub_txt_gameover_paddings
	call	sub_txt_tipografia_gameover

	ld	hl,melodia_gameover		;Melodia triste (~4,5 s)
	call	toca_melodia

	ld	a,$32				;Y 1 segundo mas de pausa
	call	sub_pausa

	call	sub_txt_pulse_continuar
	call	sub_leer_teclado_pulse_continuar

	jp	comienzo_programa
