# Tarefa 4.8b2 — quatro propostas estáticas de pernas

Propostas em `arte_fonte/forma_humana_v1/poses_chave_48b2/`, seguindo o manual §§6.4–6.5. A 4.8b1 rejeitada e todas as evidências anteriores foram preservadas.

Redesenhei as silhuetas de f0/f2/f4/f6 como oito variantes inteiras de perna/bota, com linhas de pixels próprias de cada pose. F0/f4 receberam uma flexão mais explícita da perna recolhida. F2/f6 receberam um desenho contínuo da perna elevada e botas inclinadas, com grupos de luz/sombra do mestre. A roupa e a espada mantêm a sobreposição original. A folha auxiliar expõe quadril, um joelho, tornozelo e ponto da sola de cada perna.

Cabeça, tronco, capa, capuz, braços e espada: zero pixels RGBA alterados. Quadris e poses/oscilações do corpo/capa iguais à 4.8b1. Só pernas e botas mudaram: 104/90/145/114 pixels em f0/f2/f4/f6. As máscaras comprovam zero alterações fora desses membros.

| Pose | Sola próxima (x,y), antes = depois | Sola distante (x,y), antes = depois |
|---|---|---|
| f0 | (52,55) | (29,52) |
| f2 | (40,55) | (45,50) |
| f4 | (32,52) | (49,55) |
| f6 | (48,50) | (37,55) |

Canvas 96 × 64, âncora (40,56), pixels inteiros, 23 cores opacas da paleta oficial e alpha apenas 0/255. Cada bota fica na referência compacta de 9 × 6 px; as solas elevadas podem inclinar, mas seus centros e alturas permanecem iguais. Um componente conectado e nenhuma cor isolada em cada pose. Rig/variantes/poses reproduzem os PNGs RGBA. Mestre com SHA256 `204432d31a2d8890c6def7b6fd81b56972ce482b5eca82fa3de878ebe2dcf988` intacto; pose neutra e idle preservados.

Entregas em `codex/evidencias_forma_humana_48b2/`: comparação completa lado a lado ×1/×4; propostas individuais sobre cinza ×1/×4; recorte das pernas ×8 com o mestre na mesma ampliação; folha auxiliar de articulações; máscaras, verificação técnica e reprodução por SHA256.

Testes antes/depois: 25 suítes, 23 aprovadas e 2.069 verificações; somente as falhas antigas aceitas `verify_carrasco_gif_test` e `verify_milestone8_2`. Peregrino Corrompido: 200 verificações aprovadas antes/depois. Resultados idênticos, sem novas falhas. Segunda geração: 44 arquivos de proposta/evidência reproduzidos byte a byte.

Auditoria SHA256: 7.067 arquivos protegidos conferidos, sem alterações, incluindo jogo, checkout original, arte/evidências anteriores, mestre/conceito, referências, pacotes, arquivos do Diretor e kit pendente. As diferenças externas do Diretor têm registro separado e vazio nesta etapa; seus arquivos e o kit permanecem fora do commit.

Somente estas quatro poses estáticas foram propostas. Contrato de oito quadros, 41,67 ms, 6 px/quadro e velocidades existentes preservado. Arte não instalada; nenhuma mudança de jogo, física, colisão, combate ou mapa. 4.8c permanece em espera. Avaliação visual pendente antes de completar o ciclo ou gerar GIF/vídeo. Commit/push restrito a esta proposta, ferramentas e evidências em `feature/integracao-p40`.
