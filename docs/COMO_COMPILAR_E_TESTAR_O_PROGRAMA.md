# Como compilar e testar o programa/circuito
O nosso programa foi construito totalmente sobre o compilar [AVRA](https://github.com/Ro5bert/avra), por conta disso é indispensavel que se você quiser testar o funcionamento do nosso programa/circuito tenha-o instalado em sua maquina.

Uma vez tendo o [AVRA](https://github.com/Ro5bert/avra) instalado, clone o repositorio utilizando ` git clone https://github.com/estrela-h/Projeto-Bingo.git`, navegue para a pasta `/src` dentro da raiz repositorio utilizando seu terminal/linha de comando e execute: `avra Main.asm`, isso irá gerar um novo arquivo ".hex" na pasta `/src`. Caso tenha dificuldades em instalar o compilador AVRA sinta-se livre para testar o arquivo .hex ja pre-gerado na pasta `/src`, é pouco provavel que resulte em algum erro uma vez que o binario gerado não depende de inputs externos (apenas do compilador).

Para testar o programa há duas opções, você pode experimentar montar o [circuito fisico](https://github.com/estrela-h/Projeto-Bingo/blob/main/assets/Circuito_fisico2.jpeg) ou pode utilizar o simulador de circuitos [SimulIDE](https://simulide.com/p/), iremos abordar as duas opções logo abaixo.
1. 1 - **Utilizando o simulador**

Caso você tenha optado por utilizar o simulador o processo para verificar o programa é bem simples: Baixe o simulador indicado anteriormente e abra-o, após isso procure na aba superiro a opção de "carregar circuito", navegue para a pasta `/circuitos` presente na raiz do projeto e carregue o arquivo `Bingo.sim1`, após isso é esperado que você veja o circuito digital carregado em sua tela.

O proximo passo é carregar o arquivo `.hex` para dentro do arduino, para isso, clique com o botão direito do mouse sobre o arduino e siga o passo `-> mega328-109 -> load firmware`, após isso ele ira abrir seu gerenciador de arquivos, navegue até o arquivo `.hex` na pasta `/src` na raiz do projeto. Pronto, programa compilado e pronto para uso.

2. 2 - **Montando o circuito físico**

Após ter montado o circuito descrito no diagrama linkado anteriormente, carregue para seu arduino **(não esqueça de remover os jumpers do pino 0 e 1)** o arquivo `.hex` de sua maneira preferida. Após isso, o que resta é testar.

---
Caso tenha duvidas sobre o funcionamento, acesse https://github.com/estrela-h/Projeto-Bingo/blob/main/docs/LOGICA_E_FUNCIONAMENTO.md para mais detalhes.





