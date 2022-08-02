`define EN_INIT_ON                 1'b0 // enable en_init
`define EN_INIT_OFF                1'b1 // disable en_init


module task1(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

    // your code here

    logic	[7:0]  address; // input to s_mem, output from init
	logic	[7:0]  data; // input to s_mem, output from init
	logic	wren; // input to s_mem, output from init
	logic	[7:0]  data_out; // newdata output from s_mem

    logic en;  // is this not used in this module?
    logic rdy; // output from init to declare if ready for new request

    logic fast_clock;
    assign fast_clock = CLOCK_50;

    logic reset;
    assign reset = KEY[3];

    init I(.clk(fast_clock), .rst_n(reset),
            .en(en), .rdy(rdy),
            .addr(address), .wrdata(data), .wren(wren));


    s_mem s(.address(address),
	.clock(fast_clock),
	.data(data),
	.wren(wren),
	.q(data_out));
/*
    always_ff @( posedge CLOCK_50 ) begin
        if(reset) begin // active low to activate en
            en = 1'b0;
        end else begin
            en = 1'b1;
        end
    end
*/

    logic state;

    statemachine_mooremachine_task1 mt1(fast_clock, reset, state);

    statemachine_combinational_task1 ct1(state, en);


    // your code here

endmodule: task1


module statemachine_mooremachine_task1(input logic fast_clock, input logic reset,
                                        output logic state);

    logic present_state;

    always @(posedge fast_clock) begin

        if (reset) begin
            present_state = `EN_INIT_ON;
        end else begin
            case(present_state)

                `EN_INIT_ON: present_state = `EN_INIT_OFF;

                default: present_state = 1'bx;

            endcase
        end

        state = present_state;

    end
endmodule

module statemachine_combinational_task1(input logic state,
                                        output logic en);

    always @(state) begin

            case(state)

            `EN_INIT_ON: begin
                en = 1'b1;
            end

            `EN_INIT_OFF: begin
                en = 1'b0;
            end

            default: begin
                en = 1'bx;
            end

            endcase
    end

endmodule
