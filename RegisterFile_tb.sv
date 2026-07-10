`timescale 1ns/1ps
module RegisterFile_tb;
    logic clk;
    logic RegWrite;
    logic [4:0] ReadAddr1;
    logic [4:0] ReadAddr2;
    logic [4:0] WriteAddr;
    logic [31:0] WriteData;
    logic [31:0] ReadData1;
    logic [31:0] ReadData2;

    //Instantiating the Register File
    RegisterFile inst_1(
            .clk(clk),
            .RegWrite(RegWrite),
            .ReadAddr1(ReadAddr1),
            .ReadAddr2(ReadAddr2),
            .WriteAddr(WriteAddr),
            .WriteData(WriteData),
            .ReadData1(ReadData1),
            .ReadData2(ReadData2)
    );

    // Clock Generator - Time Period = 10ns
    always #5 clk = ~clk;

    initial
        begin
            $dumpfile("RegisterFile_waves.vcd");
            $dumpvars(0, RegisterFile_tb);

            //Initialize everything to 0
            clk = 0;
            RegWrite = 0;
            ReadAddr1 = 0;
            ReadAddr2 = 0;
            WriteAddr = 0;
            WriteData = 0;
            #10;

            //Test Case 1: Write 32'hAAAA_BBBB into Register 5
            RegWrite = 1;
            WriteAddr = 5;
            WriteData = 32'hAAAA_BBBB;
            #10;

            //Test Case 2: Write 32'h1234_5678 into Register 10
            WriteAddr = 10;
            WriteData = 32'h12345678;
            #10;

            //Test Case 3: Turn off writing and try to read Reg 5 and Reg 10
            RegWrite = 0;
            ReadAddr1 = 5'd5;
            ReadAddr2 = 5'd10;
            #10;

            //Try to write to register 0 (Should be blocked)
            RegWrite = 1;
            WriteAddr = 5'd0;
            WriteData = 32'hFFFFFFF;
            #10;

            //Test case 5: Read Register 0 to prove it stayed 0
            RegWrite = 0;
            ReadAddr1 = 5'd0;
            #10;

            $finish;
        end
endmodule

    




