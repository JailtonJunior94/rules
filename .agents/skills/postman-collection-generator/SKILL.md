---
name: postman-collection-generator
version: 1.0.0
description: Gera colecoes Postman a partir de specs OpenAPI/Swagger, codigo de handler ou documentacao de API. Use quando precisar de colecao testavel para endpoints REST. Nao use para testar endpoints diretamente — gera apenas o artefato de colecao.
---

# Postman Collection Generator

## Procedimentos

**Etapa 1: Identificar fonte de entrada**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Verificar se ha arquivo OpenAPI/Swagger (`.yaml`, `.json`) disponível.
2. Se nao houver spec, ler handlers HTTP e derivar endpoints, metodos, parametros e schemas.
3. Listar endpoints a incluir na colecao.

**Etapa 2: Estruturar a colecao**
1. Criar estrutura de pastas por recurso ou modulo (ex: `Users`, `Orders`).
2. Para cada endpoint: metodo, URL com variaveis `{{base_url}}`, headers, body exemplo.
3. Adicionar variaveis de ambiente: `base_url`, `token`, `api_version`.
4. Incluir testes basicos por request: status code, estrutura da resposta.

**Etapa 3: Gerar o JSON Postman Collection v2.1**
1. Gerar JSON compatível com Postman Collection Format 2.1.
2. Usar `{{variavel}}` para valores que variam por ambiente.
3. Incluir exemplos de request e response para cada endpoint.
4. Salvar em `docs/postman/<collection-name>.postman_collection.json`.

**Etapa 4: Documentar variaveis de ambiente**
1. Gerar arquivo `<collection-name>.postman_environment.json` com variaveis e valores de exemplo.
2. Documentar quais variaveis sao obrigatorias antes de executar a colecao.

## Tratamento de Erros

* Se a spec OpenAPI estiver incompleta, gerar a colecao com o que existir e listar endpoints faltantes.
* Nao incluir tokens ou senhas reais nos valores de exemplo — usar placeholders descritivos.
* Se endpoints exigirem autenticacao complexa (OAuth2, MTLS), documentar o fluxo sem implementar.
