module mm_macop(start,clk,reset,clk_count,done);
    input start;
    input clk;
    input reset;

    output reg [10:0] clk_count;
    output reg done;

    //Matrix A & B
    reg signed [7:0] memA [0:63];
    reg signed [7:0] memB [0:63];
    
    //Matrix C (result)
    reg signed [18:0] c [0:63];
 
    //Read from RAM (a & b)
    initial begin
        $readmemb("./ram_a_init.txt",memA);
        $readmemb("./ram_b_init.txt",memB);
    end //Column-major order (for a, needs to increment by 8 to read next element in row)

    //I/O for MAC & RAMOUTPUT
    reg signed [7:0] a;
    reg signed [7:0] b;
    wire signed [18:0] out [0:3];
    reg signed [18:0] write_in [0:3];
    reg clr;
    reg wr;

    reg signed [18:0] buffer;
    reg signed [7:0] a2;
    reg signed [7:0] a3;
    reg signed [7:0] a4;

    mac mac1(.inA(a),.inB(b),.clr(clr),.clk(clk),.out(out[0]));
    mac mac2(.inA(a2),.inB(b),.clr(clr),.clk(clk),.out(out[1]));
    mac mac3(.inA(a3),.inB(b),.clr(clr),.clk(clk),.out(out[2]));
    mac mac4(.inA(a4),.inB(b),.clr(clr),.clk(clk),.out(out[3]));

    RAMOUTPUT ramout(.in(buffer), .clk(clk), .write_enable(wr));
    
    //FSM variables
    reg [1:0] state;
    reg [1:0] state_c;
    reg [10:0] clk_count_c;
    reg signed [18:0] buffer_c;
    
    reg done_c;
    reg wr_c;
    reg clr_c;
    reg final_c;
    reg final;
    parameter START_fsm = 2'b00;
    parameter MACOp = 2'b01;
    parameter FINAL = 2'b10;
    parameter DONE = 2'b11;
    integer n = 512;

    integer countA = 0;
    integer countB = 0;
    integer op = 0;
    integer op_col = 0;
    integer op_row = 0;

    integer macbuffer = 0;

    always @(posedge clk) begin
        state <= state_c;
        clk_count <= clk_count_c;
        done <= done_c;
        final <= final_c;
        wr <= wr_c;
        clr <= clr_c;
        buffer <= buffer_c;
    end

    //FSM
    always @(state or clk_count or reset or start or buffer) begin
        case(state)
            START_fsm: begin
                if(reset) begin
                    clk_count_c = 0;
                    done_c = 0;
                    final_c = 0;
                    clr_c = 1;
                    wr_c = 0;
                    macbuffer = 0;
                    state_c = START_fsm;
                end
                if(!reset && start) begin
                    state_c = MACOp;
                end
            end
            MACOp: begin
                if(final) begin 
                    write_in[0] = out[0];
                    write_in[1] = out[1];
                    write_in[2] = out[2];
                    write_in[3] = out[3];
                    state_c = FINAL;
                end else if(reset) begin
                    clk_count = 0;
                    state_c = START_fsm;
                end else begin
                    clk_count_c = clk_count + 1;
                    if(macbuffer <= 4 && macbuffer > 0) begin
                        if(macbuffer == 1) begin
                            write_in[0] = out[0];
                            write_in[1] = out[1];
                            write_in[2] = out[2];
                            write_in[3] = out[3];
                        end
                        $display("Current Outs: %d %d %d %d", write_in[0],write_in[1],write_in[2],write_in[3]);
                        buffer_c = write_in[macbuffer-1];
                        
                        wr_c = 1;
                        macbuffer = macbuffer+1;
                    end else begin
                        macbuffer = 0;
                        wr_c = 0;
                    end

                    
                    state_c = MACOp;
                    $display("MAC1: Next Access: (%d,%d) | Operation: %d * %d | MAC1: Out = %d | Clock Cycle: %d | clr: %d, wr: %d",countA,countB,a,b,out[0],clk_count,clr,wr);
                    //$display("MAC2: Next Access: (%d,%d) | Operation: %d * %d | MAC1: Out = %d | Clock Cycle: %d | clr: %d, wr: %d",countA+4,countB,a2,b,out2,clk_count,clr,wr);
                    //$write(" | MAC2: Next Access: (%d, %d) | Operation: %d * %d\n",countA+4,countB,a2,b);
                    a = memA[countA];
                    // a2 has element 4 indices ahead of a
                    a2 = memA[countA + 1];
                    a3 = memA[countA + 2];
                    a4 = memA[countA + 3];
                    b = memB[countB];
                    //$write("MAC1: Out = %d | Clock Cycle: %d | clr: %d, wr: %d | ",out,clk_count, clr,wr);
                    //$write("MAC2: Out = %d | Clock Cycle: %d | clr: %d, wr: %d\n",out2,clk_count, clr,wr);
                    //$display("Write %d to RAMOUTPUT", out);
                    clr_c = 0;

                    countA = countA + 8; //next row
                    countB = countB + 1; //next column
                    op = op + 1;
                    
                    if(op == 8) begin
                        op_col = op_col + 4;
                        countA = op_col;
                        countB = 8 * op_row;
                        op = 0;
                        
                        macbuffer = 1;
                        clr_c = 1;

                        if(op_col == 8) begin
                            countA = 0; // refresh the matrix A count
                            if(op_row < 8)
                                op_row = op_row + 1; // update the column in Matrix B
                            countB = 8 * op_row;
                            op_col = 0;
                            if(op_row == 8) begin
                                final_c = 1;
                            end
                        end
                    end
                end
            end
            DONE: begin    
                if(reset) begin
                    clk_count_c = 0;
                    done_c = 0;
                    state_c = START_fsm;
                end else begin
                    done_c = 1;
                    state_c = DONE;
                end
            end
            FINAL: begin
                if(done)
                    state_c = DONE;
                state_c = FINAL;
                
                if(macbuffer <= 4) begin
                    $display("Current Outs: %d %d %d %d", write_in[0],write_in[1],write_in[2],write_in[3]);
                    buffer_c = write_in[macbuffer-1];
                    
                    wr_c = 1;
                    macbuffer = macbuffer + 1;
                end else begin
                    macbuffer = -1;
                    wr_c = 0;
                end

                if(macbuffer == -1) begin
                    wr_c = 0;
                    done_c = 1;
                end
            end
            default: begin
                state_c = START_fsm;
            end
            
        endcase
    end
endmodule

    