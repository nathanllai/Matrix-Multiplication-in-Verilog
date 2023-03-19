`timescale 1ps/1ps 
module task1_tb;

	reg signed [7:0] a;
	reg signed [7:0] b;
	reg clk;
	reg clr;
	
	wire [18:0] out;

    
	mac m1 (
		.inA (a),
		.inB (b),
		.clr (clr),
		.clk (clk),
		.out (out)
	
	);
    
	 initial begin
		a = 8'd9;
		b = 8'd5;
		clr =	1'b1;
		clk = 1'b0;
		#10
		clk = 1'b1;
		#10
		clr = 1'b0;
		clk = 1'b0;
		
		#10
		clk = 1'b1;
		a = 8'd4;
		b = 8'd2;
		#10
		clr = 1'b1;
		clk = 1'b1;
		#10
		clk = 1'b0;
		clr = 1'b0;
		
		#10
		clk = 1'b1;
		a = 8'd2;
		b = 8'd3;
		#10
		clr = 1'b1;
		clk = 1'b1;
		#10
		clk = 1'b0;
		clr = 1'b0;
		

		
	 end
	 
	

	
	

endmodule