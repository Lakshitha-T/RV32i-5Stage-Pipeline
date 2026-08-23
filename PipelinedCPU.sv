module PipelinedCPU(
    input logic clk,
    input logic rst,

    output logic WB_RegWrite_dbg,
    output logic [4:0] WB_WriteAddr_dbg,
    output logic [31:0] WB_WriteData_dbg
);

logic [1:0] ForwardA, ForwardB;
logic StallF, StallD, FlushD, FlushE;

logic [31:0] PCNext, PCTarget;
logic [31:0] IF_PCResult, IF_Instruction;

logic [31:0] ID_PCResult, ID_Instruction;
logic ID_predicted_taken;
logic ID_RegWrite, ID_ALUSrc, ID_MemWrite, ID_Branch;
logic ID_Jump, ID_JALR, ID_LUI, ID_AUIPC;
logic [2:0] ID_ImmSrc;
logic [1:0] ID_ResultSrc;
logic [3:0] ID_ALUControl;
logic [31:0] ID_ReadData1, ID_ReadData2, ID_ImmExt;

logic [4:0] ID_Rs1, ID_Rs2;

assign ID_Rs1 = ID_Instruction[19:15];
assign ID_Rs2 = ID_Instruction[24:20];

logic [31:0] EX_PC, EX_ReadData1, EX_ReadData2, EX_ImmExt;
logic [4:0] EX_WriteAddr;
logic [2:0] EX_Funct3;
logic [3:0] EX_ALUControl;

logic EX_Branch;
logic EX_Jump, EX_JALR, EX_LUI, EX_AUIPC;

logic EX_ALUSrc, EX_MemWrite, EX_RegWrite;
logic [1:0] EX_ResultSrc;
logic [31:0] EX_SrcB, EX_ALUResult, EX_ALUResult_Final;
logic EX_Zero, EX_PCSrc;

logic [4:0] EX_Rs1, EX_Rs2;
logic [31:0] EX_MuxA_Out, EX_MuxB_Out;
logic [31:0] EX_JumpTarget;

logic [31:0] MEM_ALUResult, MEM_WriteData, MEM_ReadDataMem, MEM_ForwardData;
logic [4:0] MEM_WriteAddr;
logic MEM_MemWrite, MEM_RegWrite;
logic [1:0] MEM_ResultSrc;

logic [31:0] WB_ReadDataMem, WB_ALUResult, WB_WriteData;
logic [4:0] WB_WriteAddr;
logic WB_RegWrite;
logic [1:0] WB_ResultSrc;

logic predicted_taken;
logic [31:0] predicted_target;
logic EX_predicted_taken;
logic BP_mispredicted;


//1. IF

BranchPredictor bp_instance(
    .clk(clk), .rst(rst),
    .IF_PC(IF_PCResult),
    .predicted_taken(predicted_taken),
    .predicted_target(predicted_target),
    .EX_Branch(EX_Branch),
    .EX_actual_taken(EX_PCSrc),
    .EX_PC(EX_PC),
    .EX_target(PCTarget)
);

assign BP_mispredicted = (EX_Branch && (EX_PCSrc != EX_predicted_taken)) || EX_Jump;

always_comb
    begin
        if(BP_mispredicted)
            begin
                if(EX_Jump)
                    PCNext = EX_JumpTarget;
                else
                    PCNext = EX_PCSrc ? PCTarget : (EX_PC + 32'd4);
            end
        else if(predicted_taken)
            PCNext = predicted_target;
        else
            PCNext = IF_PCResult + 32'd4;
    end

PC pc_instance(
    .clk(clk), .rst(rst), .stall(StallF),
    .PCNext(PCNext), .PCResult(IF_PCResult)
);

InstructionMemory imem_instance(
    .A(IF_PCResult), .RD(IF_Instruction)
);

IF_ID_reg if_id_register(
    .clk(clk), .rst(rst), .stall(StallD), .flush(FlushD),
    .IF_PC(IF_PCResult), .IF_Instruction(IF_Instruction),
    .IF_predicted_taken(predicted_taken),
    .ID_PC(ID_PCResult), .ID_Instruction(ID_Instruction),
    .ID_predicted_taken(ID_predicted_taken)
);


//2. ID

ControlUnit control_instance(
    .Op(ID_Instruction[6:0]),
    .Funct3(ID_Instruction[14:12]),
    .Funct7b5(ID_Instruction[30]),
    .RegWrite(ID_RegWrite), .ImmSrc(ID_ImmSrc), .ALUSrc(ID_ALUSrc),
    .MemWrite(ID_MemWrite), .ResultSrc(ID_ResultSrc), .Branch(ID_Branch),
    .Jump(ID_Jump), .JALR(ID_JALR), .LUI(ID_LUI), .AUIPC(ID_AUIPC),
    .ALUControl(ID_ALUControl)
);

RegisterFile regFile_instance(
    .clk(clk), .rst(rst), .RegWrite(WB_RegWrite),
    .ReadAddr1(ID_Instruction[19:15]), .ReadAddr2(ID_Instruction[24:20]),
    .WriteAddr(WB_WriteAddr), .WriteData(WB_WriteData),
    .ReadData1(ID_ReadData1), .ReadData2(ID_ReadData2)
);

ImmGen immgen_instance(
    .instr(ID_Instruction), .ImmSrc(ID_ImmSrc), .imm_ext(ID_ImmExt)
);

ID_EX_reg id_ex_register(
    .clk(clk), .rst(rst), .flush(FlushE),
    .ID_PC(ID_PCResult),
    .ID_ReadData1(ID_ReadData1), .ID_ReadData2(ID_ReadData2),
    .ID_ImmExt(ID_ImmExt),
    .ID_WriteAddr(ID_Instruction[11:7]),
    .ID_Funct3(ID_Instruction[14:12]),
    .ID_Rs1(ID_Rs1), .ID_Rs2(ID_Rs2),
    .ID_ALUControl(ID_ALUControl), .ID_ALUSrc(ID_ALUSrc),
    .ID_Branch(ID_Branch),
    .ID_Jump(ID_Jump), .ID_JALR(ID_JALR), .ID_LUI(ID_LUI), .ID_AUIPC(ID_AUIPC),
    .ID_MemWrite(ID_MemWrite),
    .ID_RegWrite(ID_RegWrite), .ID_ResultSrc(ID_ResultSrc),

    .EX_PC(EX_PC), .EX_ReadData1(EX_ReadData1), .EX_ReadData2(EX_ReadData2),
    .EX_ImmExt(EX_ImmExt), .EX_WriteAddr(EX_WriteAddr), .EX_Funct3(EX_Funct3),
    .EX_ALUControl(EX_ALUControl), .EX_ALUSrc(EX_ALUSrc),
    .EX_Rs1(EX_Rs1), .EX_Rs2(EX_Rs2),
    .EX_Branch(EX_Branch),
    .EX_Jump(EX_Jump), .EX_JALR(EX_JALR), .EX_LUI(EX_LUI), .EX_AUIPC(EX_AUIPC),
    .EX_MemWrite(EX_MemWrite),
    .EX_RegWrite(EX_RegWrite), .EX_ResultSrc(EX_ResultSrc),

    .ID_predicted_taken(ID_predicted_taken),
    .EX_predicted_taken(EX_predicted_taken)
);

// 3. EX

always_comb
    begin
        case(ForwardA)
            2'b10: EX_MuxA_Out = MEM_ForwardData;
            2'b01: EX_MuxA_Out = WB_WriteData;
            default: EX_MuxA_Out = EX_ReadData1;
        endcase
    end

always_comb
    begin
        case(ForwardB)
            2'b10: EX_MuxB_Out = MEM_ForwardData;
            2'b01: EX_MuxB_Out = WB_WriteData;
            default: EX_MuxB_Out = EX_ReadData2;
        endcase
    end

assign EX_SrcB = EX_ALUSrc ? EX_ImmExt : EX_MuxB_Out;

ALU alu_instance(
    .A(EX_MuxA_Out), .B(EX_SrcB),
    .ALUControl(EX_ALUControl),
    .ALUResult(EX_ALUResult), .Zero(EX_Zero)
);

always_comb
    begin
        if(EX_Branch)
            begin
                case(EX_Funct3)
                    3'b000: EX_PCSrc = EX_Zero;
                    3'b001: EX_PCSrc = ~EX_Zero;
                    3'b100: EX_PCSrc = EX_ALUResult[0];   // blt
                    3'b101: EX_PCSrc = ~EX_ALUResult[0];  // bge
                    3'b110: EX_PCSrc = EX_ALUResult[0];   // bltu
                    3'b111: EX_PCSrc = ~EX_ALUResult[0];  // bgeu
                    default: EX_PCSrc = 1'b0;
                endcase
            end
        else
            EX_PCSrc = 1'b0;
    end

assign PCTarget = EX_PC + EX_ImmExt;
assign EX_JumpTarget = EX_JALR ? (EX_ALUResult & ~32'h1) : PCTarget;

assign EX_ALUResult_Final = EX_LUI    ? EX_ImmExt      :
                             EX_AUIPC ? PCTarget        :
                             EX_Jump  ? (EX_PC + 32'd4) :
                                        EX_ALUResult;

EX_MEM_reg ex_mem_register (
    .clk(clk), .rst(rst),
    .EX_ALUResult(EX_ALUResult_Final),
    .EX_WriteData(EX_MuxB_Out),
    .EX_WriteAddr(EX_WriteAddr),
    .EX_MemWrite(EX_MemWrite),
    .EX_RegWrite(EX_RegWrite),
    .EX_ResultSrc(EX_ResultSrc),

    .MEM_ALUResult(MEM_ALUResult),
    .MEM_WriteData(MEM_WriteData),
    .MEM_WriteAddr(MEM_WriteAddr),
    .MEM_MemWrite(MEM_MemWrite),
    .MEM_RegWrite(MEM_RegWrite),
    .MEM_ResultSrc(MEM_ResultSrc)
);


// 4. MEM

DataMemory dmem_instance(
    .clk(clk), .MemWrite(MEM_MemWrite),
    .A(MEM_ALUResult), .WD(MEM_WriteData), .RD(MEM_ReadDataMem)
);

assign MEM_ForwardData = (MEM_ResultSrc == 2'b01) ? MEM_ReadDataMem : MEM_ALUResult;

MEM_WB_reg mem_wb_register (
    .clk(clk), .rst(rst),
    .MEM_ReadDataMem(MEM_ReadDataMem),
    .MEM_ALUResult(MEM_ALUResult),
    .MEM_WriteAddr(MEM_WriteAddr),
    .MEM_RegWrite(MEM_RegWrite),
    .MEM_ResultSrc(MEM_ResultSrc),

    .WB_ReadDataMem(WB_ReadDataMem),
    .WB_ALUResult(WB_ALUResult),
    .WB_WriteAddr(WB_WriteAddr),
    .WB_RegWrite(WB_RegWrite),
    .WB_ResultSrc(WB_ResultSrc)
);


// 5. WB
assign WB_WriteData = (WB_ResultSrc == 2'b01) ? WB_ReadDataMem : WB_ALUResult;


HazardUnit hazard_unit_instance(
    .EX_Rs1(EX_Rs1), .EX_Rs2(EX_Rs2),
    .MEM_WriteAddr(MEM_WriteAddr), .MEM_RegWrite(MEM_RegWrite),
    .WB_WriteAddr(WB_WriteAddr), .WB_RegWrite(WB_RegWrite),
    .ID_Rs1(ID_Rs1), .ID_Rs2(ID_Rs2),
    .EX_WriteAddr(EX_WriteAddr), .EX_ResultSrc(EX_ResultSrc),
    .BP_mispredicted(BP_mispredicted),
    .ForwardA(ForwardA), .ForwardB(ForwardB),
    .StallF(StallF), .StallD(StallD),
    .FlushD(FlushD), .FlushE(FlushE)
);

assign WB_RegWrite_dbg  = WB_RegWrite;
assign WB_WriteAddr_dbg = WB_WriteAddr;
assign WB_WriteData_dbg = WB_WriteData;

endmodule
