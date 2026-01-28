`include "defines.v"

module MiniMIPS32_Lite(
    input  wire                  cpu_clk_50M,
    input  wire                  cpu_rst_n,
    
    output wire [`INST_ADDR_BUS] iaddr,
    input  wire [`INST_BUS]      inst,
    input  wire                  inst_rom_stall,
  
    output wire [`INST_ADDR_BUS] daddr,
    input  wire [`WORD_BUS]      drdata,
    output wire [`WORD_BUS]      dwdata,
    output wire                  dwe,
    output wire [3:0]            dce
    );
    
    wire [`WORD_BUS      ] pc;
    wire [`WORD_BUS      ] id_pc_i;
    wire [`INST_BUS      ] id_inst_i;
    
    wire [`REG_ADDR_BUS  ] ra1;
    wire [`REG_BUS       ] rd1;
    wire [`REG_ADDR_BUS  ] ra2;
    wire [`REG_BUS       ] rd2;
    
    wire [`ALUOP_BUS     ] id_aluop_o;
    wire [`ALUTYPE_BUS   ] id_alutype_o;
    wire [`REG_BUS 	     ] id_src1_o;
    wire [`REG_BUS 	     ] id_src2_o;
    wire 				   id_wreg_o;
    wire [`REG_ADDR_BUS  ] id_wa_o;
    wire [`REG_BUS       ] id_mem_data_o;
    wire                   id_branch_flag;
    wire [`INST_ADDR_BUS ] id_branch_target;
    
    wire [`ALUOP_BUS     ] exe_aluop_i;
    wire [`ALUTYPE_BUS   ] exe_alutype_i;
    wire [`REG_BUS 	     ] exe_src1_i;
    wire [`REG_BUS 	     ] exe_src2_i;
    wire 				   exe_wreg_i;
    wire [`REG_ADDR_BUS  ] exe_wa_i;
    wire [`REG_BUS       ] exe_mem_data;
    wire [`ALUOP_BUS     ] exe_aluop_o;
    wire 				   exe_wreg_o;
    wire [`REG_ADDR_BUS  ] exe_wa_o;
    wire [`REG_BUS 	     ] exe_wd_o;
    wire [`REG_BUS       ] mem_mem_data_i;
    wire [`ALUOP_BUS     ] mem_aluop_i;
    wire 				   mem_wreg_i;
    wire [`REG_ADDR_BUS  ] mem_wa_i;
    wire [`REG_BUS 	     ] mem_wd_i;
    wire [`REG_BUS       ] mem_mem_data_o;
    wire 				   mem_wreg_o;
    wire [`REG_ADDR_BUS  ] mem_wa_o;
    wire [`REG_BUS 	     ] mem_dreg_o;
    wire 				   wb_wreg_i;
    wire [`REG_ADDR_BUS  ] wb_wa_i;
    wire [`REG_BUS       ] wb_dreg_i;
    wire 				   wb_wreg_o;
    wire [`REG_ADDR_BUS  ] wb_wa_o;
    wire [`REG_BUS       ] wb_wd_o;
    wire                    stallreq_id;
    wire [5:0]              stall;

    // 结构冒险预判逻辑
    wire exe_is_mem_op = (exe_aluop_o == `MINIMIPS32_LB) ||
                         (exe_aluop_o == `MINIMIPS32_LW) ||
                         (exe_aluop_o == `MINIMIPS32_SB) ||
                         (exe_aluop_o == `MINIMIPS32_SW);
    wire exe_target_rom = (exe_wd_o[31:16] == 16'h8000);
    wire stallreq_for_rom = exe_is_mem_op && exe_target_rom;

    if_stage if_stage0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .stall(stall),
        .branch_flag_i(id_branch_flag), .branch_target_i(id_branch_target),
        .pc(pc)
    );
    assign iaddr = pc;
    
    ifid_reg ifid_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .stall(stall),
        .inst(inst), .if_pc(pc), 
        .id_inst(id_inst_i), .id_pc(id_pc_i)
    );
    id_stage id_stage0(.id_pc_i(id_pc_i), 
        .id_inst_i(id_inst_i),
        .rd1(rd1), .rd2(rd2),	  
        .ra1(ra1), .ra2(ra2), 
        .exe_wreg_i(exe_wreg_o), .exe_wa_i(exe_wa_o), .exe_wd_i(exe_wd_o), .exe_aluop_i(exe_aluop_o),
        .mem_wreg_i(mem_wreg_o), .mem_wa_i(mem_wa_o), .mem_wd_i(mem_dreg_o),
        .id_aluop_o(id_aluop_o), .id_alutype_o(id_alutype_o),
        .id_src1_o(id_src1_o), .id_src2_o(id_src2_o),
        .id_wa_o(id_wa_o), .id_wreg_o(id_wreg_o),
        .id_mem_data_o(id_mem_data_o),
        .id_branch_flag_o(id_branch_flag), .id_branch_target_o(id_branch_target),
    
        .stallreq_id(stallreq_id)
    );
    
    regfile regfile0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .we(wb_wreg_o), .wa(wb_wa_o), .wd(wb_wd_o),
        .ra1(ra1), .rd1(rd1),
        .ra2(ra2), .rd2(rd2)
    );
    idexe_reg idexe_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n), 
        .stall(stall),
        .id_alutype(id_alutype_o), .id_aluop(id_aluop_o),
        .id_src1(id_src1_o), .id_src2(id_src2_o),
        .id_wa(id_wa_o), .id_wreg(id_wreg_o),
        .id_mem_data(id_mem_data_o),
        .exe_alutype(exe_alutype_i), .exe_aluop(exe_aluop_i),
        .exe_src1(exe_src1_i), .exe_src2(exe_src2_i), 
        .exe_wa(exe_wa_i), .exe_wreg(exe_wreg_i),
        .exe_mem_data(exe_mem_data)
    );
    exe_stage exe_stage0(
        .exe_alutype_i(exe_alutype_i), .exe_aluop_i(exe_aluop_i),
        .exe_src1_i(exe_src1_i), .exe_src2_i(exe_src2_i),
        .exe_wa_i(exe_wa_i), .exe_wreg_i(exe_wreg_i),
        .exe_mem_data_i(exe_mem_data),
        .cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .exe_aluop_o(exe_aluop_o),
        .exe_wa_o(exe_wa_o), .exe_wreg_o(exe_wreg_o), .exe_wd_o(exe_wd_o),
        .exe_mem_data_o(mem_mem_data_i)
    );
    exemem_reg exemem_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),.stall(stall),
        .exe_aluop(exe_aluop_o),
        .exe_wa(exe_wa_o), .exe_wreg(exe_wreg_o), .exe_wd(exe_wd_o),
        .exe_mem_data(mem_mem_data_i),
        .mem_aluop(mem_aluop_i),
        .mem_wa(mem_wa_i), 
        .mem_wreg(mem_wreg_i),
        .mem_wd(mem_wd_i),
        .mem_mem_data(mem_mem_data_o)
    );
    mem_stage mem_stage0(.mem_aluop_i(mem_aluop_i),.stall(stall),
        .mem_wa_i(mem_wa_i), .mem_wreg_i(mem_wreg_i), .mem_wd_i(mem_wd_i),
        .mem_mem_data_i(mem_mem_data_o), 
        .drdata(drdata),
        .mem_wa_o(mem_wa_o), .mem_wreg_o(mem_wreg_o), .mem_dreg_o(mem_dreg_o),
        .daddr(daddr), .dwdata(dwdata), .dwe(dwe), .dce(dce)
    );
    memwb_reg memwb_reg0(.cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .mem_wa(mem_wa_o), .mem_wreg(mem_wreg_o), .mem_dreg(mem_dreg_o),
        .wb_wa(wb_wa_i), .wb_wreg(wb_wreg_i), .wb_dreg(wb_dreg_i)
    );
    wb_stage wb_stage0(
        .wb_wa_i(wb_wa_i), .wb_wreg_i(wb_wreg_i), .wb_dreg_i(wb_dreg_i), 
        .wb_wa_o(wb_wa_o), .wb_wreg_o(wb_wreg_o), .wb_wd_o(wb_wd_o)
    );

    ctrl ctrl0(
        .rst(cpu_rst_n), 
        .stallreq_id(stallreq_id | stallreq_for_rom), 
        .stallreq_exe(`FALSE_V),
        .stallreq_mem(inst_rom_stall), 
        .stall(stall)
    );

    // =========================================================
    //  CPU 顶层调试监控逻辑
    // =========================================================
    integer log_file;
    initial begin
        log_file = $fopen("cpu_debug.log", "w");
        if (log_file) begin
            $fdisplay(log_file, "Time(ns) | RST_N | PC_Current | ID_PC      | ID_Inst  | Stall[5:0] | BrFlag | BrTarget   | WB_Data");
            $fdisplay(log_file, "-----------------------------------------------------------------------------------------------------");
        end else begin
            $display("Error: Could not open cpu_debug.log");
        end
    end

    always @(posedge cpu_clk_50M) begin
        if (log_file) begin
            $fdisplay(log_file, "%8t | %b     | %h | %h | %h | %b     | %b      | %h | %h",
                      $time, 
                      cpu_rst_n, 
                      pc,            // 当前取指PC
                      id_pc_i,       // 译码阶段PC
                      id_inst_i,     // 译码阶段指令
                      stall,         // 全局暂停信号
                      id_branch_flag,// 跳转发生标志
                      id_branch_target, // 跳转目标
                      wb_wd_o        // 写回数据(辅助判断程序进展)
            );

            // 【异常捕捉】: 如果不在复位期间，且PC突然变为0 (注意MIPS通常从0开始复位，但运行中不应回0，除非特意跳转)
            // 如果你的PC初始值不是0 (比如是 0x80000000)，请将 32'h0 改为你的初始PC值
            if (pc == 32'h80000000 && cpu_rst_n == 1'b1) begin
                 $fdisplay(log_file, "!!! ABNORMAL RESET DETECTED: PC hit 0x0 while RST is inactive !!!");
            end
        end
    end

endmodule