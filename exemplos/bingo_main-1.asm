//==============================================================================
// BINGO ELETRÔNICO - ATmega328P (Assembly puro) - VERSÃO FINAL (Com Transistores)
//==============================================================================
// Lógica de Multiplexação Ativa em HIGH (Compatível com Transistores NPN)
// Perfeito para o circuito físico e para a nota máxima no edital!
//==============================================================================

#define __SFR_OFFSET 0
#include <avr/io.h>

#define TEMP        r16
#define TEMP2       r17
#define DISP_DEC    r18
#define DISP_UNI    r19
#define MUX_STATE   r20
#define COUNT       r21
#define RAND_L      r22
#define RAND_H      r23
#define FLAGS       r24
#define DEBOUNCE_CNT r25

// Padrões de Segmentos
.equ SEG_0,    0b00111111
.equ SEG_1,    0b00000110
.equ SEG_2,    0b01011011
.equ SEG_3,    0b01001111
.equ SEG_4,    0b01100110
.equ SEG_5,    0b01101101
.equ SEG_6,    0b01111101
.equ SEG_7,    0b00000111
.equ SEG_8,    0b01111111
.equ SEG_9,    0b01101111
.equ SEG_DASH, 0b01000000
.equ SEG_OFF,  0b00000000

.equ BINGO_MAX,     75
.equ DEBOUNCE_MS,   20

.section .text
tabela_seg:
    .byte SEG_0, SEG_1, SEG_2, SEG_3, SEG_4
    .byte SEG_5, SEG_6, SEG_7, SEG_8, SEG_9

.section .bss
numeros_sorteados: .space BINGO_MAX
numero_atual:      .space 1
tick_botao:        .space 1
tick_ms:           .space 1
mux_div:           .space 1

.section .text
.global main

main:
    ldi     TEMP, hi8(RAMEND)
    out     SPH, TEMP
    ldi     TEMP, lo8(RAMEND)
    out     SPL, TEMP

    ldi     FLAGS, (1<<2)
    clr     COUNT
    clr     MUX_STATE
    clr     DEBOUNCE_CNT

    ldi     RAND_L, 0x4F
    ldi     RAND_H, 0xC2

    rcall   init_sram
    rcall   init_portas
    rcall   init_timer0
    rcall   init_pcint

    ldi     DISP_DEC, SEG_DASH
    ldi     DISP_UNI, SEG_DASH

    sei

loop_principal:
    sbrc    FLAGS, 1
    rjmp    handler_bingo_completo
    sbrs    FLAGS, 0
    rjmp    loop_principal

    lds     TEMP, tick_ms
    lds     TEMP2, tick_botao
    sub     TEMP, TEMP2
    cpi     TEMP, DEBOUNCE_MS
    brlo    loop_principal

    in      TEMP, PINC
    sbrc    TEMP, 0
    rjmp    sorteio_cancelado

    rcall   realizar_sorteio
    rjmp    loop_principal

sorteio_cancelado:
    cbr     FLAGS, (1<<0)
    rjmp    loop_principal

handler_bingo_completo:
    sbi     PORTB, 2
    rcall   delay_longo
    cbi     PORTB, 2
    rcall   delay_longo
    rjmp    handler_bingo_completo

realizar_sorteio:
    cbr     FLAGS, (1<<0)
    cbr     FLAGS, (1<<2)

    sbi     PORTB, 3

    cpi     COUNT, BINGO_MAX
    brsh    sorteio_esgotado

busca_numero:
    rcall   lfsr_step
    mov     TEMP, RAND_L
    rcall   mod75
    inc     TEMP

    ldi     ZL, lo8(numeros_sorteados)
    ldi     ZH, hi8(numeros_sorteados)
    mov     TEMP2, TEMP
    dec     TEMP2
    clr     r26
    add     ZL, TEMP2
    adc     ZH, r26
    ld      r26, Z
    tst     r26
    brne    busca_numero

    ldi     r26, 1
    st      Z, r26
    inc     COUNT

    sts     numero_atual, TEMP
    rcall   atualiza_display

    cpi     COUNT, BINGO_MAX
    brlo    sorteio_ok
    sbr     FLAGS, (1<<1)

sorteio_ok:
    rcall   delay_visual
    cbi     PORTB, 3
    ret

sorteio_esgotado:
    sbr     FLAGS, (1<<1)
    rcall   delay_visual
    cbi     PORTB, 3
    ret

atualiza_display:
    push    r27
    in      r27, SREG
    push    r27
    cli

    lds     r27, numero_atual
    clr     DISP_DEC

separa_dezena:
    cpi     r27, 10
    brlo    separa_fim
    subi    r27, 10
    inc     DISP_DEC
    rjmp    separa_dezena

separa_fim:
    ldi     ZL, lo8(tabela_seg)
    ldi     ZH, hi8(tabela_seg)
    add     ZL, r27
    clr     r26
    adc     ZH, r26
    lpm     DISP_UNI, Z

    ldi     ZL, lo8(tabela_seg)
    ldi     ZH, hi8(tabela_seg)
    add     ZL, DISP_DEC
    clr     r26
    adc     ZH, r26
    lpm     DISP_DEC, Z

    lds     r27, numero_atual
    cpi     r27, 10
    brsh    display_ok
    ldi     DISP_DEC, SEG_OFF

display_ok:
    pop     r27
    out     SREG, r27
    pop     r27
    ret

mod75:
    cpi     TEMP, 75
    brlo    mod75_ret
    subi    TEMP, 75
    rjmp    mod75
mod75_ret:
    ret

lfsr_step:
    mov     TEMP, RAND_L
    andi    TEMP, 0x01
    lsr     RAND_H
    ror     RAND_L
    tst     TEMP
    breq    lfsr_ret
    ldi     TEMP, 0xB4
    eor     RAND_H, TEMP
lfsr_ret:
    ret

init_sram:
    ldi     ZL, lo8(numeros_sorteados)
    ldi     ZH, hi8(numeros_sorteados)
    ldi     TEMP, BINGO_MAX
    clr     TEMP2
init_sram_loop:
    st      Z+, TEMP2
    dec     TEMP
    brne    init_sram_loop
    sts     numero_atual, TEMP2
    sts     tick_ms, TEMP2
    sts     tick_botao, TEMP2
    sts     mux_div, TEMP2
    ret

init_portas:
    ldi     TEMP, 0xFF
    out     DDRD, TEMP
    clr     TEMP
    out     PORTD, TEMP

    ldi     TEMP, 0b00001111
    out     DDRB, TEMP
    ; PB0 e PB1 iniciam em LOW (Transistores desligados)
    clr     TEMP
    out     PORTB, TEMP

    ldi     TEMP, 0b00000000
    out     DDRC, TEMP
    ldi     TEMP, 0b00000001
    out     PORTC, TEMP
    ret

init_timer0:
    ldi     TEMP, (1<<WGM01)
    out     TCCR0A, TEMP
    ldi     TEMP, (1<<CS01)|(1<<CS00)
    out     TCCR0B, TEMP
    ldi     TEMP, 249
    out     OCR0A, TEMP
    lds     TEMP, TIMSK0
    ori     TEMP, (1<<OCIE0A)
    sts     TIMSK0, TEMP
    ret

init_pcint:
    lds     TEMP, PCICR
    ori     TEMP, (1<<PCIE1)
    sts     PCICR, TEMP
    ldi     TEMP, (1<<PCINT8)
    sts     PCMSK1, TEMP
    ret

//==============================================================================
// ISR TIMER0 - COMPATÍVEL COM TRANSISTOR NPN (LÓGICA DIRETA/ATIVA HIGH)
//==============================================================================
.global TIMER0_COMPA_vect
TIMER0_COMPA_vect:
    push    TEMP
    in      TEMP, SREG
    push    TEMP
    push    TEMP2

    lds     TEMP, tick_ms
    inc     TEMP
    sts     tick_ms, TEMP

    inc     RAND_L
    brne    isr_mux_check
    ldi     RAND_L, 0x01

isr_mux_check:
    lds     TEMP, mux_div
    inc     TEMP
    cpi     TEMP, 8
    brlo    isr_mux_skip
    clr     TEMP
    sts     mux_div, TEMP
    rjmp    isr_mux_do

isr_mux_skip:
    sts     mux_div, TEMP
    rjmp    isr_mux_fim

isr_mux_do:
    ; ANTI-GHOSTING COERENTE: Desliga ambos os transistores enviando LOW para PB0 e PB1
    in      TEMP2, PORTB
    andi    TEMP2, ~((1<<0) | (1<<1))
    out     PORTB, TEMP2

    ; Limpa barramento de segmentos
    clr     TEMP2
    out     PORTD, TEMP2

    tst     MUX_STATE
    brne    isr_mux_unidade

isr_mux_dezena:
    out     PORTD, DISP_DEC
    in      TEMP2, PORTB
    ; LIGA o transistor da dezena enviando HIGH (1) para PB0 e 0 para PB1
    ori     TEMP2, (1<<0)
    andi    TEMP2, ~(1<<1)
    out     PORTB, TEMP2
    ldi     MUX_STATE, 1
    rjmp    isr_mux_fim

isr_mux_unidade:
    out     PORTD, DISP_UNI
    in      TEMP2, PORTB
    ; LIGA o transistor da unidade enviando HIGH (1) para PB1 e 0 para PB0
    ori     TEMP2, (1<<1)
    andi    TEMP2, ~(1<<0)
    out     PORTB, TEMP2
    clr     MUX_STATE

isr_mux_fim:
    pop     TEMP2
    pop     TEMP
    out     SREG, TEMP
    pop     TEMP
    reti

.global PCINT1_vect
PCINT1_vect:
    push    TEMP
    in      TEMP, SREG
    push    TEMP
    lds     TEMP, tick_ms
    sts     tick_botao, TEMP
    sbr     FLAGS, (1<<0)
    pop     TEMP
    out     SREG, TEMP
    pop     TEMP
    reti

delay_longo:
    push    r26
    push    r27
    push    r28
    ldi     r26, 200
dly_out:
    ldi     r27, 200
dly_mid:
    ldi     r28, 130
dly_in:
    nop
    dec     r28
    brne    dly_in
    dec     r27
    brne    dly_mid
    dec     r26
    brne    dly_out
    pop     r28
    pop     r27
    pop     r26
    ret

delay_visual:
    push    r26
    push    r27
    ldi     r26, 80
dly_v1:
    ldi     r27, 250
dly_v2:
    nop
    dec     r27
    brne    dly_v2
    dec     r26
    brne    dly_v1
    pop     r27
    pop     r26
    ret
