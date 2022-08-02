
`timescale 1 ps / 1 ps

module tb_rtl_task2();

// Your testbench goes here.

task2 dut(.*);

logic CLOCK_50; 
logic [3:0] KEY; 
logic [9:0] SW;
logic [6:0] HEX0; 
logic [6:0] HEX1; 
logic [6:0] HEX2;
logic [6:0] HEX3; 
logic [6:0] HEX4; 
logic [6:0] HEX5;
logic [9:0] LEDR;

logic [7:0] memory [0:255];

assign memory = dut.s.altsyncram_component.m_default.altsyncram_inst.mem_data; 

initial begin
    CLOCK_50 = 0;
    forever #5 CLOCK_50 = ~CLOCK_50;
end

initial begin

KEY[3] = 1'b1;
SW = 10'b1100111100; // key value
#10
KEY[3] = 1'b0;

#50000;

$display("memory: finished %p", memory);

end

endmodule: tb_rtl_task2
