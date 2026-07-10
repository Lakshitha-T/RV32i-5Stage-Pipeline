module SingleCycleCPU(
    input logic clk,
    input logic rst
);

// Linking modules together - wires
logic [31:0] PCNext, PCResult;
logic [31:0] PCTarget;           // FOr Branching   
logic PCSrc;                    // For Branching
logic [31:0] Instruction;

// Control Signals
logic RegWrite, ALUSrc, MemWrite, Branch;
logic [2:0] ImmSrc;
logic [1:0] ResultSrc;
logic [3:0] ALUControl;

// Register File wires
logic [31:0] ReadData1, ReadData2, WriteData;

//ImmGen Wire
logic [31:0] ImmExt;

//ALU Wires
logic [31:0] SrcB;
logic [31:0] ALUResult;
logic Zero;

//Data Memory Wire
logic [31:0] ReadDataMem;





//1. IF (Instruction Fetch Stage)

logic [2:0] funct3_wire;
assign funct3_wire = Instruction[14:12];

// Branching for beq and bne
always_comb 
    begin
        if(Branch)
            begin
                case(funct3_wire)        // Checking funct3
                    3'b000: PCSrc = Zero;       // BEQ: Jump if equal (Subtraction)
                    3'b001: PCSrc = ~Zero;      // BNE: Jump if not equal (Subtraction)
                    default: PCSrc = 1'b0;      // Default case
                endcase
            end
        else
            begin
                PCSrc = 1'b0;                   // Not a branch instruction
            end
    end
            

// Address Calculation
assign PCTarget = PCResult + ImmExt;

// assign PCNext = PCResult + 32'd4; - Removed due to inclusion of branching

// PC Source Mux - Choosing between going to the next instruction or jumping due to branch instruction
assign PCNext = PCSrc? PCTarget: (PCResult + 32'd4);

PC pc_instance(
    .clk(clk),
    .rst(rst),
    .PCNext(PCNext),
    .PCResult(PCResult)
);

InstructionMemory imem_instance(
    .A(PCResult),
    .RD(Instruction)
);


//2. ID (Instruction Decode and Control stage)

ControlUnit control_instance(
    .Op(Instruction[6:0]),
    .Funct3(Instruction[14:12]),
    .Funct7b5(Instruction[30]),
    .RegWrite(RegWrite),
    .ImmSrc(ImmSrc),
    .ALUSrc(ALUSrc),
    .MemWrite(MemWrite),
    .ResultSrc(ResultSrc),
    .Branch(Branch),
    .ALUControl(ALUControl)
);

RegisterFile regFile_instance(
    .clk(clk),
    .rst(rst),
    .RegWrite(RegWrite),
    .ReadAddr1(Instruction[19:15]),
    .ReadAddr2(Instruction[24:20]),
    .WriteAddr(Instruction[11:7]),
    .WriteData(WriteData),
    .ReadData1(ReadData1),
    .ReadData2(ReadData2)
);

ImmGen immgen_instance(
    .instr(Instruction),
    .ImmSrc(ImmSrc),
    .imm_ext(ImmExt)
);



// 3. EX (Execute Stage)

//ALUSrc MUX - choosing between the second data value being from register 2 or Imm

assign SrcB = ALUSrc?ImmExt: ReadData2;

ALU alu_instance(
    .A(ReadData1),
    .B(SrcB),
    .ALUControl(ALUControl),        
    .ALUResult(ALUResult),
    .Zero(Zero)
);



// 4. MEM and WB (Memory and WriteBack stages)

DataMemory dmem_instance(
    .clk(clk),
    .MemWrite(MemWrite),
    .A(ALUResult),
    .WD(ReadData2),
    .RD(ReadDataMem)
);

// What data gets written into the register
// 2'b00 - ALU Result, 2'b01 - Data Memory Read Data
assign WriteData = (ResultSrc == 2'b01)? ReadDataMem: ALUResult;

endmodule


