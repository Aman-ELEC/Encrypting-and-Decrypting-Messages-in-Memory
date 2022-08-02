`timescale 1ps / 1ps

module tb_rtl_task1();

task1 dut(.*);

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

KEY[3] = 1'b1; // want en = 1, reset = 1 --> ~KEY[3] = 1, KEY[3] = 0;
#10;
KEY[3] = 1'b0; // want en = 0, reset = 0 --> ~KEY[3] = 0, KEY[3] = 1;

// $display("memory: %p", memory);

#50; // wait for address to start updating
for (int i = 0; i < 255; i++) begin
    // $display("memory: start %p", memory);
    assert(memory[i] == i)
    else $error("Incorrect memory at address (%d)", i);
    #10;
end
#3000;

$display("memory: finished %p", memory);

end

endmodule: tb_rtl_task1
