# test3.S - 分支指令测试
# 测试：BEQ, BNE, BLEZ 以及分支延迟槽和跳转目标
# 入口地址：0x80000000

    .text
    .globl _start
    .org 0x0000
_start:
    # 初始化测试数据
    ori  $1, $0, 0          # $1 = 0
    ori  $2, $0, 10         # $2 = 10
    ori  $3, $0, 10         # $3 = 10
    addiu $4, $0, -5        # $4 = -5
    
    # BEQ测试：相等跳转
    beq  $2, $3, beq_taken  # 应该跳转（10 == 10）
    ori  $5, $0, 0xBAD1     # 不应执行
beq_not_taken:
    ori  $5, $0, 0xBAD2     # 不应执行
    beq  $0, $0, beq_test_done
    nop
    
beq_taken:
    ori  $5, $0, 0x0001     # $5 = 1，标记BEQ正确跳转
    
beq_test_done:
    # BEQ测试：不等不跳转
    beq  $1, $2, beq_wrong  # 不应跳转（0 != 10）
    ori  $6, $0, 0x0002     # $6 = 2，应该执行
    beq  $0, $0, bne_test
    nop
    
beq_wrong:
    ori  $6, $0, 0xBAD3     # 不应执行
    
bne_test:
    # BNE测试：不等跳转
    bne  $1, $2, bne_taken  # 应该跳转（0 != 10）
    ori  $7, $0, 0xBAD4     # 不应执行
    
bne_not_taken:
    ori  $7, $0, 0xBAD5     # 不应执行
    beq  $0, $0, bne_test_done
    nop
    
bne_taken:
    ori  $7, $0, 0x0003     # $7 = 3，标记BNE正确跳转
    
bne_test_done:
    # BNE测试：相等不跳转
    bne  $2, $3, bne_wrong  # 不应跳转（10 == 10）
    ori  $8, $0, 0x0004     # $8 = 4，应该执行
    beq  $0, $0, blez_test
    nop
    
bne_wrong:
    ori  $8, $0, 0xBAD6     # 不应执行
    
blez_test:
    # BLEZ测试：零跳转
    blez $1, blez_zero      # 应该跳转（0 <= 0）
    ori  $9, $0, 0xBAD7     # 不应执行
    
blez_zero:
    ori  $9, $0, 0x0005     # $9 = 5，标记零测试通过
    
    # BLEZ测试：负数跳转
    blez $4, blez_neg       # 应该跳转（-5 <= 0）
    ori  $10, $0, 0xBAD8    # 不应执行
    
blez_neg:
    ori  $10, $0, 0x0006    # $10 = 6，标记负数测试通过
    
    # BLEZ测试：正数不跳转
    blez $2, blez_wrong     # 不应跳转（10 > 0）
    ori  $11, $0, 0x0007    # $11 = 7，应该执行
    beq  $0, $0, forward_test
    nop
    
blez_wrong:
    ori  $11, $0, 0xBAD9    # 不应执行
    
forward_test:
    # 前向跳转测试
    ori  $12, $0, 1
    beq  $12, $12, skip_block
    nop
    ori  $13, $0, 0xBADA    # 应该被跳过
    ori  $13, $0, 0xBADB    # 应该被跳过
    ori  $13, $0, 0xBADC    # 应该被跳过
    
skip_block:
    ori  $13, $0, 0x0008    # $13 = 8
    
    # 后向跳转测试（循环）
    ori  $14, $0, 5         # 计数器
    ori  $15, $0, 0         # 累加器
    
loop:
    addu $15, $15, $14      # $15 += $14
    addiu $14, $14, -1      # $14--
    bne  $14, $0, loop      # 如果$14 != 0，继续循环
    nop
    # 循环结束后，$15应该 = 5+4+3+2+1 = 15 = 0x0F
    
    # 结束标记
    ori  $31, $0, 0xFFFF
    
_end:
    beq  $0, $0, _end
    nop
