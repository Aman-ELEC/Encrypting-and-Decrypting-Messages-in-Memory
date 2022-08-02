`define EN_BC_OFF                3'b000
`define EN_BC_ON                 3'b001 
`define CHECK_KEY_1              3'b010 
`define CHECK_KEY_2              3'b011 
`define FAIL_DB                     3'b100 
`define PASS_C1                  3'b101 
`define PASS_C2                  3'b110

`timescale 1 ps / 1 ps

module tb_rtl_doublecrack();

// Your testbench goes here.

doublecrack dut(.*);

logic clk;
logic rst_n;
logic en;
logic rdy;
logic [23:0] key;
logic key_valid;
logic [7:0] ct_addr;
logic [7:0] ct_rddata;

logic [7:0] s_memory1 [0:255];
assign s_memory1 = dut.c1.a4.s.altsyncram_component.m_default.altsyncram_inst.mem_data;

logic [7:0] s_memory2 [0:255];
assign s_memory2 = dut.c2.a4.s.altsyncram_component.m_default.altsyncram_inst.mem_data;

logic [7:0] ct_memory [0:255];
assign ct_memory = dut.ct.altsyncram_component.m_default.altsyncram_inst.mem_data; 

logic [7:0] pt_memory1 [0:255];
assign pt_memory1 = dut.c1.pt.altsyncram_component.m_default.altsyncram_inst.mem_data;

logic [7:0] pt_memory2 [0:255];
assign pt_memory2 = dut.c2.pt.altsyncram_component.m_default.altsyncram_inst.mem_data;

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

en = 1'b0;
//key = 24'b000000000000000000011000;     // key value for test 2
#10;
en = 1'b1;

assert(dut.state == `EN_BC_OFF)
else $error("Incorrect EN_BC_OFF state");
#10;

assert(dut.state == `EN_BC_ON)
else $error("Incorrect EN_BC_ON state");
#659090;                                    // set ps to state where dc passes

assert(dut.state == `PASS_C1)
else $error("Incorrect PASS_C1 state");
#10;


end

endmodule: tb_rtl_doublecrack
