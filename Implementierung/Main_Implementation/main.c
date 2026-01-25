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
	printf("Usage: ./BurningShip [-V (int)] [-B (int)] [-o (String)] [-s (float)(float)] [-d (size_t)(size_t)] [-n (int)] [-r (float)] \n");
        printf("The following options exist:\n");
	printf(" -V (int)                                : Selects which version of this program to run.  Default: 0, Assembly SISD Implementation: 1, C SISD Implementation: 2\n");
	printf(" -B(optionalInt)                         : when set, measures benchmark time. Optional number parameter sets number of iterations \n");
	printf(" -o (String)                             : Sets the name of the output file. Default Name: output.bmp\n");
	printf(" -s (float),(float)                       : Sets the starting point for the calculation, 1. real part, 2. imaginary part\n"); 
	printf(" -d (size_t),(size_t)                     : Sets the dimensions for the output image: 1. width, 2. height\n");
	printf(" -n (int)                                : Sets the number of iterations per pixel\n");
	printf(" -r (float)                              : Sets the step length per pixel\n");
	printf(" -h, --help                              : Print this help message.\n");
}

// extern void burning_ship(float complex start, size_t width, size_t height, float res, unsigned n, unsigned char* img);


int main(int argc, char* argv[]) {

int version = 0;  // Determines which implementation is used
int iterations = 1; // Number of times the Algorithm runs
int benchmark = 0; // 1 = Benchmark testing enabled, 0 = disabled
unsigned n = 1;
size_t imgWidth = 1;
size_t imgHeight = 1;
float real = 1;
float imag = 0;
float res = 1;
char *output = "output.bmp";
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
                    iterations = atoi(optarg);
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
/*
if(optind < argc) {
	input = argv[optind];
} else {
 	fprintf(stderr, "Error: Please submit an input file! Use -h or --help for help!\n");
 	return 1;
}
*/
// Starting the benchmark timer
if(benchmark > 0) {
	clock_gettime(CLOCK_MONOTONIC, &start);
}
if(iterations < 1) {
	iterations = 1;
	printf("Warning: Number of iterations needs to be >1 ! Value has been set to 1\n");
}

if(version < 0) {
	version = 0;
	printf("Warning: Selected version number doesn't exist! Setting to default version\n");
}

if(n < 1) {
	n = 1;
	printf("Warning: There needs to be at least 1 iteration per pixel! Setting n to 1\n");
}

float complex complexStart = real + imag*I;

FILE *outputFile = fopen(output, "wb");
if(!outputFile) {
	fprintf(stderr, "Error: Unable to allocate space for generating output!\n");
	return EXIT_FAILURE;
	
}

unsigned char *img = malloc(imgWidth * imgHeight * 4);

if (img == NULL) {
	fprintf(stderr, "Error: Unable to allocate memory");
	return EXIT_FAILURE;
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
	default:
		burning_ship(complexStart, imgWidth, imgHeight, res, n, img);
}


Pixel *pixels = (Pixel *) img;

// Write the pixels to the output file
write_pixel(pixels, imgWidth, imgHeight, output);

// Benchmark timer end
if(benchmark > 0) {
	clock_gettime(CLOCK_MONOTONIC, &end);
	double time = end.tv_sec - start.tv_sec + 1e-9*(end.tv_nsec - start.tv_nsec);
	printf("Execution time: %lf seconds\n", time);
}

printf("Process finished, the result can be found at %s \n", output);
fclose(outputFile);
free(img);
return 0;
}
