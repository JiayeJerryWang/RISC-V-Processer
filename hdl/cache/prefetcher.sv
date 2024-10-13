
module prefetcher (
    input logic clk,
    input logic rst,

    /* l1 cache signals */
    input logic l1_mem_read,
    output logic l1_mem_resp,
    input logic [31:0] l1_mem_address,

    /* l2 cache signals */
    output logic l2_mem_read,
    input logic l2_mem_resp,
    output logic [31:0] l2_mem_address   
);
/* State Enumeration */
enum int unsigned
{
    idle,
    prefetch
} state, next_state;

logic [31:0] preftech_mem_address;
logic load;
assign load = (l1_mem_read && state == idle);

register preftech_address (
    .clk(clk),
    .rst(rst),
    .load(load),
    .in(l1_mem_address + 32'd32),
    .out(preftech_mem_address)
);

/* State Control Signals */
always_comb begin : state_actions
	/* Defaults */
    l2_mem_read =  l1_mem_read;
    l2_mem_address = l1_mem_address;
    l1_mem_resp = l2_mem_resp;

    case(state)
        idle: begin
            l2_mem_read =  l1_mem_read;
            l2_mem_address = l1_mem_address;
            l1_mem_resp = l2_mem_resp;  
        end
        prefetch: begin
            l2_mem_read = 1'b1;
            l2_mem_address = preftech_mem_address;
            l1_mem_resp = 1'b0;
        end
    endcase
end

/* Next State Logic */
always_comb begin : next_state_logic
	/* Default state transition */
	next_state = state;
	case(state)
        idle: begin
            if (l1_mem_read && l2_mem_resp) begin
                next_state = prefetch;
            end 
        end
        prefetch: begin
            if (l2_mem_resp) begin
                next_state = idle;
            end
        end
	endcase
end

/* Next State Assignment */
always_ff @(posedge clk) begin: next_state_assignment
  if (rst) state <= idle;
  else state <= next_state;
end

endmodule: prefetcher
