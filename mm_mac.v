module mm_mac(start,clk,reset,clk_count,done);
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
    wire signed [18:0] out_c;
    reg clr;
    reg wr;

    mac mac1(.inA(a),.inB(b),.clr(clr),.clk(clk),.out(out));
    RAMOUTPUT ramout(.in(out), .clk(clk), .write_enable(wr));
    
    //FSM variables
    reg [1:0] state;
    reg [1:0] state_c;
    reg [10:0] clk_count_c;
    reg done_c;
    reg wr_c;
    reg clr_c;
    reg final;
    reg final_c;
    parameter START_fsm = 3'b000;
    parameter MACOp = 3'b001;
    parameter FINAL = 3'b010;
    integer n = 512;

    integer countA = 0;
    integer countB = 0;
    integer op = 0;
    integer op_col = 0;
    integer op_row = 0;


    always @(posedge clk) begin
        state <= state_c;
        clk_count <= clk_count_c;
        done <= done_c;
        wr <= wr_c;
        final <= final_c;
        clr <= clr_c;
    end

    //FSM
    always @(state or clk_count or reset or start) begin
        case(state)
            START_fsm: begin
                if(reset) begin
                    clk_count_c = 0;
                    done_c = 0;
                    clr_c = 1;
                    wr_c = 0;
                    state_c = START_fsm;
                end
                if(!reset && start) begin
                    state_c = MACOp;
                end
            end
            MACOp: begin
                
                if(final) begin
                    wr_c = 0;
                    state_c = FINAL;
                end else if(reset) begin
                    clk_count = 0;
                    state_c = START_fsm;
                end else begin
                    clk_count_c = clk_count + 1;
                    
                    wr_c = 0;

                    state_c = MACOp;
                    $write("Next Access: (%d,%d) | Operation: %d * %d",countA,countB,a,b);
                    a = memA[countA];
                    b = memB[countB];
                    $write(" = %d | Clock Cycle: %d | clr: %d, wr: %d\n",out,clk_count,clr,wr);
                    clr_c = 0;

                    countA = countA + 8; //next row
                    countB = countB + 1; //next column
                    op = op + 1;
                    
                    if(op == 8) begin
                        op_col = op_col + 1;
                        countA = op_col;
                        countB = 8 * op_row;
                        op = 0;
                        
                        wr_c = 1;
                        clr_c = 1;

                        if(op_col == 8) begin
                            countA = 0; // refresh the matrix A count
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
            FINAL: begin
                if(reset) begin
                    clk_count_c = 0;
                    done_c = 0;
                    state_c = START_fsm;
                end else begin
                    done_c = 1;
                    state_c = FINAL;
                end
            end
            default: begin
                state_c = START_fsm;
            end
        endcase
    end
    
endmodule

    