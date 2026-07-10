//PC - 32 bit register that holds the memory of the instruction currently being executed.
//Every clock cycle it goes to the next instruction address
//The instruction memory - a storage unit that holds the binary machine code of the program.
//The PC points to an address inside the memory and the memory outputs the instruction

module PC(
    input logic clk,
    input logic rst,
    input logic stall,                  // When it is initiated, we stop updating its internal register
    input logic [31:0] PCNext,          //The calculated address of the next instruction (PC + 4)
    output logic [31:0] PCResult        //The current instruction address
);

    //Should be a flip flop output
    always_ff @(posedge clk or posedge rst)
        begin
            if(rst)
                begin
                    PCResult<=32'b0;
                end
            else if (!stall)
                begin
                    PCResult<=PCNext;
                end
        end
endmodule


