module BranchPredictor(
    input logic clk,
    input logic rst,

    // IF stage - prediction
    input logic [31:0] IF_PC,
    output logic predicted_taken,

    // EX stage - update interface
    input logic EX_Branch,              // 1 if the instruction in execute is actually a branch
    input logic EX_actual_taken,        // 1 if branch is actually taken (PCSrc)
    input logic [31:0] EX_PC
);

// 00 - Strongly not taken, 01 - Weakly not taken, 10 - Weakly taken, 11 - Strongly taken

logic [1:0] bht [0:7];

// 3 bit indexing ( dropping the two lower alignment bits)
logic [2:0] fetch_idx;
logic [2:0] update_idx;

assign fetch_idx = IF_PC[4:2];
assign update_idx = EX_PC[4:2];

// Taken - if the MSB of the counter is 1
assign predicted_taken = bht[fetch_idx][1];

// Synchronous FSM to update counter
always_ff @(posedge clk or posedge rst)
    begin
        if(rst)
            begin
                bht[0] <= 2'b01;
                bht[1] <= 2'b01;
                bht[2] <= 2'b01;
                bht[3]<= 2'b01;
                bht[4] <= 2'b01;
                bht[5]<= 2'b01;
                bht[6] <= 2'b01;
                bht[7] <= 2'b01;
            end
        else if (EX_Branch)
            begin
                case(bht[update_idx])
                    2'b00: bht[update_idx] <= EX_actual_taken?2'b01: 2'b00;       // strongly not taken to - 0= strongly not taken, 1 = weakly not taken
                    2'b01: bht[update_idx] <= EX_actual_taken?2'b10: 2'b00;
                    2'b10: bht[update_idx] <= EX_actual_taken?2'b11: 2'b01;
                    2'b11: bht[update_idx] <= EX_actual_taken?2'b11: 2'b10;
                endcase
            end
    end
endmodule