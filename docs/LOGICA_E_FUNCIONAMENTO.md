<h2>Lógica do Projeto</h2>
<div>
O projeto está dividido em módulos, cada um com uma função específica, em Assembly e o circuito digital 
do projeto físico organizados na pasta 
<a href="https://github.com/estrela-h/Projeto-Bingo/tree/main/src">src</a> e 
<a href="https://github.com/estrela-h/Projeto-Bingo/tree/main/circuitos">circuitos</a>.
</div>

<h3>Módulos</h3>
<div>
<p>
<strong>>>Delays</strong><br>
Neste primeiro módulo, estão definidas as rotinas de atraso para criar pausas
visuais e filtrar os ruídos do botão físico.
</p>

<p>
<strong>>>Display</strong><br>
Aqui, será resgatado o número sorteado para separar a dezena e a unidade,
determinar quais LEDs do display vão acender para formar esse desenho e preparar
a exibição.
</p>

<p>
<strong>>>Hardware</strong><br>
Este arquivo configura os pinos físicos, prepara os cronômetros e diz quando um
alarme (Interrupção) tocar.
</p>

<p>
<strong>>>Power</strong><br>
Já neste, é realizado o controle do botão de energia para ligar, desligar e resetar
o Bingo.
</p>

<p>
<strong>>>Regras</strong><br>
Este módulo está responsável por controlar o fluxo do jogo, realizar o sorteio,
verificar se todos os números já foram sorteados e exibir uma mensagem de fim.
</p>

<p>
<strong>>>Sorteio</strong><br>
Gera números aleatórios, garante que estes não passem de 75, verifica se o
número que foi gerado não foi sorteado ainda e quebra de previsibilidade da
sequência.
</p>

<p>
<strong>>>Variáveis Globais</strong><br>
Este é o dicionário do sistema, onde contém a definição dos pinos, dos registradores
e da memória SRAM.
</p>

<p>
<Strong>>>Main</Strong><br>
Esse é o arquivo principal, o qual contém o algoritmo que conecta os módulos, configura
a memória inicial e que junta a lógica do botão de ligar e desligar com o sorteio.
</p>
</div>

<h3>Funcionamento Geral do Circuito</h3>
<div>
<p>O funcionamento geral do programa consiste em reservar um vetor conforme o tamanho 
desejado, o qual por padrão é 75, mas pode ser alterado no código por meio da diretiva
de montagem BINGO_MAX, a qual se encontra no módulo varglobais.inc.</p>
<p>
Dado isso, quando o Arduino é ligado ele carrega ambos os displays com o sinal de "-", 
simbolizando que o bingo começou. Além disso, o circuito tem dois botões, sendo um responsável apenas
por sortear novos números e o outro por ligar, desligar e reiniciar. Esse último
funciona da seguinte forma, quando ele é pressionado rapidamente ele desliga os displays
e para de ouvir as interrupções do botão de sortear, ou seja, ele entra em power down,
salvando o estado atual do bingo, e para voltar a funcionar basta ser pressionado
rapidamente que ele volta a estar ligado.</p>
Enquanto isso, a função de reiniciar zera o sorteio e é ativada unicamente quando esse
botão é pressionado por um intervalo em torno de 4s ou mais. Além disso, quando o sorteio é 
finalizado os displays passam a imprimir a palavra "FIM" 3 vezes, sendo que durante esse processo,
nenhum dos botões conseguem interromper. Após o ciclo, o Bingo é reiniciado e outra partida pode ser jogada.
</div>

<h3>Noção Intuitiva da Lógica do Código</h3>
<div>
<p>
<b>1. Vetor do Sorteio</b><br>
    Para o sorteio funcionar, o código reserva um vetor na memória SRAM com o tamanho definido pela diretiva 
BINGO_MAX. Assim que um número é sorteado, esse vetor é acessado para verificar o status daquele número.<br>
    Por exemplo, se for sorteado o número 15, primeiro é analisado se ele já saiu. Caso já tenha sido sorteado,
o sistema busca outro número e tenta novamente. Caso não, a posição 15 do vetor (que também pode ser interpretada
como posição 14, se considerarmos que a primeira posição é a 0) é marcada com o valor 1.
</p>

<p>
<b>2. Algoritmo do Sorteio</b><br>
    A geração de números é feita pela técnica pseudoaleatória LFSR (Linear-Feedback Shift Register), utilizando um 
número inicial carregado como constante no arquivo main.asm. Enquanto o jogador não aperta o botão de sortear, 
essa constante é incrementada continuamente. Isso garante uma sensação de aleatoriedade, pois o jogador não tem
a precisão necessária para pressionar o botão no milissegundo exato para obter um número específico. Entretanto,
o sistema ainda é pseudoaleatório, pois alguém com o controle absoluto das variáveis de tempo e hardware conseguiria 
prever o resultado.<br>
    Quando o botão é pressionado, é chamada a rotina de busca de números. Ela aciona a sub-rotina LFSR, que executa 
diversas operações binárias para aumentar a imprevisibilidade, começando pelo deslocamento de bits para a direita e 
aplicando portas lógicas nas partes alta e baixa do número. Por fim, é realizada uma operação de módulo para garantir 
que o resultado caia no intervalo válido do jogo. Se o número gerado já tiver saído, a rotina é repetida até encontrar
um número não sorteado.
</p>

<b>3. Botões e Interrupções</b><br>
Para a implementação dos botões foi escolhido a configuração de pull-up, o que reduz o uso de resistores, já que
aproveita os próprios resistores internos do Arduino. Assim, quando um botão é pressionado ele gera uma interrupção,
sendo que durante o fim do jogo as interrupções não são ouvidas e após as mensagens de "FIM" o jogo reinicia sozinho.
<p>
    <strong>- Botão de Sorteio:</strong> Este botão está conectado na porta A0 do circuito, sendo que o código dele 
possui delays antirruídos, o que o permite ser pressionado múltiplas vezes em sequência sem que ele deixe de funcionar 
corretamente.
</p>
<p>
    <strong>- Botão de Energia (Power/Reset):</strong> Conectado na porta A1 e controlado pelo arquivo power.asm, possui 
funções dinâmicas diferente do outro botão. Enquanto o sistema estiver com os displays acesos, ele avalia o tempo de pressão: 
um toque rápido o coloca em power down, e após isso passa a ignorar as interrupções do sorteio, além de salvar o estado
atual do sorteio, podendo ser ligado com outro toque rápido. Já se for mantido pressionado por cerca de 4 a 5 segundos, 
ou um tempo maior que esse, o botão força o reinício do jogo, o que no código é um rjmp na label main que inicializa as 
configurações iniciais.
</p>

<p>
<b>4. Rotinas de Delay</b><br>
    A rotina de delays contempla tanto delays para lidar com o ruído, tanto quanto para controlar o ritmo das exibições no
display. A construção de todas as sub-rotinas de delays do delays.asm foram feitas utilizando loops que apenas fazem 
decrementações, ou seja, apenas queimam alguns clocks. Entretanto, há algumas sub-rotinas que realmente utilizam do relógio
-interno do microcontrolador, elas estão presentes em hardware.asm, mas essas sub-rotinas não são para o uso de delays 
gerais, elas estão relacionadas a multiplexação e interrupção.
</p>

<p>
<b>5. Multiplexação dos Displays</b><br>
    A técnica de multiplexação para controlar a exibição dos números nos displays está presente no módulo hardware.asm, 
em que as rotinas de interrupção do temporizador, as quais utilizam do relógio-interno do microcontrolador, alternando os
números de saída. Assim, o código escreve as dezenas apaga e escreve as unidades, em um loop.
</p>

<p>
    <a href="https://github.com/estrela-h/Projeto-Bingo/blob/main/docs/MATERIAIS.md">
        <img src="/assets/Seguir.jpeg" height="34" width="34"/>
    </a>
</p>
</div>