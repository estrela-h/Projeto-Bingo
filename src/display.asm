;==============================================================================
; MÓDULO: display.asm
; Responsabilidade: Pegar o número sorteado (ex: 73), separar o 7 e o 3, 
;                   descobrir quais LEDs acender para formar esses desenhos
;                   e preparar a exibição.
;==============================================================================

; Define uma constante para apagar o display.
.equ SEG_OFF = 0b00000000

; ====================================================================
; TABELA DE TRADUÇÃO (Look-up Table)
; Fica gravada na Memória Flash (o "manual" imutável do chip).
; Cada byte aqui representa os LEDs que devem acender para formar um número de 0 a 9
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
    push    r27             ; Guarda o valor original de r27 na pilha
    
    in      r27, SREG       ; Guarda os status do SREG em R27
    push    r27             ; E armazena na pilha
    
    cli                     ; Desliga os alarmes (interrupções)

    ; 2. PEGA O NÚMERO SORTEADO
    lds     r27, numero_atual ; Guarda o número recém sorteado (ex: 42)
    clr     DISP_DEC        ; Zera a nossa contagem de dezenas (começa em 0)

; 3. O TRUQUE DA DIVISÃO (Separando a dezena da unidade)
; Como não temos o comando de dividir por 10, vamos subtrair 10 várias vezes
; Exemplo para o número 42:
; 42 - 10 = 32 (Dezena = 1) -> 32 - 10 = 22 (Dezena = 2) -> 22 - 10 = 12 (Dezena = 3) -> 12 - 10 = 2 (Dezena = 4)
; O que sobrou (2) é a unidade
separa_dezena:
    cpi     r27, 10         ; O número que sobrou em R27 é menor que 10?
    brlo    separa_fim      ; Se for menor, pula para a próxima etapa.
    subi    r27, 10         ; Se for maior ou igual a 10, subtrai 10 do número.
    inc     DISP_DEC        ; Adiciona 1 no nosso contador de Dezenas.
    rjmp    separa_dezena   ; Volta para o início do loop para tentar subtrair 10 de novo

; 4. TRADUZINDO OS NÚMEROS EM DESENHOS (Acesso à Memória Flash)
separa_fim:
    ; R27 agora contém a Unidade. DISP_DEC contém a Dezena.

    ; --- Preparando para ler o desenho da UNIDADE ---
    ; Para ler a memória Flash, usamos o ponteiro Z
    ldi     ZL, LOW(tabela_seg<<1)  ; Pega o endereço da tabela.
    ldi     ZH, HIGH(tabela_seg<<1)
    
    add     ZL, r27         ; Soma a nossa unidade (ex: 2) ao endereço da tabela
    clr     r26             ; Zera o R26 para ajudar na conta de "vai um" (carry)
    adc     ZH, r26         ; Soma o "vai um" na parte alta do endereço, caso o endereço tenha passado de 255
    
    lpm     DISP_UNI, Z     ; Lê o desenho que Z está apontando e guarda no registrador DISP_UNI

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
    cpi     r27, 10         ; O número original é maior ou igual a 10?
    brsh    display_ok      ; Se for 10 ou mais, pula para o final
    
    ldi     DISP_DEC, SEG_OFF ; Se não pulou, é porque o número é menor que 10. Então sobrescreve o desenho do "0" da dezena com a ordem de "Apagar Tudo".

; 6. FINALIZANDO E DEVOLVENDO O CHIP AO NORMAL
display_ok:
    pop     r27             ; Tira a cópia do SREG da pilha
    ; BUG FIX 5: O comentário original dizia que "out SREG não re-habilita interrupções",
    ; o que está ERRADO. No AVR, escrever no SREG via "out" restaura TODOS os bits,
    ; inclusive o bit I (Global Interrupt Enable). Se o SREG salvo tinha I=1 (caso
    ; normal — chamada vinda do loop_principal com sei ativo), as interrupções são
    ; re-habilitadas aqui automaticamente. A linha abaixo está correta como está.
    out     SREG, r27       ; Restaura SREG salvo, RE-HABILITANDO interrupções (bit I=1)
    pop     r27             ; Tira o valor original de r27 da pilha
    sei                     ; Garante re-habilitação explícita (segurança extra, dado que
                            ; atualiza_display sempre é chamada de contexto com sei ativo)
    ret                     ; Retorna, displays prontos para acender
