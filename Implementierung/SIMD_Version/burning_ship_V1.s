.intel_syntax noprefix
.global burning_ship

.section .rodata
.align 16
active_mask:
    .int 0xFFFFFFFF
    .int 0xFFFFFFFF
    .int 0xFFFFFFFF
    .int 0XFFFFFFFF

.align 16
divergence_check:
    .float 4.0
    .float 4.0
    .float 4.0
    .float 4.0

.align 16
abs_mask:
    .int 0x7FFFFFFF
    .int 0x7FFFFFFF
    .int 0x7FFFFFFF
    .int 0x7FFFFFFF

.align 16
pixel_offset:
    .float 0.0
    .float 1.0
    .float 2.0
    .float 3.0

.align 16
blue:
    .int 13
    .int 13
    .int 13
    .int 13

green:
    .int 5
    .int 5
    .int 5
    .int 5

red:
    .int 9
    .int 9
    .int 9
    .int 9

.section .text
# void burning_ship(float complex start, size_t width, size_t height,
#                  float res, unsigned  n, unisgned char* img)

#SIMD_Version

# Parameter: 
# xmm0: start real (start_x)
# xmm2: start imaginary (start_y)
# xmm5rdi: width
# rsi: height
# xmm1: resolution (res)
# rdx: n (max iterations)
# rcx: img pointer

# r8: max iterations
# r12: row index i
# r13: column index j

# xmm3: current pixel_x [cx_1, cx_2, cx_3, cx_4]
# xmm4: current pixel_y [cy_1, cy_2, cy_3, cy_4]
# xmm5: pixel_offset mask [0 * res | 1 * res | 2 * res | 3 * res]
# xmm6: abs_mask 
# xmm7: divergence_check mask
# xmm8: iterations  [n1, n2, n3, n4]
# xmm9: max iterations
# xmm10: zx
# xmm11: zy
# xmm12: active mask

burning_ship:

.set_up:
  push r12
  push r13

  mov r8, rdx
  pshufd xmm2, xmm0, 0x55

  movaps xmm5, [rip + pixel_offset]
  pshufd xmm1, xmm1, 0
  mulps xmm5, xmm1
  
  movaps xmm6, [rip + abs_mask]
  
  movaps xmm7, [rip + divergence_check]
  
  pshufd xmm2, xmm0, 0x55
  pshufd xmm3, xmm0, 0
  addps xmm3, xmm5      # current pixel_x
  pshufd xmm4, xmm2, 0  # current pixel_y

  movd xmm9, r8  # move max iteration to all four lanes
  pshufd xmm9, xmm9, 0

  mov r9, rdi    # SIMD_width
  and r9, -4

  xor r12, r12    # row index i

.loop_row:
  cmp r12, rsi
  jge .end
 
  xor r13, r13    # row index i

.loop_pixel_SIMD:
  cmp r13, r9
  jge .loop_pixel_SISD

  pxor xmm8, xmm8   # iterations
  pxor xmm10, xmm10   # Zx
  pxor xmm11, xmm11 # Zy 
  
.iterations_SIMD:
  # divergence_check
  movaps xmm12, xmm10
  mulps xmm12, xmm12

movaps xmm13, xmm11
  mulps xmm13, xmm13

  addps xmm12, xmm13
  cmpps xmm12, xmm7, 0x00000001  # check if less than 4.0
  
  movmskps eax, xmm12  # check if all lanes diverged
  test eax, eax
  jz .set_colors_SIMD

  # check if all lanes reached max iteration
  movaps xmm13, xmm8
  cmpps xmm13, xmm9, 0x00000001   # cmp < max iteration
  movmskps eax, xmm13
  test eax, eax
  jz .set_colors_SIMD

  # combine divergence check and max iteration check
  andps xmm12, xmm13  # active mask (OxFFFFFFFF = still active; 
                      # 0x00000000 = diverged or max n reached)

  # zx² - zy² + cx
  movaps xmm13, xmm10
  mulps xmm13, xmm13
  movaps xmm14, xmm11
  mulps xmm14, xmm14
  subps xmm13, xmm14
  addps xmm13, xmm3  # new zx

  # 2 * |zx * zy| + cy
  movaps xmm14, xmm10
  andps xmm14, xmm6
  movaps xmm15, xmm11
  andps xmm15, xmm6
  mulps xmm14, xmm15
  addps xmm14, xmm14
  addps xmm14, xmm4  # new zy
  
  # only replace active lanes with new values
  andps xmm13, xmm12
  andnps xmm10, xmm12
  orps xmm10, xmm13   # zx 

  andps xmm14, xmm12
  andnps xmm11, xmm12
  orps xmm11, xmm14   #zy

  # update iteration for active lanes
  pcmpeqd xmm13, xmm13
  psrld xmm13, 31
  pand xmm13, xmm12
  paddd xmm8, xmm13

  jmp .iterations_SIMD

  add r13, 4
  jmp .loop_pixel_SIMD

.set_colors_SIMD:
  # set blue
  movaps xmm13, [rip + blue]
  pmuldp xmm8, xmm13
  pmulld

.loop_pixel_SISD:

.end:
  pop r13
  pop r12


