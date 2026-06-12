; ==============================================================================
; --- MÓDULO: varglobais.inc ---
; Responsabilidade: Dicionário do sistema. Contém definições de pinos,
;                   variáveis globais (registradores) e memória SRAM.
; ==============================================================================
.nolist
.include "m328Pdef.inc" ; Inclui um "dicionário" com os nomes dos pinos e funções do chip
.list

; ==============================================================================
;               --- Mapeamento de Registradores ---
; Aqui damos nomes fáceis de lembrar para os espaços de memória.
; ==============================================================================
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

; Define uma constante. O Bingo tradicional vai até 75.
.equ BINGO_MAX   = 75; se quiser definir o Bingo indo até outro número basta alterar aqui( sendo de 1 a 99)

; ==============================================================================
; --- Memória de Dados (SRAM) ---
; Este é o local onde guardamos coisas que mudam durante o jogo e ocupam espaço.
; ==============================================================================
.dseg
.org SRAM_START
numeros_sorteados: .byte BINGO_MAX ; Cria uma lista com o tamanho de BINGO_MAX espaços. Se sair o 10, marcamos o espaço 10.
numero_atual:      .byte 1         ; Guarda o número que acabou de ser sorteado
tick_botao:        .byte 1         ; Variável de tempo para ajudar na leitura do botão
tick_ms:           .byte 1         ; Conta os milissegundos que passam
mux_div:           .byte 1         ; Variável para ajudar a piscar os displays na velocidade certa
