`define INITIAL              5'b00000
`define CIPHER_0             5'b00001
`define CHECK_1              5'b00010
`define UPDATE_I             5'b00011
`define ADDR_I               5'b00100
`define BUFFER_1             5'b00101
`define UPDATE_J             5'b00110
`define COPY_I_PRGA          5'b00111
`define BUFFER_2             5'b01000
`define BUFFER_2_1           5'b01001
`define COPY_J_PRGA          5'b01010
`define SWAP_J_PRGA          5'b01011
`define BUFFER_3             5'b01100
`define SWAP_I_PRGA          5'b01101
`define SWAPPED              5'b01110
`define ADDR_MATH            5'b01111
`define BUFFER_4             5'b10000
`define ADDR_K               5'b10001
`define COPY_MATH            5'b10010
`define BUFFER_5             5'b10011
`define GET_PAD              5'b10100
`define SET_LOAD_K_1         5'b10101
`define INCREMENT_1          5'b10110
`define SWITCH               5'b10111
`define CHECK_2              5'b11000
`define BUFFER_6             5'b11001
`define XOR_PT               5'b11010
`define SET_LOAD_K_2         5'b11011
`define INCREMNET_2          5'b11100
`define DONE_PRGA            5'b11101
`define BUFFER_7             5'b11110



module prga(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] s_addr, input logic [7:0] s_rddata, output logic [7:0] s_wrdata, output logic s_wren,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);

    // your code here

logic [4:0] state;

logic [7:0] i;
logic load_i;

logic [7:0] j;
logic load_j;

logic [7:0] k;
logic load_k_inc;
logic load_k_1;

logic [7:0] store_i;
logic load_store_i;

logic [7:0] store_j;
logic load_store_j;

logic [7:0] math;           // acts as index --> s[(s[i]+s[j]) mod 256] = s[math]
logic [7:0] store_math;
logic load_math;

logic [7:0] message_length;

    counter_i_prga ci_prga(clk, en, i, load_i);
    
    counter_j_prga cj_prga(clk, en, j, load_j, s_rddata);

    counter_k_prga ck_prga(clk, en, k, load_k_inc, load_k_1);

    register_store_i_prga st_i_prga(clk, en, s_rddata, store_i, load_store_i);

    register_store_j_prga st_j_prga(clk, en, s_rddata, store_j, load_store_j);

    register_math math_prga(clk, en, s_rddata, store_math, load_math);

    register_message message_prga(clk, en, ct_addr, ct_rddata, message_length);

    statemachine_mooremachine_prga mooremachine_prga(clk, en, state, k, message_length);

    statemachine_combinational_prga combinational_prga(state, rdy, 
                                                    s_addr, s_rddata, s_wrdata, s_wren,
                                                    ct_addr, ct_rddata,
                                                    pt_addr, pt_rddata, pt_wrdata, pt_wren,
                                                    i, j, k,
                                                    store_i, store_j, store_math,
                                                    load_i, load_j, load_k_inc, load_k_1,
                                                    load_store_i, load_store_j, load_math, math, message_length);

endmodule: prga

module counter_i_prga(input logic clk, input logic en,             // register module
            output logic [7:0] i, input logic load_i);

            always_ff @(posedge clk) begin
            if (en == 1'b0)
                i <= 8'b00000000;
            else if (load_i == 1'b1)
                i <= ((i + 8'b00000001) % 256);
            else
                i <= i;
        end

endmodule

module counter_j_prga(input logic clk, input logic en,             // register module
            output logic [7:0] j, input logic load_j,
            input logic [7:0] s_rddata);

            always_ff @(posedge clk) begin
            if (en == 1'b0)
                j <= 8'b00000000;
            else if (load_j == 1'b1)
                j <= ((j + s_rddata) % 256);
            else
                j <= j;
        end

endmodule

module counter_k_prga(input logic clk, input logic en,             // register module
            output logic [7:0] k, input logic load_k_inc, input logic load_k_1);

            always_ff @(posedge clk) begin
            if (en == 1'b0 || load_k_1 == 1'b1)
                k <= 8'b00000001;
            else if (load_k_inc == 1'b1)
                k <= k + 8'b00000001;
            else
                k <= k;
        end

endmodule

module register_store_i_prga(input logic clk, input logic en, 
                        input logic [7:0] s_rddata,
                        output logic [7:0] store_i, input logic load_store_i);

            always_ff @(posedge clk) begin
            if (en == 1'b0)
                store_i <= 8'b00000000;
            else if (load_store_i == 1'b1)
                store_i <= s_rddata;
            else
                store_i <= store_i;
        end

endmodule

module register_store_j_prga(input logic clk, input logic en, 
                        input logic [7:0] s_rddata,
                        output logic [7:0] store_j, input logic load_store_j);

            always_ff @(posedge clk) begin
            if (en == 1'b0)
                store_j <= 8'b00000000;
            else if (load_store_j == 1'b1)
                store_j <= s_rddata;
            else
                store_j <= store_j;
        end

endmodule

module register_math(input logic clk, input logic en, 
                        input logic [7:0] s_rddata,
                        output logic [7:0] store_math, input logic load_math);

            always_ff @(posedge clk) begin
            if (en == 1'b0)
                store_math <= 8'b00000000;
            else if (load_math == 1'b1)
                store_math <= s_rddata;
            else
                store_math <= store_math;
        end

endmodule

module register_message(input logic clk, input logic en,
                        input logic [7:0] ct_addr, input logic [7:0] ct_rddata,
                        output logic [7:0] message_length);

            always_ff @(posedge clk) begin
            if (en == 1'b0)
                message_length <= 8'b00000000;
            else if (ct_addr == 8'b00000000)
                message_length <= ct_rddata;                // ct_rddata is ct[0]
            else
                message_length <= message_length;
        end
endmodule

module statemachine_mooremachine_prga(input logic clk,
                                     input logic en, output logic [4:0] state,
                                     input logic [7:0] k, input logic [7:0] message_length);

    // wire declarations
    logic [4:0] present_state; // hold present state to check for next state

    always @(posedge clk) begin

        if (en == 1'b0) begin // if (rst_n == 0) begin, en is en_ksa
            present_state = `INITIAL;
        end else begin
            case(present_state)

                `INITIAL: present_state = `CIPHER_0;

                `CIPHER_0: present_state = `CHECK_1;

                `CHECK_1: if (k > message_length)
                    present_state = `SWITCH;
                    else begin
                        present_state = `UPDATE_I;
                    end
                
                `UPDATE_I: present_state = `ADDR_I;

                `ADDR_I: present_state = `BUFFER_1;

                `BUFFER_1: present_state = `UPDATE_J;

                `UPDATE_J: present_state = `COPY_I_PRGA;

                `COPY_I_PRGA: present_state = `BUFFER_2;

                `BUFFER_2: present_state = `BUFFER_2_1;

                `BUFFER_2_1: present_state = `COPY_J_PRGA;

                `COPY_J_PRGA: present_state = `SWAP_J_PRGA;

                `SWAP_J_PRGA: present_state = `BUFFER_3;

                `BUFFER_3: present_state = `SWAP_I_PRGA;

                `SWAP_I_PRGA: present_state = `SWAPPED;

                `SWAPPED: present_state = `ADDR_MATH;

                `ADDR_MATH: present_state = `BUFFER_4;

                `BUFFER_4: present_state = `ADDR_K;

                `ADDR_K: present_state = `COPY_MATH;

                `COPY_MATH: present_state = `BUFFER_5;

                `BUFFER_5: present_state = `GET_PAD;               
                
                `GET_PAD: present_state = `SET_LOAD_K_1;

                `SET_LOAD_K_1: present_state = `INCREMENT_1;

                `INCREMENT_1: present_state = `CHECK_1;

                /*___________________________________*/

                `SWITCH: present_state = `CHECK_2;

                `CHECK_2: if (k > message_length)
                    present_state = `DONE_PRGA;
                    else begin
                        present_state = `BUFFER_6;
                    end

                `BUFFER_6: present_state = `BUFFER_7;

                `BUFFER_7: present_state = `XOR_PT;

                `XOR_PT: present_state = `SET_LOAD_K_2;

                `SET_LOAD_K_2: present_state = `INCREMNET_2;

                `INCREMNET_2: present_state = `CHECK_2;

                `DONE_PRGA: present_state = `DONE_PRGA;

                default: present_state = 4'bxxxx;

            endcase           
    
        end

        state = present_state; // update the output wire 

    end
endmodule

module statemachine_combinational_prga(input logic [4:0] state, output logic rdy, 
                                       output logic [7:0] s_addr, input logic [7:0] s_rddata, output logic [7:0] s_wrdata, output logic s_wren,
                                       output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
                                       output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren,
                                       input logic [7:0] i, input logic [7:0] j, input logic [7:0] k,
                                       input logic [7:0] store_i, input logic [7:0] store_j, input logic [7:0] store_math,
                                       output logic load_i, output logic load_j, output logic load_k_inc, output logic load_k_1,
                                       output logic load_store_i, output logic load_store_j, output logic load_math, output logic [7:0] math, input logic [7:0] message_length);

    always @(state or s_rddata or ct_rddata or pt_rddata or i or j or k or store_i or store_j or store_math or message_length or math) begin
            
            case(state)

            `INITIAL: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         8'b00000000;
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;

                rdy =            1'b0;           
            end

            `CIPHER_0: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         8'b00000000;
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `CHECK_1: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         8'b00000000;
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `UPDATE_I: begin
                load_i =         1'b1;              // calc new i by next clk cycle
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         8'b00000000;
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `ADDR_I: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         i;                 // this is the new i value
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `BUFFER_1: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         i;                 // s_addr is now updated
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `UPDATE_J: begin
                load_i =         1'b0;
                load_j =         1'b1;              // new j value by next clk cycle
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         i;                 // s_rddata = s[i]
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b1;              // store_i will update by next clk cycle
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `COPY_I_PRGA: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         j;
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;              // store_i = s[i]
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `BUFFER_2: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         j;                 // s_addr is now j
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;              // store_i = s[i]
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `BUFFER_2_1: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         j;                 // s_rddata = s[j]
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b1;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `COPY_J_PRGA: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         j;                 // s_rddata = s[j]
                s_wrdata =       store_i;
                s_wren =         1'b1;              // will write store_i to s[j] at next clk cycle

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;              // store_j = s[j]
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `SWAP_J_PRGA: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         i;                 // will move to s[i] by next clk cycle
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `BUFFER_3: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         i;                 // s_addr is now at i
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `SWAP_I_PRGA: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         i;                 // s_rddata = s[i]
                s_wrdata =       store_j;
                s_wren =         1'b1;              // will write store_j to s[i] at next clk cycle

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `SWAPPED: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         i;             // s[i] <-> s[j], store_i = s[i], store_j = s[j]
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      ((store_i + store_j) % 256);    // index created
                
                rdy =            1'b0;           
            end

            `ADDR_MATH: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         math;   // s_addr will be at math by next clk cycle
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      ((store_i + store_j) % 256);
                
                rdy =            1'b0;           
            end

            `BUFFER_4: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         math;   // s_addr is at math
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      ((store_i + store_j) % 256);
                
                rdy =            1'b0;           
            end

            `ADDR_K: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         math;   // s_rddata =  s[math]
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b1;                      // store_math = s[math] by next clk cycle
                math =      ((store_i + store_j) % 256);
                
                rdy =            1'b0;           
            end

            `COPY_MATH: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         k;                         // change s_addr by next clk cycle
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        k;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;                      // store_math = s[math]
                math =      ((store_i + store_j) % 256);
                
                rdy =            1'b0;           
            end

            `BUFFER_5: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         k;                         // s_addr is at k
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        k;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      ((store_i + store_j) % 256);
                
                rdy =            1'b0;           
            end

            `GET_PAD: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         k;                         // s_rddata = s[k]
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;                      // will write store[math] to s[k] by next clk cycle

                ct_addr =        8'b00000000;

                pt_addr =        k;
                pt_wrdata =      store_math;
                pt_wren =        1'b1;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      ((store_i + store_j) % 256);
                
                rdy =            1'b0;           
            end

            `SET_LOAD_K_1: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b1;                      // k will increment by next clk cycle
                load_k_1 =       1'b0;

                s_addr =         k;
                s_wrdata =       store_math;
                s_wren =         1'b0;                      // s [k] is now store_math --> s[k] is now pad[k]

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      ((store_i + store_j) % 256);
                
                rdy =            1'b0;           
            end

            `INCREMENT_1: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;                      // k has incremented
                load_k_1 =       1'b0;

                s_addr =         k;
                s_wrdata =       store_math;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      ((store_i + store_j) % 256);
                
                rdy =            1'b0;           
            end

            `SWITCH: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b1;              // set k back to 1 for next for loop

                s_addr =         k;
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      message_length;    // pt_addr = 0 in CHECK_1
                pt_wren =        1'b1;              // pt[0] will be message_length at next clk cycle
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `CHECK_2: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;              // k is now 1,...,message_length

                s_addr =         k;                 // will be at k at next clk cycle
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        k;                 // will be at k at next clk cycle

                pt_addr =        k;                 // will be at k at next clk cycle
                pt_wrdata =      message_length;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `BUFFER_6: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         k;                 // s_addr is at k
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        k;                 // ct_addr is at k

                pt_addr =        k;                 // pt_addr is at k
                pt_wrdata =      message_length;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `BUFFER_7: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         k;                 // s_rddata = s[k]
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        k;                 // ct_rddata = ct[k]

                pt_addr =        k;                 // pt_rddata = pt[k]
                pt_wrdata =      message_length;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `XOR_PT: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         k;                 // s_rddata = s[k]
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        k;                 // ct_rddata = ct[k]

                pt_addr =        k;                 // pt_rddata = pt[k]
                pt_wrdata =      pt_rddata ^ ct_rddata;                      // XOR
                pt_wren =        1'b1;              // update by the next clk cycle
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `SET_LOAD_K_2: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b1;              // k will increment by next clk cycle
                load_k_1 =       1'b0;

                s_addr =         k;
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        k;

                pt_addr =        k;
                pt_wrdata =      s_rddata ^ ct_rddata;
                pt_wren =        1'b0;              // XOR'ed
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `INCREMNET_2: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;              // k has incremented
                load_k_1 =       1'b0;

                s_addr =         k;
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        k;

                pt_addr =        k;
                pt_wrdata =      s_rddata ^ ct_rddata;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b0;           
            end

            `DONE_PRGA: begin
                load_i =         1'b0;
                load_j =         1'b0;
                load_k_inc =     1'b0;
                load_k_1 =       1'b0;

                s_addr =         8'b00000000;
                s_wrdata =       8'b00000000;
                s_wren =         1'b0;

                ct_addr =        8'b00000000;

                pt_addr =        8'b00000000;
                pt_wrdata =      8'b00000000;
                pt_wren =        1'b0;
                
                load_store_i =   1'b0;
                load_store_j =   1'b0;
                load_math =      1'b0;
                math =      8'b00000000;
                
                rdy =            1'b1;           
            end

            default: begin
                load_i =         1'bx;
                load_j =         1'bx;
                load_k_inc =     1'bx;
                load_k_1 =       1'bx;

                s_addr =         8'bxxxxxxxx;
                s_wrdata =       8'bxxxxxxxx;
                s_wren =         1'bx;

                ct_addr =        8'bxxxxxxxx;

                pt_addr =        8'bxxxxxxxx;
                pt_wrdata =      8'bxxxxxxxx;
                pt_wren =        1'bx;
                
                load_store_i =   1'bx;
                load_store_j =   1'bx;
                load_math =      1'bx;
                math =      8'bxxxxxxxx;
                
                rdy =            1'bx;           
            end

            endcase
    end
endmodule