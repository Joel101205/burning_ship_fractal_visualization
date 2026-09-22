#include "bmp.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

int write_pixel(Pixel *pixel, size_t width, size_t height, const char *path) {
    FILE *file;
    file = fopen(path, "wb");

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
        24, // bits_per_pixel: 3 * 8
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
    // so start is at bottom left
    for (size_t i = 0; i < height; i++) {
        for (size_t j = 0; j < width; j++) {
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
