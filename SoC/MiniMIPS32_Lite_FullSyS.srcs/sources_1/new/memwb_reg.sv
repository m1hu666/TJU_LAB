`include "defines.v"

module memwb_reg (
    input  wire                     cpu_clk_50M,
	input  wire                     cpu_rst_n,

	// 来自访存阶段的信息
	input  wire [`REG_ADDR_BUS  ]   mem_wa,
	input  wire                     mem_wreg,
	input  wire [`REG_BUS       ] 	mem_dreg,

	// 送至写回阶段的信息 
	output reg  [`REG_ADDR_BUS  ]   wb_wa,
	output reg                      wb_wreg,
	output reg  [`REG_BUS       ]   wb_dreg
    );

    always @(posedge cpu_clk_50M) begin
		// 复位的时候将送至写回阶段的信息清0
		if (cpu_rst_n == `RST_ENABLE) begin
			wb_wa                 <= `REG_NOP;
			wb_wreg               <= `WRITE_DISABLE;
			wb_dreg               <= `ZERO_WORD;
		end
		// 将来自访存阶段的信息寄存并送至写回阶段
		else begin
			wb_wa 	              <= mem_wa;
			wb_wreg               <= mem_wreg;
			wb_dreg               <= mem_dreg;
		end
	end

	// 临时诊断：当 mem_debug_wb_pc 为关注PC时，打印 mem->wb 转移信息（FPGA综合时无效）
	// always @(posedge cpu_clk_50M) begin
	// 	if (mem_debug_wb_pc == 32'h80000070) begin
	// 		$display("%t MEMWB_DBG: mem_wa=%0d mem_wreg=%b mem_dreg=0x%h mem_debug_wb_pc=0x%h", $time, mem_wa, mem_wreg, mem_dreg, mem_debug_wb_pc);
	// 	end
	// end

endmodule