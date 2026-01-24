#include "bmp.h"
#include "burning_ship.h"
#include <stdio.h>
#include <stdlib.h>


int main()
{
  size_t width = 1300;
  size_t height = 1300;
  float complex start = -2.0 + 2.0 * I;
  float res = 0.003;
  unsigned n = 1000;

  unsigned char *img = malloc(width * height * sizeof(Pixel));

  if (img == NULL) {
    printf("Error, could not allocate memory");
    return 1;
  }
  
  burning_ship(start, width, height, res, n, img);

  Pixel *pixels = (Pixel *) img;

  write_pixel(pixels, width, height, "burning_ship_fractal.bmp");

  return EXIT_SUCCESS;
}
