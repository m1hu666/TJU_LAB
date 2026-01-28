`include "defines.v"

module id_stage(
    input  wire [`INST_ADDR_BUS]    id_pc_i,
    input  wire [`INST_BUS     ]    id_inst_i,
    input  wire [`REG_BUS      ]    rd1,
    input  wire [`REG_BUS      ]    rd2,
    input  wire                     exe_wreg_i,
    input  wire [`REG_ADDR_BUS ]    exe_wa_i,
    input  wire [`REG_BUS      ]    exe_wd_i,
    input  wire [`ALUOP_BUS    ]    exe_aluop_i,
    input  wire                     mem_wreg_i,
    input  wire [`REG_ADDR_BUS ]    mem_wa_i,
    input  wire [`REG_BUS      ]    mem_wd_i,
    output wire [`ALUTYPE_BUS  ]    id_alutype_o,
    output wire [`ALUOP_BUS    ]    id_aluop_o,
    output wire [`REG_ADDR_BUS ]    id_wa_o,
    output wire                     id_wreg_o,
    output wire [`REG_BUS      ]    id_src1_o,
    output wire [`REG_BUS      ]    id_src2_o,
    output wire [`REG_BUS      ]    id_mem_data_o,
    output wire                     id_branch_flag_o,
    output wire [`INST_ADDR_BUS]    id_branch_target_o,
    output reg                      stallreq_id,
    output wire [`REG_ADDR_BUS ]    ra1,
    output wire [`REG_ADDR_BUS ]    ra2
    );

    wire [`INST_BUS] id_inst = {id_inst_i[7:0], id_inst_i[15:8], id_inst_i[23:16], id_inst_i[31:24]};
    wire [5 :0] op   = id_inst[31:26];
    wire [5 :0] func = id_inst[5 : 0];
    wire [4 :0] rd   = id_inst[15:11];
    wire [4 :0] rs   = id_inst[25:21];
    wire [4 :0] rt   = id_inst[20:16];
    wire [4 :0] sa   = id_inst[10: 6];
    wire [15:0] imm  = id_inst[15: 0];

    wire inst_reg     = ~|op;
    wire inst_add     = inst_reg & func[5]&~func[4]&~func[3]&~func[2]&~func[1]&~func[0];
    wire inst_addu    = inst_reg & func[5]&~func[4]&~func[3]&~func[2]&~func[1]& func[0];
    wire inst_subu    = inst_reg & func[5]&~func[4]&~func[3]&~func[2]& func[1]& func[0];
    wire inst_mult    = inst_reg &~func[5]& func[4]& func[3]&~func[2]&~func[1]&~func[0];
    wire inst_sll     = inst_reg &~func[5]&~func[4]&~func[3]&~func[2]&~func[1]&~func[0];
    wire inst_srav    = inst_reg &~func[5]&~func[4]&~func[3]& func[2]& func[1]& func[0];
    wire inst_and     = inst_reg & func[5]&~func[4]&~func[3]& func[2]&~func[1]&~func[0];
    wire inst_or      = inst_reg & func[5]&~func[4]&~func[3]& func[2]&~func[1]& func[0];
    wire inst_xor     = inst_reg & func[5]&~func[4]&~func[3]& func[2]& func[1]&~func[0];
    wire inst_slt     = inst_reg & func[5]&~func[4]& func[3]&~func[2]& func[1]&~func[0];
    wire inst_mfhi    = inst_reg &~func[5]& func[4]&~func[3]&~func[2]&~func[1]&~func[0];
    wire inst_mflo    = inst_reg &~func[5]& func[4]&~func[3]&~func[2]& func[1]&~func[0];
    wire inst_addiu   = ~op[5]&~op[4]& op[3]&~op[2]&~op[1]& op[0];
    wire inst_lui     = ~op[5]&~op[4]& op[3]& op[2]& op[1]& op[0];
    wire inst_ori     = ~op[5]&~op[4]& op[3]& op[2]&~op[1]& op[0];
    wire inst_andi    = ~op[5]&~op[4]& op[3]& op[2]&~op[1]&~op[0];
    wire inst_sltiu   = ~op[5]&~op[4]& op[3]&~op[2]& op[1]& op[0];
    wire inst_beq     = ~op[5]&~op[4]&~op[3]& op[2]&~op[1]&~op[0];
    wire inst_bne     = ~op[5]&~op[4]&~op[3]& op[2]&~op[1]& op[0];
    wire inst_blez    = ~op[5]&~op[4]&~op[3]& op[2]& op[1]&~op[0];
    wire inst_lw      =  op[5]&~op[4]&~op[3]&~op[2]& op[1]& op[0];
    wire inst_lb      =  op[5]&~op[4]&~op[3]&~op[2]&~op[1]&~op[0];
    wire inst_sw      =  op[5]&~op[4]& op[3]&~op[2]& op[1]& op[0];
    wire inst_sb      =  op[5]&~op[4]& op[3]&~op[2]&~op[1]&~op[0];

    wire op_add       = inst_add | inst_addu | inst_addiu | inst_lw | inst_lb | inst_sw | inst_sb;
    wire op_sub       = inst_subu;
    wire op_slt       = inst_slt | inst_sltiu;
    wire op_mult      = inst_mult;
    wire op_and       = inst_and | inst_andi;
    wire op_lui       = inst_lui;
    wire op_or        = inst_ori | inst_or;
    wire op_xor       = inst_xor;
    wire op_sll       = inst_sll;
    wire op_srav      = inst_srav;
    wire op_mfhi      = inst_mfhi;
    wire op_mflo      = inst_mflo;
    wire op_branch    = inst_beq | inst_bne | inst_blez;

    assign id_alutype_o = (op_add | op_sub | op_slt | op_mult) ? `ARITH  :
                          (op_and | op_or | op_xor | op_lui)    ? `LOGIC  :
                          (op_sll | op_srav)                    ? `SHIFT  :
                          (op_mfhi | op_mflo)                   ? `MOVE   :
                          (op_branch)                           ? `BRANCH : `NOP;

    assign id_aluop_o = (inst_add) ? `MINIMIPS32_ADD : (inst_addu) ? `MINIMIPS32_ADDU :
                        (inst_addiu) ? `MINIMIPS32_ADDIU : (inst_subu) ? `MINIMIPS32_SUBU :
                        (inst_mult) ? `MINIMIPS32_MULT : (inst_slt | inst_sltiu) ? `MINIMIPS32_SLT :
                        (inst_and) ? `MINIMIPS32_AND : (inst_andi) ? `MINIMIPS32_ANDI :
                        (inst_or) ? `MINIMIPS32_OR : (inst_ori) ? `MINIMIPS32_ORI :
                        (inst_xor) ? `MINIMIPS32_XOR : (inst_lui) ? `MINIMIPS32_LUI :
                        (inst_sll) ? `MINIMIPS32_SLL : (inst_srav) ? `MINIMIPS32_SRAV :
                        (inst_mfhi) ? `MINIMIPS32_MFHI : (inst_mflo) ? `MINIMIPS32_MFLO :
                        (inst_beq) ? `MINIMIPS32_BEQ : (inst_bne) ? `MINIMIPS32_BNE :
                        (inst_blez) ? `MINIMIPS32_BLEZ : (inst_lw) ? `MINIMIPS32_LW :
                        (inst_lb) ? `MINIMIPS32_LB : (inst_sw) ? `MINIMIPS32_SW :
                        (inst_sb) ? `MINIMIPS32_SB : `MINIMIPS32_SLL;

    assign id_wreg_o = inst_add | inst_addu | inst_subu | inst_slt | inst_and | inst_or | inst_xor | 
                       inst_addiu | inst_lui | inst_ori | inst_andi | inst_sltiu | inst_sll | inst_srav | 
                       inst_mfhi | inst_mflo | inst_lw | inst_lb;

    assign ra1 = (inst_sll) ? rd : rs;
    assign ra2 = (inst_sll | inst_srav) ? rt : (inst_blez) ? rs : rt;
    assign id_wa_o = (inst_addiu | inst_lui | inst_ori | inst_andi | inst_sltiu | inst_lw | inst_lb) ? rt : rd;

    wire [31:0] imm_sign_extended = {{16{imm[15]}}, imm};
    wire [31:0] imm_zero_extended = {16'h0, imm};
    wire [31:0] imm_lui = {imm, 16'h0};
    
    reg [`REG_BUS] src1_data;
    always @(*) begin
        if (ra1 == `REG_NOP)
            src1_data = `ZERO_WORD;
        else if ((ra1 == exe_wa_i) && (exe_wreg_i == `WRITE_ENABLE)) begin
            if (exe_aluop_i == `MINIMIPS32_LW || exe_aluop_i == `MINIMIPS32_LB) begin
                src1_data = `ZERO_WORD; 
            end else begin
                src1_data = exe_wd_i;
            end
        end
        else if ((ra1 == mem_wa_i) && (mem_wreg_i == `WRITE_ENABLE))
            src1_data = mem_wd_i;
        else
            src1_data = rd1;
    end
    
    reg [`REG_BUS] src2_data;
    always @(*) begin
        if (ra2 == `REG_NOP)
            src2_data = `ZERO_WORD;
        else if ((ra2 == exe_wa_i) && (exe_wreg_i == `WRITE_ENABLE)) begin
            if (exe_aluop_i == `MINIMIPS32_LW || exe_aluop_i == `MINIMIPS32_LB) begin
                src2_data = `ZERO_WORD;
            end else begin
                src2_data = exe_wd_i;
            end
        end
        else if ((ra2 == mem_wa_i) && (mem_wreg_i == `WRITE_ENABLE))
            src2_data = mem_wd_i;
        else
            src2_data = rd2;
    end
    
    // =========================================================
    // 调试日志文件
    // =========================================================
    integer log_file;
    initial begin
        log_file = $fopen("stall_detect_id.txt", "w");
        if (log_file) $fwrite(log_file, "Simulation Start: ID Stage Monitoring...\n");
    end

    // Load-Use 冒险检测
    always @(*) begin
        stallreq_id = `FALSE_V;
        if ((exe_aluop_i == `MINIMIPS32_LW || exe_aluop_i == `MINIMIPS32_LB) && exe_wreg_i == `WRITE_ENABLE) begin
            if ((ra1 == exe_wa_i && ra1 != `REG_NOP) || (ra2 == exe_wa_i && ra2 != `REG_NOP)) begin
                stallreq_id = `TRUE_V;
                // 输出到文件
                $fwrite(log_file, "[%t] ID DETECTED STALL: EXE Load to r%d matches ID read r%d/r%d\n", $time, exe_wa_i, ra1, ra2);
                $fflush(log_file);
            end
        end
    end
    
    assign id_src1_o = (inst_sll) ? {27'b0, sa} : src1_data;
    assign id_src2_o = (inst_addiu | inst_lw | inst_lb | inst_sw | inst_sb | inst_sltiu) ? imm_sign_extended :
                       (inst_lui) ? imm_lui :
                       (inst_ori | inst_andi) ? imm_zero_extended : src2_data;           
    assign id_mem_data_o = src2_data;

    wire [31:0] branch_offset = {{14{imm[15]}}, imm, 2'b00};
    wire [31:0] branch_target = id_pc_i + 4 + branch_offset;
    
    wire beq_taken  = inst_beq && (src1_data == src2_data);
    wire bne_taken  = inst_bne && (src1_data != src2_data);
    wire blez_taken = inst_blez && ($signed(src1_data) <= 0);
    
    assign id_branch_flag_o = (stallreq_id == `TRUE_V) ? 1'b0 : (beq_taken | bne_taken | blez_taken);
    assign id_branch_target_o = branch_target;

endmodule