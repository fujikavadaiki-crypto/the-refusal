# Pacotes de inimigo — preparo da Tarefa 4.4

Os pacotes finais ainda não foram entregues. Após avaliação, extrair `pacote_inimigo_peregrino_v1.zip` em `assets/enemies/peregrino_v1/` e `pacote_inimigo_corvo_v1.zip` em `assets/enemies/corvo_v1/`, com `manifesto_sprites.json` diretamente nessas pastas. Os mapas em `data/enemies/` permitem ajustar nomes de animações sem alterar IA. Raiz também tem adaptador/fallback, sem pacote definitivo nesta fase.

## Manifesto

Mesmo formato do Pequeno A: `animacoes[]`, cada entrada com `id`, `loop`, `quadros[]`; cada quadro informa `arquivo`, `sha256`, `ms`, `ancora:[x,y]` e dimensões opcionais `largura/altura`. PNGs nativos, ×1 NEAREST, âncora em pixels inteiros. SHA256 confere bytes exatos ou remove somente o chunk caBX, como o Carrasco. Arquivos relativos ao pacote; caminhos externos/`..` são rejeitados.

`sombra` pode vir na animação ou no quadro, com arquivo/hash/dimensões/âncora próprios. Fica no terreno abaixo dos pés, reduz/clareia no ar e desaparece sem chão; nunca embutir sombra no corpo ou nos FX. `efeitos[]` usa o mesmo descritor de PNG, `fase` e seletor `quadro` opcional. Também aceita efeitos locais no quadro. Fases: WINDUP/PREP/PREPARACAO, ACTIVE/ATIVO, RECOVERY/RECUP/RECUPERACAO, ALL/TODAS.

Para ataques, marcar fases pelo campo `fase` do quadro ou por `ataque.fases.{PREPARACAO,ATIVO,RECUPERACAO}.quadros`. `hitbox` é opcional somente em ACTIVE: `retangulo:[x,y,w,h]`, `retangulos:[[...],...]`, `poligono:[[x,y],...]` ou `arco/lamina.poligono`, relativos à âncora. X positivo à frente, Y positivo para baixo. Recorte x≥0, decomposição convexa e espelho único. Os tempos da IA/ataques originais prevalecem: os quadros autorais são distribuídos dentro de cada fase, sem modificar seu tempo físico.

Um ataque com algum dado de hitbox usa exclusivamente seus quadros; quadro vazio não reativa a caixa antiga. Ataque/animação sem dados mantém fallback. Recuo, flash, sangue e hitstop usam o sistema comum da sensação, não precisam ser desenhados no pacote.

## Mapeamento

`*_mapa.json` contém `pacote`, `padrao`, `pes_world:[x,y]`, `estados:{NOME_DA_IA:animacao}` e `ataques:{id_do_tres:animacao}`. Pés seguem o colisor original: Peregrino Y=15,5, Corvo Y=8 e Raiz Y=9 unidades. Isso não altera cápsulas, IA, vida ou postura. Os mapas entregues listam todos os estados/IDs atuais, como ponto de partida.

Corvo aceita `projeteis:{corvo_cuspe_pestilento:cuspe_projetil}`. Essa animação tem PNG/âncora próprios e avança por `ms` durante o voo. Seus quadros de dano são ACTIVE e relativos à origem/âncora do projétil, com direção travada na trajetória. A animação do bico é distinta. Sem animação dedicada, o core e a área nativos continuam. Velocidade, duração, colisão com terreno e defesa permanecem originais.

`codex/fixtures/inimigo_falso_v1/` é **FALSO, apenas para testes**: quatro PNGs pequenos, idle/hurt/death e ataque com retângulo/polígono ACTIVE, FX e sombra separados. A sala normal não o usa. A suíte F5 injeta seu mapa em Peregrino, Corvo, Raiz e projétil, testa rejeição de hash/caminho/tempo/âncora/fase inválidos e restaura os mapas reais. F3 exibe polígonos dos inimigos quando um pacote válido fornecer áreas.
