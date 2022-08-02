`timescale 1 ps / 1 ps

module tb_rtl_task5();

// found key for test2.mif in 659,085 ps 

task5 dut(.*);

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

logic [7:0] s_memory1 [0:255];
assign s_memory1 = dut.dc.c1.a4.s.altsyncram_component.m_default.altsyncram_inst.mem_data;

logic [7:0] s_memory2 [0:255];
assign s_memory2 = dut.dc.c2.a4.s.altsyncram_component.m_default.altsyncram_inst.mem_data;


logic [7:0] ct_memory [0:255];
assign ct_memory = dut.ct.altsyncram_component.m_default.altsyncram_inst.mem_data; 

logic [7:0] ct_memory2 [0:255];
assign ct_memory2 = dut.dc.ct.altsyncram_component.m_default.altsyncram_inst.mem_data; 

logic [7:0] pt_memory1 [0:255];
assign pt_memory1 = dut.dc.c1.pt.altsyncram_component.m_default.altsyncram_inst.mem_data;

logic [7:0] pt_memory2 [0:255];
assign pt_memory2 = dut.dc.c2.pt.altsyncram_component.m_default.altsyncram_inst.mem_data;

// logic [7:0] s_memory [0:255];
// assign s_memory = dut.a4.s.altsyncram_component.m_default.altsyncram_inst.mem_data; 

// custom array / variables

int i;
int j;
int k;

logic [7:0] s_mem_test [0:255];
logic [7:0] pt_mem_test [0:255];
logic [7:0] ct_mem_test [0:255];



int hold_i;
int hold_j;

int key_test[3];

int msg_length;



initial begin
    CLOCK_50 = 0;
    forever #5 CLOCK_50 = ~CLOCK_50;
end

initial begin
#10;
//$readmemh("task4_test1.memh", ct_memory);
$readmemh("test2.memh", ct_memory);
KEY[3] = 1'b1;
//SW = 10'b0000011000; // key value for test2
//SW = 10'b1100111100; // ksa test key
//SW = 24'b000111100100011000000000;
#10;
KEY[3] = 1'b0;

// key_test values:
// key_test = '{0,0,24}; // key value for test2
// key_test = '{0,3,60}; // ksa test key
// key_test = '{30,70,0}; // key value for test1


// initializing pt_mem. looping through all keys

//key_test = '{0,0,24}; // key value for test2

for (int n = 0; n <=24; n++) begin

    key_test[2] = n; // set key_test value 

    // initialize cipher text:

    for (i = 0; i <= 255; i++) begin
        ct_mem_test[i] = dut.ct.altsyncram_component.m_default.altsyncram_inst.mem_data[i];
    end
    $display("ct_mem_test(CIPHERTEXT) = %p", ct_mem_test); // test if ciphertext read correctly


    // INIT
    for (i = 0; i <= 255; i++) begin
        s_mem_test[i] = i;
    end
    // $display("s_mem_test(0-255) = %p", s_mem_test); // s_mem_test should be initialized from 0-255


    // KSA
    for (j = 0, i = 0; i <= 255; i++) begin
        j = (j + s_mem_test[i] + key_test[i % 3]) % 256;

        hold_i = s_mem_test[i];
        hold_j = s_mem_test[j];

        s_mem_test[i] = hold_j;
        s_mem_test[j] = hold_i;

    end

    // $display("s_mem_test(KSA) = %p", s_mem_test); // s_mem_test should be initialized with ksa

    // PRGA
    msg_length = dut.ct.altsyncram_component.m_default.altsyncram_inst.mem_data[0];

    i = 0;
    j = 0;
    for (k = 1; k <= msg_length; k++) begin
        i = (i+1)%256;
        j = (j+s_mem_test[i])%256;
        
        hold_i = s_mem_test[i];
        hold_j = s_mem_test[j];

        s_mem_test[i] = hold_j;
        s_mem_test[j] = hold_i;

        // s_mem_test[k] = s_mem_test[(s_mem_test[i]+s_mem_test[j])%256];
        pt_mem_test[k] = s_mem_test[(s_mem_test[i]+s_mem_test[j])%256];


    end

    pt_mem_test[0] = msg_length;
    for (k = 1; k <= msg_length; k++) begin
        pt_mem_test[k] = pt_mem_test[k] ^ ct_mem_test[k];
    end

    $display("pt_mem_test(#%d) = %p", n, pt_mem_test); // pt_mem_test should have the final contents

end





// finish initializing test memories ---------------

// #50; // delay to wait for init to start

// $display("memory = %p", dut.a4.s.altsyncram_component.m_default.altsyncram_inst.mem_data);

// for (int x = 0; x < 256; x++) begin
//     $display("memory[%d] = %p", x, dut.a4.s.altsyncram_component.m_default.altsyncram_inst.mem_data[x]);
//     #10;
// end

// #35000; // delay to have ksa run thorough


// $display("memory(ksa) = %p", dut.a4.s.altsyncram_component.m_default.altsyncram_inst.mem_data);


// for (int i = 0; i < 256; i++) begin
//     //$display("i = %d", i);
//     $display("memory[%d] = %p", i, dut.a4.s.altsyncram_component.m_default.altsyncram_inst.mem_data[i]);
// end

// for (int u = 0; u < 100; u++) begin
//     //$display("i = %d", i);
//     $display("u=%d: memory = %p", u, dut.a4.s.altsyncram_component.m_default.altsyncram_inst.mem_data);
//     #10;
// end


// testing task2 ksa:



// after this for loop done, set delay for ksa to finish,
// then compare the two arrays $display

// assert(HEX0 == `OFF && HEX1 == `OFF && HEX2 == `OFF && 
//         HEX3 == `OFF && HEX4 == `OFF && HEX5 == `OFF &&
//         LEDR[3:0] == 4'b0000 && LEDR[7:4] == 4'b0000)
// else $error("Incorrect KSA array");    


// #12745;

end



endmodule: tb_rtl_task5
