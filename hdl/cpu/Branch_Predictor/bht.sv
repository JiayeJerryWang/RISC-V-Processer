module branch_history_table 
#(parameter int width = 4)
(
  input clk,
  input rst,
  input update,
  input in,
  output [width-1:0] out
);

logic [(width-1):0] data;

assign out = data;

always_ff @(posedge clk) begin
  if (rst) begin
    data <= '0;
  end else begin
    if (update) begin
      data <= data << 1; //new branch result stored in low bit
      data[0] <= in;
    end else begin
      data <= data;
    end
  end
end

endmodule : branch_history_table
