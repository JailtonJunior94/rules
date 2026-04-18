#!/usr/bin/env python3
"""Valida lista de bugs contra o formato canonico review->bugfix.

Usa o JSON Schema em agent-governance/references/bug-schema.json quando
jsonschema estiver disponivel; caso contrario, faz validacao manual equivalente.
"""
import argparse
import json
import os
import re
import sys


REQUIRED_FIELDS = [
    "id",
    "severity",
    "file",
    "line",
    "reproduction",
    "expected",
    "actual",
]
ALLOWED_SEVERITIES = {"critical", "major", "minor"}
ID_PATTERN = re.compile(r"^BUG-\d{3,}$")

SCHEMA_PATH = os.path.join(
    os.path.dirname(__file__),
    "..", "..", "agent-governance", "references", "bug-schema.json",
)


def _try_jsonschema(payload):
    """Tenta validar via jsonschema. Retorna True se conseguiu, False se lib ausente."""
    try:
        import jsonschema  # noqa: F811
    except ImportError:
        return False

    if not os.path.isfile(SCHEMA_PATH):
        return False

    with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
        schema = json.load(f)

    jsonschema.validate(instance=payload, schema=schema)
    return True


def validate_bug(bug, index):
    if not isinstance(bug, dict):
        raise ValueError(f"bug[{index}] deve ser um objeto JSON")

    missing = [field for field in REQUIRED_FIELDS if field not in bug]
    if missing:
        raise ValueError(f"bug[{index}] faltando campos obrigatorios: {', '.join(missing)}")

    extra = set(bug.keys()) - set(REQUIRED_FIELDS)
    if extra:
        raise ValueError(f"bug[{index}] campos desconhecidos: {', '.join(sorted(extra))}")

    severity = bug["severity"]
    if severity not in ALLOWED_SEVERITIES:
        raise ValueError(
            f"bug[{index}].severity invalido: {severity}. Use apenas critical, major ou minor"
        )

    bug_id = bug["id"]
    if not isinstance(bug_id, str) or not ID_PATTERN.match(bug_id):
        raise ValueError(f"bug[{index}].id deve seguir o padrao BUG-NNN (ex: BUG-001)")

    line = bug["line"]
    if not isinstance(line, int) or line <= 0:
        raise ValueError(f"bug[{index}].line deve ser inteiro positivo")

    for field in REQUIRED_FIELDS:
        if field == "line":
            continue
        value = bug[field]
        if not isinstance(value, str) or not value.strip():
            raise ValueError(f"bug[{index}].{field} deve ser string nao vazia")


def main():
    parser = argparse.ArgumentParser(
        description="Valida bugs contra o schema canonico review->bugfix."
    )
    parser.add_argument("--input", required=True, help="caminho para arquivo JSON contendo uma lista de bugs")
    args = parser.parse_args()

    try:
        with open(args.input, "r", encoding="utf-8") as handle:
            payload = json.load(handle)
    except json.JSONDecodeError as exc:
        raise ValueError(f"arquivo JSON invalido em {args.input}: {exc}") from exc

    if not isinstance(payload, list) or not payload:
        raise ValueError("o arquivo deve conter uma lista JSON nao vazia de bugs")

    if _try_jsonschema(payload):
        print(f"SUCCESS: {len(payload)} bugs validados via JSON Schema.")
        return

    for index, bug in enumerate(payload):
        validate_bug(bug, index)

    print(f"SUCCESS: {len(payload)} bugs validados no formato canonico.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
