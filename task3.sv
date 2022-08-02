`define EN_ARC4_ON                 1'b0 // enable en_arc4
`define EN_ARC4_OFF                1'b1 // disable en_arc4

module task3(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

    // your code here

    logic [23:0] key;  // this is done in the toplevel module
    assign key = {14'b0, SW}; // this is done in the toplevel module

    logic reset;
    assign reset = KEY[3];

    logic [7:0] ct_addr;
    logic [7:0] ct_rddata;

    logic [7:0] ct_wrdata; // DNE
    assign ct_wrdata = 8'b00000000;

    logic ct_wren;         // DNE
    assign ct_wren = 1'b0;

    logic [7:0] pt_addr;
    logic [7:0] pt_rddata;

    logic [7:0] pt_wrdata; 

    logic pt_wren;         

    logic en_arc4;
    logic rdy_arc4;
    
    ct_mem ct(.address(ct_addr),
	.clock(CLOCK_50),
	.data(ct_wrdata),
	.wren(ct_wren),
	.q(ct_rddata));

    pt_mem pt(.address(pt_addr),
	.clock(CLOCK_50),
	.data(pt_wrdata),
	.wren(pt_wren),
	.q(pt_rddata));

    arc4 a4(.clk(CLOCK_50), .rst_n(reset),
            .en(en_arc4), .rdy(rdy_arc4),
            .key(key),
            .ct_addr(ct_addr), .ct_rddata(ct_rddata),
            .pt_addr(pt_addr), .pt_rddata(pt_rddata), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren));

    // your code here

    logic state;

    statemachine_mooremachine_task3 mt3(CLOCK_50, reset, state);

    statemachine_combinational_task3 ct3(state, en_arc4);

endmodule: task3

module statemachine_mooremachine_task3(input logic CLOCK_50, input logic reset,
                                        output logic state);

    logic present_state;

    always @(posedge CLOCK_50) begin

        if (reset) begin
            present_state = `EN_ARC4_OFF;
        end else begin
            case(present_state)

                `EN_ARC4_OFF: present_state = `EN_ARC4_ON;

                `EN_ARC4_ON: present_state = `EN_ARC4_ON;

                default: present_state = 1'bx;

            endcase
        end

        state = present_state;

    end
endmodule

module statemachine_combinational_task3(input logic state,
                                        output logic en_arc4);

    always @(state) begin

            case(state)

            `EN_ARC4_OFF: begin
                en_arc4 = 1'b0;
            end

            `EN_ARC4_ON: begin
                en_arc4 = 1'b1;

            end
            default: begin
                en_arc4 = 1'bx;
            end

            endcase
    end

endmodule


