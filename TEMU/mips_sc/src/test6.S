# test6.S - Load-Use冒险和流水线暂停测试
# 测试需要暂停流水线的情况
# 入口地址：0x80000000

    .text
    .globl _start
    .org 0x0000
_start:
    # 初始化数据段基地址
    lui  $28, 0x8000
    ori  $28, $28, 0x1000   # $28 = 0x80001000
    
    # 准备测试数据
    ori  $1, $0, 0x1234
    ori  $2, $0, 0x5678
    ori  $3, $0, 0xABCD
    sw   $1, 0($28)         # [0x80001000] = 0x1234
    sw   $2, 4($28)         # [0x80001004] = 0x5678
    sw   $3, 8($28)         # [0x80001008] = 0xABCD
    
    # Load-Use冒险测试1：紧邻的load和use
    lw   $4, 0($28)         # $4 = 0x1234 (load)
    addu $5, $4, $4         # $5 = $4 + $4 (use) - 需要暂停1周期
    # 预期：$5 = 0x1234 + 0x1234 = 0x2468
    
    # Load-Use冒险测试2：load后立即作为跳转条件
    ori  $6, $0, 0x0001
    sw   $6, 12($28)        # [0x8000100C] = 0x0001
    lw   $7, 12($28)        # $7 = 0x0001
    beq  $7, $6, label1     # 需要暂停（分支条件依赖load结果）
    nop
    ori  $8, $0, 0xBAD1     # 不应执行
    beq  $0, $0, label2
    nop
    
label1:
    ori  $8, $0, 0x0001     # $8 = 1
    
label2:
    # Load-Use冒险测试3：load后立即用于地址计算
    ori  $9, $0, 4
    sw   $9, 16($28)        # [0x80001010] = 4
    lw   $10, 16($28)       # $10 = 4
    lw   $11, 0($10)        # 使用刚load的值作为地址 - 需要暂停
    # 注意：这里可能会访问错误地址，仅作为测试暂停机制
    
    # Load-Use冒险测试4：多个连续load-use
    lw   $12, 0($28)        # load
    addu $13, $12, $12      # use - 暂停
    lw   $14, 4($28)        # load
    addu $15, $14, $14      # use - 暂停
    addu $16, $13, $15      # use两个之前的结果
    
    # Load-Use冒险测试5：load后间隔一条指令再use（不需要暂停）
    lw   $17, 0($28)        # load
    ori  $18, $0, 0x0100    # 中间指令
    addu $19, $17, $18      # use（有足够时间，不需要暂停）
    
    # Load-Use冒险测试6：LB指令的load-use
    ori  $20, $0, 0xFF
    sb   $20, 20($28)       # [0x80001014] = 0xFF
    lb   $21, 20($28)       # $21 = 0xFFFFFFFF (符号扩展)
    andi $22, $21, 0x00FF   # use load的结果 - 需要暂停
    # 预期：$22 = 0x00FF
    
    # Load-Use冒险测试7：load用于store的数据
    lw   $23, 0($28)        # load
    sw   $23, 24($28)       # 立即store - 需要暂停
    
    # Load-Use冒险测试8：load用于store的地址
    ori  $24, $0, 28
    sw   $24, 28($28)       # [0x8000101C] = 28
    lw   $25, 28($28)       # load
    ori  $26, $0, 0xFFFF
    sw   $26, 0($25)        # 使用load的结果作为地址 - 需要暂停
    
    # Load-Use冒险测试9：多路径依赖
    lw   $27, 0($28)        # load $27
    lw   $29, 4($28)        # load $29
    addu $30, $27, $29      # 两个源都依赖load - 需要暂停
    
    # 无load-use冒险的对照组
    ori  $1, $0, 0xAAAA
    ori  $2, $0, 0xBBBB
    addu $3, $1, $2         # 不需要暂停
    sw   $3, 32($28)
    
    # 复杂场景：load-use后再load-use
    lw   $4, 0($28)         # load1
    addu $5, $4, $4         # use1 - 暂停
    lw   $6, 4($28)         # load2
    addu $7, $6, $5         # use2（$6需要暂停，$5不需要）
    
    # 边界测试：连续三个load-use
    lw   $8, 0($28)         # load1
    addu $9, $8, $8         # use1 - 暂停
    addu $10, $9, $9        # use2 - 暂停
    addu $11, $10, $10      # use3 - 暂停
    
    # Store后立即load同一地址（不是load-use冒险）
    ori  $12, $0, 0x9999
    sw   $12, 36($28)
    lw   $13, 36($28)       # 读取刚写入的值
    addu $14, $13, $13      # 需要暂停
    
    # 结束测试
    ori  $31, $0, 0xDEAD
    
_end:
    beq  $0, $0, _end
    nop
