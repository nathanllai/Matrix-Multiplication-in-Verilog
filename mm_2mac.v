module mm_twomac(start,clk,reset,clk_count,done);
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
    wire signed [18:0] out;
    wire signed [18:0] out2;
    reg clr;
    reg wr;

    reg signed [18:0] buffer;
    reg signed [7:0] a2;

    mac mac1(.inA(a),.inB(b),.clr(clr),.clk(clk),.out(out));
    mac mac2(.inA(a2),.inB(b),.clr(clr),.clk(clk),.out(out2));

    RAMOUTPUT ramout(.in(buffer), .clk(clk), .write_enable(wr));
    
    //FSM variables
    reg [2:0] state;
    reg [2:0] state_c;
    reg [10:0] clk_count_c;
    reg signed [18:0] buffer_c;
    reg signed [18:0] write_in;
    reg done_c;
    reg wr_c;
    reg clr_c;
    reg final_c;
    reg final;
    parameter START_fsm = 3'b000;
    parameter MACOp = 3'b001;
    parameter DONE = 3'b010;
    parameter FINAL_fsm = 3'b011;
    integer n = 512;

    integer countA = 0;
    integer countB = 0;
    integer op = 0;
    integer op_col = 0;
    integer op_row = 0;

    reg [1:0] macbuffer;


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
                    buffer_c = out;
                    write_in = out2;
                    wr_c = 1;
                    state_c = FINAL_fsm;
                end else if(reset) begin
                    clk_count = 0;
                    state_c = START_fsm;
                end else begin
                    clk_count_c = clk_count + 1;
                    if(macbuffer == 1) begin
                        buffer_c = out;
                        write_in = out2;
                        wr_c = 1;
                        macbuffer = 2;
                    end else if(macbuffer == 2) begin
                        buffer_c = write_in;
                        wr_c = 1;
                        macbuffer = 0;
                    end else begin
                        wr_c = 0;
                    end

                    
                    state_c = MACOp;
                    $display("MAC1: Next Access: (%d,%d) | Operation: %d * %d | MAC1: Out = %d | Clock Cycle: %d | clr: %d, wr: %d",countA,countB,a,b,out,clk_count,clr,wr);
                    //$display("MAC2: Next Access: (%d,%d) | Operation: %d * %d | MAC1: Out = %d | Clock Cycle: %d | clr: %d, wr: %d",countA+4,countB,a2,b,out2,clk_count,clr,wr);
                    //$write(" | MAC2: Next Access: (%d, %d) | Operation: %d * %d\n",countA+4,countB,a2,b);
                    a = memA[countA];
                    // a2 has element 4 indices ahead of a
                    a2 = memA[countA + 1];
                    b = memB[countB];
                    //$write("MAC1: Out = %d | Clock Cycle: %d | clr: %d, wr: %d | ",out,clk_count, clr,wr);
                    //$write("MAC2: Out = %d | Clock Cycle: %d | clr: %d, wr: %d\n",out2,clk_count, clr,wr);
                    //$display("Write %d to RAMOUTPUT", out);
                    clr_c = 0;

                    countA = countA + 8; //next row
                    countB = countB + 1; //next column
                    op = op + 1;
                    
                    if(op == 8) begin
                        op_col = op_col + 2;
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
            FINAL_fsm: begin
                if(done) begin
                    state_c = DONE;
                end
                $display("%d %d",buffer_c, write_in);
                state_c = FINAL_fsm;

                if(macbuffer == 1) begin
                    buffer_c = write_in;
                    wr_c = 1;
                    macbuffer = 2;
                end else begin
                    wr_c = 0;
                    macbuffer = 3;
                end

                if(macbuffer == 3) 
                    done_c = 1;
            end
            default: begin
                state_c = START_fsm;
            end
        endcase
    end
    
endmodule

    