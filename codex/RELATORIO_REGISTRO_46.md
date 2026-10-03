# Tarefa 4.6 — Registro da arte-fonte

Manual lido integralmente e adotado como referência principal. Registro dos **51 arquivos de `arte_fonte/`**, incluindo `.gdignore` vazio: quatro folhas v2, 12 recortes, 12 mestres ×1, 12 prévias ×4, seis comparações de escala, alturas, paleta JSON/GPL e ferramenta. `codex/MANUAL_CODEX.md` e todos os arquivos fornecidos conservam seus bytes originais. A seção 17 do histórico já existia e permaneceu intacta.

## Reprodução

Executado o comando solicitado, com saída em `.godot/registro_46/reproducao`:

```text
python arte_fonte/ferramentas/reduzir_referencia.py lote arte_fonte/referencias/inimigos_v2/recortes arte_fonte/inimigos_mestre_x1/alturas_alvo.json .godot/registro_46/reproducao
```

**12/12 mestres e 12/12 prévias reproduzidos**, com dimensões, pixels e SHA256 do conteúdo RGBA idênticos. Alturas correspondem à tabela; mestres têm alfa binário e somente cores da paleta. JSON e GPL coincidem: 62 cores, mantendo as 44 originais do Carrasco.

Os PNGs reexportados não têm o mesmo SHA256 do arquivo: faltam os metadados de origem `caBX` e a codificação/compressão difere. As imagens fornecidas foram preservadas. Ambiente: Python 3.12.14, NumPy 2.3.5, Pillow 12.3.0 e SciPy 1.18.1, esta isolada na pasta temporária ignorada pelo Git. A primeira tentativa parou ao carregar SciPy; a execução final terminou com código 0.

## Testes e preservação

- **Antes/depois: 23/25 suítes aprovadas; 2069 PASS em cada rodada; zero regressões.** Falhas antigas aceitas: `verify_carrasco_gif_test` (sprite nulo) e `verify_milestone8_2` (propriedade legada `sprite`).
- Suíte do pacote real: **204 PASS**. O manual cita 201; foi registrado sem edição, conforme o escopo desta tarefa.
- **SHA256: zero alterações** nos 51 arquivos de arte, manual, histórico, P40 (1578 arquivos), prova (1550), checkout original (770), pacotes aprovados (3) e integração anterior (1839, incluindo jogo, Bosque e evidências anteriores).
- Auditoria exclui `.git`, `.godot`, `__pycache__` e o `runtime/` gerado do P40; listas e hashes estão em `evidencias_registro_46/PRESERVACAO_*.json`.
- Main local/remoto conserva `ef24b5561cacb823d1f719370c29d82522cb5b58`. Registro restrito a `feature/integracao-p40`; commit/push somente desse branch, sem merge.

Conferência, inventário, reprodução e logs antes/depois em `codex/evidencias_registro_46/`. Jogo preservado. Entrega encerrada para avaliação.
