# Burning Ship Fractal — SIMD Assembly

**University Project · TUM · Aspekte der systemnahen Programmierung bei der Spieleentwicklung (ASP)**
**Winter Semester 2025/26**

**Contributors: Joel Chiu, Arthur Öttl, Leif Nissen**

An optimized implementation of the **Burning Ship fractal** written in x86-64 Assembly, with a C-based command-line interface and multiple implementations for performance comparison.

## Overview

The project focused on implementing and optimizing a Burning Ship fractal renderer at a low level. The main goal was to explore **x86-64 Assembly, SIMD parallelization, floating-point arithmetic, and performance optimization**.

The program generates the fractal as a 24-bit BMP image and supports configurable image dimensions, iteration count, starting coordinates, resolution, output file, and implementation version with the following options:

- -V <*Number*> implementation version
- -B <*Zahl*> benchmark repetition
- -s <*Real part*>, <*Imaginary part*> Starting point
- -d <*Number*>, <*Number*> Width & Height
- -n <*Number*> Iteration count
- -r <*Floating point number*> Step size
- -o <*File name*> Output file 
- -h Help Message

Example:

```bash
./burning_ship -V 0 -o burning_ship.bmp -s -1.8,0.01 -d 1920,1080 -n 500 -r 0.0001
```
Output:

<img width="1772" height="1002" alt="image" src="https://github.com/user-attachments/assets/52cd3001-f65c-4834-8f5d-2e1e864c0bc8" />

## Burning Ship Fractal

The fractal is generated using the iteration

$$
z_{k+1} = (|Re(z_k)| + i|Im(z_k)|)^2 + c \quad (k \geq 0)
$$

with $z_0 = 0$.

For efficient implementation, the complex-number calculation was expanded into real-valued operations:

$$
x_{k+1} = x_k^2 - y_k^2 + c_x
$$

$$
y_{k+1} = 2|x_k||y_k| + c_y
$$

A point is considered to have escaped when

$$
x_k^2 + y_k^2 > 4.
$$

The number of iterations before escape is used to determine the pixel color, while points that remain bounded after the maximum number of iterations are rendered black.

## Implementations

To evaluate the impact of different optimization techniques, four versions were implemented:

| Version | Implementation                                | Parallelism        |
| ------- | --------------------------------------------- | ------------------ |
| **V0**  | SIMD x86-64 Assembly                          | 4 pixels at once   |
| **V1**  | SISD x86-64 Assembly                          | Single pixel       |
| **V2**  | Unoptimized C                                 | Single pixel       |
| **V3**  | Optimized C (`-O3 -ffast-math -march=native`) | Compiler-dependent |

The SIMD Assembly implementation processes four pixels simultaneously using **128-bit SSE registers**.

## SIMD Optimization

The main optimization was to exploit the fact that neighboring pixels can be processed independently.

Instead of calculating one pixel at a time, the SIMD implementation stores the values of four pixels in an SSE register and performs the fractal iteration on all four pixels in parallel.

For example, the squaring operation can be performed on four values simultaneously:

```asm
movups xmm13, xmm10
mulps  xmm13, xmm13
```

The divergence check is also vectorized, allowing multiple pixels to be tested in parallel.

Since an image width is not necessarily divisible by four, the remaining one to three pixels at the end of each row are processed using the SISD implementation.

Pixel color calculations are vectorized as well, allowing the RGB components of multiple pixels to be generated simultaneously.

## Performance

The implementations were benchmarked on:

* **CPU:** Intel Processor U300 — 5 cores, 0.4–4.4 GHz
* **RAM:** 16 GB DDR4
* **OS:** Ubuntu 25.04
* **Compiler:** GCC 14.2.0
* **SIMD:** SSE4.2
* **Power mode:** Performance

Runtime measurements were performed using `clock_gettime()` with `CLOCK_MONOTONIC`.

The SIMD Assembly implementation consistently achieved the shortest runtime among the tested implementations. The performance advantage becomes more noticeable as the image size and computational workload increase.

<img width="800" height="550" alt="image" src="https://github.com/user-attachments/assets/a792e2c9-5339-4353-834f-13a86fad41c5" />


Using the unoptimized C implementation as the baseline, the SIMD implementation achieved a relative runtime of approximately **12–15%** of the baseline in the tested configurations.

## My Contribution

I was primarily responsible for the low-level implementation and performance evaluation:

* Developed the **SISD x86-64 Assembly implementation**
* Developed the **SIMD x86-64 Assembly implementation**
* Implemented the **C reference implementation**
* Contributed to the **C command-line framework**
* Designed and performed the **benchmark experiments**

## Technologies

**C · x86-64 Assembly · SSE/SIMD · GCC · Linux · Python · BMP**

## Possible Extensions

Potential future improvements include:

* **AVX2 / AVX-512:** Process more pixels per instruction using wider vector registers.
* **GPU acceleration:** Move the highly parallel fractal computation to a GPU using CUDA or another GPU framework.

