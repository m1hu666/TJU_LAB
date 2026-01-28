`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/20 21:08:28
// Design Name: 
// Module Name: fulladder
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

// 1 位全加器
module fulladder (
    input  logic A,      // 被加数位
    input  logic B,      // 加数位
    input  logic Cin,    // 来自低位的进位
    output logic S,      // 本位和
    output logic Cout    // 向高位的进位
);
    // 逻辑表达式：
    // S    = A ^ B ^ Cin
    // Cout = (A & B) | (A & Cin) | (B & Cin)
    always_comb begin
        S    = A ^ B ^ Cin;
        Cout = (A & B) | (A & Cin) | (B & Cin);
    end

endmodule
