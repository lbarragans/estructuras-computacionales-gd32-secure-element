.section .text
    .align 2

    /* HMAC-SHA256 para key=32 bytes y mensaje=32 bytes. */
    .global hmac_sha256_fixed
hmac_sha256_fixed:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    mv s1, a0
    mv s2, a1

    /* Primer bloque interior: (key || ceros) XOR ipad. */
    la t0, g_sha_block
    la t1, hmac_key
    li t2, 0
.Linner_pad:
    li t3, 32
    bgeu t2, t3, .Linner_zero_key
    add t4, t1, t2
    lbu t5, 0(t4)
    j .Linner_xor
.Linner_zero_key:
    li t5, 0
.Linner_xor:
    xori t5, t5, 0x36
    add t4, t0, t2
    sb t5, 0(t4)
    addi t2, t2, 1
    li t3, 64
    bltu t2, t3, .Linner_pad
    jal ra, sha256_init
    la a0, g_sha_block
    jal ra, sha256_transform

    /* Segundo bloque: mensaje32, 0x80, ceros, longitud 96*8=0x0300. */
    la t0, g_sha_block
    li t1, 0
.Lclear_inner_msg:
    add t2, t0, t1
    sb zero, 0(t2)
    addi t1, t1, 1
    li t3, 64
    bltu t1, t3, .Lclear_inner_msg
    li t1, 0
.Lcopy_message:
    add t2, s1, t1
    lbu t3, 0(t2)
    add t2, t0, t1
    sb t3, 0(t2)
    addi t1, t1, 1
    li t3, 32
    bltu t1, t3, .Lcopy_message
    li t1, 0x80
    sb t1, 32(t0)
    li t1, 3
    sb t1, 62(t0)
    sb zero, 63(t0)
    mv a0, t0
    jal ra, sha256_transform
    la a0, g_inner_digest
    jal ra, sha256_export

    /* Primer bloque exterior: (key || ceros) XOR opad. */
    la t0, g_sha_block
    la t1, hmac_key
    li t2, 0
.Louter_pad:
    li t3, 32
    bgeu t2, t3, .Louter_zero_key
    add t4, t1, t2
    lbu t5, 0(t4)
    j .Louter_xor
.Louter_zero_key:
    li t5, 0
.Louter_xor:
    xori t5, t5, 0x5c
    add t4, t0, t2
    sb t5, 0(t4)
    addi t2, t2, 1
    li t3, 64
    bltu t2, t3, .Louter_pad
    jal ra, sha256_init
    la a0, g_sha_block
    jal ra, sha256_transform

    /* Segundo bloque exterior: inner32 y padding de longitud 0x0300. */
    la t0, g_sha_block
    li t1, 0
.Lclear_outer_msg:
    add t2, t0, t1
    sb zero, 0(t2)
    addi t1, t1, 1
    li t3, 64
    bltu t1, t3, .Lclear_outer_msg
    la t4, g_inner_digest
    li t1, 0
.Lcopy_inner:
    add t2, t4, t1
    lbu t3, 0(t2)
    add t2, t0, t1
    sb t3, 0(t2)
    addi t1, t1, 1
    li t3, 32
    bltu t1, t3, .Lcopy_inner
    li t1, 0x80
    sb t1, 32(t0)
    li t1, 3
    sb t1, 62(t0)
    sb zero, 63(t0)
    mv a0, t0
    jal ra, sha256_transform
    mv a0, s2
    jal ra, sha256_export

    lw s2, 4(sp)
    lw s1, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

sha256_init:
    la t0, sha256_iv
    la t1, g_sha_state
    li t2, 0
.Linit_loop:
    lw t3, 0(t0)
    sw t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    addi t2, t2, 1
    li t3, 8
    bltu t2, t3, .Linit_loop
    ret

/* a0=bloque de 64 bytes. */
sha256_transform:
    addi sp, sp, -64
    sw ra, 48(sp)
    sw s0, 44(sp)
    sw s1, 40(sp)
    sw s2, 36(sp)
    sw s3, 32(sp)
    sw s4, 28(sp)
    sw s5, 24(sp)
    sw s6, 20(sp)
    sw s7, 16(sp)
    sw s8, 12(sp)
    sw s9, 8(sp)
    sw s10, 4(sp)
    sw s11, 0(sp)
    la s10, g_sha_schedule

    /* W[0..15], entrada big-endian. */
    li t0, 0
.Lload_words:
    slli t1, t0, 2
    add t2, a0, t1
    lbu t3, 0(t2)
    lbu t4, 1(t2)
    lbu t5, 2(t2)
    lbu t6, 3(t2)
    slli t3, t3, 24
    slli t4, t4, 16
    slli t5, t5, 8
    or t3, t3, t4
    or t3, t3, t5
    or t3, t3, t6
    add t2, s10, t1
    sw t3, 0(t2)
    addi t0, t0, 1
    li t1, 16
    bltu t0, t1, .Lload_words

    /* W[i]=W[i-16]+s0+W[i-7]+s1. */
    li t0, 16
.Lextend_words:
    slli t1, t0, 2
    add t2, s10, t1
    lw t3, -60(t2)             /* W[i-15] */
    srli t4, t3, 7
    slli t5, t3, 25
    or t4, t4, t5
    srli t5, t3, 18
    slli t6, t3, 14
    or t5, t5, t6
    xor t4, t4, t5
    srli t5, t3, 3
    xor t4, t4, t5             /* small sigma0 */
    lw t3, -8(t2)              /* W[i-2] */
    srli t5, t3, 17
    slli t6, t3, 15
    or t5, t5, t6
    srli t6, t3, 19
    slli a1, t3, 13
    or t6, t6, a1
    xor t5, t5, t6
    srli t6, t3, 10
    xor t5, t5, t6             /* small sigma1 */
    lw t3, -64(t2)
    lw t6, -28(t2)
    add t3, t3, t4
    add t3, t3, t6
    add t3, t3, t5
    sw t3, 0(t2)
    addi t0, t0, 1
    li t1, 64
    bltu t0, t1, .Lextend_words

    la s11, g_sha_state
    lw s0, 0(s11)
    lw s1, 4(s11)
    lw s2, 8(s11)
    lw s3, 12(s11)
    lw s4, 16(s11)
    lw s5, 20(s11)
    lw s6, 24(s11)
    lw s7, 28(s11)
    la s9, sha256_k
    li s8, 0
.Lround:
    /* Sigma1(e). */
    srli t0, s4, 6
    slli t1, s4, 26
    or t0, t0, t1
    srli t1, s4, 11
    slli t2, s4, 21
    or t1, t1, t2
    xor t0, t0, t1
    srli t1, s4, 25
    slli t2, s4, 7
    or t1, t1, t2
    xor t0, t0, t1
    and t1, s4, s5
    not t2, s4
    and t2, t2, s6
    xor t1, t1, t2             /* Ch */
    slli t2, s8, 2
    add t3, s9, t2
    lw t3, 0(t3)
    add t4, s10, t2
    lw t4, 0(t4)
    add t5, s7, t0
    add t5, t5, t1
    add t5, t5, t3
    add t5, t5, t4             /* T1 */
    /* Sigma0(a). */
    srli t0, s0, 2
    slli t1, s0, 30
    or t0, t0, t1
    srli t1, s0, 13
    slli t2, s0, 19
    or t1, t1, t2
    xor t0, t0, t1
    srli t1, s0, 22
    slli t2, s0, 10
    or t1, t1, t2
    xor t0, t0, t1
    and t1, s0, s1
    and t2, s0, s2
    xor t1, t1, t2
    and t2, s1, s2
    xor t1, t1, t2             /* Maj */
    add t6, t0, t1             /* T2 */
    mv s7, s6
    mv s6, s5
    mv s5, s4
    add s4, s3, t5
    mv s3, s2
    mv s2, s1
    mv s1, s0
    add s0, t5, t6
    addi s8, s8, 1
    li t0, 64
    bltu s8, t0, .Lround

    lw t0, 0(s11)
    add t0, t0, s0
    sw t0, 0(s11)
    lw t0, 4(s11)
    add t0, t0, s1
    sw t0, 4(s11)
    lw t0, 8(s11)
    add t0, t0, s2
    sw t0, 8(s11)
    lw t0, 12(s11)
    add t0, t0, s3
    sw t0, 12(s11)
    lw t0, 16(s11)
    add t0, t0, s4
    sw t0, 16(s11)
    lw t0, 20(s11)
    add t0, t0, s5
    sw t0, 20(s11)
    lw t0, 24(s11)
    add t0, t0, s6
    sw t0, 24(s11)
    lw t0, 28(s11)
    add t0, t0, s7
    sw t0, 28(s11)

    lw s11, 0(sp)
    lw s10, 4(sp)
    lw s9, 8(sp)
    lw s8, 12(sp)
    lw s7, 16(sp)
    lw s6, 20(sp)
    lw s5, 24(sp)
    lw s4, 28(sp)
    lw s3, 32(sp)
    lw s2, 36(sp)
    lw s1, 40(sp)
    lw s0, 44(sp)
    lw ra, 48(sp)
    addi sp, sp, 64
    ret

/* a0=salida de 32 bytes, big-endian. */
sha256_export:
    la t0, g_sha_state
    li t1, 0
.Lexport_loop:
    lw t2, 0(t0)
    srli t3, t2, 24
    sb t3, 0(a0)
    srli t3, t2, 16
    sb t3, 1(a0)
    srli t3, t2, 8
    sb t3, 2(a0)
    sb t2, 3(a0)
    addi t0, t0, 4
    addi a0, a0, 4
    addi t1, t1, 1
    li t2, 8
    bltu t1, t2, .Lexport_loop
    ret

.section .rodata
hmac_key:
    .byte 0x31,0xA7,0x09,0xD2,0x8E,0x44,0xF1,0x6C
    .byte 0x90,0x13,0x5B,0xC8,0x22,0xE7,0x6A,0x0D
    .byte 0xB4,0x58,0xCF,0x72,0x19,0xA0,0x35,0xEB
    .byte 0x86,0x2D,0xF9,0x41,0x67,0xBC,0x04,0xD5
    .align 2
sha256_iv:
    .word 0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a
    .word 0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19
sha256_k:
    .word 0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5
    .word 0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5
    .word 0xd807aa98,0x12835b01,0x243185be,0x550c7dc3
    .word 0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174
    .word 0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc
    .word 0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da
    .word 0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7
    .word 0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967
    .word 0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13
    .word 0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85
    .word 0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3
    .word 0xd192e819,0xd6990624,0xf40e3585,0x106aa070
    .word 0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5
    .word 0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3
    .word 0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208
    .word 0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2

.section .bss
    .align 2
g_sha_state:       .space 32
g_sha_schedule:    .space 256
g_sha_block:       .space 64
g_inner_digest:    .space 32
