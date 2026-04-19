# Persistência (Node/TypeScript)

## Objetivo
Manter acesso a dados explícito, testável e isolado do domínio.

## Diretrizes

### Repository
- Repository encapsula acesso a dados e expõe operações do domínio, não queries genéricas.
- Repository concreto pertence à camada de infraestrutura.
- Não vazar abstrações de ORM (Prisma client, Sequelize models, TypeORM entities) para fora do repository.

### Transactions
- Gerenciar transações na camada de aplicação (use case), não no repository individual.
- Usar `prisma.$transaction()`, `knex.transaction()` ou equivalente com callback ou interactive mode.
- Não abrir transação para leitura simples sem necessidade de consistência.

### Connection Management
- Configurar pool de conexões com limites explícitos (ex: `pg` pool `max`, Prisma connection limit).
- Fechar conexões ao desligar o processo (graceful shutdown).
- Usar `AbortSignal` ou timeout em queries longas quando suportado.

### Migrations
- Migrations devem ser versionadas, idempotentes e auditáveis.
- Usar a ferramenta do ORM adotado (`prisma migrate`, `knex migrate`, `typeorm migration`) ou ferramenta standalone.
- Separar migrations de esquema (DDL) de migrations de dados (DML) quando possível.
- Não rodar migrations destrutivas automaticamente em produção.

### Queries
- Preferir queries tipadas (Prisma, Kysely) a query builders sem tipagem.
- Usar parametrização para evitar SQL injection — nunca concatenar input em queries.

## Riscos Comuns
- Repository que retorna modelos do ORM em vez de entidades de domínio.
- Transação sem tratamento de erro e rollback automático.
- Connection leak por pool não fechado no shutdown.

## Proibido
- SQL injection por concatenação de input.
- Domínio importando pacote de ORM ou driver.
- Transação sem timeout.
