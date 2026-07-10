`timescale 1ns/1ps

module DataMemory_tb;
    logic clk;
    logic MemWrite;
    logic [31:0] A;
    logic [31:0] WD;
    logic [31:0] RD;


    //Instantiate Data Memory
    DataMemory inst_1(
        .clk(clk),
        .MemWrite(MemWrite),
        .A(A),
        .WD(WD),
        .RD(RD)
    );

    //Clock generator
    always #5 clk = ~clk;

    initial
        begin
            $dumpfile("DataMemory_waves.vcd");
            $dumpvars(0, DataMemory_tb);

            //Initialize signals
            clk = 0;
            MemWrite = 0;
            A = 32'b0;
            WD = 32'b0;
            #10;

            //Test case 1: 0xABCDEFGH
            A = 32'd12;
            WD = 32'hABCDEFAB;
            MemWrite = 1;
            #10;

            //Test Case 2: Read mode
            MemWrite = 0;
            WD = 32'h00000000;
            #10;

            // Test Case 3: Trying to read another address
            A = 32'd0;
            #10;

            //Test Case 4: Trying to read the same register again to get the prev data
            A = 32'd12;
            #10;

            $finish;
        end
endmodule
