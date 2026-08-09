from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

HERE = Path(__file__).parent
ATLAS = HERE / "atlas"
chars = " .:-=+*#%@"          # low to high density, per the alexharri.com ordering
cell_w, cell_h = 8, 16
font = ImageFont.truetype("consola.ttf", 14)  # any monospace TTF on your system

atlas = Image.new("RGBA", (cell_w * len(chars), cell_h), (0, 0, 0, 0))
draw = ImageDraw.Draw(atlas)
for i, c in enumerate(chars):
    draw.text((i * cell_w, 0), c, font=font, fill=(255, 255, 255, 255))
atlas.save(ATLAS / "ascii_atlas_c_8_16.png")