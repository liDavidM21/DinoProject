module fpga_top(KEY, HEX0, HEX1);
	input [1:0] KEY;
	output [6:0] HEX0, HEX1;
	
	wire [7:0] LFSR_out;
	
	LFSR l0(.clk(KEY[1]), .resetn(KEY[0]), .out(LFSR_out));
	
	hex_decoder h0(.hex_digit(LFSR_out[3:0]), .segments(HEX0));
	hex_decoder h1(.hex_digit(LFSR_out[7:4]), .segments(HEX1));
endmodule

module LFSR(clk, resetn, out);
	input clk;
	input resetn;
	output [7:0] out;
	
	wire xor_out;
	reg [12:0] random_reg;
	reg [3:0] current_reg;
	assign xor_out = random_reg[12] ^ random_reg[3] ^ random_reg[2] ^ random_reg[0];
	
	always @(posedge clk)
	begin
		if(!resetn)
			begin
				random_reg <= 8'd7;
				current_reg <= 3'd0;
			end
		else
			begin
				random_reg <= {random_reg[11:0], xor_out};
			end
	end
	
	assign out = random_reg[7:0];
	
endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule