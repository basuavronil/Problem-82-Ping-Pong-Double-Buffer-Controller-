`timescale 1ns/1ps

module tb_ping_pong_buffer();

    // System Signals
    reg        clk;
    reg        rst_n;

    // Write Interface Signals
    reg        wr_en;
    reg  [3:0] wr_addr;
    reg  [7:0] wr_data;

    // Read Interface Signals
    reg        rd_en;
    reg  [3:0] rd_addr;
    wire [7:0] rd_data;

    integer i;

    // Instantiate Unit Under Test (UUT)
    ping_pong_buffer uut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

    // 100 MHz Clock Generation (10ns Period)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk     = 0;
        rst_n   = 0;
        wr_en   = 0;
        wr_addr = 0;
        wr_data = 0;
        rd_en   = 0;
        rd_addr = 0;

        // Apply Reset
        #20;
        rst_n = 1;
        #10;

        $display("-------------------------------------------------------");
        $display("=== PHASE 1: Fill Bank B (Addresses 0 to 15) ===");
        $display("-------------------------------------------------------");
        // Note: Reader must also read to location 15 so frame_done = 1 on cycle 15
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            wr_en   <= 1'b1;
            wr_addr <= i[3:0];
            wr_data <= 8'hA0 + i[7:0]; // Data pattern 0xA0 to 0xAF

            rd_en   <= 1'b1;
            rd_addr <= i[3:0]; // Dummy reads to satisfy rd_addr == 15 requirement
        end

        // Deassert signals at end of frame
        @(posedge clk);
        wr_en <= 1'b0;
        rd_en <= 1'b0;

        $display("\n[CHECK] At end of Phase 1, bank_sel = %b (Expect 1 due to swap on address 15)\n", uut.bank_sel);

        $display("-------------------------------------------------------");
        $display("=== PHASE 2: Parallel Read Bank B / Write Bank A ===");
        $display("-------------------------------------------------------");
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            // Write new data into Bank A
            wr_en   <= 1'b1;
            wr_addr <= i[3:0];
            wr_data <= 8'hB0 + i[7:0]; // Data pattern 0xB0 to 0xBF

            // Read stored data back from Bank B
            rd_en   <= 1'b1;
            rd_addr <= i[3:0];
        end

        // Deassert signals
        @(posedge clk);
        wr_en <= 1'b0;
        rd_en <= 1'b0;

        $display("\n[CHECK] At end of Phase 2, bank_sel = %b (Expect 0 due to 2nd swap)\n", uut.bank_sel);

        #30;
        $display("=======================================================");
        $display("               SIMULATION COMPLETE                   ");
        $display("=======================================================");
        $finish;
    end

    // Monitor read operations on every clock cycle
    always @(posedge clk) begin
        if (rd_en) begin
            $display("[TIME %0t ns] Read Address = %0d | Output rd_data = 8'h%h", $time, rd_addr, rd_data);
        end
    end

endmodule
