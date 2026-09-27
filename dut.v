module ping_pong_buffer (
    input  wire       clk,
    input  wire       rst_n,

    // Write Interface (Producer)
    input  wire       wr_en,
    input  wire [3:0] wr_addr,
    input  wire [7:0] wr_data,

    // Read Interface (Consumer)
    input  wire       rd_en,
    input  wire [3:0] rd_addr,
    output reg  [7:0] rd_data,

    // Status Output Signal
    output wire       frame_done
);

    // Two Memory Banks: Depth of 16 entries, 8 bits wide
    reg [7:0] mem_a [0:15];
    reg [7:0] mem_b [0:15];

    // Bank Switch Flag: 0 = Write to B / Read from A, 1 = Write to A / Read from B
    reg bank_sel;

    // Output assign: High only when BOTH writer and reader reach address 15 (4'd15) simultaneously
    assign frame_done = (wr_en && (wr_addr == 4'd15)) && (rd_en && (rd_addr == 4'd15));

    // Toggle active memory bank on frame_done pulse
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bank_sel <= 1'b0;
        end else if (frame_done) begin
            bank_sel <= ~bank_sel;
        end
    end

    // Write Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // mem_a and mem_b are left unreset for Block RAM inferencing
        end else if (wr_en) begin
            if (bank_sel == 1'b0) begin
                mem_b[wr_addr] <= wr_data;
            end else begin
                mem_a[wr_addr] <= wr_data;
            end
        end
    end

    // Read Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data <= 8'h00;
        end else if (rd_en) begin
            if (bank_sel == 1'b0) begin
                rd_data <= mem_a[rd_addr];
            end else begin
                rd_data <= mem_b[rd_addr];
            end
        end
    end

endmodule
