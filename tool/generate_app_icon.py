"""Generate the native launcher icon set for 记账本.

The icon is built at 2048px and downsampled, so the curves and the coin glyph
stay clean at launcher sizes. Source art is kept under assets/icon/ and the
platform outputs are written into the existing Flutter icon locations.

Run from the project root:
    python tool/generate_app_icon.py
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets" / "icon"
S = 2048  # supersampled master canvas
DESIGN = 1024.0
SCALE = S / DESIGN


def px(value: float) -> int:
    return int(round(value * SCALE))


def box(*values: float) -> tuple[int, int, int, int]:
    return tuple(px(value) for value in values)  # type: ignore[return-value]


def gradient_background() -> Image.Image:
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    t = (xx + yy) / (2.0 * (S - 1))
    top = np.array([18, 154, 120], dtype=np.float32)
    bottom = np.array([5, 73, 56], dtype=np.float32)
    rgb = top[None, None, :] * (1.0 - t[..., None]) + bottom[None, None, :] * t[..., None]

    # Soft radial light behind the book.
    dx = (xx - S * 0.36) / (S * 0.72)
    dy = (yy - S * 0.28) / (S * 0.72)
    glow = np.clip(1.0 - np.sqrt(dx * dx + dy * dy), 0.0, 1.0) ** 2
    rgb = rgb * (1.0 - glow[..., None] * 0.10) + 255.0 * glow[..., None] * 0.10

    # Subtle darkening at the bottom edge keeps the white book grounded.
    vignette = np.clip((yy / (S - 1) - 0.58) / 0.42, 0.0, 1.0) ** 2
    rgb = rgb * (1.0 - vignette[..., None] * 0.12)

    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB").convert(
        "RGBA"
    )


def vertical_gradient(
    size: int, top: tuple[int, int, int], bottom: tuple[int, int, int]
) -> Image.Image:
    rows = np.linspace(0, 1, size, dtype=np.float32)[:, None, None]
    a = np.array(top, dtype=np.float32)[None, None, :]
    b = np.array(bottom, dtype=np.float32)[None, None, :]
    rgb = a * (1.0 - rows) + b * rows
    rgb = np.repeat(rgb, size, axis=1)
    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB").convert("RGBA")


def add_shadow(
    canvas: Image.Image,
    shape: str,
    coords: tuple[float, float, float, float],
    radius: float,
    offset: tuple[float, float],
    blur: float,
    alpha: int,
) -> None:
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    x0, y0, x1, y1 = coords
    dx, dy = offset
    if shape == "round":
        draw.rounded_rectangle(
            box(x0 + dx, y0 + dy, x1 + dx, y1 + dy),
            radius=px(radius),
            fill=(2, 27, 20, alpha),
        )
    else:
        draw.ellipse(
            box(x0 + dx, y0 + dy, x1 + dx, y1 + dy),
            fill=(2, 27, 20, alpha),
        )
    shadow = shadow.filter(ImageFilter.GaussianBlur(px(blur)))
    canvas.alpha_composite(shadow)


def draw_mark() -> Image.Image:
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    # Book shadow.
    add_shadow(layer, "round", (290, 160, 730, 830), 66, (0, 30), 32, 90)

    # White ledger cover, with a barely-there vertical paper gradient.
    book_mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(book_mask).rounded_rectangle(
        box(290, 160, 730, 830),
        radius=px(66),
        fill=255,
    )
    cover = vertical_gradient(S, (255, 255, 253), (238, 249, 243)).convert("RGBA")
    layer.paste(cover, (0, 0), book_mask)

    # Spine, clipped to the cover silhouette.
    spine_mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(spine_mask).rectangle(box(290, 160, 366, 830), fill=255)
    spine_mask = Image.composite(spine_mask, Image.new("L", (S, S), 0), book_mask)
    spine = Image.new("RGBA", (S, S), (10, 107, 81, 255))
    layer.paste(spine, (0, 0), spine_mask)

    # A thin pale page edge along the spine.
    draw.rounded_rectangle(
        box(358, 176, 364, 814),
        radius=px(3),
        fill=(210, 239, 228, 235),
    )
    # A soft highlight on the left edge of the cover.
    draw.rounded_rectangle(
        box(376, 178, 381, 812),
        radius=px(2),
        fill=(255, 255, 255, 110),
    )

    # A small mint title bar and ledger rules.
    draw.rounded_rectangle(
        box(405, 242, 590, 266),
        radius=px(12),
        fill=(12, 126, 96, 255),
    )
    for x_end, y in ((648, 324), (620, 402), (548, 480), (522, 558)):
        draw.rounded_rectangle(
            box(405, y, x_end, y + 18),
            radius=px(9),
            fill=(202, 232, 218, 255),
        )

    # Faint ruled margin, like a paper ledger.
    draw.rounded_rectangle(
        box(385, 294, 388, 575),
        radius=px(1.5),
        fill=(226, 242, 234, 255),
    )

    # Deep-mint bookmark ribbon with a V notch.
    mark_shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(mark_shadow).polygon(
        [
            (px(624), px(144)),
            (px(678), px(144)),
            (px(678), px(288)),
            (px(651), px(264)),
            (px(624), px(288)),
        ],
        fill=(2, 27, 20, 55),
    )
    mark_shadow = mark_shadow.filter(ImageFilter.GaussianBlur(px(7)))
    layer.alpha_composite(mark_shadow)
    draw.polygon(
        [
            (px(624), px(138)),
            (px(678), px(138)),
            (px(678), px(282)),
            (px(651), px(258)),
            (px(624), px(282)),
        ],
        fill=(12, 126, 96, 255),
    )
    draw.rounded_rectangle(
        box(628, 148, 632, 268),
        radius=px(2),
        fill=(99, 178, 154, 170),
    )

    # Gold coin shadow and body.
    coin = (600, 585, 810, 795)
    add_shadow(layer, "ellipse", coin, 0, (0, 18), 24, 95)

    # Pale rim so the coin reads on both the mint background and the white page.
    draw.ellipse(box(593, 578, 817, 802), fill=(213, 239, 228, 255))
    draw.ellipse(box(600, 585, 810, 795), fill=(255, 253, 246, 255))

    gold_mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(gold_mask).ellipse(box(610, 595, 800, 785), fill=255)
    gold = vertical_gradient(S, (248, 197, 91), (215, 137, 42)).convert("RGBA")
    layer.paste(gold, (0, 0), gold_mask)

    # Inner ring + glossy highlight.
    draw.ellipse(
        box(632, 617, 778, 763),
        outline=(255, 246, 218, 105),
        width=px(2.5),
    )
    draw.arc(
        box(626, 611, 784, 769),
        start=206,
        end=286,
        fill=(255, 255, 255, 90),
        width=px(5),
    )

    # White ¥ monogram.
    font_path = Path(r"C:\Windows\Fonts\arialbd.ttf")
    if not font_path.exists():
        font_path = Path(r"C:\Windows\Fonts\seguisb.ttf")
    font = ImageFont.truetype(str(font_path), px(112))
    glyph = "¥"
    bbox = draw.textbbox((0, 0), glyph, font=font)
    gw, gh = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(
        (px(705) - gw / 2 - bbox[0], px(694) - gh / 2 - bbox[1]),
        glyph,
        font=font,
        fill=(255, 255, 255, 255),
    )

    return layer


def compose(
    background: Image.Image,
    mark: Image.Image,
    *,
    safe: bool = False,
    rounded: bool = False,
) -> Image.Image:
    canvas = background.copy()
    if safe:
        scaled = mark.resize((int(S * 0.80), int(S * 0.80)), Image.LANCZOS)
        canvas.alpha_composite(scaled, ((S - scaled.width) // 2, (S - scaled.height) // 2))
    else:
        canvas.alpha_composite(mark)
    if rounded:
        mask = Image.new("L", (S, S), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            box(0, 0, 1024, 1024),
            radius=px(225),
            fill=255,
        )
        canvas.putalpha(Image.composite(canvas.getchannel("A"), Image.new("L", (S, S), 0), mask))
    return canvas


def save_resized(image: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.LANCZOS).save(path, "PNG")


def write_android_adaptive() -> None:
    anydpi = ROOT / "android" / "app" / "src" / "main" / "res" / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""
    for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
        (anydpi / name).write_text(xml, encoding="utf-8")


def main() -> None:
    ART.mkdir(parents=True, exist_ok=True)
    background = gradient_background()
    mark = draw_mark()
    full = compose(background, mark)
    rounded = compose(background, mark, rounded=True)
    safe = compose(background, mark, safe=True)
    foreground = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    scaled_mark = mark.resize((int(S * 0.80), int(S * 0.80)), Image.LANCZOS)
    foreground.alpha_composite(
        scaled_mark,
        ((S - scaled_mark.width) // 2, (S - scaled_mark.height) // 2),
    )

    # Source art.
    full.resize((1024, 1024), Image.LANCZOS).convert("RGB").save(
        ART / "app_icon_1024.png", "PNG"
    )
    rounded.resize((1024, 1024), Image.LANCZOS).save(
        ART / "app_icon_rounded_1024.png", "PNG"
    )
    background.resize((1024, 1024), Image.LANCZOS).convert("RGB").save(
        ART / "app_icon_background_1024.png", "PNG"
    )
    foreground.resize((1024, 1024), Image.LANCZOS).save(
        ART / "app_icon_foreground_1024.png", "PNG"
    )
    safe.resize((1024, 1024), Image.LANCZOS).convert("RGB").save(
        ART / "app_icon_maskable_1024.png", "PNG"
    )

    # Android legacy icons.
    legacy_sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, size in legacy_sizes.items():
        save_resized(rounded, ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png", size)

    # Android adaptive layers.
    adaptive_sizes = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
    for density, size in adaptive_sizes.items():
        resized_background = background.resize((size, size), Image.LANCZOS).convert("RGBA")
        resized_foreground = foreground.resize((size, size), Image.LANCZOS)
        resized_background.save(
            ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher_background.png",
            "PNG",
        )
        resized_foreground.save(
            ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher_foreground.png",
            "PNG",
        )
    write_android_adaptive()

    # iOS icon set.
    ios = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for name, size in ios_sizes.items():
        ios_image = full if size != 1024 else full
        ios_image.resize((size, size), Image.LANCZOS).convert("RGB").save(ios / name, "PNG")

    # Web icons + favicon.
    web = ROOT / "web" / "icons"
    save_resized(full, web / "Icon-192.png", 192)
    save_resized(full, web / "Icon-512.png", 512)
    save_resized(safe, web / "Icon-maskable-192.png", 192)
    save_resized(safe, web / "Icon-maskable-512.png", 512)
    full.resize((32, 32), Image.LANCZOS).convert("RGB").save(ROOT / "web" / "favicon.png", "PNG")

    # Windows .ico, useful when running the desktop target.
    ico = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
    if ico.parent.exists():
        rounded.save(ico, sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])

    # Preview sheet used for design review.
    preview = Image.new("RGB", (1200, 760), (243, 246, 242))
    shadow = Image.new("RGBA", preview.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((362, 142, 838, 618), radius=96, fill=(10, 40, 28, 45))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    preview = Image.alpha_composite(preview.convert("RGBA"), shadow)
    icon_preview = rounded.resize((448, 448), Image.LANCZOS)
    preview.alpha_composite(icon_preview, (376, 132))
    pd = ImageDraw.Draw(preview)
    label_font_path = Path(r"C:\Windows\Fonts\msyh.ttc")
    if not label_font_path.exists():
        label_font_path = Path(r"C:\Windows\Fonts\msyhbd.ttc")
    if not label_font_path.exists():
        label_font_path = Path(r"C:\Windows\Fonts\simhei.ttf")
    label_font = ImageFont.truetype(str(label_font_path), 34)
    pd.text((600, 626), "记账本", font=label_font, fill=(18, 33, 27), anchor="mm")
    small_y = 700
    for i, size in enumerate((48, 72, 96, 144)):
        tile = rounded.resize((size, size), Image.LANCZOS)
        x = 272 + i * 180
        preview.alpha_composite(tile, (x, small_y - size // 2))
    preview.convert("RGB").save(ART / "app_icon_preview.png", "PNG")

    print("Generated icon assets:")
    for path in sorted(ART.glob("*.png")):
        print(" ", path.relative_to(ROOT))


if __name__ == "__main__":
    main()
