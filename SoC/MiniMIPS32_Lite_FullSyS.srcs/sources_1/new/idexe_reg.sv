`include "defines.v"

module idexe_reg (
    input  wire 				  cpu_clk_50M,
    input  wire 				  cpu_rst_n,
    input  wire [5:0]             stall,

    input  wire [`ALUTYPE_BUS  ]  id_alutype,
    input  wire [`ALUOP_BUS    ]  id_aluop,
    input  wire [`REG_BUS      ]  id_src1,
    input  wire [`REG_BUS      ]  id_src2,
    input  wire [`REG_ADDR_BUS ]  id_wa,
    input  wire                   id_wreg,
    input  wire [`REG_BUS      ]  id_mem_data,
    
    output reg  [`ALUTYPE_BUS  ]  exe_alutype,
    output reg  [`ALUOP_BUS    ]  exe_aluop,
    output reg  [`REG_BUS      ]  exe_src1,
    output reg  [`REG_BUS      ]  exe_src2,
    output reg  [`REG_ADDR_BUS ]  exe_wa,
    output reg                    exe_wreg,
    output reg  [`REG_BUS      ]  exe_mem_data
    );

    // 日志文件
    // integer log_file;
    // initial begin
    //     log_file = $fopen("stall_bubble.txt", "w");
    //     if (log_file) $fwrite(log_file, "Simulation Start: Pipeline Reg Monitoring...\n");
    // end

    always @(posedge cpu_clk_50M) begin
        if (cpu_rst_n == `RST_ENABLE) begin
            exe_alutype 	   <= `NOP;
            exe_aluop 		   <= `MINIMIPS32_SLL;
            exe_src1 		   <= `ZERO_WORD;
            exe_src2 		   <= `ZERO_WORD;
            exe_wa 			   <= `REG_NOP;
            exe_wreg    	   <= `WRITE_DISABLE;
            exe_mem_data       <= `ZERO_WORD;
        end
        // 【关键修复与日志】
        else if (stall[2] == `TRUE_V && stall[3] == `FALSE_V) begin
            exe_alutype        <= `NOP;
            exe_aluop          <= `MINIMIPS32_SLL; // NOP
            exe_src1           <= `ZERO_WORD;
            exe_src2           <= `ZERO_WORD;
            exe_wa             <= `REG_NOP;
            exe_wreg           <= `WRITE_DISABLE;
            exe_mem_data       <= `ZERO_WORD;
            
            // // 写入文件
            // $fwrite(log_file, "[%t] BUBBLE INSERTED: ID Stalled, Inserting NOP into EXE\n", $time);
            // $fflush(log_file);
        end
        else if (stall[3] == `FALSE_V) begin
            exe_alutype 	   <= id_alutype;
            exe_aluop 		   <= id_aluop;
            exe_src1 		   <= id_src1;
            exe_src2 		   <= id_src2;
            exe_wa 			   <= id_wa;
            exe_wreg		   <= id_wreg;
            exe_mem_data       <= id_mem_data;
        end
    end

endmodule