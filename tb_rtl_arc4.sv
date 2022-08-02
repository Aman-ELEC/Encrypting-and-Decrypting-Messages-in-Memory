`define EN_INIT_ON                 3'b000 // enable en_init
`define EN_INIT_OFF                3'b001 // disable en_init
`define CHECK_RDY_INIT             3'b010 // check for rdy_init. IF LOW, stay here. if HIGH, move to next state
`define EN_KSA_ON                  3'b011 // enable en_ksa
`define EN_KSA_OFF                 3'b100 // disable ksa_ksa
`define EN_PRGA_ON                 3'b101 // enable en_prga
`define EN_PRGA_OFF                3'b110 // disable en_prga

`timescale 1 ps / 1 ps

module tb_rtl_arc4();

// Your testbench goes here.

arc4 dut(.*);

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

logic [7:0] memory [0:255];

assign memory = dut.s.altsyncram_component.m_default.altsyncram_inst.mem_data; 

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

en = 1'b0;
key = 24'b000000000000000000011000;     // key value for test 2
#10;
en = 1'b1;

assert(dut.state == `EN_INIT_ON)
else $error("Incorrect EN_INIT_ON state");
#10;

assert(dut.state == `EN_INIT_OFF)
else $error("Incorrect EN_INIT_OFF state");
#10;

assert(dut.state == `CHECK_RDY_INIT)
else $error("Incorrect CHECK_RDY_INIT state");
#2570;                                              // time to complete init         

assert(dut.state == `EN_KSA_ON)
else $error("Incorrect EN_KSA_ON state");
#33310;                                             // time to complete ksa

assert(dut.state == `EN_KSA_OFF)
else $error("Incorrect EN_KSA_OFF state");
#10;

assert(dut.state == `EN_PRGA_ON)
else $error("Incorrect EN_PRGA_ON state");
#10;                                                // state will goes to EN_PRGA_OFF in tb for task 3 

end

endmodule: tb_rtl_arc4
