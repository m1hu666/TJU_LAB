`include "defines.v"

module ctrl(
    input  wire                 rst,
    input  wire                 stallreq_id,
    input  wire                 stallreq_exe,
    input  wire                 stallreq_mem, // 这里实际连接的是 inst_rom_stall
    output reg [5:0]            stall
);

    always @(*) begin
        if (rst == `RST_ENABLE) begin
            stall = 6'b000000;
        end
        else if (stallreq_mem == `TRUE_V) begin
            // 【关键修改】
            // 原来是 011111 (暂停全流水线)
            // 改为   000111 (只暂停 PC, IF, ID)
            // 解释：指令ROM忙碌只影响取指。已经在流水线里的 EXE/MEM 指令应该继续跑，
            // 这样 MEM 阶段的 Store 指令就能在 1 个周期后结束，不会卡住导致重复写。
            stall = 6'b000111;
        end
        else if (stallreq_exe == `TRUE_V) begin
            stall = 6'b001111;
        end
        else if (stallreq_id == `TRUE_V) begin
            stall = 6'b000111;
        end
        else begin
            stall = 6'b000000;
        end
    end

endmodule