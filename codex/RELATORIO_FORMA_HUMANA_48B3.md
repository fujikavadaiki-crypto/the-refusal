# 4.8b3 — propostas estáticas f0/f4

Somente f0/f4 redesenhadas, em `arte_fonte/forma_humana_v1/poses_chave_48b3/`. A 4.8b2 permanece intacta, incluindo f2/f6 como propostas. Segui o manual §§6.4–6.5: variantes próprias para a pose dobrada, sem girar recortes verticais nem suavizar o gancho anterior.

A coxa recolhida desce do quadril até um joelho único; a canela volta diagonalmente ao calcanhar elevado. O espaço entre coxa e canela abre a dobra. A bota mantém cano, pé curto, sola e grupos de sombra/luz; a capa continua cobrindo parte do cano da bota distante. Na perna de apoio, a calça desce em uma diagonal contínua até o cano; a sola mantém o mesmo contato com o chão.

| Pose | Sola elevada: 4.8b2 → proposta | Delta | Apoio: antes = depois |
|---|---|---|---|
| f0 | (29,52) → (31,51) | (+2,−1) px | (52,55) |
| f4 | (32,52) → (34,51) | (+2,−1) px | (49,55) |

Coordenadas no canvas 96 × 64; Y aumenta para baixo. A margem autorizada é de 2 px por eixo. Quadris preservados: próxima (44,43), distante (41,43). Joelho recolhido: f0 (40,52), f4 (43,52); tornozelo: f0 (34,47), f4 (37,47). O joelho fica abaixo do calcanhar alto, dando uma flexão real.

Alterações RGBA frente à 4.8b2: 135 pixels em f0, 116 em f4; **zero fora das pernas/botas**, zero em cabeça, tronco, capa, braços e espada. As máscaras registram corpo protegido, membros e diferenças. Âncora (40,56), pixels inteiros, NEAREST, 23 cores opacas da paleta oficial, alpha 0/255, um componente conectado e nenhuma cor isolada. A pose neutra recomposta reproduz o mestre RGBA; mestre e conceito preservados. Variantes, pivôs, articulações e composição registrados; segunda geração reproduziu 28 arquivos byte a byte.

Evidências em `codex/evidencias_forma_humana_48b3/`: comparação 4.8b2/proposta ×1/×4 sobre cinza; poses individuais ×1/×4; recorte ×8 com o mestre; folha auxiliar de articulações (quadrado branco = sola elevada antiga), verificação técnica e reprodução SHA256. Os PNGs transparentes e máscaras estão na subpasta da revisão.

Testes antes/depois: 25 suítes, 23 aprovadas, 2.069 verificações; somente `verify_carrasco_gif_test` e `verify_milestone8_2`, falhas antigas de arte aceitas no manual. Pacote real do Peregrino: 200 verificações aprovadas antes/depois. Resultados idênticos, sem novas falhas. A conferência específica das duas poses também passou.

Auditoria SHA256 antes/depois: 7.191 registros protegidos, sem diferenças; 503 arquivos de arte/evidências anteriores explicitamente conferidos, incluindo 12 arquivos de f2/f6. As alterações externas do Diretor têm registro separado e vazio. Diretor e kit pendente permanecem fora do commit; main e checkout original preservados. `SHA256_ENTREGAS.json` registra os arquivos novos; a conferência do stage exige que seus bytes coincidam com os arquivos auditados e permite somente adições no escopo desta revisão.

Contrato existente intacto: oito quadros, 41,67 ms, 6 px/quadro e velocidades humanas. Somente estas duas poses estáticas: sem GIF/vídeo, ciclo completo ou instalação. 4.8c continua em espera. Avaliação visual pendente; commit/push restrito à revisão, ferramentas e evidências em `feature/integracao-p40`.
