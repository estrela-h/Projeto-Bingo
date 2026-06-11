;==============================================================================
; BINGO ELETRÔNICO - BUGS CORRIJIDOS E CODIGO MODULARIZADO 
;==============================================================================

; Estes comandos preparam o terreno. Eles dizem ao programa para ler as 
; definições do "cérebro" do nosso projeto, que é o chip ATmega328P.
.nolist
.include "m328Pdef.inc" ; Inclui um "dicionário" com os nomes dos pinos e funções do chip
.list

;==============================================================================
; --- Mapeamento de Registradores (Os "Post-its" da CPU) ---
; Aqui damos nomes fáceis de lembrar para os espaços de memória ultrarrápidos.
;==============================================================================
.def TEMP         = r16 ; Variável temporária de uso geral (como um rascunho)
.def TEMP2        = r17 ; Outro rascunho para ajudar em contas rápidas
.def DISP_DEC     = r18 ; Guarda o desenho do número da DEZENA no display
.def DISP_UNI     = r19 ; Guarda o desenho do número da UNIDADE no display
.def MUX_STATE    = r20 ; Controla qual display está aceso (multiplexação)
.def COUNT        = r21 ; Conta quantos números já foram sorteados no total
.def RAND_L       = r22 ; Metade do número usado para gerar a aleatoriedade (sorteio)
.def RAND_H       = r23 ; Outra metade do número para o sorteio
.def FLAGS        = r24 ; Um "checklist". Cada bit (0 ou 1) avisa se algo aconteceu (ex: botão clicado)
.def DEBOUNCE_CNT = r25 ; Contador usado para ignorar ruídos físicos do botão

; Define uma constante (um valor fixo). O Bingo tradicional vai até 75.
.equ BINGO_MAX   = 75

;==============================================================================
; --- Memória de Dados (SRAM) ---
; Este é o "caderno" onde guardamos coisas que mudam durante o jogo e ocupam espaço.
;==============================================================================
.dseg
.org SRAM_START
numeros_sorteados: .byte BINGO_MAX ; Cria uma lista com 75 espaços. Se sair o 10, marcamos o espaço 10.
numero_atual:      .byte 1         ; Guarda o número que acabou de ser sorteado
tick_botao:        .byte 1         ; Variável de tempo para ajudar na leitura do botão
tick_ms:           .byte 1         ; Conta os milissegundos que passam
mux_div:           .byte 1         ; Variável para ajudar a piscar os displays na velocidade certa

;==============================================================================
; --- Memória de Programa (Flash) e Vetores de Interrupção ---
; Onde o código vive. Os "Vetores de Interrupção" são como alarmes. Se algo 
; urgente acontece (como apertar um botão), o chip para o que está fazendo e vem pra cá.
;==============================================================================
.cseg
.org 0x0000
    rjmp main          ; Quando liga a energia (Reset), pula direto para a rotina "main"

.org PCI1addr      ; 0x0008 - Alarme de Pino (Pin Change Interrupt)
    rjmp PCINT1_ISR    ; Se alguém apertou o botão, vai para a rotina de interrupção do botão

.org OC0Aaddr      ; 0x001C - Alarme do Cronômetro (Timer)
    rjmp TIMER0_COMPA_ISR ; O timer apitou? Vai para a rotina que cuida do tempo e dos displays

.org INT_VECTORS_SIZE  ; Marca onde os alarmes acabam e o código seguro começa

;==============================================================================
; --- ROTINA PRINCIPAL (Onde o jogo começa de verdade) ---
;==============================================================================
main:
    ; 1. Configura a Pilha (Stack Pointer)
    ; A Pilha é como um "marcador de página". Quando o código vai fazer uma 
    ; tarefa em outro lugar, ele anota aqui onde estava para saber voltar.
    ldi     TEMP, HIGH(RAMEND) ; Pega a parte alta do endereço final da memória
    out     SPH, TEMP          ; Salva no Stack Pointer Alto
    ldi     TEMP, LOW(RAMEND)  ; Pega a parte baixa
    out     SPL, TEMP          ; Salva no Stack Pointer Baixo

    ; 2. Prepara as variáveis e botões para o estado inicial
    ldi     FLAGS, (1<<2)      ; Inicia o "checklist" ligando um bit padrão de configuração
    clr     COUNT              ; Zera o contador de números sorteados (ninguém foi sorteado ainda)
    clr     MUX_STATE          ; Zera o controlador do display
    clr     DEBOUNCE_CNT       ; Zera o contador de ruído do botão

    ; 3. Prepara a "semente" para gerar números aleatórios
    ldi     RAND_L, 0x4F       ; Coloca um valor maluco qualquer
    ldi     RAND_H, 0xC2       ; Coloca outro valor maluco. Isso garante que o sorteio não seja viciado.

    ; 4. Liga as outras partes da máquina (configurações que estão nos outros arquivos .inc)
    rcall   init_sram          ; Limpa a memória SRAM
    rcall   init_portas        ; Define quem é entrada (botão) e quem é saída (Leds, Display)
    rcall   init_timer0        ; Liga o cronômetro que vai ficar atualizando os displays
    rcall   init_pcint         ; Avisa o chip para prestar atenção no botão do bingo

    ; 5. Desenha um traço "-" nos displays de Dezena e Unidade (0b01000000 acende só o segmento do meio)
    ldi     DISP_DEC, 0b01000000 
    ldi     DISP_UNI, 0b01000000 

    sei                        ; Autoriza todos os "alarmes" a tocarem (Habilita interrupções globais)

;==============================================================================
; --- LOOP PRINCIPAL (O jogo fica girando aqui infinitamente) ---
;==============================================================================
loop_principal:
    sbrc    FLAGS, 1                 ; O jogo acabou? (Pula a próxima linha se o bit 1 das FLAGS for 0)
    rjmp    handler_bingo_completo   ; Se for 1, vai para a festa de encerramento do bingo!
    
    sbrs    FLAGS, 0                 ; Alguém apertou o botão? (Pula a próxima linha se o bit 0 for 1)
    rjmp    loop_principal           ; Se for 0, ninguém apertou. Volta para o início do loop_principal e fica rodando.

    ; ====================================================================
    ; Se chegou aqui, é porque alguém apertou o botão! Mas precisamos 
    ; ter certeza de que não foi só um ruído elétrico ("debounce").
    ; ====================================================================
    cbr     FLAGS, (1<<0)            ; Limpa a marcação de que o botão foi clicado (já estamos cuidando disso)
    rcall   debounce_adaptativo      ; Pede para a rotina confirmar se foi um clique de verdade ou só ruído
    brcc    loop_principal           ; Se for mentira/ruído (Carry=0), ignora tudo e volta a rodar o loop!
    ; ====================================================================

    ; Se foi um clique verdadeiro, bora sortear um número!
    rcall   realizar_sorteio         ; Chama a rotina que sorteia o número
    rjmp    loop_principal           ; Depois do sorteio, volta para o começo para esperar o próximo clique

;==============================================================================
; --- FIM DE JOGO (Todos os 75 números saíram) ---
;==============================================================================
handler_bingo_completo:
    sbi     PORTB, 2                 ; Liga um LED ou Buzzer no Pino 2 da Porta B
    rcall   delay_longo              ; Espera um tempão (pisca devagar)
    cbi     PORTB, 2                 ; Desliga o LED/Buzzer
    rcall   delay_longo              ; Espera mais um pouco
    rjmp    handler_bingo_completo   ; Fica preso aqui pra sempre piscando, indicando que o bingo acabou!

;==============================================================================
; --- ROTINA QUE SORTEIA OS NÚMEROS ---
;==============================================================================
realizar_sorteio:
    cbr     FLAGS, (1<<0)            ; Garante que não tem nenhum clique pendente gravado
    cbr     FLAGS, (1<<2)            ; Limpa a flag de configuração inicial (o jogo já começou)
    sbi     PORTB, 3                 ; Liga um LED (ou som rápido) no pino 3 para dar emoção ao clique!
    
    cpi     COUNT, BINGO_MAX         ; Compara: O total de sorteados já atingiu 75?
    brsh    sorteio_esgotado         ; Se sim (maior ou igual), pula lá pro final (sorteio esgotado)
    
    rcall   busca_numero             ; Vai em outro arquivo buscar um número aleatório inédito
    rcall   atualiza_display         ; Pega esse número e desenha nos displays de 7 segmentos
    
    cpi     COUNT, BINGO_MAX         ; Compara de novo: Chegou em 75 números com esse último sorteio?
    brlo    sorteio_ok               ; Se for menor que 75, tudo ok, pula pro final da rotina
    sbr     FLAGS, (1<<1)            ; Se chegou em 75, anota na FLAGS (Bit 1) que o Bingo está completo!

sorteio_ok:
    rcall   delay_visual             ; Dá um tempinho só para o LED/som do sorteio aparecer
    cbi     PORTB, 3                 ; Desliga o LED/som que ligamos lá no começo desta rotina
    ret                              ; Retorna para onde fomos chamados (lá no loop principal)

sorteio_esgotado:
    sbr     FLAGS, (1<<1)            ; Anota na FLAGS (Bit 1) que o Bingo está completo
    rcall   delay_visual             ; Espera um tempinho
    cbi     PORTB, 3                 ; Desliga o LED
    ret                              ; Retorna

;==============================================================================
; --- INCLUSÃO DOS OUTROS ARQUIVOS (Módulos do Sistema) ---
; Em vez de fazer um código gigantesco, dividimos as tarefas em outros arquivos.
;==============================================================================
.include "hardware.inc" ; Arquivo que cuida dos botões, pinos e temporizadores
.include "sorteio.inc"  ; Arquivo focado em gerar números aleatórios e checar se já saíram
.include "display.inc"  ; Arquivo focado em acender as luzes certas para formar os números
.include "delays.inc"   ; Arquivo focado em fazer o processador "perder tempo" quando precisa (pausas)
