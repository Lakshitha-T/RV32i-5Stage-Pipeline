`timescale 1ns/1ps

module ControlUnit_tb;
    logic [6:0] Op;
    logic [2:0] Funct3;
    logic Funct7b5;
    logic RegWrite;
    logic [2:0] ImmSrc;
    logic ALUSrc;
    logic MemWrite;
    logic [1:0] ResultSrc;
    logic Branch;
    logic [2:0]ALUControl;

    // Instantiating Control Unit
    ControlUnit inst_1 (.Funct7b5(Funct7b5),
                        .Op(Op),
                        .Funct3(Funct3),
                        .RegWrite(RegWrite),
                        .ImmSrc(ImmSrc),
                        .ALUSrc(ALUSrc),
                        .MemWrite(MemWrite),
                        .ResultSrc(ResultSrc),
                        .Branch(Branch),
                        .ALUControl(ALUControl)    
    );

    initial begin
        $dumpfile("ControlUnit_waves.vcd");
        $dumpvars(0,ControlUnit_tb);

        // Test 1: R type Add
        Op = 7'b0110011;
        Funct3 = 3'b000;
        Funct7b5 = 1'b0;
        #10;

        // Test 2: R type Sub
        Op = 7'b0110011;
        Funct3 = 3'b000;
        Funct7b5 = 1'b1;
        #10;

        //Test 3: I type Addi
        Op = 7'b0010011;
        Funct3 = 3'b000;
        Funct7b5 = 1'b0;
        #10;

        // Test 4: sw
        Op = 7'b0100011;
        Funct3 = 3'b010;
        Funct7b5 = 1'b0;
        #10;

        //Test 5: beq
        Op = 7'b1100011;
        Funct3 = 3'b000;
        Funct7b5 = 1'b0;
        #10;

        $finish;
    end
endmodule


