
module stride_prefetcher (
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

/* Parameters */
parameter NUM_ENTRIES = 10;

/* State Enumeration */
enum int unsigned
{
    idle,
    prefetch
} state, next_state;

/* Variables */
logic [31:0] saved_addresses [NUM_ENTRIES];
logic [31:0] strides [NUM_ENTRIES];
logic [31:0] prefetch_mem_address;
logic [31:0] last_addr;
int entry_index;
int lru_counter;
assign prefetch_mem_address = saved_addresses[entry_index] + strides[entry_index];

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
            l2_mem_address = prefetch_mem_address;
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
            for (int i = 0; i < NUM_ENTRIES; i++) begin
                if (l1_mem_read && l2_mem_resp && l1_mem_address == saved_addresses[i]) begin
                    entry_index = i;
                    next_state = prefetch;
                end
            end
        end
        prefetch: begin
            if (l2_mem_resp) begin
                next_state = idle;
            end
        end
    endcase
end

/* Update saved_addresses and strides */
always_comb begin: update_strides
    if (rst) begin
        lru_counter = 0;
        for (int i = 0; i < NUM_ENTRIES; i++) begin
            saved_addresses[i] = 32'd0;
            strides[i] = 32'd0;
        end
        last_addr = 32'd0;
    end else if (l1_mem_read && l2_mem_resp) begin
        saved_addresses[lru_counter] = last_addr;
        strides[lru_counter] = l1_mem_address - last_addr;
        last_addr = l1_mem_address;
        lru_counter = lru_counter + 1;
        if (lru_counter == NUM_ENTRIES) begin
            lru_counter = 0;
        end
    end
end

/* Next State Assignment */
always_ff @(posedge clk) begin: next_state_assignment
    if (rst) state <= idle;
    else state <= next_state;
end

endmodule: stride_prefetcher
