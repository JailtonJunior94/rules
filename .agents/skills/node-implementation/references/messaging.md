# Messaging e Eventos (Node/TypeScript)

## Objetivo
Manter comunicação assíncrona confiável, rastreável e desacoplada do domínio.

## Diretrizes

### Produção de Mensagens
- Publicar eventos após a transação de domínio ser confirmada — não dentro da transação (salvo outbox pattern).
- Serializar mensagens com schema explícito (JSON com contrato documentado ou protobuf).
- Incluir metadata: event type, timestamp, correlation ID, source.
- Usar clientes tipados (`kafkajs`, `bullmq`, `amqplib`) com configuração explícita de serialização.

### Consumo de Mensagens
- Consumidores devem ser idempotentes — processar a mesma mensagem mais de uma vez sem efeito colateral.
- Processar mensagens dentro de timeout explícito — não segurar ack indefinidamente.
- Commitar offset/ack somente após processamento bem-sucedido.
- Tratar erros de processamento sem bloquear a fila inteira.

### Dead-Letter e Retry
- Encaminhar mensagens que falharam após N tentativas para dead-letter queue (DLQ).
- Definir política de retry com backoff antes de mover para DLQ.
- Monitorar tamanho da DLQ com alerta.

### Ordering e Partitioning
- Não depender de ordenação global — usar partition key quando ordem importar dentro de um aggregate.
- Documentar garantias de ordenação assumidas pelo consumidor.

### Observabilidade
- Propagar trace context nas mensagens para manter tracing distribuído entre producer e consumer.
- Expor métricas de consumer lag e taxa de erro por tópico/fila.

## Riscos Comuns
- Publicar evento antes do commit — mensagem fantasma se a transação falhar.
- Consumidor não-idempotente com at-least-once delivery causando duplicação.
- Consumer lag crescendo silenciosamente sem alerta.

## Proibido
- Publicar evento dentro de transação de banco sem outbox pattern.
- Consumidor que ignora falha e commita offset/ack.
- Mensagem sem correlation ID ou trace context.
