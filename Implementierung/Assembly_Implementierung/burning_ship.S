.intel_syntax noprefix
.global burning_ship
.text

// void burning_ship(float complex start, size_t width, size_t height,
//                  float res, unsigned  n, unisgned char* img)


// start: xmm0[31:0] = real part; xmm0[32:63] = imaginary part
// width: rdi
// height: rsi
// res: xmm1
// n: rdx
// img: rcx
burning_ship:
  movss xmm2, xmm0 
  


