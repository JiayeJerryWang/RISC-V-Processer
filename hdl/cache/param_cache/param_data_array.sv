module param_data_array #(
  parameter Sets = 8,
  parameter Set_index = ($clog2(Sets) - 1)
)
(
  input clk,
  input rst,
  input logic [31:0] write_en,
  input logic [Set_index:0] rindex,
  input logic [Set_index:0] windex,
  input logic [255:0] datain,
  output logic [255:0] dataout
);

logic [255:0] data [Sets];

always_comb begin
  for (int i = 0; i < 32; i++) begin
      dataout[8*i +: 8] = (write_en[i] & (rindex == windex)) ? datain[8*i +: 8] : data[rindex][8*i +: 8];
  end
end

always_ff @(posedge clk) begin
    if (rst) for (int i = 0; i < Sets; ++i) begin
      data[i] <= '0;
    end
    else begin
    for (int i = 0; i < 32; i++) begin
		  data[windex][8*i +: 8] <= write_en[i] ? datain[8*i +: 8] : data[windex][8*i +: 8];
    end
    end
end

endmodule : param_data_array
