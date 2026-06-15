# Pequenas decisões sobre a montagem do circuito
Gostaria de detalhar algumas decições que foram descartadas (no caso somente duas) que achei interessante para a montagem do circuito mas que foram posteriormente descartas por algum motivo.

### Utilizar 1 transistor NPN e 1 PNP ao invés de 2 NPN
Um dos detalhes que percebemos ao monstar o circuito enquanto pensavem em como construir o codigo é que seria possivel fazer a multiplexação nos displays utilizando apenas uma porta de saida do arduino ao invés de duas (que é a abordagem adotada no circuito/programa final). Para isso, usariamos apenas 1 transistor NPN e 1 PNP ao invés de 2 NPN.

A logica do programa se baseia que os pinos responsaveis pela multiplexação (os pinos 8 e 9) sempre estão com valores logicos diferentes, i.e: Se P8 está com valor logico HIGH, P9 deve necessariamente estar com o valor logico LOW; com essa logica, podemos fazer a multiplexação tranquilamente utilizando dois transistores NPM, onde a base de cada um está conectada ao seus respectivos pinos de multiplexação responsaveis. Ou seja, quando P8 estivesse com valor logico HIGH um dos digitos estaria sendo exibido enquanto outro não e vice-versa. 

Para a abordagem utilizando um transistor NPN e outro PNP a logica seriá semelhante, entretanto a diferença fundamental é que a base de ambos transistores estariam conectadas ao mesmo pino de multiplexação, pela natureza desses dois tipos de transistores, quando P8 estivesse em HIGH (e sim, a logica de trocar o valor do pino periodicamente se mantém) o transistor NPN estaria permitindo a passagem de corrente, enquanto o transistor PNP estaria bloqueando-a (lembrando que transistores PNP são sensiveis ao nivel logico baixo), quando P8 estivesse em LOW o transistor NPN bloquearia a passagem enquanto o transistor PNP permitiria, gerando assim um circuito equivalente ao anterior para a multiplexação.

Essa abordagem não é ideal e amplamente não recomendada pela comunidade de eletrocia (com base em pesquisas). A recomendação é utilizar um transistor PNP quando o emissor está conectado ao nivel logico alto, o que não é o nosso caso. Isso evita dores de cabeças decorrentes de resultados inesperados. Por conta disso, essa ideia foi descartada apesar de **talvez** ser uma solução elegante.


### Conectar o emissor dos transistores as duas fontes GND em paralelo
Essa é uma ideia descartada por praticidade e para exemplificar o circuito, fora que a não utilização dela não implicaria em nada mutio grave. Vou explicar o que estou falando:

Uma das preocupações na hora da montagem era se a corrente indo dos pinos que controlam o display para a fonte GND era suficiente para danificar a fonte ou não. Para saber a resposta precisamos apenas saber o limite de estresse que podemos submeter a fonte GND. A documentação do ATMEGA328 diz que a fonte GND aguenta um limite de 200mA, ou seja, caso proximo desse regime existe uma change consideravel de danificar a fonte GND.  

Cada pino de saida tem um **limite padrão** de 20mA segundo a documentação do ATMEGA328, sendo que pode ser programado para até 40mA (o que não foi o nosso caso) com o risco de danificar o pino de saída. Ja que o cenario dos 40mA não ocorre no nosso projeto, vamos supor que o arduino a todo momento está fornecendo o máximo de carga permitida (20mA), nesse cénario, cada um dos 7 pinos do display estaria lidando com um total de 20mA e o display como um todo com 7*20mA = 140mA. Isso significa essencialmente a saida onde conecta o terra do display catodo comum lida com um maximo teorico de 140mA e essa corrente vai direto para a fonte GND.

Ou seja, podemos concluir que a fonte GND lida com um maximo de 140mA apenas, estando 60mA abaixo do limite máximo estabelecido. Isso é o suficiente para proteger a fonte de de eventuais ESDs (descargas eletroestaticas). Claro, conectar as duas fontes GNDs em paralelo ainda iria garantir uma magem de segurança maior, uma vez que cada fonte estaria lidando apenas com 140/2mA=70mA ao invés de 140mA. Mas julgamos que isso seria desnecessario/exagerado ja que nossa abordagem atual tem uma boa margem de segurança.

