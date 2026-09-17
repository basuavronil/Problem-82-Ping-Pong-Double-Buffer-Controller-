`timescale 1ns/1ps

module tb_ping_pong_buffer;

    reg       clk;
    reg       rst_n;
    reg       frame_done;
    reg       wr_en;
    reg [3:0] wr_addr;
    reg [7:0] wr_data;
    reg       rd_en;
    reg [3:0] rd_addr;
    wire [7:0] rd_data;

    // Instantiate DUT
    ping_pong_buffer dut (
        .clk(clk),
        .rst_n(rst_n),
        .frame_done(frame_done),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

    // Clock Generation (100MHz)
    always #5 clk = ~clk;

    integer i;

    // Monitor for Real-time Console Output
    initial begin
        $monitor("Time=%0t | rst_n=%b | bank_sel=%b | frame_done=%b | wr_en=%b wr_addr=%0d wr_data=0x%0h | rd_en=%b rd_addr=%0d rd_data=0x%0h",
                 $time, rst_n, dut.bank_sel, frame_done, wr_en, wr_addr, wr_data, rd_en, rd_addr, rd_data);
    end

    initial begin
        // Waveform Dumping for GTKWave / EDA Playground
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_ping_pong_buffer);

        clk = 0;
        rst_n = 0;
        frame_done = 0;
        wr_en = 0;
        rd_en = 0;
        wr_addr = 0;
        rd_addr = 0;
        wr_data = 0;

        #20 rst_n = 1;

        // Step 1: Write initial dataset to Bank B
        $display("\n--- Starting Frame 1 Writes ---");
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            wr_en   <= 1;
            wr_addr <= i;
            wr_data <= i + 10;
        end

        @(posedge clk);
        wr_en <= 0;

        // Step 2: Swap banks
        $display("\n--- Triggering Bank Swap (frame_done) ---");
        @(posedge clk);
        frame_done <= 1;
        @(posedge clk);
        frame_done <= 0;

        // Step 3: Write new dataset to Bank A while reading old dataset from Bank B
        $display("\n--- Starting Frame 2 Writes & Frame 1 Reads Simultaneously ---");
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            wr_en   <= 1;
            wr_addr <= i;
            wr_data <= i + 50;

            rd_en   <= 1;
            rd_addr <= i;
        end

        @(posedge clk);
        wr_en <= 0;
        rd_en <= 0;

        #20;
        $display("\n--- Simulation Complete ---");
        $finish;
    end

endmodule
