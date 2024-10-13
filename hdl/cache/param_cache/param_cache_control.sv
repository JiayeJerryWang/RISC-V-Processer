module param_cache_control #(
  parameter Ways = 8,
  parameter Lru = ($clog2(Ways) - 1)
) 
(
  input clk,
  input rst,
  /* CPU memory data signals */
  input  logic mem_read,
	input  logic mem_write,
	output logic mem_resp,

  /* Physical memory data signals */
  input  logic pmem_resp,
	output logic pmem_read,
	output logic pmem_write,

  /* Control signals */
  output logic tag_load,
  output logic valid_load,
  input logic valid_out[Ways],
  output logic dirty_load,
  output logic dirty_in,
  input logic dirty_out,

  input logic hit,
  output logic [1:0] writing,

  output logic lru_load[Ways],
  output logic [Lru : 0] lru_in[Ways],
  input logic [Lru : 0] lru_out[Ways],
  input logic [Lru : 0] lru_idx
);

/* State Enumeration */
enum int unsigned
{
  check_hit,
	read_mem
} state, next_state;

/* State Control Signals */
always_comb begin : state_actions

	/* Defaults */
  tag_load = 1'b0;
  valid_load = 1'b0;
  dirty_load = 1'b0;
  dirty_in = 1'b0;
  writing = 2'b11;

	mem_resp = 1'b0;
	pmem_write = 1'b0;
	pmem_read = 1'b0;
  for (int i = 0; i < Ways; i++) begin
    lru_load[i] = 1'b0;
    lru_in[i] = '0;
  end

	case(state)
    check_hit: begin
      if (mem_read || mem_write) begin
        if (hit) begin
          mem_resp = 1'b1;
          if (mem_write) begin
            dirty_load = 1'b1;
            dirty_in = 1'b1;
            writing = 2'b01;
          end
          for (int i = 0; i < Ways; i++) begin
            if ((lru_out[i] < lru_out[lru_idx]) && valid_out[i]) begin
              lru_in[i] = lru_out[i] + 1;
              lru_load[i] = 1'b1;
            end
          end
          lru_in[lru_idx] = '0;
          lru_load[lru_idx] = 1'b1;
        end else begin
          if (dirty_out)
            pmem_write = 1'b1;
        end
      end
    end

    read_mem: begin
      pmem_read = 1'b1;
      writing = 2'b00;
      if (pmem_resp) begin
        tag_load = 1'b1;
        valid_load = 1'b1;
      end
        dirty_load = 1'b1;
        dirty_in = 1'b0;
    end
	endcase
end

/* Next State Logic */
always_comb begin : next_state_logic

	/* Default state transition */
	next_state = state;

	case(state)
    check_hit: begin
      if ((mem_read || mem_write) && !hit) begin
        if (dirty_out) begin
          if (pmem_resp)
            next_state = read_mem;
        end else begin
          next_state = read_mem;
		  end
      end
    end

    read_mem: begin
      if (pmem_resp)
        next_state = check_hit;
    end

	endcase
end

/* Next State Assignment */
always_ff @(posedge clk) begin: next_state_assignment
  if (rst) state <= check_hit;
  else state <= next_state;
end

endmodule : param_cache_control