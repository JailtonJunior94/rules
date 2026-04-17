# Segurança

- Rule ID: R-SEC-001
- Severidade: hard
- Escopo: Todo código, configuração, logs, runtime e providers.

## Objetivo
Definir o baseline de segurança para uma CLI que orquestra agentes e executa ações no filesystem.

## Requisitos

### Segredos
- Credenciais de providers devem vir de ambiente, config do sistema ou autenticação já feita pelo CLI do provider.
- Segredos não devem ser hardcoded, logados ou persistidos em `.orq/`.

### Filesystem
- Toda escrita deve ser intencional e auditável.
- Paths devem ser normalizados e validados antes do uso.
- O runtime deve evitar sobrescrever artefatos de runs anteriores sem política explícita.

### Execução de Comandos
- Subprocessos devem ser construídos com argumentos explícitos.
- Shell deve ser evitado quando a chamada puder ser feita diretamente.
- Comandos de git destrutivos ou publicações remotas são proibidos na V1, salvo pedido explícito do usuário fora do fluxo padrão.

### Input Externo
- YAML de workflow, input de arquivo e respostas de provider devem ser tratados como dados não confiáveis.
- Parsing e validação devem ocorrer antes de uso.

### Dependências
- Preferir bibliotecas pequenas, estáveis e mantidas.
- Cobra é o padrão para a CLI; evitar frameworks pesados para resolver problemas simples.

## Proibido
- Hardcode de token, segredo ou path sensível de usuário.
- Concatenação insegura de comandos shell.
- Persistir conteúdo sensível sem necessidade operacional clara.
