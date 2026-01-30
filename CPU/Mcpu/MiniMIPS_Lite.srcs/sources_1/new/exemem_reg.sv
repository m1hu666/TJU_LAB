`include "defines.v"

module exemem_reg (
    input  wire 				cpu_clk_50M,
    input  wire 				cpu_rst_n,
    
    // 新增：接收暂停信号
    input  wire [5:0]           stall,

    input  wire [`ALUOP_BUS   ] exe_aluop,
    input  wire [`REG_ADDR_BUS] exe_wa,
    input  wire                 exe_wreg,
    input  wire [`REG_BUS 	  ] exe_wd,
    input  wire [`REG_BUS     ] exe_mem_data,
    
    output reg  [`ALUOP_BUS   ] mem_aluop,
    output reg  [`REG_ADDR_BUS] mem_wa,
    output reg                  mem_wreg,
    output reg  [`REG_BUS 	  ] mem_wd,
    output reg  [`REG_BUS     ] mem_mem_data
    );

    always @(posedge cpu_clk_50M) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            mem_aluop       <= `MINIMIPS32_SLL;
            mem_wa 			<= `REG_NOP;
            mem_wreg   		<= `WRITE_DISABLE;
            mem_wd   		<= `ZERO_WORD;
            mem_mem_data    <= `ZERO_WORD;
        end
        // EXE暂停但MEM继续时，插入气泡(NOP)，防止指令重复执行
        else if (stall[3] == `TRUE_V && stall[4] == `FALSE_V) begin
            mem_aluop       <= `MINIMIPS32_SLL; // NOP
            mem_wa 			<= `REG_NOP;
            mem_wreg   		<= `WRITE_DISABLE;
            mem_wd   		<= `ZERO_WORD;
            mem_mem_data    <= `ZERO_WORD;
        end
        // 正常流动
        else if (stall[3] == `FALSE_V) begin
            mem_aluop       <= exe_aluop;
            mem_wa 			<= exe_wa;
            mem_wreg 		<= exe_wreg;
            mem_wd 		    <= exe_wd;
            mem_mem_data    <= exe_mem_data;
        end
        // 如果 stall[4] == TRUE，则保持输出不变(Hold)
    end
endmodule