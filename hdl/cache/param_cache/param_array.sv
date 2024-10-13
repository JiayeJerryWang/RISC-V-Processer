
module param_array #(
  parameter width = 1,
  parameter Sets = 8, 
  parameter Set_index = ($clog2(Sets) - 1)
)
(
  input clk,
  input rst,
  input logic load,
  input logic [Set_index:0] rindex,
  input logic [Set_index:0] windex,
  input logic [width-1:0] datain,
  output logic [width-1:0] dataout
);

logic [width-1:0] data [Sets];

always_ff @(posedge clk)
begin
    if (rst) begin
      for (int i = 0; i < Sets; ++i) data[i] <= '0;
    end
    else if(load) begin
        data[windex] <= datain;
    end
end

always_comb begin
  dataout = /*(load  & (rindex == windex)) ? datain : */ data[rindex];
end

endmodule : param_array