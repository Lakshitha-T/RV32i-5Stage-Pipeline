module EX_MEM_reg(
    input logic clk,
    input logic rst,

    // Data inputs from EX
    input logic [31:0] EX_ALUResult,
    input logic [31:0] EX_WriteData,
    input logic [4:0] EX_WriteAddr,

    // Control inputs from EX
    input logic EX_MemWrite,
    input logic EX_RegWrite,
    input logic [1:0] EX_ResultSrc,

    // Data outputs to MEM
    output logic [31:0] MEM_ALUResult,
    output logic [31:0] MEM_WriteData,
    output logic [4:0] MEM_WriteAddr,

    // Control outputs to MEM
    output logic MEM_MemWrite,
    output logic MEM_RegWrite,
    output logic [1:0] MEM_ResultSrc
);

always_ff @(posedge clk or posedge rst)
    begin
        if(rst)
            begin
                MEM_ALUResult <= 32'b0;
                MEM_WriteData <= 32'b0;
                MEM_WriteAddr <= 5'b0;
                MEM_MemWrite <= 1'b0;
                MEM_RegWrite <= 1'b0;
                MEM_ResultSrc <= 2'b0;
            end
        else
            begin
                MEM_ALUResult <= EX_ALUResult;
                MEM_WriteData <= EX_WriteData;
                MEM_WriteAddr <= EX_WriteAddr;
                MEM_MemWrite <= EX_MemWrite;
                MEM_RegWrite <= EX_RegWrite;
                MEM_ResultSrc <= EX_ResultSrc;
            end
    end
endmodule


