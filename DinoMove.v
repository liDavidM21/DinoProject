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
	wire en_xy, en_delay, finish_draw, finish_erase, finish_death, right, down, is_move, finish_tree_draw, en_erase, en_xy_tree, draw_tree, finish_delay, is_over, set_over;
	wire finish_bird, draw_bird, en_bird, draw_death;

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
				 .set_over(set_over),
				 .finish_bird(finish_bird),
				 .draw_bird(draw_bird),
				 .en_bird(en_bird),
				 .draw_death(draw_death),
				 .finish_death(finish_death)
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
			   .set_over(set_over),
			   .finish_bird(finish_bird),
			   .draw_bird(draw_bird),
			   .en_bird(en_bird),
			   .draw_death(draw_death),
			   .finish_death(finish_death)
		       );
endmodule

module datapath3(colour, 
				resetn, 
				clock, 
				draw, 
				draw_ground, 
				draw_tree,
				draw_bird,
				draw_death,
				en_xy, 
				en_xy_tree,
				en_erase,
				en_delay,
				en_bird,
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
				finish_bird,
				finish_death,
				is_move, 
				q,
				finish_delay,
				is_over);
				
    input resetn, clock;
	input en_xy, en_delay, en_erase, draw, right, down, is_move, draw_ground, en_xy_tree, draw_tree, set_over, draw_bird, en_bird, draw_death;
	input [2:0] colour;
	
	output reg finish_erase;
	output reg finish_ground;
	output reg finish_draw;
	output reg finish_tree_draw;
	output reg finish_bird;
	output reg finish_death;
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
	reg [7:0] bird_x;
	reg [6:0] bird_y;
	reg [4:0] bird_q; 
	reg [4:0] death_q;
	reg direction;
	

	output reg [5:0] q;
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
				if(x_original + 3'd6 > tree_x && x_original + 3'd6 < tree_x + 3'd3)
					begin
						if(y_original + 3'd7 > tree_y)
							is_over = 1'd1;
					end	
				if(x_original > tree_x && x_original < tree_x + 3'd3)
				    begin
					    if(y_original + 3'd7 > tree_y)
						    is_over = 1'd1;
					end
				if(x_original < bird_x && x_original + 3'd6 > bird_x)
					begin
						if(y_original >= bird_y - 3'd7 && y_original <= bird_y + 3'd3)
							is_over = 1'd1;
					end
				if(x_original > bird_x && x_original + 3'd6 < bird_x + 3'd7)
					begin
						if(y_original >= bird_y - 3'd7 && y_original <= bird_y + 3'd3)
							is_over = 1'd1;
					end
				if(x_original > bird_x && x_original + 3'd6 > bird_x + 3'd7)
					begin
						if(y_original >= bird_y - 3'd7 && y_original <= bird_y + 3'd3)
							is_over = 1'd1;
					end
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
	begin
		if (!resetn || set_over) begin
			colour_out <= 3'b000;
			end
		else 
			begin
			    if(draw_ground)
				    colour_out <= 3'b010;
			    if (draw)
				    colour_out <= 3'b001;
				if (draw_tree)
					colour_out <= 3'b111;
				if(draw_bird)
					colour_out <= 3'b101;
			    if (draw_death)
				    colour_out <= 3'b001;
				if (en_erase)
					colour_out <= 3'b000;
			end
	end
	
	always @(posedge clock)
	begin: delay_counter
		if (!resetn || set_over)
			delay <= 20'd633333;
		if (delay == 0)
			delay <= 20'd633333;
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
	
	//bird x counter
	always @(posedge clock)
	begin
		if(!resetn || set_over)
			bird_x <= 8'd30;
		else if(en_bird)
			bird_x <= bird_x - 1'd1;
	end
	
	//bird y counter
	always @(posedge clock)
	begin
		if(!resetn || set_over) begin
			bird_y <= 7'd60;
			end
		else if(en_bird)
			begin
				if(direction)
					bird_y <= bird_y - 1'd1;
				else
					bird_y <= bird_y + 1'd1;
			end
		else if(bird_x == 8'd200)
			begin
				if (LFSR_out[1:0] == 2'b00)
					bird_y <= 7'd80;
				else if (LFSR_out[1:0] == 2'b01)
					bird_y <= 7'd105;
				else if (LFSR_out[1:0] == 2'b10)
					bird_y <= 7'd60;
				else if (LFSR_out[1:0] == 2'b11)
					bird_y <= 7'd90;
			end
	end
	
	always @(*)
	begin
		if(!resetn)
			direction <= 1'b1;
		if(bird_y == 7'd50)
			direction <= 1'b0;
		else if(bird_y == 7'd110)
			direction <= 1'b1;
	end
	
	always @(posedge clock)
	begin
		if(!resetn)
			begin
				bird_q <= 5'd0;
				finish_bird <= 1'd0;
			end
		if(finish_delay)
			bird_q <= 5'd0;
		if(bird_q == 5'd17)
			begin
				bird_q <= 5'd0;
				finish_bird <= 1'd1;
			end	
		else if(draw_bird)
			begin
				bird_q <= bird_q + 1'd1;
				finish_bird <= 1'd0;
			end	
	end
			
	
	always @(posedge clock)
	begin
		if(!resetn)
			begin
				death_q <= 5'd0;
				finish_death <= 1'd0;
			end
		if(finish_delay)
			death_q <= 5'd0;
		if(death_q == 5'd10)
			begin
				death_q <= 5'd0;
				finish_death <= 1'd1;
			end	
		else if(draw_death)	
			begin
				death_q <= death_q + 1'd1;
				finish_death <= 1'd0;
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
		else if(tree_x + 2'd3 == 8'd200)
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
	
	
	//draw tree counter
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
		if (q == 6'd21) begin
			q <= 0;
			finish_draw <= 1'b1;
			end
		else if (draw)
			begin
				q <= q + 1;
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
		else if(draw_tree)
			begin
				x = tree_x + tree_x_counter;
				y = tree_y + tree_y_counter;
			end
		else if(draw)
			begin
				if(q == 6'd0) begin
					x = x_original + 2'd3;
					y = y_original;
				end	
				else if (q == 6'd1) begin
					x = x_original + 3'd4;
					y = y_original;
				end
				else if(q == 6'd2) begin
					x = x_original + 3'd5;
					y = y_original;
				end
				else if(q == 6'd3) begin
					x = x_original + 2'd3;
					y = y_original + 1'b1;
				end	
				else if(q == 6'd4) begin
					x = x_original + 3'd5;
					y = y_original + 1'd1;
				end
				else if(q == 6'd5) begin
					x = x_original + 2'd3;
					y = y_original + 2'd2;
				end	
				else if(q == 6'd6) begin
					x = x_original + 3'd4;
					y = y_original + 2'd2;
				end	
				else if(q == 6'd7) begin
					x = x_original + 3'd5;
					y = y_original + 2'd2;
				end
				else if(q == 6'd8) begin
					x = x_original;
					y = y_original + 3'd3;
				end
				else if(q == 6'd9) begin
					x = x_original + 1'd1;
					y = y_original + 3'd3;
				end
				else if(q == 6'd10) begin
					x = x_original + 2'd2;
					y = y_original + 3'd3;
				end
				else if(q == 6'd11) begin
					x = x_original + 2'd3;
					y = y_original + 3'd3;
				end
				else if(q == 6'd12) begin
					x = x_original;
					y = y_original + 3'd4;
				end
				else if(q == 6'd13) begin
					x = x_original + 1'd1;
					y = y_original + 3'd4;
				end
				else if(q == 6'd14) begin
					x = x_original + 2'd2;
					y = y_original + 3'd4;
				end
				else if(q == 6'd15) begin
					x = x_original + 2'd3;
					y = y_original + 3'd4;
				end	
				else if(q == 6'd16) begin
					x = x_original;
					y = y_original + 3'd5;
				end
				else if(q == 6'd17) begin
					x = x_original + 1'd1;
					y = y_original + 3'd5;
				end
				else if(q == 6'd18) begin
					x = x_original + 2'd2;
					y = y_original + 3'd5;
				end
				else if(q == 6'd19) begin
					x = x_original + 3'd3;
					y = y_original + 3'd5;
				end
				else if(q == 6'd20) begin
					x = x_original;
					y = y_original + 3'd6;
				end	
				else if(q == 6'd21) begin
					x = x_original + 3'd3;
					y = y_original + 3'd6;
				end
			end
		else if(draw_bird) begin
			if(bird_q == 5'd0) begin
				x = bird_x;
				y = bird_y + 2'd2;
				end
			else if(bird_q == 5'd1) begin
				x = bird_x + 1'd1;
				y = bird_y;
				end
			else if(bird_q == 5'd2) begin
				x = bird_x + 1'd1;
				y = bird_y + 2'd1;
				end
			else if(bird_q == 5'd3) begin
				x = bird_x + 1'd1;
				y = bird_y + 2'd2;
				end
			else if(bird_q == 5'd4) begin
				x = bird_x + 2'd2;
				y = bird_y;
				end
			else if(bird_q == 5'd5) begin
				x = bird_x + 2'd2;
				y = bird_y + 2'd2;
				end	
			else if(bird_q == 5'd6) begin
				x = bird_x + 2'd3;
				y = bird_y;
				end	
			else if(bird_q == 5'd7) begin
				x = bird_x + 2'd3;
				y = bird_y + 1'd1;
				end	
			else if(bird_q == 5'd8) begin
				x = bird_x + 2'd3;
				y = bird_y + 2'd2;
				end	
			else if(bird_q == 5'd9) begin
				x = bird_x + 3'd4;
				y = bird_y - 1'd1;
				end
			else if(bird_q == 5'd10) begin
				x = bird_x + 3'd4;
				y = bird_y;
				end
			else if(bird_q == 5'd11) begin
				x = bird_x + 3'd4;
				y = bird_y + 1'd1;
				end	
			else if(bird_q == 5'd12) begin
				x = bird_x + 3'd4;
				y = bird_y + 2'd2;
				end	
			else if(bird_q == 5'd13) begin
				x = bird_x + 3'd5;
				y = bird_y;
				end
			else if(bird_q == 5'd14) begin
				x = bird_x + 3'd5;
				y = bird_y + 1'd1;
				end
			else if(bird_q == 5'd15) begin
				x = bird_x + 3'd5;
				y = bird_y + 2'd2;
				end
			else if(bird_q == 5'd16) begin
				x = bird_x + 3'd6;
				y = bird_y;
				end
			else if(bird_q == 5'd17) begin
				x = bird_x + 3'd6;
				y = bird_y + 2'd2;
				end	
			end
		else if(draw_death) begin
			if(death_q == 5'd0) begin
				x = x_original;
				y = y_original + 2'd2;
			end
			else if(death_q == 5'd1) begin
				x = x_original + 1'd1;
				y = y_original + 2'd2;
			end
			else if(death_q == 5'd2) begin
				x = x_original + 2'd2;
				y = y_original + 2'd2;
			end
			else if(death_q == 5'd3) begin
				x = x_original + 2'd2;
				y = y_original + 1'd1;
			end
			else if(death_q == 5'd4) begin
				x = x_original + 2'd2;
				y = y_original;
			end
			else if(death_q == 5'd5) begin
				x = x_original + 2'd2;
				y = y_original + 2'd3;
			end
			else if(death_q == 5'd6) begin
				x = x_original + 2'd2;
				y = y_original + 3'd4;
			end
			else if(death_q == 5'd7) begin
				x = x_original + 2'd2;
				y = y_original + 3'd5;
			end
			else if(death_q == 5'd8) begin
				x = x_original + 2'd2;
				y = y_original + 3'd6;
			end
			else if(death_q == 6'd9) begin
				x = x_original + 2'd3;
				y = y_original + 2'd2;
			end
			else if(death_q == 6'd10) begin
				x = x_original + 3'd4;
				y = y_original + 2'd2;
			end
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
			finish_bird,
			finish_death,
			x, 
			y, 
			en_xy,
			en_xy_tree,
			en_delay, 
			en_bird,
			right, 
			down,
			draw_ground, 
			draw_tree,
			draw_bird,
			draw, 
			draw_death,
			plot, 
			is_move, 
			current_state,
			finish_delay,
			en_erase,
			is_over,
			set_over);
			
	input resetn, clock, go, finish_ground, finish_draw, finish_erase, finish_tree_draw, finish_death, jump, finish_bird, finish_delay, is_over;
	input [7:0] x;
	input [6:0] y;
	output reg en_xy, en_xy_tree, en_erase, en_delay, draw_ground, draw, draw_death, plot, down, right, is_move, draw_tree, set_over, draw_bird, en_bird;

	output reg [3:0] current_state;
	reg [3:0] next_state;
	
	localparam  BEGIN = 4'd0,
	            GROUND = 4'd1,
				DRAW = 4'd2,
				DRAW_TREE = 4'd3,
				DRAW_BIRD = 4'd4,
				DRAW_DEATH = 4'd5,
				DELAY = 4'd6,
				ERASE= 4'd7,
				NEW_XY = 4'd8,
				NEW_XY_TREE = 4'd9,
				NEW_XY_BIRD = 4'd10;
					

	
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
			GROUND : begin
						if(finish_ground) //next_state = finish_ground ? DRAW : GROUND;
							begin
								if(is_over)
									next_state = DRAW_DEATH;
								else
									next_state = DRAW;
							end
					end
			DRAW: next_state = finish_draw ? DRAW_BIRD : DRAW;
			DRAW_BIRD : next_state = finish_bird ? DRAW_TREE: DRAW_BIRD;
			DRAW_TREE : next_state = finish_tree_draw ? DELAY : DRAW_TREE;
			DRAW_DEATH : next_state = finish_death ? DRAW_BIRD : DRAW_DEATH;
			DELAY : begin//next_state = finish_delay ? ERASE : DELAY;
						if(finish_delay)
							begin
								if(is_over)
									next_state = BEGIN;
								else
									next_state = ERASE;
							end	
					end
			ERASE: begin
						if(finish_erase)
							begin
								if(is_move)
									next_state = NEW_XY;
								else
									next_state = NEW_XY_TREE;
							end
					end
			NEW_XY: next_state = NEW_XY_TREE;
			NEW_XY_TREE : next_state = NEW_XY_BIRD;
			NEW_XY_BIRD : next_state = GROUND;
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
		draw_bird = 1'b0;
		en_xy_tree = 1'b0;
		en_erase = 1'b0;
		set_over = 1'b0;
		en_bird = 1'b0;
		draw_death = 1'b0;
		
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
		DRAW_BIRD: begin
		    draw_bird = 1'b1;
			plot = 1'b1;
		    end
		DRAW_TREE: begin
			draw_tree = 1'b1;
			plot = 1'b1;
			end
		DELAY: begin
			en_delay = 1'b1;
			end	
		DRAW_DEATH: begin
			draw_death = 1'b1;
			plot = 1'b1;
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
		NEW_XY_BIRD:
			begin
				en_bird = 1'b1;
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