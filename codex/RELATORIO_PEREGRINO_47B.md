# Tarefa 4.7b — Peregrino Corrompido (arte)

Foram refeitos somente patrulha, perseguição, morte e ruptura: **31 quadros**. IA, tempos, dano, hitboxes, hurtbox, colisor, sombras e efeitos de ataque mantidos. A comparação integral do manifesto admite apenas a troca dos 31 hashes dos corpos.

- **Marcha:** pernas e botas alternam claramente; o pé próximo passa de +10,5 px em f0 para −5,5 px em f4, medido nos pixels da sola. O pé levanta 7 px na passagem; o corpo oscila 1 px. Manto/musgo e sinos acompanham o quadro anterior. As duas marchas mantêm oito quadros e **4 px por quadro por distância**.
- **Morte:** começa de joelhos e tomba para a frente. O capuz/rosto são a peça original do rig, inclinada 20° em NEAREST, sobre um manto dobrado com musgo. Cajado e sinos caem separados, sem braço nem peça em L. Todas as cores dos 31 quadros já existem no mestre limpo de pé; nenhuma cor rosada nova. Os quadros finais têm dois componentes intencionais: corpo e cajado, sem pixels soltos.
- **Ruptura:** pose ajoelhada; o capuz fica por cima do braço/pano para preservar a caveira. Entrada, duração dos sete quadros e início do laço em f3 mantidos. Nenhum pixel dos quatro estados fica abaixo da âncora dos pés.

**Leitura em ×1:** conferida na sala real a 960×540, zoom 0,9. A caveira clara, a borda do capuz e o musgo permanecem reconhecíveis sobre o chão escuro; o cajado fica separado ao lado. A foto aciona o callback de morte e imobiliza os atores apenas para capturar o último quadro, sem mudanças no jogo.

## Evidências e testes

- `codex/evidencias_peregrino_47b/COMPARACAO.md`: links dos oito GIFs ×4, antes/depois das quatro animações, e foto nativa da morte.
- `QUADROS_DEPOIS_x1.png`: todos os novos quadros em pixels nativos; folhas ×4 e peças/poses em `arte_fonte/peregrino_corrompido_v1/ajuste_47b/`.
- Antes e depois: **23/25 suítes aprovadas, 2.069 PASS em cada rodada, nenhuma regressão**. As duas falhas aceitas continuam idênticas: `verify_carrasco_gif_test` (texture_filter de instância antiga ausente) e `verify_milestone8_2` (campo sprite da arte antiga).
- Suíte do pacote real: **200 PASS**. Checagem de arte: hashes, âncoras, paleta, componentes, ausência de pixels isolados, rosto/musgo em cada quadro, troca dos pés no raster, subida/descida do corpo e contrato integral. Reprodução por rig: **31/31 PNGs idênticos por SHA256**.
- GIFs antes copiados sem alteração das evidências aprovadas da 4.7. GIFs antes/depois têm as mesmas durações exportadas; o formato GIF arredonda para 10 ms e junta os dois últimos quadros idênticos da morte. Os oito quadros/tempos do jogo permanecem no manifesto.

## Auditoria e escopo

SHA256 confirmou intactos todos os arquivos protegidos do jogo (incluindo Bosque, IA/tuning, áreas de combate, Pequeno A e arte Profanado arquivada), os 58 corpos não revisados, 31 FX e sombra do Corrompido, mestres e peças anteriores e evidências 4.7. Referências: **1.550 arquivos em prova, 1.578 no P40, 770 no checkout original, 3 pacotes aprovados e o histórico**; main e estado do checkout original preservados.

**Alteração externa registrada:** `codex/diretor/DIARIO_DIRETOR.md`, já não versionado no início, recebeu uma nova seção de abertura do Diretor durante esta tarefa. Nenhuma operação desta tarefa escreveu nele. Seus hashes antes/depois estão na auditoria; o arquivo fica em disco e fora do commit, junto de `arte_fonte/kit_rig/` e dos demais arquivos do Diretor. Por isso a preservação integral do diretório registra essa diferença, enquanto a preservação dos arquivos sob responsabilidade desta tarefa está confirmada.

O gerador anterior agora encaminha geração/verificação para a revisão 4.7b, evitando restaurar as poses rejeitadas ou regravar as evidências antigas. Somente ferramentas de arte/teste foram acrescentadas; nenhum script de jogo mudou. Trabalho e push restritos a `feature/integracao-p40`, sem merge no main.

Para conferir novamente: `python arte_fonte/ferramentas/gerar_peregrino_corrompido.py --verify`; `python codex/verificar_peregrino_47b.py new` para o pacote, ou `after` para as 25 suítes. Para jogar: `JOGAR_INTEGRACAO.cmd`.

Entrega encerrada para avaliação.
