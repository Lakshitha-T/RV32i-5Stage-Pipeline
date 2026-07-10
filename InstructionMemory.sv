//Instruction Memory is read only - that too, only during runtime
module InstructionMemory(
    input logic [31:0]A,        //32 bit byte address coming from the PC
    output logic [31:0]RD       //32 bit read data ( The instruction machine code)
);


// Creating a memory array of 64 words ( each word is 4 bytes (32bits) wide)
logic [31:0] mem [0:63];


//Word aligned read logic: Drop the last 2 bits (divide by 4)
assign RD = mem[A[31:2]];

// The program.mem has the machine codes for 
//addi s9,s0,4
//sw x31,4(x2)
//add a0,s1,s2

endmodule