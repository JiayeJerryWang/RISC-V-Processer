module arbiter (

    input logic clk,
    input logic rst,

    //cacheline

    //d-data
    input logic data_read,
    input logic data_write,
    input logic[31:0] data_addr,
    input logic[255:0] data_wdata,
    output logic data_resp,
    output logic[255:0] data_out,

    //i-data
    input logic i_read,
    output logic i_resp,
    input logic[31:0] i_addr,
    output logic[255:0] i_data,

    //cacheline adaptor
    input logic cache_resp,
    input logic[255:0] cache_data,
    output logic cache_read,
    output logic cache_write,
    output logic[31:0] cache_addr,
    output logic[255:0] cache_wdata

);

enum int unsigned{
    decode,
    i_cache,
    d_cache
} state, next_states;

function void set_defaults();
    //cacheline
    cache_read = 1'b0;
    cache_write = 1'b0;
    cache_addr = 32'b0;
    cache_wdata = 256'b0;
    //d_cache
    data_resp = 1'b0;
    data_out = 256'b0;
    //i_Cache
    i_resp = 1'b0;
    i_data = 256'b0;
endfunction

always_comb
begin : state_actions
    set_defaults();
    case(state)
        decode: begin

        end
        i_cache: begin //when i_read
            cache_addr = i_addr;
            cache_read = 1'b1;
            i_data= cache_data;
            i_resp = cache_resp;
        end
        d_cache: begin  //when d_read or d_write
            data_resp = cache_resp;
            cache_addr = data_addr;
            if(data_read)begin
                data_out = cache_data;
                cache_read = data_read;
            end
            else if(data_write)begin
                cache_write = data_write;
                cache_wdata = data_wdata;
            end

        end
    endcase
end

always_comb
begin: next_state_logic
        unique case(state)
            decode: begin
                if(data_read || data_write)begin
                    next_states = d_cache;
                end
                else if(i_read)begin
                    next_states = i_cache;
                end
                else begin
                    next_states = decode;
                end
            end
            i_cache: begin
                if(cache_resp)begin
                    next_states = decode;
                end
                else begin
                    next_states = i_cache;
                end
            end
            d_cache: begin
                if(cache_resp)begin
                    next_states = decode;
                end
                else begin
                    next_states = d_cache;
                end
            end
        endcase
end


always_ff @(posedge clk)
begin: next_state_assignment

    if (rst) begin
        state <= decode;
    end
    else begin
        state <= next_states;
    end

end

endmodule:arbiter