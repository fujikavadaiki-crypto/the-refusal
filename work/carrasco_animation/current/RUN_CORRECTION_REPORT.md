# Carrasco — correção da RUN_V2

## Entrega e escopo

Arquivo de trabalho: **Carrasco_RUN_V2_CORRECTED.blend**. Ação ativa: **RUN_V2_CORRECTED**.
Origem: `outputs/carrasco_run_v2_03/delivery/Carrasco_RUN_V2.blend`.
Blender portátil **4.5.14 LTS**, render Cycles, câmera ortográfica original, 1280×720, 30 fps.
Mesmo ciclo de 24 frames; quadro 25 repete a pose do quadro 1. A ação RUN_V2 permanece arquivada no arquivo atualizado.
O trabalho foi feito em uma cópia separada. Godot, Bosque B e assets de origem não receberam alterações.

## 1. Diagnóstico das pernas

### Causa encontrada

A leitura de transparência era causada por **aberturas reais na geometria interna das pernas/virilha**, visíveis quando a passada separava as coxas. O corpo e o tecido vieram fundidos; a preparação/separação funcional anterior deixou regiões sem uma superfície interna independente. Há também fragmentos de tecido ainda ligados à malha das pernas.

Evidências anteriores à correção:

- Principled BSDF: Alpha 1, sem ligação; Transmission 0.
- Texturas basecolor 4096×4096, normal e RM 2048×2048: canal alpha inteiramente 1.
- Render Cycles, compositor desligado, fundo do render opaco; backface culling desligado.
- O teste solid sem materiais reproduziu as aberturas (`captures/before_solid_legs_19.png`).
- A auditoria por posições coincidentes encontrou 407 bordas abertas no corpo, 397 abaixo da cintura, e 14 arestas non-manifold. Parte dessas bordas também corresponde à separação de tecido e armadura; a contagem não representa 407 buracos nas pernas.
- Alpha/sorting/render pass não explicam uma abertura que também aparece no modo solid. Não foi necessário alterar normals ou duplicar as faces originais para corrigir o defeito observado.

### Correção localizada

Adicionado **Carrasco_LowerBody_Continuity**, um revestimento interno fechado sob cintura, coxas e armadura. É composto por duas superfícies internas de perna e um pequeno fechamento pélvico, com **1.248 vértices / 2.484 triângulos**. O reparo possui **0 bordas abertas e 0 arestas non-manifold**.

Usa somente Hips, LeftUpLeg, RightUpLeg, LeftLeg e RightLeg do rig recebido. Pesos normalizados, preserve volume aplicado somente ao reparo e material opaco `Carrasco_Inner_Fabric_Opaque`. Nenhuma face do corpo original foi removida. Armadura, botas, UVs, normals e texturas existentes foram preservados.

Geometria de personagem preparada anterior: 19.402 triângulos. Arma: 9.658. Total desses meshes antes/depois: **29.060 → 31.544 triângulos**; o aumento é exclusivamente o revestimento local. O HIGH POLY não foi modificado.

## 2. Diagnóstico das mãos e arma

O WeaponSocket já estava parentado à mão e a empunhadura já tinha posição relativa consistente. A falha de leitura vinha principalmente da **pose alta e fechada do braço armado**, do punho, dos dois punhos diante do peito e da lâmina quase vertical com material branco uniforme.

A pose foi ajustada para **carga baixa ao lado do quadril, com lâmina inclinada para trás e balanço limitado**. A mão direita acompanha a arma pelo mesmo socket; a transformação local de socket, arma e referência de apoio foi preservada.

Alterações na ação, usando os eixos de trabalho do arquivo (os números abaixo são parâmetros de rotação, não medições anatômicas do cotovelo):

- RightArm: X = 7·cos(fase) − 4°, Y = 7°.
- RightForeArm: X = −40° + 3·sin(fase − 0,35), reduzindo a flexão da pose alta anterior.
- RightHand: X = 8°, reduzindo a aparência de punho quebrado na carga baixa.
- LeftArm: oposição preservada, X = −24·cos(fase) − 3°, Y = −5°.
- LeftForeArm: X = −62° − 7·sin(fase); LeftHand neutra.
- Nenhum bone dos dedos foi remodelado ou refeito. As mãos fechadas/gauntlets do candidato continuam sendo uma limitação para futuros gestos detalhados.

A arma de trabalho recebeu dois materiais simples opacos para leitura: **Carrasco_Weapon_Neutral_Steel** e **Carrasco_Weapon_Handle_Dark**. Não foram criados UVs, pintura de sangue ou textura final. O FBX original, geometria e escala da arma permanecem idênticos.

Verificação das poses 1–25: **0 pares de interseção entre a superfície da lâmina e corpo, manto, correntes ou reparo**; distância mínima da arma ao piso: **4.28 cm**. Esta verificação não exige ausência de contato no cabo, que deve estar dentro da empunhadura; também não é uma certificação de colisão contínua entre todos os subframes.

## 3. Postura e peso

A RUN_V2 tinha inclinação anatômica efetiva Spine→Neck de aproximadamente **5,8°**, apesar da inclinação nominal maior indicada anteriormente. A nova pose mede **8.99°–9.13°** durante o ciclo.

- Spine e Spine1: acréscimo de 2° cada no eixo de inclinação.
- Neck e Head: compensação de −2° cada, mantendo a cabeça mais estável.
- Pelvis/quadril, pernas, pés, fase da passada, compressão, impulso, voo e recuperação preservados.
- Todos os canais de Hips, UpLeg, Leg, Foot e ToeBase são idênticos aos anteriores.
- Diferença máxima medida na geometria original dos pés: **0,000328 mm**, compatível com arredondamento numérico. O ground point permaneceu idêntico.

## 4. Lista exata de alterações

| Elemento | Alteração |
|---|---|
| RUN_V2_CORRECTED | Cópia da RUN_V2; curvas de Spine, Spine1, Spine2, Neck, Head, RightArm, RightForeArm, RightHand, LeftArm, LeftForeArm e LeftHand regravadas. Spine2 mantém a pose recebida. |
| Carrasco_LowerBody_Continuity | Novo mesh local fechado; 2.484 triângulos; pesos somente nos 5 bones existentes descritos acima. |
| Carrasco_Inner_Fabric_Opaque | Material escuro, Alpha 1, roughness 0,86; bump procedural discreto. |
| Carrasco_Weapon_Neutral_Steel | Material aço simples, metallic 0,82, roughness 0,56; 3.498 faces da arma. |
| Carrasco_Weapon_Handle_Dark | Material cabo simples, metallic 0,15, roughness 0,72; 1.784 faces da arma. |
| Weights originais | **0 alterações** em corpo, manto e correntes. |
| Shape keys | **0 alterações** nos shape keys existentes. |
| Bones | **0 criados / 0 removidos**, total mantido em **65**. Rest pose e hierarquia idênticas. |
| WeaponSocket / LeftHandSupport_REFERENCE | Posição local, parentesco e escala preservados. |

Mudança estrutural limitada: acréscimo da superfície interna que faltava. Recriar o rig ou substituir o personagem não foi necessário.

## 5. Validação e comparação

- 24 frames renderizados com personagem completo e também em perfil lateral com manto, correntes e arma ocultados apenas na inspeção das pernas.
- Revisão visual dos 24 frames das pernas e da sequência completa; as aberturas que davam aparência transparente foram preenchidas.
- Comparação completa usa a mesma câmera, iluminação, resolução e frame da RUN_V2 anterior.
- Comparação das pernas usa a mesma câmera lateral em ambas as versões, ocultando os mesmos objetos. A câmera lateral de diagnóstico não modifica a câmera principal salva.
- Mãos/arma têm close-up antes/depois, enquadrado na empunhadura de cada pose.
- Pose do frame 25 coincide com a do frame 1: erro de fechamento geométrico medido **0 m** em corpo, manto, correntes, reparo e arma.
- Vídeos decodificados integralmente sem erro: 12 ciclos / 9,6 s / 30 fps; versão lenta 19,2 s, duplicação de quadros a 0,5×, sem poses geradas.
- Hashes de vértices, triângulos, pesos, UVs, normals, shape keys, imagens, rest bones, câmera, ground point e transformações locais dos sockets confirmam a preservação dos elementos existentes.

Evidência técnica: `CORRECTION_VERIFICATION.json`, `DIAGNOSIS_BEFORE.json`, `VIDEO_CHECK.json`, `GODOT_UNCHANGED.json`.

## 6. Avaliação sincera / limites

As correções desta entrega melhoram continuidade das pernas, pega/silhueta da arma e inclinação do tronco. A corrida conserva o contato dos pés já estabelecido.

Ainda existem fragmentos/tiras de tecido fundidos à malha original, com volume e bordas angulares em algumas poses. O manto e seus correctivos anteriores foram preservados; esta entrega não certifica ausência de todo clipping de tecido. As mãos recebidas continuam fechadas, e o acabamento da arma é provisório. A superfície interna resolve as aberturas desta corrida, mas não equivale à retopologia completa para todos os ataques/futuras poses extremas.

**Estado: correção implementada e validada tecnicamente, pronta para revisão visual. O rig completo não recebe classificação de aprovado para produção nesta entrega.** A próxima decisão deve partir da comparação fornecida, sem voltar ao pipeline 2D por recortes.

## 7. Arquivos entregues

- `Carrasco_RUN_V2_CORRECTED.blend` — cena/rig de trabalho atualizado, texturas do personagem empacotadas.
- `Carrasco_RUN_Corrected.mp4` — corrida completa, 1280×720.
- `Carrasco_RUN_Corrected_Slow_05x.mp4` — revisão em velocidade 0,5×.
- `Carrasco_RUN_Before_After.mp4` — comparação completa lado a lado, 1920×1080.
- `Carrasco_Legs_Solid_Diagnostic.mp4` — inspeção lateral das pernas.
- `Carrasco_Legs_Before_After.mp4` — comparação lateral das pernas.
- `captures/` — comparações nos frames 1, 7, 13 e 19; close-up mão/arma; folhas com todos os 24 frames e diagnóstico solid.
- `RUN_CORRECTION_REVIEW.html` — página de revisão com vídeos e capturas.
- `RUN_CORRECTION_REPORT.md` — este relatório.
- `CORRECTION_VERIFICATION.json`, `DIAGNOSIS_BEFORE.json`, `CANDIDATE_B.json`, `VIDEO_CHECK.json`, `GODOT_UNCHANGED.json`, `DELIVERY_MANIFEST.json` — evidências e inventário.

Scripts de diagnóstico, reparo, render, verificação e empacotamento foram criados somente em `work/blender_pipeline/run_v2_fix_*.py` deste workspace. Nenhum arquivo funcional do repositório do jogo foi alterado.

## 8. Preservação do projeto

Repositório em **main**, HEAD = origin/main = `ef24b5561cacb823d1f719370c29d82522cb5b58`; status Git limpo.
Preservados: projeto Godot, Bosque B, vídeo de fundo, Player/controller, câmera da room, escala, colisões, layout e gameplay. Não foram produzidos sprites nem feita integração no Godot nesta etapa.

Hashes SHA-256 de fontes preservadas:

- GLB: `d68702f5484503c730c77d253510bae0c33b619acba2893d349be43e5bbc4b0c`
- FBX: `0ede67a0738601441da99108e4b6fa387e44b9aa74670ff062e734bde897ba37`
- Blender RUN_V2 anterior: `ff7041b06232d23e8887a779db14e9d1c79a450e258930a9ab991b63d892d410`
