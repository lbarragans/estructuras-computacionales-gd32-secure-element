.section .text
    .align 2
    .equ RCU_AHB1EN,0x40023830
    .equ GPIOC_CTL,0x40020800
    .equ GPIOC_OMODE,0x40020804
    .equ GPIOC_OSPD,0x40020808
    .equ GPIOC_PUD,0x4002080C
    .equ GPIOC_BOP,0x40020818
    .equ GPIOC_BC,0x40020828
    .equ GPIOC_CLOCK_BIT,4
    .equ PC13_BIT,0x2000
    .equ PC13_FIELD_MASK,0x0C000000
    .equ PC13_OUTPUT_MODE,0x04000000
    .equ PC13_SPEED_10MHZ,0x04000000
    .equ SYSTIMER_CMP_LO,0xD1000008
    .equ SYSTIMER_CMP_HI,0xD100000C
    .equ SYSTIMER_MTIMECTL,0xD1000FF8
    .equ ECLIC_INTIP7,0xD200101C
    .equ ECLIC_INTIE7,0xD200101D
    .equ ECLIC_INTATTR7,0xD200101E
    .equ ECLIC_INTCTRL7,0xD200101F
    .equ ACCEPTED,0
    .equ REJECTED_MAC,1
    .equ REJECTED_REPLAY,2
    .extern hmac_sha256_fixed

    .global main
main:
    /* PC13 como salida, LED apagado. */
    li t0, RCU_AHB1EN
    lw t1, 0(t0)
    ori t1, t1, GPIOC_CLOCK_BIT
    sw t1, 0(t0)
    fence iorw, iorw
    li t0, GPIOC_CTL
    lw t1, 0(t0)
    li t2, PC13_FIELD_MASK
    not t2, t2
    and t1, t1, t2
    li t2, PC13_OUTPUT_MODE
    or t1, t1, t2
    sw t1, 0(t0)
    li t0, GPIOC_OMODE
    lw t1, 0(t0)
    li t2, PC13_BIT
    not t2, t2
    and t1, t1, t2
    sw t1, 0(t0)
    li t0, GPIOC_OSPD
    lw t1, 0(t0)
    li t2, PC13_FIELD_MASK
    not t2, t2
    and t1, t1, t2
    li t2, PC13_SPEED_10MHZ
    or t1, t1, t2
    sw t1, 0(t0)
    li t0, GPIOC_PUD
    lw t1, 0(t0)
    li t2, PC13_FIELD_MASK
    not t2, t2
    and t1, t1, t2
    sw t1, 0(t0)
    li t0, GPIOC_BOP
    li t1, PC13_BIT
    sw t1, 0(t0)

    /* SysTimer 1 ms. */
    li t0, SYSTIMER_MTIMECTL
    li t1, 2
    sw t1, 0(t0)
    li t0, SYSTIMER_CMP_LO
    li t1, -1
    sw t1, 0(t0)
    li t0, SYSTIMER_CMP_HI
    sw zero, 0(t0)
    li t0, SYSTIMER_CMP_LO
    li t1, 40000
    sw t1, 0(t0)
    li t0, ECLIC_INTIP7
    sb zero, 0(t0)
    li t0, ECLIC_INTATTR7
    li t1, 2
    sb t1, 0(t0)
    li t0, ECLIC_INTCTRL7
    sb zero, 0(t0)
    li t0, ECLIC_INTIE7
    li t1, 1
    sb t1, 0(t0)
    li t0, 8
    csrs mstatus, t0
    li t1, 500
    la t0, g_next_test_ms
    sw t1, 0(t0)

.Lmain_loop:
    la t0, g_systimer_ticks
    lw s0, 0(t0)
    la t0, g_next_test_ms
    lw t1, 0(t0)
    sub t2, s0, t1
    blt t2, zero, .Lindicator
    la t0, g_script_step
    lw a0, 0(t0)
    jal ra, run_auth_step
    la t0, g_last_auth_result
    sw a0, 0(t0)
    beqz a0, .Lauth_ok
    la t0, g_authentication_rejected
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)
    li t2, REJECTED_MAC
    bne a0, t2, .Lcheck_replay
    la t0, g_expected_mac_failures
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)
    j .Lstart_reject
.Lcheck_replay:
    li t2, REJECTED_REPLAY
    bne a0, t2, .Lstart_reject
    la t0, g_expected_replays
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)
.Lstart_reject:
    li t1, 1
    la t0, g_indicator_pulses
    sw t1, 0(t0)
    li t1, 650
    j .Lstart_indicator
.Lauth_ok:
    la t0, g_authentication_accepted
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)
    li t1, 2
    la t0, g_indicator_pulses
    sw t1, 0(t0)
    li t1, 120
.Lstart_indicator:
    la t0, g_indicator_on_ms
    sw t1, 0(t0)
    la t0, g_indicator_state
    li t2, 1
    sw t2, 0(t0)
    la t0, g_indicator_deadline
    add t1, s0, t1
    sw t1, 0(t0)
    li t0, GPIOC_BC
    li t1, PC13_BIT
    sw t1, 0(t0)

    la t0, g_script_step
    lw t1, 0(t0)
    addi t1, t1, 1
    li t2, 5
    bltu t1, t2, .Lnext_regular
    sw zero, 0(t0)
    la t0, g_sequence_cycles
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)
    li t1, 1700
    add t1, s0, t1
    j .Lnext_store
.Lnext_regular:
    sw t1, 0(t0)
    addi t1, s0, 850
.Lnext_store:
    la t0, g_next_test_ms
    sw t1, 0(t0)

.Lindicator:
    mv a0, s0
    jal ra, indicator_update
    la t0, g_background_iterations
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)
    j .Lmain_loop

/* a0=destino, a1=seed. */
make_challenge:
    li t0, 0
.Lchallenge_loop:
    li t1, 13
    mul t2, t0, t1
    add t2, t2, a1
    add t3, a0, t0
    sb t2, 0(t3)
    addi t0, t0, 1
    li t1, 32
    bltu t0, t1, .Lchallenge_loop
    ret

/* a0=destino, a1=origen. */
copy32:
    li t0, 0
.Lcopy32_loop:
    add t1, a1, t0
    lbu t2, 0(t1)
    add t1, a0, t0
    sb t2, 0(t1)
    addi t0, t0, 1
    li t1, 32
    bltu t0, t1, .Lcopy32_loop
    ret

/* Comparacion acumulativa. Devuelve a0=1 si iguales. */
equal32:
    li t0, 0
    li t1, 0
.Lequal_loop:
    add t2, a0, t0
    lbu t3, 0(t2)
    add t2, a1, t0
    lbu t4, 0(t2)
    xor t3, t3, t4
    or t1, t1, t3
    addi t0, t0, 1
    li t2, 32
    bltu t0, t2, .Lequal_loop
    seqz a0, t1
    ret

/* Verifica replay y HMAC. */
verify_response:
    addi sp, sp, -16
    sw ra, 12(sp)
    la t0, g_verification_attempts
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)
    la t0, g_has_last_challenge
    lw t1, 0(t0)
    beqz t1, .Lverify_mac
    la a0, g_challenge
    la a1, g_last_accepted_challenge
    jal ra, equal32
    beqz a0, .Lverify_mac
    li a0, REJECTED_REPLAY
    j .Lverify_return
.Lverify_mac:
    la a0, g_challenge
    la a1, g_expected_response
    jal ra, hmac_sha256_fixed
    la a0, g_expected_response
    la a1, g_response
    jal ra, equal32
    bnez a0, .Lverify_accept
    li a0, REJECTED_MAC
    j .Lverify_return
.Lverify_accept:
    la a0, g_last_accepted_challenge
    la a1, g_challenge
    jal ra, copy32
    la t0, g_has_last_challenge
    li t1, 1
    sw t1, 0(t0)
    li a0, ACCEPTED
.Lverify_return:
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

/* a0=paso, devuelve resultado. */
run_auth_step:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s1, 8(sp)
    mv s1, a0
    beqz s1, .Lstep0
    li t0, 1
    beq s1, t0, .Lstep1
    li t0, 2
    beq s1, t0, .Lstep2
    li t0, 3
    beq s1, t0, .Lstep3
    j .Lstep4
.Lstep0:
    la a0, g_challenge
    li a1, 0x21
    jal ra, make_challenge
    la a0, g_challenge
    la a1, g_response
    jal ra, hmac_sha256_fixed
    j .Lcommand_done
.Lstep1:
    la t0, g_challenge
    lbu t1, 3(t0)
    xori t1, t1, 1
    sb t1, 3(t0)
    j .Ldo_verify
.Lstep2:
    la a0, g_challenge
    li a1, 0x62
    jal ra, make_challenge
    la a0, g_challenge
    la a1, g_response
    jal ra, hmac_sha256_fixed
    la t0, g_response
    lbu t1, 12(t0)
    xori t1, t1, 0x80
    sb t1, 12(t0)
    j .Lcommand_done
.Lstep3:
    la a0, g_challenge
    li a1, 0xa4
    jal ra, make_challenge
    la a0, g_challenge
    la a1, g_response
    jal ra, hmac_sha256_fixed
    la a0, g_saved_challenge
    la a1, g_challenge
    jal ra, copy32
    la a0, g_saved_response
    la a1, g_response
    jal ra, copy32
    j .Lcommand_done
.Lstep4:
    la a0, g_challenge
    la a1, g_saved_challenge
    jal ra, copy32
    la a0, g_response
    la a1, g_saved_response
    jal ra, copy32
    j .Ldo_verify
.Lcommand_done:
    la t0, g_commands_executed
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)
.Ldo_verify:
    jal ra, verify_response
    lw s1, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

/* LED no bloqueante: a0=now. */
indicator_update:
    la t0, g_indicator_state
    lw t1, 0(t0)
    beqz t1, .Lind_return
    la t2, g_indicator_deadline
    lw t3, 0(t2)
    sub t4, a0, t3
    blt t4, zero, .Lind_return
    li t3, 1
    bne t1, t3, .Lind_off_state
    li t3, GPIOC_BOP
    li t4, PC13_BIT
    sw t4, 0(t3)
    la t3, g_indicator_pulses
    lw t4, 0(t3)
    addi t4, t4, -1
    sw t4, 0(t3)
    beqz t4, .Lind_done
    li t1, 2
    sw t1, 0(t0)
    addi t4, a0, 120
    sw t4, 0(t2)
    ret
.Lind_off_state:
    li t3, GPIOC_BC
    li t4, PC13_BIT
    sw t4, 0(t3)
    li t1, 1
    sw t1, 0(t0)
    la t3, g_indicator_on_ms
    lw t4, 0(t3)
    add t4, a0, t4
    sw t4, 0(t2)
    ret
.Lind_done:
    sw zero, 0(t0)
.Lind_return:
    ret

    .global eclic_mtip_handler
eclic_mtip_handler:
    li t0, ECLIC_INTIP7
    sb zero, 0(t0)
    la t0, g_systimer_ticks
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)
    ret

.section .bss
    .align 2
    .global g_challenge
g_challenge:                  .space 32
    .global g_response
g_response:                   .space 32
g_expected_response:          .space 32
g_saved_challenge:            .space 32
g_saved_response:             .space 32
g_last_accepted_challenge:    .space 32
g_has_last_challenge:         .word 0
    .global g_commands_executed
g_commands_executed:         .word 0
    .global g_verification_attempts
g_verification_attempts:     .word 0
    .global g_authentication_accepted
g_authentication_accepted:   .word 0
    .global g_authentication_rejected
g_authentication_rejected:   .word 0
    .global g_expected_mac_failures
g_expected_mac_failures:     .word 0
    .global g_expected_replays
g_expected_replays:          .word 0
g_script_step:               .word 0
g_sequence_cycles:           .word 0
g_last_auth_result:          .word 0
g_systimer_ticks:            .word 0
g_next_test_ms:              .word 0
g_indicator_state:           .word 0
g_indicator_deadline:        .word 0
g_indicator_pulses:          .word 0
g_indicator_on_ms:           .word 0
g_background_iterations:    .word 0
