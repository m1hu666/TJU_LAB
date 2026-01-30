#include <regdef.h>

    .set noreorder
    .set noat
    .section .text
    .global __start
    .global main

__start:
main:
    /* 1. 初始化 (Initialization) */
    /* 初始化栈指针 (lui + ori) */
    lui   sp, 0x8001
    ori   sp, sp, 0x3FF0

    /* 加载外设基地址 */
    lui   s1, 0xBFD0        # s1 = UART Base
    lui   s4, 0xBFD1        # s4 = LED Base

    /* 2. 打印 "Start" (Print Start) */
    /* 手动展开打印逻辑，避免使用 jal */
    lui   s0, %hi(msg_start)
    addiu s0, s0, %lo(msg_start)

print_loop_start:
    lb    a0, 0(s0)         # 加载字符
    beq   a0, zero, init_data_phase # 遇到 \0 结束
    nop

wait_tx_start:
    lb    t0, 0x03FC(s1)    # 读 UART 状态
    andi  t0, t0, 1         # 检查 TX Busy
    beq   t0, zero, wait_tx_start
    nop

    sb    a0, 0x03F8(s1)    # 发送字符
    addiu s0, s0, 1         # 指针++
    beq   zero, zero, print_loop_start # 无条件跳转
    nop

init_data_phase:
    /* 3. 数据初始化 (Data Initialization) */
    /* 在内存中填充两个数组 A 和 B */
    lui   s2, 0x8001        # s2 = RAM Base
    ori   s2, s2, 0x1000    # Array A at 0x80011000
    
    lui   s3, 0x8001
    ori   s3, s3, 0x1100    # Array B at 0x80011100

    ori   t0, zero, 16      # 循环计数 16 次
    ori   t1, zero, 0       # 初始值

init_loop:
    beq   t0, zero, calc_phase
    nop
    
    /* A[i] = i, B[i] = i */
    addiu t1, t1, 1         # val++
    sw    t1, 0(s2)
    sw    t1, 0(s3)
    
    /* 进度显示到 LED */
    sw    t1, 0(s4)

    addiu s2, s2, 4         # ptrA += 4
    addiu s3, s3, 4         # ptrB += 4
    addiu t0, t0, -1        # count--
    beq   zero, zero, init_loop
    nop

calc_phase:
    /* 4. 计算与校验 (Calculation & Checksum) */
    /* 计算 Sum = XOR_SUM( A[i] + B[i] ) */
    /* 预期结果：(1+1)^(2+2)^...^(16+16) = 2^4^...^32 = 32 (0x20) */
    
    lui   s2, 0x8001
    ori   s2, s2, 0x1000    # Reset ptrA
    lui   s3, 0x8001
    ori   s3, s3, 0x1100    # Reset ptrB
    
    ori   t0, zero, 16      # Count = 16
    ori   t5, zero, 0       # Checksum = 0

calc_loop:
    beq   t0, zero, verify_phase
    nop

    lw    t1, 0(s2)         # Load A
    lw    t2, 0(s3)         # Load B
    addu  t3, t1, t2        # t3 = A + B
    
    xor   t5, t5, t3        # Checksum ^= t3

    addiu s2, s2, 4
    addiu s3, s3, 4
    addiu t0, t0, -1
    beq   zero, zero, calc_loop
    nop

verify_phase:
    /* 5. 验证结果 (Verification) */
    /* 预期结果 0x20 (32) */
    ori   t6, zero, 0x20
    
    /* 将计算结果写入 LED (取反显示，因为低电平点亮) */
    lui   t7, 0xFFFF
    ori   t7, t7, 0xFFFF
    xor   t7, t5, t7        # t7 = ~Result
    sw    t7, 0(s4)         # LED 显示结果 (应该是 0x20，即第5个灯亮)

    bne   t5, t6, error_loop
    nop

    /* 6. 打印 "PASS" */
    lui   s0, %hi(msg_pass)
    addiu s0, s0, %lo(msg_pass)
    beq   zero, zero, print_loop_final
    nop

error_loop:
    /* 如果错误，打印 "FAIL" */
    lui   s0, %hi(msg_fail)
    addiu s0, s0, %lo(msg_fail)

print_loop_final:
    lb    a0, 0(s0)
    beq   a0, zero, finish_blink
    nop

wait_tx_final:
    lb    t0, 0x03FC(s1)
    andi  t0, t0, 1
    beq   t0, zero, wait_tx_final
    nop

    sb    a0, 0x03F8(s1)
    addiu s0, s0, 1
    beq   zero, zero, print_loop_final
    nop

finish_blink:
    /* 7. 结束闪烁 (Blink Forever) */
    /* 证明 CPU 依然在运行 */
    lui   t2, 0x0010        # 延时基数

blink_loop:
    lw    t1, 0(s4)         # 读当前 LED
    lui   t3, 0xFFFF
    ori   t3, t3, 0xFFFF
    xor   t1, t1, t3        # 取反
    sw    t1, 0(s4)         # 写回

    /* 延时 */
    ori   t0, t2, 0
delay_inner:
    addiu t0, t0, -1
    bne   t0, zero, delay_inner
    nop
    
    beq   zero, zero, blink_loop
    nop

    .section .data
msg_start: .asciz "\r\nStart"
msg_pass:  .asciz "...PASS!\r\n"
msg_fail:  .asciz "...FAIL!\r\n"