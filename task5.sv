// defining HEX numbers and letters
`define OFF 7'b1111111      //nothing is displayed
`define ZERO 7'b1000000         // 0
`define ONE 7'b1111001          // 1
`define TWO 7'b0100100          // 2
`define THREE 7'b0110000        // 3
`define FOUR 7'b0011001         // 4
`define FIVE 7'b0010010         // 5
`define SIX 7'b0000010          // 6
`define SEVEN 7'b1111000        // 7
`define EIGHT 7'b0000000        // 8
`define NINE 7'b0010000         // 9
`define A_HEX 7'b0001000        // A
`define B_HEX 7'b0000011        // b
`define C_HEX 7'b1000110        // C
`define D_HEX 7'b0100001        // d
`define E_HEX 7'b0000110        // E
`define F_HEX 7'b0001110        // F
`define BLANK 7'b0111111        // ------

`define EN_DB_CRACK_OFF               3'b000 // disable en_db_crack
`define EN_DB_CRACK_ON                3'b001 // enable en_db_crack
`define DB_CRACK_COMPLETE             3'b010 // check for key_valid being 1 or 0
`define FAIL_5                          3'b011 // key_valid = 0
`define SUCCESS                       3'b100 // key_valid = 1

module task5(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

    // your code here

    logic [23:0] key;  // this is done in the toplevel module
    // assign key = {14'b0, SW}; // this is done in the toplevel module

    logic key_valid;

    logic reset;
    assign reset = KEY[3];

    logic en_db_crack;
    logic rdy_db_crack;

    logic [7:0] ct_addr;
    logic [7:0] ct_rddata;

    logic [7:0] ct_wrdata; // DNE
    assign ct_wrdata = 8'b00000000;

    logic ct_wren;         // DNE
    assign ct_wren = 1'b0;

    ct_mem ct(.address(ct_addr),
	.clock(CLOCK_50),
	.data(ct_wrdata),
	.wren(ct_wren),
	.q(ct_rddata));

    doublecrack dc(.clk(CLOCK_50), .rst_n(reset),
             .en(en_db_crack), .rdy(rdy_db_crack),
             .key(key), .key_valid(key_valid),
             .ct_addr(ct_addr), .ct_rddata(ct_rddata));

    // your code here

    logic [6:0] hex0_seg;
    logic [6:0] hex1_seg;
    logic [6:0] hex2_seg;
    logic [6:0] hex3_seg;
    logic [6:0] hex4_seg;
    logic [6:0] hex5_seg;
    logic load_hex;

    sseg5 h0(key[3:0], hex0_seg);
    sseg5 h1(key[7:4], hex1_seg);
    sseg5 h2(key[11:8], hex2_seg);
    sseg5 h3(key[15:12], hex3_seg);
    sseg5 h4(key[19:16], hex4_seg);
    sseg5 h5(key[23:20], hex5_seg);

    register_hex5 rh5(CLOCK_50, reset,
                    key_valid, load_hex,
                    hex0_seg,
                    hex1_seg,
                    hex2_seg,
                    hex3_seg,
                    hex4_seg,
                    hex5_seg,
                    HEX0,
                    HEX1,
                    HEX2,
                    HEX3,
                    HEX4,
                    HEX5);

    logic [2:0] state;

    statemachine_mooremachine_task5 mt5(CLOCK_50, reset, state, key_valid, rdy_db_crack);

    statemachine_combinational_task5 ct5(state,
                                        load_hex,
                                        en_db_crack);

endmodule: task5

module register_hex5(input logic CLOCK_50, input logic reset,
                    input logic key_valid, input logic load_hex,
                    input logic [6:0] hex0_seg,
                    input logic [6:0] hex1_seg,
                    input logic [6:0] hex2_seg,
                    input logic [6:0] hex3_seg,
                    input logic [6:0] hex4_seg,
                    input logic [6:0] hex5_seg,
                    output logic [6:0] HEX0,
                    output logic [6:0] HEX1,
                    output logic [6:0] HEX2,
                    output logic [6:0] HEX3,
                    output logic [6:0] HEX4,
                    output logic [6:0] HEX5);

            always_ff @(posedge CLOCK_50) begin
            if (reset) begin
                HEX0 <= `OFF;
                HEX1 <= `OFF;
                HEX2 <= `OFF;
                HEX3 <= `OFF;
                HEX4 <= `OFF;
                HEX5 <= `OFF;
            end
            else if ((load_hex == 1'b1) && (key_valid == 1'b0)) begin
                HEX0 <= `BLANK;
                HEX1 <= `BLANK;
                HEX2 <= `BLANK;
                HEX3 <= `BLANK;
                HEX4 <= `BLANK;
                HEX5 <= `BLANK;
            end
            else if ((load_hex == 1'b1) && (key_valid == 1'b1)) begin
                HEX0 <= hex0_seg;
                HEX1 <= hex1_seg;
                HEX2 <= hex2_seg;
                HEX3 <= hex3_seg;
                HEX4 <= hex4_seg;
                HEX5 <= hex5_seg;
            end
            else begin
                HEX0 <= HEX0;
                HEX1 <= HEX1;
                HEX2 <= HEX2;
                HEX3 <= HEX3;
                HEX4 <= HEX4;
                HEX5 <= HEX5;
            end
        end

endmodule

module statemachine_mooremachine_task5(input logic CLOCK_50, input logic reset,
                                        output logic [2:0] state, input logic key_valid, input logic rdy_db_crack);

    logic [2:0] present_state;

    always @(posedge CLOCK_50) begin

        if (reset) begin
            present_state = `EN_DB_CRACK_OFF;
        end else begin
            case(present_state)

                `EN_DB_CRACK_OFF: present_state = `EN_DB_CRACK_ON;

                `EN_DB_CRACK_ON: if (rdy_db_crack == 1'b1) // 16777215
                            present_state = `DB_CRACK_COMPLETE;
                            else
                            present_state = `EN_DB_CRACK_ON;

                `DB_CRACK_COMPLETE: if (key_valid == 1'b1) // 16777215
                            present_state = `SUCCESS;
                            else
                            present_state = `FAIL_5;
                
                `SUCCESS: present_state = `SUCCESS;

                `FAIL_5: present_state = `FAIL_5;

                default: present_state = 3'bxxx;

            endcase
        end

        state = present_state;

    end
endmodule



module statemachine_combinational_task5(input logic [2:0] state,
                                        output logic load_hex,
                                        output logic en_db_crack);

    always @(state) begin

            case(state)

            `EN_DB_CRACK_OFF: begin
                en_db_crack = 1'b0;
                load_hex = 1'b0;
            end

            `EN_DB_CRACK_ON: begin
                en_db_crack = 1'b1;
                load_hex = 1'b0;
            end

            `DB_CRACK_COMPLETE: begin
                en_db_crack = 1'b0;
                load_hex = 1'b1;
            end

            `SUCCESS: begin
                en_db_crack = 1'b0;
                load_hex = 1'b0;
            end

            `FAIL_5: begin
                en_db_crack = 1'b0;
                load_hex = 1'b0;
            end

            default: begin
                en_db_crack = 1'bx;
                load_hex = 1'bx;
            end

            endcase
    end

endmodule

module sseg5(in,segs);
  input [3:0] in;
  output reg [6:0] segs;

  always @(in) begin

    case (in)  //update 7-seg displays only if NOT in the final states 
    4'b0000:segs = `ZERO;
        
    4'b0001:segs = `ONE;
        
    4'b0010:segs = `TWO;
          
    4'b0011:segs = `THREE;
          
    4'b0100:segs = `FOUR;                   
        
    4'b0101:segs = `FIVE;                       
        
    4'b0110:segs = `SIX;                    
        
    4'b0111:segs = `SEVEN;
          
    4'b1000:segs = `EIGHT;
          
    4'b1001:segs = `NINE;

    4'b1010:segs = `A_HEX;

    4'b1011:segs = `B_HEX;
    
    4'b1100:segs = `C_HEX;

    4'b1101:segs = `D_HEX;

    4'b1110:segs = `E_HEX;

    4'b1111:segs = `F_HEX;
          
    default:segs = 7'bxxxxxxx;

    endcase
    
  end

endmodule