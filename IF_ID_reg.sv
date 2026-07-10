// Starting pipelining from here
// From IF to ID stage, the Instruction and PC values need to pass on
// Instruction - The decoder reads it in the next cycle
// PC - Branch target calculations need the original instruction address

module IF_ID_reg (
    input logic clk,
    input logic rst,
    input logic stall,                     // Retains the current instruction
    input logic flush,                      // Clears the instruction on a taken branch
    input logic [31:0] IF_PC,
    input logic [31:0] IF_Instruction,
    output logic [31:0] ID_PC,
    output logic [31:0] ID_Instruction
);

always_ff @(posedge clk or posedge rst)
        begin
            if(rst)
                begin
                    ID_PC <= 32'b0;
                    ID_Instruction <=32'h00000013;        // Default to NOP ( addi x0,x0,0)
                end
            else if (flush)
                begin
                    ID_PC <= 32'b0;
                    ID_Instruction <= 32'h00000013;     // Flush to NOP
                end
            else if (!stall)                            // Only go forward if not stalling. If stalling, retains the old data because it's a flip flop.
                begin
                    ID_PC <= IF_PC;
                    ID_Instruction <= IF_Instruction;
                end
        end
endmodule

//Modified SingleCycleCPU.sv after this to include and keep track of the IF and ID variables