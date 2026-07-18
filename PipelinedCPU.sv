module PipelinedCPU(
    input logic clk,
    input logic rst
);

output logic WB_RegWrite_dbg,
output logic [4:0] WB_WriteAddr_dbg,
output logic [31:0] WB_WriteData_dbg
    
// Hazard unit control wires
logic [1:0] ForwardA, ForwardB;
logic StallF, StallD, FlushD, FlushE;

// IF Stage wires
logic [31:0] PCNext, PCTarget;
logic [31:0] IF_PCResult, IF_Instruction;

// ID Stage wires
logic [31:0] ID_PCResult, ID_Instruction;
logic ID_RegWrite, ID_ALUSrc, ID_MemWrite, ID_Branch;
logic [2:0] ID_ImmSrc;
logic [1:0] ID_ResultSrc;
logic [3:0] ID_ALUControl;
logic [31:0] ID_ReadData1, ID_ReadData2, ID_ImmExt;

logic [4:0] ID_Rs1, ID_Rs2;

assign ID_Rs1 = ID_Instruction[19:15];
assign ID_Rs2 = ID_Instruction[24:20];

// EX stage wires
logic [31:0] EX_PC, EX_ReadData1, EX_ReadData2, EX_ImmExt;
logic [4:0] EX_WriteAddr;
logic [2:0] EX_Funct3;
logic [3:0] EX_ALUControl;

logic EX_Branch;

logic EX_ALUSrc, EX_MemWrite, EX_RegWrite;
logic [1:0] EX_ResultSrc;
logic [31:0] EX_SrcB, EX_ALUResult;
logic EX_Zero, EX_PCSrc;

logic [4:0] EX_Rs1, EX_Rs2;
logic [31:0] EX_MuxA_Out, EX_MuxB_Out;          // Wires for forwarding multipliers



// MEM Stage wires
logic [31:0] MEM_ALUResult, MEM_WriteData, MEM_ReadDataMem;
logic [4:0] MEM_WriteAddr;
logic MEM_MemWrite, MEM_RegWrite;
logic [1:0] MEM_ResultSrc;


// WB Stage wires
logic [31:0] WB_ReadDataMem, WB_ALUResult, WB_WriteData;
logic [4:0] WB_WriteAddr;
logic WB_RegWrite;
logic [1:0] WB_ResultSrc;

// Branch prediction
logic predicted_taken;
logic EX_predicted_taken;
logic BP_mispredicted;



//1. IF (Instruction Fetch Stage)

// logic [2:0] funct3_wire;
// assign funct3_wire = ID_Instruction[14:12];

// // Branching for beq and bne
// always_comb 
//     begin
//         if(Branch)
//             begin
//                 case(funct3_wire)        // Checking funct3
//                     3'b000: PCSrc = Zero;       // BEQ: Jump if equal (Subtraction)
//                     3'b001: PCSrc = ~Zero;      // BNE: Jump if not equal (Subtraction)
//                     default: PCSrc = 1'b0;      // Default case
//                 endcase
//             end
//         else
//             begin
//                 PCSrc = 1'b0;                   // Not a branch instruction
//             end
//     end
            


// PC Source Mux - controlled by output of EX stage
//assign PCNext = EX_PCSrc? PCTarget: (IF_PCResult + 32'd4);         - Changed during branch prediction implementation

BranchPredictor bp_instance(
    .clk(clk),
    .rst(rst),
    .IF_PC(IF_PCResult),
    .predicted_taken(predicted_taken),
    .EX_Branch(EX_Branch),
    .EX_actual_taken(EX_PCSrc),
    .EX_PC(EX_PC)
);

// Finding out if the prediction made in the past was wrong - we are always predicting not taken
assign BP_mispredicted = EX_Branch && (EX_PCSrc != EX_predicted_taken);

// Next PC mux logic
always_comb
    begin
        if(BP_mispredicted)
            begin
                PCNext = PCTarget;              // Mispredicted
            end
        else
            begin
                // Default incremental fetch
                PCNext = IF_PCResult + 32'd4;   // Default path
            end
    end


PC pc_instance(
    .clk(clk),
    .rst(rst),
    //.PCNext(PCNext),
    .stall(StallF), // If StallF is high, directly passing it 
    .PCNext(PCNext),      
    .PCResult(IF_PCResult)
);

InstructionMemory imem_instance(
    .A(IF_PCResult),
    .RD(IF_Instruction)
);


// IF_ID Pipeline register
IF_ID_reg if_id_register(
    .clk(clk),
    .rst(rst),
    .stall(StallD),
    .flush(FlushD),
    .IF_PC(IF_PCResult),
    .IF_Instruction(IF_Instruction),
    .ID_PC(ID_PCResult),
    .ID_Instruction(ID_Instruction)
);


//2. ID (Instruction Decode and Control stage)

ControlUnit control_instance(
    .Op(ID_Instruction[6:0]),
    .Funct3(ID_Instruction[14:12]),
    .Funct7b5(ID_Instruction[30]),
    .RegWrite(ID_RegWrite),
    .ImmSrc(ID_ImmSrc),
    .ALUSrc(ID_ALUSrc),
    .MemWrite(ID_MemWrite),
    .ResultSrc(ID_ResultSrc),
    .Branch(ID_Branch),
    .ALUControl(ID_ALUControl)
);

RegisterFile regFile_instance(
    .clk(clk),
    .rst(rst),
    .RegWrite(WB_RegWrite),
    .ReadAddr1(ID_Instruction[19:15]),
    .ReadAddr2(ID_Instruction[24:20]),
    .WriteAddr(WB_WriteAddr),
    .WriteData(WB_WriteData),
    .ReadData1(ID_ReadData1),
    .ReadData2(ID_ReadData2)
);

ImmGen immgen_instance(
    .instr(ID_Instruction),
    .ImmSrc(ID_ImmSrc),
    .imm_ext(ID_ImmExt)
);

ID_EX_reg id_ex_register(
    .clk(clk), .rst(rst), 
    .flush(FlushE),             // Hazard control
    .ID_PC(ID_PCResult),
    .ID_ReadData1(ID_ReadData1), .ID_ReadData2(ID_ReadData2),
    .ID_ImmExt(ID_ImmExt),
    .ID_WriteAddr(ID_Instruction[11:7]),
    .ID_Funct3(ID_Instruction[14:12]),
    .ID_Rs1(ID_Rs1), .ID_Rs2(ID_Rs2),       // Hazard control
    .ID_ALUControl(ID_ALUControl), .ID_ALUSrc(ID_ALUSrc),
    .ID_Branch(ID_Branch), .ID_MemWrite(ID_MemWrite),
    .ID_RegWrite(ID_RegWrite), .ID_ResultSrc(ID_ResultSrc),
    
    // EX outputs
    .EX_PC(EX_PC), .EX_ReadData1(EX_ReadData1), .EX_ReadData2(EX_ReadData2),
    .EX_ImmExt(EX_ImmExt), .EX_WriteAddr(EX_WriteAddr), .EX_Funct3(EX_Funct3),
    .EX_ALUControl(EX_ALUControl), .EX_ALUSrc(EX_ALUSrc),
    .EX_Rs1(EX_Rs1), .EX_Rs2(EX_Rs2),       // Hazard control
    .EX_Branch(EX_Branch), .EX_MemWrite(EX_MemWrite),
    .EX_RegWrite(EX_RegWrite), .EX_ResultSrc(EX_ResultSrc),

    .ID_predicted_taken(predicted_taken),
    .EX_predicted_taken(EX_predicted_taken)
);

// 3. EX (Execute Stage)

//ALUSrc MUX - choosing between the second data value being from register 2 or Imm


// 3 to 1 MUX for ALU operand A
always_comb 
    begin
        case(ForwardA)
            2'b10: EX_MuxA_Out = MEM_ALUResult;         // Forward from MEM stage
            2'b01: EX_MuxA_Out = WB_WriteData;          // Forward from WB stage
            default: EX_MuxA_Out = EX_ReadData1;        // Normal read from RegFile
        endcase
    end


// 3 to 1 MUX for ALU Operand B before Immediate select
always_comb
    begin
        case(ForwardB)
            2'b10: EX_MuxB_Out = MEM_ALUResult;
            2'b01: EX_MuxB_Out = WB_WriteData;
            default: EX_MuxB_Out = EX_ReadData2;
        endcase
    end

// Selecting where operand B comes from  - register fwding pipeline or imm value
assign EX_SrcB = EX_ALUSrc?EX_ImmExt: EX_MuxB_Out;

ALU alu_instance(
    .A(EX_MuxA_Out),
    .B(EX_SrcB),
    .ALUControl(EX_ALUControl),        
    .ALUResult(EX_ALUResult),
    .Zero(EX_Zero)
);

// Branching in EX stage
always_comb 
    begin
        if(EX_Branch)
            begin
                case(EX_Funct3)
                    3'b000: EX_PCSrc = EX_Zero; // beq
                    3'b001: EX_PCSrc = ~EX_Zero; // bne
                    default: EX_PCSrc = 1'b0;
                endcase
            end
        else
            begin
                EX_PCSrc = 1'b0;
            end
    end

assign PCTarget = EX_PC + EX_ImmExt;

EX_MEM_reg ex_mem_register (
    .clk(clk), .rst(rst),
    .EX_ALUResult(EX_ALUResult),
    .EX_WriteData(EX_MuxB_Out),
    .EX_WriteAddr(EX_WriteAddr),
    .EX_MemWrite(EX_MemWrite),
    .EX_RegWrite(EX_RegWrite),
    .EX_ResultSrc(EX_ResultSrc),
    
    // MEM outputs
    .MEM_ALUResult(MEM_ALUResult),
    .MEM_WriteData(MEM_WriteData),
    .MEM_WriteAddr(MEM_WriteAddr),
    .MEM_MemWrite(MEM_MemWrite),
    .MEM_RegWrite(MEM_RegWrite),
    .MEM_ResultSrc(MEM_ResultSrc)
);


// 4. MEM stage

DataMemory dmem_instance(
    .clk(clk),
    .MemWrite(MEM_MemWrite),
    .A(MEM_ALUResult),
    .WD(MEM_WriteData),
    .RD(MEM_ReadDataMem)
);

MEM_WB_reg mem_wb_register (
    .clk(clk), .rst(rst),
    .MEM_ReadDataMem(MEM_ReadDataMem),
    .MEM_ALUResult(MEM_ALUResult),
    .MEM_WriteAddr(MEM_WriteAddr),
    .MEM_RegWrite(MEM_RegWrite),
    .MEM_ResultSrc(MEM_ResultSrc),
    
    // WB outputs
    .WB_ReadDataMem(WB_ReadDataMem),
    .WB_ALUResult(WB_ALUResult), 
    .WB_WriteAddr(WB_WriteAddr),
    .WB_RegWrite(WB_RegWrite),
    .WB_ResultSrc(WB_ResultSrc)
);


// 5. WB Stage
assign WB_WriteData = (WB_ResultSrc == 2'b01)? WB_ReadDataMem: WB_ALUResult;



// Hazard Detection part
HazardUnit hazard_unit_instance(
    .EX_Rs1(EX_Rs1),
    .EX_Rs2(EX_Rs2),
    .MEM_WriteAddr(MEM_WriteAddr),
    .MEM_RegWrite(MEM_RegWrite),
    .WB_WriteAddr(WB_WriteAddr),
    .WB_RegWrite(WB_RegWrite),
    .ID_Rs1(ID_Rs1),
    .ID_Rs2(ID_Rs2),
    .EX_WriteAddr(EX_WriteAddr),
    .EX_ResultSrc(EX_ResultSrc),
    .EX_PCSrc(EX_PCSrc),
    .ForwardA(ForwardA),
    .ForwardB(ForwardB),
    .StallF(StallF),
    .StallD(StallD),
    .FlushD(FlushD),
    .FlushE(FlushE)
);

assign WB_RegWrite_dbg  = WB_RegWrite;
assign WB_WriteAddr_dbg = WB_WriteAddr;
assign WB_WriteData_dbg = WB_WriteData;
    
endmodule
