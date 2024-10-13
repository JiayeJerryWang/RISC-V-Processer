module param_cache_datapath #(
  parameter Ways = 8,
  parameter Lru = ($clog2(Ways) - 1),
  parameter Sets = 8,
  parameter Set_index = ($clog2(Sets) - 1)
)
(
  input clk,
  input rst,
  /* CPU memory data signals */
  input logic  [31:0]  mem_byte_enable,
  input logic  [31:0]  mem_address,
  input logic  [255:0] mem_wdata,
  output logic [255:0] mem_rdata,

  /* Physical memory data signals */
  input  logic [255:0] pmem_rdata,
  output logic [255:0] pmem_wdata,
  output logic [31:0]  pmem_address,

  /* Control signals */
  input logic tag_load,
  input logic valid_load,
  output logic valid_out[Ways],
  input logic dirty_load,
  input logic dirty_in,
  output logic dirty_out,

  output logic hit,
  input logic [1:0] writing,

  /* param signals */
  input logic lru_load[Ways],
  input logic [Lru : 0] lru_in[Ways],
  output logic [Lru : 0] lru_out[Ways],
  output logic [Lru : 0] lru_idx
);

logic [255:0] line_in, line_out[Ways];
logic [(31-(6+Set_index)):0] address_tag, tag_out[Ways];
logic [Set_index:0] index;
logic [31:0] mask[Ways];
logic ld_tag[Ways];
logic ld_valid[Ways];
logic ld_dirty[Ways];
logic dirty[Ways];

function int get_index();
  for (int i = 0; i < Ways; i++) begin
    // hit
    if ((valid_out[i] == 1'b1) && (tag_out[i] == address_tag)) begin
      return i;
    end
  end
  for (int i = 0; i < Ways; i++) begin
    // dirty
    if (valid_out[i] == 1'b0) begin
      return i;
    end
  end
  for (int i = 0; i < Ways; i++) begin
    // lru
    if ((lru_out[i] + 1) == Ways) begin
      return i;
    end
  end
  return 0;
endfunction;

always_comb begin
  // defaults
  address_tag = mem_address[31:(6+Set_index)];
  index = mem_address[(5+Set_index):5];

  for (int i = 0; i < Ways; i++) begin
    ld_tag[i] = 1'b0;
    ld_valid[i] = 1'b0;
    ld_dirty[i] = 1'b0;
    mask[i] = 32'b0;
  end

  // get the lru index
  lru_idx = get_index();

  // assign values
  ld_tag[lru_idx] = tag_load;
  ld_valid[lru_idx] = valid_load;
  ld_dirty[lru_idx] = dirty_load;
  dirty_out = dirty[lru_idx];
  hit = valid_out[lru_idx] && (tag_out[lru_idx] == address_tag);
  pmem_address = (dirty[lru_idx]) ? {tag_out[lru_idx], mem_address[(5+Set_index):0]} : mem_address;
  mem_rdata = line_out[lru_idx];
  pmem_wdata = line_out[lru_idx];

  case(writing)
    2'b00: begin // load from memory
      mask[lru_idx] = 32'hFFFFFFFF;
      line_in = pmem_rdata;
    end
    2'b01: begin // write from cpu
      mask[lru_idx] = mem_byte_enable;
      line_in = mem_wdata;
    end
    default: begin // don't change data
      mask[lru_idx] = 32'b0;
      line_in = mem_wdata;
    end
	endcase
end

genvar i;
generate
  for (i = 0; i < Ways; i++) begin: arrays
    param_data_array #(Sets, Set_index) DM_cache (clk, rst, mask[i], index, index, line_in, line_out[i]);
    param_array #((31 - (5 + Set_index)), Sets, Set_index) tag_array (clk, rst, ld_tag[i], index, index, address_tag, tag_out[i]);
    param_array #(1, Sets, Set_index) valid_array (clk, rst, ld_valid[i], index, index, 1'b1, valid_out[i]);
    param_array #(1, Sets, Set_index) dirty_array (clk, rst, ld_dirty[i], index, index, dirty_in, dirty[i]);
    param_lru_array #(Ways, Lru + 1, Sets, Set_index) lru_array (clk, rst, lru_load[i], index, index, lru_in[i], lru_out[i]);
  end
endgenerate

endmodule : param_cache_datapath