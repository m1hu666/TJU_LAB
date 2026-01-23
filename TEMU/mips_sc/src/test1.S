# test1.S - 基本算术和逻辑指令测试
# 测试：ADD, ADDU, ADDIU, SUBU, AND, OR, XOR, ORI, ANDI, LUI
# 入口地址：0x80000000

    .text
    .globl _start
    .org 0x0000
_start:
    # 初始化寄存器
    lui  $1, 0x1234         # $1 = 0x12340000
    ori  $1, $1, 0x5678     # $1 = 0x12345678
    lui  $2, 0xABCD         # $2 = 0xABCD0000
    ori  $2, $2, 0xEF00     # $2 = 0xABCDEF00
    
    # 算术指令测试
    add  $3, $1, $2         # $3 = $1 + $2 (有符号加法)
    addu $4, $1, $2         # $4 = $1 + $2 (无符号加法)
    addiu $5, $1, 0x1000    # $5 = $1 + 0x1000
    addiu $6, $1, -100      # $6 = $1 - 100 (负立即数)
    subu $7, $1, $2         # $7 = $1 - $2
    
    # 逻辑指令测试
    and  $8, $1, $2         # $8 = $1 & $2
    or   $9, $1, $2         # $9 = $1 | $2
    xor  $10, $1, $2        # $10 = $1 ^ $2
    andi $11, $1, 0xFF00    # $11 = $1 & 0x0000FF00
    ori  $12, $0, 0xFFFF    # $12 = 0x0000FFFF
    
    # 边界条件测试
    lui  $13, 0xFFFF        # $13 = 0xFFFF0000 (最大立即数)
    ori  $13, $13, 0xFFFF   # $13 = 0xFFFFFFFF (全1)
    addiu $14, $0, -1       # $14 = 0xFFFFFFFF (-1)
    addu $15, $13, $14      # $15 = 0xFFFFFFFF + 0xFFFFFFFF (溢出)
    
    # 零寄存器测试
    add  $16, $0, $1        # $16 = 0 + $1 = $1
    or   $17, $0, $2        # $17 = 0 | $2 = $2
    xor  $18, $1, $1        # $18 = $1 ^ $1 = 0
    
    # 结束标记
    lui  $31, 0xDEAD        # $31 = 0xDEAD0000
    ori  $31, $31, 0xBEEF   # $31 = 0xDEADBEEF
    
    # 无限循环
_end:
    beq  $0, $0, _end       # 跳转到自身
    nop                     # 延迟槽（虽然实现可能不需要）
