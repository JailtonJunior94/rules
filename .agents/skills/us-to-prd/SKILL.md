---
name: us-to-prd
version: 1.0.0
description: Converte User Stories brutas em um PRD estruturado com objetivo, escopo, restricoes e requisitos funcionais numerados. Use como etapa anterior ao create-prd quando a entrada for historias de usuario (formato "Como <persona>, quero <acao>, para <valor>"). Nao use para criar PRDs a partir do zero sem historias de usuario.
---

# User Stories para PRD

## Procedimentos

**Etapa 1: Receber e analisar as User Stories**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Coletar todas as User Stories fornecidas (formato livre ou "Como/Quero/Para").
2. Identificar personas, acoes e valores de negocio em cada historia.
3. Agrupar historias por tema ou modulo funcional.
4. Listar ambiguidades e lacunas que precisam de esclarecimento antes de prosseguir.

**Etapa 2: Derivar requisitos funcionais**
1. Converter cada historia em um ou mais requisitos funcionais (RF-nn).
2. Numerar sequencialmente a partir de RF-01.
3. Cada RF deve ser: atomico, testavel, sem detalhes de implementacao.
4. Identificar criterios de aceite para cada RF.

**Etapa 3: Estruturar o PRD**
1. Redigir as secoes: Objetivo, Escopo, Restricoes, Usuarios-alvo, Requisitos Funcionais.
2. Adicionar secao de Requisitos Nao-Funcionais quando identificados nas historias.
3. Incluir a lista original de User Stories como apendice para rastreabilidade.
4. Salvar em `tasks/<slug-feature>/prd.md`.

**Etapa 4: Validar com o solicitante**
1. Apresentar o PRD gerado para revisao.
2. Destacar suposicoes feitas na conversao de historias para requisitos.
3. Aguardar aprovacao antes de prosseguir com `create-technical-specification`.

## Tratamento de Erros

* Se as historias forem incompletas ou contraditórias, listar os conflitos e perguntar antes de converter.
* Se uma historia nao tiver valor de negocio claro, marcar como `RF pendente` e pedir esclarecimento.
* Nao inferir requisitos tecnicos (ex: "usar PostgreSQL") a partir de historias que nao mencionam tecnologia.
