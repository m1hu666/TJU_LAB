#include "trap.h"
    .set noat
    .globl main
    .text

main:
    ########################################################
    # 1. lui / ori
    ########################################################
    lui     $t0, 0x1234
    ori     $t0, $t0, 0xabcd      # $t0 = 0x1234ABCD

    ########################################################
    # 2. addu
    ########################################################
    addiu   $t1, $zero, 16
    addiu   $t2, $zero, 32
    addu    $t3, $t1, $t2        # $t3 = 48

    ########################################################
    # 3. andi / or / xor
    ########################################################
    ori     $t4, $zero, 0xf0f0
    andi    $t5, $t4, 0x0ff0     # $t5 = 0x000000f0

    ori     $t6, $zero, 0x00f0
    ori     $t7, $zero, 0x000f
    or      $t8, $t6, $t7        # $t8 = 0x000000ff
    xor     $t9, $t8, $t7        # $t9 = 0x000000f0

    ########################################################
    # 4. addiu / add（不溢出）
    ########################################################
    addiu   $s0, $zero, 16
    addiu   $s1, $s0, -1         # $s1 = 15

    addiu   $s2, $zero, 100
    addiu   $s3, $zero, 200
    add     $s4, $s2, $s3        # $s4 = 300

    ########################################################
    # 5. sll / srav
    ########################################################
    addiu   $s5, $zero, 3
    sll     $s6, $s5, 4          # $s6 = 48

    addiu   $s7, $zero, -16
    addiu   $t0, $zero, 2
    srav    $t1, $s7, $t0        # $t1 = -4

    ########################################################
    # 6. lw / sw / lb / sb
    ########################################################
    lui     $t2, 0x8001          # $t2 = 0x80010000
    addiu   $t2, $t2, 0

    lui     $t3, 0x1122
    ori     $t3, $t3, 0x3344     # $t3 = 0x11223344
    sw      $t3, 0($t2)
    lw      $t4, 0($t2)          # $t4 = 0x11223344

    addiu   $t5, $zero, 128      # 0x80
    sb      $t5, 4($t2)
    lb      $t6, 4($t2)          # $t6 = 0xFFFFFF80

    ########################################################
    # 7. beq / bne / blez —— 全部用标签，不用 j
    ########################################################

    # beq: 5 == 5 应跳转
    addiu   $t7, $zero, 0        # 标志：默认 0
    addiu   $t8, $zero, 5
    addiu   $t9, $zero, 5
    beq     $t8, $t9, BEQ_OK
    nop

BEQ_FAIL:                        # 不应该来到这里
    nop
    nop

BEQ_OK:
    addiu   $t7, $zero, 1        # $t7 = 1 表示 beq 正常

AFTER_BEQ:

    # bne: 3 != 4 应跳转
    addiu   $s0, $zero, 0
    addiu   $s1, $zero, 3
    addiu   $s2, $zero, 4
    bne     $s1, $s2, BNE_OK
    nop

BNE_FAIL:                        # 不应该来到这里
    nop
    nop

BNE_OK:
    addiu   $s0, $zero, 1        # $s0 = 1 表示 bne 正常

AFTER_BNE:

    # blez: x=0 应跳转；x=-1 应跳转；x=5 不应跳转

    # case1: x = 0 应跳转
    addiu   $s3, $zero, 0
    addiu   $s4, $zero, 0
    blez    $s3, BLEZ_OK1
    nop

BLEZ_FAIL1:                      # 不应该来到这里
    nop
    nop

BLEZ_OK1:
    addiu   $s4, $zero, 1        # $s4 = 1

AFTER_BLEZ1:

    # case2: x = -1 应跳转
    addiu   $s5, $zero, -1
    addiu   $s6, $zero, 0
    blez    $s5, BLEZ_OK2
    nop

BLEZ_FAIL2:                      # 不应该来到这里
    nop
    nop

BLEZ_OK2:
    addiu   $s6, $zero, 1        # $s6 = 1

AFTER_BLEZ2:

    # case3: x = 5 不应跳转
    addiu   $s7, $zero, 5
    addiu   $t0, $zero, 1        # 默认认为正确（不跳转）
    blez    $s7, BLEZ_ERR3       # 如果实现错误，会跳到 ERR3
    nop

AFTER_BLEZ3:
    ########################################################
    # 结束：GOOD TRAP
    ########################################################
    HIT_GOOD_TRAP                # stop temu

    # 错误路径：只有 blez 实现错误才会到这里
BLEZ_ERR3:
    addiu   $t0, $zero, 0        # t0=0，标记错误
    # 然后程序就结束在 GOOD_TRAP 之后（不会有 j）