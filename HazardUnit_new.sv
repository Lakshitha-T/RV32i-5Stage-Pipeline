// Looks at the source registers being executed in the ALU (EX_RS1 and EX_RS2) and checks if they match
// the destination register in the (MEM_WriteAddr, WB_WriteAddr) - shifts the MUX

module HazardUnit(
    input logic [4:0] EX_Rs1,
    input logic [4:0] EX_Rs2,
    input logic [4:0] MEM_WriteAddr,
    input logic MEM_RegWrite,
    input logic [4:0] WB_WriteAddr,
    input logic WB_RegWrite,

    // Load Use hazard detection inputs
    input logic [4:0] ID_Rs1,
    input logic [4:0] ID_Rs2,
    input logic [4:0] EX_WriteAddr,
    input logic [1:0] EX_ResultSrc,          // 2'b01 for lw instruction

    // Control Hazard inputs
    input logic EX_PCSrc,                    // 1 when the branch is taken

    // Forwarding selection pins to ALU MUXs
    output logic [1:0] ForwardA,
    output logic [1:0] ForwardB,

    // Pipeline control outputs
    output logic StallF,                    // Stalls the PC
    output logic StallD,                    // Stalls the IF_ID Register
    output logic FlushD,                    // Flushes the IF_ID when branch is taken
    output logic FlushE                     // Flushes ID/EX when load stall or branch
);


// 1. Forwarding to the ALU input A
always_comb 
    begin
        if(((EX_Rs1 == MEM_WriteAddr) && MEM_RegWrite) && (EX_Rs1 != 5'b0))
            ForwardA = 2'b10;           // Forward from MEM stage
        else if (((EX_Rs1 == WB_WriteAddr) && WB_RegWrite) && (EX_Rs1 != 5'b0))
            ForwardA = 2'b01;           // Forward from WB stage
        else
            ForwardA = 2'b00;           // No hazard, read from register file
    end


// 2. Forwarding to ALU input B
always_comb
    begin
        if(((EX_Rs2 == MEM_WriteAddr) && MEM_RegWrite) && (EX_Rs2 != 5'b0))
            ForwardB = 2'b10;           // Forward from MEM stage
        else if(((EX_Rs2 == WB_WriteAddr) && WB_RegWrite) && (EX_Rs2 != 5'b0))
            ForwardB = 2'b01;           // FIX: was 5'b01 (wrong width), now 2'b01
        else
            ForwardB = 2'b00;           // No hazard
    end

// 3. Load-use hazard detection - stall
logic lwStall;
assign lwStall = (EX_ResultSrc == 2'b01) && ((ID_Rs1 == EX_WriteAddr) || (ID_Rs2 == EX_WriteAddr));

// 4. Combining stall and flush controls
assign StallF = lwStall;
assign StallD = lwStall;

// If branch is taken - flush the incorrectly fetched instructions
// If lwStall occurs - insert a bubble into EX stage
assign FlushD = EX_PCSrc;
assign FlushE = lwStall || EX_PCSrc;

endmodule
