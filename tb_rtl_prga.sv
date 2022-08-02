`define INITIAL              5'b00000
`define CIPHER_0             5'b00001
`define CHECK_1              5'b00010
`define UPDATE_I             5'b00011
`define ADDR_I               5'b00100
`define BUFFER_1             5'b00101
`define UPDATE_J             5'b00110
`define COPY_I_PRGA          5'b00111
`define BUFFER_2             5'b01000
`define BUFFER_2_1           5'b01001
`define COPY_J_PRGA          5'b01010
`define SWAP_J_PRGA          5'b01011
`define BUFFER_3             5'b01100
`define SWAP_I_PRGA          5'b01101
`define SWAPPED              5'b01110
`define ADDR_MATH            5'b01111
`define BUFFER_4             5'b10000
`define ADDR_K               5'b10001
`define COPY_MATH            5'b10010
`define BUFFER_5             5'b10011
`define GET_PAD              5'b10100
`define SET_LOAD_K_1         5'b10101
`define INCREMENT_1          5'b10110
`define SWITCH               5'b10111
`define CHECK_2              5'b11000
`define BUFFER_6             5'b11001
`define XOR_PT               5'b11010
`define SET_LOAD_K_2         5'b11011
`define INCREMNET_2          5'b11100
`define DONE_PRGA            5'b11101
`define BUFFER_7             5'b11110

module tb_rtl_prga();

// Your testbench goes here.

prga dut(.*);

logic clk; 
logic rst_n; 
logic en;
logic rdy;
logic [23:0] key;
logic [7:0] ct_addr; 
logic [7:0] ct_rddata; 
logic [7:0] pt_addr;
logic [7:0] pt_rddata; 
logic [7:0] pt_wrdata; 
logic pt_wren;
logic [7:0] s_addr; 
logic [7:0] s_rddata; 
logic [7:0] s_wrdata; 
logic s_wren;

// logic [7:0] memory [0:255];

// assign memory = dut.s.altsyncram_component.m_default.altsyncram_inst.mem_data; 

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

en = 1'b0;
key = 24'b000000000000001100111100; // key value
#10
en = 1'b1;

assert(dut.state == `INITIAL)
else $error("Incorrect INITIAL state");
#10;
assert(dut.state == `CIPHER_0)
else $error("Incorrect CIPHER_0 state");
#10;

// loop state start

for (int i = 0; i <= 10; i++) begin
    $display("cycle: %d", i);
    // $display(dut.state);

    assert(dut.state == `CHECK_1)
    else $error("Incorrect CHECK_1 state");
    #10;
    assert(dut.state == `UPDATE_I)
    else $error("Incorrect UPDATE_I state");
    #10;
    assert(dut.state == `ADDR_I)
    else $error("Incorrect ADDR_I state");
    #10;
    assert(dut.state == `BUFFER_1)
    else $error("Incorrect BUFFER_1 state");
    #10;
    assert(dut.state == `UPDATE_J)
    else $error("Incorrect UPDATE_J state");
    #10;
    assert(dut.state == `COPY_I_PRGA)
    else $error("Incorrect COPY_I_PRGA state");
    #10;
    assert(dut.state == `BUFFER_2)
    else $error("Incorrect BUFFER_2 state");
    #10;
    assert(dut.state == `BUFFER_2_1)
    else $error("Incorrect BUFFER_2_1 state");
    #10;
    assert(dut.state == `COPY_J_PRGA)
    else $error("Incorrect COPY_J_PRGA state");
    #10;
    assert(dut.state == `SWAP_J_PRGA)
    else $error("Incorrect SWAP_J_PRGA state");
    #10;
    assert(dut.state == `BUFFER_3)
    else $error("Incorrect BUFFER_3 state");
    #10;
    assert(dut.state == `SWAP_I_PRGA)
    else $error("Incorrect SWAP_I_PRGA state");
    #10;
    assert(dut.state == `SWAPPED)
    else $error("Incorrect SWAPPED state");
    #10;
    assert(dut.state == `ADDR_MATH)
    else $error("Incorrect ADDR_MATH state");
    #10;
    assert(dut.state == `BUFFER_4)
    else $error("Incorrect BUFFER_4 state");
    #10;
    assert(dut.state == `ADDR_K)
    else $error("Incorrect ADDR_K state");
    #10;
    assert(dut.state == `COPY_MATH)
    else $error("Incorrect COPY_MATH state");
    #10;
    assert(dut.state == `BUFFER_5)
    else $error("Incorrect BUFFER_5 state");
    #10;
    assert(dut.state == `GET_PAD)
    else $error("Incorrect GET_PAD state");
    #10;
    assert(dut.state == `SET_LOAD_K_1)
    else $error("Incorrect SET_LOAD_K_1 state");
    #10;
    assert(dut.state == `INCREMENT_1)
    else $error("Incorrect INCREMENT_1 state");
    #10;
  
end

// assert(dut.state == `INCREMENT_1)
// else $error("Incorrect INCREMENT_1 state");
// #10;
// assert(dut.state == `SWITCH)
// else $error("Incorrect SWITCH state");
// #10;
// assert(dut.state == `CHECK_2)
// else $error("Incorrect CHECK_2 state");
// #10;
// assert(dut.state == `BUFFER_6)
// else $error("Incorrect BUFFER_6 state");
// #10;
// assert(dut.state == `XOR_PT)
// else $error("Incorrect XOR_PT state");
// #10;
// assert(dut.state == `SET_LOAD_K_2)
// else $error("Incorrect SET_LOAD_K_2 state");
// #10;
// assert(dut.state == `INCREMNET_2)
// else $error("Incorrect INCREMNET_2 state");
// #10;



$display("done");





$display(dut.state);

end


endmodule: tb_rtl_prga
