# Tarefa 4.8a — quadro-mestre da Forma Humana

Conceito aprovado reduzido proporcionalmente pela ferramenta original do projeto e limpo por retoques locais de pixels. Quadro único, olhando para a direita. Arte-fonte apenas: nenhuma instalação no jogo, rig, animação ou pacote. O corpo pequeno já escolhido será tratado na integração posterior.

| Conferência | Resultado |
|---|---|
| Redução automática | 46 × 48 px; recorte visível do conceito: 1084 × 1126 px, alpha > 40; escala proporcional 48/1126 |
| Mestre transparente | Canvas 50 × 52 px, incluindo margem de 2 px; desenho 46 × 48 px |
| Cabelo às solas | 48 px exatos, linhas Y=2…49 |
| Âncora dos pés | **(24,50)**, inteira; chão imediatamente após a sola; sem pixels abaixo |
| Transparência | RGBA, somente alpha **0/255** |
| Paleta | **23 cores** exclusivamente de `paleta_bosque_v1`; RGB/contagens em `mestre_conferido.json` |
| Contorno | Cor 3 contínua; um componente principal; nenhum pixel solto ou cor isolada dos 8 vizinhos |

Limpeza: 681 pixels alterados em relação à redução, com mechas e dobras escolhidas por coordenadas; 62 outliers de cor reagrupados pela regra do manual. A silhueta proporcional foi conservada, retirando somente resíduos pequenos desconectados. Nenhuma parte esticada. Capa usa carvão 0/1/2 e luz 14; couro e botas mantêm sombra 7/8 e volume 10/11/12. Pele 35/37/39, aço 15/17/18 e pequeno detalhe vermelho 21/25; a lista completa está no JSON.

Conferido visualmente a ×1: olho unido à franja e perfil humano legíveis, capuz recuado, mão na empunhadura reconhecível, espada reta inteira e destacada, botas compactas distintas, cabelo e capa organizados em grupos. A Humana fica próxima à altura do Carrasco; o Peregrino aprovado permanece mais alto e volumoso. No chão escuro do cemitério, rosto, mãos e lâmina destacam a silhueta sem clarear toda a capa.

Entregas:

- [Mestre transparente ×1](../arte_fonte/forma_humana_v1/forma_humana_mestre_x1.png) e [prévia transparente ×4](../arte_fonte/forma_humana_v1/forma_humana_mestre_x4.png).
- [Conceito / redução automática / mestre limpo](evidencias_forma_humana_48a/COMPARACAO_CONCEITO_REDUCAO_MESTRE.png), apresentados com a mesma altura visível para comparação.
- [Escala alinhada pelo chão ×1](evidencias_forma_humana_48a/ESCALA_ALINHADA_x1.png) e [×4](evidencias_forma_humana_48a/ESCALA_ALINHADA_x4.png), usando o idle aprovado do Carrasco e o mestre limpo aprovado do Peregrino.
- [PRÉVIA no cemitério ×1](evidencias_forma_humana_48a/PREVIA_CEMITERIO_x1.png): montagem sobre a captura real da 4.7c, em zoom 0,9; mestre colado sem escala, em posição inteira e alinhado ao chão. Não é captura de arte instalada. Método e hash da captura registrados em `PREVIA_METODO.json`.

Reprodução: `python arte_fonte/ferramentas/preparar_forma_humana_48a.py --reduzir`; conferência: a mesma ferramenta com `--verify`. A ferramenta de redução original permanece intacta. SciPy 1.18.1 ficou isolada no cache `.godot/forma_humana_48a/deps`; não entra no commit. Redução e mestre reproduzidos com SHA256 idêntico.

Testes antes/depois: **25 suítes, 23 aprovadas e 2069 verificações positivas em ambos**; somente `verify_carrasco_gif_test` e `verify_milestone8_2`, antigas e aceitas. Suíte do pacote real: **200/200 antes e depois**. Conferências do mestre e reprodução passaram. Nenhuma nova falha; comparação por suíte em `TESTES_COMPARACAO.json`.

Auditoria antes/depois: **6603 arquivos protegidos**, nenhuma diferença. Conceito PNG (`a06f3671…`) e `PROMPT.txt` (`2b87ac1e…`) intactos; mestre `c7f501c3…`. Assets instalados, código, física, combate, máscaras, inimigos, mapas, referências, provas e checkout original preservados. Nenhuma alteração externa nos arquivos do Diretor; kit de rig pendente intacto e fora do commit. `main` local/remoto continua em `ef24b556…`. Commit/push exclusivamente no branch `feature/integracao-p40`.

Parar para avaliação do mestre antes de animar.
