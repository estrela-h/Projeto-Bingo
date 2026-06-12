;==============================================================================
; MÓDULO: delays.asm
; Responsabilidade: Fazer o processador "perder tempo" de propósito para
;                   criar pausas visuais e filtrar os ruídos do botão físico.
;==============================================================================

; ====================================================================
; --- DELAYS ORIGINAIS PARA O BINGO (Animação e Travamento) ---
; ====================================================================

; delay_longo: Cria uma pausa bem grande (usado no fim do jogo para piscar devagar)
delay_longo:
    ; 1. Salva os dados originais
    ; Como vamos usar os registradores r26, r27 e r28 para contar,
    ; guardamos o que quer que estivesse neles antes, para não estragar outra parte do programa
    push    r26
    push    r27
    push    r28

    ; 2. Prepara os três "ponteiros" do nosso relógio de atraso
    ldi     r26, 200      ; Ponteiro das horas
dly_out:
    ldi     r27, 200      ; Ponteiro dos minutos
dly_mid:
    ldi     r28, 130      ; Ponteiro dos segundos
dly_in:
    ; 3. O coração do loop (onde o tempo realmente é gasto)
    nop                   ; Faz absolutamente nada, só gasta 1 ciclo de máquina
    dec     r28           ; Diminui 1 do ponteiro dos segundos
    brne    dly_in        ; Se não chegou em zero, volta pro dly_in

    dec     r27           ; Quando os segundos chegam a zero, diminui 1 dos minutos
    brne    dly_mid       ; Se os minutos não chegaram a zero, recarrega os segundos e continua

    dec     r26           ; Quando os minutos chegam a zero, diminui 1 das horas
    brne    dly_out       ; Se as horas não chegaram a zero, recarrega tudo e continua

    ; 4. Restaura os dados originais
    ; A ordem de tirar tem que ser o inverso da ordem que guardamos.
    pop     r28
    pop     r27
    pop     r26
    ret                   ; Retorna para onde a rotina foi chamada

; delay_visual: Uma pausa mais curta, só para dar tempo do olho humano 
; ver o número sorteado ou o botão acender. Usa apenas 2 loops.
delay_visual:
    push    r26           ; Guarda o valor original de r26
    push    r27           ; Guarda o valor original de r27
    
    ldi     r26, 80       ; Loop externo (repete 80 vezes)
dly_v1:
    ldi     r27, 250      ; Loop interno (repete 250 vezes a cada volta do externo)
dly_v2:
    nop                   ; Gasta um tempinho atoa
    dec     r27           ; Diminui o contador interno
    brne    dly_v2        ; Se não for zero, volta pro dly_v2
    
    dec     r26           ; Diminui o contador externo
    brne    dly_v1        ; Se não for zero, volta pro dly_v1
    
    pop     r27           ; Devolve o valor original de r27
    pop     r26           ; Devolve o valor original de r26
    ret                   ; Retorna

; ====================================================================
; DEBOUNCE ADAPTATIVO EXPLÍCITO (Filtro passa-baixa digital)
; Função: Ter certeza de que o clique no botão foi real e não um ruído.
;
; BUG FIX 2 — COMPORTAMENTO DE BLOQUEIO (documentado):
; Esta rotina chama delay_1ms num loop de polling e trava o loop principal
; por até ~10 ms (10 × 1 ms). Durante esse tempo o Timer0 ISR continua
; disparando normalmente (o display multiplexado e RAND_L seguem rodando),
; mas nenhuma outra lógica do loop_principal é executada. O bloqueio é
; aceitável para este projeto: 10 ms é imperceptível ao usuário e o Timer0
; garante que o sistema não "congele" de verdade.
; ====================================================================
debounce_adaptativo:
    ldi     r26, 10         ; Coloca 10 na contagem. O botão precisa ficar apertado por 10 testes seguidos
    
debounce_loop:
    rcall   delay_1ms       ; Espera 1 milissegundo cravado
    in      TEMP, PINC      ; Guarda o estado de todos os pinos da porta C
    
    ; Lógica Pull-up Interno: O botão Pressionado lê ZERO (0). Solto lê UM (1)
    sbrc    TEMP, 0         ; Pula se for ZERO (Continua pressionado)
    rjmp    debounce_reset  ; Se for UM (soltou), é ruído da mola batendo. Aborta a leitura
    
    dec     r26             ; Se pulou, continua apertado. Diminui a contagem
    brne    debounce_loop   ; Repete até bater 10 milissegundos consecutivos em ZERO
    
    ; Se sobreviveu às 10 voltas no loop, o clique é verdadeiro
    sec                     ; Ativa o Carry para avisar a rotina principal
    ret                     ; Retorna

debounce_reset:
    ; Caiu aqui porque o botão deu uma "piscada" e soltou antes de dar 10 milissegundos
    ldi     r26, 10         ; Restaura as 10 leituras caso precise tentar de novo no futuro
    clc                     ; Limpa o Carry, avisando que foi alarme falso
    ret                     ; Retorna avisando a rotina principal para ignorar

; ====================================================================
; Delay auxiliar de 1 milissegundo (Para clock de 16MHz)
; ====================================================================
delay_1ms:
    push    r24             ; Guarda r24
    push    r25             ; Guarda r25
    
    ; Aqui usamos um truque diferente: r24 e r25 formam um par (16 bits)
    ; Juntos, eles conseguem contar até 65.535 (em vez do limite de 255 de um registrador sozinho).
    ; A instrução sbiw consome exatamente 4 ciclos de clock para cada subtração. 
    ; Em um chip de 16 milhões de hertz, subtrair 4000 vezes gasta exato 1 milissegundo.
    ldi     r24, LOW(4000)  ; Coloca a parte baixa do número 4000 em r24
    ldi     r25, HIGH(4000) ; Coloca a parte alta do número 4000 em r25
    
delay_1ms_loop:
    sbiw    r24, 1          ; Subtrai 1 do par r25:r24 inteiro
    brne    delay_1ms_loop  ; Se o par ainda não zerou, continua subtraindo
    
    pop     r25             ; Devolve r25
    pop     r24             ; Devolve r24
    ret                     ; Retorna
