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
                4'b0000: ALUResult = A & B;
                4'b0001: ALUResult = A | B;
                4'b0010: ALUResult = A + B;
                4'b0100: ALUResult = A ^ B;
                4'b0110: ALUResult = A - B;
                4'b0111: ALUResult = (A<B)? 32'b1: 32'b0;
                default: ALUResult = 32'b0;
            endcase
                
        end

        
endmodule
