`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/20 21:34:26
// Design Name: 
// Module Name: rca
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

// 32 位行波进位加法器
module rca (
    input  logic [31:0] A,     // 加数 A
    input  logic [31:0] B,     // 加数 B
    input  logic        Cin,   // 初始进位（通常加法=0，减法=1）
    output logic [31:0] S,     // 和
    output logic        Cout   // 最高位进位
);
    // 中间进位线，C[0] 是 Cin，C[32] 是最终 Cout
    logic [32:0] C;
    assign C[0] = Cin;
    assign Cout = C[32];

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_fulladders
            fulladder fa_i (
                .A   (A[i]),
                .B   (B[i]),
                .Cin (C[i]),
                .S   (S[i]),
                .Cout(C[i+1])
            );
        end
    endgenerate

endmodule