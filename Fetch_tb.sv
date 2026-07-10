//To test the PC and Instruction Memory together
//Testing out PCNext = PC + 32'd4

`timescale 1ns/1ps

module Fetch_tb;

    //Declaring the signals 

    logic clk;
    logic rst;
    logic [31:0] PCNext;            // The address of the next instruction
    logic [31:0] PCResult;          // The current instruction address
    logic [31:0] Instruction;

    assign PCNext = PCResult + 32'd4;

    // Instantiating the Program Counter
    PC inst_1(
        .clk(clk),
        .rst(rst),
        .PCNext(PCNext),
        .PCResult(PCResult)
    );

    // Instantiating the Instruction Memory
    InstructionMemory inst_2(
        .A(PCResult),
        .RD(Instruction)
    );

    //Generating the clock
    always #5 clk = ~clk;

    initial
        begin
            $dumpfile("Fetch_waves.vcd");
            $dumpvars(0,Fetch_tb);

            // Initializing
            clk = 0;
            rst = 1;
            #12;        // In reset state for 12 seconds

            rst = 0;    // Needs to fetch the 4 instructions
            #40         // Giving it 4 clock cycles

            $finish;
            end
endmodule
