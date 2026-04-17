# Exemplos de Implementação

## Construtor com invariantes
```go
type Config struct {
    timeout time.Duration
}

func NewConfig(timeout time.Duration) (Config, error) {
    if timeout <= 0 {
        return Config{}, fmt.Errorf("timeout must be positive")
    }
    return Config{timeout: timeout}, nil
}
```

## Interface no consumidor
```go
type clock interface {
    Now() time.Time
}
```

## Table-driven test
```go
func TestNormalize(t *testing.T) {
    tests := []struct {
        name string
        in   string
        want string
    }{
        {name: "trim", in: " a ", want: "a"},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Normalize(tt.in)
            if got != tt.want {
                t.Fatalf("got %q want %q", got, tt.want)
            }
        })
    }
}
```
