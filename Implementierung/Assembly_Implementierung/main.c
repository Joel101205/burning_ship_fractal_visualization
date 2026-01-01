#include "bmp.h"
#include "burning_ship.h"
#include <stdlib.h>


int main(int argc, char *argv[])
{
  size_t width = 1600;
  size_t height = 1000;
  float complex start = -1.8 + 0.0 * I;
  float res = 0.0001;
  unsigned n = 1000;

  unsigned char *img = malloc(width * height * 3);

  if (img == NULL) return 1;

  burning_ship(start, width, height, res, n, img);

  Pixel *pixels = (Pixel *) img;

  write_pixel(pixels, width, height);

  return EXIT_SUCCESS;
}
