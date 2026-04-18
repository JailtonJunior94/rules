# Passos de Validacao

## Objetivo
Bloco canonico de validacao reutilizado por todas as skills que alteram codigo.

## Passos
1. Rodar formatter nos arquivos alterados quando a stack oferecer esse passo.
2. Rodar primeiro testes direcionados aos packages ou modulos afetados.
3. Rodar testes mais amplos e lint quando o custo for proporcional ao risco.
4. Registrar falhas com o comando exato e um diagnostico curto.
5. Se o projeto oferecer `detect-toolchain.sh`, usar os comandos retornados em vez de adivinhar.
