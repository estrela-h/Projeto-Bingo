;==============================================================================
; MÓDULO: sorteio.inc
; Responsabilidade: Gerar números "aleatórios", garantir que não passem de 75,
;                   e checar se o número já saiu antes no bingo.
;==============================================================================

; ====================================================================
; A ROTINA PRINCIPAL DO SORTEIO
; ====================================================================
busca_numero:
    rcall   lfsr_step       ; 1. Gira a roleta matemática (rotina lá embaixo)
    mov     TEMP, RAND_L    ; 2. Pega a metade (o byte baixo) do número maluco que a roleta gerou
    
    rcall   mod75           ; 3. O número gerado pode ir até 255. Aqui cortamos ele para sobrar apenas o resto da divisão por 75 (ficando de 0 a 74).
    inc     TEMP            ; 4. Soma +1. Assim, o nosso número sorteado agora será obrigatoriamente de 1 a 75!

    ; --- 5. VERIFICA SE O NÚMERO JÁ SAIU (Olhando o "Caderno") ---
    ; Vamos usar o número sorteado como um "índice" (posição) na lista.
    ; Se saiu a bola 10, vamos olhar a 10ª linha da lista na nossa memória.
    ldi     ZL, LOW(numeros_sorteados)  ; Aponta o "dedo" (Z) para o começo da lista
    ldi     ZH, HIGH(numeros_sorteados)
    
    mov     TEMP2, TEMP     ; Copia o número sorteado (ex: 10) para o rascunho
    dec     TEMP2           ; Subtrai 1 (porque, na programação, a posição 1 da lista é o endereço 0)
    clr     r26             ; Prepara o "vai um" da matemática
    
    add     ZL, TEMP2       ; Desloca o "dedo" Z exatamente para a posição do número sorteado
    adc     ZH, r26         
    
    ld      r26, Z          ; "Load": Lê o que está escrito no caderno naquela linha exata.
    tst     r26             ; "Test": O que tá escrito lá é zero (vazio) ou não é zero (já preenchido)?
    brne    busca_numero    ; "Branch if Not Equal": Se não for zero, significa que O NÚMERO JÁ SAIU! Ignora e pula lá pro começo pra girar a roleta de novo.

    ; --- 6. NÚMERO INÉDITO! VAMOS MARCAR ---
    ; Se chegou nesta linha, é porque o 'tst' deu zero (a linha estava vazia).
    ldi     r26, 1          ; Carrega a "caneta" com o número 1
    st      Z, r26          ; "Store": Escreve 1 na lista, marcando que essa bola agora já saiu.
    inc     COUNT           ; Aumenta a contagem global de "quantas bolas já cantamos no total"

    sts     numero_atual, TEMP ; Salva esse número final no endereço `numero_atual` para que o Display saiba o que desenhar.
    ret                     ; Sucesso! Retorna para o `main.asm`.

; ====================================================================
; O FAMOSO "RESTO DA DIVISÃO" (Módulo)
; Como o microcontrolador não sabe dividir nativamente, fazemos isso 
; subtraindo 75 várias vezes seguidas até não dar mais.
; ====================================================================
mod75:
    cpi     TEMP, 75        ; Compara: O número que está na mão é menor que 75?
    brlo    mod75_ret       ; Se sim, beleza! O número já serve. Pula pro final.
    subi    TEMP, 75        ; Se for 75 ou maior, subtrai 75. (Ex: Sorteou 160. 160 - 75 = 85. Depois 85 - 75 = 10. Sobrou 10!)
    rjmp    mod75           ; Volta pro início e compara de novo.
mod75_ret:
    ret

; ====================================================================
; O EMBARALHADOR DE BITS (LFSR - Linear-Feedback Shift Register)
; Funciona empurrando os 16 bits do número para a direita e embaralhando 
; com uma "máscara mágica" dependendo do que cai pra fora.
; ====================================================================
lfsr_step:
    ; 1. Salva o último bit
    mov     TEMP, RAND_L    ; Copia a metade baixa
    andi    TEMP, 0x01      ; "E" Lógico: Isola APENAS o último bit (o mais à direita) de todos.
    
    ; 2. Empurra tudo para a direita (Shift)
    lsr     RAND_H          ; "Logical Shift Right": Empurra os bits altos pra direita. O que cair fora fica preso na "Carry Flag".
    ror     RAND_L          ; "Rotate Right": Empurra os bits baixos pra direita, preenchendo o vazio da esquerda com o bit que tinha caído do RAND_H (eles viram uma fita só).
    
    ; 3. O toque de mágica
    tst     TEMP            ; Lembra do bit isolado que salvamos no passo 1?
    breq    lfsr_ret        ; Se o bit que caiu fora era ZERO, a gente não faz mais nada. Só retorna.
    
    ; Se o bit que caiu era UM, a gente vira o número de cabeça para baixo
    ; aplicando uma porta XOR ("Ou Exclusivo") com a máscara 0xB4. Isso destrói
    ; a previsibilidade da sequência.
    ldi     TEMP, 0xB4      
    eor     RAND_H, TEMP    ; Mistura os bits altos com a máscara.
    
lfsr_ret:
    ret