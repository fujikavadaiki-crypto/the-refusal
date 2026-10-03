# MANUAL DO CODEX — THE REFUSAL (passagem completa, 03/10/2026)

> **Leia este arquivo inteiro no início de TODA tarefa.** A partir de agora o Codex trabalha **sozinho**: o Claude não estará mais disponível para arte nem para revisão. Este manual reúne tudo o que antes estava espalhado entre conversas, relatórios e o `ESTADO_DO_PROJETO.md`.
> O usuário fala **português do Brasil**. Relatórios curtos, em pt-BR, com o que mudou, como testar e o que ficou pendente.

---

## 0. Como trabalhar (regras que valem sempre)

1. **Repositório de trabalho:** `C:\Users\daiki\Documents\Codex\The Refusal\integracao-p40`, branch **`feature/integracao-p40`**.
   - Commit e push **somente nesse branch**. **Nunca** fazer merge com o `main` nem tocar no `main` (`ef24b55…`), a não ser que o usuário peça com essas palavras.
2. **Não tocar** no checkout original `C:\Users\daiki\Documents\Codex\The Refusal\the-refusal`. Pode ler.
3. **Somente leitura** na pasta `C:\Users\daiki\Documents\Codex\carrasco_25d_test`, que guarda os protótipos, as provas de arte e o `ESTADO_DO_PROJETO.md`.
   - Exceção: atualizar o `ESTADO_DO_PROJETO.md` quando a tarefa pedir, **só acrescentando** seções no fim.
4. **Não apagar o Bosque B.** O mapa e o cenário congelados não mudam sem pedido; o cemitério do P40 é a sala inicial.
5. **Não baixar assets** da internet. O Skul: The Hero Slayer é **estudo de regras e sensação**: nunca copiar quadro, forma ou personagem.
6. **Antes e depois de cada tarefa:**
   - rodar as suítes de teste e comparar;
   - fazer a auditoria SHA256 do que deve ficar intacto: `prova/`, checkout original, Bosque, pacotes aprovados.
   - **Falhas preexistentes aceitas:** `verify_carrasco_gif_test` e `verify_milestone8_2` (testes de arte antiga).
7. **Uma tarefa por vez. Parar para avaliação ao fim de cada uma.** Entregar:
   - um relatório `codex/RELATORIO_*.md`;
   - evidências: GIF ×4, foto ×1 na sala, clipe de ~20 s do jogo real, prints F3 com as áreas.
8. **Arte nova** fica em `arte_fonte/`, que tem `.gdignore` para o Godot não importar. Só o **pacote final** é copiado para `assets/` (ex.: `assets/enemies/<nome>_v1/`).
9. **Decisões de design** (IA nova, tamanho, nome, mecânica) que este manual marca como **PROPOSTA** precisam do OK do usuário. Apresente-as como proposta curta antes de gastar uma tarefa inteira nelas.

---

## 1. O jogo

- **THE REFUSAL**: roguelite de ação 2D em pixel art, Godot **4.7.2**, física a 60 Hz.
- **Referência forte:** *Skul: The Hero Slayer*, pela mobilidade, fluidez, golpes vendidos por arcos em meia-lua grandes, poucos quadros com poses exageradas e personagem pequeno contra inimigos maiores.
- **O que manda é o jogador se divertir.** Fluidez e resposta vêm antes de detalhe de arte.
- **Personagem pequeno (~48 px).** Inimigos de **1× a 4×** a altura dele; chefes maiores, com barra própria. Sem números de dano na tela.
- **Tom:** Bosque dos Esquecidos, cemitério, ruínas; corrupção vegetal (musgo, galhos, raízes) sobre cavaleiros, peregrinos e religiosos; sinos fúnebres. Tema de **corrupção × purificação**: o Lenhador Corrompido pode virar Lenhador Purificado.

---

## 2. Estado atual (fim da Tarefa 4.5 / F6)

**Integrado e funcionando no branch:**

- **Física nova.**
  - Corrida: Carrasco 4,5 m/s; humano 4,89 m/s pelo multiplicador de máscara 0,92.
  - Dash: 3,5 m em 0,35 s, i-frames [61,25; 218,75) ms, cooldown 280 ms, cancelamento 80 ms.
  - Pulo: 2,315 m com ápice em 20 ticks (g 1481,13 e v0 −481,37); toque curto 1,0 m.
- **Escala fixa:** 32 px de tela por metro com zoom 0,9, ou seja **35,555556 unidades/m**, independente da câmera.
- **Máscara Carrasco com a arte "Pequeno A v34A"** (26 animações, `assets/…/pequeno_v34A`).
  - Corrida animada por distância: 8 quadros, 6 px por quadro.
  - Sombra única no chão; rastro do dash.
  - Dano por quadro ACTIVE, em polígonos/retângulos só à frente do corpo.
  - Cápsula: raio 7, altura 51,11 unidades, pés Y=13, pivô Y=−16,8667.
- **Forma Humana** ainda com **arte antiga** e corpo antigo (altura 64).
- **Sensação** (`data/config/sensacao.json`, 4 grupos ligados):
  - buffers de 100/120 ms, coyote, pulo variável;
  - hitstop 60/90 ms (parry 80); tremor só no pesado;
  - flash branco, recuo, sangue e poeira em pixels;
  - câmera com antecipação de 18 px.
- **Inimigos:**
  - **Peregrino Profanado v1** com arte (`assets/enemies/peregrino_v1/`), hurtbox 7×44 px. **Este visual será substituído** pelo Peregrino Corrompido (§5.2).
  - **Corvo** (ave) e **Raiz Faminta** ainda com `Polygon2D` provisório.
- **Leitor genérico de pacote de inimigo**, com contrato em `codex/CONTRATO_PACOTE_INIMIGO.md`:
  - mapas IA→animação em `data/enemies/*_mapa.json`;
  - projétil com animação própria;
  - pacote FALSO só para os testes.
- **Salas:** `JOGAR_INTEGRACAO.cmd` abre o **cemitério do P40**; F9 alterna para o **Bosque B**. As teclas estão em `codex/README_INTEGRACAO_P40.md`.
- **Testes:** `python codex/verificar_fase6.py after` roda 24 suítes, com 2 falhas preexistentes; `python codex/verificar_fase6.py new` roda as 201 verificações do pacote real.

**Pendências conhecidas (não resolver sem tarefa):**

- Ataques altos de inimigos passam por cima do Carrasco pequeno. Fica para o futuro "balanceamento de inimigos": mirar no centro da hurtbox.
- Ataques aéreos do jogador passam acima do Corvo: reavaliar com a arte nova.
- Em salas com zoom 1 a área física projeta 11% maior que a arte.
- Revisão R4 do mapa e fase vertical: futuras.
- O Carrasco pequeno é mais "chapado" (menos sombreamento) que o estilo dos inimigos novos. Avaliar um retoque de sombreamento **depois** (veja `inimigos_mestre_x1/escala_*.png`).

---

## 3. Números travados (não mudar sem pedido)

| Item | Valor |
|---|---|
| Escala | 32 px/m @ zoom 0,9 → 35,555556 unidades/m |
| Altura de referência do personagem | Carrasco pequeno ≈ **48 px** (cápsula 7 × 46 px) |
| Corrida | Carrasco 160 unidades/s (4,5 m/s); humano 173,913 (×1/0,92) |
| Caminhada | 0,55 × corrida |
| Dash | 355,56 unidades/s, 0,35 s; i-frames [61,25; 218,75) ms; cooldown 280 ms; cancelamento 80 ms |
| Pulo | g 1481,130835; v0 −481,367521; ≈2,315 m; ápice 20 ticks |
| Sensação | buffer pulo 100 ms / ataque-dash 120 ms; hitstop 60/90 ms (parry 80); tremor só pesado 3 px/110 ms; recuo 1,1/2,1 m/s |
| Arte | ×1, filtro NEAREST, âncora nos pés em pixel inteiro, olhando para a DIREITA (o jogo espelha), sombra em arquivo separado |

---

## 4. Elenco — jogador

**Protagonista: FORMA HUMANA**, um jovem de capa escura e espada reta. Equilibrada, o "sem máscara".
O jogador veste **máscaras**, e cada máscara é uma forma jogável com animações próprias (no código: `MaskController`, `data/masks/*.tres`).

### 4.1 Máscaras (9) — todas jogáveis

| Máscara | Situação | Linha de evolução (4 degraus) | Papel proposto |
|---|---|---|---|
| **Carrasco** | **PRONTA** (Pequeno A v34A) | Carrasco → Executor Rubro → Juiz Carmesim → Colosso do Sangue | machado; lento e pesado; arco gigante; quebra postura |
| **Corvo** | rascunho (`carrasco_25d_test/pacotes/pacote_mascara_corvo_rascunho_v1.zip`; **não é inimigo**) | Corvo → Mensageiro do Vazio → Asa Sombria → Arauto Abissal | rápido, aéreo; roxo do vazio |
| **Fome** | só conceito | Fome → Devorador Pestilento → Apóstolo da Praga → Colosso Faminto | praga; vermelho escuro + verde doente |
| **Procissão** | só conceito | Procissão → Liturgista das Raízes → Prelado Carmesim → Santo Enraizado | raízes vermelhas, halo de cruz |
| **Duelista** | conceito, **evoluções a criar** | — | espada fina; precisão; **parry com janela extra + riposte** |
| **Besta** | conceito, evoluções a criar | — | garras; agressiva; fúria que cresce ao acertar |
| **Caçador** | conceito, evoluções a criar | — | besta + adaga; distância; tiro carregado, armadilhas |
| **Oráculo** | conceito, evoluções a criar | — | cajado de cristal; projéteis do vazio; marca |
| **Ritualista** | conceito, evoluções a criar | — | báculo de anel + livro; círculos de ritual no chão |

- **Forma Humana × Duelista** (as duas usam espada): a Humana é a referência equilibrada (combo de 3, sem especialidade); o Duelista vive de parry/riposte e estocada longa.
- **Regra de evolução:** mesmo rig e mesmas animações da base, mais **peças novas** desenhadas por cima (ombreira, elmo, coroa, capa, brilho). Animação nova só quando a mecânica nova pedir.
- **Folhas de conceito:** `carrasco_25d_test/referencias/elenco/`. São `elenco_formas_jogaveis_v1/v2`, `evolucao_carrasco_v1`, `evolucao_carrasco_v2_brilho`, `evolucao_corvo`, `evolucao_fome`, `evolucao_procissao`.
- **Ordem de produção combinada:**
  1. **Forma Humana** com arte nova (é a protagonista e ainda usa a arte antiga);
  2. Carrasco (pronto);
  3. Corvo;
  4. Fome e Procissão;
  5. Duelista, Besta, Caçador, Oráculo e Ritualista.

### 4.2 NPCs (folha `elenco_npcs_v1/v2`)

- Guardiã das Máscaras, Ferreiro Cego, Oráculo das Memórias, Mercador das Dívidas, Cartógrafa, Sobrevivente, Eremita das Raízes, Colecionador.
- **Lenhador Purificado** (folha de inimigos v2): NPC que surge ao purificar o chefe Lenhador Corrompido. **PROPOSTA.**

---

## 5. Elenco — INIMIGOS (referência visual OFICIAL v2, enviada pelo usuário em 03/10/2026)

> As folhas antigas `elenco_inimigos_v1/v2` (Peregrino Profanado de capuz vermelho, Arqueiro do Bosque, Portador do Vazio, Sentinela da Copa, Devoto Desgarrado, Rei Esquecido, Rei das Maldições) **não são o visual desejado**. Ficam **arquivadas**. Só se usa algo delas se o usuário pedir.
> **O visual oficial é o das 4 folhas v2**, em `arte_fonte/referencias/inimigos_v2/`:
> - marrons e cinzas foscos;
> - **musgo verde-oliva** escorrendo;
> - **galhos/raízes** saindo da cabeça e do corpo;
> - caveiras e máscaras **cor de osso**;
> - **bronze** nos sinos;
> - **vermelho-sangue** só como destaque (capa do Maceiro, boca do Devorarraiz);
> - contorno escuro.

### 5.1 Arquivos prontos para começar

- `arte_fonte/referencias/inimigos_v2/folhas/`: as 4 folhas originais.
- `arte_fonte/referencias/inimigos_v2/recortes/`: um PNG por personagem, sem rótulo, fundo transparente.
- `arte_fonte/inimigos_mestre_x1/`:
  - **quadro-mestre ×1 de cada um, já na altura do jogo e na paleta do projeto** (`<nome>_x1.png`), com prévia ×4;
  - **comparação de escala ao lado do Carrasco**: `escala_A_comuns`, `escala_B_pesados`, `escala_C_chefes`.
  - São **reduções automáticas** (rascunho de escala). Leem bem, mas precisam de limpeza à mão antes de virar arte final (§6.3).
- `arte_fonte/paleta/paleta_bosque_v1.json` e `.gpl`: C5.1 (44 cores, ids 0–43, as mesmas do Carrasco) + **extensão do Bosque** (18 cores, ids 44–61: musgo/oliva, casca, bronze, pele, osso quente, névoa verde).
- `arte_fonte/ferramentas/reduzir_referencia.py`: separa folhas, remove fundo, reduz para a altura do jogo, quantiza na paleta, aplica contorno e tira pixels soltos.

### 5.2 Tabela dos inimigos

Alturas em px ×1 (Carrasco = 48). "IA" diz se já existe no jogo.

| Inimigo | Classe | Altura | IA | Ataques |
|---|---|---|---|---|
| **Peregrino Corrompido** | comum | 52 | **existe** (Peregrino) | 5 ataques atuais: corte, estocada, corte duplo, investida, penitência (NÃO aparável) |
| **Corvo da Praga** | comum aéreo | 40 alt. / 61 larg. | **existe** (Corvo ave) | pairar, rasante (aparável), cuspe pestilento (NÃO aparável) |
| **Raiz Faminta** | comum emboscada | 38 alt. / 52 larg. | **existe** (Raiz) | escondida/enterrada, garra subterrânea, mordida (ambas NÃO aparáveis) |
| **Máscara Vazia** | comum flutuante | 58 | **nova — PROPOSTA** | flutua e atravessa plataformas; fica **intangível** em ciclos (só leva dano quando a máscara acende); sopro de névoa verde em arco (projétil lento); investida curta |
| **Acólito do Lamento** | conjurador | 58 | **nova — PROPOSTA** | mantém distância; orbe verde lento e teleguiado (aparável); toca o sino pequeno para **reerguer um aliado caído uma vez**; teleporte curto quando cercado |
| **Sentinela do Sepulcro** | pesado defensivo | 70 | **nova — PROPOSTA** | **escudo frontal bloqueia golpes leves** (faísca + recuo); vulnerável por trás, por cima e ao pesado; estocada (aparável); escudada que empurra (aparável); avanço com escudo (NÃO aparável) |
| **Maceiro Profanado** | pesado bruto | 72 | **nova — PROPOSTA** | maçada vertical lenta (aparável); giro 360° (NÃO aparável, área em volta); pancada no chão com onda baixa (pular para desviar) |
| **Sino Fúnebre** | pesado suporte | 88 | **nova — PROPOSTA** | badalada = **onda circular** (NÃO aparável; atravessar com i-frames do dash); fortalece a postura de aliados próximos; golpe com o sino (aparável). Lento |
| **Devorarraiz** | elite / mini-chefe | 72 alt. / 125 larg. | **nova — PROPOSTA** | investida longa (NÃO aparável); mordida (aparável); raízes que brotam sob o jogador (aviso no chão) |
| **Lenhador Corrompido** | **chefe 1** | 150 alt. / 221 larg. | **nova — PROPOSTA** | machadadas horizontais; machado arremessado em bumerangue; raízes; ao ser vencido: escolha **purificar** → vira o NPC Lenhador Purificado |
| **Abadessa Enraizada** | **chefe 2** | 168 | **nova — PROPOSTA** | incensário em pêndulo (zona de névoa); raízes; invoca Acólitos; halo de cruz |
| **Lenhador Purificado** | NPC | 54 | — | conversa/serviço (proposta: lenhador/ferreiro do acampamento) |

**Regras de leitura dos ataques (todos os inimigos):**

- **Aviso pálido** (cores 18/16) = aparável; **aviso vermelho** (41/26) = NÃO aparável. Já é assim no Peregrino v1.
- O efeito do golpe é um arco em meia-lua com 3 faixas mais um filete. As cores ficam por inimigo, por exemplo:
  - musgo/oliva para os enraizados;
  - bronze para os sinos;
  - vermelho para Maceiro e Devorarraiz.
- **Hurtbox sugerida** no manifesto: cápsula no tronco, sem armas, galhos ou asas.
- A **IA atual** (tempos de `.tres`, dano, vida, postura) **prevalece**. Os quadros se distribuem dentro das fases do ataque, como no Peregrino v1.

---

## 6. PIPELINE DE ARTE (sem o Claude)

O que funcionou neste projeto:

- **(a)** conceito estático bonito, vindo do ChatGPT;
- **(b)** redução para ×1 na paleta;
- **(c)** limpeza;
- **(d)** separação em PARTES;
- **(e)** animação por **rig de partes**, com poucos quadros, poses exageradas e arcos de golpe desenhados por código.

O que **NÃO funcionou:** pedir ao ChatGPT folhas de animação quadro a quadro. As pernas nunca alternam e os quadros não batem entre si. **Use o ChatGPT só para conceitos parados e, no máximo, poses-chave isoladas.**

### 6.1 Conceito (ChatGPT, feito pelo usuário)

Modelo de pedido (o usuário cola no ChatGPT):

```
Pixel art de jogo 2D, vista lateral, personagem INTEIRO de corpo, olhando para a DIREITA, pose neutra de combate,
fundo TRANSPARENTE (ou cor lisa única), contorno escuro de 1 pixel, luz vindo de cima/direita.
Estilo igual às folhas de inimigos do THE REFUSAL: marrons e cinzas foscos, musgo verde-oliva, osso, bronze,
vermelho-sangue só como destaque. Sem texto, sem sombra no chão, sem efeitos soltos.
Personagem: <descrição>. Armas e braços bem separados do corpo (para recortar em partes).
```

### 6.2 Redução para ×1

```
cd arte_fonte
python ferramentas/reduzir_referencia.py folha  <folha.png> referencias/<grupo>/recortes --nomes a,b,c
python ferramentas/reduzir_referencia.py reduzir referencias/<grupo>/recortes/a.png <saida>/a_x1.png --altura 52
```

Escolha a altura pela §5.2 ou pela regra 1×–4×. Sempre gere uma comparação ao lado do Carrasco: o script `escala_*` é simples, veja os PNGs existentes.

### 6.3 Limpeza do quadro-mestre (obrigatória antes de animar)

- **Só cores da paleta** `paleta_bosque_v1`; um efeito novo (roxo do vazio, por exemplo) entra como extensão registrada.
- Contorno escuro (cor 3) contínuo. **Nenhum pixel isolado:** um pixel que difere de todos os 8 vizinhos vira o vizinho mais comum.
- **Hierarquia de valor:** silhueta escura legível contra o fundo escuro do cemitério. Rosto, máscara e caveira em osso claro; arma com borda clara.
- Detalhe miúdo que vira "ruído" a 1× (fiapos de musgo de 1 px, galhos finos) deve ser simplificado em **cachos**, não em pontinhos.
- Conferir na sala real com zoom 0,9.

### 6.4 Separar em partes (rig)

- Cortar o quadro-mestre em camadas PNG, cada uma com seu **pivô** (ombro, quadril, punho), salvo num JSON. As camadas típicas são:
  - corpo;
  - cabeça/máscara;
  - braço da arma + arma;
  - outro braço;
  - perna de trás e perna da frente;
  - capa/manto/musgo pendurado.
- Completar à mão os pixels que ficavam escondidos atrás das partes (por exemplo, o tronco atrás do braço).
- **Ordem de camadas** que deu certo no Carrasco: membro distante → corpo/pano → membro próximo (só abaixo da barra do pano) → arma por cima.
- Exemplos de rig no projeto (só leitura, para estudar):
  - `carrasco_25d_test/jogavel/prototipo_40/pacotes/pequeno_v34A/geradores/mao32/` (`v4rig.py`, `v4poses.py`, `v4pack.py`, `v6*`);
  - `carrasco_25d_test/geradores/e1/` (Peregrino v1: `e1lib.py`, `e1_peregrino.py`, `e1_per_anim.py`, `e1_pack.py`);
  - a função **`arc_e`/`arc3`** desenha o arco em meia-lua de 3 faixas.
  - Esses scripts importam módulos por caminhos `/tmp/...` do ambiente antigo; copie as funções que precisar para `arte_fonte/ferramentas/`.

### 6.5 Animar (regras de estilo Skul)

- Deslocamentos em **pixels inteiros**. Rotação de parte só em ângulos pequenos (≤ 20°), em NEAREST, e **limpar o serrilhado depois**. Para poses extremas, **trocar a peça** (desenhar uma variante) em vez de girar muito.
- **Poucos quadros, poses exageradas:**
  - idle 4–6 quadros;
  - marcha 6–8 quadros, **animada por distância** (`floor(distância/px_por_quadro) mod n`) para não patinar;
  - ataque = preparação 2–4 quadros + ATIVO 1–2 quadros com **arco grande** + recuperação 2–3 quadros;
  - dano 2 quadros;
  - ruptura 4–7 quadros (entrada + laço);
  - morte 6–8 quadros.
- **Movimento secundário:** capa, musgo, sinos e correntes atrasam 1 quadro em relação ao corpo.
- **Aviso** (brilho pálido ou vermelho) cresce durante a preparação. O brilho fica em camada de efeito, não no corpo.
- Mapear **cada estado da IA** para uma animação (veja o `*_mapa.json` do Peregrino) e **somar os tempos de cada fase com assert contra o `.tres`**.

### 6.6 Pacote

Siga `codex/CONTRATO_PACOTE_INIMIGO.md` e copie a estrutura do Peregrino v1 (`assets/enemies/peregrino_v1/`):

- `manifesto_sprites.json` com `animacoes[]/quadros[]`. Cada quadro tem `arquivo`, `sha256`, `ms`, `ancora`, `fase` e `hitbox` só nos ACTIVE (à frente do corpo, x ≥ 0).
- `sombra` em arquivo próprio; `efeitos[]` com `camada` e `fase`.
- `hurtbox_sugerida` (raio/altura em px).
- `estados_ia` para conferência.
- Um verificador que confere: hashes, paleta, âncoras inteiras, um único componente principal por quadro, nenhum pixel solto e a soma dos tempos igual à do `.tres`.

### 6.7 Avaliação pelo usuário

- GIF ×4 de cada animação, isolado sobre cinza neutro.
- Foto ×1 na sala do cemitério ao lado do Carrasco.
- Clipe de ~20 s no jogo real, com IA e dano reais.
- Prints F3 de cada ataque, com hitbox e hurtbox.

---

## 7. FILA DE TAREFAS

Cada item é uma tarefa; pare ao fim de cada uma. O usuário cola o prompt curto.

| # | Tarefa | Resumo |
|---|---|---|
| **4.6** | Registro | Commitar `arte_fonte/` (referências v2, recortes, mestres ×1, paleta, ferramenta) e este manual; acrescentar §17 ao `ESTADO_DO_PROJETO.md` se faltar; nada de jogo muda. |
| **4.7** | **Peregrino Corrompido** | Arte nova sobre a IA atual do Peregrino (substitui o visual do Profanado v1, que fica guardado). Primeiro teste completo do pipeline §6. |
| **4.8** | **Forma Humana** (protagonista) | Conceito novo (o usuário gera no ChatGPT a partir de `elenco_formas_jogaveis`, no estilo v2) → mestre 48 px → rig → as mesmas 26 animações do Carrasco (mesmos nomes e tempos), dano por quadro, corpo pequeno igual ao Carrasco (decidir com o usuário). |
| **4.9** | **Corvo da Praga + Raiz Faminta** | Arte nova sobre as IAs atuais; projétil do cuspe com animação própria (já suportado). |
| **5.0** | Impacto 2 | Clarão de impacto branco com borda vermelha; inimigos morrendo em pedaços; objetos quebráveis soltando lascas; gotas/itens. Sem números de dano. |
| **5.1** | Inimigos de IA nova — leves | Máscara Vazia + Acólito do Lamento (propor IA → OK do usuário → implementar → arte). |
| **5.2** | Inimigos de IA nova — pesados | Sentinela do Sepulcro + Maceiro Profanado. |
| **5.3** | Sino Fúnebre + Devorarraiz | |
| **5.4** | Balanceamento de inimigos | Mirar no centro da hurtbox; alturas dos golpes contra o corpo pequeno. |
| **6.x** | Chefes | Lenhador Corrompido (com a escolha de purificar) e Abadessa Enraizada; barra de chefe. |
| **7.x** | Máscaras | Corvo → Fome → Procissão → as cinco restantes (evoluções = mesmo rig + peças). |
| — | Futuro | Revisão R4/mapa, fase vertical (plataformas para pulo de 2,3 m + dash aéreo), merge no main **só com ordem do usuário**. |

---

## 8. Onde está cada coisa

```
The Refusal/integracao-p40/            <- TRABALHO (branch feature/integracao-p40)
  JOGAR_INTEGRACAO.cmd                 <- abre o cemitério (F9 = Bosque B)
  codex/MANUAL_CODEX.md                <- este arquivo
  codex/PLANO_INTEGRACAO.md            <- plano das fases 1–14
  codex/CONTRATO_PACOTE_INIMIGO.md     <- contrato do pacote de inimigo
  codex/README_INTEGRACAO_P40.md       <- teclas e como jogar
  codex/RELATORIO_INTEGRACAO_P40_F1..F6.md, evidencias_*/
  data/config/sensacao.json            <- valores de sensação
  data/enemies/*_mapa.json             <- IA -> animação
  assets/enemies/peregrino_v1/         <- 1º pacote real de inimigo
  arte_fonte/ (.gdignore)              <- ARTE-FONTE (não importada pelo Godot)
    referencias/inimigos_v2/folhas|recortes
    inimigos_mestre_x1/                <- mestres x1 + comparações de escala + alturas_alvo.json
    paleta/paleta_bosque_v1.json|.gpl
    ferramentas/reduzir_referencia.py
carrasco_25d_test/                     <- SÓ LEITURA (protótipos, provas, histórico)
  ESTADO_DO_PROJETO.md                 <- histórico detalhado (§11–17)
  jogavel/prototipo_40/                <- protótipo de referência jogável (P42b)
  jogavel/prototipo_40/pacotes/pequeno_v34A/  <- pacote do Carrasco + geradores mao32
  geradores/e1, e2                     <- geradores do Peregrino v1 e designs antigos de ave/raiz
  pacotes/                             <- pacote_inimigo_peregrino_v1.zip, pacote_mascara_corvo_rascunho_v1.zip
  referencias/elenco/                  <- folhas de máscaras, evoluções, NPCs (e inimigos v1 ARQUIVADOS)
```
