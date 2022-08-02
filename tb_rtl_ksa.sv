// defining the states (encoding)
`define WAIT_KSA                   5'b00000
`define CHECK                      5'b00001
`define FUNCTION_J_0               5'b00010
`define FUNCTION_J_1               5'b00011
`define FUNCTION_J_2               5'b00100
`define COPY_I                     5'b00101
`define CHANGE_ADDR_J              5'b00110
`define COPY_J                     5'b00111
`define SWAP_J                     5'b01000
`define CHANGE_ADDR_I              5'b01001
`define SWAP_I                     5'b01010
`define SET_LOAD_I                 5'b01110
`define INCREMENT_KSA              5'b01011
`define DONE_KSA                   5'b01100

`define BUFFER_RDDATA              5'b01101
`define BUFFER_RDDATA_I_1          5'b01111
`define BUFFER_RDDATA_I_2          5'b10000

module tb_rtl_ksa();

// Your testbench goes here.

ksa dut(.*);

logic clk;
logic rst_n;
logic en;
logic rdy;
logic [23:0] key;
logic [7:0] addr; 
logic [7:0] rddata; 
logic [7:0] wrdata; 
logic wren;

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

en = 1'b0;

key = 24'b000000000000001100111100;
#10
en = 1'b1;

assert(dut.state == `WAIT_KSA)
else $error("Incorrect WAIT state");
#10;

assert(dut.state == `CHECK)
else $error("Incorrect CHECK state");
#10;

// loop state start

for (int i = 0; i <= 255; i++) begin
    //$display("cycle: %d", i);
    //$display(dut.state);
    if ((i % 3) == 0) begin
        assert(dut.state == `FUNCTION_J_0)
        else $error("Incorrect FUNC_J_0 (2) state");
        #10;
    end
    else if ((i % 3) == 1) begin
        assert(dut.state == `FUNCTION_J_1)
        else $error("Incorrect FUNC_J_1 (3) state");
        #10;
    end
    else if ((i % 3) == 2) begin
        assert(dut.state == `FUNCTION_J_2)
        else $error("Incorrect FUNC_J_2 (4) state");
        #10;
    end
    else begin
    #10;
    end

    assert(dut.state == `COPY_I)
    else $error("Incorrect COPY_I state");
    #10;
    assert(dut.state == `CHANGE_ADDR_J)
    else $error("Incorrect CH_ADR_J state");
    #10;
    assert(dut.state == `BUFFER_RDDATA)
    else $error("Incorrect BUF_RDATA state");
    #10;
    assert(dut.state == `BUFFER_RDDATA_I_2)
    else $error("Incorrect BUF_RDATA_I_2 state");
    #10;
    assert(dut.state == `COPY_J)
    else $error("Incorrect COPY_J state");
    #10;
    assert(dut.state == `SWAP_J)
    else $error("Incorrect SWAP_J state");
    #10;
    assert(dut.state == `CHANGE_ADDR_I)
    else $error("Incorrect CHANGE_ADDR_I state");
    #10;
    assert(dut.state == `SWAP_I)
    else $error("Incorrect SWAP_I state");
    #10;
    assert(dut.state == `SET_LOAD_I)
    else $error("Incorrect SET_LOAD_I state");
    #10;
    assert(dut.state == `INCREMENT_KSA)
    else $error("Incorrect INCREMENT_KSA state");
    #10;
    assert(dut.state == `BUFFER_RDDATA_I_1)
    else $error("Incorrect BUFFER_RDDATA_I_1 state");
    #10;
    assert(dut.state == `CHECK)
    else $error("Incorrect CHECK state");
    #10;
  
end

assert(dut.state == `DONE_KSA)
    else $error("Incorrect DONE_KSA state");
    #10;

$display("done");





$display(dut.state);


end


endmodule: tb_rtl_ksa
