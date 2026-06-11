;==============================================================================
; MÓDULO: delays.inc
; Responsabilidade: Fazer o processador "perder tempo" de propósito para
;                   criar pausas visuais, e filtrar os ruídos do botão físico.
;==============================================================================

; ====================================================================
; --- DELAYS ORIGINAIS PARA O BINGO (Animação e Travamento) ---
; ====================================================================

; delay_longo: Cria uma pausa bem grande (usado no fim do jogo para piscar devagar)
delay_longo:
    ; 1. Salva os dados originais (Push = Guardar no bolso)
    ; Como vamos usar as "mãos" (registradores r26, r27, r28) para contar, 
    ; guardamos o que quer que estivesse neles antes, para não estragar outra parte do programa.
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
    nop                   ; "No Operation" - Faz absolutamente nada, só gasta 1 ciclo de máquina
    dec     r28           ; Diminui 1 do ponteiro dos segundos
    brne    dly_in        ; "Branch if Not Equal": Se não chegou em zero, volta pro dly_in

    dec     r27           ; Quando os segundos chegam a zero, diminui 1 dos minutos
    brne    dly_mid       ; Se os minutos não chegaram a zero, recarrega os segundos e continua

    dec     r26           ; Quando os minutos chegam a zero, diminui 1 das horas
    brne    dly_out       ; Se as horas não chegaram a zero, recarrega tudo e continua

    ; 4. Restaura os dados originais (Pop = Tirar do bolso)
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
; ====================================================================
debounce_adaptativo:
    ldi     r26, 10         ; Coloca 10 na contagem. O botão precisa ficar apertado por 10 testes seguidos!
    
debounce_loop:
    rcall   delay_1ms       ; Espera 1 milissegundo cravado
    in      TEMP, PINC      ; Tira uma "foto" do estado de todos os pinos da porta C
    
    ; Aqui, assumimos que o botão está ligado no esquema "Pull-up" (Pressionado = 0, Solto = 1)
    sbrc    TEMP, 0         ; "Skip if Bit in Register is Cleared": Pula a próxima linha se o pino 0 for zero (se estiver apertado)
    rjmp    debounce_reset  ; Se o botão soltou no meio do teste (foi pra 1), essa linha executa. É ruído! Cancela tudo!
    
    dec     r26             ; Se pulou a linha acima, é porque continua apertado. Diminui 1 da contagem.
    brne    debounce_loop   ; Se ainda não testou 10 vezes, volta e testa de novo.
    
    ; Se sobreviveu às 10 voltas no loop, o clique é firme e verdadeiro!
    sec                     ; "Set Carry": Levanta a bandeira de "Sucesso" (Carry = 1) para avisar a rotina principal.
    ret                     ; Retorna vitorioso!

debounce_reset:
    ; Caiu aqui porque o botão deu uma "piscada" e soltou antes de dar 10 milissegundos.
    ldi     r26, 10         ; Restaura as 10 leituras caso precise tentar de novo no futuro
    clc                     ; "Clear Carry": Abaixa a bandeira (Carry = 0) avisando que foi alarme falso.
    ret                     ; Retorna avisando a rotina principal para ignorar.

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
    sbiw    r24, 1          ; "Subtract Immediate from Word": Subtrai 1 do par r25:r24 inteiro
    brne    delay_1ms_loop  ; Se o par ainda não zerou, continua subtraindo
    
    pop     r25             ; Devolve r25
    pop     r24             ; Devolve r24
    ret                     ; Retorna