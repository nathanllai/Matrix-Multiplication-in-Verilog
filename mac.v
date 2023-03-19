module mac(inA,inB,clr,clk,out);

    input signed [7:0] inA;
    input signed [7:0] inB;
    input clr;
    input clk;

    output reg signed [18:0] out;

    wire signed [18:0] out_m;
    wire signed [18:0] out_a;

    wire signed [18:0] out_c;

    always @(posedge clk) begin
        out <= out_c;
    end

    assign out_m = inA * inB;
    assign out_a = out + out_m;

    //mux m1(.d1(out_m),.d0(out_a),.s(clr),.out(out_c));
    assign out_c = clr ? out_m : out_a;
    
endmodule

/*
module mac(inA,inB,clr,clk,out);

    input signed [7:0] inA;
    input signed [7:0] inB;
    input clr;
    input clk;

    output reg signed [18:0] out;

    wire signed [18:0] out_m;
    wire signed [18:0] out_a;

    wire signed [18:0] out_c;

    always @(posedge clk) begin
        out <= out_c;
    end

    assign out_m = inA * inB;
    assign out_a = out + out_m;

    //mux m1(.d1(out_m),.d0(out_a),.s(clr),.out(out_c));
    assign out_c = clr ? out_m : out_a;
    
endmodule
*/