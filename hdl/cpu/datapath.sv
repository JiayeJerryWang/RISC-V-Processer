module datapath
import rv32i_types::*;
(
    input clk,
    input rst,
    /* You will need to connect more signals to your datapath module*/
    
   
    //--------I-cache signal---------//
    input rv32i_word i_data,
    output rv32i_word i_addr,
    
    //--------D-cache signal--------//
    input rv32i_word data_r,
    output rv32i_word data_address,
    output rv32i_word data_w, 
    output logic [3:0] data_mem_byte_enable,
    output logic data_read,
    output logic data_write,
    input logic data_resp,

    //--------control rom to datapath---------//
    input rv32i_control_word ctrl,

    //--------datapath to control rom--------//
    output logic br_en,
    output rv32i_opcode opcode,
    output logic[4:0] rs1, //when to store this value in struct
    output logic[4:0] rs2,
    output logic[4:0] rd,
    output logic[2:0] funct3,
    output logic[6:0] funct7,

    //--------datapath to hazard control unit-------//
    input logic stall_pc,
    input logic stall_datamem,

    //--------datapath to RVFI-------//
    output logic commit,

    //--------datapath to prefetcher-------//
    output logic [31:0] prefetch_pc
);



/************************** Signals ********************************/
//PC
rv32i_word pc_if_out;
rv32i_word pc_if_in;
rv32i_word pc_id_out;
rv32i_word pc_ex_out;
logic[31:0] pc_mem_out;
logic[31:0] pcmux_out;
logic load_pc;
rv32i_word pc_wdata;
rv32i_word pc_wdata_id_ex;
rv32i_word pc_wdata_ex_mem;
rv32i_word pc_wdata_mem_wb;
rv32i_word rvfi_pc_wdata;
rv32i_word pc_wdata_mux_out;

//RegFile
logic reg_resp;
rv32i_word regfilemux_out;
rv32i_word regfile_u_imm;
rv32i_word rs1_out;
rv32i_word rs2_out;

//instruction
rv32i_word i_data_id_ex;
rv32i_word i_data_ex_mem;
rv32i_word i_data_mem_wb;
rv32i_word rvfi_idata;

//Data memory
rv32i_word data_wb;
rv32i_word unshift_wdata;
logic [1:0] shift;
logic [1:0] ex_mem_shift;
rv32i_word mem_rdatamux_out;

//ALU
alu_ops aluop;
rv32i_word alumux1;
rv32i_word alumux2;
rv32i_word alu_mux_1_out;
rv32i_word alu_mux_2_out;
rv32i_word alu_out;
rv32i_word alu_out_mem;
rv32i_word alu_out_wb;
rv32i_word data_addr;

//CMP
branch_funct3_t cmpop;
rv32i_word cmpmux_in;
rv32i_word cmpmux_out;
logic br_en_mem;
logic br_en_wb;

//decoder
rv32i_word i_imm;
rv32i_word s_imm;
rv32i_word b_imm;
rv32i_word u_imm;
rv32i_word j_imm;
rv32i_word id_ex_imm;
rv32i_word mem_u_imm;
rv32i_word wb_u_imm;
rv32i_word cmp_rs1;
rv32i_word cmp_rs2;

//ctrl
rv32i_control_word id_ex_ctrl;
rv32i_control_word ex_mem_ctrl;
rv32i_control_word mem_wb_ctrl;

//forwarding unit
rv32i_word forward1_out;
rv32i_word forward2_out;
rv32i_word forward3_out;
rv32i_word forward4_out;
rv32i_word forward5_out;

//flush signal
logic rst_flush;
logic flush;
logic rst_flush_id_ex;

//stall signal
logic stall_ex_mem;
logic stall_mem_wb;
logic flush_stall;
logic all_stall;
logic regfile_stall;
logic pc_reg_load;
logic ex_reg_load;
logic wb_reg_load;
logic wb_regfile_load;

//branch predictor 
logic pred_result;
rv32i_word pc_reg_input;

//btb
logic btb_hit;
rv32i_word pred_pc;
logic decode_btb;
logic exe_btb;

//RVFI
rv32i_word ex_mem_rs1;
rv32i_word ex_mem_rs2;
rv32i_word rvfi_ex_mem_rs1;
rv32i_word rvfi_ex_mem_rs2;
rv32i_word rvfi_rs1;
rv32i_word rvfi_rs2;
rv32i_word rvfi_data_w;
logic write_to_x0;
rv32i_word rvfi_data_addr;
logic [4:0] id_ex_wmask;
logic [4:0] ex_mem_wmask;
logic [4:0] rvfi_wmask;


//misprediction calculate
logic mis_predict;
logic [31:0] prefetch_pc_addr;
/*****************************************************************/

/************************** Muxes ********************************/
//PC mux
pcmux::pcmux_sel_t pcmux_sel;
pc_wdata_mux::pc_wdata_sel_t pc_wdata_sel;

//ALU mux
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;

//Regfile mux
regfilemux::regfilemux_sel_t regfilemux_sel;

//CMP mux
cmpmux::cmpmux_sel_t cmpmux_sel;

//MEMRDATA mux
mem_rdatamux::mem_rdatamux_sel_t mem_rdata_sel;

//forwarding mux
forward1mux::forward1mux_sel_t forward1_sel;
forward2mux::forward2mux_sel_t forward2_sel;
forward3mux::forward3mux_sel_t forward3_sel;
forward4mux::forward4mux_sel_t forward4_sel;
forward5mux::forward5mux_sel_t forward5_sel;
/*****************************************************************************/

/************************** Signal assignment ********************************/
assign prefetch_pc =  prefetch_pc_addr;
//stall
assign all_stall = stall_pc && stall_datamem && stall_ex_mem && stall_mem_wb;
assign flush_stall = stall_pc && stall_datamem && stall_ex_mem && stall_mem_wb && (!rst_flush);
assign regfile_stall= all_stall && mem_wb_ctrl.Regwrite_en;

//flush
assign rst_flush = (rst || ((((br_en!= exe_btb) && (id_ex_ctrl.opcode == op_br)) || (id_ex_ctrl.opcode == op_jal) || (id_ex_ctrl.opcode == op_jalr)) && (all_stall)));
assign rst_flush_id_ex = rst_flush && (stall_datamem);

//ALU
assign aluop = id_ex_ctrl.aluop;
assign alumux1_sel = ctrl.alumux1_sel;
assign alumux2_sel = ctrl.alumux2_sel;

//CMP
assign cmpmux_sel = id_ex_ctrl.cmpmux_sel;
assign cmpop = id_ex_ctrl.cmpop;

//Regfile
assign regfilemux_sel = mem_wb_ctrl.regfilemux_sel;

//instruction memory signal
assign i_addr = pc_if_in; //use mux out or PC register out

//data memory signal
assign shift = alu_out_wb[1:0];
assign ex_mem_shift = data_addr[1:0];
assign data_address = (data_addr & 32'hFFFFFFFC);
assign data_read = ex_mem_ctrl.mem_read;
assign data_write = ex_mem_ctrl.mem_write;
assign data_mem_byte_enable = (ex_mem_ctrl.mem_byte_enable << data_addr[1:0]);
assign data_w = unshift_wdata << (8 * data_addr[1:0]);

//rvfi signal
assign rvfi_data_addr = alu_out_wb ;
assign commit = (wb_reg_load || wb_regfile_load) && (mem_wb_ctrl.opcode != 7'b0000000) && (pc_ex_out != pc_mem_out); //active high
assign pc_wdata = pc_if_in + 3'b100;
assign write_to_x0 = (mem_wb_ctrl.rd == 5'b0);

//misprediction
assign mis_predict = ((br_en!= exe_btb) && (id_ex_ctrl.opcode == op_br)) ? 1'b1 : 1'b0;

//mem_rdatamux
assign mem_rdata_sel = ex_mem_ctrl.mem_rdatamux_sel;
/*****************************************************************************/

/**********************************Fetch *******************************************/
pc_register PC_register(
    .clk(clk),
    .rst(rst),
    .load(pc_reg_load),
    .in(pc_reg_input),
    .out(pc_if_in)
);

always_comb begin: pc_input
    if(pred_result && btb_hit && ~rst_flush) begin 
        pc_reg_input = pred_pc;
    end
    else begin 
        pc_reg_input = pcmux_out;
    end
end

/************************************************* Registers ***************************************************/
//---------------------------------------------------IF_ID-----------------------------------------------------//
ir decoder(
    .clk (clk),
    .rst (rst_flush),
    .load (all_stall),
    .in (i_data),
    .funct3 (funct3),
    .funct7 (funct7),
    .opcode (opcode),
    .i_imm  (i_imm),
    .s_imm  (s_imm),
    .b_imm  (b_imm),
    .u_imm  (u_imm),
    .j_imm  (j_imm),
    .rs1    (rs1),
    .rs2    (rs2),
    .rd     (rd)
);

pc_register IF_ID_pc(
    .clk(clk),
    .rst(rst_flush),
    .load(all_stall),
    .in(pc_if_in),
    .out(pc_if_out)
);

register IF_ID_idata(
    .clk(clk),
    .rst(rst_flush),
    .load(all_stall),
    .in(i_data),
    .out(i_data_id_ex)
);

register #($bits(decode_btb)) IF_ID_btb(
	.clk (clk),
    .rst (rst_flush),
    .load (all_stall),
 	.in (btb_hit && pred_result),     	
    .out (decode_btb)
);

//-----------------------------------------------------ID_EX------------------------------------------------------------------//
register #($bits(ctrl)) ID_EX_ctrl(
    .clk(clk),
    .rst(rst_flush_id_ex),
    .load(all_stall),
    .in(ctrl),
    .out(id_ex_ctrl)
);

pc_register ID_EX_pc(
    .clk(clk),
    .rst(rst_flush_id_ex),
    .load(all_stall),
    .in(pc_if_out),
    .out(pc_id_out)
);

pc_register ID_EX_pc_wdata(
    .clk(clk),
    .rst(rst_flush_id_ex),
    .load(all_stall),
    .in(pc_wdata_id_ex),
    .out(pc_wdata_ex_mem)
);


register ID_EX_idata(
    .clk(clk),
    .rst(rst_flush_id_ex),
    .load(all_stall),
    .in(i_data_id_ex),
    .out(i_data_ex_mem)
);

register ID_EX_alumux1(
	.clk (clk),
    .rst (rst_flush_id_ex),
    .load (all_stall),
 	.in (alu_mux_1_out),     	
    .out (alumux1)
);

register ID_EX_alumux2(
	.clk (clk),
    .rst (rst_flush_id_ex),
    .load (all_stall),
 	.in (alu_mux_2_out),     	
    .out (alumux2)
);

register ID_EX_i_imm(
	.clk (clk),
    .rst (rst_flush_id_ex),
    .load (all_stall),
 	.in (i_imm),     	
    .out (cmpmux_in)
);

register ID_EX_u_imm(
	.clk (clk),
    .rst (rst_flush_id_ex),
    .load (all_stall),
 	.in (u_imm),     	
    .out (mem_u_imm)
);


register ID_EX_rs1(
	.clk (clk),
    .rst (rst_flush_id_ex),
    .load (all_stall),
 	.in (rs1_out),     	
    .out (cmp_rs1)
);

register ID_EX_rs2(
	.clk (clk),
    .rst (rst_flush_id_ex),
    .load (all_stall),
 	.in (rs2_out),     	
    .out (cmp_rs2)
);


register  #($bits(decode_btb)) ID_EX_btb(
	.clk (clk),
    .rst (rst_flush),
    .load (all_stall),
 	.in (decode_btb),     	
    .out (exe_btb)
);

//---------------------------------------------EX_MEM---------------------------------------------------//
register #($bits(ctrl)) EX_MEM_ctrl(
    .clk(clk),
    .rst(rst),
    .load(ex_reg_load),
    .in(id_ex_ctrl),
    .out(ex_mem_ctrl)
);

pc_register EX_MEM_pc(
    .clk(clk),
    .rst(rst),
    .load(ex_reg_load),
    .in(pc_id_out),
    .out(pc_ex_out)
);

pc_register EX_MEM_pc_wdata(
    .clk(clk),
    .rst(rst),
    .load(ex_reg_load),
    .in(pc_wdata_mux_out),
    .out(pc_wdata_mem_wb)
);


register EX_MEM_idata(
    .clk(clk),
    .rst(rst),
    .load(ex_reg_load),
    .in(i_data_ex_mem),
    .out(i_data_mem_wb)
);

register EX_MEM_aluout(
    .clk(clk),
    .rst(rst),
    .load(ex_reg_load),
    .in(alu_out),
    .out(data_addr) //addr to D-cache
);

register EX_MEM_u_imm(
	.clk (clk),
    .rst (rst),
    .load (ex_reg_load),
 	.in (mem_u_imm),     	
    .out (wb_u_imm)
);

register #($bits(br_en)) EX_MEM_br_en(
	.clk (clk),
    .rst (rst),
    .load (ex_reg_load),
    .in (br_en),
    .out (br_en_mem)
);

register EX_MEM_rs1(
	.clk (clk),
    .rst (rst),
    .load (ex_reg_load),
 	.in ((id_ex_ctrl.opcode == op_br) ? forward4_out : forward1_out),     	
    .out (ex_mem_rs1)
);

register EX_MEM_RS2(
	.clk (clk),
    .rst (rst),
    .load (ex_reg_load),
 	.in (forward5_out),     	
    .out (ex_mem_rs2)
);

register EX_MEM_wdata(
	.clk (clk),
    .rst (rst),
    .load (ex_reg_load),
 	.in (forward3_out),     	
    .out (unshift_wdata)
);

register #($bits(id_ex_wmask)) EX_MEM_wmask(
	.clk (clk),
    .rst (rst),
    .load (ex_reg_load),
 	.in (id_ex_wmask),     	
    .out (ex_mem_wmask)
);

//---------------------------------MEM_WB-----------------------------------------//
register #($bits(ctrl)) MEM_WB_ctrl(
    .clk(clk),
    .rst(rst),
    .load(wb_reg_load),
    .in(ex_mem_ctrl),
    .out(mem_wb_ctrl)
);

pc_register MEM_WB_pc(
    .clk(clk),
    .rst(rst),
    .load(wb_reg_load),
    .in(pc_ex_out),
    .out(pc_mem_out)
);

pc_register MEM_WB_pc_wdata(
    .clk(clk),
    .rst(rst),
    .load(wb_reg_load),
    .in(pc_wdata_mem_wb),
    .out(rvfi_pc_wdata)
);

register MEM_WB_idata(
    .clk(clk),
    .rst(rst),
    .load(wb_reg_load),
    .in(i_data_mem_wb),
    .out(rvfi_idata)
);

register MEM_WB_u_imm(
	.clk (clk),
    .rst (rst),
    .load (wb_reg_load),
 	.in (wb_u_imm),     	
    .out (regfile_u_imm)
);

register #($bits(br_en)) MEM_WB_br_en(
    .clk (clk),
    .rst (rst),
    .load (wb_reg_load),
    .in (br_en_mem),
    .out (br_en_wb) 
);

register MEM_WB_aluout(
    .clk (clk),
    .rst (rst),
    .load (wb_reg_load),
    .in (data_addr),
    .out (alu_out_wb) 
);

register MEM_WB_mem_rdata(
	.clk (clk),
    .rst (rst),
    .load (data_resp && wb_reg_load),
    .in (data_r),
    .out (data_wb)
);

register EX_MEM_mem_wdata(
	.clk (clk),
    .rst (rst),
    .load (wb_reg_load),
 	.in (data_w),     	
    .out (rvfi_data_w)
);

register MEM_WB_rs1(
	.clk (clk),
    .rst (rst),
    .load (wb_reg_load),
 	.in (ex_mem_rs1),
    .out (rvfi_rs1)
);

register MEM_WB_rs2(
	.clk (clk),
    .rst (rst),
    .load (wb_reg_load),
    .in (ex_mem_rs2),
    .out (rvfi_rs2)
);

regfile regfile(
    .clk (clk),
    .rst (rst),
    .load (wb_regfile_load),
    .in (regfilemux_out),
    .src_a (ctrl.rs1),
    .src_b (ctrl.rs2),
    .dest (mem_wb_ctrl.rd),
    .reg_a (rs1_out),
    .reg_b (rs2_out),
    .reg_resp (reg_resp)
);

register #($bits(ex_mem_wmask)) MEM_WB_wmask(
	.clk (clk),
    .rst (rst),
    .load (wb_reg_load),
 	.in (ex_mem_wmask),     	
    .out (rvfi_wmask)
);
/****************************************************************************************************/

/******************************* ALU / CMP / FORWARDING / BRprediction *********************************/
alu ALU (
	.aluop (aluop),
	.a (forward1_out), //alumux1
	.b (forward2_out), //alumux2
	.f (alu_out)
);

branch CMP(
    .s1(forward4_out),
    .s2(forward5_out),
    .cmpop(cmpop),
    .br_en(br_en)
);

forwarding forward(
    .rs1(id_ex_ctrl.rs1), //id_ex
    .rs2(id_ex_ctrl.rs2),
    .ex_mem_rs1 (ex_mem_ctrl.rs1),
    .ex_mem_rs2 (ex_mem_ctrl.rs2),
    .rd_ex_mem(ex_mem_ctrl.rd),
    .rd_mem_wb(mem_wb_ctrl.rd),
    .reg_ex_mem(ex_mem_ctrl.Regwrite_en),
    .reg_mem_wb(mem_wb_ctrl.Regwrite_en),
    .ctrl_opcode(id_ex_ctrl.opcode),
    .ex_mem_ctrl_opcode(ex_mem_ctrl.opcode),
    .id_ex_alumux1_sel(id_ex_ctrl.alumux1_sel),
    .id_ex_alumux2_sel(id_ex_ctrl.alumux2_sel),
    .mem_write_id_ex(id_ex_ctrl.mem_write),
    .mem_write_ex_mem(ex_mem_ctrl.mem_write),
    .mem_read_ex_mem(ex_mem_ctrl.mem_read),
    .data_mem_resp(data_resp),
    .f1(forward1_sel),
    .f2(forward2_sel),
    .f3(forward3_sel),
    .f4(forward4_sel),
    .f5(forward5_sel),
    .stall_ex_mem(stall_ex_mem),
    .stall_mem_wb(stall_mem_wb),
    .mem_read_mem_wb(mem_wb_ctrl.mem_read)
);


// pattern_hist_t #(.phtidx(4))
// local_predictor (
//     .clk(clk),
//     .rst(rst),
//     .pht_r_idx(pc_if_in[6:3]),
//     .pht_w_idx(pc_id_out[6:3]),
//     .br_en(br_en),
//     .opcode(i_data[6:0]),
//     .update_pht(id_ex_ctrl.opcode==op_br&& all_stall),
//     .pred_result(pred_result),
//     .mis_predict()
// );


// global_branch_predictor  #(.idx_offset(5),.idx_length(5), .bht_length(5)) 
// global_branch_predictor
// (
//   .clk(clk),
//   .rst(rst),
//   .global_pred_update(id_ex_ctrl.opcode==op_br && all_stall),
//   .br_en(br_en),
//   .pc_fetch(pc_if_in),
//   .pc_exe(pc_id_out),
//   .opcode (i_data[6:0]),
//   .br_result(pred_result),
//   .mis_predict()
// );

tournament_predictor  #(.idx_offset(5),.idx_length(5)) 
tournament_predictor
(
  .clk(clk),
  .rst(rst),
  .tournament_update(id_ex_ctrl.opcode==op_br && all_stall),
  .br_en(br_en),
  .pc_addr_fetch(pc_if_in),
  .pc_addr_ex(pc_id_out),
  .opcode (i_data[6:0]),
  .tournament_pred_result(pred_result),
  .all_stall(all_stall)
);

btb #(.btb_idx(5))
branch_target_buffer (
    .clk(clk),
    .rst(rst),
    .update_btb(id_ex_ctrl.opcode == op_br && all_stall),
    .br_en(br_en),
    .pc_addr_if(pc_if_in),
    .pc_addr_ex(pc_id_out),
    .br_addr(alu_out),
    .btb_hit(btb_hit),
    .pred_pc(pred_pc)
);


/***************************************Prefetch logic**************************************/
always_comb begin: Prefetch_PC
    if ((ex_mem_ctrl.opcode == op_load)) begin
        prefetch_pc_addr = pc_ex_out;
    end
    else begin
        prefetch_pc_addr = prefetch_pc;
    end
end

/***************************************pc stall logic**************************************/
always_comb begin: ID_PC
    if(((id_ex_ctrl.opcode == op_br) || (id_ex_ctrl.opcode == op_jal) || (id_ex_ctrl.opcode == op_jalr)) && rst_flush && (!all_stall)) begin 
        if ((pc_if_in != pcmux_out)) begin 
            pc_reg_load = 1'b1;
        end
        else begin 
            pc_reg_load = all_stall;
        end
    end
    else begin 
        pc_reg_load = all_stall;
    end
end

/***************************************ex mem stall logic**************************************/
always_comb begin: EX_MEM_stall_logic
    if(((id_ex_ctrl.opcode == op_br) || (id_ex_ctrl.opcode == op_jal) || (id_ex_ctrl.opcode == op_jalr)) && rst_flush && (!all_stall) && (stall_datamem)) begin 
        if ((pc_id_out != pc_ex_out) || (id_ex_ctrl != ex_mem_ctrl) || (alu_out != data_addr) 
        || (pc_wdata_mux_out != pc_wdata_mem_wb) || (mem_u_imm != wb_u_imm) || (br_en != br_en_mem) 
        || (((id_ex_ctrl.opcode == op_br) ? forward4_out : forward1_out) != ex_mem_rs1) 
        || (forward5_out != ex_mem_rs2) || (forward3_out != unshift_wdata) || (id_ex_wmask != ex_mem_wmask)) begin 
            ex_reg_load = 1'b1;
        end
        else begin 
            ex_reg_load = all_stall;
        end
    end
    else begin 
        ex_reg_load = all_stall;
    end
end

/***************************************mem wb stall logic**************************************/
always_comb begin: MEM_WB_stall_logic
    if(((id_ex_ctrl.opcode == op_br) || (id_ex_ctrl.opcode == op_jal) || (id_ex_ctrl.opcode == op_jalr)) && rst_flush && (!all_stall)) begin 
        if ((pc_mem_out != pc_ex_out) || (mem_wb_ctrl != ex_mem_ctrl) || (pc_wdata_mem_wb != rvfi_pc_wdata)
         || (i_data_mem_wb != rvfi_idata) || (wb_u_imm != regfile_u_imm) || (br_en_mem != br_en_wb)
         || (data_addr != alu_out_wb) || (data_w != rvfi_data_w) || (ex_mem_rs1 != rvfi_rs1) || (ex_mem_wmask != rvfi_wmask)) begin
            wb_reg_load = 1'b1;
        end
        else begin 
            wb_reg_load = all_stall;
        end
    end
    else begin 
        wb_reg_load = all_stall;
    end
end

/***************************************regfile stall logic**************************************/
always_comb begin: WB_REG
    if(((id_ex_ctrl.opcode == op_br) || (id_ex_ctrl.opcode == op_jal) || (id_ex_ctrl.opcode == op_jalr)) && rst_flush && (!all_stall)) begin
        if ((mem_wb_ctrl.Regwrite_en == 1)) begin
            wb_regfile_load = 1'b1;
        end
        else begin
            wb_regfile_load = regfile_stall;
        end
    end

    else begin 
        wb_regfile_load = regfile_stall;
    end
end

/******************************** Muxes **************************************/
always_comb begin: PC_SEL
    if (all_stall == 1'b1) begin
        if (id_ex_ctrl.opcode == op_br)  begin 
            //predict: br not take actual:br take
            if (br_en == 1'b1 && exe_btb== 1'b0) begin 
                pcmux_sel = pcmux::alu_out;
            end
            //predict: br take actual:br not take
            else if (br_en == 1'b0 && exe_btb== 1'b1) begin 
                pcmux_sel = pcmux::pc_exe_plus4;
            end

            else begin 
                pcmux_sel = pcmux::pc_plus4;
            end

        end 

        else if ((id_ex_ctrl.opcode == op_jal) || (id_ex_ctrl.opcode == op_jalr))  begin     
            pcmux_sel = pcmux::alu_mod2;
        end
        else begin
            pcmux_sel = pcmux::pc_plus4;
        end
    end

    else begin 
        pcmux_sel = pcmux::pc_plus4;
    end
end

always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog. 
    pcmux_out = pc_if_in + 4;
    unique case (pcmux_sel)
        pcmux::pc_plus4: begin 
            pcmux_out = pc_if_in + 4; // last_pc + 4 
            load_pc = 1'b1;
        end

        pcmux::alu_out: begin 
            pcmux_out = alu_out; 
            load_pc = 1'b1;
        end

        pcmux::alu_mod2: begin 
            pcmux_out = {alu_out[31:1], 1'b0}; 
            load_pc = 1'b1;
        end
        
        pcmux::pc_exe_plus4: begin 
            pcmux_out = pc_id_out +4; 
            load_pc = 1'b1;
        end

    endcase

    unique case(cmpmux_sel)
        cmpmux::rs2_out: cmpmux_out = cmp_rs2;
        cmpmux::i_imm: cmpmux_out = cmpmux_in;
        //default: ;
    endcase

    unique case(alumux1_sel)
        alumux::rs1_out: alu_mux_1_out = rs1_out; //comes from regfile?????
        alumux::pc_out: alu_mux_1_out = pc_if_out;
        default: ;
    endcase

    unique case(alumux2_sel)
        alumux::i_imm: alu_mux_2_out = i_imm;
        alumux::u_imm: alu_mux_2_out = u_imm;
        alumux::b_imm: alu_mux_2_out = b_imm;
        alumux::s_imm: alu_mux_2_out = s_imm;
        alumux::j_imm: alu_mux_2_out = j_imm; 
        alumux::rs2_out: alu_mux_2_out = rs2_out;//use regfile output or IR output
        //default: ;
    endcase

    unique case(regfilemux_sel) 
        regfilemux::alu_out: regfilemux_out = alu_out_wb; //
        regfilemux::br_en: regfilemux_out = {31'b0, br_en_wb};
        regfilemux::u_imm: regfilemux_out = regfile_u_imm;
        regfilemux::lw: regfilemux_out = data_wb;
        regfilemux::pc_plus4: regfilemux_out = pc_mem_out + 4;
        regfilemux::lb: begin 
            regfilemux_out = 32'($signed(data_wb[shift*8 +: 8])); 
        end
        regfilemux::lbu: begin 
            regfilemux_out = {24'b0,data_wb[shift*8 +: 8]};
        end
        regfilemux::lh: begin
            regfilemux_out = 32'($signed(data_wb[shift*8 +: 16])); 
        end
        regfilemux::lhu: begin 
            regfilemux_out = {16'b0,data_wb[shift*8+: 16]}; 
        end
    endcase

    unique case(mem_rdata_sel) 
        mem_rdatamux::alu_out: mem_rdatamux_out = data_addr; //
        mem_rdatamux::br_en: mem_rdatamux_out = {31'b0, br_en_mem};
        mem_rdatamux::u_imm: mem_rdatamux_out = wb_u_imm;
        mem_rdatamux::lw: mem_rdatamux_out = data_r;
        mem_rdatamux::pc_plus4: mem_rdatamux_out = pc_ex_out + 4;
        mem_rdatamux::lb: begin 
            mem_rdatamux_out = 32'($signed(data_r[ex_mem_shift*8 +: 8])); 
        end
        mem_rdatamux::lbu: begin 
            mem_rdatamux_out = {24'b0,data_r[ex_mem_shift*8 +: 8]};
        end
        mem_rdatamux::lh: begin
            mem_rdatamux_out = 32'($signed(data_r[ex_mem_shift*8 +: 16])); 
        end
        mem_rdatamux::lhu: begin 
            mem_rdatamux_out = {16'b0,data_r[ex_mem_shift*8+: 16]}; 
        end
    endcase

    unique case(forward1_sel)
        forward1mux::stay:  forward1_out = alumux1; 
        forward1mux::forward1:  forward1_out = data_addr; 
        forward1mux::forward2:  forward1_out = regfilemux_out; 
        forward1mux::forward3:  forward1_out = mem_rdatamux_out; 
    endcase

    unique case(forward2_sel)
        forward2mux::stay:  forward2_out = alumux2; 
        forward2mux::forward1:  forward2_out = data_addr; 
        forward2mux::forward2:  forward2_out = regfilemux_out; 
        forward2mux::forward3:  forward2_out = mem_rdatamux_out; 
    endcase 
    
    unique case(forward3_sel)
        forward3mux::stay: forward3_out = cmp_rs2; 
        forward3mux::forward1: forward3_out = regfilemux_out; 
        forward3mux::forward2: forward3_out = data_addr; 
    endcase 

    unique case(forward4_sel)
        forward4mux::stay:  forward4_out = cmp_rs1; 
        forward4mux::forward1:  forward4_out = data_addr;
        forward4mux::forward2:  forward4_out = regfilemux_out; 
        forward4mux::forward3:  forward4_out = mem_rdatamux_out; 
    endcase 

    unique case(forward5_sel)
        forward5mux::stay:  forward5_out = cmpmux_out; 
        forward5mux::forward1:  forward5_out = data_addr; 
        forward5mux::forward2:  forward5_out = regfilemux_out; 
        forward5mux::forward3:  forward5_out = mem_rdatamux_out; 
    endcase 

    unique case(pc_wdata_sel)
        pc_wdata_mux::plus4:  pc_wdata_mux_out = pc_wdata_ex_mem; 
        pc_wdata_mux::br:  pc_wdata_mux_out = alu_out;
    endcase
end

always_comb begin: MASK
    if (id_ex_ctrl.opcode == op_store)  begin 
        id_ex_wmask =  id_ex_ctrl.mem_byte_enable << (alu_out[1:0]);
    end
    else begin
        id_ex_wmask = id_ex_ctrl.mem_byte_enable;
    end
end
endmodule : datapath
/*****************************************************************************/

module pc_wdata_mod
import rv32i_types::*;
(
    input logic br_en,
    input rv32i_opcode id_ex_ctrl_opcode,
    output pc_wdata_mux::pc_wdata_sel_t pc_wdata_sel
);


always_comb begin
    if(id_ex_ctrl_opcode == op_br && br_en) begin 
        pc_wdata_sel = 1'b1;
    end
    else begin 
        pc_wdata_sel = 1'b0;
    end
end
endmodule: pc_wdata_mod
