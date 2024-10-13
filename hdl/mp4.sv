
module mp4
import rv32i_types::*;
(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
	//To physical memory
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);
/*********************************************************************/
// cache signal
logic i_resp, d_resp, i_resp_prefetch, d_resp_prefetch;
logic [31:0] i_mem_rdata, d_mem_rdata;
logic [31:0] i_mem_wdata, d_mem_wdata;
logic d_mem_read, d_mem_write, d_mem_read_l2, d_mem_write_l2, d_mem_read_prefetch;
logic i_mem_read, i_mem_read_l2, i_mem_write_l2, i_mem_read_prefetch;
logic [3:0] mem_byte_enable;
logic [31:0] i_mem_address, d_mem_address, d_mem_address_l2, i_mem_address_l2, i_mem_address_prefetch, d_mem_address_prefetch;

// cacheline adaptor signal
logic [255:0] l2_line_i, line_i, i_line_i, d_line_i, d_mem_wdata_l2, i_mem_wdata_l2;
logic [255:0] l2_line_o, line_o, i_line_o, d_line_o, d_mem_rdata_l2, i_mem_rdata_l2;
logic [31:0] l2_address_i, address_i, i_address_i, d_address_i, prefetch_pc_address;
logic read_i, i_read_i, d_read_i, l2_read_i;
logic write_i, l2_write_i, i_write_i, d_write_i;
logic resp_o, l2_resp_o, i_resp_o, d_resp_o, resp_l2;
/*********************************************************************/
assign i_mem_wdata = 32'b0;
cpu cpu(
    .clk(clk),
    .rst(rst),
    .i_data(i_mem_rdata),
    .i_addr(i_mem_address),
    .data_address(d_mem_address),
    .data_w(d_mem_wdata),
    .data_r(d_mem_rdata), 
    .data_mem_byte_enable(mem_byte_enable),  
    .data_read(d_mem_read),
    .data_write (d_mem_write),
    .i_resp(i_resp),
    .i_read(i_mem_read),
    .data_resp(d_resp),
    .prefetch_pc(prefetch_pc_address)
);

l1_param_cache #(4, 8) l1_i_cache (
    .clk(clk),
    .rst(rst),
    /* Physical memory signals when using prefetch */

    // .pmem_resp(i_resp_prefetch),
    // .pmem_rdata(i_line_o),
    // .pmem_address(i_mem_address_prefetch),
    // .pmem_wdata(i_line_i),
    // .pmem_read(i_mem_read_prefetch),
    // .pmem_write(i_write_i),

    /* Physical memory signals when not using prefetch */

    .pmem_resp(i_resp_o),
    .pmem_rdata(i_line_o),
    .pmem_address(i_address_i),
    .pmem_wdata(i_line_i),
    .pmem_read(i_read_i),
    .pmem_write(i_write_i),

    /* CPU memory signals */
    .mem_read(i_mem_read),
    .mem_write(1'b0),
    .mem_byte_enable_cpu(mem_byte_enable),
    .mem_address(i_mem_address),
    .mem_wdata_cpu(i_mem_wdata),
    .mem_resp(i_resp),
    .mem_rdata_cpu(i_mem_rdata)
);

// prefetcher i_prefetcher (
//     .clk(clk),
//     .rst(rst),

//     /* l1 cache signals */
//     .l1_mem_read(i_mem_read_prefetch),
//     .l1_mem_resp(i_resp_prefetch),
//     .l1_mem_address(i_mem_address_prefetch),

//     /* arbiter signals */
//     .l2_mem_read(i_read_i),
//     .l2_mem_resp(i_resp_o),
//     .l2_mem_address(i_address_i)
// );

l1_param_cache #(4, 8) l1_d_cache (
    .clk(clk),
    .rst(rst),
    /* Physical memory signals when using prefetch */

    // .pmem_resp(d_resp_prefetch),
    // .pmem_rdata(d_line_o),
    // .pmem_address(d_mem_address_prefetch),
    // .pmem_wdata(d_line_i),
    // .pmem_read(d_mem_read_prefetch),
    // .pmem_write(d_write_i),

    /* Physical memory signals when not using prefetch */

    .pmem_resp(d_resp_o),
    .pmem_rdata(d_line_o),
    .pmem_address(d_address_i),
    .pmem_wdata(d_line_i),
    .pmem_read(d_read_i),
    .pmem_write(d_write_i),

    /* CPU memory signals */
    .mem_read(d_mem_read),
    .mem_write(d_mem_write),
    .mem_byte_enable_cpu(mem_byte_enable),
    .mem_address(d_mem_address),
    .mem_wdata_cpu(d_mem_wdata),
    .mem_resp(d_resp),
    .mem_rdata_cpu(d_mem_rdata)
);

// prefetcher d_prefetcher (
//     .clk(clk),
//     .rst(rst),

//     /* l1 cache signals */
//     .l1_mem_read(d_mem_read_prefetch),
//     .l1_mem_resp(d_resp_prefetch),
//     .l1_mem_address(d_mem_address_prefetch),

//     /* l2 cache signals */
//     .l2_mem_read(d_read_i),
//     .l2_mem_resp(d_resp_o),
//     .l2_mem_address(d_address_i)
// );

arbiter arbiter (
    .clk(clk),
    .rst(rst),

    // from the i_cache
    .i_read(i_read_i),
    .i_resp(i_resp_o),
    .i_addr(i_address_i),
    .i_data(i_line_o),

    // from the d_cache
    .data_read(d_read_i),
    .data_write(d_write_i),
    .data_addr(d_address_i),
    .data_wdata(d_line_i),
    .data_resp(d_resp_o),
    .data_out(d_line_o),

    // to l2_cache
    // .cache_resp(l2_resp_o),
    // .cache_data(l2_line_o),
    // .cache_read(l2_read_i),
    // .cache_write(l2_write_i),
    // .cache_addr(l2_address_i),
    // .cache_wdata(l2_line_i)

    // to line adaptor
    .cache_resp(resp_o),
    .cache_data(line_o),
    .cache_read(read_i),
    .cache_write(write_i),
    .cache_addr(address_i),
    .cache_wdata(line_i)
);

// l2_param_cache #(4, 8) l2_cache (
//     .clk(clk),
//     .rst(rst),
//     /* Physical memory signals */
//     .pmem_resp(resp_o),
//     .pmem_rdata(line_o),
//     .pmem_address(address_i),
//     .pmem_wdata(line_i),
//     .pmem_read(read_i),
//     .pmem_write(write_i),

//     /* l1 memory signals */
//     .mem_read(l2_read_i),
//     .mem_write(l2_write_i),
//     .mem_byte_enable(32'hFFFFFFFF),
//     .mem_address(l2_address_i),
//     .mem_wdata(l2_line_i),
//     .mem_resp(l2_resp_o),
//     .mem_rdata(l2_line_o)
// );

cacheline_adaptor cache_adaptor (
    .clk(clk),
    .reset_n(~rst),
    // Port to LLC (Lowest Level Cache)
    .line_i(line_i),
    .line_o(line_o),
    .address_i(address_i),
    .read_i(read_i),
    .write_i(write_i),
    .resp_o(resp_o),

    // Port to memory
    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);
endmodule : mp4
