`include "defines.v"

module if_stage (
    input cpu_clk_50M,
    input cpu_rst_n,
    input [5:0] stall,                  // 暂停信号
    
    // 分支信号
    input                       branch_flag_i,
    input  [`INST_ADDR_BUS]     branch_target_i,
    
    output logic [31:0] pc
    );
    
    wire [`INST_ADDR_BUS] pc_next;
    assign pc_next = branch_flag_i ? branch_target_i : (pc + 4);

    always @(posedge cpu_clk_50M) begin
        if (~cpu_rst_n)
            pc <= `PC_INIT;
        else if (stall[0] == `FALSE_V) begin  // PC不暂停时才更新
            pc <= pc_next;	
        end
        // 否则保持不变（暂停）
    end

endmodule