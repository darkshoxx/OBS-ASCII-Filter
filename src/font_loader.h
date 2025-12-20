#pragma once
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include "glyphs.h"

// Load font and rasterize glyphs for the given character set.
// Returns true on success, false on failure.
// out_glyphs: pointer to array of glyph_t (caller should free array).
bool load_font_glyphs(const char* font_path,
                      const char* charset,
                      glyph_t** out_glyphs,
                      size_t* out_count,
                      size_t glyph_width,
                      size_t glyph_height);
