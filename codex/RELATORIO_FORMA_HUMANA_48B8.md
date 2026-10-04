# 4.8b8 — capa da corrida

Revisão separada em `arte_fonte/forma_humana_v1/rig_corrida_48b8_capa/`, sobre a 4.8b7 do commit `c9adc51`. Apenas run foi revisado; nenhuma arte instalada. 4.8c permanece em espera para avaliação desta capa.

Estudei Walk de `preview 6.webp`, Walk e dobras nos golpes de `148019.png`, e Walk/Dash de `148045.png`, conforme o complemento da referência principal. A ligação ao corpo permanece estável enquanto a curvatura muda no meio e a ponta sobe/retorna. Apliquei esse princípio ao desenho original, sem copiar sprites, quantidade de quadros, tempos ou o porte do manto com foice. Recortes e hashes do estudo estão nas evidências.

O tecido tem oito contornos distintos. A raiz acompanha o ombro na oscilação aprovada; a parte solta usa fase e resposta ao corpo atrasadas um quadro. A onda muda a forma das colunas de pano e transporta as dobras/sombreamento até a barra, com amplitude material de 2,5 px antes do arredondamento. A largura das colunas é preservada. A diferença local máxima f7→f0 é 2 px; não há deslocamento local do pivô do ombro. A raiz e a peça inteira não recebem rotação rígida.

F0 recomposta: **zero diferenças RGBA**, inclusive PNG com SHA256 `28d0f2438a34e78ccef3676432a522dd2e35ecff381ad52a016d95b571813852`. As 25 peças originais e os dados das solas são byte a byte idênticos. Poses de pernas, ajustes da f3 e parâmetros de todas as peças fora da capa permanecem iguais. Nos oito quadros há zero diferenças nos pixels visíveis dessas outras peças e zero diferenças fora da união capa antiga/nova.

As máscaras distinguem pano retirado que revela fundo, pano retirado que revela uma peça original e pano novo sobre fundo. O compositor preserva os pixels marrons de corpo que existiam no recorte antigo da capa. Um pequeno fragmento cinza da barra incluído no recorte antigo da perna é classificado como tecido; os arquivos da perna não foram editados. Essa separação e os contadores por quadro estão em `CAPA_MATERIAL.json` e `PRESERVACAO_PEÇAS.json`.

Contrato preservado: 8 quadros de run, **41,67 ms/quadro**, **6 px/quadro por distância**, caminhada usando run; canvas **96×64**, âncora **(40,56)** e chão **Y=55**. Os 26 tons usados pertencem à paleta oficial; alpha apenas 0/255, contorno conectado, sem pixels isolados ou sombra embutida. F0 continua com 48 px do cabelo à sola; a oscilação de ±1 px do corpo é a anterior.

Entregas em `codex/evidencias_forma_humana_48b8/`: GIFs antes/depois ×4 do personagem e da capa; comparações simultâneas; folhas ×1/×4; f0/recomposição; fechamento do ciclo; máscaras; contrato e dados das solas. A ferramenta reproduz as variantes e evidências byte a byte. O GIF quantiza o ciclo a 330 ms por limitação de 10 ms do formato; o manifesto mantém os tempos originais.

A **PRÉVIA de 20 s** é externa ao jogo, identificada na imagem: 10 s de caminhada a **2,690217 m/s** e 10 s de corrida a **4,891304 m/s**, velocidades humanas atuais lidas do código preservado. Fundo do cemitério, arte ×1, detalhe NEAREST ×4, marcas fixas e posições das solas visíveis. Foram conferidos 600 quadros a 30 fps e seleção por distância. A oscilação discreta de até 6 px entre eventos de apoio continua visível, como na base aprovada; esta tarefa não a modifica.

Testes completos antes/depois: **23 de 25 suítes concluídas**, resultados idênticos, nenhuma falha nova. As duas falhas antigas aceitas permanecem: `verify_carrasco_gif_test.gd` acessa `texture_filter` em instância nula; `verify_milestone8_2.gd` acessa `sprite` inexistente no apresentador oficial. O pacote real do Peregrino passou **200/200** antes e depois.

Auditoria: **7.821 registros da linha de base**, com 7.818 hashes iguais. A coleta externa anunciada pelo usuário acrescentou 11 folhas e atualizou referência principal, inventário e diário do Diretor: **14 diferenças externas**, todas enumeradas com SHA256 antes/depois; nenhuma outra diferença. Os **974 arquivos de arte/evidências anteriores**, as fontes, mestre, conceito, 4.8b6/4.8b7, kit, jogo, main, checkout original, P40 e prova foram preservados por esta tarefa. Os arquivos do Diretor e o kit pendente ficam fora do commit.

Registro e envio limitados à revisão/ferramentas/evidências desta etapa no branch `feature/integracao-p40`. Main permanece em `ef24b5561cacb823d1f719370c29d82522cb5b58`. Parar para avaliação da capa.
