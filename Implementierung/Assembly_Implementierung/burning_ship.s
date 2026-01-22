.intel_syntax noprefix
.global burning_ship

.section .rodata
.align 4
four: 
  .float 4.0

.section .text
# void burning_ship(float complex start, size_t width, size_t height,
#                  float res, unsigned  n, unisgned char* img)

# Parameter: 
# xmm0: start real (start_x)
# xmm2: start imaginary (start_y)
# rdi: width
# rsi: height
# xmm1: resolution (res)
# rdx: n (max iterations)
# rcx: img pointer

# Variables: 
# rbx: pixel offset
# r12: row index i
# r13: column index j 
# r14: current iteration

# xmm3: current pixel_x (cx) 
# xmm4: current pixel_y (cy)
# xmm5: zx
# xmm6: zy
burning_ship:
  push rbx 
  push r12
  push r13
  push r14

  mov r9, rdx # max iterations

  # load constant for checking divergence
  movss xmm12, dword ptr[rip + four]  

  # create mask for absolute value
  mov eax, 0x7fffffff
  movd xmm9, eax 

  pshufd xmm2, xmm0, 0x55 # broadcast the imaginary part to xmm2  
  xor rbx, rbx    # pixeloffset 
  
  movss xmm3, xmm0 # cx = start_x
  movss xmm4, xmm2 # cy = start_y

  xor r12, r12 # row index i

.loop_row:
  cmp r12, rsi
  jge .end
  
  xor r13, r13 # column index j
  
.loop_pixel:
  cmp r13, rdi
  jge .next_row
  
  xor r14, r14 # iteration
  pxor xmm5, xmm5 # zx = 0
  pxor xmm6, xmm6 # zy = 0

.iterations:
  # check if less than 4
  # zx² + zy²
  movss xmm7, xmm5
  mulss xmm7, xmm7  

  movss xmm8, xmm6
  mulss xmm8, xmm8 

  addss xmm7, xmm8  
  cmpss xmm7, xmm12, 0x00000001  # cmp < 4.0
  movd eax, xmm7
  test eax, eax
  jz .set_colors  

  # check for max iterations
  cmp r14, r9
  jge .set_colors

  # compute absolute value
  # |zx|, |zy|
  andps xmm5, xmm9
  andps xmm6, xmm9
  
  # zx² - zy² + cx
  movss xmm10, xmm5 
  mulss xmm10, xmm10
  movss xmm11, xmm6
  mulss xmm11, xmm11
  subss xmm10, xmm11
  addss xmm10, xmm3  # new zx

  # 2 * |zx * zy| + cy
  movss xmm11, xmm5
  mulss xmm11, xmm6
  addss xmm11, xmm11
  addss xmm11, xmm4 # new zy 

  movss xmm5, xmm10 # set new zx
  movss xmm6, xmm11 # set new zy 
  inc r14
  jmp .iterations

  # [img + n * sizeof(Pixel) + displacement]
.set_colors:
  cmp r14, r9   # set color black if max iteration reached
  jge .set_black

  # set blue
  mov rax, r14
  mov r10, 9
  mul r10
  mov r10, 256
  div r10  
  
  mov byte ptr[rcx + rbx], dl

  # set green
  mov rax, r14
  mov r10, 5
  mul r10
  mov r10, 256
  div r10  

  mov byte ptr[rcx + rbx + 1], dl

  # set red
  mov rax, r14
  mov r10, 13
  mul r10
  mov r10, 256
  div r10  

  mov byte ptr[rcx + rbx + 2], dl

  jmp .next_pixel

.set_black:
  mov byte ptr[rcx + rbx], 0
  mov byte ptr[rcx + rbx + 1], 0
  mov byte ptr[rcx + rbx + 2], 0

.next_pixel:
  add rbx, 4
  inc r13
  addss xmm3, xmm1

  jmp .loop_pixel

.next_row: 
  movss xmm3, xmm0   # cx = start_x
  subss xmm4, xmm1   # cy = -= res
  inc r12
  jmp .loop_row
  
.end:
  pop r14
  pop r13
  pop r12
  pop rbx 

  ret
