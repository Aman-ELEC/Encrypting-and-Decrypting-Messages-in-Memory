// defining the states (encoding)
`define WAIT              2'b00
`define SET_LOAD          2'b01
`define INCREMENT         2'b10
`define DONE              2'b11

module init(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            output logic [7:0] addr, output logic [7:0] wrdata, output logic wren);

// your code here

// !!! NEED TO FIGURE OUT 'en' WIRE !!!

logic [1:0] state; // output of mooremachine, input to combinational
logic [7:0] i;
logic load;        // load for i

// instanting modules

// counter for i incrementation
    counter c(clk, rst_n, i, load);

// mooremachine part of the statemachine -> for the state transitions 
    statemachine_mooremachine mooremachine(clk, state, i, en);

// combinational logic for statemachine
    statemachine_combinational combinational(state, load,
                                            rdy,
                                            addr, wrdata, wren, i);

endmodule: init

module counter(input logic clk, input logic rst_n,             // register module
            output logic [7:0] i, input logic load);

            always_ff @(posedge clk) begin
            if (rst_n == 1'b1)
                i <= 8'b00000000;
            else if (load == 1'b1)
                i <= i + 8'b00000001;
            else
                i <= i;
        end

endmodule


module statemachine_mooremachine(input logic clk,
                                output logic [1:0] state, input logic [7:0] i,
                                input logic en);

    // wire declarations
    logic [1:0] present_state; // hold present state to check for next state

    always @(posedge clk) begin

        // 'for loop' should only run when 'en' is enabled. 
        // 'en' is set to HIGH from outside module only if the module sees that 'rdy' is HIGH
        // how to implement 'en' with the reset ?? -> if (rst_n == 0 && en = 1'b1)
        if (en == 1'b0) begin // if (rst_n == 1) begin
            present_state = `WAIT;
        end else begin
            case(present_state)

                `WAIT: present_state = `SET_LOAD;

                // `INCREMENT_ODD: if (i < 8'b11111111)
                //     present_state = `INCREMENT_EVEN; // go here to stay in for loop
                //     else
                //     present_state = `DONE; // Go here to finish for loop
                
                // `INCREMENT_EVEN: present_state = `INCREMENT_ODD;

                `SET_LOAD: present_state = `INCREMENT;

                `INCREMENT: if (i == 8'b11111111) begin
                    present_state = `DONE; // go here to stay in for loop
                    end
                    else begin
                    present_state = `INCREMENT; // Go here to finish for loop
                    end

                `DONE: present_state = `DONE;

                                
                default: present_state = 2'bxx;

            endcase           
    
        end

        state = present_state; // update the output wire 

    end

endmodule

module statemachine_combinational(input logic [1:0] state, output logic load,
                                output logic rdy,
                                output logic [7:0] addr, output logic [7:0] wrdata, output logic wren,
                                input logic [7:0] i);

    // here we check for what state we are in to output corresponding output value
    
    always @(state or i) begin
        
        case(state)

        `WAIT: begin
            load = 1'b0;            // at WAIT, en = 1 --> i is 0 // keep load at 0 to not increment
            addr = 8'b00000000;
            wrdata = 8'b00000000;
            wren = 1'b0;
            rdy = 1'b0;           
        end

        `SET_LOAD: begin
            load = 1'b1;            // load = 1 --> i will increment in next clk cycle/state
            addr = i;
            wrdata = i;
            wren = 1'b1;
            rdy = 1'b0;     
        end        

        `INCREMENT: begin
            load = 1'b1;
            addr = i;
            wrdata = i;
            wren = 1'b1;
            rdy = 1'b0;     
        end     

        `DONE: begin
            load = 1'b0;
            addr = 8'b00000000;
            wrdata = 8'b00000000;
            wren = 1'b0;
            rdy = 1'b1;      
        end

        default: begin
            load = 1'bx; 
            addr = 8'bxxxxxxxx;
            wrdata = 8'bxxxxxxxx;
            wren = 1'bx;
            rdy = 1'bx;  
        
        end

        endcase   

    end

endmodule