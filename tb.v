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

    // Instantiate DUT directly without parameters
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

    initial begin
        clk = 0;
        rst_n = 0;
        frame_done = 0;
        wr_en = 0;
        rd_en = 0;
        wr_addr = 0;
        rd_addr = 0;
        wr_data = 0;

        #20 rst_n = 1;

        // --- STEP 1: Write 16 values into initial write bank ---
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            wr_en   <= 1;
            wr_addr <= i;
            wr_data <= i + 10; // Data pattern: 10, 11, 12...
        end

        @(posedge clk);
        wr_en <= 0;

        // --- STEP 2: Trigger SWAP command ---
        @(posedge clk);
        frame_done <= 1;
        @(posedge clk);
        frame_done <= 0;

        // --- STEP 3: Read old data while writing new data ---
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            // Write new frame data
            wr_en   <= 1;
            wr_addr <= i;
            wr_data <= i + 50; // Data pattern: 50, 51, 52...

            // Read previous frame data simultaneously
            rd_en   <= 1;
            rd_addr <= i;
        end

        @(posedge clk);
        wr_en <= 0;
        rd_en <= 0;

        #20 $finish;
    end

endmodule
