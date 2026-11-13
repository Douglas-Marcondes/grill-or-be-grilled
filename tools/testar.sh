#!/bin/bash
# Roda todos os testes headless (ferramentas/teste_*.tscn) e falha se algum
# teste sair com erro ou se o Godot registrar ERROR/assert no caminho.
#
#   tools/testar.sh
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
G="$RAIZ/Godot_v4.7.2-stable_linux.x86_64"
falhou=0
for cena in "$RAIZ"/grill-or-be-grilled/ferramentas/teste_*.tscn; do
  nome=$(basename "$cena" .tscn)
  saida=$(timeout 120 "$G" --headless --path "$RAIZ/grill-or-be-grilled" "res://ferramentas/$nome.tscn" 2>&1)
  codigo=$?
  erros=$(echo "$saida" | grep -cE "ERROR|FALHOU|Assertion failed")
  echo "== $nome (saida=$codigo erros=$erros)"
  echo "$saida" | grep -E "_OK|FALHOU|ERROR|Assertion|at: " | head -12
  if [ "$codigo" -ne 0 ] || [ "$erros" -ne 0 ]; then falhou=1; fi
done
exit $falhou
