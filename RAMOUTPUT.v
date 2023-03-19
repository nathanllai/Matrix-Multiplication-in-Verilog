module RAMOUTPUT(in,write_enable, clk);

    input signed [18:0] in;
    input clk;
    input write_enable;

    reg signed [18:0] mem [0:63];

    integer i = 0;

    always @(posedge clk) begin
        if(write_enable) begin
            $display("wrote %d to RAMOUTPUT at index %d", in, i);
            mem[i] = in;
            i = i + 1;
        end
    end
endmodule