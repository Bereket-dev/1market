#!/usr/bin/env python3
"""Generate 1market launcher + splash PNGs with transparent foreground on brand blue."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "brand"

BRAND_BLUE = (0, 40, 142, 255)  # #00288E
WHITE = (255, 255, 255, 255)

FONT_CANDIDATES = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf",
]


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in FONT_CANDIDATES:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def draw_centered_k(size: int, *, scale: float = 0.52) -> Image.Image:
    render_size = max(size * 4, 512)
    img = Image.new("RGBA", (render_size, render_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    font = load_font(max(24, int(render_size * scale)))
    text = "K"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = (render_size - tw) // 2 - bbox[0]
    y = (render_size - th) // 2 - bbox[1]
    draw.text((x, y), text, fill=WHITE, font=font)
    if render_size != size:
        img = img.resize((size, size), Image.Resampling.LANCZOS)
    return img


def composite_on_blue(size: int, foreground: Image.Image) -> Image.Image:
    bg = Image.new("RGB", (size, size), BRAND_BLUE[:3])
    bg.paste(foreground, mask=foreground.split()[3])
    return bg


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    # Adaptive icon foreground — transparent, K in centre safe zone.
    logo_foreground = draw_centered_k(1024, scale=0.50)
    logo_foreground.save(OUT / "logo_foreground.png", optimize=True)

    # Legacy square launcher icon — solid brand blue + centred K.
    logo = composite_on_blue(1024, logo_foreground)
    logo.save(OUT / "logo.png", optimize=True)

    # Pre-Android-12 splash — small centred logo; background colour from XML.
    splash_logo = draw_centered_k(288, scale=0.52)
    splash_logo.save(OUT / "splash_logo.png", optimize=True)

    # Android 12 splash icon — large canvas, K in centre ~768px circle.
    splash_android12 = draw_centered_k(1152, scale=0.38)
    splash_android12.save(OUT / "splash_logo_android12.png", optimize=True)

    print("Wrote brand assets to", OUT)


if __name__ == "__main__":
    main()
