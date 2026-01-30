.intel_syntax noprefix
.global burning_ship

.section .rodata
.align 16
divergence_check:
    .float 4.0
    .float 4.0
    .float 4.0
    .float 4.0

abs_mask:
    .int 0x7FFFFFFF
    .int 0x7FFFFFFF
    .int 0x7FFFFFFF
    .int 0x7FFFFFFF

pixel_offset:
    .float 0.0
    .float 1.0
    .float 2.0
    .float 3.0

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

color_mask:
    .int 255
    .int 255
    .int 255
    .int 255

.section .text
# void burning_ship(float complex start, size_t width, size_t height,
#                  float res, unsigned  n, unisgned char* img)

#SIMD_Version

# Parameter: 
# xmm0: start real (start_x)
# xmm2: start imaginary (start_y)
# rdi: width
# rsi: height
# xmm1: resolution (res)
# rdx: n (max iterations)
# rcx: img pointer

# r8: max iterations
# r9: SIMD_width
# r10: pixel_offset (number of pixel * 4)
# r11: SISD_iteration
# r12: row index i
# r13: column index j

# xmm3: current pixel_x [cx_1, cx_2, cx_3, cx_4]
# xmm2: current pixel_y [cy_1, cy_2, cy_3, cy_4]
# xmm5: pixel_offset mask [0 * res | 1 * res | 2 * res | 3 * res]
# xmm6: abs_mask 
# xmm7: divergence_check mask
# xmm8: iterations  [n1, n2, n3, n4]
# xmm9: max iterations
# xmm10: zx
# xmm11: zy

burning_ship:

.set_up:
  push r12
  push r13
  push r14

  mov r8, rdx
  movd xmm9, r8
  pshufd xmm9, xmm9, 0 # broadcast max n

  mov r9, rdi    
  and r9, -4      # SIMD_width
  
  movups xmm6, [rip + abs_mask]
  movups xmm7, [rip + divergence_check]

  # inititalize cy 
  pshufd xmm2, xmm0, 0x55 # broadcast start_y

  # initialize cx 
  pshufd xmm0, xmm0, 0  # broadcast start_x
  pshufd xmm1, xmm1, 0  # breoadcas res
  movups xmm5, [rip + pixel_offset]
  mulps xmm5, xmm1
  movups xmm3, xmm5
  addps xmm3, xmm0        # current pixel_x
  movaps xmm0, xmm3
  
  xor r10, r10    # pixel offset
  xor r12, r12    # row index i

.loop_row:
  cmp r12, rsi
  jge .end
 
  xor r13, r13    # column index j

.loop_pixel_SIMD:
  cmp r13, r9
  jge .loop_pixel_SISD

  pxor xmm8, xmm8   # iterations
  pxor xmm10, xmm10   # Zx
  pxor xmm11, xmm11 # Zy 
  
.iterations_SIMD:
  # divergence check
  movups xmm13, xmm10  # zx²
  mulps xmm13, xmm13

  movups xmm14, xmm11   # zy²
  mulps xmm14, xmm14

  movaps xmm4, xmm13
  addps xmm4, xmm14
  cmpps xmm4, xmm7, 1  # zx² + zy² < 4
  
  # max iteration check
  movaps xmm12, xmm9
  pcmpgtd xmm12, xmm8

  andps xmm4, xmm12    # combine mask
  movmskps eax, xmm4
  test eax, eax
  jz .set_colors_SIMD

  # burning ship calculation
  andps xmm10, xmm6
  andps xmm11, xmm6

  # zx² - zy² + cx
  subps xmm13, xmm14
  addps xmm13, xmm3   # new zx

  # 2 * zx * zy + cy
  mulps xmm11, xmm10
  addps xmm11, xmm11
  addps xmm11, xmm2   # new zy

  movaps xmm10, xmm13

  psrld xmm4, 31
  paddd xmm8, xmm4

  jmp .iterations_SIMD

.set_colors_SIMD:
  movaps xmm13, xmm9
  pcmpgtd xmm13, xmm8
  pand xmm8, xmm13
  
  # set blue
  movaps xmm13, xmm8
  pmulld xmm13, [rip + blue]
  pand xmm13, [rip + color_mask] 

  # set green 
  movaps xmm10, xmm8
  pmulld xmm10, [rip + green]
  pand xmm10, [rip + color_mask]
  pslld xmm10, 8

  # set red
  movaps xmm12, xmm8
  pmulld xmm12, [rip + red]
  pand xmm12, [rip + color_mask] 
  pslld xmm12, 16

  por xmm13, xmm10
  por xmm13, xmm12
  movups [rcx + r10], xmm13

.next_pixels_SIMD:
  add r10, 16
  add r13, 4
  
  # cx + 4 * res
  addps xmm3, xmm1
  addps xmm3, xmm1
  addps xmm3, xmm1
  addps xmm3, xmm1

  jmp .loop_pixel_SIMD


.loop_pixel_SISD:
  cmp r13, rdi
  jge .next_row

  xor r11, r11        # iteration
  pxor xmm10, xmm10   # zx
  pxor xmm11, xmm11   # zy

.iterations_SISD:
  # divergence check
  # zx² + zy²
  movss xmm12, xmm10
  mulss xmm12, xmm12

  movss xmm13, xmm11
  mulss xmm13, xmm13

  addss xmm12, xmm13
  cmpss xmm12, xmm7, 0x00000001
  cvtss2si eax, xmm12
  test eax, eax
  jz .set_colors_SISD

  # check max iteration
  cmp r11, r8
  jge .set_colors_SISD

  # compute absolute value
  # |zx|, |zy|
  andps xmm10, xmm6
  andps xmm11, xmm6

  # zx² - zy² + cx
  movss xmm12, xmm10
  mulss xmm12, xmm12
  movss xmm13, xmm11
  mulss xmm13, xmm13
  subss xmm12, xmm13
  addss xmm12, xmm3

  # 2 * |zx * zy| + cy
  mulss xmm11, xmm10
  addss xmm11, xmm11
  addss xmm11, xmm2  # new zy

  movss xmm10, xmm12 # new zx

  inc r11
  jmp .iterations_SISD 

.set_colors_SISD:
  cmp r11, r8
  jge .set_black

  # set blue
  mov rax, r11
  mov r14, 9
  mul r14
  mov r14, 256
  div r14

  mov byte ptr [rcx + r10], dl

  # set green 
  mov rax, r11
  mov r14, 5
  mul r14
  mov r14, 256
  div r14

  mov byte ptr [rcx + r10 + 1], dl

  # set red 
  mov rax, r11
  mov r14, 13
  mul r14
  mov r14, 256
  div r14

  mov byte ptr [rcx + r10 + 2], dl

  mov byte ptr [rcx + r10 + 3], 0

  jmp .next_pixel_SISD

.set_black:
  mov byte ptr [rcx + r10], 0
  mov byte ptr [rcx + r10 + 1], 0
  mov byte ptr [rcx + r10 + 2], 0
  mov byte ptr [rcx + r10 + 3], 0

.next_pixel_SISD:
  add r10, 4
  inc r13
  addss xmm3, xmm1

  jmp .loop_pixel_SISD

.next_row:
  movups xmm3, xmm0   # cx_start = [cx_1, cx_2, cx_3, cx_4]
  subps xmm2, xmm1    # cy = [cy_1 - res, cy_2 - res, cy_3 - res, cy_4 - res]
  inc r12
  jmp .loop_row

.end:
  pop r14
  pop r13
  pop r12

  ret 
