`timescale 1ns / 1ps

module alu(
    input        [31 : 0] A,
    input        [31 : 0] B,
    input        [3  : 0] aluop,
    output logic [31 : 0] alures,
    output logic          ZF,
    output logic          OF
);

    localparam	AND   =	4'b0000;
	localparam	OR    =	4'b0001;
	localparam	XOR   =	4'b0010;
	localparam	NAND  =	4'b0011;
	localparam	NOT   =	4'b0100;
	localparam	SLL   =	4'b0101;
	localparam	SRL   =	4'b0110;
	localparam	SRA   =	4'b0111;
	localparam	MULU  =	4'b1000;
	localparam	MUL   =	4'b1001;
	localparam	ADD   =	4'b1010;
	localparam	ADDU  =	4'b1011;
	localparam	SUB   =	4'b1100;
	localparam	SUBU  =	4'b1101;
	localparam	SLT   =	4'b1110;
	localparam	SLTU  =	4'b1111;
	
    // -----------------------------
    // 中间信号
    // -----------------------------

    // 加法 A + B
    logic [31:0] add_res;
    logic        add_cout;

    // 减法 A - B = A + (~B + 1)
    logic [31:0] sub_res;
    logic        sub_cout;

    // 乘法结果（只用低 32 位输出到 alures）
    logic [63:0] mulu_res;
    logic [63:0] mul_res;

    // 逻辑、移位、比较结果
    logic [31:0] logic_res;
    logic [31:0] shift_res;
    logic [31:0] cmp_res;

    // -----------------------------
    // 行波进位加法器实例化
    // -----------------------------

    // 有符号/无符号加法的硬件实现：A + B
    rca rca_add (
        .A   (A),
        .B   (B),
        .Cin (1'b0),
        .S   (add_res),
        .Cout(add_cout)
    );

    // 有符号/无符号减法的硬件实现：A - B = A + (~B) + 1
    rca rca_sub (
        .A   (A),
        .B   (~B),
        .Cin (1'b1),
        .S   (sub_res),
        .Cout(sub_cout)
    );

    // -----------------------------
    // 乘法
    // -----------------------------

    // 无符号乘法（MULU）
    assign mulu_res = $unsigned(A) * $unsigned(B);

    // 有符号乘法（MUL）
    assign mul_res  = $signed(A)   * $signed(B);

    // -----------------------------
    // 逻辑运算
    // -----------------------------
    always_comb begin
        unique case (aluop)
            AND  : logic_res = A & B;
            OR   : logic_res = A | B;
            XOR  : logic_res = A ^ B;
            NAND : logic_res = ~(A & B);
            NOT  : logic_res = ~A;          // 只对 A 取反
            default: logic_res = 32'b0;
        endcase
    end

    // -----------------------------
    // 移位运算
    // -----------------------------
    always_comb begin
        unique case (aluop)
            SLL : shift_res = A <<  B[4:0];             // 逻辑左移
            SRL : shift_res = A >>  B[4:0];             // 逻辑右移
            SRA : shift_res = $signed(A) >>> B[4:0];    // 算术右移
            default: shift_res = 32'b0;
        endcase
    end

    // -----------------------------
    // 比较运算
    // -----------------------------
    always_comb begin
        unique case (aluop)
            // 有符号比较
            SLT : cmp_res = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;

            // 无符号比较
            SLTU: cmp_res = ($unsigned(A) < $unsigned(B)) ? 32'd1 : 32'd0;

            default: cmp_res = 32'b0;
        endcase
    end

    // -----------------------------
    // ALU 主结果选择 alures
    // -----------------------------
    always_comb begin
        unique case (aluop)
            AND, OR, XOR, NAND, NOT:
                alures = logic_res;

            SLL, SRL, SRA:
                alures = shift_res;

            ADD, ADDU:
                alures = add_res;

            SUB, SUBU:
                alures = sub_res;

            SLT, SLTU:
                alures = cmp_res;

            MULU:
                alures = mulu_res[31:0];   // 低 32 位

            MUL :
                alures = mul_res [31:0];   // 低 32 位

            default:
                alures = 32'b0;
        endcase
    end

    // -----------------------------
    // 零标志 ZF：所有操作都检查 alures 是否为 0
    // -----------------------------
    always_comb begin
        ZF = (alures == 32'b0);
    end

    // -----------------------------
    // 溢出标志 OF：仅对有符号 ADD / SUB 有效
    // 输入 A、B 为补码形式
    // -----------------------------
    always_comb begin
        OF = 1'b0;
        unique case (aluop)
            ADD: begin
                // A + B：A,B 同号，结果与 A/B 异号 => 溢出
                OF = (A[31] == B[31]) && (add_res[31] != A[31]);
            end
            SUB: begin
                // A - B：A,B 异号，结果与 A 异号 => 溢出
                OF = (A[31] != B[31]) && (sub_res[31] != A[31]);
            end
            default: OF = 1'b0;
        endcase
    end

endmodule