`include "defines.v"

module mem_stage (

    // 从执行阶段获得的信息
    input  wire [`ALUOP_BUS     ]       mem_aluop_i,
    input  wire [`REG_ADDR_BUS  ]       mem_wa_i,
    input  wire                         mem_wreg_i,
    input  wire [`REG_BUS       ]       mem_wd_i,
    input  wire [`REG_BUS       ]       mem_mem_data_i,
    input  wire [`INST_ADDR_BUS]        mem_debug_wb_pc,  // 供调试使用的PC值，上板测试时务必删除该信号
    
    // 来自数据存储器的数据
    input  wire [`WORD_BUS      ]       drdata,
    
    // 送至写回阶段的信息
    output wire [`REG_ADDR_BUS  ]       mem_wa_o,
    output wire                         mem_wreg_o,
    output wire [`REG_BUS       ]       mem_dreg_o,
    
    // 送至数据存储器的信息
    output wire [`INST_ADDR_BUS ]       daddr,
    output wire [`WORD_BUS      ]       dwdata,
    output wire                         dwe,
    output wire [3:0]                   dce,
    
    output wire [`INST_ADDR_BUS] 	    debug_wb_pc  // 供调试使用的PC值，上板测试时务必删除该信号
    );

    // 数据存储器地址
    assign daddr = mem_wd_i;
    
    // Load指令处理
    wire is_load = (mem_aluop_i == `MINIMIPS32_LW) || (mem_aluop_i == `MINIMIPS32_LB);
    
    // Store指令处理
    wire is_store = (mem_aluop_i == `MINIMIPS32_SW) || (mem_aluop_i == `MINIMIPS32_SB);
    
    // 写使能
    assign dwe = is_store;
    
    // 字节选择信号处理
    wire [1:0] addr_offset = mem_wd_i[1:0];
    
    // 根据指令类型和地址偏移生成字节使能信号
    assign dce = (mem_aluop_i == `MINIMIPS32_SW) ? 4'b1111 :
                 (mem_aluop_i == `MINIMIPS32_SB) ? (addr_offset == 2'b00 ? 4'b0001 :
                                                     addr_offset == 2'b01 ? 4'b0010 :
                                                     addr_offset == 2'b10 ? 4'b0100 : 4'b1000) : 4'b0000;
    
    // 写数据处理（根据偏移调整字节位置）
    wire [31:0] sb_data = (addr_offset == 2'b00) ? {24'h0, mem_mem_data_i[7:0]} :
                          (addr_offset == 2'b01) ? {16'h0, mem_mem_data_i[7:0], 8'h0} :
                          (addr_offset == 2'b10) ? {8'h0, mem_mem_data_i[7:0], 16'h0} :
                                                   {mem_mem_data_i[7:0], 24'h0};
    
    assign dwdata = (mem_aluop_i == `MINIMIPS32_SW) ? mem_mem_data_i : sb_data;
    
    // 读数据处理
    wire [31:0] lb_data;
    wire [7:0] byte_data = (addr_offset == 2'b00) ? drdata[7:0] :
                           (addr_offset == 2'b01) ? drdata[15:8] :
                           (addr_offset == 2'b10) ? drdata[23:16] : drdata[31:24];
    
    assign lb_data = {{24{byte_data[7]}}, byte_data};  // 符号扩展
    
    wire [31:0] load_data = (mem_aluop_i == `MINIMIPS32_LW) ? drdata :
                            (mem_aluop_i == `MINIMIPS32_LB) ? lb_data : 32'h0;
    
    // 输出到写回阶段
    assign mem_wa_o     = mem_wa_i;
    assign mem_wreg_o   = mem_wreg_i;
    assign mem_dreg_o   = is_load ? load_data : mem_wd_i;
    
    assign debug_wb_pc = mem_debug_wb_pc;    // 上板测试时务必删除该语句 

endmodule