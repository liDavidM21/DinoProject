module dinoProject
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	wire ld_x, ld_y, draw, draw_ground;
	wire en_xy, en_delay, finish_draw, finish_erase, right, down, is_move, finish_tree_draw, en_erase, en_xy_tree, draw_tree, finish_delay, is_over, set_over;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
		
		
	datapath3 d3(
	             .colour(SW[9:7]),
		         .resetn(resetn),
		         .clock(CLOCK_50),
				 .draw(draw),
                 .draw_ground(draw_ground),				 
		         .en_xy(en_xy),
		         .en_delay(en_delay),
				 .right(right),
				 .down(down),
		         
		         .x(x),
		         .y(y),
		         .colour_out(colour),
				 .finish_ground(finish_ground),
		         .finish_draw(finish_draw),
		         .finish_erase(finish_erase),
				 .is_move(is_move),
				 .finish_tree_draw(finish_tree_draw),
				 .en_xy_tree(en_xy_tree),
				 .draw_tree(draw_tree),
				 .finish_delay(finish_delay),
				 .en_erase(en_erase),
				 .is_over(is_over),
				 .set_over(set_over)
	             );
	 FSM3 fsm3(
		       .clock(CLOCK_50),
		       .resetn(resetn),
		       .go(~KEY[1]),
			   .jump(KEY[2]),
			   .finish_ground(finish_ground),
		       .finish_draw(finish_draw),
		       .finish_erase(finish_erase),
			   .x(x),
			   .y(y),
		
		       .en_xy(en_xy),
		       .en_delay(en_delay),
			   .right(right),
			   .down(down),
			   .draw_ground(draw_ground),
		       .draw(draw),
		       .plot(writeEn),
			   .is_move(is_move),
			   .finish_tree_draw(finish_tree_draw),
			   .en_xy_tree(en_xy_tree),
			   .draw_tree(draw_tree),
			   .finish_delay(finish_delay),
			   .en_erase(en_erase),
			   .is_over(is_over),
			   .set_over(set_over)
		       );
endmodule

module datapath3(colour, 
				resetn, 
				clock, 
				draw, 
				draw_ground, 
				draw_tree,
				en_xy, 
				en_xy_tree,
				en_erase,
				en_delay,
				set_over,
				right, 
				down, 
				x, 
				y, 
				colour_out, 
				finish_ground, 
				finish_draw, 
				finish_erase, 
				finish_tree_draw,
				is_move, 
				q,
				finish_delay,
				is_over);
				
    input resetn, clock;
	input en_xy, en_delay, en_erase, draw, right, down, is_move, draw_ground, en_xy_tree, draw_tree, set_over;
	input [2:0] colour;
	
	output reg finish_erase;
	output reg finish_ground;
	output reg finish_draw;
	output reg finish_tree_draw;
	output finish_delay;
	output reg is_over;
	reg [7:0] ground_x;
	reg [6:0] ground_y;
	output reg [7:0] x;
	output reg [6:0] y;
	output reg [2:0] colour_out;
	reg [7:0] tree_x;
	reg [6:0] tree_y;
	reg [7:0] x_original;
	reg [6:0] y_original;
	reg [7:0] erase_counter_x;
	reg [6:0] erase_counter_y;

	output reg [3:0] q;
	reg [1:0] tree_x_counter;
	reg [6:0] tree_y_counter;
	reg [3:0]  frame;
	reg [19:0] delay;
	reg [19:0] tree_delay;
	reg [3:0] tree_frame;
	wire en_frame;
	wire en_tree_frame;
	wire [7:0] LFSR_out;
	
	LFSR l0(.clk(clock), .resetn(resetn), .out(LFSR_out));
	
	always @(*)
	begin
		if(!resetn)
			is_over = 1'b0;
		if(set_over)
			is_over = 1'b0;
		else
			begin
				if(x_original + 3'd6 >= tree_x && x_original + 3'd6 <= tree_x + 3'd3 && y_original + 3'd7 >= tree_y)
					is_over = 1'd1;
				else if(x_original + 3'd6 >= tree_x + 3'd3 && x_original <= tree_x && y_original + 3'd7 >= tree_y)
				    is_over = 1'd1;
				else if(x_original >= tree_x && x_original <= tree_x + 3'd3 && y_original + 3'd7 >= tree_y)
				    is_over = 1'd1;
			end
	end
	
	always @(posedge clock)
	begin: ground
	    if(!resetn || set_over)
		    begin
		        ground_x <= 8'd0;
				ground_y <= 7'd115;
		    end
		if(finish_delay)
			begin
				ground_y <= 7'd115;
				ground_x <= 8'd0;
			end
		if(ground_y == 7'd120)
			begin
				ground_y <= 7'd115;
				finish_ground <= 1'd1;
			end	
		else
		    begin
			    if(draw_ground)
				    begin
			            
				        if (ground_x >= 8'd159)
				            begin
					            ground_x <= 0;
						        ground_y <= ground_y + 1;
					        end
						else
							begin
								ground_x <= ground_x + 1;
								finish_ground <= 1'd0;
							end
			        end
			end
	end
	
	always @(posedge clock)
	begin
		if(!resetn || set_over)
			begin
				erase_counter_x <= 8'd0;
				erase_counter_y <= 7'd0;
			end
		if(finish_delay)
			begin
				erase_counter_y <= 7'd0;
				erase_counter_x <= 8'd0;
			end
		if(erase_counter_y == 7'd120)
			begin
				erase_counter_y <= 7'd0;
				finish_erase <= 1'd1;
			end
		else
			begin
				if(en_erase)
					begin
						if(erase_counter_x >= 8'd159)
							begin
								erase_counter_x <= 0;
								erase_counter_y <= erase_counter_y + 1'd1;
							end
						else
							begin
								erase_counter_x <= erase_counter_x + 1;
								finish_erase <= 1'd0;
							end
					end
			end
	end
	
	always @(posedge clock)
	begin: load_register
		if (!resetn || set_over) begin
			colour_out <= 3'b000;
			end
		else 
			begin
			    if(draw_ground)
				    colour_out <= 3'b010;
			    else if (draw)
				    colour_out <= 3'b001;
				else if (draw_tree)
					colour_out <= 3'b111;
				else if (en_erase)
					colour_out <= 3'b000;
			end
	end
	
	always @(posedge clock)
	begin: delay_counter
		if (!resetn || set_over)
			delay <= 20'd833333;
		if (delay == 0)
			delay <= 20'd833333;
	    else if (en_delay)
		begin
			    delay <= delay - 1'b1;
		end
	end
	
	assign en_frame = (delay == 20'd0)? 1: 0;
	
	always @(posedge clock)
	begin: frame_counter
	    if (!resetn || set_over)
		    frame <= 4'b0000;
		if (frame == 4'd1)
			frame <= 4'd0;
		else if (en_frame == 1'b1)
		begin
			    frame <= frame + 1'b1;
		end
		
	end
	
	assign finish_delay = (frame == 4'd1) ? 1: 0;
	
	// always @(posedge clock)
	// begin: x_counter
	    // if (!resetn)
		    // x_original <= 8'd40;
		// else if (en_xy)
		// begin
		    // if (right == 1'b1)
			    // x_original <= x_original + 1'b1;
			// else
			    // x_original <= x_original - 1'b1;
		// end
	// end
	
	always @(posedge clock)
	begin: x_counter
		if (!resetn || set_over)
			x_original <= 8'd10;
	end
	
	always @(posedge clock)
	begin: y_counter
	    if (!resetn || set_over)
		    y_original <= 7'd110;
		else if (en_xy)
		begin
			if (is_move)
				begin
					if (down == 1'b1)
						y_original <= y_original + 1'b1;
					else
						y_original <= y_original - 1'b1;
				end
		end
	end
	
	
	//tree x counter
	always @(posedge clock)
	begin
		if(!resetn || set_over)
			tree_x <= 8'd130;
		else if(en_xy_tree)
		begin
			tree_x <= tree_x - 1'd1;
		end
	end
	//tree y counter
	always @(posedge clock)
	begin
		if(!resetn || set_over)
			tree_y <= 7'd100;
		else if(tree_x + 2'd3 == 8'd0)
		begin
			if (LFSR_out[1:0] == 2'b00)
			    tree_y <= 7'd112;
			else if (LFSR_out[1:0] == 2'b01)
			    tree_y <= 7'd105;
			else if (LFSR_out[1:0] == 2'b10)
			    tree_y <= 7'd95;
			else if (LFSR_out[1:0] == 2'b11)
			    tree_y <= 7'd90;
		end
	end
	
	always @(posedge clock)
	begin
		if(!resetn || set_over)
			begin
				tree_x_counter <= 2'd0;
				tree_y_counter <= 7'd0;
			end
		if(finish_delay) begin
			tree_y_counter <= 7'd0;
			tree_x_counter <= 2'd0;
		end
		else if(draw_tree)
				begin
					if(tree_x_counter == 2'd3)
						begin
							tree_x_counter <= 0;
							if(tree_y_counter + tree_y == 7'd114)
								begin
									tree_y_counter <= 7'd0;
									finish_tree_draw <= 1'd1;
								end
							else
								tree_y_counter <= tree_y_counter + 1'd1;
						end
					else
						begin
							tree_x_counter <= tree_x_counter + 1;
							finish_tree_draw <= 1'd0;
						end	
				end
	end
	
	always @(posedge clock)
	begin: counter
		if (!resetn || set_over) begin
			q <= 4'b0000;
			finish_draw <= 1'd0;
			end
		if(finish_delay) begin
			q <= 4'b0000;
			end
		if (q == 4'b1111) begin
			q <= 0;
			finish_draw <= 1'b1;
			end
		else if (draw)
			begin
				q <= q + 1'b1;
				finish_draw <= 1'b0;
			end
	end

	
	always @(*)
	begin
		if (!resetn || set_over) begin
			x = ground_x;
			y = ground_y;
		end
		else if (draw_ground)
		    begin
			    x = ground_x;
				y = ground_y;
			end
		else if(draw)
			begin
				x = x_original + q[1:0];
				y = y_original + q[3:2];
			end
		else if(draw_tree)
			begin
				x = tree_x + tree_x_counter;
				y = tree_y + tree_y_counter;
			end
		else if(en_erase)
			begin
				x = erase_counter_x;
				y = erase_counter_y;
			end	
	end
endmodule

module FSM3(clock, 
			resetn, 
			go, 
			jump, 
			finish_ground, 
			finish_draw, 
			finish_erase, 
			finish_tree_draw,
			x, 
			y, 
			en_xy,
			en_xy_tree,
			en_delay, 
			right, 
			down,
			draw_ground, 
			draw_tree,
			draw, 
			plot, 
			is_move, 
			current_state,
			finish_delay,
			en_erase,
			is_over,
			set_over);
			
	input resetn, clock, go, finish_ground, finish_draw, finish_erase, finish_tree_draw, jump, finish_delay, is_over;
	input [7:0] x;
	input [6:0] y;
	output reg en_xy, en_xy_tree, en_erase, en_delay, draw_ground, draw, plot, down, right, is_move, draw_tree, set_over;

	output reg [3:0] current_state;
	reg [3:0] next_state;
	
	localparam  BEGIN = 4'd0,
	            GROUND = 4'd1,
				DRAW = 4'd2,
				DRAW_TREE = 4'd3,
				DELAY = 4'd4,
				ERASE= 4'd5,
				NEW_XY = 4'd6,
				NEW_XY_TREE = 4'd7;
					

	
	always @(posedge clock)
	begin
		if(!resetn || current_state == BEGIN)
			is_move <= 0;
		if(!jump)
			is_move <= 1;
		else if(down == 1 && y == 7'd115 && current_state == DRAW)
			is_move <= 0;
	end	
	
	always @(*)
	begin: state_table
		case (current_state)
			BEGIN: next_state = go ? GROUND : BEGIN;
			GROUND : next_state = finish_ground ? DRAW : GROUND;
			DRAW: next_state = finish_draw ? DRAW_TREE : DRAW;
			DRAW_TREE : next_state = finish_tree_draw ? DELAY : DRAW_TREE;
			DELAY : next_state = finish_delay ? ERASE : DELAY;
			ERASE: begin
						if(finish_erase)
							begin
								if(is_over)
									next_state = BEGIN;
								else if(is_move)
									next_state = NEW_XY;
								else
									next_state = NEW_XY_TREE;
							end
					end
			NEW_XY: next_state = NEW_XY_TREE;
			NEW_XY_TREE : next_state = GROUND;
			default: next_state = BEGIN;
		endcase
	end
	
	always @(*)
	begin: signals
		en_xy = 1'b0; 
		en_delay = 1'b0;
		draw = 1'b0;
		plot = 1'b0;
		draw_ground = 1'b0;
		draw_tree = 1'b0;
		en_xy_tree = 1'b0;
		en_erase = 1'b0;
		set_over = 1'b0;
		
		case (current_state)
		BEGIN: begin
			set_over = 1'b1;
		end
		GROUND: begin
		    draw_ground = 1'b1;
			plot = 1'b1;
			end
		DRAW: begin
			draw = 1'b1;
			plot = 1'b1;
			end
		DRAW_TREE: begin
			draw_tree = 1'b1;
			plot = 1'b1;
			end
		DELAY: begin
			en_delay = 1'b1;
			end	
		ERASE: begin
			en_erase = 1'b1;
			plot = 1'b1;
			end
		NEW_XY :
			begin
				en_xy = 1'b1;
			end
		NEW_XY_TREE:
			begin
				en_xy_tree = 1'b1;
			end
		endcase
	end
	
	always @(posedge clock)
	begin
		if(!resetn)begin
			right <= 1'b1;
			down <= 1'b0;
		end	
		else
			begin
				if (y == 7'd115 && current_state == DRAW)
					begin
						down <= 0;
					end
				if (y == 7'd60 && current_state == DRAW)
					begin
						down <= 1;
					end
			end	
	end
	
always@(posedge clock)
    begin: state_FFs
        if(!resetn)
            current_state <= BEGIN;
        else
            current_state <= next_state;
    end // state_FFS
endmodule

module LFSR(clk, resetn, out);
	input clk;
	input resetn;
	output [4:0] out;
	
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
	
	assign out = random_reg[4:0];
	
endmodule