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
    <a href="https://github.com/estrela-h/Projeto-Bingo/blob/documentacao/docs/MATERIAIS.md">
        <img src="/assets/Seguir.jpeg" height="34" width="34"/>
    </a>
</p>
</div>