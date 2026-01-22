.intel_syntax noprefix
.global burning_ship

.section .rodata
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

.align 16
green:
    .int 5
    .int 5
    .int 5
    .int 5

.align 16
red:
    .int 9
    .int 9
    .int 9
    .int 9

.align 16
color_mask:
    .long 255
    .long 255
    .long 255
    .long 255

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
  push r14

  xor r10, r10

  mov r8, rdx

  movaps xmm5, [rip + pixel_offset]
  pshufd xmm1, xmm1, 0
  mulps xmm5, xmm1
  
  movaps xmm6, [rip + abs_mask]
  
  movaps xmm7, [rip + divergence_check]
  
  pshufd xmm2, xmm0, 0x55

  pshufd xmm0, xmm0, 0 # start_x
  
  movaps xmm3, xmm5
  addps xmm3, xmm0      # current pixel_x
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

  pcmpeqd xmm12, xmm12 # reset active mask
  pxor xmm8, xmm8   # iterations
  pxor xmm10, xmm10   # Zx
  pxor xmm11, xmm11 # Zy 
  
.iterations_SIMD:
  andps xmm10, xmm6
  andps xmm11, xmm6
  
  # divergence_check
  movaps xmm13, xmm10
  mulps xmm13, xmm13

  movaps xmm14, xmm11
  mulps xmm14, xmm14

  addps xmm13, xmm14
  cmpps xmm13, xmm7, 0x00000001  # check if less than 4.0
  
  # check if all lanes reached max iteration
  movaps xmm14, xmm8
  cmpps xmm14, xmm9, 0x00000001   # cmp < max iteration

  # combine divergence check and max iteration check
  andps xmm13, xmm14
  andps xmm12, xmm13  # active mask (OxFFFFFFFF = still active; 
                      # 0x00000000 = diverged or max n reached)
  movmskps eax, xmm12
  test eax, eax
  jz .set_colors_SIMD

  # zx² - zy² + cx
  movaps xmm13, xmm10
  mulps xmm13, xmm13
  movaps xmm14, xmm11
  mulps xmm14, xmm14
  subps xmm13, xmm14
  addps xmm13, xmm3  # new zx

  # 2 * |zx * zy| + cy
  movaps xmm14, xmm11
  mulps xmm14, xmm10
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
  movaps xmm13, xmm12
  psrld xmm13, 31
  paddd xmm8, xmm13 
  jmp .iterations_SIMD

.set_colors_SIMD:
  movdqa xmm13, xmm9
  pcmpgtd xmm13, xmm8 
  andps xmm8, xmm13  # flip max iteration to zero

  # set blue
  movdqa xmm13, [rip + blue]
  pmulld xmm13, xmm8
  pand xmm13, [rip + color_mask]

  packusdw xmm13, xmm13   # convert double word to word
  packuswb xmm13, xmm13   # convert word to byte

  # set green 
  movdqa xmm10, [rip + green]
  pmulld xmm10, xmm8
  pand xmm10, [rip + color_mask]

  packusdw xmm10, xmm10
  packuswb xmm10, xmm10

  # set red
  movdqa xmm11, [rip + red]
  pmulld xmm11, xmm8
  pand xmm11, [rip + color_mask]  

  packusdw xmm11, xmm11
  packuswb xmm11, xmm11

  punpcklbw xmm13, xmm10
  punpcklwd xmm13, xmm11

  movdqa [rcx + r10], xmm13

.next_pixels_SIMD:
  add r10, 16
  add r13, 4
  
  cvtsi2ss xmm13, r13
  pshufd xmm13, xmm13, 0
  mulps xmm13, xmm1
  movaps xmm3, xmm0
  addps xmm3, xmm13

  jmp .loop_pixel_SIMD

.loop_pixel_SISD:
  cmp r13, rdi
  jge .next_row

  xor r11, r11        # iteration
  pxor xmm10, xmm10   # zx
  pxor xmm11, xmm11   # zy

  # xmm8, 12, 13, 14 free to use

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
  addss xmm11, xmm4  # new zy

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
  movaps xmm3, xmm0   # cx_start = [cx_1, cx_2, cx_3, cx_4]
  subps xmm4, xmm1    # cy = [cy_1 - res, cy_2 - res, cy_3 - res, cy_4 - res]
  inc r12
  jmp .loop_row

.end:
  pop r14
  pop r13
  pop r12


