module ControlUnit(
    input logic [6:0] Op,
    input logic [2:0] Funct3,
    input logic Funct7b5,
    output logic RegWrite,
    output logic [2:0] ImmSrc,
    output logic ALUSrc,
    output logic MemWrite,
    output logic [1:0] ResultSrc,
    output logic Branch,
    output logic Jump,
    output logic JALR,
    output logic LUI,
    output logic AUIPC,
    output logic [3:0] ALUControl
);

    logic [1:0] ALUOp;

    always_comb
        begin
            // Safe defaults
            RegWrite  = 1'b0;
            ImmSrc    = 3'b000;
            ALUSrc    = 1'b0;
            MemWrite  = 1'b0;
            ResultSrc = 2'b00;
            Branch    = 1'b0;
            Jump      = 1'b0;
            JALR      = 1'b0;
            LUI       = 1'b0;
            AUIPC     = 1'b0;
            ALUOp     = 2'b00;

            case(Op)
                7'b0110011: // R-type
                    begin
                        RegWrite = 1'b1;
                        ALUOp    = 2'b10;
                    end

                7'b0010011: // I-type (addi, slli, slti, ...)
                    begin
                        RegWrite = 1'b1;
                        ALUSrc   = 1'b1;
                        ALUOp    = 2'b10;
                    end

                7'b0000011: // lw
                    begin
                        RegWrite  = 1'b1;
                        ALUSrc    = 1'b1;
                        ResultSrc = 2'b01;
                        ALUOp     = 2'b00;
                    end

                7'b0100011: // sw
                    begin
                        ImmSrc   = 3'b001;
                        ALUSrc   = 1'b1;
                        MemWrite = 1'b1;
                        ALUOp    = 2'b00;
                    end

                7'b1100011: // beq/bne/blt/bge/bltu/bgeu
                    begin
                        ImmSrc = 3'b010;
                        Branch = 1'b1;
                        ALUOp  = 2'b01;
                    end

                7'b0110111: // lui
                    begin
                        RegWrite = 1'b1;
                        ImmSrc   = 3'b011;
                        LUI      = 1'b1;
                    end

                7'b0010111: // auipc
                    begin
                        RegWrite = 1'b1;
                        ImmSrc   = 3'b011;
                        AUIPC    = 1'b1;
                    end

                7'b1101111: // jal
                    begin
                        RegWrite = 1'b1;
                        ImmSrc   = 3'b100;
                        Jump     = 1'b1;
                    end

                7'b1100111: // jalr
                    begin
                        RegWrite = 1'b1;
                        ImmSrc   = 3'b000;
                        ALUSrc   = 1'b1;
                        ALUOp    = 2'b00;   // forces ADD -> rs1 + imm
                        Jump     = 1'b1;
                        JALR     = 1'b1;
                    end

                default: ; // NOP / unknown - defaults already safe
            endcase
        end


    always_comb
        begin
            case(ALUOp)
                2'b00: ALUControl = 4'b0010;    // Load/Store/JALR - ADD

                2'b01:                          // Branch - depends on Funct3
                    begin
                        case(Funct3)
                            3'b100: ALUControl = 4'b1000;  // blt  -> SLT
                            3'b101: ALUControl = 4'b1000;  // bge  -> SLT (inverted at use site)
                            3'b110: ALUControl = 4'b0111;  // bltu -> SLTU
                            3'b111: ALUControl = 4'b0111;  // bgeu -> SLTU (inverted at use site)
                            default: ALUControl = 4'b0110; // beq/bne -> SUB (Zero flag used)
                        endcase
                    end

                2'b10:                          // R-type / I-type - check Funct3
                    begin
                        case(Funct3)
                            3'b000:
                                begin
                                    if((Op == 7'b0110011) && Funct7b5)
                                        ALUControl = 4'b0110;   // SUB
                                    else
                                        ALUControl = 4'b0010;   // ADD / ADDI
                                end
                            3'b001: ALUControl = 4'b0011;        // SLL / SLLI
                            3'b010: ALUControl = 4'b1000;        // SLT / SLTI
                            3'b011: ALUControl = 4'b0111;        // SLTU / SLTIU
                            3'b100: ALUControl = 4'b0100;        // XOR / XORI
                            3'b101:
                                begin
                                    if(Funct7b5)
                                        ALUControl = 4'b1001;    // SRA / SRAI
                                    else
                                        ALUControl = 4'b0101;    // SRL / SRLI
                                end
                            3'b110: ALUControl = 4'b0001;        // OR / ORI
                            3'b111: ALUControl = 4'b0000;        // AND / ANDI
                            default: ALUControl = 4'b0010;
                        endcase
                    end

                default: ALUControl = 4'b0010;
            endcase
        end

endmodule
