from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

HERE = Path(__file__).parent
ATLAS = HERE / "atlas"
chars = " .:-=+*#%@"          # low to high density, per the alexharri.com ordering
edges = r"-\|/"
cell_w, cell_h = 8, 16
font = ImageFont.truetype("consola.ttf", 14)  # any monospace TTF on your system

atlas = Image.new("RGBA", (cell_w * len(chars), cell_h), (0, 0, 0, 0))
atlas_edges = Image.new("RGBA", (cell_w * len(edges), cell_h), (0, 0, 0, 0))
draw = ImageDraw.Draw(atlas)
draw_edges = ImageDraw.Draw(atlas_edges)
for index, character in enumerate(chars):
    draw.text((index * cell_w, 0), character, font=font, fill=(255, 255, 255, 255))
for index, character in enumerate(edges):
    draw_edges.text((index * cell_w, 0), character, font=font, fill=(255, 255, 255, 255))
atlas.save(ATLAS / "ascii_atlas_c_8_16.png")
atlas_edges.save(ATLAS / "ascii_atlas_e_8_16.png")