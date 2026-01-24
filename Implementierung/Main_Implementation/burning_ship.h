#ifndef BURNING_SHIP_H
#define BURNING_SHIP_H

#include <complex.h>
#include <stddef.h>

void burning_ship(
  float complex start, 
  size_t width,
  size_t height,
  float res,
  unsigned n, 
  unsigned char* img
);

#endif 
