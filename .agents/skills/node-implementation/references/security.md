# Segurança (Node/TypeScript)

## Objetivo
Proteger o sistema contra vulnerabilidades comuns em backends Node/TypeScript.

## Diretrizes

### Input Validation
- Validar e sanitizar todo input externo (request body, query params, headers, path params).
- Usar bibliotecas de validação tipada: `zod`, `joi`, `class-validator` ou equivalente.
- Limitar tamanho de request body (ex: `express.json({ limit: '1mb' })`).
- Não confiar em input do cliente para decisões de autorização.

### Autenticação e Autorização
- Autenticação em middleware, autorização no use case ou handler.
- Validar tokens (JWT, opaque) em cada request — não cachear decisão de autenticação.
- Verificar claims relevantes: expiração, audience, issuer.
- Aplicar princípio de menor privilégio em permissões e roles.

### Segredos
- Carregar segredos de variáveis de ambiente ou secret manager — nunca hardcoded.
- Não logar segredos, tokens ou credenciais em nenhum nível de log.
- Não expor segredos em mensagens de erro ou responses.

### HTTP
- Usar `helmet` para headers de segurança quando disponível.
- Configurar CORS com origins explícitos — não usar `*` em produção.
- Aplicar rate limiting em endpoints públicos (ex: `express-rate-limit`).

### SQL e Persistência
- Usar queries parametrizadas — nunca concatenar input em SQL.
- Preferir ORM ou query builder com parametrização automática.

### Dependências
- Rodar `npm audit` ou `pnpm audit` periodicamente em CI.
- Manter dependências atualizadas de forma controlada.
- Considerar `socket.dev` ou `snyk` para análise de supply chain.

## Riscos Comuns
- JWT validado apenas por assinatura sem verificar expiração ou audience.
- Rate limiting ausente em endpoint de login.
- Prototype pollution via merge de objetos sem sanitização.

## Proibido
- Segredo hardcoded em código ou arquivo commitado.
- SQL por concatenação de string com input externo.
- Response de erro expondo stack trace ou path interno.
- `eval()` ou `new Function()` com input do usuário.
