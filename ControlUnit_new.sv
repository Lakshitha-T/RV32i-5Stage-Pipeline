// The control unit - takes the 32 bit instruction and identifies specific fields
// Main decoder  - looks at opcode, sets RegWrite, MemWrite, ALUSrc, ResultSrc, Branch, ALUOp
// ALU decoder   - takes ALUOp + Funct3 + Funct7b5, produces 4-bit ALUControl

module ControlUnit(
    input logic [6:0] Op,               // Instruction bits [6:0]
    input logic [2:0] Funct3,           // Differentiates add/sub/addi vs or vs and
    input logic Funct7b5,               // Instruction bit 30 (differentiates add and sub)
    output logic RegWrite,              // Enables writing to regfile
    output logic [2:0] ImmSrc,          // Controls immediate generator extension type
    output logic ALUSrc,                // ALU second input: 0 = register, 1 = ImmGen
    output logic MemWrite,              // Enables writing to data memory
    output logic [1:0] ResultSrc,       // Selects the register writeback source
    output logic Branch,                // For branch instructions
    output logic [3:0] ALUControl       // 4-bit code to ALU
);

    logic [1:0] ALUOp;

    // ----------------------------------------------------------------
    // 1. MAIN DECODER
    // ----------------------------------------------------------------
    always_comb
        begin
            // Safe defaults
            RegWrite  = 1'b0;
            ImmSrc    = 3'b000;
            ALUSrc    = 1'b0;
            MemWrite  = 1'b0;
            ResultSrc = 2'b00;
            Branch    = 1'b0;
            ALUOp     = 2'b00;

            case(Op)
                7'b0110011: // R-type
                    begin
                        RegWrite  = 1'b1;
                        ImmSrc    = 3'b000;   // unused for R-type
                        ALUSrc    = 1'b0;
                        MemWrite  = 1'b0;
                        ResultSrc = 2'b00;
                        Branch    = 1'b0;
                        ALUOp     = 2'b10;
                    end

                7'b0010011: // I-type (addi, etc.)
                    begin
                        RegWrite  = 1'b1;
                        ImmSrc    = 3'b000;
                        ALUSrc    = 1'b1;
                        MemWrite  = 1'b0;
                        ResultSrc = 2'b00;
                        Branch    = 1'b0;
                        ALUOp     = 2'b10;
                    end

                7'b0000011: // lw
                    begin
                        RegWrite  = 1'b1;
                        ImmSrc    = 3'b000;
                        ALUSrc    = 1'b1;
                        MemWrite  = 1'b0;
                        ResultSrc = 2'b01;
                        Branch    = 1'b0;
                        ALUOp     = 2'b00;
                    end

                7'b0100011: // sw
                    begin
                        RegWrite  = 1'b0;
                        ImmSrc    = 3'b001;
                        ALUSrc    = 1'b1;
                        MemWrite  = 1'b1;
                        ResultSrc = 2'b00;  // FIX: was 2'bxx - X propagates into pipeline regs
                        Branch    = 1'b0;
                        ALUOp     = 2'b00;
                    end

                7'b1100011: // beq/bne
                    begin
                        RegWrite  = 1'b0;
                        ImmSrc    = 3'b010;
                        ALUSrc    = 1'b0;
                        MemWrite  = 1'b0;
                        ResultSrc = 2'b00;  // FIX: was 2'bxx - X propagates into pipeline regs
                        Branch    = 1'b1;
                        ALUOp     = 2'b01;
                    end

                default:    // NOP / unknown
                    begin
                        RegWrite  = 1'b0;
                        ImmSrc    = 3'b000;
                        ALUSrc    = 1'b0;
                        MemWrite  = 1'b0;
                        ResultSrc = 2'b00;
                        Branch    = 1'b0;
                        ALUOp     = 2'b00;
                        // FIX: removed "ALUControl = 4'b0000" here - ALUControl is
                        // driven solely by the ALU decoder below; driving it from
                        // two always_comb blocks creates a multiple-driver conflict.
                    end
            endcase
        end


    // ----------------------------------------------------------------
    // 2. ALU DECODER
    // ----------------------------------------------------------------
    always_comb
        begin
            case(ALUOp)
                2'b00: ALUControl = 4'b0010;    // Load/Store - ADD

                2'b01: ALUControl = 4'b0110;    // Branch - SUB (for comparison)

                2'b10:                          // R-type / I-type - check Funct3
                    begin
                        case(Funct3)
                            3'b000:
                                begin
                                    if((Op == 7'b0110011) && Funct7b5)
                                        ALUControl = 4'b0110; // FIX: was 3'b110 (3-bit on 4-bit wire)
                                    else
                                        ALUControl = 4'b0010; // FIX: was 3'b010
                                end
                            3'b110: ALUControl = 4'b0001;     // FIX: was 3'b001 - OR
                            3'b111: ALUControl = 4'b0000;     // FIX: was 3'b000 - AND
                            default: ALUControl = 4'b0010;    // Fallback ADD
                        endcase
                    end

                default: ALUControl = 4'b0010;
            endcase
        end

endmodule
