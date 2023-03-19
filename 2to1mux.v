module mux(d1,d0,s,out);

    input signed [18:0] d1;
    input signed [18:0] d0;
    input s;
    output signed [18:0] out;

    assign out = d1 & s | ~s & d0;

endmodule