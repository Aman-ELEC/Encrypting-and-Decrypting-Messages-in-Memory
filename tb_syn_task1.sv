`timescale 1ps / 1ps


module tb_syn_task1();

// Your testbench goes here.

task1 dut(CLOCK_50, KEY, SW,
          HEX0, HEX1, HEX2,
          HEX3, HEX4, HEX5,
          LEDR);

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

// logic [7:0] memory [0:255];
// assign memory = dut.\s|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem;

initial begin
    CLOCK_50 = 0;
    forever #5 CLOCK_50 = ~CLOCK_50;
end


initial begin

KEY[3] = 1'b1; // want en = 1, reset = 1 --> ~KEY[3] = 1, KEY[3] = 0;
#10;
KEY[3] = 1'b0; // want en = 0, reset = 0 --> ~KEY[3] = 0, KEY[3] = 1;

#12745;

end


endmodule: tb_syn_task1
