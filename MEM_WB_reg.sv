module MEM_WB_reg(
    input logic clk,
    input logic rst,

    // Data inputs from MEM
    input logic [31:0] MEM_ReadDataMem,
    input logic [31:0] MEM_ALUResult,
    input logic [4:0] MEM_WriteAddr,

    // Control inputs from MEM
    input logic MEM_RegWrite,
    input logic [1:0] MEM_ResultSrc,

    // Data outputs to WB
    output logic [31:0] WB_ReadDataMem,
    output logic [31:0] WB_ALUResult,
    output logic [4:0] WB_WriteAddr,

    // Control outputs to WB
    output logic WB_RegWrite,
    output logic [1:0] WB_ResultSrc
);

always_ff @(posedge clk or posedge rst)
    begin
        if(rst)
            begin
                WB_ReadDataMem <= 32'b0;
                WB_ALUResult <= 32'b0;
                WB_WriteAddr <= 5'b0;
                WB_RegWrite <= 1'b0;
                WB_ResultSrc <= 2'b0;
            end
        else
            begin
                WB_ReadDataMem <= MEM_ReadDataMem;
                WB_ALUResult <= MEM_ALUResult;
                WB_WriteAddr <= MEM_WriteAddr;
                WB_RegWrite <= MEM_RegWrite;
                WB_ResultSrc <= MEM_ResultSrc;
            end
    end
endmodule


