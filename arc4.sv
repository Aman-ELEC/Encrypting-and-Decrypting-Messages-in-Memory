`define EN_INIT_ON                 3'b000 // enable en_init
`define EN_INIT_OFF                3'b001 // disable en_init
`define CHECK_RDY_INIT             3'b010 // check for rdy_init. IF LOW, stay here. if HIGH, move to next state
`define EN_KSA_ON                  3'b011 // enable en_ksa
`define EN_KSA_OFF                 3'b100 // disable ksa_ksa
`define EN_PRGA_ON                 3'b101 // enable en_prga
`define EN_PRGA_OFF                3'b110 // disable en_prga



module arc4(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);

    logic	[7:0]  address_init; // input to FSM, output from init
    logic	[7:0]  address_ksa; // input to FSM, output from ksa
    logic	[7:0]  address_prga; // input to FSM, output from prga


	logic	[7:0]  data_init; // input to FSM, output from init
    logic	[7:0]  data_ksa; // input to FSM, output from ksa
    logic	[7:0]  data_prga; // input to FSM, output from prga

	logic	wren_init; // input to FSM, output from init
	logic	wren_ksa;  // input to FSM, output from ksa
	logic	wren_prga;  // input to FSM, output from prga



    logic	[7:0]  address; // input to s_mem, output from FSM
	logic	[7:0]  data; // input to s_mem, output from FSM
	logic	wren; // input to s_mem, output from FSM 

	logic	[7:0]  data_out; // newdata output from s_mem

    logic en_init;  // pulse when reset pressed 
    logic rdy_init; // output from init to declare ready for new request

    logic en_ksa;  // turn on after rdy_init on
    logic rdy_ksa; // output from ksa to declare ready for new request

    logic en_prga;  // turn on after rdy_ksa on
    logic rdy_prga; // output from prga to declare ready for new request

    // logic [23:0] key;
    // assign key = {14'b0, SW};
    
    // logic reset;
    // assign reset = KEY[3];

    init i(.clk(clk), .rst_n(rst_n),
            .en(en_init), .rdy(rdy_init),
            .addr(address_init), .wrdata(data_init), .wren(wren_init));

    ksa k(.clk(clk), .rst_n(rst_n),
            .en(en_ksa), .rdy(rdy_ksa),
            .key(key),
            .addr(address_ksa), .rddata(data_out), .wrdata(data_ksa), .wren(wren_ksa));


    s_mem s(.address(address),
	.clock(clk),
	.data(data),
	.wren(wren),
	.q(data_out));

    prga p(.clk(clk), .rst_n(rst_n),
            .en(en_prga), .rdy(rdy_prga),
            .key(key),
            .s_addr(address_prga), .s_rddata(data_out), .s_wrdata(data_prga), .s_wren(wren_prga),
            .ct_addr(ct_addr), .ct_rddata(ct_rddata),
            .pt_addr(pt_addr), .pt_rddata(pt_rddata), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren));


/*
    always_ff @( posedge clk ) begin
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

    statemachine_mooremachine_arc4 arc4_mm(clk, en, state, rdy_init, rdy_ksa, rdy_prga);

    statemachine_combinational_arc4 arc4_cl(state,
                                        address_init, address_ksa, address_prga,
                                        data_init, data_ksa, data_prga,
                                        wren_init, wren_ksa, wren_prga,
                                        address,
                                        data,
                                        wren,
                                        en_init, en_ksa, en_prga,
                                        rdy);

    // your code here

endmodule: arc4

module statemachine_mooremachine_arc4(input logic clk, input logic en,
                                        output logic [2:0] state, 
                                        input logic rdy_init, input logic rdy_ksa, input logic rdy_prga);

    logic [2:0] present_state;

    always @(posedge clk) begin

        if (en == 1'b0) begin // en will be 1 when running through FSM
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

                `EN_KSA_OFF: present_state = `EN_PRGA_ON;

                `EN_PRGA_ON: if (rdy_prga == 1'b1)
                            present_state = `EN_PRGA_OFF;
                            else
                            present_state = `EN_PRGA_ON;

                `EN_PRGA_OFF: present_state = `EN_PRGA_OFF;

                default: present_state = 3'bxxx;

            endcase
        end

        state = present_state;

    end
endmodule

module statemachine_combinational_arc4(input logic [2:0] state,
                                        input logic [7:0] address_init, input logic [7:0] address_ksa, input logic [7:0] address_prga,  
                                        input logic [7:0] data_init, input logic [7:0] data_ksa, input logic [7:0] data_prga, 
                                        input logic wren_init, input logic wren_ksa, input logic wren_prga,
                                        output logic [7:0] address,
                                        output logic [7:0] data,
                                        output logic wren,
                                        output logic en_init, output logic en_ksa, output logic en_prga,
                                        output logic rdy);

     always @(state or 
            address_init or address_ksa or address_prga or
            data_init or data_ksa or data_prga or
            wren_init or wren_ksa or wren_prga) begin
                
            case(state)

            `EN_INIT_ON: begin
                address <= address_init;
                data <= data_init;
                wren <= wren_init;
                en_init <= 1'b1;
                en_ksa <= 1'b0;
                en_prga <= 1'b0;
                rdy <= 1'b0;
            end

            `EN_INIT_OFF: begin
                address <= address_init;
                data <= data_init;
                wren <= wren_init;
                en_init <= 1'b0;
                en_ksa <= 1'b0;
                en_prga <= 1'b0;
                rdy <= 1'b0;
            end

            `CHECK_RDY_INIT: begin
                address <= address_init;
                data <= data_init;
                wren <= wren_init;
                en_init <= 1'b0;
                en_ksa <= 1'b0;
                en_prga <= 1'b0;
                rdy <= 1'b0;
            end

            `EN_KSA_ON: begin
                address <= address_ksa;
                data <= data_ksa;
                wren <= wren_ksa;
                en_init <= 1'b0;
                en_ksa <= 1'b1;
                en_prga <= 1'b0;
                rdy <= 1'b0;
            end

            `EN_KSA_OFF: begin
                address <= address_ksa;
                data <= data_ksa;
                wren <= wren_ksa;
                en_init <= 1'b0;
                en_ksa <= 1'b0;
                en_prga <= 1'b0;
                rdy <= 1'b0;
            end

            `EN_PRGA_ON: begin
                address <= address_prga;
                data <= data_prga;
                wren <= wren_prga;
                en_init <= 1'b0;
                en_ksa <= 1'b0;
                en_prga <= 1'b1;
                rdy <= 1'b0;
            end

            `EN_PRGA_OFF: begin
                address <= address_prga;
                data <= data_prga;
                wren <= wren_prga;
                en_init <= 1'b0;
                en_ksa <= 1'b0;
                en_prga <= 1'b0;
                rdy <= 1'b1;
            end

            default: begin
                address <= 8'bxxxxxxxx;
                data <= 8'bxxxxxxxx;
                wren <= 1'bx;
                en_init <= 1'bx;
                en_ksa <= 1'bx;
                en_prga <= 1'bx;
                rdy <= 1'bx;
            end

            endcase

    end
endmodule