;==============================================================================
; MÓDULO: display.inc
; Responsabilidade: Pegar o número sorteado (ex: 73), separar o 7 e o 3, 
;                   descobrir quais LEDs acender para formar esses desenhos
;                   e preparar a exibição.
;==============================================================================

; Define uma constante para apagar tudo. 0 = LED apagado. 
; 0b00000000 significa todos os 8 segmentos (A, B, C, D, E, F, G e o ponto) apagados.
.equ SEG_OFF = 0b00000000

; ====================================================================
; TABELA DE TRADUÇÃO (Look-up Table)
; Fica gravada na Memória Flash (o "manual" imutável do chip).
; Cada byte aqui representa os LEDs que devem acender para formar um número de 0 a 9.
; Exemplo: O primeiro byte (0b00111111) forma o número "0" (acende as bordas, apaga o meio).
; ====================================================================
tabela_seg:
    ; Posições:  0           1           2           3           4           5           6           7
    .db 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 0b01101101, 0b01111101, 0b00000111
    ; Posições:  8           9        (Espaços extras preenchidos com zero por segurança)
    .db 0b01111111, 0b01101111, 0b00000000, 0b00000000

; ====================================================================
; ROTINA PRINCIPAL DO DISPLAY
; ====================================================================
atualiza_display:
    ; 1. PREPARAÇÃO E SEGURANÇA
    push    r27             ; Guarda o valor original de r27 "no bolso" (Pilha)
    
    in      r27, SREG       ; O SREG é a "memória de curto prazo" do chip (guarda se a última conta deu zero, negativo, etc). 
    push    r27             ; Copiamos o SREG pro r27 e guardamos no bolso também, para não bagunçar o programa principal.
    
    cli                     ; "Clear Interrupts": Desliga os alarmes! Pede silêncio total para o chip focar só nessa matemática agora.

    ; 2. PEGA O NÚMERO SORTEADO
    lds     r27, numero_atual ; "Load from SRAM": Vai lá no "caderno" e pega o número recém sorteado (ex: 42)
    clr     DISP_DEC        ; Zera a nossa contagem de dezenas (começa em 0)

; 3. O TRUQUE DA DIVISÃO (Separando a dezena da unidade)
; Como não temos o comando de dividir por 10, vamos subtrair 10 várias vezes!
; Exemplo para o número 42:
; 42 - 10 = 32 (Dezena = 1) -> 32 - 10 = 22 (Dezena = 2) -> 22 - 10 = 12 (Dezena = 3) -> 12 - 10 = 2 (Dezena = 4)
; O que sobrou (2) é a unidade!
separa_dezena:
    cpi     r27, 10         ; Compara: O número que sobrou em r27 é menor que 10?
    brlo    separa_fim      ; "Branch if Lower": Se for menor, acabou! Pula pra próxima etapa.
    subi    r27, 10         ; "Subtract Immediate": Se for maior ou igual a 10, subtrai 10 do número.
    inc     DISP_DEC        ; "Increment": Adiciona +1 no nosso contador de Dezenas.
    rjmp    separa_dezena   ; Volta pro início do loop para tentar subtrair 10 de novo.

; 4. TRADUZINDO OS NÚMEROS EM DESENHOS (Acesso à Memória Flash)
separa_fim:
    ; r27 agora contém a Unidade. DISP_DEC contém a Dezena.

    ; --- Preparando para ler o desenho da UNIDADE ---
    ; Para ler a memória Flash, usamos o Registrador Z (que é a união de ZL e ZH). Ele funciona como um "dedo apontando" para uma página do manual.
    ldi     ZL, LOW(tabela_seg<<1)  ; Pega o endereço da tabela. O "<<1" (multiplicar por 2) é obrigatório no AVR porque a Flash é organizada em palavras de 2 bytes.
    ldi     ZH, HIGH(tabela_seg<<1)
    
    add     ZL, r27         ; Soma a nossa unidade (ex: 2) ao endereço da tabela. Assim o dedo aponta exatamente para a 3ª posição da lista!
    clr     r26             ; Zera o r26 para ajudar na conta de "vai um" (carry)
    adc     ZH, r26         ; Soma o "vai um" na parte alta do endereço, caso o endereço tenha passado de 255.
    
    lpm     DISP_UNI, Z     ; "Load Program Memory": Lê o desenho que o dedo (Z) tá apontando e guarda no registrador DISP_UNI.

    ; --- Preparando para ler o desenho da DEZENA ---
    ; Repete exatamente o mesmo processo acima, mas agora usando o valor da dezena.
    ldi     ZL, LOW(tabela_seg<<1)
    ldi     ZH, HIGH(tabela_seg<<1)
    
    add     ZL, DISP_DEC    ; Soma a nossa dezena ao endereço da tabela.
    clr     r26             
    adc     ZH, r26         
    
    lpm     DISP_DEC, Z     ; Lê o desenho da dezena e guarda no registrador DISP_DEC.

    ; 5. AJUSTE FINO VISUAL (Apagar zero à esquerda)
    ; Se sortear o número 7, a matemática acima vai dizer que a dezena é "0" e a unidade é "7".
    ; Mas num bingo, não mostramos "07", mostramos apenas "7" (com a dezena apagada).
    lds     r27, numero_atual ; Pega o número original inteiro de novo
    cpi     r27, 10         ; Compara: O número original é maior ou igual a 10?
    brsh    display_ok      ; "Branch if Same or Higher": Se for 10 ou mais (ex: 12, 45, 70), tá tudo certo, pula pro final.
    
    ldi     DISP_DEC, SEG_OFF ; Se não pulou, é porque o número é menor que 10. Então sobrescreve o desenho do "0" da dezena com a ordem de "Apagar Tudo".

; 6. FINALIZANDO E DEVOLVENDO O CHIP AO NORMAL
display_ok:
    pop     r27             ; Tira a memória de curto prazo (SREG) do bolso...
    out     SREG, r27       ; ... e devolve ela para o lugar certo, restaurando como o chip estava antes.
    pop     r27             ; Tira o valor original do r27 do bolso e devolve.
    ; Observação: O comando 'out SREG' não liga os alarmes (interrupções) de novo sozinho se eles foram desligados pelo 'cli' no começo.
    ; Mas normalmente isso é tratado no retorno da interrupção (reti) que chama essa rotina.
    ret                     ; Retorna! Missão cumprida, displays prontos para acender.