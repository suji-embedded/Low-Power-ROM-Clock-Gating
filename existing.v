`timescale 1ns/1ps

// ============================================================
// DESIGN MODULES
// ============================================================

// Module 1 : Gray Encoder (6-bit binary -> 6-bit Gray code)
module gray_encoder #(parameter WIDTH = 6)(
    input  [WIDTH-1:0] bin_in,
    output [WIDTH-1:0] gray_out
);
    assign gray_out[WIDTH-1] = bin_in[WIDTH-1];
    genvar i;
    generate
        for (i = 0; i < WIDTH-1; i = i + 1) begin : g
            assign gray_out[i] = bin_in[i+1] ^ bin_in[i];
        end
    endgenerate
endmodule

// ============================================================
// Module 2 : Clock Gate (FPGA Hardware-Optimized Version)
// Uses Xilinx BUFGCE primitive to prevent LUTs on the clock tree
// ============================================================
module clock_gate (
    input  clk,
    input  en,
    input  te,
    output clk_gated
);
    // Combine standard enable and test-enable
    wire enable_comb = en | te;

    // Instantiate the Xilinx Artix-7 Clock Buffer with Enable
    // This guarantees the clock stays on the dedicated clock tree
    BUFGCE u_bufgce (
        .O(clk_gated),   // Clock output
        .CE(enable_comb),// Clock enable input
        .I(clk)          // Clock input
    );

endmodule
// Module 3 : Top-level Low-Power ROM (64 x 8)
module low_power_rom (
    input        clk,
    input        rst,        // active-high async reset
    input        en,
    input  [5:0] addr,
    output [7:0] data
);
    wire [5:0] gray_addr;
    wire       clk_gated;
    reg  [7:0] data_out;
    
    // 7-bit register prevents collision with 6-bit addresses on first read
    reg  [6:0] prev_gray; 

    gray_encoder #(.WIDTH(6)) u_gray_enc (
        .bin_in  (addr),
        .gray_out(gray_addr)
    );

    clock_gate u_icg (
        .clk      (clk),
        .en       (en),
        .te       (1'b0),
        .clk_gated(clk_gated)
    );

    always @(posedge clk_gated or posedge rst) begin
        if (rst) begin
            data_out  <= 8'h00;
            // 7th bit forces a guaranteed mismatch on the first access
            prev_gray <= 7'b1111111; 
        end else begin
            // Pad gray_addr with a 0 to match the 7-bit prev_gray
            if ({1'b0, gray_addr} != prev_gray) begin
                prev_gray <= {1'b0, gray_addr};
                
                case (gray_addr)
                    // ---- addr 0-7 ----
                    6'b000000: data_out <= 8'hA5;
                    6'b000001: data_out <= 8'h3C;
                    6'b000011: data_out <= 8'hF0;
                    6'b000010: data_out <= 8'h69;
                    6'b000110: data_out <= 8'hB4;
                    6'b000111: data_out <= 8'h1E;
                    6'b000101: data_out <= 8'hD2;
                    6'b000100: data_out <= 8'h87;
                    // ---- addr 8-15 ----
                    6'b001100: data_out <= 8'h4A;
                    6'b001101: data_out <= 8'hC3;
                    6'b001111: data_out <= 8'h7B;
                    6'b001110: data_out <= 8'h2F;
                    6'b001010: data_out <= 8'hE6;
                    6'b001011: data_out <= 8'h58;
                    6'b001001: data_out <= 8'h91;
                    6'b001000: data_out <= 8'hAD;
                    // ---- addr 16-23 ----
                    6'b011000: data_out <= 8'h34;
                    6'b011001: data_out <= 8'hFE;
                    6'b011011: data_out <= 8'h0B;
                    6'b011010: data_out <= 8'h76;
                    6'b011110: data_out <= 8'hC9;
                    6'b011111: data_out <= 8'h52;
                    6'b011101: data_out <= 8'h1D;
                    6'b011100: data_out <= 8'hEA;
                    // ---- addr 24-31 ----
                    6'b010100: data_out <= 8'h83;
                    6'b010101: data_out <= 8'h4F;
                    6'b010111: data_out <= 8'hB0;
                    6'b010110: data_out <= 8'h27;
                    6'b010010: data_out <= 8'h6E;
                    6'b010011: data_out <= 8'hD5;
                    6'b010001: data_out <= 8'h39;
                    6'b010000: data_out <= 8'hC1;
                    // ---- addr 32-39 ----
                    6'b110000: data_out <= 8'hAB;
                    6'b110001: data_out <= 8'h5C;
                    6'b110011: data_out <= 8'hF7;
                    6'b110010: data_out <= 8'h08;
                    6'b110110: data_out <= 8'h64;
                    6'b110111: data_out <= 8'h9E;
                    6'b110101: data_out <= 8'h31;
                    6'b110100: data_out <= 8'hDA;
                    // ---- addr 40-47 ----
                    6'b111100: data_out <= 8'h47;
                    6'b111101: data_out <= 8'hBC;
                    6'b111111: data_out <= 8'h72;   
                    6'b111110: data_out <= 8'h2A;
                    6'b111010: data_out <= 8'hE1;
                    6'b111011: data_out <= 8'h55;
                    6'b111001: data_out <= 8'h98;
                    6'b111000: data_out <= 8'hCD;
                    // ---- addr 48-55 ----
                    6'b101000: data_out <= 8'h16;
                    6'b101001: data_out <= 8'hF3;
                    6'b101011: data_out <= 8'h8A;
                    6'b101010: data_out <= 8'h45;
                    6'b101110: data_out <= 8'hBE;
                    6'b101111: data_out <= 8'h29;
                    6'b101101: data_out <= 8'h71;
                    6'b101100: data_out <= 8'hEC;
                    // ---- addr 56-63 ----
                    6'b100100: data_out <= 8'h0D;
                    6'b100101: data_out <= 8'h6A;
                    6'b100111: data_out <= 8'hC5;
                    6'b100110: data_out <= 8'h38;
                    6'b100010: data_out <= 8'hF9;
                    6'b100011: data_out <= 8'h42;
                    6'b100001: data_out <= 8'h1B;
                    6'b100000: data_out <= 8'hD7;
                    
                    default:   data_out <= 8'h00;
                endcase
            end
        end
    end

    assign data = data_out;
endmodule
