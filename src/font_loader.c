#include "font_loader.h"
#include <ft2build.h>
#include FT_FREETYPE_H
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

bool load_font_glyphs(const char* font_path,
                      const char* charset,
                      glyph_t** out_glyphs,
                      size_t* out_count,
                      size_t glyph_width,
                      size_t glyph_height)
{
    if (!font_path || !charset || !out_glyphs || !out_count)
        return false;

    FT_Library ft;
    if (FT_Init_FreeType(&ft)) {
        fprintf(stderr, "[Font Loader] Could not init FreeType library\n");
        return false;
    }

    FT_Face face;
    if (FT_New_Face(ft, font_path, 0, &face)) {
        fprintf(stderr, "[Font Loader] Failed to load font: %s\n", font_path);
        FT_Done_FreeType(ft);
        return false;
    }

    // Set pixel size
    FT_Set_Pixel_Sizes(face, glyph_width, glyph_height);

    size_t n = strlen(charset);
    glyph_t* glyphs = calloc(n, sizeof(glyph_t));
    if (!glyphs) {
        FT_Done_Face(face);
        FT_Done_FreeType(ft);
        return false;
    }

    for (size_t i = 0; i < n; i++) {
        char c = charset[i];
        glyphs[i].ch = c;

        // Load glyph
        if (FT_Load_Char(face, c, FT_LOAD_RENDER)) {
            fprintf(stderr, "[Font Loader] Failed to load char '%c'\n", c);
            memset(glyphs[i].rows, 0, glyph_height);
            continue;
        }

        FT_Bitmap* bmp = &face->glyph->bitmap;

        // Copy into glyph->rows as 8-bit greyscale
        // If bmp.width < glyph_width, center horizontally
        size_t x_offset = (glyph_width > bmp->width) ? (glyph_width - bmp->width)/2 : 0;
        size_t y_offset = (glyph_height > bmp->rows) ? (glyph_height - bmp->rows)/2 : 0;

        memset(glyphs[i].rows, 0, glyph_height); // clear first

        for (size_t row = 0; row < bmp->rows && row + y_offset < glyph_height; row++) {
            for (size_t col = 0; col < bmp->width && col + x_offset < glyph_width; col++) {
                glyphs[i].intensity[row + y_offset][col + x_offset] = bmp->buffer[row * bmp->width + col];
            }
        }
    }

    *out_glyphs = glyphs;
    *out_count = n;

    FT_Done_Face(face);
    FT_Done_FreeType(ft);
    return true;
}
