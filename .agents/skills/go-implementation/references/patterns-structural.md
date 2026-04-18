# Design Patterns — Structural e Creational

## Principios Gerais
- Preferir composicao a hierarquias profundas.
- Preferir funcao, metodo ou tipo concreto antes de factory, strategy ou decorator.
- Usar pattern quando houver variacao recorrente de comportamento ou dependencia externa que exija adaptacao clara.
- Escolher no maximo um pattern principal por problema.
- Go nao tem heranca — patterns que dependem dela devem ser adaptados com interfaces e composicao.

## Sinais de uso indevido
- Mais tipos e indirecao sem melhora de teste ou legibilidade.
- Pattern introduzido para "seguir boas praticas" sem pressao concreta do contexto.
- Pattern que exige explicacao para o leitor entender um fluxo simples.

---

## Creational

### Factory Function
**Quando usar:** Construcao envolve validacao de invariantes, valores default ou dependencias que nao devem ser expostas.
**Em Go:** Funcoes `New*` que retornam `(T, error)` ou `*T`. Nao usar factory abstrata a menos que exista familia de objetos variante.

```go
func NewOrder(id string, total Money) (*Order, error) {
    if id == "" {
        return nil, errors.New("order id is required")
    }
    return &Order{id: id, status: StatusPending, total: total}, nil
}
```

### Builder (Functional Options)
**Quando usar:** Objeto com muitos campos opcionais onde construtores com N parametros ficam ilegiveis.
**Em Go:** Functional options e o idioma preferido sobre builder fluente.

```go
type ServerOption func(*Server)

func WithTimeout(d time.Duration) ServerOption {
    return func(s *Server) { s.timeout = d }
}

func WithLogger(l *slog.Logger) ServerOption {
    return func(s *Server) { s.logger = l }
}

func NewServer(addr string, opts ...ServerOption) *Server {
    s := &Server{addr: addr, timeout: 30 * time.Second, logger: slog.Default()}
    for _, opt := range opts {
        opt(s)
    }
    return s
}
```

### Singleton
**Quando usar:** Quase nunca. Usar apenas para recursos genuinamente unicos (pool de conexao inicializado uma vez).
**Em Go:** `sync.Once` quando inevitavel. Preferir injecao explicita via construtor.

---

## Structural

### Adapter
**Quando usar:** Integrar interface externa incompativel com contrato interno.
**Em Go:** Struct que implementa interface do consumidor e delega para o tipo externo.

```go
type paymentGateway interface {
    Charge(ctx context.Context, amount Money) error
}

type stripeAdapter struct {
    client *stripe.Client
}

func (a *stripeAdapter) Charge(ctx context.Context, amount Money) error {
    _, err := a.client.Charges.New(&stripe.ChargeParams{
        Amount:   stripe.Int64(amount.Cents()),
        Currency: stripe.String("brl"),
    })
    return err
}
```

### Decorator (Middleware)
**Quando usar:** Adicionar comportamento transversal (logging, metricas, retry) sem modificar a implementacao original.
**Em Go:** Funcao ou struct que wrapa uma interface e adiciona comportamento.

```go
type loggingRepository struct {
    next orderRepository
    log  *slog.Logger
}

func (r *loggingRepository) FindByID(ctx context.Context, id string) (*Order, error) {
    r.log.InfoContext(ctx, "finding order", slog.String("id", id))
    order, err := r.next.FindByID(ctx, id)
    if err != nil {
        r.log.ErrorContext(ctx, "find order failed", slog.String("id", id), slog.String("error", err.Error()))
    }
    return order, err
}
```

### Facade
**Quando usar:** Simplificar interacao com subsistema complexo expondo operacao de alto nivel.
**Em Go:** Service ou use case que orquestra multiplas dependencias.

```go
type Service struct {
    orders   orderRepository
    payments paymentGateway
    notify   notificationSender
}

func (s *Service) Checkout(ctx context.Context, orderID string) error {
    order, err := s.orders.FindByID(ctx, orderID)
    if err != nil {
        return err
    }
    if err := s.payments.Charge(ctx, order.Total()); err != nil {
        return fmt.Errorf("charging order %s: %w", orderID, err)
    }
    if err := order.Confirm(); err != nil {
        return err
    }
    if err := s.orders.Save(ctx, order); err != nil {
        return fmt.Errorf("saving order %s: %w", orderID, err)
    }
    _ = s.notify.Send(ctx, order.CustomerID(), "Order confirmed")
    return nil
}
```

---

## Patterns Raramente Uteis em Go (Structural)

| Pattern | Por que evitar | Alternativa Go |
|---------|---------------|----------------|
| Abstract Factory | Go nao tem heranca; over-abstraction | Factory function + interface no consumidor |
| Prototype | Clone e raro em Go; valor semantico resolve | Copiar struct por atribuicao |
| Flyweight | Premature optimization na maioria dos casos | `sync.Pool` quando medicao justificar |

## Proibido
- Pattern introduzido sem problema recorrente que o justifique.
- Mais de um pattern para o mesmo problema.
- Pattern que exige `reflect` para funcionar quando tipagem estatica resolveria.
- Factory abstrata para um unico tipo concreto.
