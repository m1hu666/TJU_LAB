`include "defines.v"

module exe_stage (

    // 从译码阶段获得的信息
    input  wire [`ALUTYPE_BUS	] 	exe_alutype_i,
    input  wire [`ALUOP_BUS	    ] 	exe_aluop_i,
    input  wire [`REG_BUS 		] 	exe_src1_i,
    input  wire [`REG_BUS 		] 	exe_src2_i,
    input  wire [`REG_ADDR_BUS 	] 	exe_wa_i,
    input  wire 					exe_wreg_i,
    input  wire [`REG_BUS       ]   exe_mem_data_i,
    
    // 时钟和复位信号
    input  wire                     cpu_clk_50M,
    input  wire                     cpu_rst_n,

    // 送至执行阶段的信息
    output wire [`ALUOP_BUS	    ] 	exe_aluop_o,
    output wire [`REG_ADDR_BUS 	] 	exe_wa_o,
    output wire 					exe_wreg_o,
    output wire [`REG_BUS 		] 	exe_wd_o,
    output wire [`REG_BUS       ]   exe_mem_data_o
    );

    // 直接传到下一阶段
    assign exe_aluop_o = exe_aluop_i;
    
    // HI和LO寄存器
    reg [`REG_BUS] hi;
    reg [`REG_BUS] lo;
    
    // 乘法运算临时结果
    wire [`DOUBLE_REG_BUS] mult_result;
    reg  [`DOUBLE_REG_BUS] hilo_temp;
    
    // MOVE类指令结果
    wire [`REG_BUS] moveres;
    
    // 与通用 ALU 相连的信号
    // A/B 为参与运算的两个操作数，alu_res 为 32 位结果
    wire [`REG_BUS] alu_a;
    wire [`REG_BUS] alu_b;
    logic [3:0]     alu_op;
    wire [`REG_BUS] alu_res;
    wire            alu_zf;
    wire            alu_of;

    // 统一从流水线寄存器来的两个源操作数
    // 对移位类指令，约定 A 为被移位数，B[4:0] 为移位量
    assign alu_a = (exe_aluop_i == `MINIMIPS32_SLL || exe_aluop_i == `MINIMIPS32_SRAV) ?
                   exe_src2_i : exe_src1_i;

    assign alu_b = (exe_aluop_i == `MINIMIPS32_SLL || exe_aluop_i == `MINIMIPS32_SRAV) ?
                   {27'b0, exe_src1_i[4:0]} : exe_src2_i;

    // 复用实验中的 ALU 实现，对应其内部 localparam 编码
    localparam ALU_AND  = 4'b0000;
    localparam ALU_OR   = 4'b0001;
    localparam ALU_XOR  = 4'b0010;
    localparam ALU_NAND = 4'b0011;
    localparam ALU_NOT  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_MULU = 4'b1000;
    localparam ALU_MUL  = 4'b1001;
    localparam ALU_ADD  = 4'b1010;
    localparam ALU_ADDU = 4'b1011;
    localparam ALU_SUB  = 4'b1100;
    localparam ALU_SUBU = 4'b1101;
    localparam ALU_SLT  = 4'b1110;
    localparam ALU_SLTU = 4'b1111;

    // 将流水线内部的 aluop 映射到通用 ALU 的 4 位控制信号
    always @(*) begin
        case (exe_aluop_i)
            `MINIMIPS32_AND, `MINIMIPS32_ANDI:   alu_op = ALU_AND;
            `MINIMIPS32_OR,  `MINIMIPS32_ORI:    alu_op = ALU_OR;
            `MINIMIPS32_XOR:                     alu_op = ALU_XOR;
            `MINIMIPS32_SLL:                     alu_op = ALU_SLL;
            `MINIMIPS32_SRAV:                    alu_op = ALU_SRA;   // 算术右移
            `MINIMIPS32_ADD,
            `MINIMIPS32_ADDU,
            `MINIMIPS32_ADDIU,
            `MINIMIPS32_LW,
            `MINIMIPS32_LB,
            `MINIMIPS32_SW,
            `MINIMIPS32_SB:                      alu_op = ALU_ADD;   // 地址计算也视作加法
            `MINIMIPS32_SUBU:                    alu_op = ALU_SUBU;
            `MINIMIPS32_SLT:                     alu_op = ALU_SLT;
            `MINIMIPS32_SLTIU:                   alu_op = ALU_SLTU;
            default:                             alu_op = ALU_ADD;
        endcase
    end

    // 实例化通用 ALU
    alu u_alu(
        .A     (alu_a),
        .B     (alu_b),
        .aluop (alu_op),
        .alures(alu_res),
        .ZF    (alu_zf),
        .OF    (alu_of)
    );
    
    // 调试：监控 UART 访问地址计算
    always @(*) begin
        if (exe_aluop_i == `MINIMIPS32_SB || exe_aluop_i == `MINIMIPS32_LB) begin
            $display("[EXE DBG] aluop=SB/LB, src1=0x%h, src2=0x%h, alu_a=0x%h, alu_b=0x%h, alu_res=0x%h", 
                     exe_src1_i, exe_src2_i, alu_a, alu_b, alu_res);
        end
    end
    
    /*------------------- 乘法运算 -------------------*/
    assign mult_result = $signed(exe_src1_i) * $signed(exe_src2_i);
    
    // HI/LO寄存器更新
    always @(posedge cpu_clk_50M) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            hi <= `ZERO_WORD;
            lo <= `ZERO_WORD;
        end
        else if (exe_aluop_i == `MINIMIPS32_MULT) begin
            hi <= mult_result[63:32];
            lo <= mult_result[31:0];
        end
    end
    
    /*------------------- MOVE类指令 -------------------*/
    assign moveres = (exe_aluop_i == `MINIMIPS32_MFHI) ? hi :
                     (exe_aluop_i == `MINIMIPS32_MFLO) ? lo : `ZERO_WORD;

    assign exe_wa_o   = exe_wa_i;
    assign exe_wreg_o = exe_wreg_i;
    assign exe_mem_data_o = exe_mem_data_i;

    // 根据操作类型 alutype 确定执行阶段最终的运算结果
    // LUI 指令直接使用扩展后的立即数，不经过通用 ALU
    assign exe_wd_o = (exe_aluop_i == `MINIMIPS32_LUI)      ? exe_src2_i :
                      (exe_alutype_i == `MOVE )             ? moveres    :
                      (exe_alutype_i == `LOGIC ||
                       exe_alutype_i == `SHIFT ||
                       exe_alutype_i == `ARITH)             ? alu_res    :
                      `ZERO_WORD;

endmodule