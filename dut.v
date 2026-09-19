module ping_pong_buffer (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame_done,
    
    // frame done is the triggering event and the bank_sel is the internal register that does the switching 
    // relationship between them 
    // if (frame_done) 
    //    bank_sel = ~ bank_sel

    
    // Write Interface (Producer)
    input  wire       wr_en,
    input  wire [3:0] wr_addr,
    input  wire [7:0] wr_data,
    
    // Read Interface (Consumer)
    input  wire       rd_en,
    input  wire [3:0] rd_addr,
    output reg  [7:0] rd_data
);

    // Two Memory Banks: Depth of 16 entries, 8 bits wide
    reg [7:0] mem_a [0:15];
    reg [7:0] mem_b [0:15];

    // Bank Switch Flag: 0 = Write to B / Read from A, 1 = Write to A / Read from B
    reg bank_sel;

    // Toggle active memory bank on frame_done
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bank_sel <= 1'b0;
        end else if (frame_done) begin
            bank_sel <= ~bank_sel;
        end
    end

    // Write Logic
    always @(posedge clk) begin
        if (wr_en) begin
            if (bank_sel == 1'b0) begin
                mem_b[wr_addr] <= wr_data;
            end else begin
                mem_a[wr_addr] <= wr_data;
            end
        end
    end

    // Read Logic
    always @(posedge clk) begin
        if (rd_en) begin
            if (bank_sel == 1'b0) begin
                rd_data <= mem_a[rd_addr];
            end else begin
                rd_data <= mem_b[rd_addr];
            end
        end
    end

endmodule
