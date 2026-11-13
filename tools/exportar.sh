#!/bin/bash
# Exporta o jogo para jogar no celular.
#
#   tools/exportar.sh web       -> exportar/web/  (abre no navegador do celular)
#   tools/exportar.sh android   -> exportar/android/grill-or-be-grilled.apk
#   tools/exportar.sh testar    -> serve exportar/web em http://<ip-do-pc>:8765
#
# Web usa o template sem threads: assim roda em qualquer hospedagem estatica
# (GitHub Pages, itch.io), sem precisar dos cabecalhos de isolamento de origem.
# Android exige Android SDK e os templates de Android do Godot (ver README).
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
G="$RAIZ/Godot_v4.7.2-stable_linux.x86_64"
PROJETO="$RAIZ/grill-or-be-grilled"

exportar() {
  local preset="$1" destino="$2"
  mkdir -p "$(dirname "$destino")"
  "$G" --headless --path "$PROJETO" --export-release "$preset" "$destino" 2>&1 \
    | grep -E "ERROR|template|Template" || true
  if [ ! -s "$destino" ]; then
    echo "Falhou: $destino nao foi gerado (preset \"$preset\")." >&2
    exit 1
  fi
  echo "Pronto: $destino"
}

case "${1:-}" in
  web)
    exportar "Web" "$RAIZ/exportar/web/index.html"
    ;;
  android)
    exportar "Android" "$RAIZ/exportar/android/grill-or-be-grilled.apk"
    ;;
  testar)
    # Mesma rede Wi-Fi: abra o endereco abaixo no navegador do celular.
    ip=$(hostname -I | awk '{print $1}')
    echo "Abra no celular: http://$ip:8765/index.html  (Ctrl+C para parar)"
    python3 -m http.server 8765 --directory "$RAIZ/exportar/web"
    ;;
  *)
    echo "uso: tools/exportar.sh web|android|testar" >&2
    exit 2
    ;;
esac
