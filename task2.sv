`define EN_INIT_ON                 3'b000 // enable en_init
`define EN_INIT_OFF                3'b001 // disable en_init
`define CHECK_RDY_INIT             3'b010 // check for rdy_init. IF LOW, stay here. if HIGH, move to next state
`define EN_KSA_ON                  3'b011 // enable ksa_init
`define EN_KSA_OFF                 3'b100 // disable ksa_init


module task2(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

    logic	[7:0]  address_init; // input to FSM, output from init
    logic	[7:0]  address_ksa; // input to FSM, output from ksa

	logic	[7:0]  data_init; // input to FSM, output from init
    logic	[7:0]  data_ksa; // input to FSM, output from ksa

	logic	wren_init; // input to FSM, output from init
	logic	wren_ksa;  // input to FSM, output from ksa


    logic	[7:0]  address; // input to s_mem, output from FSM
	logic	[7:0]  data; // input to s_mem, output from FSM
	logic	wren; // input to s_mem, output from FSM 

	logic	[7:0]  data_out; // newdata output from s_mem

    logic en_init;  // pulse when reset pressed 
    logic rdy_init; // output from init to declare if ready for new request

    logic en_ksa;  // is this not used in this module?
    logic rdy_ksa; // output from init to declare if ready for new request

    logic [23:0] key;
    assign key = {14'b0, SW};
    
    logic reset;
    assign reset = KEY[3];

    init I(.clk(CLOCK_50), .rst_n(reset),
            .en(en_init), .rdy(rdy_init),
            .addr(address_init), .wrdata(data_init), .wren(wren_init));

    ksa K(.clk(CLOCK_50), .rst_n(reset),
            .en(en_ksa), .rdy(rdy_ksa),
            .key(key),
            .addr(address_ksa), .rddata(data_out), .wrdata(data_ksa), .wren(wren_ksa));


    s_mem s(.address(address),
	.clock(CLOCK_50),
	.data(data),
	.wren(wren),
	.q(data_out));

/*
    always_ff @( posedge CLOCK_50 ) begin
        if(reset)
            en_init = 1'b1;
        else
            en_init = 1'b0;
        if (rdy_init)       // check if init is 'rdy' to assert the 'en' for ksa
            en_ksa = 1'b1; 
        else 
            en_ksa = 1'b0; // in FSM of ksa, rdy_ksa will be set to one once complete 
    end
*/

    logic [2:0] state;

    statemachine_mooremachine_task2 mt(CLOCK_50, reset, state, rdy_init, rdy_ksa);

    statemachine_combinational_task2 ct(state,
                                        address_init, address_ksa,  
                                        data_init, data_ksa, 
                                        wren_init, wren_ksa,
                                        address,
                                        data,
                                        wren,
                                        en_init, en_ksa);

    // your code here

endmodule: task2

module statemachine_mooremachine_task2(input logic CLOCK_50, input logic reset,
                                        output logic [2:0] state, input logic rdy_init, input logic rdy_ksa);

    logic [2:0] present_state;

    always @(posedge CLOCK_50) begin

        if (reset) begin
            present_state = `EN_INIT_ON;
        end else begin
            case(present_state)

                `EN_INIT_ON: present_state = `EN_INIT_OFF; // en_init behaves like reset

                `EN_INIT_OFF: present_state = `CHECK_RDY_INIT;

                `CHECK_RDY_INIT: if (rdy_init == 1'b1)
                            present_state = `EN_KSA_ON; // when en_ksa is off, ksa does not start
                            else
                            present_state = `CHECK_RDY_INIT;

                `EN_KSA_ON: if (rdy_ksa == 1'b1)
                            present_state = `EN_KSA_OFF;
                            else
                            present_state = `EN_KSA_ON;

                `EN_KSA_OFF: present_state = `EN_KSA_OFF;

                default: present_state = 3'bxxx;

            endcase
        end

        state = present_state;

    end
endmodule

module statemachine_combinational_task2(input logic [2:0] state,
                                        input logic [7:0] address_init, input logic [7:0] address_ksa,  
                                        input logic [7:0] data_init, input logic [7:0] data_ksa, 
                                        input logic wren_init, input logic wren_ksa,
                                        output logic [7:0] address,
                                        output logic [7:0] data,
                                        output logic wren,
                                        output logic en_init, output logic en_ksa);

    always @(state or address_init or address_ksa or data_init or data_ksa or wren_init or wren_ksa) begin

            case(state)

            `EN_INIT_ON: begin
                address <= address_init;
                data <= data_init;
                wren <= wren_init;
                en_init <= 1'b1;
                en_ksa <= 1'b0;
            end

            `EN_INIT_OFF: begin
                address <= address_init;
                data <= data_init;
                wren <= wren_init;
                en_init <= 1'b0;
                en_ksa <= 1'b0;
            end

            `CHECK_RDY_INIT: begin
                address <= address_init;
                data <= data_init;
                wren <= wren_init;
                en_init <= 1'b0;
                en_ksa <= 1'b0;
            end

            `EN_KSA_ON: begin
                address <= address_ksa;
                data <= data_ksa;
                wren <= wren_ksa;
                en_init <= 1'b0;
                en_ksa <= 1'b1;
            end

            `EN_KSA_OFF: begin
                address <= 8'b00000000;
                data <= 8'b00000000;
                wren <= 1'b0;
                en_init <= 1'b1;
                en_ksa <= 1'b0;
            end

            default: begin
                address <= 8'bxxxxxxxx;
                data <= 8'bxxxxxxxx;
                wren <= 1'bx;
                en_init <= 1'bx;
                en_ksa <= 1'bx;
            end

            endcase

    end
endmodule