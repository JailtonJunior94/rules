---
name: prompt-enricher
version: 1.0.0
description: Enriquece e melhora prompts de usuario com contexto, restricoes e criterios de saida para uso com agentes de IA. Use quando um prompt for vago, incompleto ou precisar de estrutura para obter resultados determinísticos. Nao use para executar o prompt enriquecido — apenas para produzi-lo.
---

# Enriquecer Prompt

## Procedimentos

**Etapa 1: Analisar o prompt original**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Identificar a intencao principal, o contexto disponivel e o que falta.
2. Verificar se ha restricoes de output (formato, tamanho, linguagem) implicitas ou ausentes.
3. Listar ambiguidades que podem gerar respostas imprevisíveis.

**Etapa 2: Enriquecer o prompt**
1. Adicionar contexto relevante (linguagem, framework, restricoes do sistema).
2. Especificar o formato de saida esperado (JSON, markdown, codigo, lista).
3. Incluir criterios de aceitacao mensuráveis.
4. Adicionar exemplos de entrada/saída quando a tarefa for complexa (few-shot).
5. Limitar o escopo para evitar respostas excessivamente amplas.

**Etapa 3: Apresentar resultado**
1. Mostrar o prompt original e o enriquecido lado a lado.
2. Explicar cada adicao com justificativa curta.
3. Oferecer variantes quando multiplas abordagens forem igualmente validas.

## Tratamento de Erros

* Se o prompt original for contraditório, apontar o conflito antes de enriquecer.
* Se o contexto necessario nao estiver disponível, listar o que e necessario e perguntar.
* Nao adicionar restricoes que mudem o objetivo original sem confirmar com o usuario.
