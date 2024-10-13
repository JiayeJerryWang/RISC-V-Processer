module tournament_predictor
#(parameter idx_offset=6, parameter idx_length=4) 
(
  input clk,
  input rst,
  input tournament_update,
  input br_en,
  input [31:0] pc_addr_fetch,
  input [31:0] pc_addr_ex,
  input [6:0] opcode,
  input logic all_stall,
  output logic tournament_pred_result
);

logic local_pred_result;
logic global_pred_result;
logic lbht_decode,lbht_ex;
logic gbht_decode,gbht_ex;
logic [idx_offset:idx_offset-idx_length+1] pht_read_idx;
logic [idx_offset:idx_offset-idx_length+1] pht_write_idx;

assign pht_read_idx = pc_addr_fetch[idx_offset:idx_offset-idx_length+1];
assign pht_write_idx = pc_addr_ex [idx_offset:idx_offset-idx_length+1];


typedef enum bit [1:0]
{
  ST_local = 2'b00,
  WT_local = 2'b01,
  WT_global = 2'b10,
  ST_global = 2'b11
} predictor_sel_t;

predictor_sel_t predictor_selector;

always_comb begin 
    //select logic for global/local
    if(predictor_selector[1]) begin 
        tournament_pred_result=global_pred_result;
    end
    else begin 
        tournament_pred_result=local_pred_result;
    end
end

always_ff @(posedge clk) begin 
    //initialize selector to local
    if (rst) begin 
        predictor_selector <= WT_local;
    end

    else if (tournament_update) begin 
        if(br_en) begin
            if((lbht_ex==1'b0) && (gbht_ex==1'b0))begin
                predictor_selector <= predictor_selector; //both predictor wrong
            end

            if((lbht_ex==1'b0) && (gbht_ex==1'b1) && predictor_selector!= ST_global)begin
                predictor_selector <= predictor_selector+1; //global correct, increment
            end

            if((lbht_ex==1'b1) && (gbht_ex==1'b0) && predictor_selector!= ST_local )begin
                predictor_selector <= predictor_selector-1; //local correct, decreament
            end

            if((lbht_ex==1'b1) && (gbht_ex==1'b1))begin
                predictor_selector <= predictor_selector;//both predictor correct
            end
        end

        if(~br_en) begin
            if((lbht_ex==1'b0) && (gbht_ex==1'b0))begin
                predictor_selector <= predictor_selector; //both correct
            end

            if((lbht_ex==1'b0) && (gbht_ex==1'b1) && predictor_selector!= ST_local)begin
                predictor_selector <= predictor_selector-1; //local correct, decreament
            end

            if((lbht_ex==1'b1) && (gbht_ex==1'b0) && predictor_selector!= ST_global)begin
                predictor_selector <= predictor_selector+1; //global correct, increment
            end

            if((lbht_ex==1'b1) && (gbht_ex==1'b1))begin 
                predictor_selector <= predictor_selector; //both wrong
            end
        end
    end

//     else if (all_stall) begin
//         lbht_decode <= local_pred_result;
//         lbht_ex <= lbht_decode;
        
//         gbht_decode <= global_pred_result;
//         gbht_ex <= gbht_decode;
//   end
end

always_ff @(posedge clk) begin
  if (all_stall) begin
    lbht_decode <= local_pred_result;
    lbht_ex <= lbht_decode;
    
    gbht_decode <= global_pred_result;
    gbht_ex <= gbht_decode;

  end
end


//*********************************instanciate global and local predictor here*******************************************//
global_branch_predictor  #(.idx_offset(idx_offset),.idx_length(idx_length), .bht_length(idx_length)) 
global_branch_predictor
(
  .clk(clk),
  .rst(rst),
  .global_pred_update(tournament_update),
  .br_en(br_en),
  .pc_fetch(pc_addr_fetch),
  .pc_exe(pc_addr_ex),
  .opcode (opcode),
  .br_result(global_pred_result),
  .mis_predict() //not used
);

pattern_hist_t #(.phtidx(idx_length))
local_predictor (
    .clk(clk),
    .rst(rst),
    .pht_r_idx(pht_read_idx),
    .pht_w_idx(pht_write_idx),
    .br_en(br_en),
    .opcode(opcode),
    .update_pht(tournament_update),
    .pred_result(local_pred_result),
    .mis_predict() //not used
);

endmodule:tournament_predictor