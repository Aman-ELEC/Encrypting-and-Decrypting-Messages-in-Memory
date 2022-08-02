`define WAIT              2'b00
`define SET_LOAD          2'b01
`define INCREMENT         2'b10
`define DONE              2'b11

module tb_rtl_init();

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

en = 1'b1;
#10;
en = 1'b0;

assert(dut.state == `WAIT)
else $error("Incorrect WAIT state");
#10;
assert(dut.state == `SET_LOAD)
else $error("Incorrect SET_LOAD state");
#10;

for (int i = 0; i < 255; i++) begin
    assert(dut.state == `INCREMENT)
    else $error("Incorrect INCREMENT state (%d)", i);
    #10;
end

assert(dut.state == `DONE)
else $error("Incorrect DONE state");
#10;


// $display(dut.state);
// #10;


end

endmodule: tb_rtl_init
