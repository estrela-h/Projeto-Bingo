;==============================================================================
; BINGO ELETRÔNICO - ARQUIVO PRINCIPAL (main.asm)
;==============================================================================

; Estes comandos preparam o terreno. Eles dizem ao programa para ler as 
; definições do "cérebro" do nosso projeto, que é o chip ATmega328P,
; além de puxar todas as variáveis e memórias do nosso dicionário.
.include "varglobais.inc"

;==============================================================================
; --- Memória de Programa (Flash) e Vetores de Interrupção ---
; Os "Vetores de Interrupção" são como alarmes. Se algo urgente acontece (como apertar
; um botão), o chip para o que está fazendo e vem pra cá.
;==============================================================================
.cseg
.org 0x0000
    rjmp main          ; Quando liga a energia (Reset), pula direto para a rotina "main"

.org PCI1addr      ; 0x0008 - Alarme de Pino (Pin Change Interrupt)
    rjmp PCINT1_ISR    ; Se alguém apertou o botão, vai para a rotina de interrupção do botão

.org OC0Aaddr      ; 0x001C - Alarme do Cronômetro (Timer)
    rjmp TIMER0_COMPA_ISR ; Se o timer apitou vai para a rotina que cuida do tempo e dos displays

.org INT_VECTORS_SIZE  ; Marca onde os alarmes acabam e o código seguro começa

;==============================================================================
; --- ROTINA PRINCIPAL (Onde o jogo começa de verdade) ---
;==============================================================================
main:
    ; 1. Configura a Pilha (Stack Pointer)
    ldi     TEMP, HIGH(RAMEND)
    out     SPH, TEMP
    ldi     TEMP, LOW(RAMEND)
    out     SPL, TEMP

    ; 2. Prepara as variáveis e botões para o estado inicial
    ldi     FLAGS, (1<<2)
    clr     COUNT
    clr     MUX_STATE
    clr     DEBOUNCE_CNT

    ; 3. Configuração para gerar números aleatórios
    ldi     RAND_L, 0x4F
    ldi     RAND_H, 0xC2

    ; 4. Liga as outras partes da máquina
    rcall   init_sram         ; Limpa a memória SRAM (fundamental para o reset)
    rcall   init_portas
    rcall   init_timer0
    rcall   init_pcint

    ; 5. Desenha o traço inicial "-"
    ldi     DISP_DEC, 0b01000000
    ldi     DISP_UNI, 0b01000000

    sei                       ; Autoriza interrupções

;==============================================================================
; --- LOOP PRINCIPAL (O jogo fica girando aqui infinitamente) ---
;==============================================================================
loop_principal:
    in      TEMP, PINC
    sbrs    TEMP, 1                  ; Pula a próxima linha se o pino 1 (A1) for 1 (Solto)
    rjmp    desliga_sistema          ; Vai para a rotina de desligar se for 0 (Apertado)

    sbrc    FLAGS, 1                 ; O jogo acabou? (Pula a próxima linha se o bit 1 da FLAGS for 0)
    rjmp    handler_bingo_completo   ; Se sim, mostra "FIM"

    sbrs    FLAGS, 0                 ; Alguém apertou o botão? (Pula a próxima linha se o bit 0 for 1)
    rjmp    loop_principal           ; Se for 0, ninguém apertou. Volta para o início do loop_principal e fica rodando.

    ; ====================================================================
    ; Se chegou aqui, é porque alguém apertou o botão. Mas precisamos
    ; ter certeza de que não foi só um ruído elétrico ("debounce").
    ; ====================================================================
    cbr     FLAGS, (1<<0)            ; Limpa a marcação de que o botão foi clicado (já estamos cuidando disso)
    rcall   debounce_adaptativo      ; Pede para a rotina confirmar se foi um clique de verdade ou só ruído
    brcc    loop_principal           ; Se foi um ruído (Carry=0), ignora tudo e volta a rodar o loop
    ; ====================================================================

    ; Se foi um clique verdadeiro, começa a sortear um número
    rcall   realizar_sorteio         ; Chama a rotina que sorteia o número
    rjmp    loop_principal           ; Depois do sorteio, volta para o começo para esperar o próximo clique

;==============================================================================
; --- INCLUSÃO DOS OUTROS ARQUIVOS (Módulos do Sistema) ---
; Em vez de fazer um código gigantesco, dividimos as tarefas em outros arquivos.
;==============================================================================
.include "hardware.asm" ; Arquivo que cuida dos botões, pinos e temporizadores
.include "sorteio.asm"  ; Arquivo focado em gerar números aleatórios e checar se já saíram
.include "display.asm"  ; Arquivo focado em acender as luzes certas para formar os números
.include "delays.asm"   ; Arquivo focado em fazer o processador "perder tempo" quando precisa (pausas)
.include "power.asm"    ; Arquivo focado no controle do botão de ligar, desligar
.include "regras.asm"   ; Arquivo focado na lógica de como funciona o sorteio
