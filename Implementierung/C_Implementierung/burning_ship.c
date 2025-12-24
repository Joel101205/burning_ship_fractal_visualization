#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <complex.h>
#include <stdio.h>

typedef struct{ // order for writing to BMP
  unsigned char b;
  unsigned char g;
  unsigned char r;
} Pixel;


// define struct for BMP file headers
// ensure header structs have one byte alignment
#pragma pack(push, 1)

// 14 byte
typedef struct{
  unsigned char signature[2];
  unsigned int file_size;
  unsigned short reserved1;
  unsigned short reserved2;
  unsigned int pixel_offset;
} BMPFileHeader;

// 40 byte
typedef struct{
  unsigned int header_size;
  int width;
  int height;
  unsigned short planes;
  unsigned short bits_per_pixel;
  unsigned int compression;
  unsigned int image_size;
  int x_ppm;
  int y_ppm;
  unsigned int colors_used;
  unsigned int important_colors;
} BMPInfoHeader;


#pragma pack(pop)

int write_pixel(Pixel *pixel, int width, int height) {
  FILE *file;
  file = fopen("burning_ship_fractal.bmp", "wb");

  if (file == NULL) {
    printf("Error, could not open file\n");
    return EXIT_FAILURE;
  }

  // calculate padding
    int num_of_padding = (4 - ((width * 3) % 4)) % 4;
    unsigned char padding[3] = {0, 0, 0}; 

  // BMP headers
    int pixel_data_size = (((width * 3) + num_of_padding) * height);
    
    BMPFileHeader file_header = {
      {'B', 'M'},
      54 + pixel_data_size,
      0,
      0,
      54
    };

    BMPInfoHeader info_header = {
      40,
      width,
      height,
      1,
      24,  // bits_per_pixel: 3 * 8
      0, 
      pixel_data_size,
      0,
      0,
      0,
      0
    };

  fwrite(&file_header, sizeof(file_header), 1, file);
  fwrite(&info_header, sizeof(info_header), 1, file);
 
  // vertically reflected for aestatic purposes, so no need to start from bottom row for BMP
  for (int i = 0; i < height; i++) {
    for (int j = 0; j < width; j++) {
      Pixel current = pixel[i * width + j];
      unsigned char pixel_string[3] = {current.b, current.g, current.r};
      fwrite(pixel_string, 1, 3, file); 
    }

    // add padding
      fwrite(padding, 1, num_of_padding, file); 
  } 
  
  fclose(file);
  
  return EXIT_SUCCESS;
}

void burning_ship(float complex start, size_t width, size_t height, float res, unsigned n, unsigned char* img) {
  float cx = crealf(start); // get real part of start
  float cy = cimagf(start); // get imaginary part of start
  int num_of_pixel = 0;
  Pixel *pixel_ptr = (Pixel *) img;

  for (int i = 0; i < height; i++) {
    
    for (int j = 0; j < width; j++) {
      float zx = 0; // initialize real part of Z0
      float zy = 0; // initialize imaginarty part of Z0
      float iteration = 0; // number of iteration for current pixel

      while ((zx * zx + zy * zy < 4) && (iteration < n)) {   // check if Zn diverges 
        float ax = fabsf(zx);
        float ay = fabsf(zy);
        float xtemp = (ax * ax) - (ay * ay) + cx;
        zy = (2 * ax * ay) + cy;
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
        float factor = n / iteration;
        float color = factor * 255;
        pixel_ptr[num_of_pixel].r = color;
        pixel_ptr[num_of_pixel].g = 0;
        pixel_ptr[num_of_pixel].b = 0;
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
