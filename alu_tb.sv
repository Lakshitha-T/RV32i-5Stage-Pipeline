`timescale 1ns/1ps

module ALU_tb;
    logic [31:0] A;
    logic [31:0] B;
    logic [3:0] ALUControl;
    logic [31:0] ALUResult;
    logic Zero;

    // Instantiating the ALU
    ALU inst_1(.A(A),
               .B(B),
               .ALUControl(ALUControl),
               .ALUResult(ALUResult),
               .Zero(Zero)
    );

    initial begin
        $dumpfile("ALU_waves.vcd");
        $dumpvars(0,ALU_tb);


        //Test case 1: ADD
        A = 32'd15; B = 32'd10; ALUControl = 4'b0010;
        #10;

        //Test case 2: SUB
        A = 32'd15; B = 32'd10; ALUControl = 4'b0110;
        #10;

        //Test case 3: AND
        A = 32'd15; B = 32'd10; ALUControl = 4'b0000;
        #10;

        //Test case 4: OR
        A = 32'd15; B = 32'd10; ALUControl = 4'b0001;
        #10;

        //Test case 5: SLT
        A = 32'd15; B = 32'd10; ALUControl = 4'b0111;
        #10;

        //Test case 6: defaule
        A = 32'd15; B = 32'd10; ALUControl = 4'b0111;
        #10;

        $finish;
    end

endmodule