`timescale 1ns / 1ps

module tb_MiniMIPS32_Lite_FullSyS;

    //================================================================
    // 1. 信号定义
    //================================================================
    reg clk = 0;
    reg locked = 0;
    reg rxd = 1; // 串口空闲为高电平
    wire txd;
    
    // I/O 接口
    reg [31:0] sw_1 = 0;
    reg [31:0] sw_2 = 0;
    reg [7:0]  btn = 0;
    wire [31:0] led;
    wire [3:0]  seg_cs;
    wire [7:0]  seg_data;

    //================================================================
    // 2. 参数设置
    //================================================================
    localparam CLK_FREQ = 50000000; 
    localparam BAUD_RATE = 9600;
    localparam BIT_PERIOD = 1000000000 / BAUD_RATE; // 104166 ns

    //================================================================
    // 3. 实例化被测模块 (DUT)
    //================================================================
    MiniMIPS32_Lite_FullSyS dut (
        .clk(clk),
        .locked(locked),
        .rxd(rxd),
        .txd(txd),
        .sw_1(sw_1),
        .sw_2(sw_2),
        .led(led),
        .seg_cs(seg_cs),
        .seg_data(seg_data),
        .btn(btn)
    );

    //================================================================
    // 4. 时钟生成
    //================================================================
    always #10 clk = ~clk; // 50MHz

    //================================================================
    // 5. 串口发送任务 (模拟 PC -> FPGA)
    //================================================================
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            // Start bit
            rxd = 0;
            #(BIT_PERIOD);
            
            // Data bits
            for (i=0; i<8; i=i+1) begin
                rxd = data[i];
                #(BIT_PERIOD);
            end
            
            // Stop bit
            rxd = 1;
            #(BIT_PERIOD);
            #(BIT_PERIOD); // Margin
        end
    endtask

    //================================================================
    // 6. 主测试流程 & 文件输出控制
    //================================================================
    integer file_handle; // 文件句柄

initial begin
        // 1. 打开文件
        file_handle = $fopen("uart_output.txt", "w");
        if (file_handle == 0) begin
            $display("Error: Could not open output file!");
            $finish;
        end
        $display("Simulation Started. Output directed to uart_output.txt");

        // 2. 初始化信号
        clk = 0;
        locked = 0;
        rxd = 1;
        
        // 3. 【关键】加速复位 (直接赋值，不要用 force)
        // 设置为 FFFF0，只需走 16 个时钟周期 (320ns) 即可释放复位
        dut.rst_cnt = 20'hFFFF0; 
        
        // 4. 模拟上电
        #100;
        locked = 1; // PLL 锁定
        
        // 5. 等待系统复位释放
        wait(dut.rst_n == 1);
        $display("[%t] System Reset Released. CPU should start now.", $time);

        // 6. 等待 CPU 输出 "Fib Finish."
        // 给它 10ms 时间 (在 9600 波特率下，10ms 约能发 10 个字符)
        #10000000; 

        // 7. 模拟 PC 发送 'T'
        $display("[%t] Sending trigger 'T'...", $time);
        uart_send_byte("T");

        // 8. 等待响应 "All PASS!"
        // 再给 10ms
        #10000000;

        // 9. 结束
        $fclose(file_handle);
        $display("[%t] Simulation Finished. Please check uart_output.txt", $time);
        $stop;
    end

    //================================================================
    // 7. 串口接收监控 (FPGA -> PC/File)
    //================================================================
    initial begin
        forever begin
            @(negedge txd); // 检测起始位
            
            #(BIT_PERIOD / 2); // 等待到起始位中间
            
            if (txd == 0) begin
                reg [7:0] rx_byte;
                integer j;
                
                #(BIT_PERIOD); // 跳过起始位
                
                for (j=0; j<8; j=j+1) begin
                    rx_byte[j] = txd;
                    #(BIT_PERIOD);
                end
                
                // 【核心修改】输出到文件，而不是屏幕
                $fwrite(file_handle, "%c", rx_byte);
                // 如果您还想在控制台看到 HEX 值以便调试，保留下面这行：
                // $display("Received Char: %c (0x%h)", rx_byte, rx_byte);
            end
        end
    end

endmodule