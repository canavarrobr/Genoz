"""Gera o símbolo do Genoz (dupla hélice em "S") e os PNGs derivados.

Uso (na pasta Genoz):   python -X utf8 tools/marca/gerar_marca.py

Desenho (fiel a docs/estilo/recortes/simbolo_dna.png): quatro fitas diagonais
de largura constante e pontas arredondadas — ciano nas extremidades, petróleo
no meio — e uma faixa ciano fina ao fundo formando o "X" central. O símbolo
tem simetria de rotação de 180°. Cada fita é uma curva de Bézier cúbica
traçada com espessura; o mesmo desenho gera o SVG e os PNGs.
Determinístico: rodar de novo gera os mesmos arquivos. Dependência: Pillow.
"""

from __future__ import annotations

import os

from PIL import Image, ImageChops, ImageDraw

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SAIDA_APP = os.path.join(RAIZ, "app", "assets", "marca")
SAIDA_DOCS = os.path.join(RAIZ, "docs", "estilo", "marca")

DEEP = (0x07, 0x3B, 0x4C)
PETROLEUM = (0x0B, 0x72, 0x85)
PETROLEUM_DARK = (0x08, 0x55, 0x66)
CYAN = (0x22, 0xB8, 0xCF)
CYAN_LIGHT = (0x4C, 0xCB, 0xDD)
CYAN_BACK = (0x1A, 0x9E, 0xB6)
BACKGROUND = (0xF6, 0xFA, 0xFB)

# Quadro de desenho (mesma proporção da referência, 105 × 200).
W, H = 420.0, 800.0
LARGURA = 80.0  # espessura máxima das fitas (afinam para 60% nas pontas)
LARGURA_X = 60.0  # espessura da faixa central do fundo


# Variante para fundo escuro (ícone e abertura): as fitas do meio clareiam
# para manter o contraste com o azul profundo, como no ícone da referência.
TROCA_ESCURO = {
    PETROLEUM: (0x1A, 0x9A, 0xC4),
    PETROLEUM_DARK: (0x12, 0x7C, 0xA6),
    CYAN_BACK: (0x2B, 0xA9, 0xC8),
}


def girar(p):
    """Rotação de 180° em torno do centro do quadro."""
    return (W - p[0], H - p[1])


# Fitas: (pontos de controle da cúbica, cor inicial, cor final, espessura),
# na ordem de desenho (primeiro o fundo).
F1 = [(64, 336), (40, 196), (250, 196), (352, 54)]  # ciano superior
F2 = [(364, 128), (392, 262), (150, 246), (74, 346)]  # petróleo superior
# Faixa central: simétrica em relação ao centro (210, 400), cruza entre as fitas petróleo.
X1 = [(104, 338), (170, 360), (250, 440), (316, 462)]
FITAS = [
    (X1, CYAN_BACK, CYAN_BACK, LARGURA_X),
    (F1, CYAN, CYAN_LIGHT, LARGURA),
    ([girar(p) for p in F1], CYAN, CYAN_LIGHT, LARGURA),
    (F2, PETROLEUM, PETROLEUM_DARK, LARGURA),
    ([girar(p) for p in F2], PETROLEUM, PETROLEUM_DARK, LARGURA),
]


def bezier(ctrl, t):
    (x0, y0), (x1, y1), (x2, y2), (x3, y3) = ctrl
    u = 1 - t
    a, b, c, d = u * u * u, 3 * u * u * t, 3 * u * t * t, t * t * t
    return (a * x0 + b * x1 + c * x2 + d * x3, a * y0 + b * y1 + c * y2 + d * y3)


def contorno(ctrl, largura, n=160):
    """Bordas da fita: pontos da curva deslocados pela normal, largura variável."""
    import math

    esquerda, direita, centro = [], [], []
    for i in range(n + 1):
        t = i / n
        x, y = bezier(ctrl, t)
        xa, ya = bezier(ctrl, max(0.0, t - 1e-3))
        xb, yb = bezier(ctrl, min(1.0, t + 1e-3))
        dx, dy = xb - xa, yb - ya
        m = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / m, dx / m
        meia = largura / 2 * (0.6 + 0.4 * math.sin(math.pi * t))
        esquerda.append((x + nx * meia, y + ny * meia))
        direita.append((x - nx * meia, y - ny * meia))
        centro.append((x, y, meia))
    return esquerda, direita, centro


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def desenhar(tamanho: int, fundo=None, escala=0.62, arredondar=0.0, escuro=False) -> Image.Image:
    """Símbolo centralizado num quadrado `tamanho`, ocupando `escala` da altura."""
    ss = 4  # supersampling para bordas suaves
    s = tamanho * ss
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if fundo is not None:
        for yy in range(s):  # gradiente vertical sutil
            d.line([(0, yy), (s, yy)], fill=lerp(fundo, lerp(fundo, PETROLEUM, 0.3), yy / s) + (255,))
    k = s * escala / H  # pixels por unidade do quadro
    ox, oy = (s - W * k) / 2, (s - H * k) / 2
    for ctrl, c0, c1, largura in FITAS:
        if escuro:
            c0, c1 = TROCA_ESCURO.get(c0, c0), TROCA_ESCURO.get(c1, c1)
        esq, dir_, centro = contorno(ctrl, largura)
        n = len(centro) - 1
        pt = lambda p: (ox + p[0] * k, oy + p[1] * k)  # noqa: E731
        for i in range(n):  # trechos com a cor do gradiente ao longo da fita
            cor = lerp(c0, c1, i / n) + (255,)
            d.polygon([pt(esq[i]), pt(esq[i + 1]), pt(dir_[i + 1]), pt(dir_[i])], fill=cor)
        for (x, y, meia), cor in ((centro[0], c0), (centro[-1], c1)):  # pontas arredondadas
            cx, cy, r = ox + x * k, oy + y * k, meia * k
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=cor + (255,))
    img = img.resize((tamanho, tamanho), Image.LANCZOS)
    if arredondar > 0:
        mascara = Image.new("L", (s, s), 0)
        ImageDraw.Draw(mascara).rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * arredondar), fill=255)
        img.putalpha(ImageChops.multiply(img.getchannel("A"), mascara.resize((tamanho, tamanho), Image.LANCZOS)))
    return img


def svg(escuro: bool = False) -> str:
    hexc = lambda c: "#%02X%02X%02X" % c  # noqa: E731
    defs, paths = [], []
    for i, (ctrl, c0, c1, largura) in enumerate(FITAS):
        if escuro:
            c0, c1 = TROCA_ESCURO.get(c0, c0), TROCA_ESCURO.get(c1, c1)
        (x0, y0), (x1, y1), (x2, y2), (x3, y3) = ctrl
        defs.append(
            f'<linearGradient id="g{i}" gradientUnits="userSpaceOnUse" x1="{x0:.0f}" y1="{y0:.0f}" '
            f'x2="{x3:.0f}" y2="{y3:.0f}"><stop offset="0" stop-color="{hexc(c0)}"/>'
            f'<stop offset="1" stop-color="{hexc(c1)}"/></linearGradient>'
        )
        esq, dir_, centro = contorno(ctrl, largura, n=48)
        pontos = " ".join(f"{x:.1f},{y:.1f}" for x, y in esq + dir_[::-1])
        paths.append(f'<polygon points="{pontos}" fill="url(#g{i})"/>')
        for (x, y, meia), cor in ((centro[0], c0), (centro[-1], c1)):
            paths.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{meia:.1f}" fill="{hexc(cor)}"/>')
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W:.0f} {H:.0f}" role="img" aria-label="Genoz">\n'
        "<title>Genoz</title>\n<defs>" + "".join(defs) + "</defs>\n" + "\n".join(paths) + "\n</svg>\n"
    )


def main():
    os.makedirs(SAIDA_APP, exist_ok=True)
    os.makedirs(SAIDA_DOCS, exist_ok=True)
    with open(os.path.join(SAIDA_APP, "simbolo.svg"), "w", encoding="utf-8", newline="\n") as f:
        f.write(svg())
    with open(os.path.join(SAIDA_APP, "simbolo_escuro.svg"), "w", encoding="utf-8", newline="\n") as f:
        f.write(svg(escuro=True))
    # Ícone completo (iOS, lojas, Web): fundo azul profundo, símbolo a 70% da altura.
    desenhar(1024, fundo=DEEP, escala=0.70, escuro=True).save(os.path.join(SAIDA_APP, "icone_1024.png"))
    # Primeiro plano do ícone adaptativo do Android (zona segura ≈ 66%): símbolo a 60%.
    desenhar(1024, escala=0.60, escuro=True).save(os.path.join(SAIDA_APP, "icone_primeiro_plano_1024.png"))
    # Abertura (splash) e símbolo avulso.
    desenhar(768, escala=0.9, escuro=True).save(os.path.join(SAIDA_APP, "abertura_simbolo.png"))
    desenhar(512, escala=0.96).save(os.path.join(SAIDA_APP, "simbolo_512.png"))
    # Prévias para a documentação.
    desenhar(512, fundo=DEEP, escala=0.70, arredondar=0.22, escuro=True).save(os.path.join(SAIDA_DOCS, "previa_icone.png"))
    claro = Image.new("RGBA", (512, 512), BACKGROUND + (255,))
    claro.alpha_composite(desenhar(512, escala=0.9))
    claro.save(os.path.join(SAIDA_DOCS, "previa_simbolo_fundo_claro.png"))
    print("ok:", sorted(os.listdir(SAIDA_APP)))


if __name__ == "__main__":
    main()
