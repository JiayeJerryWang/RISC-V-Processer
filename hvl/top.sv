`ifndef performance_itf
`define performance_itf

interface performance_counter_itf(input clk, input rst);
    logic halt;
    logic [6:0] br_op;
    logic mis_pred;
    logic stall;
    logic pmem_read;
    logic pmem_write;
    logic pmem_resp;
endinterface

`endif
//************************************************************//

module mp4_tb;
`timescale 1ns/10ps
import rv32i_types::*;



/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf(); 
rvfi_itf rvfi(itf.clk, itf.rst);
performance_counter_itf performance_counter (itf.clk, itf.rst);

logic commit;
assign commit = dut.cpu.datapath.commit;
logic [63:0] order;
initial order = 0;
always @(posedge itf.clk iff commit) order <= order + 1;
int timeout = 100000;   // Feel Free to adjust the timeout value
//assign itf.halt = dut.cpu.datapath.mem_wb_ctrl.opcode == op_br && (dut.cpu.datapath.br_en_wb && (dut.cpu.datapath.pc_mem_out == dut.cpu.datapath.alu_out_wb));
// assign itf.halt = (dut.cpu.datapath.pcmux_out == 32'h800000dc);

//performance counter signal
assign performance_counter.br_op = (dut.cpu.datapath.id_ex_ctrl.opcode == op_br);
assign performance_counter.mis_pred = dut.cpu.datapath.mis_predict;
assign performance_counter.halt = dut.cpu.datapath.mem_wb_ctrl.opcode == op_br && (dut.cpu.datapath.br_en_wb && (dut.cpu.datapath.pc_mem_out == dut.cpu.datapath.alu_out_wb));
assign performance_counter.stall = dut.cpu.datapath.all_stall;
assign performance_counter.pmem_read = dut.pmem_read;
assign performance_counter.pmem_write = dut.pmem_write;
assign performance_counter.pmem_resp = dut.pmem_resp;
//Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

//Dump signals
initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, mp4_tb, "+all");
end


always @(posedge itf.clk) begin
    if (itf.halt)
        $finish;
    if (timeout == 0) begin
        $display("TOP: Timed out");
        $finish;
    end
    timeout <= timeout - 1;
end

/****************************** End do not touch *****************************/



/***************************** Spike Log Printer *****************************/
// Can be enabled for debugging
spike_log_printer printer(.itf(itf), .rvfi(rvfi));
/*************************** End Spike Log Printer ***************************/


/************************ Signals necessary for monitor **********************/
// This section not required until CP2
assign rvfi.commit = dut.cpu.datapath.commit; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = dut.cpu.datapath.mem_wb_ctrl.opcode == op_br && (dut.cpu.datapath.br_en_wb && (dut.cpu.datapath.pc_mem_out == dut.cpu.datapath.alu_out_wb));; // Set high when target PC == Current PC for a branch
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

/*
Instruction and trap:
    rvfi.inst 
    rvfi.trap

Regfile:
    rvfi.rs1_addr
    rvfi.rs2_addr
    rvfi.rs1_rdata
    rvfi.rs2_rdata
    rvfi.load_regfile
    rvfi.rd_addr
    rvfi.rd_wdata

PC:
    rvfi.pc_rdata
    rvfi.pc_wdata

Memory:
    rvfi.mem_addr
    rvfi.mem_rmask
    rvfi.mem_wmask
    rvfi.mem_rdata
    rvfi.mem_wdata

Please refer to rvfi_itf.sv for more information.
*/

// Instruction and trap:
assign rvfi.inst = dut.cpu.datapath.rvfi_idata;
assign rvfi.trap = 1'b0;

// Regfile:
assign rvfi.rs1_addr = dut.cpu.datapath.mem_wb_ctrl.rs1;
assign rvfi.rs2_addr = dut.cpu.datapath.mem_wb_ctrl.rs2;
assign rvfi.rs1_rdata = dut.cpu.datapath.rvfi_rs1;
assign rvfi.rs2_rdata = dut.cpu.datapath.rvfi_rs2;
assign rvfi.load_regfile = dut.cpu.datapath.mem_wb_ctrl.Regwrite_en;
assign rvfi.rd_addr = dut.cpu.datapath.mem_wb_ctrl.rd ;
assign rvfi.rd_wdata = (dut.cpu.datapath.write_to_x0) ? 32'b0 : dut.cpu.datapath.regfilemux_out;

// PC:
assign rvfi.pc_rdata = dut.cpu.datapath.pc_mem_out;
assign rvfi.pc_wdata = dut.cpu.datapath.rvfi_pc_wdata;

// Memory:
assign rvfi.mem_addr = (dut.cpu.datapath.mem_wb_ctrl.mem_read || dut.cpu.datapath.mem_wb_ctrl.mem_write) ? dut.cpu.datapath.rvfi_data_addr : 32'b0;
assign rvfi.mem_rmask = (dut.cpu.datapath.mem_wb_ctrl.opcode == op_load) ? 4'b1111 : 4'b0;
assign rvfi.mem_wmask = (dut.cpu.datapath.mem_wb_ctrl.opcode == op_store) ? dut.cpu.datapath.rvfi_wmask : 4'b0 ;
assign rvfi.mem_rdata = dut.cpu.datapath.data_wb;
assign rvfi.mem_wdata = dut.cpu.datapath.rvfi_data_w;

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/
assign itf.inst_read = dut.i_mem_read;
assign itf.inst_addr = dut.i_mem_address;
assign itf.inst_resp = dut.i_resp;
assign itf.inst_rdata = dut.i_mem_rdata;

assign itf.data_read = dut.d_mem_read;
assign itf.data_write = dut.d_mem_write;
assign itf.data_mbe = dut.mem_byte_enable;
assign itf.data_addr = dut.d_mem_address;
assign itf.data_wdata = dut.cpu.datapath.data_w;
assign itf.data_resp = dut.d_resp;
assign itf.data_rdata = dut.cpu.datapath.data_r;

/*********************** End Shadow Memory Assignments ***********************/
// Set this to the proper value
assign itf.registers = dut.cpu.datapath.regfile.data;

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level for CP2:
Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/

perf_cnt perf_cnt(
    .itf(performance_counter)
);

mp4 dut(
    .clk(itf.clk),
    .rst(itf.rst),
    .pmem_read(itf.mem_read),
    .pmem_write(itf.mem_write),
    .pmem_wdata(itf.mem_wdata),
    .pmem_rdata(itf.mem_rdata),
    .pmem_address(itf.mem_addr),
    .pmem_resp(itf.mem_resp)
);

/***************************** End Instantiation *****************************/

endmodule

module perf_cnt(
    performance_counter_itf itf
);

// branch
int mispredict_count = 0;
int br_count = 0;

// pmem
int pmem_read_count = 0;
int pmem_write_count = 0;

// stall count
int stall_count = 0;

// clock cycle count
int clk_count = 0;

always @(posedge itf.clk ) begin
    if (itf.halt) begin
        $display(" ");
        $display("Performance counter:");
        $display("Clock cycle count: %0d", clk_count);
        $display("Stall cycle count: %0d", stall_count);
        $display("Pmem read cycle count: %0d", pmem_read_count);
        $display("Pmem write cycle count: %0d", pmem_write_count);
        $display("Branch count: %0d", br_count);
        $display("Branch mispredict count: %0d", mispredict_count);
        $display("Branch Correct prediction count: %0d", br_count-mispredict_count);
        $finish;
    end
end

always @(posedge itf.clk ) begin
    clk_count = clk_count + 1;
end

always @(negedge itf.clk ) begin
    if (~itf.stall) begin 
        stall_count = stall_count+1;
    end 
end

always @(negedge itf.clk ) begin
    if (~itf.rst && itf.stall && (~itf.halt)) begin 
        if (itf.mis_pred) begin 
            mispredict_count = mispredict_count+1;
        end 
        if (itf.br_op && itf.stall&& (~itf.halt)) begin
            br_count = br_count+1;
        end 
    end 
end

always @(posedge itf.clk) begin
    if (~itf.rst && (itf.pmem_read || itf.pmem_write)) begin 
        if (itf.pmem_read) begin
            pmem_read_count++;
        end
        if (itf.pmem_write) begin
            pmem_write_count++;
        end
    end 
end

endmodule