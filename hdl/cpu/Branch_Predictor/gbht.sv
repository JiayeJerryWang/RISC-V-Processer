module global_branch_predictor 
#(parameter idx_offset=6, parameter idx_length=4, parameter bht_length=4) 
(
  input clk,
  input rst,
  input global_pred_update,
  input br_en,
  input [31:0] pc_fetch,
  input [31:0] pc_exe,
  input [6:0] opcode,
  output br_result,
  output logic mis_predict
);

logic [(bht_length-1):0] bht_out;
logic [idx_offset:idx_offset-idx_length+1] pht_read_idx;
logic [idx_offset:idx_offset-idx_length+1] pht_write_idx;
assign pht_read_idx = pc_fetch[idx_offset:idx_offset-idx_length+1] ^ bht_out; 
assign pht_write_idx = pc_exe[idx_offset:idx_offset-idx_length+1] ^ bht_out;

pattern_hist_t #(.phtidx(idx_length))
local_predictor (
    .clk(clk),
    .rst(rst),
    .pht_r_idx(pht_read_idx),
    .pht_w_idx(pht_write_idx),
    .br_en(br_en),
    .opcode(opcode),
    .update_pht(global_pred_update),
    .pred_result(br_result),
    .mis_predict()//not used
);

branch_history_table #(.width(bht_length))
bhrt (
  .clk(clk),
  .rst(rst),
  .update(global_pred_update),
  .in(br_en),
  .out(bht_out)
);

endmodule : global_branch_predictor