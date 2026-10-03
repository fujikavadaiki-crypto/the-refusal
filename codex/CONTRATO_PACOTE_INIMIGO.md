# Pacotes de inimigo — preparo da Tarefa 4.4

**Tarefa 4.5:** Peregrino Profanado aprovado e equipado em `assets/enemies/peregrino_v1/`, cópia byte a byte de `carrasco_25d_test/pacotes/pacote_inimigo_peregrino_v1.zip`. O campo histórico de status dentro do manifesto foi preservado; a aprovação válida é a decisão atual do usuário. IA/tempos/dano continuam originais. Hurtbox sugerida aplicada por opção explícita do mapa, em todas as instâncias (cemitério e Bosque).

**Corvo inimigo é uma ave.** Não extrair/equipar como inimigo o pacote humanoide `pacote_inimigo_corvo_v1.zip`: foi reclassificado como rascunho da máscara Corvo jogável. Corvo ave e Raiz aguardam pacotes próprios; mantêm fallback. Os mapas permitem trocar nomes de animações sem alterar IA.

## Manifesto

Mesmo formato do Pequeno A: `animacoes[]`, cada entrada com `id`, `loop`, `quadros[]`; cada quadro informa `arquivo`, `sha256`, `ms`, `ancora:[x,y]` e dimensões opcionais `largura/altura`. PNGs nativos, ×1 NEAREST, âncora em pixels inteiros. SHA256 confere bytes exatos ou remove somente o chunk caBX, como o Carrasco. Arquivos relativos ao pacote; caminhos externos/`..` são rejeitados.

`sombra` pode vir na animação ou no quadro, com arquivo/hash/dimensões/âncora próprios. Fica no terreno abaixo dos pés, reduz/clareia no ar e desaparece sem chão; nunca embutir sombra no corpo ou nos FX. `efeitos[]` usa o mesmo descritor de PNG, `fase` e seletor `quadro` opcional. Também aceita efeitos locais no quadro. Sem `fase`, um efeito selecionado por `quadro` herda a fase desse quadro, ou ALL nos estados sem fase. `camada:atras_do_corpo` desenha antes do corpo e `frente_do_corpo` depois; brilho de aviso aparece somente em WINDUP. Fases: WINDUP/PREP/PREPARACAO, ACTIVE/ATIVO, RECOVERY/RECUP/RECUPERACAO, ALL/TODAS.

`hitbox:null` significa quadro sem área. `loop_inicio_quadro` toca a entrada uma vez e repete a cauda (ruptura); animação sem loop mantém o último quadro (morte).

Para ataques, marcar fases pelo campo `fase` do quadro ou por `ataque.fases.{PREPARACAO,ATIVO,RECUPERACAO}.quadros`. `hitbox` é opcional somente em ACTIVE: `retangulo:[x,y,w,h]`, `retangulos:[[...],...]`, `poligono:[[x,y],...]` ou `arco/lamina.poligono`, relativos à âncora. X positivo à frente, Y positivo para baixo. Recorte x≥0, decomposição convexa e espelho único. `ataque` aceita objeto ou lista de objetos com `attack_id` e fases separados (as duas partes do corte duplo). Índices JSON são normalizados para inteiros antes da seleção. Os tempos da IA/ataques originais prevalecem: os quadros autorais são distribuídos dentro de cada fase, sem modificar seu tempo físico.

Um ataque com algum dado de hitbox usa exclusivamente seus quadros; quadro vazio não reativa a caixa antiga. Ataque/animação sem dados mantém fallback. Recuo, flash, sangue e hitstop usam o sistema comum da sensação, não precisam ser desenhados no pacote.

## Mapeamento

`*_mapa.json` contém `pacote`, `padrao`, `pes_world:[x,y]`, `estados:{NOME_DA_IA:animacao}` e `ataques:{id_do_tres:animacao}`. Pés seguem o colisor original: Peregrino Y=15,5, Corvo Y=8 e Raiz Y=9 unidades. Isso não altera o colisor de locomoção, IA, vida ou postura. `aplicar_hurtbox_sugerida:true` lê `hurtbox_sugerida.raio_px/altura_px` do manifesto e divide pela escala física fixa 0,9. Peregrino: raio 7/altura 44 px, centro Y=−8,944444 e base Y=15,5; colisor original raio 7/altura 31 unidades intocado. Mantém 44 px em todos os estados vivos nesta fase; a variante opcional de 34 px na ruptura não foi ativada. Morte mantém a desativação original; pacote ausente/falso restaura a hurtbox anterior. Os mapas entregues listam todos os estados/IDs atuais, como ponto de partida.

Corvo aceita `projeteis:{corvo_cuspe_pestilento:cuspe_projetil}`. Essa animação tem PNG/âncora próprios e avança por `ms` durante o voo. Seus quadros de dano são ACTIVE e relativos à origem/âncora do projétil, com direção travada na trajetória. A animação do bico é distinta. Sem animação dedicada, o core e a área nativos continuam. Velocidade, duração, colisão com terreno e defesa permanecem originais.

`codex/fixtures/inimigo_falso_v1/` é **FALSO, apenas para testes**: quatro PNGs pequenos, idle/hurt/death e ataque com retângulo/polígono ACTIVE, FX e sombra separados. A sala normal não o usa. A suíte F5 injeta seu mapa em Peregrino, Corvo, Raiz e projétil, testa rejeição de hash/caminho/tempo/âncora/fase inválidos e restaura os mapas reais. F3 exibe polígonos dos inimigos quando um pacote válido fornecer áreas.

## Tarefa 4.7 — Peregrino Corrompido

Pacote equipado: `assets/enemies/peregrino_corrompido_v1/`, com paleta Bosque v1 (62 cores, as 44 originais preservadas), mestre v2 de 52 px, 12 animações e 89 quadros. O Profanado v1 e seu pacote continuam arquivados byte a byte. A fixture `codex/fixtures/peregrino_profanado_mapa.json` permite verificar o pacote antigo sem depender da roupa atualmente equipada.

`px_por_quadro` é opcional, numérico e positivo. Patrulha/perseguição usam 4 px de referência por quadro; acumulam deslocamento horizontal pela escala fixa 0,9, conservam a fase entre as duas marchas e não avançam só com o tempo. Teleportes ≥48 px não contam como passos; idle limpa o acumulador. Pacotes sem esse campo mantêm a cadência temporal. Tolerância numérica de 0,001 px nos limites de quadro; arte final em pixels inteiros.

Cajado e sinos substituem a lâmina visual; penitência crava o cajado no chão e usa aviso vermelho. Os outros golpes usam aviso pálido. Cada área ACTIVE combina arco em polígono, corpo próximo da arma em retângulo e segmento do cajado; recortados à frente e acima do chão. Os seis recursos de ataque, suas fases, parry, dano e IA continuam originais.

Hurtbox sugerida/aplicada: raio 7 e altura 48 px (capuz/tronco sem galhos/arma), raio 7,777778 e altura 53,333333 unidades; centro Y=−11,166667, pés Y=15,5. O colisor de locomoção mantém raio 7/altura 31 unidades. F3 desenha a hurtbox e áreas acima dos sprites/FX, para não ocultar as linhas de inspeção.
