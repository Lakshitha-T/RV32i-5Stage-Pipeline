// 00 - Strongly not taken, 01 - Weakly not taken, 10 - Weakly taken, 11 - Strongly taken
//
// UPDATED for real speculative fetch: this now doubles as a tiny direct-mapped
// BTB. Each of the 8 entries carries both the 2-bit saturating counter (taken/
// not-taken direction) AND the last-seen branch target address for that PC
// index, so IF can redirect the PC on a predicted-taken branch before the
// branch has even been decoded, let alone resolved in EX.
//
// Known limitation (same as any small direct-mapped BTB): entries are indexed
// by IF_PC[4:2] with no tag/valid bit, so two different branches (or a branch
// and a non-branch instruction) that alias to the same index can stomp on each
// other's prediction. With only 8 entries this is a real risk on anything
// beyond a small program - a tag bit and a "this index is actually a branch"
// valid bit would be the natural next hardening step.

module BranchPredictor(
    input logic clk,
    input logic rst,

    // IF stage - prediction
    input logic [31:0] IF_PC,
    output logic predicted_taken,
    output logic [31:0] predicted_target,

    // EX stage - update interface
    input logic EX_Branch,              // 1 if the instruction in execute is actually a branch
    input logic EX_actual_taken,        // 1 if branch is actually taken (PCSrc)
    input logic [31:0] EX_PC,
    input logic [31:0] EX_target        // actual resolved target address (EX_PC + EX_ImmExt)
);

logic [1:0] bht [0:7];
logic [31:0] btb [0:7];

// 3 bit indexing ( dropping the two lower alignment bits)
logic [2:0] fetch_idx;
logic [2:0] update_idx;

assign fetch_idx = IF_PC[4:2];
assign update_idx = EX_PC[4:2];

// Taken - if the MSB of the counter is 1
assign predicted_taken = bht[fetch_idx][1];
assign predicted_target = btb[fetch_idx];

// Synchronous FSM to update counter + target
always_ff @(posedge clk or posedge rst)
    begin
        if(rst)
            begin
                bht[0] <= 2'b01;
                bht[1] <= 2'b01;
                bht[2] <= 2'b01;
                bht[3] <= 2'b01;
                bht[4] <= 2'b01;
                bht[5] <= 2'b01;
                bht[6] <= 2'b01;
                bht[7] <= 2'b01;
                // btb entries left uninitialized on purpose: they're only ever
                // read when predicted_taken is 1, and predicted_taken can't be
                // 1 for an index until that index has been through an update
                // below, which always writes btb alongside bht.
            end
        else if (EX_Branch)
            begin
                case(bht[update_idx])
                    2'b00: bht[update_idx] <= EX_actual_taken?2'b01: 2'b00;       // strongly not taken to - 0= strongly not taken, 1 = weakly not taken
                    2'b01: bht[update_idx] <= EX_actual_taken?2'b10: 2'b00;
                    2'b10: bht[update_idx] <= EX_actual_taken?2'b11: 2'b01;
                    2'b11: bht[update_idx] <= EX_actual_taken?2'b11: 2'b10;
                endcase
                btb[update_idx] <= EX_target;   // record/refresh this branch's target regardless of direction
            end
    end
endmodule
