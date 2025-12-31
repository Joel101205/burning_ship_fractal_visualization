#ifndef BMP_H
#define BMP_H

#include <stddef.h>

// define pixel struct
typedef struct {
  unsigned char b;
  unsigned char g;
  unsigned char r;
} Pixel;

#pragma pack(push, 1) // ensure one byte alignment

// define BMP headers
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

// write pixels to a bmp file
int write_pixel(Pixel *pixel, size_t width, size_t height);

#endif 
