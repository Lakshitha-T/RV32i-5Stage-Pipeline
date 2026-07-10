`timescale 1ns/1ps

module CPU_tb;
    logic clk;
    logic rst;

    SingleCycleCPU inst1(
        .clk(clk),
        .rst(rst)
    );

    //Clock
    always #5 clk = ~clk;

    initial
        begin
            $dumpfile("CPU_waves.vcd");
            $dumpvars(0, CPU_tb);


            // Initial Conditions
            clk = 0;
            rst = 1;
            #12;

            rst = 0;

            // To execute the instructions in program.mem
            #100;

            $finish;

        end
endmodule


// Current instructions are
// 00400093 - addi x1,x0,4
// 01F22223 - sw x31, 4(x4)
//00A48533 - add x10, x9, x10
// 00000063 - beq x0, x0, 0


