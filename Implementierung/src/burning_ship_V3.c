#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <complex.h>
#include <stdio.h>
#include "bmp.h"

// width, height: number of pixels 
// res: size of each pixel
// smaller res => zoom in
void burning_ship_V3(float complex start, size_t width, size_t height, float res, unsigned n, unsigned char *img) {
    float cx = crealf(start); // get real part of start
    float cy = cimagf(start); // get imaginary part of start
    int num_of_pixel = 0;
    Pixel *pixel_ptr = (Pixel *) img;

    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            float zx = 0; // initialize real part of Z0
            float zy = 0; // initialize imaginarty part of Z0
            int iteration = 0; // number of iteration for current pixel

            while ((zx * zx + zy * zy < 4) && (iteration < n)) {
                // check if Zn diverges
                float ax = fabsf(zx);
                float ay = fabsf(zy);
                float xtemp = (ax * ax) - (ay * ay) + cx;
                zy = (2 * ax * ay) + cy;
                zx = xtemp;
                iteration++;
            }

            if (iteration == n) {
                // if Z converges, set color to black
                pixel_ptr[num_of_pixel].r = 0;
                pixel_ptr[num_of_pixel].g = 0;
                pixel_ptr[num_of_pixel].b = 0;
                num_of_pixel++;
            } else {
                // if Z diverges, set color according to rate of divergence
                pixel_ptr[num_of_pixel].r = (iteration * 9) % 256;
                pixel_ptr[num_of_pixel].g = (iteration * 5) % 256;
                pixel_ptr[num_of_pixel].b = (iteration * 13) % 256;
                num_of_pixel++;
            }

            // update cx
            cx += res;
        }
        // update cx, cy
        cx = crealf(start);
        cy -= res;
    }
}
