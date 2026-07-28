// Starting pipelining from here
// From IF to ID stage, the Instruction and PC values need to pass on
// Instruction - The decoder reads it in the next cycle
// PC - Branch target calculations need the original instruction address
//
// FIX (speculative fetch): `predicted_taken` now rides through this register
// alongside the instruction it belongs to. Previously the live IF-stage
// `predicted_taken` combinational signal was wired straight into ID_EX_reg's
// ID_predicted_taken input, bypassing this register entirely — so by the
// time an instruction reached EX, the "prediction" tagging along with it was
// actually whatever the predictor happened to say for whatever PC was being
// fetched *that* cycle, not the prediction IF actually used two cycles
// earlier to fetch this instruction. That stage-misalignment silently broke
// misprediction detection (BP_mispredicted) once BP_mispredicted started
// gating real flush/recovery decisions.

module IF_ID_reg (
    input logic clk,
    input logic rst,
    input logic stall,                     // Retains the current instruction
    input logic flush,                      // Clears the instruction on a taken branch
    input logic [31:0] IF_PC,
    input logic [31:0] IF_Instruction,
    input logic IF_predicted_taken,         // NEW: prediction IF used to fetch IF_Instruction
    output logic [31:0] ID_PC,
    output logic [31:0] ID_Instruction,
    output logic ID_predicted_taken         // NEW
);

always_ff @(posedge clk or posedge rst)
        begin
            if(rst)
                begin
                    ID_PC <= 32'b0;
                    ID_Instruction <= 32'h00000013;        // Default to NOP ( addi x0,x0,0)
                    ID_predicted_taken <= 1'b0;
                end
            else if (flush)
                begin
                    ID_PC <= 32'b0;
                    ID_Instruction <= 32'h00000013;     // Flush to NOP
                    ID_predicted_taken <= 1'b0;
                end
            else if (!stall)                            // Only go forward if not stalling. If stalling, retains the old data because it's a flip flop.
                begin
                    ID_PC <= IF_PC;
                    ID_Instruction <= IF_Instruction;
                    ID_predicted_taken <= IF_predicted_taken;
                end
        end
endmodule
