# test7.S - 综合测试和边界条件
# 综合测试所有指令类型，包括各种边界条件和特殊情况
# 入口地址：0x80000000

    .text
    .globl _start
    .org 0x0000
_start:
    # 边界条件1：零寄存器不可修改
    ori  $0, $0, 0xFFFF     # 尝试写$0（应该无效）
    addiu $0, $0, 1000      # 尝试写$0（应该无效）
    addu $1, $0, $0         # $1 = 0 ($0始终为0)
    
    # 边界条件2：最大和最小立即数
    lui  $2, 0xFFFF         # 最大正立即数
    ori  $2, $2, 0xFFFF     # $2 = 0xFFFFFFFF (-1)
    addiu $3, $0, -1        # $3 = 0xFFFFFFFF (-1)
    addiu $4, $0, 32767     # 最大正16位立即数
    addiu $5, $0, -32768    # 最小负16位立即数
    
    # 边界条件3：算术溢出
    lui  $6, 0x7FFF
    ori  $6, $6, 0xFFFF     # $6 = 0x7FFFFFFF (最大正整数)
    ori  $7, $0, 1
    addu $8, $6, $7         # $8 = 0x80000000 (溢出到负数)
    lui  $9, 0x8000         # $9 = 0x80000000 (最小负整数)
    subu $10, $9, $7        # $10 = 0x7FFFFFFF (下溢到正数)
    
    # 边界条件4：移位边界
    ori  $11, $0, 1
    sll  $12, $11, 0        # 移位0位
    sll  $13, $11, 31       # 移位31位（最大）
    ori  $14, $0, 31
    srav $15, $13, $14      # 算术右移31位
    
    # 边界条件5：分支到自身和分支到下一条
    beq  $0, $0, self_branch
self_branch:
    ori  $16, $0, 0x0001
    beq  $0, $0, next_instr
next_instr:
    ori  $17, $0, 0x0002
    
    # 综合场景1：数组求和
    lui  $28, 0x8000
    ori  $28, $28, 0x1000   # 数据段基地址
    
    # 初始化数组
    ori  $18, $0, 10
    sw   $18, 0($28)        # array[0] = 10
    ori  $18, $0, 20
    sw   $18, 4($28)        # array[1] = 20
    ori  $18, $0, 30
    sw   $18, 8($28)        # array[2] = 30
    ori  $18, $0, 40
    sw   $18, 12($28)       # array[3] = 40
    ori  $18, $0, 50
    sw   $18, 16($28)       # array[4] = 50
    
    # 求和循环
    ori  $19, $0, 0         # sum = 0
    ori  $20, $0, 0         # i = 0
    ori  $21, $0, 5         # n = 5
    
sum_loop:
    sll  $22, $20, 2        # offset = i * 4
    addu $23, $28, $22      # address = base + offset
    lw   $24, 0($23)        # load array[i]
    addu $19, $19, $24      # sum += array[i]
    addiu $20, $20, 1       # i++
    slt  $25, $20, $21      # i < n ?
    bne  $25, $0, sum_loop  # 继续循环
    nop
    # 预期：$19 = 10+20+30+40+50 = 150
    
    # 综合场景2：阶乘计算 (5!)
    ori  $26, $0, 5         # n = 5
    ori  $27, $0, 1         # result = 1
    
factorial_loop:
    blez $26, factorial_done
    nop
    addu $27, $0, $0        # 清零累加器
    ori  $29, $0, 0         # counter
factorial_mult:            # 用加法实现乘法
    beq  $29, $26, mult_done
    nop
    addu $27, $27, $27      # 这只是示例，实际应累加之前的result
    addiu $29, $29, 1
    beq  $0, $0, factorial_mult
    nop
mult_done:
    addiu $26, $26, -1
    beq  $0, $0, factorial_loop
    nop
factorial_done:
    
    # 综合场景3：字节操作和字拼接
    ori  $1, $0, 0x12
    ori  $2, $0, 0x34
    ori  $3, $0, 0x56
    ori  $4, $0, 0x78
    
    sb   $1, 100($28)       # byte 0
    sb   $2, 101($28)       # byte 1
    sb   $3, 102($28)       # byte 2
    sb   $4, 103($28)       # byte 3
    lw   $5, 100($28)       # $5 = 0x78563412 (小端)
    
    # 综合场景4：位操作提取字段
    lui  $6, 0xABCD
    ori  $6, $6, 0xEF12     # $6 = 0xABCDEF12
    
    # 提取低8位
    andi $7, $6, 0x00FF     # $7 = 0x12
    
    # 提取高8位（需要移位）
    ori  $8, $0, 24
    srav $9, $6, $8
    andi $9, $9, 0x00FF     # $9 = 0xAB
    
    # 提取中间16位
    ori  $10, $0, 8
    srav $11, $6, $10
    andi $11, $11, 0xFFFF   # $11 = 0xCDEF
    
    # 边界条件6：所有寄存器使用测试
    ori  $1, $0, 1
    ori  $2, $0, 2
    ori  $3, $0, 3
    ori  $4, $0, 4
    ori  $5, $0, 5
    ori  $6, $0, 6
    ori  $7, $0, 7
    ori  $8, $0, 8
    addu $9, $1, $8         # $9 = 9
    addu $10, $2, $8        # $10 = 10
    addu $11, $3, $8        # $11 = 11
    
    # 最终测试：复杂表达式 ((a+b)*(c-d)) & mask
    ori  $12, $0, 10        # a = 10
    ori  $13, $0, 20        # b = 20  
    ori  $14, $0, 50        # c = 50
    ori  $15, $0, 30        # d = 30
    addu $16, $12, $13      # $16 = a + b = 30
    subu $17, $14, $15      # $17 = c - d = 20
    # 乘法用循环实现
    ori  $18, $0, 0         # result
    ori  $19, $0, 0         # counter
mult_loop:
    beq  $19, $17, mult_end
    nop
    addu $18, $18, $16
    addiu $19, $19, 1
    beq  $0, $0, mult_loop
    nop
mult_end:
    # $18 = 30 * 20 = 600 = 0x258
    andi $20, $18, 0x0FFF   # mask
    
    # 结束标记
    lui  $31, 0xDEAD
    ori  $31, $31, 0xBEEF   # $31 = 0xDEADBEEF
    
_end:
    beq  $0, $0, _end
    nop
