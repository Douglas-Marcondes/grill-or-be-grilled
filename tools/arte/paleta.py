"""Cores por nome para ASCII art: DawnBringer 32 e os tons das rampas.

A DB32 (paleta padrao do Aseprite) era a paleta do jogo inteiro. Personagens e
cenario passaram para as rampas de rampas.py, que tem cinco tons por material;
a DB32 ficou para a interface (fonte, botoes de toque), onde cor chapada e o
que se quer.

Uso:
    from paleta import cor
    cor("laranja")   # -> (223, 113, 38, 255), nome DB32
    cor("crista#3")  # -> nivel 3 da rampa "crista"
"""

DB32: dict[str, str] = {
    "preto": "000000",
    "roxo_noite": "222034",
    "vinho": "45283c",
    "marrom_escuro": "663931",
    "marrom": "8f563b",
    "laranja": "df7126",
    "areia": "d9a066",
    "creme": "eec39a",
    "amarelo": "fbf236",
    "verde_limao": "99e550",
    "verde": "6abe30",
    "verde_agua": "37946e",
    "verde_musgo": "4b692f",
    "oliva": "524b24",
    "cinza_verde": "323c39",
    "azul_escuro": "3f3f74",
    "azul_petroleo": "306082",
    "azul": "5b6ee1",
    "azul_claro": "639bff",
    "ciano": "5fcde4",
    "azul_gelo": "cbdbfc",
    "branco": "ffffff",
    "cinza_azulado": "9badb7",
    "cinza_claro": "847e87",
    "cinza": "696a6a",
    "cinza_escuro": "595652",
    "roxo": "76428a",
    "vermelho": "ac3232",
    "rosa_vermelho": "d95763",
    "rosa": "d77bba",
    "verde_palha": "8f974a",
    "mostarda": "8a6f30",
}

# Unico apelido que sobrou: o contorno preto dos icones e dos botoes.
PAPEIS: dict[str, str] = {"tinta": "preto"}

TRANSPARENTE = (0, 0, 0, 0)


def cor(nome: str) -> tuple[int, int, int, int]:
    """Resolve um papel ou nome DB32 para RGBA.

    Levanta ValueError nomeando o valor recebido, porque um typo em ASCII art
    some silenciosamente como pixel transparente se nao estourar aqui.
    """
    if nome == ".":
        return TRANSPARENTE
    if "#" in nome:
        # "crista#3": nivel 3 da rampa crista (rampas.py). Deixa ASCII art
        # pequena (icones) usar os mesmos tons dos sprites esculpidos.
        from rampas import tom
        rampa, nivel = nome.split("#")
        return tom(rampa, int(nivel))
    chave = PAPEIS.get(nome, nome)
    if chave not in DB32:
        raise ValueError(
            "cor desconhecida %r; esperado um papel de PAPEIS (%s...) "
            "ou um nome DB32 (%s...)"
            % (nome, ", ".join(sorted(PAPEIS)[:3]), ", ".join(sorted(DB32)[:3]))
        )
    return _hex_para_rgba(DB32[chave])


def _hex_para_rgba(valor: str) -> tuple[int, int, int, int]:
    return (int(valor[0:2], 16), int(valor[2:4], 16), int(valor[4:6], 16), 255)
