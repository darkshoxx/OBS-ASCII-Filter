#pragma once
#include <stdint.h>

#define GLYPH_W 8
#define GLYPH_H 8

typedef struct {
    char ch;
    uint8_t rows[GLYPH_H];                 // keep 1-bit for backwards compatibility if needed
    uint8_t intensity[GLYPH_H][GLYPH_W];   // new greyscale values 0–255
} glyph_t;


const glyph_t *get_glyph(char c);
