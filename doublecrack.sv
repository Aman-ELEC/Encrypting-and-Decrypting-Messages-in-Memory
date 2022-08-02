`define EN_BC_OFF                3'b000
`define EN_BC_ON                 3'b001 
`define CHECK_KEY_1              3'b010 
`define CHECK_KEY_2              3'b011 
`define FAIL_DB                     3'b100 
`define PASS_C1                  3'b101 
`define PASS_C2                  3'b110

module doublecrack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata);

    // your code here

    logic flag_c1;
    assign flag_c1 = 1'b0;      // even

    logic flag_c2;
    assign flag_c2 = 1'b1;      // odd
    
    logic [7:0] pt_addr;
    logic [7:0] pt_rddata; // will be the value needed to CHECK_CRACK, output of pt_mem, input of a4
    logic [7:0] pt_wrdata; 
    logic pt_wren;

    logic en_crack_1;
    logic en_crack_2;

    logic rdy_crack_1;
    logic rdy_crack_2;

    logic key_valid_c1;
    logic key_valid_c2;

    logic [23:0] key_c1;
    logic [23:0] key_c2;

    logic [7:0] ct_addr_c1;
    // logic [7:0] ct_addr_c2;

    logic [7:0] ct_rddata_c1;

    logic [7:0] ct_wrdata_c1; // DNE
    assign ct_wrdata_c1 = 8'b00000000;

    logic ct_wren_c1;         // DNE
    assign ct_wren_c1 = 1'b0;

    logic load_hold_key;


    ct_mem ct(.address(ct_addr_c1),
	.clock(clk),
	.data(ct_wrdata_c1),
	.wren(ct_wren_c1),
	.q(ct_rddata_c1));



    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem pt(.address(pt_addr),
	.clock(clk),
	.data(pt_wrdata),
	.wren(pt_wren),
	.q(pt_rddata));

    // for this task only, you may ADD ports to crack
    crack c1(.clk(clk), .rst_n(rst_n),
             .en(en_crack_1), .rdy(rdy_crack_1),
             .key(key_c1), .key_valid(key_valid_c1),
             .ct_addr(ct_addr_c1), .ct_rddata(ct_rddata_c1),
             .flag(flag_c1));                               // even inc.
    crack c2(.clk(clk), .rst_n(rst_n),
             .en(en_crack_2), .rdy(rdy_crack_2),
             .key(key_c2), .key_valid(key_valid_c2),
             .ct_addr(ct_addr), .ct_rddata(ct_rddata),
             .flag(flag_c2));                               // odd inc.
    
    // your code here

    logic [2:0] state;

    register_hold_key rhk(clk, en, key_c1, key_c2, key, load_hold_key, key_valid_c1, key_valid_c2);

    statemachine_mooremachine_dc mmdc(clk, en, state, rdy_crack_1, rdy_crack_2, key_valid_c1, key_valid_c2);

    statemachine_combinational_cldc cldc(state, en_crack_1, en_crack_2, rdy, key_valid, load_hold_key);

endmodule: doublecrack

module register_hold_key(input logic clk, input logic en,             // register module
            input logic [23:0] key_c1, input logic [23:0] key_c2,
            output logic [23:0] key, input logic load_hold_key,
            input logic key_valid_c1, input logic key_valid_c2);
            
            always_ff @(posedge clk) begin
            if (en == 1'b0)
                key <= 24'b000000000000000000000000;
            else if ((load_hold_key == 1'b1) && (key_valid_c1 == 1'b1))
                key <= key_c1;
            else if ((load_hold_key == 1'b1) && (key_valid_c2 == 1'b1))
                key <= key_c2;
            else
                key <= key;
        end

endmodule

module statemachine_mooremachine_dc(input logic clk, input logic en,
                                    output logic [2:0] state,
                                    input logic rdy_crack_1,
                                    input logic rdy_crack_2,
                                    input logic key_valid_c1, input logic key_valid_c2);
    
    logic [2:0] present_state;

    always @(posedge clk) begin

        if (en == 1'b0) begin // goes through FSM when en is 1
            present_state = `EN_BC_OFF;
        end else begin
            case(present_state)

            `EN_BC_OFF: present_state = `EN_BC_ON;

 
            `EN_BC_ON: if (rdy_crack_1 == 1'b1 && rdy_crack_2 == 1'b0)      // 10
                            present_state = `CHECK_KEY_1;
                        else if (rdy_crack_1 == 1'b0 && rdy_crack_2 == 1'b1) // 01 
                            present_state = `CHECK_KEY_2;
                        else if (rdy_crack_1 == 1'b1 && rdy_crack_2 == 1'b1) // 11 
                            present_state = 3'bxxx;
                        else                                                 // 00 
                            present_state = `EN_BC_ON;

            `CHECK_KEY_1: if (key_valid_c1 == 1'b1)
                            present_state = `PASS_C1;
                            else
                            present_state = `FAIL_DB;

            `CHECK_KEY_2: if (key_valid_c2 == 1'b1)
                            present_state = `PASS_C2;
                            else
                            present_state = `FAIL_DB;

            `FAIL_DB: present_state = `FAIL_DB;

            `PASS_C1: present_state = `PASS_C1;

            `PASS_C2: present_state = `PASS_C2;

            default: present_state = 3'bxxx;

            endcase
        end

        state = present_state;

    end
endmodule

module statemachine_combinational_cldc(input logic [2:0] state,
                                       output logic en_crack_1, 
                                       output logic en_crack_2,
                                       output logic rdy,
                                       output logic key_valid,
                                       output logic load_hold_key);

    always @(state) begin
    
        case(state)
        
        `EN_BC_OFF: begin
                en_crack_1 <= 1'b0;
                en_crack_2 <= 1'b0;
                rdy        <= 1'b0; 
                key_valid  <= 1'b0;
                load_hold_key <= 1'b0;
            end

            `EN_BC_ON: begin
                en_crack_1 <= 1'b1;
                en_crack_2 <= 1'b1;
                rdy        <= 1'b0;
                key_valid  <= 1'b0;
                load_hold_key <= 1'b1; 
            end

            `CHECK_KEY_1: begin
                en_crack_1 <= 1'b0;
                en_crack_2 <= 1'b0;
                rdy        <= 1'b0;
                key_valid  <= 1'b0;
                load_hold_key <= 1'b0;
            end

            `CHECK_KEY_2: begin
                en_crack_1 <= 1'b0;
                en_crack_2 <= 1'b0;
                rdy        <= 1'b0;
                key_valid  <= 1'b0; 
                load_hold_key <= 1'b0;
            end

            `FAIL_DB: begin
                en_crack_1 <= 1'b0;
                en_crack_2 <= 1'b0;
                rdy        <= 1'b1; 
                key_valid  <= 1'b0;
                load_hold_key <= 1'b0;
            end

            `PASS_C1: begin
                en_crack_1 <= 1'b0;
                en_crack_2 <= 1'b0;
                rdy        <= 1'b1; 
                key_valid  <= 1'b1;
                load_hold_key <= 1'b0;
            end

            `PASS_C2: begin
                en_crack_1 <= 1'b0;
                en_crack_2 <= 1'b0;
                rdy        <= 1'b1; 
                key_valid  <= 1'b1;
                load_hold_key <= 1'b0;
            end

            default: begin
                en_crack_1 <= 1'bx;
                en_crack_2 <= 1'bx;
                rdy        <= 1'bx; 
                key_valid  <= 1'bx;
                load_hold_key <= 1'bx;
            end

        endcase
    end
endmodule
