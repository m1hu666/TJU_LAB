module MiniMIPS32_Lite_FullSyS(
    input sys_clk,
    input sys_rst_n
    );
    
    logic cpu_clk;
    logic cpu_rst_n;
    logic locked;
    
    // 时钟分频
    clkdiv clocking0 (
    // Clock out ports
    .clk_out(cpu_clk),     // output clk_out
    // Status and control signals
    .resetn(sys_rst_n), // input resetn
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in(sys_clk ));      // input clk_in
    
    // 将locked信号转为后级电路的复位信号rst_n
    always_ff @(posedge cpu_clk or negedge locked) begin
        if(~locked) cpu_rst_n = 1'b0; 
        else        cpu_rst_n = 1'b1;
    end

    // 数据存储器相关信号
    logic [31:0] daddr;
    logic [31:0] drdata;
    logic [31:0] dwdata;
    logic        dwe;
    logic [3:0]  dce;
    
    logic [31:0] iaddr;
    logic [31:0] inst;
    
    MiniMIPS32_Lite MiniMIPS32_Lite0(
        .cpu_clk_50M(cpu_clk),
        .cpu_rst_n(cpu_rst_n),
        
        .iaddr(iaddr),
        .inst(inst),
        
        .daddr(daddr),
        .drdata(drdata),
        .dwdata(dwdata),
        .dwe(dwe),
        .dce(dce)
    );
    
    inst_rom inst_rom0 (
      .a(iaddr[15:2]),      // input wire [13 : 0] a
      .spo(inst)  // output wire [31 : 0] spo
    );
    
    // 数据存储器实例化
    // data_ram配置为16384深度(64KB)，需要14位地址
    // 添加调试输出
    // always @(posedge cpu_clk) begin
    //     if (dwe) begin
    //         $display("DEBUG FullSyS WRITE: daddr=%h, daddr[15:2]=%h, dwdata=%h", 
    //                  daddr, daddr[15:2], dwdata);
    //     end
    // end
    
    data_ram data_ram0 (
      .clk(cpu_clk),           // input wire clk
      .a(daddr[15:2]),         // input wire [13 : 0] a
      .d(dwdata),              // input wire [31 : 0] d
      .we(dwe),                // input wire we
      .spo(drdata)             // output wire [31 : 0] spo
    );
endmodule
//3023244073 hya666