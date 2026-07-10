`timescale 1ns/1ps

module ImmGen_tb;
    logic [31:0] instr;
    logic [2:0] ImmSrc;
    logic [31:0] imm_ext;

    //Instantiate the immediate generator
    ImmGen inst_1(
            .instr(instr),
            .ImmSrc(ImmSrc),
            .imm_ext(imm_ext)
    );

    initial
        begin
            $dumpfile("Immgen_waves.vcd");
            $dumpvars(0,ImmGen_tb);


            //Test Case 1: Decoding and I type instruction
            instr = 32'h00400093;
            ImmSrc = 3'b000;
            #10;


            //Test Case 1: Decoding and S type instruction
            instr = 32'h01f22023;
            ImmSrc = 3'b001;
            #10;

            $finish;
        end
endmodule


            
            