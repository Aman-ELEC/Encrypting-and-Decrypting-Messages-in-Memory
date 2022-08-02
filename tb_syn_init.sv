module tb_syn_init();

// Your testbench goes here.

init dut(.*);

logic clk;
logic rst_n;
logic en;
logic rdy;
logic [7:0] addr;
logic [7:0] wrdata;
logic wren;


initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

en = 1'b0;
#10
en = 1'b1;

#12745;
/*
// checking increment state
assert(addr == 8'b11111111 && wrdata == 8'b11111111 && wren == 1'b0 && rdy == 1'b0)
else $error("incorrect increment state");
#10;

// checking check state
assert(addr == 8'b11111111 && wrdata == 8'b11111111 && wren == 1'b0 && rdy == 1'b0)
else $error("incorrect check state");
#10;

// checking final state
assert(addr == 8'b00000000 && wrdata == 8'b00000000 && wren == 1'b0 && rdy == 1'b1)
else $error("incorrect final state");
#10;
*/





end




endmodule: tb_syn_init
