#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <complex.h>

struct Pixel {
  unsigned char r;
  unsigned char g;
  unsigned char b;
};

int main(int argc, char *argv[])
{
  return EXIT_SUCCESS;
}

void burning_ship(float complex start, size_t width, size_t height, float res, unsigned n, unsigned char* img) {
  float cx = crealf(start); // get real part of start
  float cy = cimagf(start); // get imaginary part of start
  int num_of_pixel = 0;
  struct Pixel *pixel_ptr = (struct Pixel *) img;

  for (int i = 0; i < height; i++) {
    
    for (int j = 0; j < width; j++) {
      float zx = 0; // initialize real part of Z0
      float zy = 0; // initialize imaginarty part of Z0
      float iteration = 0; // number of iteration for current pixel

      while ((zx * zx + zy * zy < 4) && (iteration < n)) {   // check if Zn diverges 
        float xtemp = (zx * zx) - (zy * zy) + cx;
        zy = fabsf(2 * zx * zy) + cy;
        zx = xtemp;
        iteration++;
      }
      
      
      if (iteration == n) { // if Z converges, set color to black
        pixel_ptr[num_of_pixel].r = 0;
        pixel_ptr[num_of_pixel].g = 0;
        pixel_ptr[num_of_pixel].b = 0;
        num_of_pixel++;
      }
      else {  // if Z diverges, set color according to rate of divergence
        float factor = iteration / n;
        float color = factor * 255;
        pixel_ptr[num_of_pixel].r = color;
        pixel_ptr[num_of_pixel].g = color;
        pixel_ptr[num_of_pixel].b = color;
        num_of_pixel++;
      }

      // update cx
      cx += res; 
    }
    // update cx, cy
    cx = crealf(start);
    cy += res;
  }
}
