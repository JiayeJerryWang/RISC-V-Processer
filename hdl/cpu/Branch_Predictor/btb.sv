import rv32i_types::*;
module btb 
#(parameter btb_idx=4)
(
  input clk,
  input rst,
  input logic update_btb,
  input logic br_en,
  input logic [31:0] pc_addr_if,   
  input logic [31:0] pc_addr_ex,   
  input logic [31:0] br_addr,     
  output logic btb_hit,
  output logic [31:0] pred_pc
);

//predict addr array--16 element
logic [31:0] br_addr_arr [2**btb_idx];
//pc array--16 element
logic [31:0] pc_addr_arr [2**btb_idx];
//branch predict result--16 element
logic br_pred_arr [2**btb_idx];
//branch target buffer hit
logic btb_hit;
//btb write idx
logic [btb_idx-1:0] btb_if_idx;
logic [btb_idx-1:0] btb_ex_idx;
assign btb_if_idx = pc_addr_if [btb_idx+1 : 5-btb_idx+1];//pc_if_in 5:2
assign btb_ex_idx = pc_addr_ex [btb_idx+1 : 5-btb_idx+1];//pc_id_out 5:2

always_comb begin 
    //pc match and prediction is branch
    if(pc_addr_if == pc_addr_arr[btb_if_idx]  && br_pred_arr[btb_if_idx] == 1'b1) begin 
        btb_hit=1'b1;
        pred_pc = br_addr_arr[btb_if_idx]; //output predicted pc address
    end

    else begin 
        //btb miss, do nothing
        btb_hit=1'b0;
        pred_pc = 32'b0;
    end
end

always_ff @(posedge clk) begin
  if (rst) begin
    for (int i=0; i < (2**btb_idx); ++i) begin
      br_addr_arr[i] <= 32'b0;
      pc_addr_arr[i] <= 32'b0;
      br_pred_arr[i] <= 32'b0;
    end
  end

  else if (update_btb) begin
    //when op_br, update branch target buffer
    br_addr_arr[btb_ex_idx] <= br_addr; //branch address from aluout
    pc_addr_arr[btb_ex_idx] <= pc_addr_ex; //pc address in exe
    br_pred_arr[btb_ex_idx] <= br_en;
  end
end


endmodule:btb