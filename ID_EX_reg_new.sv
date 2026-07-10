module ID_EX_reg(
    input logic clk,
    input logic rst,
    input logic flush,                  // Clears the decoded signal in case we need to stall or bubble

    // Data Inputs from ID
    input logic [31:0] ID_PC,
    input logic [31:0] ID_ReadData1,
    input logic [31:0] ID_ReadData2,
    input logic [31:0] ID_ImmExt,
    input logic [4:0] ID_WriteAddr,
    input logic [2:0] ID_Funct3,
    input logic [4:0] ID_Rs1,           // Hazard detection
    input logic [4:0] ID_Rs2,           // Hazard detection

    // Control Inputs from ID
    input logic [3:0] ID_ALUControl,
    input logic ID_ALUSrc,
    input logic ID_Branch,
    input logic ID_MemWrite,
    input logic ID_RegWrite,
    input logic [1:0] ID_ResultSrc,

    // Data outputs to EX stage
    output logic [31:0] EX_PC,
    output logic [31:0] EX_ReadData1,
    output logic [31:0] EX_ReadData2,
    output logic [31:0] EX_ImmExt,
    output logic [4:0] EX_WriteAddr,
    output logic [2:0] EX_Funct3,
    output logic [4:0] EX_Rs1,      // Hazard detection
    output logic [4:0] EX_Rs2,      // Hazard detection

    // Control outputs to EX
    output logic [3:0] EX_ALUControl,
    output logic EX_ALUSrc,
    output logic EX_Branch,
    output logic EX_MemWrite,
    output logic EX_RegWrite,
    output logic [1:0] EX_ResultSrc
);

always_ff @(posedge clk or posedge rst)
        begin
            if(rst || flush)
                begin
                    EX_PC <= 32'b0;
                    EX_ReadData1 <= 32'b0;
                    EX_ReadData2 <= 32'b0;
                    EX_ImmExt <= 32'b0;
                    EX_WriteAddr <= 5'b0;
                    EX_Funct3 <= 3'b0;
                    EX_Rs1 <= 5'b0;
                    EX_Rs2 <= 5'b0;
                    EX_ALUControl <= 4'b0;
                    EX_ALUSrc <= 1'b0;
                    EX_Branch <= 1'b0;
                    EX_MemWrite <= 1'b0;
                    EX_RegWrite <= 1'b0;
                    EX_ResultSrc <= 2'b0;
                end
            else
                begin
                    EX_PC <= ID_PC;
                    EX_ReadData1 <= ID_ReadData1;
                    EX_ReadData2 <= ID_ReadData2;
                    EX_ImmExt <= ID_ImmExt;
                    EX_WriteAddr <= ID_WriteAddr;
                    EX_Funct3 <= ID_Funct3;
                    EX_Rs1 <= ID_Rs1;       // FIX: was hardcoded 5'b0
                    EX_Rs2 <= ID_Rs2;       // FIX: was hardcoded 5'b0
                    EX_ALUControl <= ID_ALUControl;
                    EX_ALUSrc <= ID_ALUSrc;
                    EX_Branch <= ID_Branch;
                    EX_MemWrite <= ID_MemWrite;
                    EX_RegWrite <= ID_RegWrite;
                    EX_ResultSrc <= ID_ResultSrc;
                end
        end
endmodule
