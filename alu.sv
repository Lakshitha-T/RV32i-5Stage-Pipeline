module ALU(
    input logic [31:0]A,
    input logic [31:0]B,
    input logic [3:0]   ALUControl,
    output logic [31:0] ALUResult,
    output logic Zero
);
    assign Zero = (A==B);
    always_comb 
        begin
            case(ALUControl)
                4'b0000: ALUResult = A & B;                                    // AND
                4'b0001: ALUResult = A | B;                                    // OR
                4'b0010: ALUResult = A + B;                                    // ADD
                4'b0011: ALUResult = A << B[4:0];                              // SLL
                4'b0100: ALUResult = A ^ B;                                    // XOR
                4'b0101: ALUResult = A >> B[4:0];                              // SRL
                4'b0110: ALUResult = A - B;                                    // SUB
                4'b0111: ALUResult = (A < B) ? 32'b1 : 32'b0;                  // SLTU
                4'b1000: ALUResult = ($signed(A) < $signed(B)) ? 32'b1:32'b0;  // SLT
                4'b1001: ALUResult = $signed(A) >>> B[4:0];                    // SRA
                default: ALUResult = 32'b0;
            endcase
        end
endmodule
