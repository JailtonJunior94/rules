# Stack do Projeto

- Produto: CLI de orquestração de agentes de IA
- Linguagem: Go 1.22+
- Framework de CLI: `github.com/spf13/cobra`
- Logging estruturado: `log/slog`
- Task runner: `https://taskfile.dev/`
- Release automation: `https://goreleaser.com/getting-started/install/`
- Style guide mandatória: `https://github.com/alcir-junior-caju/uber-go-style-guide-pt-br/blob/main/style.md`
- Formato de workflow: YAML
- Persistência local: filesystem + JSON
- Saída estruturada: Markdown + JSON validável
- Providers V1: Claude CLI e Copilot CLI via subprocesso
- Arquitetura: Clean Architecture + Ports and Adapters + composição idiomática em Go
- Padrões preferidos: Strategy, Command, Factory Method, Adapter, State, Facade
- Princípios: SOLID, KISS, baixo acoplamento, alta coesão, determinismo
