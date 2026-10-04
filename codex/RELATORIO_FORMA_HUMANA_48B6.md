# 4.8b6 — proposta estática de run f0, 48 px

Uma única pose em `arte_fonte/forma_humana_v1/pose_corrida_48b6/`. A fonte aprovada 4.8b5 e seu PROMPT permanecem intactos. Redução proporcional pela ferramenta do projeto: recorte de 1.068 × 1.038 px → 49 × 48 px, remoção do cinza por preenchimento conectado e quantização na paleta oficial. A redução usa BOX premultiplicado; todas as ampliações e a apresentação usam NEAREST.

Reutilizados os **329 pixels RGBA de cabelo/rosto do mestre**, apenas transladados (+9,+6), sem escala ou rotação. O olho branco destacado da referência não foi adotado. Couro, capa e botas mantêm grupos de luz/sombra. Lâmina reta com espessura vertical de 4 px na maior parte; somente os quatro últimos pixels longitudinais formam a ponta.

Após as observações do usuário, ampliei a canela de apoio e seu encaixe no cano. Para a perna elevada, adotei a construção do **último recorte enviado pelo usuário**, que corresponde à redução automática: joelho arredondado, canela contínua e bota compacta inclinada. A máscara de transparência dessa região é idêntica à referência escolhida; apenas os grupos de cores foram limpos. A comparação específica está em `RECORTE_USUARIO_VS_PROPOSTA.png`.

Canvas **96 × 64**, altura cabelo–sola apoiada **48 px** (Y=8…55), âncora **(40,56)** e chão **Y=55**. 26 cores da `paleta_bosque_v1`, alpha **0/255**, um componente conectado, contorno escuro contínuo e nenhuma cor isolada. Sem sombra embutida.

| Ponto novo | Apoio | Elevada |
|---|---|---|
| Quadril | (34,40) | (28,40) |
| Joelho | (36,47) | (26,45) |
| Tornozelo | (39,51) | (18,44) |
| Sola | (40,55) | (15,49) |

Na bota elevada, a sola é inclinada: o ponto registrado é seu pixel inferior. São pontos novos desta pose estática, sem alegação de trajetória idêntica às revisões rejeitadas.

Entregas: PNG transparente ×1/×4, redução intermediária, variantes de pernas, receita de pixels e pontos; comparação referência/redução/proposta, mestre e f0 4.8b4 rejeitada ao lado, escala com Carrasco, recorte do encaixe e folha auxiliar de articulações. Montagem ×1 sobre captura do cemitério em zoom 0,9, identificada como **PRÉVIA — arte não instalada**. Evidências em `codex/evidencias_forma_humana_48b6/`.

Testes antes/depois: **25 suítes, 23 aprovadas, 2.069 verificações**, resultados idênticos. Somente as falhas antigas aceitas `verify_carrasco_gif_test` e `verify_milestone8_2`. Pacote real do Peregrino: **200 verificações aprovadas** antes/depois. Conferência específica da pose aprovada; reprodução final de **26 arquivos byte a byte**.

Auditoria SHA256: **7.403 registros protegidos preservados**, incluindo **708 arquivos de arte/evidências anteriores** conferidos separadamente. Fonte/PROMPT 4.8b5, conceito/PROMPT, mestre, revisões, mapas, pacotes, protótipos, prova, main e checkout original intactos. Nenhuma alteração externa do Diretor detectada. Diretor e kit pendente ficam fora do commit.

Hashes completos estão em `VERIFICACAO_POSE.json`, `PRESERVACAO_antes.json`, `PRESERVACAO_depois.json` e `SHA256_ENTREGAS.json`. Mestre: `204432d31a2d8890c6def7b6fd81b56972ce482b5eca82fa3de878ebe2dcf988`; proposta ×1: `28d0f2438a34e78ccef3676432a522dd2e35ecff381ad52a016d95b571813852`.

Reprodução: `python arte_fonte/ferramentas/adaptar_corrida_forma_humana_48b6.py`; acrescente `--reduce` para repetir também a ferramenta de redução (numpy, Pillow e scipy). `--verify` confere o resultado. Suítes/auditoria: `python codex/verificar_forma_humana_48b6.py before|after|preserve-before|preserve-after|audit-art`.

Sem f4/outros quadros, GIF/vídeo, rig/ciclo atualizado ou instalação. Física, colisão, velocidades, tempos, cadência de 6 px/quadro, combate e demais personagens permanecem intactos. Commit/push somente da referência, proposta, ferramentas e evidências em `feature/integracao-p40`. **4.8c permanece em espera; parar para avaliação desta pose.**
