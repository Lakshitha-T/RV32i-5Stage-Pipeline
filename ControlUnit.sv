// The control unit - takes the 32 bit instructions and identifies the specific fields - opcode, funct3, funct7
// Flips the MUXs, Write enables and ALU operation wires everything
// Main decoder - looks only at the opcode - Identifies the type fo instruction (R, I, S, B) - Flips regwrite, memwrite, ALUsrc
// ALU Decoder - Takes ALUop and checks the funct3 and funct7 - determine the type of instruction

module ControlUnit(
    input logic [6:0] Op,               // Instruction bits [6:0]
    input logic [2:0] Funct3,           // For (add,sub,addi) vs or vs and
    input logic Funct7b5,               // Instruction bit 30 ( to differentiate add and sub)
    output logic RegWrite,              // Enables writing to regfile
    output logic [2:0] ImmSrc,          // Controls immediate generator extension type 
    output logic ALUSrc,                // ALU second input selection: 0 - register, 1 - ImmGen
    output logic MemWrite,              // Enables writing to data memory
    output logic [1:0] ResultSrc,       // Selects the register write back source
    output logic Branch,                // For branch instructions
    output logic [3:0] ALUControl       // 4 bit code to ALU
);

    logic [1:0] ALUOp;

    // 1. MAIN DECODER BLOCK

    always_comb
            begin
                //Setting default values
                RegWrite = 1'b0;
                ImmSrc = 3'b000;
                ALUSrc = 1'b0;
                MemWrite = 1'b0;
                ResultSrc = 2'b00;
                Branch = 1'b0;
                ALUOp = 2'b00;

                case(Op)
                    7'b0110011: // R type
                        begin
                            RegWrite = 1'b1;
                            ImmSrc = 3'bxxx;
                            ALUSrc = 1'b0;
                            MemWrite = 1'b0;
                            ResultSrc = 2'b00;
                            Branch = 1'b0;
                            ALUOp = 2'b10;
                        end
                    
                    7'b0010011: // I type
                        begin
                            RegWrite = 1'b1;
                            ImmSrc = 3'b000;
                            ALUSrc = 1'b1;
                            MemWrite = 1'b0;
                            ResultSrc = 2'b00;
                            Branch = 1'b0;
                            ALUOp = 2'b10;
                        end

                    7'b0000011: // lw
                        begin
                            RegWrite = 1'b1;
                            ImmSrc = 3'b000;
                            ALUSrc = 1'b1;
                            MemWrite = 1'b0;
                            ResultSrc = 2'b01;
                            Branch = 1'b0;
                            ALUOp = 2'b00;
                        end
                    
                    7'b0100011: //sw
                        begin
                            RegWrite = 1'b0;
                            ImmSrc = 3'b001;
                            ALUSrc = 1'b1;
                            MemWrite = 1'b1;
                            ResultSrc = 2'bxx;
                            Branch = 1'b0;
                            ALUOp = 2'b00;
                        end

                    7'b1100011: //beq
                        begin
                            RegWrite = 1'b0;
                            ImmSrc = 3'b010;
                            ALUSrc = 1'b0;
                            MemWrite = 1'b0;
                            ResultSrc = 2'bxx;
                            Branch = 1'b1;
                            ALUOp = 2'b01;
                        end
                    
                    default:
                        begin
                            RegWrite = 1'b0;
                            ImmSrc = 3'b000;
                            ALUSrc = 1'b0;
                            MemWrite = 1'b0;
                            ResultSrc = 2'b00;
                            Branch = 1'b0;
                            ALUControl = 4'b0000;
                        end
                endcase
            end



    // 2. ALU Decoder Block

    always_comb
        begin
            case(ALUOp)
                2'b00: ALUControl = 4'b0010; // Laoad/Store - add
                2'b01: ALUControl = 4'b0110; // Branches - subtract
                2'b10:
                    begin
                        case(Funct3)
                            3'b000:
                                begin
                                    if((Op == 7'b0110011) && Funct7b5)
                                        ALUControl = 3'b110; //Sub
                                    else
                                        ALUControl = 3'b010; //Add, Addi
                                end
                            3'b110: ALUControl = 3'b001; //OR
                            3'b111: ALUControl = 3'b000; //AND
                            default: ALUControl = 3'b010; //Default fallback to add
                        endcase
                    end
                    default: ALUControl = 4'b0010;
            endcase
        end
endmodule


                    
                    
                            
