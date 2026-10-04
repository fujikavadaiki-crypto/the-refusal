# 4.8b4 — proposta estática f0

Revisão em `arte_fonte/forma_humana_v1/poses_chave_48b4/`, seguindo o manual §§6.4–6.5. Somente f0; f4/f2/f6 e todas as revisões anteriores preservadas.

Reconstruí a perna recolhida com coxa curta, um joelho intermediário e canela diagonal retornando à bota elevada. A silhueta inteira foi conferida a ×1 antes do sombreamento. O joelho está 7 px acima do chão, contra 3 px na 4.8b3; a sola elevada fica 6 px acima do chão. As distâncias entre articulações são 5,39 px na coxa e 7,21 px na canela. A bota curta mantém sola e grupos de luz/sombra; a capa original cobre parte do cano.

| Ponto recolhido | 4.8b3 | Proposta | Diferença |
|---|---|---|---|
| Quadril | (41,43) | (41,43) | (0,0) |
| Joelho | (40,52) | (39,48) | (−1,−4) |
| Tornozelo | (34,47) | (33,44) | (−1,−3) |
| Centro da sola | (31,51) | (32,49) | (+1,−2) |

Y aumenta para baixo. O limite anterior de 2 px foi removido da conferência. São pontos novos de uma pose estática; **não há alegação de trajetória idêntica**. Sola apoiada (52,55), quadris e a perna de apoio inteira são idênticos à 4.8b3.

79 pixels RGBA alterados, todos na perna recolhida/bota; zero em cabeça, tronco, capa, braços, espada e apoio. Máscaras e composição reproduzível comprovam o escopo. Canvas 96 × 64, âncora (40,56), pixels inteiros, NEAREST, 23 cores opacas da paleta oficial e alpha 0/255; um componente conectado e nenhuma cor isolada. Pose neutra recomposta igual ao mestre aprovado; mestre e conceito intactos. Segunda geração: 20 arquivos reproduzidos byte a byte.

Entregas em `codex/evidencias_forma_humana_48b4/`: f0 completa ×1/×4 sobre cinza, comparação 4.8b3/proposta ×1/×4, recorte ×8 com o mestre e folha auxiliar de articulações. Na folha auxiliar, círculo branco indica o joelho antigo; quadrado branco, a sola antiga. PNG transparente, variantes, rig, pose, linhas de pixels e máscaras na subpasta da revisão.

Testes antes/depois: 25 suítes, 23 aprovadas e 2.069 verificações; somente as falhas antigas aceitas `verify_carrasco_gif_test` e `verify_milestone8_2`. Peregrino real: 200 verificações aprovadas antes/depois. Resultados idênticos, sem novas falhas. A conferência específica de f0 também passou.

Auditoria SHA256 antes/depois: 7.299 registros protegidos sem diferenças; 609 arquivos de arte/evidências anteriores conferidos separadamente, incluindo f4/f2/f6. Diretor e kit pendente intactos e fora do commit; alterações externas do Diretor registradas separadamente, sem diferenças nesta etapa. Main e checkout original preservados. Manifesto SHA256 das entregas e conferência dos bytes no stage antes do commit.

Oito quadros, tempos, cadência de 6 px/quadro, velocidades e física permanecem intactos. Sem GIF/vídeo, outras poses, ciclo completo ou instalação. 4.8c continua em espera. Avaliação visual desta única pose pendente; commit/push somente da revisão, ferramentas e evidências em `feature/integracao-p40`.
