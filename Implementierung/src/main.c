#include<stdio.h>
#include<stdlib.h>
#include<stdint.h>
#include<getopt.h>
#include<string.h>
#include<complex.h>
#include<time.h>
#include "bmp.h"
#include "burning_ship.h"

void helpMessage() {
	printf("Help Message\n");
	printf("This Program generates a burning ship fractal based on user-submitted parameters.\n");
	printf("Usage: ./BurningShip [-V (int)] [-B (int)] [-o (String)] [-s (float),(float)] [-d (size_t),(size_t)] [-n (int)] [-r (float)] \n");
	printf("Default input: ./burning_ship -V 0 -o burning_ship.bmp -s -1.8,0.01 -d 1920,1080 -n 500 -r 0.0001\n");
    printf("The following options exist:\n");
	printf(" -V (int)                       : Selects which version of this program to run. Default: 0\n");
  	printf("                                  0: Assembly SIMD Implementation, 1: Assembly SISD Implementation, 2: C SISD Implementation: 2, 3: C compiler optimized\n");
	printf(" -B(optionalInt)                : when set, measures benchmark time. Optional number parameter sets number of repetitions \n");
	printf(" -o (String)                    : Sets the name of the output file. Default Name: burning_ship.bmp\n");
	printf(" -s (float),(float)             : Sets the starting point (top left) for the calculation, 1. real part, 2. imaginary part; Default: -1.8,0.01\n"); 
	printf(" -d (size_t),(size_t)           : Sets the dimensions for the output image: 1. width, 2. height; Default:1920,1080 \n");
	printf(" -n (int)                       : Sets the number of iterations per pixel; Default: 500\n");
	printf(" -r (float)                     : Sets the step length per pixel; Default: 0.0001\n");
	printf(" -h, --help                     : Print this help message.\n");
}

int main(int argc, char* argv[]) {

int version = 0;  // Determines which implementation is used
int repetitions = 1; // Number of times the Algorithm runs
int benchmark = 0; // 1 = Benchmark testing enabled, 0 = disabled
unsigned n = 500; // Number of iterations per pixel
size_t imgWidth = 1920;
size_t imgHeight = 1080;
float real = -1.8;
float imag = 0.01;
float res = 0.0001;
char *output = "burning_ship.bmp";
int opt;
struct timespec start;
struct timespec end;

static struct option long_options[] = {
	{"help", no_argument, 0, 'h'},
	{0, 0, 0, 0}
};


// Looping switch statement that parses all option parameters using getopt_long
while ((opt = getopt_long(argc, argv, "V:B::o:s:r:n:d:h", long_options, NULL)) != -1) {
        switch (opt) {
            case 'V':
                version = atoi(optarg);
                break;
            case 'B':
                if (optarg) {
                    repetitions = atoi(optarg);
                }
                benchmark = 1;
                break;
            case 'o':
                output = optarg;
                break;
            case 'h':
                helpMessage();
                return EXIT_SUCCESS;
	    	case 's':
				if (sscanf(optarg, "%f, %f", &real, &imag) != 2) {
		   			fprintf(stderr, "Error: Something went wrong when assigning start point!\n");
	           		return EXIT_FAILURE;
				}
				break;
			case 'd':
				if (sscanf(optarg, "%zu, %zu", &imgWidth, &imgHeight) != 2) {
					fprintf(stderr, "Error: Something went wrong when assigning image size!\n");
					return EXIT_FAILURE;
				}
				break;
            case 'n':
				n = atoi(optarg);  
				break;
			case 'r':
				res = atof(optarg);
				break;
            default:
				fprintf(stderr, "Invalid input, use -h or --help to see input options!\n");
						return EXIT_FAILURE;
				}
    }

// Validating user inputs
if(repetitions < 1 || repetitions > 100) {
	repetitions = 1;
	printf("Warning: repetitions must be in [1, 100]. Reset to 1.\n");
}

if(version < 0 || version > 3) {
	version = 0;
	printf("Warning: invalid Version. Reset to 0.\n");
}

if(n < 1 || n > 5000) {
	n = 500;
	printf("Warning: iterations per pixel must be in [1, 5000]. Reset to 500\n");
}

if (imgHeight < 1 || imgHeight > 8000) {
	imgHeight = 1080;
	printf("Warning: height must be in [1, 8000]. Reset to 1080\n");
}

if (imgWidth < 1 || imgWidth > 8000) {
	imgWidth = 1920;
	printf("Warning: width must be in [1, 8000]. Reset to 1920.\n");
}

if (imgWidth * imgHeight > 50000000) {
	imgWidth = 1920;
	imgHeight = 1080;
	printf("Warning: total pixel count too large. Reset to 1920x1080.\n");
}
float complex complexStart = real + imag*I;

FILE *outputFile = fopen(output, "wb");
if(!outputFile) {
	fprintf(stderr, "Error: Unable to allocate space for generating output!\n");
	return EXIT_FAILURE;
	
}

unsigned char *img = malloc(imgWidth * imgHeight * sizeof(Pixel));

if (img == NULL) {
	fprintf(stderr, "Error: Unable to allocate memory");
	return EXIT_FAILURE;
}


double total_time = 0.0;

if (benchmark > 0) burning_ship(complexStart, imgWidth, imgHeight, res, n, img); // warmup execution for benchmarking

for (int i = 0; i < repetitions; i++) {

	// Starting the benchmark timer
	if(benchmark > 0) {
		clock_gettime(CLOCK_MONOTONIC, &start);
	}

	// Call the correct version of the function
	switch (version) {
	case 0: 
		burning_ship(complexStart, imgWidth, imgHeight, res, n, img);
		break;
	case 1: 
		burning_ship_V1(complexStart, imgWidth, imgHeight, res, n, img);
		break;
	case 2:
		burning_ship_V2(complexStart, imgWidth, imgHeight, res, n, img);
		break;
	case 3:
		burning_ship_V3(complexStart, imgWidth, imgHeight, res, n, img);
		break;
	default:
		burning_ship(complexStart, imgWidth, imgHeight, res, n, img);
	}

	// Benchmark timer end
	if(benchmark > 0) {
		clock_gettime(CLOCK_MONOTONIC, &end);
		total_time += end.tv_sec - start.tv_sec + 1e-9*(end.tv_nsec - start.tv_nsec);
	}
}

// Print out average execution time
if (benchmark > 0) {
	total_time /= repetitions;
	printf("Average execution time: %lf seconds\n", total_time);
}

// Write pixels to the output file
Pixel *pixels = (Pixel *) img;
write_pixel(pixels, imgWidth, imgHeight, output);

printf("Process finished, the result can be found at %s \n", output);
fclose(outputFile);
free(img);
return 0;
}
