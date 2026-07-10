// Going to have provision for reading from 2 registers and writing to one register.
// Because, like, add r1, r2, r3 ( need to read from both r2 and r3)
// Also going to have synchronous write and asynchronous read

module RegisterFile(
    input logic clk,
    input logic rst,
    input logic RegWrite,               // If 1 = Write Enabled
    input logic [4:0] ReadAddr1,        // Address to read (rs1)
    input logic [4:0] ReadAddr2,        // Address to read (rs2)
    input logic [4:0] WriteAddr,        // Address where to write (rd)
    input logic [31:0] WriteData,       // Data to write
    output logic [31:0] ReadData1,      // Data read from rs1
    output logic [31:0] ReadData2       // Data read from rs2
);

    // Creating the array of registers
    logic [31:0] registers [31:0];


    // Asynchronous Read (Combinational) - Can read at any time
    assign ReadData1 = (ReadAddr1 == 5'b0)? 32'b0: registers[ReadAddr1];
    assign ReadData2 = (ReadAddr2 == 5'b0)? 32'b0: registers[ReadAddr2];

    // Synchronous Write (Sequential) - Writes only at the rising clock edge
    always_ff @(posedge clk)
        begin
            if (rst)
                begin
                    integer i;
                    for(i=0;i<32;i=i+1)
                        begin
                            registers[i] <=32'b0;
                        end
                end
            else if(RegWrite && (WriteAddr != 5'b0))
                begin
                    registers[WriteAddr]<= WriteData;
                end
        end

endmodule

    