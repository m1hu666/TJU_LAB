module MiniMIPS32_Lite_FullSyS(
    input  wire         clk,            // 50MHz
    input  wire         locked,         // PLL Locked (忽略，使用内部计数器复位)
    
    input  wire         rxd,            // 串口接收
    output wire         txd,            // 串口发送
    
    input  wire [31:0]  sw_1,           
    input  wire [31:0]  sw_2,           
    output wire [31:0]  led,            
    output wire [3:0]   seg_cs,         
    output wire [7:0]   seg_data,       
    input  wire [7:0]   btn             
);

    parameter CLK_FREQ = 50000000; 
    parameter UART_BAUD = 9600;

    //======================================================================
    // 1. 纯计数器复位
    //======================================================================
    logic rst_n;
    reg [19:0] rst_cnt = 20'd0;

    always_ff @(posedge clk) begin
        if (rst_cnt != 20'hFFFFF) begin
            rst_n <= 1'b0;
            rst_cnt <= rst_cnt + 1'b1;
        end else begin
            rst_n <= 1'b1; 
        end
    end

    //======================================================================
    // 2. RXD 双级同步
    //======================================================================
    reg [1:0] rxd_sync;
    wire      rxd_safe;
    always_ff @(posedge clk) begin
        if (!rst_n) rxd_sync <= 2'b11; 
        else        rxd_sync <= {rxd_sync[0], rxd};
    end
    assign rxd_safe = rxd_sync[1]; 

    // 内部信号
    logic [31:0] cpu_iaddr, cpu_inst, cpu_daddr, cpu_drdata, cpu_dwdata;
    logic        cpu_dwe;
    logic [3:0]  cpu_dce;
    logic        inst_rom_stall;
    logic [13:0] inst_rom_addr, data_ram_addr;
    logic [31:0] inst_rom_data, data_ram_wdata, data_ram_rdata;
    logic        data_ram_we;
    logic inst_rom_access_mem, data_ram_access, uart_access, io_access;
    logic [7:0]  uart_data_reg, uart_status_reg;
    logic [31:0] led_reg, sw1_reg, sw2_reg;
    logic [3:0]  seg_reg[0:8];
    logic [7:0]  btn_reg;

    // Stall 逻辑
    reg rom_wait_done;
    always_ff @(posedge clk) begin
        if (!rst_n) rom_wait_done <= 1'b0;
        else begin
            if (inst_rom_access_mem && !rom_wait_done) rom_wait_done <= 1'b1;
            else if (rom_wait_done) rom_wait_done <= 1'b0;
        end
    end
    assign inst_rom_stall = inst_rom_access_mem && !rom_wait_done;
    assign inst_rom_addr = inst_rom_access_mem ? cpu_daddr[15:2] : cpu_iaddr[15:2];
    assign cpu_inst = inst_rom_access_mem ? 32'h00000000 : inst_rom_data;
    inst_rom inst_rom_inst (.a(inst_rom_addr), .spo(inst_rom_data));

    //======================================================================
    // 3. 地址译码
    //======================================================================
    always_comb begin
        inst_rom_access_mem = 1'b0; data_ram_access = 1'b0; uart_access = 1'b0; io_access = 1'b0;
        
        if ((cpu_daddr[31:16] == 16'h8000) && (|cpu_dce)) inst_rom_access_mem = 1'b1;
        else if ((cpu_daddr[31:16] == 16'h8001) && (|cpu_dce)) data_ram_access = 1'b1;
        
        // UART 访问放宽条件，防止死锁
        else if (cpu_daddr[31:16] == 16'hBFD0) uart_access = 1'b1;
        
        else if ((cpu_daddr[31:16] == 16'hBFD1) && (|cpu_dce)) io_access = 1'b1;
    end

    // RAM
    assign data_ram_addr = cpu_daddr[15:2];
    assign data_ram_wdata = cpu_dwdata;
    assign data_ram_we = data_ram_access & cpu_dwe;
    logic [13:0] last_write_addr; logic [31:0] last_write_data; logic last_write_valid;
    always_ff @(posedge clk) begin
        if (~rst_n) begin last_write_valid <= 0; last_write_addr <= 0; last_write_data <= 0; end
        else if (data_ram_we) begin last_write_valid <= 1; last_write_addr <= data_ram_addr; last_write_data <= data_ram_wdata; end
    end
    logic [31:0] data_ram_rdata_raw;
    data_ram data_ram_inst (.clk(clk), .a(data_ram_addr), .d(data_ram_wdata), .we(data_ram_we), .spo(data_ram_rdata_raw));
    assign data_ram_rdata = (data_ram_access && !cpu_dwe && last_write_valid && (data_ram_addr == last_write_addr)) ? last_write_data : data_ram_rdata_raw;

    //======================================================================
    // UART Logic
    //======================================================================
    logic [7:0] ext_uart_rx, ext_uart_tx;
    logic ext_uart_ready, ext_uart_clear, ext_uart_busy, ext_uart_start, ext_uart_avai;

    async_receiver #(.ClkFrequency(CLK_FREQ),.Baud(UART_BAUD)) uart_rx (
        .clk(clk), 
        .RxD(rxd_safe), // 必须使用同步信号
        .RxD_data_ready(ext_uart_ready), 
        .RxD_clear(ext_uart_clear), 
        .RxD_data(ext_uart_rx)
    );
    assign ext_uart_clear = ext_uart_ready;

    always_ff @(posedge clk) begin
        if (~rst_n) ext_uart_avai <= 1'b0;
        else if (ext_uart_ready) ext_uart_avai <= 1'b1;
        // 只要是对 Data Reg 的读操作，就清除标志，放宽 dce 检查
        else if (uart_access && !cpu_dwe && (|cpu_dce) && cpu_daddr[11:0] == 12'h3F8) ext_uart_avai <= 1'b0;
    end

    async_transmitter #(.ClkFrequency(CLK_FREQ),.Baud(UART_BAUD)) uart_tx (
        .clk(clk), .TxD(txd), .TxD_busy(ext_uart_busy), .TxD_start(ext_uart_start), .TxD_data(ext_uart_tx)
    );

    // ======================================================================
        // 4. 写请求逻辑 (确保握手信号正确，移除冷却限制)
        // ======================================================================
        logic uart_write_req;
        reg   uart_write_lock; 
    
        wire is_uart_write_addr;
        // 只有当 CPU 写使能有效、片选有效、且地址匹配时，才认定为写操作
        assign is_uart_write_addr = uart_access && cpu_dwe && (|cpu_dce) && (cpu_daddr[11:0] == 12'h3F8);
    
        always_ff @(posedge clk) begin
            if (~rst_n) begin
                uart_write_req <= 1'b0;
                uart_write_lock <= 1'b0;
            end else begin
                // 1. 只要是写地址，且还没锁住，就拉高请求信号 (Kick the transmitter)
                if (is_uart_write_addr && !uart_write_lock) begin
                    uart_write_req <= 1'b1;  // 启动发送
                    uart_write_lock <= 1'b1; // 锁定，防止一个写周期触发多次
                end 
                // 2. 当 CPU 撤销写操作（指令周期结束）时，释放锁定
                else if (!is_uart_write_addr) begin
                    uart_write_req <= 1'b0;  // 撤销请求
                    uart_write_lock <= 1'b0; // 解锁，准备下一次发送
                end 
                // 3. 默认保持低电平
                else begin
                    uart_write_req <= 1'b0;
                end
            end
        end
    
    always_ff @(posedge clk) begin
        if (~rst_n) ext_uart_start <= 1'b0;
        else if (uart_write_req && ~ext_uart_busy) ext_uart_start <= 1'b1;
        else ext_uart_start <= 1'b0;
    end
    assign ext_uart_tx = uart_data_reg;

    //======================================================================
    // 5. 寄存器读写 (Busy 状态展宽)
    //======================================================================
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            uart_data_reg <= 8'h00; uart_status_reg <= 8'h01;
            led_reg <= 32'h0; btn_reg <= 0; sw1_reg <= 0; sw2_reg <= 0;
            for(int k=0; k<9; k++) seg_reg[k] <= 0;
        end else begin
            if (is_uart_write_addr) uart_data_reg <= cpu_dwdata[7:0];
            else if (ext_uart_ready) uart_data_reg <= ext_uart_rx;
            
            // 只要在写、在启动或硬件忙，都报 Busy
            if (uart_write_req || ext_uart_start) 
                uart_status_reg[0] <= 1'b0; 
            else 
                uart_status_reg[0] <= ~ext_uart_busy;
                
            uart_status_reg[1] <= ext_uart_avai;

            if (io_access && cpu_dwe) begin
                if (cpu_daddr[15:0] == 16'h0000) led_reg <= cpu_dwdata;
                if (cpu_daddr[15:4] == 12'h001)  seg_reg[cpu_daddr[5:2]] <= cpu_dwdata[3:0];
            end
            btn_reg <= btn; sw1_reg <= sw_1; sw2_reg <= sw_2;
        end
    end

    assign led = led_reg;
    x7seg seg_ctrl (.clk(clk), .seg_wdata(seg_reg), .seg_cs(seg_cs), .seg_data(seg_data));

    // Data Mux
    always_comb begin
        cpu_drdata = 32'b0;
        if (inst_rom_access_mem) cpu_drdata = inst_rom_data;
        else if (data_ram_access) cpu_drdata = data_ram_rdata;
        else if (uart_access) begin
            if (cpu_daddr[11:0] == 12'h3F8) cpu_drdata = {24'h0, uart_data_reg};
            else                            cpu_drdata = {24'h0, uart_status_reg};
        end else if (io_access) begin
            case (cpu_daddr[15:0])
                16'h0000: cpu_drdata = led_reg;
                16'h0040: cpu_drdata = {24'h0, btn_reg};
                16'h0050: cpu_drdata = sw1_reg;
                16'h0054: cpu_drdata = sw2_reg;
                default:  cpu_drdata = 32'h0;
            endcase
        end
    end

    MiniMIPS32_Lite cpu_core (
        .cpu_clk_50M(clk), .cpu_rst_n(rst_n),
        .iaddr(cpu_iaddr), .inst(cpu_inst), .inst_rom_stall(inst_rom_stall),
        .daddr(cpu_daddr), .drdata(cpu_drdata), .dwdata(cpu_dwdata), .dwe(cpu_dwe), .dce(cpu_dce)
    );

endmodule
//3023244073 hya666