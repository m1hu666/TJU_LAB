`include "defines.v"

module ifid_reg (
	input  wire 						cpu_clk_50M,
	input  wire 						cpu_rst_n,
	input  wire [5:0]                   stall,        // 暂停信号

	// 来自取指阶段的信息  
	input  wire [`INST_ADDR_BUS]       if_pc,
	
	// 来自指令存储器的信息
	input  wire [`INST_BUS     ]       inst,
	
	// 送至译码阶段的信息  
	output reg  [`INST_ADDR_BUS]       id_pc,
	output reg  [`INST_BUS     ]       id_inst
	);

	always @(posedge cpu_clk_50M) begin
	    // 复位的时候将送至译码阶段的信息清0
		if (cpu_rst_n == `RST_ENABLE) begin
			id_pc 	<= `PC_INIT;
			id_inst  <= `ZERO_WORD;
		end
		// 当ID阶段暂停而IF阶段继续时，插入气泡（NOP）
		else if (stall[2] == `TRUE_V && stall[1] == `FALSE_V) begin
		    id_pc    <= `PC_INIT;
		    id_inst  <= `ZERO_WORD;  // NOP
		end
		// 当ID阶段不暂停时，将来自取指阶段的信息寄存并送至译码阶段
		else if (stall[2] == `FALSE_V) begin
			id_pc	<= if_pc;
			id_inst  <= inst;	
		end
		// 否则保持不变（暂停）
	end

endmodule