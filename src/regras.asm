;==============================================================================
; --- MÓDULO: regras.inc ---
; Responsabilidade: Controlar o fluxo do jogo, realizar o sorteio, checar se
;                   o jogo acabou e exibir a animação de fim.
;==============================================================================

;==============================================================================
; --- FIM DE JOGO (Todos os 75 números saíram) ---
;==============================================================================
handler_bingo_completo:
    ldi TEMP,0
    PISCA_3_VEZES:
    ; --- ETAPA 1: Escreve "F I" e LIGA o LED ---
    sbi     PORTB, 2                 ; Liga o LED ou Buzzer (Pino 2)
    ldi     DISP_DEC, 0b01110001     ; 'F'
    ldi     DISP_UNI, 0b00110000     ; 'I'
    rcall   delay_longo
    

    ; --- Escreve "m" e DESLIGA o LED ---
    cbi     PORTB, 2                 ; Desliga o LED
    ldi     DISP_DEC, 0b00110111     ; 'n' 
    ldi     DISP_UNI, 0b00110111     ; 'n' 
    rcall   delay_longo
    
    inc TEMP
    cpi TEMP,3
    brne PISCA_3_VEZES
    
    jmp     main                     ; Vai para a main reinicializando a sram

;==============================================================================
; --- ROTINA QUE SORTEIA OS NÚMEROS ---
;==============================================================================
realizar_sorteio:
    cbr     FLAGS, (1<<0)            ; Garante que não tem nenhum clique pendente gravado
    cbr     FLAGS, (1<<2)            ; Limpa a flag de configuração inicial (o jogo já começou)
    sbi     PORTB, 3                 ; Liga um LED no pino 3 ao clicar no botão

    cpi     COUNT, BINGO_MAX         ; Compara: O total de sorteados já atingiu 75?
    brsh    sorteio_esgotado         ; Se sim (maior ou igual), pula lá pro final (sorteio esgotado)

    rcall   busca_numero             ; Vai em outro arquivo buscar um número aleatório diferente
    rcall   atualiza_display         ; Pega esse número e desenha nos displays

    cpi     COUNT, BINGO_MAX +1      ; Compara de novo: Chegou em 75 números com esse último sorteio?
    brlo    sorteio_ok               ; Se for menor que 75, tudo ok, pula pro final da rotina
    sbr     FLAGS, (1<<1)            ; Se chegou em 75, anota na FLAGS (Bit 1) que o bingo está completo.

sorteio_ok:
    rcall   delay_visual             ; Dá um tempo só para o LED do sorteio aparecer
    cbi     PORTB, 3                 ; Desliga o LED que ligamos no começo desta rotina
    ret                              ; Retorna para onde fomos chamados (no loop principal)

sorteio_esgotado:
    sbr     FLAGS, (1<<1)            ; Anota na FLAGS (Bit 1) que o bingo está completo
    rcall   delay_visual             ; Espera um tempo
    cbi     PORTB, 3                 ; Desliga o LED
    ret                              ; Retorna
