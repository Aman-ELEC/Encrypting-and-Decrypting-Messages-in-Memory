`define INITIAL_CRACK       5'b00000 
`define TRY_KEY             5'b00001 
`define EN_ARC4_ON          5'b00010 
`define EN_ARC4_OFF         5'b00011 
`define SWITCH_I            5'b00100 
`define BUFFER              5'b00101 
`define CHECK_CRACK         5'b00110 
`define NEW_PT_RD           5'b00111 
`define CONSTRAINTS         5'b01000 
`define SET_LOAD_I_CRACK    5'b01001 
`define INCREMENT_I         5'b01010 
`define RESET_I             5'b01011
`define SWITCH_ADDR         5'b01100 
`define SET_LOAD_KEY        5'b01101
`define INCREMENT_KEY       5'b01110
`define FAIL                5'b01111
`define PASS                5'b10000

module crack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
             input logic flag    // determines even or odd incrementation of key_test
         /* any other ports you need to add */);

    // For Task 5, you may modify the crack port list above,
    // but ONLY by adding new ports. All predefined ports must be identical.

    // your code here

    logic [23:0] key_test; // will be the input to a4
                           // will increment until pt_mem is between 'h20 and 'h7e or until FAIL
    logic load_key;        // will need register

    logic [7:0] pt_addr;
    logic [7:0] pt_rddata; // will be the value needed to CHECK_CRACK, output of pt_mem, input of a4
    logic [7:0] pt_wrdata; 
    logic pt_wren;  

    logic en_arc4;
    logic rdy_arc4;

    logic [7:0] i;          // will help incrementation through pt_mem once arc4 is complete
    logic load_i;
    logic reset_i;

    logic [7:0] message_length;

    logic [7:0] address;

    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem pt(.address(address),
	.clock(clk),
	.data(pt_wrdata),
	.wren(pt_wren),
	.q(pt_rddata));

    arc4 a4(.clk(clk), .rst_n(rst_n),
            .en(en_arc4), .rdy(rdy_arc4),
            .key(key_test),
            .ct_addr(ct_addr), .ct_rddata(ct_rddata),
            .pt_addr(pt_addr), .pt_rddata(pt_rddata), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren));

    // your code here

    logic [4:0] state;

    counter_key_test5 ckt5(clk, en, key_test, load_key, flag);

    counter_i_crack5 cic5(clk, en, i, load_i, reset_i);

    register_message_crack5 message_crack5(clk, en, ct_addr, ct_rddata, message_length);

    statemachine_mooremachine_crack5 crack_mm5(clk, en, state, rdy_arc4, key_test, i, pt_rddata, message_length);

    statemachine_combinational_crack5 crack_cl5(state, rdy, key, key_test, key_valid,
                                              address,
                                              pt_addr, i,
                                              en_arc4, load_i, reset_i, load_key,
                                              message_length);

endmodule: crack

module counter_key_test5(input logic clk, input logic en,             // register module
            output logic [23:0] key_test, input logic load_key, input logic flag);
            
            // flag = 0 --> even
            // flag = 1 --> odd
            
            always_ff @(posedge clk) begin
            if ((en == 1'b0) && (flag == 1'b0))
                key_test <= 24'b000000000000000000000000;
            else if ((en == 1'b0) && (flag == 1'b1))
                key_test <= 24'b000000000000000000000001;
            else if (load_key == 1'b1)
                key_test <= key_test + 24'b000000000000000000000010;
            else
                key_test <= key_test;
        end

endmodule

module counter_i_crack5(input logic clk, input logic en,             // register module
            output logic [7:0] i, input logic load_i, input logic reset_i);

            always_ff @(posedge clk) begin
            if (en == 1'b0 || reset_i == 1'b1)
                i <= 8'b00000000;
            else if (load_i == 1'b1)
                i <= i + 8'b00000001;
            else
                i <= i;
        end

endmodule

module register_message_crack5(input logic clk, input logic en,
                        input logic [7:0] ct_addr, input logic [7:0] ct_rddata,
                        output logic [7:0] message_length);

            always_ff @(posedge clk) begin
            if (en == 1'b0)
                message_length <= 8'b00000000;
            else if (ct_addr == 8'b00000000)
                message_length <= ct_rddata;                // ct_rddata is ct[0]
            else
                message_length <= message_length;
        end
endmodule

module statemachine_mooremachine_crack5(input logic clk, input logic en,
                                       output logic [4:0] state,
                                       input logic rdy_arc4,
                                       input logic [23:0] key_test,
                                       input logic [7:0] i,
                                       input logic [7:0] pt_rddata,
                                       input logic [7:0] message_length);
    
    logic [4:0] present_state;

    always @(posedge clk) begin

        if (en == 1'b0) begin // goes through FSM when en is 1
            present_state = `INITIAL_CRACK;
        end else begin
            case(present_state)

             `INITIAL_CRACK: present_state = `TRY_KEY;

             `TRY_KEY: if (key_test <= 24'b111111111111111111111111) // 16777215
                            present_state = `EN_ARC4_ON;
                            else
                            present_state = `FAIL;
            
            `EN_ARC4_ON: if (rdy_arc4 == 1'b1)
                            present_state = `EN_ARC4_OFF;
                            else
                            present_state = `EN_ARC4_ON;

            `EN_ARC4_OFF: present_state = `SWITCH_I;

            `SWITCH_I: present_state = `BUFFER;

            `BUFFER: present_state = `CHECK_CRACK;

            `CHECK_CRACK: if (i <= message_length)
                            present_state = `NEW_PT_RD;
                            else
                            present_state = `PASS;

            `NEW_PT_RD: present_state = `CONSTRAINTS;

            `CONSTRAINTS: if ((pt_rddata >= 8'b00100000) && (pt_rddata <= 8'b01111110))
                            present_state = `SET_LOAD_I_CRACK; // when en_ksa is off, ksa does not start
                            else
                            present_state = `RESET_I; // try different key value

            `SET_LOAD_I_CRACK: present_state = `INCREMENT_I;

            `INCREMENT_I: present_state = `CHECK_CRACK;

            `RESET_I: present_state = `SWITCH_ADDR;

            `SWITCH_ADDR: present_state = `SET_LOAD_KEY;

            `SET_LOAD_KEY: present_state = `INCREMENT_KEY;

            `INCREMENT_KEY: present_state = `TRY_KEY;

            `FAIL: present_state = `FAIL; // key_valid = 0;

            `PASS: present_state = `PASS; // key_valid = 1;

            default: present_state = 5'bxxxxx;
                            
    
            endcase
        end

        state = present_state;
    
    end

endmodule

module statemachine_combinational_crack5(input logic [4:0] state, output logic rdy,
                                        output logic [23:0] key,
                                        input logic [23:0] key_test,
                                        output logic key_valid,
                                        output logic [7:0] address,
                                        input logic [7:0] pt_addr,
                                        input logic [7:0] i,
                                        output logic en_arc4,
                                        output logic load_i,
                                        output logic reset_i,
                                        output logic load_key,
                                        input logic [7:0] message_length);

    always @(state or key_test or pt_addr or i or message_length) begin
    
        case(state)
        
        `INITIAL_CRACK: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        pt_addr;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            `TRY_KEY: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        pt_addr;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            `EN_ARC4_ON: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        pt_addr;
                
                en_arc4 <=        1'b1;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            `EN_ARC4_OFF: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        pt_addr;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            `SWITCH_I: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        i;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            `BUFFER: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        i;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            `CHECK_CRACK: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        i;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            `NEW_PT_RD: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        i;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            `CONSTRAINTS: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        i;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            `SET_LOAD_I_CRACK: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        i;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b1;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            `INCREMENT_I: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        i;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            `RESET_I: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        i;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b1;
                load_key <=       1'b0;
            end

            `SWITCH_ADDR: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        pt_addr;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            `SET_LOAD_KEY: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        pt_addr;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b1;
            end

            `INCREMENT_KEY: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b0;

                address <=        pt_addr;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            `FAIL: begin
                key <=            24'b000000000000000000000000;
                key_valid <=      1'b0;
                rdy <=            1'b1;

                address <=        pt_addr;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            `PASS: begin
                key <=            key_test;
                key_valid <=      1'b1;
                rdy <=            1'b1;

                address <=        pt_addr;
                
                en_arc4 <=        1'b0;
                
                load_i <=         1'b0;
                reset_i <=        1'b0;
                load_key <=       1'b0;
            end

            default: begin
                key <=            24'bxxxxxxxxxxxxxxxxxxxxxxxx;
                key_valid <=      1'bx;
                rdy <=            1'bx;

                address <=        8'bxxxxxxxx;
                
                en_arc4 <=        1'bx;
                
                load_i <=         1'bx;
                reset_i <=        1'bx;
                load_key <=       1'bx;
            end

        endcase
    end


endmodule