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

module ksa(input logic clk, input logic rst_n,
           input logic en, output logic rdy,
           input logic [23:0] key,
           output logic [7:0] addr, input logic [7:0] rddata, output logic [7:0] wrdata, output logic wren);

    // your code here

logic [4:0] state;

logic [8:0] i;
logic load_i;

logic [7:0] j;
logic load_j;

logic [7:0] store_i;
logic load_store_i;

logic [7:0] store_j;
logic load_store_j;

    counter_i_ksa ci_ksa(clk, en, i, load_i);
    
    counter_j_ksa cj_ksa(clk, en, j, load_j, rddata, key, i);

    register_store_i st_i(clk, en, rddata, store_i, load_store_i);

    register_store_j st_j(clk, en, rddata, store_j, load_store_j);

    statemachine_mooremachine_ksa mooremachine_ksa(clk, en, state, i);

    statemachine_combinational_ksa combinational_ksa(state, rdy, key, addr, rddata, wrdata, wren,
                                                    i, j, store_i, store_j, load_i, load_j,
                                                    load_store_i, load_store_j);

endmodule: ksa

module counter_i_ksa(input logic clk, input logic en,             // register module
            output logic [8:0] i, input logic load_i);

            always_ff @(posedge clk) begin
            if (en == 1'b0)
                i <= 9'b000000000;
            else if (load_i == 1'b1)
                i <= i + 9'b000000001;
            else
                i <= i;
        end

endmodule

module counter_j_ksa(input logic clk, input logic en,             // register module
            output logic [7:0] j, input logic load_j,
            input logic [7:0] rddata, input logic [23:0] key, input logic [8:0] i);

            always_ff @(posedge clk) begin
            if (en == 1'b0)
                j <= 8'b00000000;
            else if ((load_j == 1'b1) && (i % 3 == 0))
                j <= ((j + rddata + key[23:16]) % 256);
            else if ((load_j == 1'b1) && (i % 3 == 1))
                j <= ((j + rddata + key[15:8]) % 256);
            else if ((load_j == 1'b1) && (i % 3 == 2))
                j <= ((j + rddata + key[7:0]) % 256);
            else
                j <= j;
        end

endmodule

module register_store_i(input logic clk, input logic en, 
                        input logic [7:0] rddata,
                        output logic [7:0] store_i, input logic load_store_i);

            always_ff @(posedge clk) begin
            if (en == 1'b0)
                store_i <= 8'b00000000;
            else if (load_store_i == 1'b1)
                store_i <= rddata;
            else
                store_i <= store_i;
        end

endmodule

module register_store_j(input logic clk, input logic en, 
                        input logic [7:0] rddata,
                        output logic [7:0] store_j, input logic load_store_j);

            always_ff @(posedge clk) begin
            if (en == 1'b0)
                store_j <= 8'b00000000;
            else if (load_store_j == 1'b1)
                store_j <= rddata;
            else
                store_j <= store_j;
        end

endmodule

module statemachine_mooremachine_ksa(input logic clk,
                                     input logic en, output logic [4:0] state,
                                     input logic [8:0] i);

    // wire declarations
    logic [4:0] present_state; // hold present state to check for next state

    always @(posedge clk) begin

        if (en == 1'b0) begin // if (rst_n == 0) begin, en is en_ksa
            present_state = `WAIT_KSA;
        end else begin
            case(present_state)

                `WAIT_KSA: present_state = `CHECK;

                `CHECK: if (i == 9'b100000000)
                    present_state = `DONE_KSA;
                    else begin
                        if (i % 3 == 0)
                        present_state = `FUNCTION_J_0;
                        else if (i % 3 == 1)
                        present_state = `FUNCTION_J_1;
                        else if (i % 3 == 2)
                        present_state = `FUNCTION_J_2;
                        else
                        present_state = 4'bxxxx;
                    end
                
                `FUNCTION_J_0: present_state = `COPY_I;
                `FUNCTION_J_1: present_state = `COPY_I;
                `FUNCTION_J_2: present_state = `COPY_I;

                `COPY_I: present_state = `CHANGE_ADDR_J;

                `CHANGE_ADDR_J: present_state = `BUFFER_RDDATA;

                `BUFFER_RDDATA: present_state = `BUFFER_RDDATA_I_2;

                `BUFFER_RDDATA_I_2: present_state = `COPY_J;

                `COPY_J: present_state = `SWAP_J;

                `SWAP_J: present_state = `CHANGE_ADDR_I;

                `CHANGE_ADDR_I: present_state = `SWAP_I;

                `SWAP_I: present_state = `SET_LOAD_I;

                `SET_LOAD_I: present_state = `INCREMENT_KSA;

                `INCREMENT_KSA: present_state = `BUFFER_RDDATA_I_1;

                `BUFFER_RDDATA_I_1: present_state = `CHECK;

                `DONE_KSA: present_state = `DONE_KSA;
                                
                default: present_state = 4'bxxxx;

            endcase           
    
        end

        state = present_state; // update the output wire 

    end
endmodule

module statemachine_combinational_ksa (input logic [4:0] state, output logic rdy, input logic [23:0] key,
                                        output logic [7:0] addr, input logic [7:0] rddata,
                                        output logic [7:0] wrdata, output logic wren,
                                        input logic [8:0] i, input logic [7:0] j,
                                        input logic [7:0] store_i, input logic [7:0] store_j,
                                        output logic load_i, output logic load_j,
                                        output logic load_store_i, output logic load_store_j);
                                        
    always @(state or key or rddata or i or j or store_i or store_j) begin
            
            case(state)

            `WAIT_KSA: begin
                load_i =   1'b0;            // at WAIT_KSA, en = 0 --> i is 0 // keep load at 0 to not INCREMENT_KSA
                load_j =   1'b0;
                addr =     8'b00000000;
                wrdata =   8'b00000000;
                load_store_i = 1'b0;
                load_store_j = 1'b0;
                wren =     1'b0;
                rdy =      1'b0;           
            end

            `CHECK: begin
                load_i =   1'b0;
                load_j =   1'b0;
                addr =     i[7:0];
                wrdata =   8'b00000000; // doesn't matter
                load_store_i = 1'b0;
                load_store_j = 1'b0;
                wren =     1'b0;
                rdy =      1'b0;           
            end

            `FUNCTION_J_0: begin
                load_i =   1'b0;
                load_j =   1'b1;
                addr =     i[7:0];
                wrdata =   8'b00000000; // doesn't matter
                load_store_i = 1'b1;
                load_store_j = 1'b0;
                wren =     1'b0;
                rdy =      1'b0;           
            end

            `FUNCTION_J_1: begin
                load_i =   1'b0;
                load_j =   1'b1;
                addr =     i[7:0];
                wrdata =   8'b00000000; // doesn't matter
                load_store_i = 1'b1;
                load_store_j = 1'b0;
                wren =     1'b0;
                rdy =      1'b0;           
            end

            `FUNCTION_J_2: begin
                load_i =   1'b0;
                load_j =   1'b1;
                addr =     i[7:0];
                wrdata =   8'b00000000; // doesn't matter
                load_store_i = 1'b1;                    // store_i will be rddata in next clk cycle
                load_store_j = 1'b0;
                wren =     1'b0;
                rdy =      1'b0;           
            end

            `COPY_I: begin
                load_i =   1'b0;
                load_j =   1'b0;
                addr =     i[7:0];
                wrdata =   8'b00000000;  // doesn't matter
                load_store_i = 1'b0;
                load_store_j = 1'b0;
                wren =     1'b0;
                rdy =      1'b0;           
            end

            `CHANGE_ADDR_J: begin
                load_i =   1'b0;
                load_j =   1'b0;
                addr =     j;
                wrdata =   8'b00000000; // doesn't matter
                load_store_i = 1'b0;
                load_store_j = 1'b0;
                wren =     1'b0;
                rdy =      1'b0;           
            end

            `BUFFER_RDDATA: begin // rddata takes buffer state to update
                load_i =   1'b0;
                load_j =   1'b0;
                addr =     j;
                wrdata =   8'b00000000; // doesn't matter
                load_store_i = 1'b0;
                load_store_j = 1'b0;
                wren =     1'b0;
                rdy =      1'b0;           
            end

            `BUFFER_RDDATA_I_2: begin // rddata takes buffer state to update
                load_i =   1'b0;
                load_j =   1'b0;
                addr =     j;
                wrdata =   8'b00000000; // doesn't matter
                load_store_i = 1'b0;
                load_store_j = 1'b0;
                wren =     1'b0;
                rdy =      1'b0;           
            end

            `COPY_J: begin
                load_i =   1'b0;
                load_j =   1'b0;
                addr =     j;
                wrdata =   store_i;     // s[j] = s[i]
                load_store_i = 1'b0;
                load_store_j = 1'b1;    // store_j will be rddata by next clk cycle
                wren =     1'b0;
                rdy =      1'b0;           
            end

            `SWAP_J: begin
                load_i =   1'b0;
                load_j =   1'b0;
                addr =     j;
                wrdata =   store_i;      // keep the same
                load_store_i = 1'b0;
                load_store_j = 1'b0;    // keep value in register the same
                wren =     1'b1;        // set wren to 1 to write s[i] value in s[j] spot
                rdy =      1'b0;           
            end

            `CHANGE_ADDR_I: begin
                load_i =   1'b0;
                load_j =   1'b0;
                addr =     i[7:0];
                wrdata =   store_j;     // s[i] = s[j]
                load_store_i = 1'b0;
                load_store_j = 1'b0;
                wren =     1'b0;
                rdy =      1'b0;           
            end

            `SWAP_I: begin
                load_i =   1'b0;
                load_j =   1'b0;
                addr =     i[7:0];
                wrdata =   store_j;      // keep the same
                load_store_i = 1'b0;
                load_store_j = 1'b0;
                wren =     1'b1;        // set wren to 1 to write s[j] value in s[i] spot
                rdy =      1'b0;           
            end

            `SET_LOAD_I: begin
                load_i =   1'b1;
                load_j =   1'b0;
                addr =     i[7:0];
                wrdata =   store_j;      // keep the same
                load_store_i = 1'b0;
                load_store_j = 1'b0;
                wren =     1'b0;
                rdy =      1'b0;           
            end

            `INCREMENT_KSA: begin           // i has now INCREMENTed
                load_i =   1'b0;
                load_j =   1'b0;
                addr =     i[7:0];
                wrdata =   store_j;      // keep the same --> doessn't matter
                load_store_i = 1'b0;
                load_store_j = 1'b0;
                wren =     1'b0;
                rdy =      1'b0;           
            end

            `BUFFER_RDDATA_I_1: begin           // i has now incremented
                load_i =   1'b0;
                load_j =   1'b0;
                addr =     i[7:0];
                wrdata =   store_j;      // keep the same
                load_store_i = 1'b0;
                load_store_j = 1'b0;
                wren =     1'b0;
                rdy =      1'b0;           
            end

            `DONE_KSA: begin
                load_i =   1'b0;
                load_j =   1'b0;
                addr =     8'b00000000;
                wrdata =   8'b00000000;
                load_store_i = 1'b0;
                load_store_j = 1'b0;
                wren =     1'b0;
                rdy =      1'b1;           
            end

            default: begin
                load_i =   1'bx;
                load_j =   1'bx;
                addr =     8'bxxxxxxxx;
                wrdata =   8'bxxxxxxxx;
                load_store_i = 1'bx;
                load_store_j = 1'bx;
                wren =     1'bx;
                rdy =      1'bx;           
            end

            endcase
    end

endmodule
