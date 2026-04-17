# Ferramentas e Comandos

- Task runner padrão: `task`
- Arquivo de automação padrão: `Taskfile.yml`
- Build local: `task build`
- Testes: `task test`
- Lint: `task lint`
- Check completo: task check
- Formatação: task fmt
- Release local e snapshots: goreleaser
- CLI alvo: orquestration
- Biblioteca obrigatória para comandos: cobra
- Logging padrão: log/slog
- Style guide mandatória: Uber Go Style Guide PT-BR
- Providers externos esperados no PATH: `claude`, `copilot`

## Instalação de Ferramentas

- Task é documentado oficialmente como um runner cross-platform com binário único e sem dependências extras.
- Task oferece instalação oficial, entre outras opções, via Homebrew com `brew install go-task/tap/go-task`.
- GoReleaser pode ser instalado via Homebrew com `brew install --cask goreleaser/tap/goreleaser` para obter a distribuição oficial mais atual.
- Como alternativa, a documentação também expõe `go install github.com/goreleaser/goreleaser/v2@latest`; esse caminho depende de uma versão recente do Go, então a referência oficial deve prevalecer no momento da instalação.

## Diretrizes Operacionais

- Preferir `task` como interface de desenvolvimento local.
- Preferir `goreleaser release --snapshot --clean` para validar pipeline de empacotamento sem publicar.
- Preferir `slog.New(...)` com handler explícito no bootstrap da aplicação.
- Preferir `logger.With(...)` para contexto estável e `slog.LogAttrs(...)` em caminhos críticos.
- Preferir `goimports`, `go vet` e lint alinhados ao guia da Uber.
- Preferir `filepath` a paths literais com separador fixo.
- Preferir `exec.CommandContext` a shell script inline.
- Todo comportamento dependente de SO deve ser encapsulado para teste.
