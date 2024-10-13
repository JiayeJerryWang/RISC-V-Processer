import rv32i_types::*;
module pattern_hist_t
#(parameter phtidx = 4)
(
  input clk,
  input rst,
  input [phtidx-1:0] pht_r_idx,
  input [phtidx-1:0] pht_w_idx,
  input logic br_en,
  input [6:0] opcode,
  input logic update_pht,
  output logic pred_result,
  output logic mis_predict
);

typedef enum bit [1:0]
{
  SNT = 2'b00,
  WNT = 2'b01,
  WT = 2'b10,
  ST = 2'b11
} counter_state;


//construct pattern history table of size 2**phtidx
counter_state pht[(2**phtidx)-1:0];

always_comb begin 
    //op=op_jal or op_jalr or op_br
    if (opcode ==  7'b1100011) begin 
            pred_result = pht [pht_r_idx][1]; // output pht result
    end

    else begin 
        pred_result = 1'b0;
    end
end

always_ff @(posedge clk) begin 
    //initialize pht to WNT
    if (rst) begin 
        for (int i=0; i<(2**phtidx); ++i) begin 
            pht[i] <= WNT;
        end
    mis_predict = 1'b0;
    end

    //2-bit counter update logic
    else if (update_pht) begin 
        if (br_en && pht[pht_w_idx] != ST) begin 
            pht[pht_w_idx] <= pht[pht_w_idx] + 1;
        end

        else if (~br_en && pht[pht_w_idx] != SNT) begin 
            pht[pht_w_idx] <= pht[pht_w_idx] - 1;
        end
    end
//2-bit update logic
//     else begin 
//         if(update_pht) begin 
//             //increment
//             if (br_en) begin 
//                 if(pht[pht_w_idx] == SNT || pht[pht_w_idx] == WNT)begin
//                     pht[pht_w_idx] <= counter_state'(pht[pht_w_idx] + 1);
//                     mis_predict=1'b1;
//                 end
//                 else if(pht[pht_w_idx] == WT) begin 
//                     pht[pht_w_idx] <=(pht[pht_w_idx] + 1);
//                     mis_predict=1'b0;
//                 end

//             end
//             //decrement
//             else if (~br_en ) begin 
//                 if (pht[pht_w_idx] == WT || pht[pht_w_idx] == ST) begin
//                     pht[pht_w_idx] <= (pht[pht_w_idx] - 1);
//                     mis_predict=1'b1;
//                 end

//                 else if (pht[pht_w_idx] == WNT) begin
//                     pht[pht_w_idx] <= (pht[pht_w_idx] - 1);
//                     mis_predict=1'b0;
//                 end
//             end
//     end
// end
end
endmodule: pattern_hist_t