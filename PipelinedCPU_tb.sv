`timescale 1ns/1ps

module PipelinedCPU_tb;
    logic clk;
    logic rst;

    PipelinedCPU inst1(
        .clk(clk),
        .rst(rst)
    );

    // Clock Generation (100MHz)
    always #5 clk = ~clk;

    // Safety Pre-initialization and Code Loading
    initial begin
        // Explicitly clear instruction memory array to avoid uninitialized 'x' states
        for(int i = 0; i < 64; i = i + 1) begin
            inst1.imem_instance.mem[i] = 32'h00000013; // Safe NOP pre-fill
        end
        
        // Load your real program machine code file over the NOPs
        $readmemh("program.mem", inst1.imem_instance.mem);
    end

    // Simulation Control Block
    initial begin
        $dumpfile("CPU_waves.vcd");
        $dumpvars(0, PipelinedCPU_tb);

        // Initial Conditions
        clk = 0;
        rst = 1;
        #12; // Release reset right after the first clock edge

        rst = 0;

        // Give the pipeline 100ns to execute instructions
    #150;

        $finish;
    end
endmodule