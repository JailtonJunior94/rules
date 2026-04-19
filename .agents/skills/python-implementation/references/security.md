# Segurança (Python)

## Objetivo
Proteger o sistema contra vulnerabilidades comuns em backends Python.

## Diretrizes

### Input Validation
- Validar e sanitizar todo input externo (request body, query params, headers, path params).
- Usar Pydantic models para validação tipada em FastAPI. Usar Django forms/serializers em Django.
- Limitar tamanho de request body via configuração do framework.
- Não confiar em input do cliente para decisões de autorização.

### Autenticação e Autorização
- Autenticação em middleware ou dependency (FastAPI `Depends`), autorização no use case.
- Validar tokens (JWT, opaque) em cada request — não cachear decisão de autenticação.
- Verificar claims relevantes: expiração, audience, issuer.
- Aplicar princípio de menor privilégio em permissões e roles.

### Segredos
- Carregar segredos de variáveis de ambiente ou secret manager — nunca hardcoded.
- Usar `pydantic-settings` para configuração tipada com validação de secrets.
- Não logar segredos, tokens ou credenciais em nenhum nível de log.
- Não expor segredos em mensagens de erro ou responses.

### HTTP
- Configurar CORS com origins explícitos — não usar `allow_origins=["*"]` em produção.
- Aplicar rate limiting em endpoints públicos (ex: `slowapi`, Django ratelimit).
- Configurar headers de segurança via middleware.

### SQL e Persistência
- Usar queries parametrizadas — nunca concatenar input em SQL ou f-strings.
- Preferir ORM ou query builder com parametrização automática.
- Em SQLAlchemy raw queries, usar `text()` com bind params.

### Dependências
- Rodar `pip-audit` ou `safety` periodicamente em CI.
- Manter dependências atualizadas de forma controlada.
- Considerar `dependabot` ou `renovate` para atualizações automáticas.

## Riscos Comuns
- JWT validado apenas por assinatura sem verificar expiração ou audience.
- Rate limiting ausente em endpoint de login.
- Pickle desserialização de dados não confiáveis (RCE).

## Proibido
- Segredo hardcoded em código ou arquivo commitado.
- SQL por concatenação de string ou f-string com input externo.
- Response de erro expondo stack trace ou path interno.
- `eval()`, `exec()` ou `pickle.loads()` com input do usuário.
