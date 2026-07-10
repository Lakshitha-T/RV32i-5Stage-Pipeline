//Reading is combinational
//Writing is sequential, synchronous, to the clock rising edge, and the MemWrite must be active

module DataMemory(
    input logic clk,
    input logic MemWrite,       // If it is 1, then write mode, else read mode
    input logic [31:0] A,       // 32 bit memory address
    input logic [31:0] WD,      // Data to be written, when in write mode
    output logic [31:0] RD      // Data that has been read (in read mode)
);

// Creating the Data Memory Array of 32 bit, each, 64 words
logic [31:0] RAM [0:63];

initial 
    begin
        for (int i = 0; i < 64; i = i + 1) begin
            RAM[i] = 32'h00000000; // Force-clear memory spaces to zero
        end
    end

//Combinational Read Logic - Outputs data whenever address changes
assign RD = RAM[A[31:2]];

// Sequential, Synchronous Write Logic
always_ff @(posedge clk)
        begin
            if(MemWrite)
                begin
                    RAM[A[31:2]] <= WD;
                end
        end

endmodule
