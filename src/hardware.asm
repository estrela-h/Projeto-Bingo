;==============================================================================
; MÓDULO: hardware.asm
; Responsabilidade: Configurar os pinos físicos do chip, preparar os cronômetros
;                   (Timers) e dizer o que fazer quando um alarme (Interrupção) tocar.
;==============================================================================

; ====================================================================
; 1. LIMPANDO O DADOS DA RODADA ANTERIOR (Memória SRAM)
; Antes de começar o jogo, precisamos apagar todos os números que 
; possam ter ficado gravados de um jogo anterior (ou lixo de memória).
; ====================================================================
init_sram:
    ldi     ZL, LOW(numeros_sorteados)  ; Aponta para o começo da lista do bingo
    ldi     ZH, HIGH(numeros_sorteados)
    ldi     TEMP, BINGO_MAX             ; Coloca 75 no contador
    clr     TEMP2                       ; TEMP2 vira o número zero

init_sram_loop:
    st      Z+, TEMP2       ; Escreve zero na posição indicada por Z e segue para
    ; a próxima
    dec     TEMP            ; Diminui 1 do contador
    brne    init_sram_loop  ; Se ainda não apagou as 75 linhas, volta e repete

    ; Agora que a lista principal está limpa, zera também as variáveis soltas
    sts     numero_atual, TEMP2
    sts     tick_ms, TEMP2
    sts     tick_botao, TEMP2
    sts     mux_div, TEMP2
    ret                     ; Tudo limpo. Retorna

; ====================================================================
; 2. CONFIGURANDO AS PORTAS
; ====================================================================
init_portas:
    ; Configura a Porta D inteira como SAÍDA (Para os 8 segmentos do Display)
    ldi     TEMP, 0xFF      ; 1 = Saída
    out     DDRD, TEMP      ; Define a direção
    clr     TEMP            
    out     PORTD, TEMP     ; Garante que comecem apagados

    ; Configura metade da Porta B como SAÍDA (Para ligar os Displays e o LED/Buzzer)
    ldi     TEMP, 0b00001111 ; Os 4 primeiros pinos (da direita) são saídas
    out     DDRB, TEMP
    clr     TEMP
    out     PORTB, TEMP     ; Começam desligados

    ; Configura a Porta C como ENTRADA (Para ler o botão do Bingo)
    ldi     TEMP, 0b00000000 ; 0 = Entrada
    out     DDRC, TEMP
    
    ; LIGANDO O PULL-UP INTERNO:
    ; Como removemos os resistores externos, mandamos 1 para os pinos 
    ; C0 (A0) e C1 (A1) para ativar os resistores internos do chip.
    ldi     TEMP, 0b00000011 ; Ativa o Pull-Up nos pinos 0 e 1 (A0 e A1)
    out     PORTC, TEMP     
    ret

; ====================================================================
; 3. AJUSTANDO O DESPERTADOR (Timer 0)
; Vamos configurar o relógio interno para disparar um "alarme" a cada 1 milissegundo.
; ====================================================================
init_timer0:
    ldi     TEMP, (1<<WGM01)            ; Modo CTC: O timer conta até um limite e zera sozinho
    out     TCCR0A, TEMP
    
    ldi     TEMP, (1<<CS01)|(1<<CS00)   ; Prescaler 64: Deixa o relógio 64 vezes mais lento para conseguirmos contar
    out     TCCR0B, TEMP
    
    ldi     TEMP, 249                   ; O limite da contagem. Quando chegar no 249, dá exatamente 1 milissegundo
    out     OCR0A, TEMP
    
    lds     TEMP, TIMSK0                
    ori     TEMP, (1<<OCIE0A)           ; Liga o alarme. Quando bater 249, ele avisa o chip (Interrupção).
    sts     TIMSK0, TEMP
    ret

; ====================================================================
; 4. INSTALANDO A CAMPAINHA DO BOTÃO (Pin Change Interrupt)
; ====================================================================
init_pcint:
    lds     TEMP, PCICR
    ori     TEMP, (1<<PCIE1)    ; Habilita o grupo de alarmes da Porta C
    sts     PCICR, TEMP
    
    ldi     TEMP, (1<<PCINT8) | (1<<PCINT9)   ; Ouve o botão do Sorteio (A0) e o de Ligar/Desligar (A1)
    sts     PCMSK1, TEMP
    ret

; ====================================================================
; 5. A ROTINA DO DESPERTADOR (Dispara a cada 1 milissegundo)
; Isso acontece em segundo plano, independente do que o programa principal estiver fazendo.
; ====================================================================
TIMER0_COMPA_ISR:
    ; --- Salva o estado atual ---
    push    TEMP
    in      TEMP, SREG
    push    TEMP
    push    TEMP2

    ; --- Atualiza o relógio global do sistema ---
    lds     TEMP, tick_ms   ; Pega a contagem atual de milissegundos
    inc     TEMP            ; Adiciona +1
    sts     tick_ms, TEMP   ; Salva de volta

    ; --- A Roleta do Sorteio ---
    ; Como essa rotina roda 1000 vezes por segundo, vamos usar isso para gerar aleatoriedade.
    ; Incrementamos um número. O valor que estiver aqui na exata fração de segundo
    ; que o usuário apertar o botão, será utilizado para o cálculo do número sorteado
    inc     RAND_L          ; Aumenta a variável de aleatoriedade
    brne    isr_mux_check   ; Se não zerou, continua
    ldi     RAND_L, 0x01    ; Se zerou, volta pra 1 (evita zero absoluto no sorteio)

    ; --- Lógica de Multiplexação (Piscar os displays) ---
isr_mux_check:
    lds     TEMP, mux_div   ; Pega um contador auxiliar
    inc     TEMP
    cpi     TEMP, 2         ; Já passaram 2 milissegundos?
    brlo    isr_mux_skip    ; Se não, pula e não atualiza o display agora. (Isso evita que o brilho fique tremendo)
    
    clr     TEMP            ; Se deu 2ms, zera a contagem e vai atualizar o display
    sts     mux_div, TEMP
    rjmp    isr_mux_do

isr_mux_skip:
    sts     mux_div, TEMP   ; Salva a contagem e retorna
    rjmp    isr_mux_fim

isr_mux_do:
    ; 1. Primeiro, desliga a energia dos dois displays
    in      TEMP2, PORTB
    andi    TEMP2, ~((1<<0) | (1<<1)) ; Zera os pinos 0 e 1 da porta B (Corta a energia)
    out     PORTB, TEMP2

    clr     TEMP2
    out     PORTD, TEMP2    ; Apaga os segmentos também

    ; 2. Verifica de quem é a vez de acender (Dezena ou Unidade?)
    tst     MUX_STATE       ; Testa a variável de controle (0 = Dezena, 1 = Unidade)
    brne    isr_mux_unidade ; Se não for zero, é a vez da unidade

isr_mux_dezena:
    out     PORTD, DISP_DEC ; Manda o desenho da DEZENA para os pinos
    in      TEMP2, PORTB
    ori     TEMP2, (1<<0)   ; Liga a energia só do display da dezena
    andi    TEMP2, ~(1<<1)  ; Garante que a unidade fique desligada
    out     PORTB, TEMP2
    
    ldi     MUX_STATE, 1    ; Muda a chave. Na próxima vez, será a unidade
    rjmp    isr_mux_fim

isr_mux_unidade:
    out     PORTD, DISP_UNI ; Manda o desenho da UNIDADE para os pinos
    in      TEMP2, PORTB
    ori     TEMP2, (1<<1)   ; Liga a energia só do display da unidade
    andi    TEMP2, ~(1<<0)  ; Garante que a dezena fique desligada
    out     PORTB, TEMP2
    
    clr     MUX_STATE       ; Muda a chave para 0. Na próxima vez, será a dezena

isr_mux_fim:
    ; --- Desempilha o estado do chip ---
    pop     TEMP2
    pop     TEMP
    out     SREG, TEMP
    pop     TEMP
    reti                    ; Acabou o alarme e retorna

; ====================================================================
; 6. A ROTINA DA CAMPAINHA (Alguém apertou o botão físico)
; ====================================================================
PCINT1_ISR:
    ; Salva o estado do chip
    push    TEMP
    in      TEMP, SREG
    push    TEMP
    
    ; Anota a que horas (em milissegundos) o botão foi apertado
    lds     TEMP, tick_ms
    sts     tick_botao, TEMP
    
    ; Levanta a bandeira de "Botão Pressionado" marcando o Bit 0 como 1.
    ; O 'main.asm' vai ver essa bandeira hasteada e vai iniciar o processo de filtro (debounce)
    ; e, se for válido, fará o sorteio!
    sbr     FLAGS, (1<<0)   
    
    ; Devolve o estado
    pop     TEMP
    out     SREG, TEMP
    pop     TEMP
    reti                    ; Fim da interrupção do botão
