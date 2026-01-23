`include "defines.v"

// 流水线控制模块，处理暂停和冲刷
module ctrl(
    input  wire                 rst,
    input  wire                 stallreq_id,    // 来自译码阶段的暂停请求
    input  wire                 stallreq_exe,   // 来自执行阶段的暂停请求（预留）
    
    output reg  [5:0]           stall           // 暂停信号，对应IF, ID, EXE, MEM, WB阶段和PC
);

    // stall[0]: PC暂停
    // stall[1]: IF阶段暂停
    // stall[2]: ID阶段暂停
    // stall[3]: EXE阶段暂停
    // stall[4]: MEM阶段暂停
    // stall[5]: WB阶段暂停

    always @(*) begin
        if (rst == `RST_ENABLE) begin
            stall = 6'b000000;
        end
        else if (stallreq_exe == `TRUE_V) begin
            // 执行阶段请求暂停，暂停PC、IF、ID、EXE阶段
            stall = 6'b001111;
        end
        else if (stallreq_id == `TRUE_V) begin
            // 译码阶段请求暂停（load-use冒险），暂停PC、IF、ID阶段
            stall = 6'b000111;
        end
        else begin
            stall = 6'b000000;
        end
    end

endmodule
