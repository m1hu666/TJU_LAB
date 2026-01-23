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
    input  wire [`INST_ADDR_BUS]    exe_debug_wb_pc,  // 供调试使用的PC值，上板测试时务必删除该信号
    
    // 时钟和复位信号
    input  wire                     cpu_clk_50M,
    input  wire                     cpu_rst_n,

    // 送至执行阶段的信息
    output wire [`ALUOP_BUS	    ] 	exe_aluop_o,
    output wire [`REG_ADDR_BUS 	] 	exe_wa_o,
    output wire 					exe_wreg_o,
    output wire [`REG_BUS 		] 	exe_wd_o,
    output wire [`REG_BUS       ]   exe_mem_data_o,
    
    output wire [`INST_ADDR_BUS] 	debug_wb_pc  // 供调试使用的PC值，上板测试时务必删除该信号
    );

    // 直接传到下一阶段
    assign exe_aluop_o = exe_aluop_i;
    
    // HI和LO寄存器
    reg [`REG_BUS] hi;
    reg [`REG_BUS] lo;
    
    // 逻辑运算结果
    wire [`REG_BUS] logicres;       
    
    // 移位运算结果
    wire [`REG_BUS] shiftres;
    
    // 算术运算结果和临时变量
    wire [`REG_BUS] arithres;
    wire [`REG_BUS] sum_result;
    wire            overflow_sum;
    wire            src1_lt_src2;
    
    // 乘法运算临时结果
    wire [`DOUBLE_REG_BUS] mult_result;
    reg  [`DOUBLE_REG_BUS] hilo_temp;
    
    // MOVE类指令结果
    wire [`REG_BUS] moveres;
    
    /*------------------- 逻辑运算 -------------------*/
    assign logicres = (exe_aluop_i == `MINIMIPS32_AND || exe_aluop_i == `MINIMIPS32_ANDI) ? (exe_src1_i & exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_OR || exe_aluop_i == `MINIMIPS32_ORI)   ? (exe_src1_i | exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_XOR)                                     ? (exe_src1_i ^ exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_LUI)                                     ? exe_src2_i : `ZERO_WORD;
    
    /*------------------- 移位运算 -------------------*/
    assign shiftres = (exe_aluop_i == `MINIMIPS32_SLL)  ? (exe_src2_i << exe_src1_i[4:0]) :
                      (exe_aluop_i == `MINIMIPS32_SRAV) ? ($signed(exe_src2_i) >>> exe_src1_i[4:0]) : `ZERO_WORD;
    
    /*------------------- 算术运算 -------------------*/
    // 计算加法结果
    assign sum_result = exe_src1_i + exe_src2_i;
    
    // 有符号比较
    assign src1_lt_src2 = (exe_src1_i[31] && !exe_src2_i[31]) ||
                          (!exe_src1_i[31] && !exe_src2_i[31] && sum_result[31]) ||
                          (exe_src1_i[31] && exe_src2_i[31] && sum_result[31]);
    
    assign arithres = (exe_aluop_i == `MINIMIPS32_ADD || exe_aluop_i == `MINIMIPS32_ADDU || exe_aluop_i == `MINIMIPS32_ADDIU) ? sum_result :
                      (exe_aluop_i == `MINIMIPS32_SUBU) ? (exe_src1_i - exe_src2_i) :
                      (exe_aluop_i == `MINIMIPS32_SLT)  ? (src1_lt_src2 ? 32'h1 : 32'h0) :
                      (exe_aluop_i == `MINIMIPS32_SLTIU)? (exe_src1_i < exe_src2_i ? 32'h1 : 32'h0) :
                      (exe_aluop_i == `MINIMIPS32_LW || exe_aluop_i == `MINIMIPS32_LB ||
                       exe_aluop_i == `MINIMIPS32_SW || exe_aluop_i == `MINIMIPS32_SB) ? sum_result : `ZERO_WORD;
    
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
    
    // 根据操作类型alutype确定执行阶段最终的运算结果
    assign exe_wd_o = (exe_alutype_i == `LOGIC) ? logicres  :
                      (exe_alutype_i == `SHIFT) ? shiftres  :
                      (exe_alutype_i == `ARITH) ? arithres  :
                      (exe_alutype_i == `MOVE ) ? moveres   : `ZERO_WORD;
    
    assign debug_wb_pc = exe_debug_wb_pc;    // 上板测试时务必删除该语句 

endmodule