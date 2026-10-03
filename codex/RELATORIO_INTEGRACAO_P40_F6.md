# Tarefa 4.5 — Peregrino Profanado

Peregrino equipado no **cemitério e no Bosque (F9)**, na cópia `integracao-p40`, branch `feature/integracao-p40`. IA, tuning, tempos/dano, colisor de locomoção e física do jogador preservados. Commit/push restritos ao branch; sem merge.

## Arte e contatos

Pacote aprovado copiado byte a byte: **12 animações, 160 arquivos**. Estados usam idle, patrulha, alerta, perseguição, dano, ruptura e morte; ataques selecionam os quadros pela fase/ID reais. O corte duplo usa f3/f4 na primeira parte e f8/f9 na segunda, com dois UIDs e danos reais de 10/12; nenhum acerto duplicado por parte. Avisos pálidos nos quatro golpes aparáveis; penitência vermelha e não aparável. Camadas atrás/frente, sombra única, pixels inteiros e ×1 NEAREST; arma provisória oculta com o pacote ativo.

Hurtbox **raio 7 / altura 44 px**, pela escala fixa: raio **7,777778**, altura **48,888889** unidades; centro Y=−8,944444, pés Y=15,5. A anterior tinha raio 7/altura 31 **unidades**, projetados em 6,3/27,9 px. A área nova sobe **16,1 px / 0,503125 m** e aumenta o diâmetro em 1,4 px. Sondas 30/36/43 px acima dos pés agora acertam; a de 47 px continua fora. Colisor de locomoção mantém 7/31 unidades. Hurtbox fixa de 44 px nos estados vivos (variante opcional 34 na ruptura não ativada); morte desliga, R restaura, fallback volta à área antiga.

**108 ensaios estáticos** contra o Carrasco, seis recursos de ataque, distâncias 8/18/30/40/50/65 px e elevações 0/24/48 px: **42 → 45 acertos, 31 resultados alterados**. Com pés na mesma altura:

| Golpe | Antes: distâncias que acertam (px) | Agora (px) |
|---|---|---|
| Corte e cada parte do duplo | 8, 18, 30 | 8, 18, 30, 40, 50 |
| Estocada / investida | 8, 18, 30, 40 | 18, 30, 40, 50 |
| Penitência | 8, 18, 30 | 18, 30, 40, 50 |

Todos ficam fora a 65 px. Estocada/investida/penitência deixam folga no ensaio colado de **8 px / 0,25 m**; ele sobrepõe os colisores físicos e serve para medir geometria. IA/dano não foram compensados. Detalhes de altura em `COMPARACAO_GEOMETRIA.json`; balanceamento futuro registrado no plano.

## Leitura em ×1

Idle tem 50 px de corpo contra 48 do Pequeno A (~1,04×). Manto vermelho e máscara pálida se distinguem do cenário; lâmina e aviso ficam claros. Ruptura entra uma vez e mantém o ajoelhado (loop f3–f6), mas o brilho pequeno fica discreto. Morte cai para frente e segura f7, sem a rotação antiga; silhueta baixa se mistura com chão escuro. **Sem retoque de arte.** Postura ainda regenera no HUD após a morte, comportamento preexistente do principal registrado para revisão; não reativa o inimigo/hurtbox.

Corvo **ave** e Raiz seguem provisórios. O pacote humanoide do Corvo, reclassificado como máscara jogável, não foi usado.

## Validação e evidências

- **Antes/depois: 22/24 suítes aprovadas, 1865 PASS em cada execução.** Mesmas duas falhas antigas: `verify_carrasco_gif_test` (sprite nulo) e `verify_milestone8_2` (propriedade legada `sprite`).
- **Suíte real: 204 PASS, zero falhas.** Manifesto/hashes, fases/duplo, áreas e espelho, deduplicação, recortes, hurtbox/pés, morte/ruptura/reset, fallback e ambas as salas. Suíte do pacote falso mantém 70 PASS.
- Fixture F2 congelava o owner e omitia a consulta de contato nova: passa a chamar `resolve_frame_contact`, como a produção. Quatro falhas iniciais, revisão e logs preservados; nenhum ajuste de IA. Fixture F5 testa ausência explícita agora que existe pacote real.
- **SHA256 preservado:** ZIP aprovado `5649f946e9c03dcc63461136844a545afee8c8b5b1ee7a6f507308ade987c013`, 160 cópias idênticas; P40 (1583), prova (1550), checkout original (770), Bosque (48), cenas de inimigos (4), scripts IA/tuning (12), recursos de ataque (29), Pequeno A (407) e evidências F5 (96). Só o mapa do Peregrino muda entre os grupos protegidos; main local/remoto conserva `ef24b5561cacb823d1f719370c29d82522cb5b58`.
- **Clipe 20 s:** 960×540/30 fps, 600 quadros decodificados sem erro; corrida/pulo/dash, cinco golpes da IA, parries, leve/pesado, ruptura e morte; dois acertos reais no Peregrino, 49 HP recebidos. Quatro grupos ON. Entradas programadas, jogador posicionado no início, hitstop virtual de 60 Hz só na exportação; sem dano/vida artificial no clipe.
- Prints F3 dos **cinco ataques**, com duas partes do duplo (seis PNGs), avisos e poses normal ×1. Fotos diagnósticas isolam o ator e usam ataques/callbacks originais; clipe usa combate real. Índice `CAPTURAS.md`, README e launcher mantidos nesta cópia.

Entrega encerrada para avaliação.
