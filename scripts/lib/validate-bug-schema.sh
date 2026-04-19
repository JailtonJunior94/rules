#!/usr/bin/env bash
# Valida JSON de bugs contra bug-schema.json.
# Uso: bash scripts/lib/validate-bug-schema.sh <bugs.json>
#
# Requisito: python3 (usa apenas stdlib — sem dependencia de jsonschema).
# Valida campos obrigatorios, tipos e valores de enum definidos no schema.
# Exit 0 = valido, Exit 1 = invalido (detalhes em stderr).

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: validate-bug-schema.sh <bugs.json>" >&2
  exit 1
fi

BUGS_FILE="$1"

if [[ ! -f "$BUGS_FILE" ]]; then
  echo "ERRO: arquivo nao encontrado: $BUGS_FILE" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEMA_FILE="$SCRIPT_DIR/../../.agents/skills/agent-governance/references/bug-schema.json"

if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo "ERRO: schema nao encontrado: $SCHEMA_FILE" >&2
  exit 1
fi

python3 - "$BUGS_FILE" "$SCHEMA_FILE" <<'PY'
import json
import re
import sys

def validate(bugs_path, schema_path):
    with open(bugs_path) as f:
        try:
            bugs = json.load(f)
        except json.JSONDecodeError as e:
            print(f"ERRO: JSON invalido: {e}", file=sys.stderr)
            return False

    with open(schema_path) as f:
        schema = json.load(f)

    if not isinstance(bugs, list):
        print("ERRO: raiz deve ser um array", file=sys.stderr)
        return False

    if len(bugs) == 0:
        print("ERRO: array de bugs vazio (minItems: 1)", file=sys.stderr)
        return False

    required = schema["items"]["required"]
    props = schema["items"]["properties"]
    valid = True

    for i, bug in enumerate(bugs):
        if not isinstance(bug, dict):
            print(f"ERRO: bugs[{i}] nao e um objeto", file=sys.stderr)
            valid = False
            continue

        # Check required fields
        for field in required:
            if field not in bug:
                print(f"ERRO: bugs[{i}] falta campo obrigatorio '{field}'", file=sys.stderr)
                valid = False

        # Check no additional properties
        allowed = set(props.keys())
        extra = set(bug.keys()) - allowed
        if extra:
            print(f"ERRO: bugs[{i}] campos desconhecidos: {', '.join(sorted(extra))}", file=sys.stderr)
            valid = False

        # Validate types and constraints
        for field, spec in props.items():
            if field not in bug:
                continue
            val = bug[field]

            if spec["type"] == "string":
                if not isinstance(val, str):
                    print(f"ERRO: bugs[{i}].{field} deve ser string", file=sys.stderr)
                    valid = False
                    continue
                if spec.get("minLength", 0) > 0 and len(val) == 0:
                    print(f"ERRO: bugs[{i}].{field} nao pode ser vazio", file=sys.stderr)
                    valid = False
                if "pattern" in spec and not re.match(spec["pattern"], val):
                    print(f"ERRO: bugs[{i}].{field} nao corresponde ao pattern '{spec['pattern']}'", file=sys.stderr)
                    valid = False
                if "enum" in spec and val not in spec["enum"]:
                    print(f"ERRO: bugs[{i}].{field} valor '{val}' nao esta em {spec['enum']}", file=sys.stderr)
                    valid = False

            elif spec["type"] == "integer":
                if not isinstance(val, int) or isinstance(val, bool):
                    print(f"ERRO: bugs[{i}].{field} deve ser inteiro", file=sys.stderr)
                    valid = False
                    continue
                if "minimum" in spec and val < spec["minimum"]:
                    print(f"ERRO: bugs[{i}].{field} deve ser >= {spec['minimum']}", file=sys.stderr)
                    valid = False

    return valid

if validate(sys.argv[1], sys.argv[2]):
    print(f"Validacao do bug report aprovada: {sys.argv[1]}")
else:
    print(f"Validacao do bug report falhou: {sys.argv[1]}", file=sys.stderr)
    sys.exit(1)
PY
