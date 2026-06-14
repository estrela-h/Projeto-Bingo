;==============================================================================
; MÓDULO: sorteio.asm
; Responsabilidade: Gerar números "aleatórios", garantir que não passem de BINGO_MAX,
;                   e checar se o número já saiu antes no bingo.
;==============================================================================

; ====================================================================
; A ROTINA PRINCIPAL DO SORTEIO
; ====================================================================
busca_numero:
    rcall   lfsr_step       ; Gira a roleta matemática
    mov     TEMP, RAND_L    ; Pega a metade (o byte baixo) do número que a roleta gerou
    
    rcall   modBINGO_MAX            ; O número gerado pode ir até 255. Aqui cortamos ele para
    ;sobrar apenas o resto da divisão por BINGO_MAX  (ficando de 0 a BINGO_MAX  -1).
    inc     TEMP            ; Soma +1. Assim, o nosso número sorteado agora será
    ;obrigatoriamente de 1 a o valor BINGO_MAX

    ;            --- VERIFICA SE O NÚMERO JÁ SAIU ---
    ; Vamos usar o número sorteado como um "índice" na lista
    ; Se saiu o 10, vamos olhar a 10ª linha da lista
    ldi     ZL, LOW(numeros_sorteados)  ; Aponta para o começo da lista
    ldi     ZH, HIGH(numeros_sorteados)
    
    mov     TEMP2, TEMP     ; Copia o número sorteado (ex: 10) para o TEMP2
    dec     TEMP2           ; Subtrai 1 (porque a posição 1 da lista é o endereço 0)
    clr     r26             ; Prepara o "vai um" da matemática
    
    add     ZL, TEMP2       ; Armazena no Z a posição do número sorteado
    adc     ZH, r26         
    
    ld      r26, Z          ; Carrega em R26 o valor sorteado configurado para o display
    tst     r26             ; R26 está armazenado com zero?
    brne    busca_numero    ; Se não for zero, significa que o número já saiu. Ignora e pula para o começo pra girar a roleta de novo.

    ;               --- NÚMERO NOVO ---
    ; Se chegou nesta linha, é porque o 'tst' deu zero (a linha estava vazia).
    ldi     r26, 1          ; Carrega R26 com o número 1
    st      Z, r26          ; Escreve 1 na lista, marcando que esse número já saiu.
    inc     COUNT           ; Aumenta a contagem global de quantos números já contamos no total

    sts     numero_atual, TEMP ; Salva esse número final no endereço "numero_atual" para que possamos mostrar no display
    ret                     ; Concluído. Retorna para o "main.asm".

; ====================================================================
; RESTO DA DIVISÃO (Módulo)
; Como o microcontrolador não sabe dividir nativamente, fazemos isso 
; subtraindo o valor de BINGO_MAX várias vezes seguidas até não dar mais.
; ====================================================================
modBINGO_MAX:
    cpi     TEMP, BINGO_MAX       ; O número atual é menor que BINGO_MAX ?
    brlo    modBINGO_MAX_ret       ; Se sim, beleza! O número já serve. Pula pro final
    subi    TEMP, BINGO_MAX        ; Se for BINGO_MAX  ou maior, subtrai BINGO_MAX . ( se BINGO_MAX =75, temos o seguinte ex: Sorteou 160. 160 - 75 = 85. Depois 85 - 75 = 10. Sobrou 10)
    rjmp    modBINGO_MAX          ; Volta pro início e compara de novo
modBINGO_MAX_ret:
    ret

; ====================================================================
; O EMBARALHADOR DE BITS (LFSR - Linear-Feedback Shift Register)
; Funciona empurrando os 16 bits do número para a direita e embaralhando 
; com uma "máscara" dependendo do que cai pra fora.
; ====================================================================
lfsr_step:
    ; 1. Salva o último bit
    mov     TEMP, RAND_L    ; Copia a metade baixa
    andi    TEMP, 0x01      ; Isola APENAS o último bit (o mais à direita) de todos
    
    ; 2. Empurra tudo para a direita (Shift)
    lsr     RAND_H          ; "Logical Shift Right": Empurra os bits altos pra
    ;direita. O que cair fora fica preso na "Carry Flag"
    ror     RAND_L          ; "Rotate Right": Empurra os bits baixos pra direita,
    ;preenchendo o vazio da esquerda com o bit que tinha caído do RAND_H (eles viram
    ;uma fita só).
    
    ; 3. Teste
    tst     TEMP            ; O bit isolado é igual a zero?
    breq    lfsr_ret        ; Se sim, só retorna.
    
    ; Se o bit que caiu era UM, a gente vira o número de cabeça para baixo
    ; aplicando uma porta XOR ("Ou Exclusivo") com a "máscara" 0xB4. Isso quebra
    ; a previsibilidade da sequência.
    ldi     TEMP, 0xB4      
    eor     RAND_H, TEMP    ; Mistura os bits altos com a máscara.
    
lfsr_ret:
    ret
