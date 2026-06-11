;==============================================================================
; BINGO ELETRÔNICO - ATmega328P (Assembly AVRA) - VERSÃO FINAL
;==============================================================================
; Lógica de Multiplexação Ativa em HIGH (Compatível com Transistores NPN)
; Montador: avra
; Compilação: avra -fI bingo_main.asm
;==============================================================================

; Facilitações 
.include "m328Pdef.inc"

;==============================================================================
; DEFINIÇÕES DE REGISTRADORES
;==============================================================================
.def TEMP        = r16
.def TEMP2       = r17
.def DISP_DEC    = r18
.def DISP_UNI    = r19
.def MUX_STATE   = r20
.def COUNT       = r21
.def RAND_L      = r22
.def RAND_H      = r23
.def FLAGS       = r24
.def DEBOUNCE_CNT= r25

;==============================================================================
; CONSTANTES
;==============================================================================
.equ BINGO_MAX     = 75
.equ DEBOUNCE_MS   = 20

; Padrões de segmentos (display 7 segmentos catodo comum)
.equ SEG_0   = 0b00111111
.equ SEG_1   = 0b00000110
.equ SEG_2   = 0b01011011
.equ SEG_3   = 0b01001111
.equ SEG_4   = 0b01100110
.equ SEG_5   = 0b01101101
.equ SEG_6   = 0b01111101
.equ SEG_7   = 0b00000111
.equ SEG_8   = 0b01111111
.equ SEG_9   = 0b01101111
.equ SEG_DASH = 0b01000000
.equ SEG_OFF  = 0b00000000

;==============================================================================
; VETORES DE INTERRUPÇÃO
;==============================================================================
.cseg
.org 0x0000
    rjmp main               ; RESET
.org 0x0002
    reti                    ; INT0
.org 0x0004
    reti                    ; INT1
.org 0x0006
    reti                    ; PCINT0
.org 0x0008
    reti                    ; PCINT1 (vamos usar o vetor específico mais adiante)
.org 0x000A
    reti                    ; PCINT2
.org 0x000C
    reti                    ; WDT
.org 0x000E
    reti                    ; TIMER2_COMPA
.org 0x0010
    reti                    ; TIMER2_COMPB
.org 0x0012
    reti                    ; TIMER2_OVF
.org 0x0014
    reti                    ; TIMER1_CAPT
.org 0x0016
    reti                    ; TIMER1_COMPA
.org 0x0018
    rjmp TIMER0_COMPA_vect  ; TIMER0_COMPA
.org 0x001A
    reti                    ; TIMER0_COMPB
.org 0x001C
    reti                    ; TIMER0_OVF
.org 0x001E
    reti                    ; SPI_STC
.org 0x0020
    reti                    ; USART_RX
.org 0x0022
    reti                    ; USART_UDRE
.org 0x0024
    reti                    ; USART_TX
.org 0x0026
    reti                    ; ADC
.org 0x0028
    rjmp PCINT1_vect        ; PCINT1 (vetor 20)
.org 0x002A
    reti                    ; ... restante
.org 0x002C
    reti
.org 0x002E
    reti
.org 0x0030
    reti
.org 0x0032
    reti
.org 0x0034
    reti
;==============================================================================

;==============================================================================
; TABELA DE SEGMENTOS (flash)
;==============================================================================
tabela_seg:
    .db SEG_0, SEG_1, SEG_2, SEG_3, SEG_4
    .db SEG_5, SEG_6, SEG_7, SEG_8, SEG_9

;==============================================================================
; SEGMENTO DE DADOS (RAM)
;==============================================================================
.dseg
.org 0x0100               ; início da RAM interna (ATmega328P)

numeros_sorteados: .byte BINGO_MAX   ; 75 bytes
numero_atual:      .byte 1
tick_ms:           .byte 1
tick_botao:        .byte 1
mux_div:           .byte 1

;==============================================================================
; CÓDIGO PRINCIPAL
;==============================================================================
.cseg
main:
    ; Inicializa pilha
    ldi TEMP, high(RAMEND)
    out SPH, TEMP
    ldi TEMP, low(RAMEND)
    out SPL, TEMP

    ; Inicializa flags e contadores
    ldi FLAGS, (1<<2)
    clr COUNT
    clr MUX_STATE
    clr DEBOUNCE_CNT

    ; Semente inicial do LFSR
    ldi RAND_L, 0x4F
    ldi RAND_H, 0xC2

    rcall init_sram
    rcall init_portas
    rcall init_timer0
    rcall init_pcint

    ldi DISP_DEC, SEG_DASH
    ldi DISP_UNI, SEG_DASH

    sei                     ; habilita interrupções

loop_principal:
    sbrc FLAGS, 1
    rjmp handler_bingo_completo
    sbrs FLAGS, 0
    rjmp loop_principal

    lds TEMP, tick_ms
    lds TEMP2, tick_botao
    sub TEMP, TEMP2
    cpi TEMP, DEBOUNCE_MS
    brlo loop_principal

    in TEMP, PINC
    sbrc TEMP, 0
    rjmp sorteio_cancelado

    rcall realizar_sorteio
    rjmp loop_principal

sorteio_cancelado:
    cbr FLAGS, (1<<0)
    rjmp loop_principal

handler_bingo_completo:
    sbi PORTB, 2
    rcall delay_longo
    cbi PORTB, 2
    rcall delay_longo
    rjmp handler_bingo_completo

;==============================================================================
; SORTEIO
;==============================================================================
realizar_sorteio:
    cbr FLAGS, (1<<0)
    cbr FLAGS, (1<<2)
    sbi PORTB, 3

    cpi COUNT, BINGO_MAX
    brsh sorteio_esgotado

busca_numero:
    rcall lfsr_step
    mov TEMP, RAND_L
    rcall mod75
    inc TEMP                ; número entre 1 e 75

    ; Verifica se já foi sorteado
    ldi ZL, low(numeros_sorteados)
    ldi ZH, high(numeros_sorteados)
    mov TEMP2, TEMP
    dec TEMP2
    add ZL, TEMP2
    adc ZH, r26
    ld r26, Z
    tst r26
    brne busca_numero

    ; Marca como sorteado
    ldi r26, 1
    st Z, r26
    inc COUNT
    sts numero_atual, TEMP
    rcall atualiza_display

    cpi COUNT, BINGO_MAX
    brlo sorteio_ok
    sbr FLAGS, (1<<1)       ; Bingo completo

sorteio_ok:
    rcall delay_visual
    cbi PORTB, 3
    ret

sorteio_esgotado:
    sbr FLAGS, (1<<1)
    rcall delay_visual
    cbi PORTB, 3
    ret

;==============================================================================
; ATUALIZA DISPLAY
;==============================================================================
atualiza_display:
    push r27
    in r27, SREG
    push r27
    cli

    lds r27, numero_atual
    clr DISP_DEC

separa_dezena:
    cpi r27, 10
    brlo separa_fim
    subi r27, 10
    inc DISP_DEC
    rjmp separa_dezena

separa_fim:
    ; unidade
    ldi ZL, low(tabela_seg)
    ldi ZH, high(tabela_seg)
    add ZL, r27
    clr r26
    adc ZH, r26
    lpm DISP_UNI, Z

    ; dezena
    ldi ZL, low(tabela_seg)
    ldi ZH, high(tabela_seg)
    add ZL, DISP_DEC
    clr r26
    adc ZH, r26
    lpm DISP_DEC, Z

    lds r27, numero_atual
    cpi r27, 10
    brsh display_ok
    ldi DISP_DEC, SEG_OFF

display_ok:
    pop r27
    out SREG, r27
    pop r27
    ret

;==============================================================================
; MÓDULO 75
;==============================================================================
mod75:
    cpi TEMP, 75
    brlo mod75_ret
    subi TEMP, 75
    rjmp mod75
mod75_ret:
    ret

;==============================================================================
; LFSR 16 bits (x^16 + x^14 + x^13 + x^11 + 1)
;==============================================================================
lfsr_step:
    mov TEMP, RAND_L
    andi TEMP, 0x01
    lsr RAND_H
    ror RAND_L
    tst TEMP
    breq lfsr_ret
    ldi TEMP, 0xB4
    eor RAND_H, TEMP
lfsr_ret:
    ret

;==============================================================================
; INICIALIZA RAM (ZERA ESTRUTURAS)
;==============================================================================
init_sram:
    ldi ZL, low(numeros_sorteados)
    ldi ZH, high(numeros_sorteados)
    ldi TEMP, BINGO_MAX
    clr TEMP2
init_sram_loop:
    st Z+, TEMP2
    dec TEMP
    brne init_sram_loop
    sts numero_atual, TEMP2
    sts tick_ms, TEMP2
    sts tick_botao, TEMP2
    sts mux_div, TEMP2
    ret

;==============================================================================
; PORTA (saída segmentos em D, transistores em B0/B1, led bingo em B2, led sorteio em B3)
;==============================================================================
init_portas:
    ; PORTD = segmentos (saída)
    ldi TEMP, 0xFF
    out DDRD, TEMP
    clr TEMP
    out PORTD, TEMP

    ; PORTB: PB0, PB1, PB2, PB3 como saída (transistores e leds)
    ldi TEMP, 0b00001111
    out DDRB, TEMP
    clr TEMP
    out PORTB, TEMP

    ; PORTC: PC0 como entrada com pull-up
    clr TEMP
    out DDRC, TEMP
    ldi TEMP, 0b00000001
    out PORTC, TEMP
    ret

;==============================================================================
; TIMER0 CTC (1 kHz)
;==============================================================================
init_timer0:
    ldi TEMP, (1<<WGM01)
    out TCCR0A, TEMP
    ldi TEMP, (1<<CS01) | (1<<CS00)   ; prescaler 64
    out TCCR0B, TEMP
    ldi TEMP, 249                      ; 16MHz / 64 / 250 = 1000 Hz
    out OCR0A, TEMP
    ldi TEMP, (1<<OCIE0A)
    sts TIMSK0, TEMP
    ret

;==============================================================================
; INTERRUPÇÃO PCINT1 (botão no PC0)
;==============================================================================
init_pcint:
    lds TEMP, PCICR
    ori TEMP, (1<<PCIE1)
    sts PCICR, TEMP
    ldi TEMP, (1<<PCINT8)
    sts PCMSK1, TEMP
    ret

;==============================================================================
; ISR TIMER0_COMPA - MULTIPLEXAÇÃO (ATIVA HIGH PARA TRANSISTORES NPN)
;==============================================================================
TIMER0_COMPA_vect:
    push TEMP
    in TEMP, SREG
    push TEMP
    push TEMP2

    ; Contador de milissegundos
    lds TEMP, tick_ms
    inc TEMP
    sts tick_ms, TEMP

    ; Atualiza LFSR (aleatoriedade adicional)
    inc RAND_L
    brne isr_mux_check
    ldi RAND_L, 0x01

isr_mux_check:
    lds TEMP, mux_div
    inc TEMP
    cpi TEMP, 8
    brlo isr_mux_skip
    clr TEMP
    sts mux_div, TEMP
    rjmp isr_mux_do

isr_mux_skip:
    sts mux_div, TEMP
    rjmp isr_mux_fim

isr_mux_do:
    ; Desliga ambos os transistores
    in TEMP2, PORTB
    andi TEMP2, ~((1<<0) | (1<<1))
    out PORTB, TEMP2

    ; Limpa segmentos
    clr TEMP2
    out PORTD, TEMP2

    tst MUX_STATE
    brne isr_mux_unidade

isr_mux_dezena:
    out PORTD, DISP_DEC
    in TEMP2, PORTB
    ori TEMP2, (1<<0)      ; PB0 = HIGH (liga transistor dezena)
    andi TEMP2, ~(1<<1)    ; PB1 = LOW
    out PORTB, TEMP2
    ldi MUX_STATE, 1
    rjmp isr_mux_fim

isr_mux_unidade:
    out PORTD, DISP_UNI
    in TEMP2, PORTB
    ori TEMP2, (1<<1)      ; PB1 = HIGH (liga transistor unidade)
    andi TEMP2, ~(1<<0)    ; PB0 = LOW
    out PORTB, TEMP2
    clr MUX_STATE

isr_mux_fim:
    pop TEMP2
    pop TEMP
    out SREG, TEMP
    pop TEMP
    reti

;==============================================================================
; ISR PCINT1 - DETECÇÃO DO BOTÃO (SORTEIO)
;==============================================================================
PCINT1_vect:
    push TEMP
    in TEMP, SREG
    push TEMP
    lds TEMP, tick_ms
    sts tick_botao, TEMP
    sbr FLAGS, (1<<0)
    pop TEMP
    out SREG, TEMP
    pop TEMP
    reti

;==============================================================================
; DELAYS (longo e visual)
;==============================================================================
delay_longo:
    push r26
    push r27
    push r28
    ldi r26, 200
dly_out:
    ldi r27, 200
dly_mid:
    ldi r28, 130
dly_in:
    nop
    dec r28
    brne dly_in
    dec r27
    brne dly_mid
    dec r26
    brne dly_out
    pop r28
    pop r27
    pop r26
    ret

delay_visual:
    push r26
    push r27
    ldi r26, 80
dly_v1:
    ldi r27, 250
dly_v2:
    nop
    dec r27
    brne dly_v2
    dec r26
    brne dly_v1
    pop r27
    pop r26
    ret
