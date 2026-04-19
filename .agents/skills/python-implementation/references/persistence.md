# Persistência (Python)

## Objetivo
Manter acesso a dados explícito, testável e isolado do domínio.

## Diretrizes

### Repository
- Repository encapsula acesso a dados e expõe operações do domínio, não queries genéricas.
- Repository concreto pertence à camada de infraestrutura.
- Não vazar abstrações de ORM (modelos SQLAlchemy, querysets Django) para fora do repository.

### Transactions
- Gerenciar transações na camada de aplicação (use case), não no repository individual.
- Usar session scope explícito: `with Session() as session:` ou context manager equivalente.
- Em Django, usar `transaction.atomic()` no use case. Em SQLAlchemy, usar `session.begin()`.
- Não abrir transação para leitura simples sem necessidade de consistência.

### Connection Management
- Configurar pool de conexões com limites explícitos (SQLAlchemy `pool_size`, `max_overflow`).
- Fechar sessões e conexões de forma determinística via context managers.
- Em async (asyncpg, async SQLAlchemy), usar `async with` para garantir cleanup.

### Migrations
- Migrations devem ser versionadas, idempotentes e auditáveis.
- Usar Alembic (SQLAlchemy), Django migrations ou ferramenta standalone.
- Separar migrations de esquema (DDL) de migrations de dados (DML) quando possível.
- Não rodar migrations destrutivas automaticamente em produção.

### Queries
- Preferir queries tipadas via ORM ou query builder.
- Usar parametrização para evitar SQL injection — nunca concatenar input em queries.
- Para queries complexas, usar SQL raw com `text()` e bind params.

## Riscos Comuns
- Repository que retorna modelos do ORM em vez de entidades de domínio.
- Sessão não fechada causando connection leak.
- N+1 queries por lazy loading não controlado.

## Proibido
- SQL injection por concatenação de input ou f-strings.
- Domínio importando pacote de ORM ou driver.
- Transação sem timeout.
