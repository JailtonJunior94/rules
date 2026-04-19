---
name: confluence-changelog-publisher
version: 1.0.0
description: Publica changelogs no Confluence a partir de CHANGELOG.md ou de git log estruturado. Use quando precisar sincronizar notas de release com o Confluence. Nao use para gerar o changelog — use github-diff-changelog-publisher para isso.
---

# Confluence Changelog Publisher

## Procedimentos

**Etapa 1: Preparar o conteudo**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Ler `CHANGELOG.md` ou receber o changelog como entrada direta.
2. Identificar versao, data e secoes (Added, Changed, Fixed, Removed).
3. Converter Markdown para formato compatível com o editor Confluence (storage format).

**Etapa 2: Verificar credenciais e pagina alvo**
1. Verificar `CONFLUENCE_URL`, `CONFLUENCE_TOKEN`, `CONFLUENCE_SPACE_KEY` via ambiente.
2. Identificar a pagina Confluence alvo (por ID ou titulo).
3. Verificar se a pagina existe; se nao, criar nova pagina pai conforme configurado.

**Etapa 3: Publicar**
1. Fazer GET na pagina para obter a versao atual.
2. Incrementar versao e fazer PUT com o novo conteudo.
3. Registrar URL da pagina publicada.

**Etapa 4: Confirmar publicacao**
1. Retornar URL da pagina atualizada.
2. Listar versoes publicadas no historico.

## Tratamento de Erros

* Se autenticacao falhar (401/403), instruir renovacao do token sem logar o atual.
* Se a pagina nao existir, perguntar antes de criar uma nova estrutura.
* Nao sobrescrever conteudo manual sem confirmacao quando a pagina tiver edicoes recentes.
