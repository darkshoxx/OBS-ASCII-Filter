#include "glyphs.h"

static const glyph_t glyph_at = {
    '@',
    {
        0b00111100,
        0b01000010,
        0b10111001,
        0b10101001,
        0b10111001,
        0b10000001,
        0b01000010,
        0b00111100
    }
};

const glyph_t *get_glyph(char c)
{
    if (c == '@')
        return &glyph_at;
    return NULL;
}
