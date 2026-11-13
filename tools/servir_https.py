"""Serve o build Web por HTTPS na rede local, para testar no celular.

O Godot Web so roda em "contexto seguro" (HTTPS ou localhost): servido por HTTP
no IP da rede, o celular mostra "Secure Context - use HTTPS" e o jogo nem abre.
Um certificado autoassinado resolve para teste: o navegador avisa que a conexao
nao e particular, toca-se em Avancado -> Continuar, e a pagina passa a contar
como segura. Para publicar de verdade, use o itch.io (README).

Uso (normalmente via tools/exportar.sh testar):
    python3 tools/servir_https.py exportar/web 8765 192.168.0.10
"""

import http.server
import ssl
import subprocess
import sys
from pathlib import Path


def gerar_certificado(pasta: Path, ip: str) -> tuple[Path, Path]:
    """Cria (ou reaproveita) certificado autoassinado valido para o IP dado.

    Um certificado por IP: ao trocar de Wi-Fi o IP muda, e certificado de outro
    IP faz o navegador recusar de vez em vez de so avisar.
    """
    certificado = pasta / ("teste-%s.crt" % ip)
    chave = pasta / ("teste-%s.key" % ip)
    if certificado.exists() and chave.exists():
        return certificado, chave
    pasta.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "30",
         "-subj", "/CN=grill-or-be-grilled-teste",
         "-addext", "subjectAltName=IP:%s,DNS:localhost" % ip,
         "-keyout", str(chave), "-out", str(certificado)],
        check=True, capture_output=True,
    )
    return certificado, chave


def servir(pasta_do_jogo: Path, porta: int, ip: str) -> None:
    if not (pasta_do_jogo / "index.html").exists():
        raise SystemExit("sem build em %s (esperado index.html); rode tools/exportar.sh web"
                         % pasta_do_jogo)
    certificado, chave = gerar_certificado(pasta_do_jogo.parent / "certificados", ip)
    contexto = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    contexto.load_cert_chain(certificado, chave)

    class Pasta(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=str(pasta_do_jogo), **kwargs)

    servidor = http.server.ThreadingHTTPServer(("0.0.0.0", porta), Pasta)
    servidor.socket = contexto.wrap_socket(servidor.socket, server_side=True)
    print("Abra no celular: https://%s:%d/index.html" % (ip, porta), flush=True)
    print("Aviso de conexao nao particular: Avancado -> Continuar. Ctrl+C para parar.", flush=True)
    servidor.serve_forever()


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("uso: servir_https.py <pasta-do-build> <porta> <ip>; recebi %r" % sys.argv[1:])
    servir(Path(sys.argv[1]), int(sys.argv[2]), sys.argv[3])
