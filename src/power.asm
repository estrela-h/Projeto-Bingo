;==============================================================================
; MÓDULO: power.asm
; Responsabilidade: controlar o botão de energia para ligar, desligar e resetar.
;==============================================================================

;==============================================================================
; --- CONTROLE DO BOTÃO DE ENERGIA (Desligar, Ligar ou Resetar) ---
;==============================================================================
desliga_sistema:
    ; ====================================================================
    ; TRATAMENTO INDEPENDENTE: Quick Press (Desliga) vs Long Press (Reset)
    ; Em vez de apagar a tela de cara, vamos medir o tempo do clique primeiro!
    ; ====================================================================
    ldi     r26, 20
power_loop_ext:
    ldi     r27, 100         ; Espera confirmação de reset
power_loop_int:
    rcall   delay_1ms
    in      TEMP, PINC       ; Lê o estado do botão
    
    ; Se o botão SOLTAR ANTES de dar o tempo (clique rápido):
    sbrc    TEMP, 1          
    rjmp    apenas_desliga   ; Vai para a rotina que realmente apaga a tela e dorme
    
    dec     r27              ; Se não, pode ser que o usuário esteja tentando
    brne    power_loop_int   ; resetar o circuito, então devemos esperar para
    dec     r26              ; confirmar.
    brne    power_loop_ext

    ; ====================================================================
    ; Segurou os 5 segundos! (RESET TOTAL)
    ; ====================================================================
espera_soltar_reset:
    in      TEMP, PINC
    sbrs    TEMP, 1                  ; Espera você soltar o botão (ir para 1)
    rjmp    espera_soltar_reset      ; Se continuar 0, fica preso aqui!

    rcall   delay_visual             ; Filtro anti-ruído da soltura
    jmp     main                     ; Reinicia o sorteio

    ; ====================================================================
    ; ROTINA DE SONO PROFUNDO (Desligamento)
    ; ====================================================================
apenas_desliga:
    ; 1. APAGA A TELA: Como confirmamos que foi um clique rápido, apagamos os displays
    clr     TEMP
    out     PORTB, TEMP
    out     PORTD, TEMP
    out     TCCR0B, TEMP             ; Para o relógio
    sts     TIMSK0, TEMP             ; Corta os alarmes do display

    rcall   delay_longo              ; Atraso para evitar interferência de ruído da soltura

    ; 2. Limpa interrupções pendentes
    ldi     TEMP, (1<<PCIF1)         ; Marca no bit PCIF1 que uma interrupção foi requisitada
    out     PCIFR, TEMP              ; Escreve no registrador e esta ação vai limpar a FLAG,
    ; quando a rotina de interrupção for executada

    ; 3. Configura o modo de sono e dorme
    ldi     TEMP, (1<<SM1) | (1<<SE)  ; Define o modo ADC Noise Reduction Mode
    out     SMCR, TEMP                ; Este para a CPU, mas permite interrupções externas
    sei                               ; Interrupção global disponível

dorme_loop:
    sleep                            
    
    ; --- ACORDANDO ---
    rcall   delay_visual             
    in      TEMP, PINC               ; Lê o estado do botão
    sbrc    TEMP, 1                  ; Verifica se o botão ainda está apertado
    rjmp    dorme_loop               ; Falso alarme, volta a dormir

espera_soltar_ligar:
    in      TEMP, PINC               ; Lê o estado do botão
    sbrs    TEMP, 1                  ; Espera soltar
    rjmp    espera_soltar_ligar      

    rcall   delay_visual             

    clr     TEMP
    out     SMCR, TEMP               ; Zera SM1 e SE — sono desabilitado até próximo ciclo explícito
    
    ; --- Religa a máquina ---
    ldi     TEMP, (1<<OCIE0A)
    sts     TIMSK0, TEMP             
    ldi     TEMP, (1<<CS01) | (1<<CS00)
    out     TCCR0B, TEMP             
    
    cbr     FLAGS, (1<<0)            ; Limpa o bit 0 da FLAGS
    rjmp    loop_principal           ; Volta para o loop da main
