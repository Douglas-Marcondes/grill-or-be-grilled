"""Paleta oficial do Grill or Be Grilled: DawnBringer 32.

A arte original da galinha (Artes/GalinhaAndando*.png) ja foi pintada nessas
cores -- elas sao a paleta padrao do Aseprite. Manter DB32 deixa Douglas e Jorge
pintando no Aseprite sem converter nada, e garante que sprite gerado por codigo
e sprite pintado a mao convivam sem destoar.

Uso:
    from paleta import cor
    cor("palha")  # -> (217, 160, 102, 255)
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

# Apelidos de papel: o codigo de arte fala em funcao ("palha", "pena"), nao em
# cor crua, para que trocar o tom de um material seja uma linha so.
PAPEIS: dict[str, str] = {
    "tinta": "preto",
    # O ceu clareia do topo para o horizonte; as silhuetas sao mais escuras que
    # a faixa do horizonte, que e onde elas aparecem -- e assim que recorte de
    # paisagem noturna le como recorte.
    "ceu_alto": "preto",
    "ceu": "roxo_noite",
    "bruma": "vinho",
    "silhueta": "roxo_noite",
    "silhueta_perto": "preto",
    "janela_acesa": "mostarda",
    "luar": "azul_gelo",
    "luar_fraco": "azul_petroleo",
    "madeira_sombra": "vinho",
    "madeira": "marrom_escuro",
    "madeira_luz": "marrom",
    "terra_sombra": "vinho",
    "terra": "marrom_escuro",
    "terra_luz": "marrom",
    "palha_sombra": "mostarda",
    "palha": "areia",
    "palha_luz": "creme",
    "grama_sombra": "oliva",
    "grama": "verde_musgo",
    "grama_luz": "verde_palha",
    # A pedra do piso ficava mais clara que a parede do porao e puxava o olho
    # para o chao; agora o piso e medio e a parede continua sendo a mais escura.
    "pedra_sombra": "cinza_verde",
    "pedra": "cinza",
    "pedra_luz": "cinza_escuro",
    "musgo": "verde_musgo",
    "pena_sombra": "cinza_azulado",
    "pena": "azul_gelo",
    "pena_luz": "branco",
    "bico": "laranja",
    "bico_sombra": "marrom",
    "crista": "vermelho",
    "crista_luz": "rosa_vermelho",
    "fogo_nucleo": "amarelo",
    "fogo": "laranja",
    "fogo_borda": "vermelho",
    "ouro": "amarelo",
    "magia": "roxo",
    "magia_luz": "rosa",
    "aco": "cinza_azulado",
    "aco_luz": "azul_gelo",
    "pele": "creme",
    "pele_sombra": "areia",
}

TRANSPARENTE = (0, 0, 0, 0)


def cor(nome: str) -> tuple[int, int, int, int]:
    """Resolve um papel ou nome DB32 para RGBA.

    Levanta ValueError nomeando o valor recebido, porque um typo em ASCII art
    some silenciosamente como pixel transparente se nao estourar aqui.
    """
    if nome == ".":
        return TRANSPARENTE
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


def paleta_db32_png(caminho: str) -> None:
    """Exporta a paleta como faixa de 1px para abrir no Aseprite."""
    from PIL import Image

    nomes = list(DB32)
    imagem = Image.new("RGBA", (len(nomes), 1))
    for x, nome in enumerate(nomes):
        imagem.putpixel((x, 0), cor(nome))
    imagem.save(caminho)
