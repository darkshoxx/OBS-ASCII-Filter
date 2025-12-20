#pragma once
#include <stdint.h>

#define GLYPH_W 8
#define GLYPH_H 8

typedef struct {
    char ch;
    const uint8_t rows[GLYPH_H];
} glyph_t;

const glyph_t *get_glyph(char c);
