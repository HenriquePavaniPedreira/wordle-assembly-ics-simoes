jmp start

rodata_header_message:
	string "WORDLE\n\n"
rodata_win_message:
	string "VOCE ADIVINHOU A PALAVRA!"
rodata_word:
	string "FOGAO"

data_pf:
	var #7
data_pf_matches:
	var #9
data_pf_match_assignments:
	var #5
data_video_offset: 
	var #1

start:
	loadn r0, #0
	store data_video_offset, r0

	loadn r0, #rodata_header_message
	call proc_puts

_round_start:
	loadn r1, #0 ; r1 guarda o ponteiro para a letra atual
	call proc_pf_new_round

_round_process_input:;ler os inputs
	call proc_pf_print
	call proc_getc

	; Processar caracteres especiais
	loadn r2, #47;tabela ascii '/' para submeter
	cmp r0, r2
	jeq _round_process_input_try_submit

	loadn r2, #45;tabela ascii '-' para apagar
	cmp r0, r2
	jeq _round_process_input_backspace

	jmp _round_process_input_standard_path

_round_process_input_try_submit:
	; Ignorar submissoes incompletas.
	loadn r2, #5;entrada nao existente (enq)$
	cmp r1, r2
	jle _round_process_input
	
	jmp _round_submit

_round_process_input_backspace:;funcao de apagar caractere
	loadn r2, #0
	cmp r1, r2
	jeq _round_process_input

	dec r1
	loadn r2, #95
	loadn r3, #data_pf
	add r3, r3, r1
	storei r3, r2

	jmp _round_process_input

_round_process_input_standard_path:
	; Normalizar caracteres em caixa baixa para caixa alta.
	loadn r2, #97
	cmp r0, r2
	jle _round_process_input_non_lower_case_ascii

	loadn r2, #122
	cmp r0, r2
	jgr _round_process_input_non_lower_case_ascii

	loadn r2, #32
	sub r0, r0, r2

_round_process_input_non_lower_case_ascii:
	; Ignorar caracteres invalidos.
	loadn r2, #65
	cmp r0, r2
	jle _round_process_input

	loadn r2, #90
	cmp r0, r2
	jgr _round_process_input

	; Ignorar caracteres alem da quantidade maxima.
	loadn r2, #5
	cmp r1, r2
	jeg _round_process_input

	; Guardar o caractere recebido.
	loadn r2, #data_pf
	add r2, r2, r1
	storei r2, r0

	inc r1
	jmp _round_process_input

_round_submit:
	; Terminar o round.
	; 
	; Nesse passo sao processados as letras submetidas no round e sao determinadas
	; as dicas que serao dadas ao jogador.
	call proc_pf_find_matches

	loadn r0, #data_pf_matches
	call proc_puts

	loadn r0, #1
	loadn r3, #79
_round_submit_verify_matches:
	loadn r1, #data_pf_matches
	add r1, r1, r0
	loadi r1, r1

	; Algum match nao foi exato. Comecar um novo round.
	cmp r1, r3
	jne _round_start

	inc r0
	loadn r2, #6
	cmp r0, r2
	jle _round_submit_verify_matches

_win_condition_met:
	; O jogador venceu!

	loadn r0, #rodata_win_message
	call proc_puts

	halt

; Gera as dicas para a playfield atual.
proc_pf_find_matches:
	push r0
	push r1
	push r2
	push r3
	push r4
	
	loadn r0, #data_pf_matches
	loadn r1, #10
	storei r0, r1 ;

	loadn r3, #0
	loadn r0, #0
_pf_find_matches_clear_assignments:
	loadn r2, #data_pf_match_assignments
	add r2, r2, r0
	storei r2, r3

	inc r0
	loadn r2, #5
	cmp r0, r2
	jle _pf_find_matches_clear_assignments

	loadn r0, #0
_pf_find_matches_outer_loop:
	
	loadn r2, #data_pf
	add r2, r2,	r0
	loadi r2, r2

	loadn r3, #rodata_word
	add r3, r3, r0
	loadi r3, r3

	cmp r2, r3
	jeq _pf_find_matches_outer_loop_exact_match

	loadn r1, #0
_pf_find_matches_inner_loop:
	loadn r4, #0	
	loadn r3, #rodata_word
	add r3, r3, r1
	loadi r3, r3

	cmp r2, r3
	jne _pf_find_matches_inner_loop_match_failed

	loadn r3, #data_pf_match_assignments
	add r3, r3, r1
	loadi r3, r3

	loadn r4, #0
	cmp r3, r4
	jne _pf_find_matches_inner_loop_match_failed

	loadn r3, #data_pf_match_assignments
	add r3, r3, r1
	
	loadn r4, #1
	storei r3, r4
	jmp _pf_find_matches_inner_loop_ended

_pf_find_matches_inner_loop_match_failed:
	inc r1
	loadn r3, #5
	cmp r1, r3
	jle _pf_find_matches_inner_loop

_pf_find_matches_inner_loop_ended:
	loadn r1, #1
	cmp r4, r1
	jeq _pf_find_matches_inner_loop_partial_match
	jmp _pf_find_matches_outer_loop_no_match

_pf_find_matches_inner_loop_partial_match:
	loadn r1, #data_pf_matches
	add r1, r1, r0
	
	inc r1
	loadn r2, #63
	storei r1, r2

	jmp _pf_find_matches_outer_loop_continue

_pf_find_matches_outer_loop_exact_match:
	loadn r1, #data_pf_matches
	add r1, r1, r0

	inc r1
	loadn r2, #79
	storei r1, r2

	loadn r1, #data_pf_match_assignments
	add r1, r1, r0

	loadn r2, #1
	storei r1, r2

	jmp _pf_find_matches_outer_loop_continue

_pf_find_matches_outer_loop_no_match:
	loadn r1, #data_pf_matches
	add r1, r1, r0

	inc r1
	loadn r2, #88
	storei r1, r2

_pf_find_matches_outer_loop_continue:
	inc r0
	loadn r2, #5
	cmp r0, r2
	jle _pf_find_matches_outer_loop


	loadn r0, #6
	loadn r1, #data_pf_matches
	add r1, r1, r0

	loadn r2, #10
	storei r1, r2

	inc r1
	storei r1, r2

	inc r1
	loadn r2, #0
	storei r1, r2

	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
	rts

; Comeca um novo round.
proc_pf_new_round:
	push r0
	push r1
	push r2

	loadn r0, #0
_pf_new_round_loop:
	loadn r2, #data_pf
	add r1, r0,	r2

	loadn r2, #95
	storei r1, r2

	loadn r2, #1
	add r0, r0, r2

	loadn r2, #5
	cmp r0, r2
	jle _pf_new_round_loop

	loadn r2, #data_pf
	add r1, r0, r2

	loadn r2, #13
	storei r1, r2

	inc r1
	loadn r2, #0
	storei r1, r2

	pop r2
	pop r1
	pop r0
	rts

; Printa a payfield atual.
proc_pf_print:
	push r0

	loadn r0, #data_pf
	call proc_puts

	pop r0
	rts
	

; Printa uma string na tela.
;
; Pametros:
;	r0 - Endereco de uma string terminada em zero.
;
proc_puts:
	push r1
	push r2
	push r4
	load r4, data_video_offset

_puts_loop:
	loadi r1, r0

	loadn r2, #0
	cmp r1, r2
	jeq _puts_loop_done

	loadn r2, #10
	cmp r1, r2
	jeq _puts_line_feed

	loadn r2, #13
	cmp r1, r2
	jeq _puts_carriage_return

	; Standard character.
	outchar r1, r4

	loadn r2, #1
	add r4, r4, r2

	jmp _puts_special_handled
_puts_line_feed:
	loadn r2, #40
	add r4, r4, r2
_puts_carriage_return:
	loadn r2, #40
	mod r2, r4, r2
	sub r4, r4, r2

_puts_special_handled:

	loadn r2, #1
	add r0, r0, r2
	jmp _puts_loop
_puts_loop_done:

	store data_video_offset, r4
	pop r4
	pop r2
	pop r1
	rts

proc_getc:
	push r1
	
_getc_loop: ;pegando char a char
	loadn r1, #255
	inchar r0

	cmp r0, r1
	jeq _getc_loop

	pop r1
	rts