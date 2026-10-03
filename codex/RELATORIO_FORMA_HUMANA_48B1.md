# Tarefa 4.8b1 — desenho das pernas de run

Revisão isolada em `arte_fonte/forma_humana_v1/rig_48b1/`, sem sobrescrever a 4.8b ou instalar arte. Seguido o `codex/MANUAL_CODEX.md`. O mestre aprovado permanece com SHA256 `204432d31a2d8890c6def7b6fd81b56972ce482b5eca82fa3de878ebe2dcf988`.

## Alteração

Os recortes verticais de coxa/canela da 4.8b criavam quinas e excesso de volume quando a perna inclinava ou recolhia. Foram substituídos por 32 variantes orientadas das calças: dois segmentos de cada perna, em cada um dos oito quadros. Os joelhos foram ajustados localmente, mantendo quadris e tornozelos. A seção compartilhada entre coxa e canela limita o volume do joelho; o sombreamento distingue a perna próxima da distante. Conferidos especialmente f0/f4 e f2/f6 a ×1 e ampliados.

Botas compactas e seus pixels RGBA foram preservados, incluindo as solas e sua luz/sombra. Roupa/capa mantém a sobreposição original; cabeça, rosto, tronco, braços, mão/espada, mestre, pose neutra e idle permanecem intactos. Nenhum trabalho de mobilidade 4.8c foi encontrado nesta cópia.

## Movimento e pixels

Mantidos oito quadros, 41,67 ms por quadro, 6 px/quadro, canvas 96 × 64 e âncora inteira (40,56). As fases de apoio/passagem, trajetórias e alturas das solas, quadris, tornozelos, oscilação do corpo e atraso de um quadro da capa coincidem com a 4.8b. A oscilação discreta de 6 px permanece visível e não foi corrigida.

| Quadro | f0 | f1 | f2 | f3 | f4 | f5 | f6 | f7 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Pixels RGBA alterados, somente nas pernas | 91 | 42 | 29 | 53 | 48 | 26 | 51 | 83 |
| Pixels alterados fora da máscara | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Pixels alterados nas botas protegidas | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

`MASCARAS_POSES_SOLAS.json` registra as articulações antes/depois. `VERIFICACAO_PERNAS.json` confere as 16 solas, pivôs, hashes de variantes, pose neutra idêntica ao mestre, parâmetros dos ciclos e replay RGBA exato dos oito quadros pelo rig/poses salvos. As máscaras declaradas são calculadas pela propriedade das camadas originais e pelo corredor dos segmentos; a diferença real é conferida como subconjunto delas. Só a região das calças é editável. Paleta `paleta_bosque_v1`, 24 cores opacas nos quadros finais, alpha apenas 0/255, um componente conectado e nenhuma cor isolada em cada quadro.

## Entregas para avaliação

Em `codex/evidencias_forma_humana_48b1/`:

- `run_antes_x4.gif` — cópia exata da animação aprovada 4.8b; `run_depois_x4.gif` — revisão com o mesmo ritmo de apresentação.
- `run_quadros_x1.png` e `run_quadros_x4.png` — oito quadros completos.
- `PERNAS_MESTRE_COMPARACAO.png` — pernas do mestre junto de f0/f4/f2/f6.
- `PERNAS_ANTES_DEPOIS_MASCARA_x4.png` e `BOTAS_SOLAS_ANTES_DEPOIS_x4.png` — área de edição e comparação dos pixels preservados.
- `PREVIA_caminhada_corrida_20s.mp4` — PRÉVIA externa de 20 s, 600 quadros a 30 fps, simulação a 60 Hz; caminhada nos primeiros 10 s e corrida nos últimos 10 s, sobre o mesmo chão do cemitério. Velocidades humanas anteriores: 2,690217 m/s e 4,891304 m/s. Arte ×1, referência de zoom 0,9, pés visíveis e detalhe ×4 NEAREST, marcas fixas no chão e posição das solas. Não é captura de arte instalada.
- `PREVIA_MOVIMENTO_COMPARACAO.json` — os 600 registros de posição, velocidade, distância, quadro, direção e solas, além de todos os eventos de troca, são idênticos aos da 4.8b.
- `REPRODUCAO.json`, testes antes/depois e auditoria SHA256 — reprodução e preservação verificáveis.

## Testes e preservação

Antes/depois: 25 suítes, 23 aprovadas, 2.069 verificações aprovadas; somente as duas falhas antigas aceitas (`verify_carrasco_gif_test`, acesso à arte antiga `texture_filter`; `verify_milestone8_2`, acesso à propriedade antiga `sprite`). Suíte do Peregrino Corrompido: 200 verificações aprovadas antes/depois. Sem novas falhas ou alteração nos resultados.

Auditoria SHA256: 6.881 arquivos protegidos, incluindo projeto, arte/evidências anteriores, conceito/PNG/PROMPT, mestre, kit pendente, arquivos do Diretor, fontes P40/prova, pacotes e checkout original. Todas as diferenças são registradas em `PRESERVACAO_resultado.json`, com a lista do Diretor separada; não houve alteração externa do diário durante esta etapa. Kit e arquivos do Diretor já estavam não rastreados antes da tarefa e permanecem fora do commit.

Commit/push restrito a esta revisão, ferramenta, verificador, relatório e evidências em `feature/integracao-p40`. `main` e checkout original preservados. Não houve alteração de jogo, instalação de arte, física, colisão, velocidades, cadência, combate, mapas ou outros personagens. Etapa encerrada para avaliação das pernas, antes de prosseguir à 4.8c.
