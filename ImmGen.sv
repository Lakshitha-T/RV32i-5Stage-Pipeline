module ImmGen(
    input logic [31:0] instr,           // The 32 bit instruction machine code
    input logic [2:0] ImmSrc,           // Control signal deciding the instruction type
    output logic[31:0] imm_ext          // The sign extended 32 bit constant output
);

//Each instruction type has a different location of the immediate value
    always@(*)
        begin
            case(ImmSrc)
                
                //I type (add, addi, lw) - 12 bits at the top
                3'b000: imm_ext = {{20{instr[31]}}, instr[31:20]};

                //S type (sw) - split across bits[31:25] and [11:7]
                3'b001: imm_ext = { {20{instr[31]}}, instr[31:25], instr[11:7]};

                //B type (beq)
                3'b010: imm_ext = { {19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

                //U type (lui)
                3'b011: imm_ext = { instr[31:12], 12'b0};

                //J type (jal, jalr)
                3'b100: imm_ext = { {11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

                default: imm_ext = 32'b0;

            endcase
        end

endmodule

