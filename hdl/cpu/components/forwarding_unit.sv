module forwarding
import rv32i_types::*;
(

    input logic[4:0] rd_ex_mem,
    input logic[4:0] rd_mem_wb,
    input logic reg_ex_mem,
    input logic reg_mem_wb,
    input logic mem_write_id_ex,
    input logic mem_write_ex_mem,
    input logic mem_read_ex_mem,
    input logic mem_read_mem_wb,
    input logic [4:0]rs1,
    input logic [4:0]rs2,
    input logic [4:0] ex_mem_rs1,
    input logic [4:0] ex_mem_rs2,
    input logic data_mem_resp,
    input rv32i_opcode ctrl_opcode,
    input rv32i_opcode ex_mem_ctrl_opcode,
    input alumux::alumux1_sel_t id_ex_alumux1_sel,
    input alumux::alumux2_sel_t id_ex_alumux2_sel,
    output forward1mux::forward1mux_sel_t f1,
    output forward2mux::forward2mux_sel_t f2,
    output forward3mux::forward3mux_sel_t f3,
    output forward4mux::forward4mux_sel_t f4,
    output forward5mux::forward5mux_sel_t f5,
    output logic stall_ex_mem,
    output logic stall_mem_wb
);

logic[1:0] forward1_sel;
logic[1:0] forward2_sel;
logic [1:0]forward3_sel;
logic [1:0]forward4_sel;
logic [1:0]forward5_sel;
assign f1 = forward1_sel;
assign f2 = forward2_sel;
assign f3 = forward3_sel;
assign f4 = forward4_sel;
assign f5 = forward5_sel;

//-----------------------------------------------------------------------------------------------------------------------
always_comb begin: FORWARD1
    if (id_ex_alumux1_sel == 1'b0) begin
        //case1: forwarding EX/MEM ALU_OUT to alumux1, data from ALU
        if(rd_ex_mem != 5'b0 && rd_ex_mem == rs1 && reg_ex_mem && mem_read_ex_mem == 1'b0) begin
            if(ex_mem_ctrl_opcode==op_lui)begin
                forward1_sel=2'b11;
            end
            
            else begin
            forward1_sel = 2'b01; //forward 1
            end
            stall_ex_mem = 1'b1;
        end
        //case3:  forwarding reg_filemux_out to alumux1, data from mem           (SW-->     LW-->  (BaseR match)          rs1:base, rs2:src)    
        else if (rd_ex_mem != 5'b0 && (rd_ex_mem == rs1 && (rd_ex_mem != rs2 && (reg_ex_mem && (mem_write_id_ex && mem_read_ex_mem)))))begin 
            if (data_mem_resp) begin //data_resp happen on next cycle
                forward1_sel = 2'b11; //stall until data_resp, forwarding reg_filemux_out to ALU_mux_1
                stall_ex_mem = 1'b1; 
            end
            else begin 
                forward1_sel = 2'b00; 
                stall_ex_mem = 1'b0; //stall everything before execute
            end
        end
        else if (rd_ex_mem != 5'b0 && rd_ex_mem == rs1 && reg_ex_mem && mem_read_ex_mem)begin 
            if (data_mem_resp) begin //data_resp happen on next cycle
                forward1_sel = 2'b11; //stall until && mem_read_ex_mem == 1'b0data_resp, forwarding reg_filemux_out to ALU_mux_1
                stall_ex_mem = 1'b1; 
            end
            else begin 
                forward1_sel = 2'b00; 
                stall_ex_mem = 1'b0; //stall everything before execute
            end
        end
        //case2: forwarding reg_filemux_out to alumux1, data from ALU or data_mem 
        else if(rd_mem_wb != 5'b0 && rd_mem_wb == rs1 && reg_mem_wb && (mem_read_mem_wb == 1'b0 || mem_read_mem_wb == 1'b1)) begin
            forward1_sel = 2'b10; //forward 2
            stall_ex_mem = 1'b1;
        end
        else begin 
            forward1_sel = 2'b00; 
            stall_ex_mem = 1'b1;
        end
    end
    else begin 
        forward1_sel = 2'b00; 
        stall_ex_mem = 1'b1;
    end

//----------------------------------------------------------------------------------------------------
    if (id_ex_alumux2_sel == 3'b101) begin
        //case3: forwarding EX/MEM ALU_OUT to alumux2, data from ALU
        if(rd_ex_mem != 5'b0 && rd_ex_mem == rs2 && reg_ex_mem && mem_read_ex_mem == 1'b0) begin
            forward2_sel = 2'b01; //forward 1
        end
        //case5: forwarding MEM/WB mem_rdata to alumux2, data from ALU
        else if (rd_ex_mem != 5'b0 && rd_ex_mem == rs2 && reg_ex_mem && mem_read_ex_mem)begin 
            if (data_mem_resp) begin //data_resp happen on next cycle
                forward2_sel = 2'b11; //stall until && mem_read_ex_mem == 1'b0data_resp, forwarding reg_filemux_out to ALU_mux_2
                stall_ex_mem = 1'b1; 
            end
            else begin 
                forward2_sel = 2'b00; 
                stall_ex_mem = 1'b0; //stall everything before execute
            end
        end
        //case4: forwarding MEM/WB ALU_OUT to alumux2, data from ALU
        else if(rd_mem_wb != 5'b0 && rd_mem_wb == rs2 && reg_mem_wb && mem_read_mem_wb == 1'b0)begin
            forward2_sel = 2'b10; //forward 2
        end
        else begin
            forward2_sel = 2'b00;
        end
    end
    else begin
        forward2_sel = 2'b00;
    end
end
//-----------------------------------------------------------------------------------------------------------
always_comb begin: FORWARD3
    // SW-->     Lb-->  (DataR match)          rs1:base, rs2:src
    if (rd_ex_mem != 5'b0 && (rd_ex_mem != rs1 && (rd_ex_mem == rs2 && (reg_ex_mem && (mem_write_id_ex && mem_read_ex_mem)))))begin 
        if(data_mem_resp) begin //data_resp happen on next cycle
            forward3_sel = 2'b01; //stall until data_resp
            stall_mem_wb = 1'b1; 
        end
        else begin 
            forward3_sel = 2'b00; //forward reg_filemux_out to cmp_rs2
            stall_mem_wb = 1'b0; //stall everything before EXE_Mem
        end
    end

    else if (rd_ex_mem != 5'b0 && (rd_ex_mem != rs1 && (rd_ex_mem == rs2 && (reg_ex_mem && (mem_write_id_ex)))))begin 
            forward3_sel = 2'b10; //stall until data_resp
            stall_mem_wb = 1'b1; 
    end

    else if (rd_mem_wb != 5'b0 && (rd_mem_wb != rs1 && (rd_mem_wb == rs2 && (reg_mem_wb && (mem_write_id_ex)))))begin 
        forward3_sel = 2'b01; //stall until data_resp
        stall_mem_wb = 1'b1; 
    end
    else begin 
        forward3_sel = 2'b00;
        stall_mem_wb= 1'b1;
    end
end
//-----------------------------------------------------------------------------------------------------------
always_comb begin: FORWARD4
    //forward alu_out to cmp rs1
    if (rd_ex_mem != 5'b0 && rd_ex_mem == rs1 && ctrl_opcode == op_br && mem_read_ex_mem == 1'b0 )begin
        forward4_sel = 2'b01; 
    end
    //forward data_r to cmp_rs1
    else if (rd_ex_mem != 5'b0 && rd_ex_mem == rs1 && ctrl_opcode == op_br && mem_read_ex_mem == 1'b1)begin
        if(data_mem_resp) begin 
            forward4_sel = 2'b11;
        end

        else begin 
            forward4_sel = 2'b00;
        end
    end
    //forward regfilemux_out to cmp rs1 
    else if (rd_mem_wb != 5'b0 && rd_mem_wb == rs1 && ctrl_opcode == op_br && (mem_read_mem_wb == 1'b0 || mem_read_mem_wb == 1'b1))begin
        forward4_sel = 2'b10;
    end

    else begin 
        forward4_sel = 2'b00;
    end
end


//-----------------------------------------------------------------------------------------------------------
always_comb begin: FORWARD5
    //forward alu_out to cmp rs2
    if (rd_ex_mem != 5'b0 && rd_ex_mem == rs2 && ctrl_opcode == op_br && mem_read_ex_mem == 1'b0)begin
        forward5_sel = 2'b01;
    end
    //forward data_r to cmp_rs2
    else if (rd_ex_mem != 5'b0 && rd_ex_mem == rs2 && ctrl_opcode == op_br && mem_read_ex_mem == 1'b1)begin
        if(data_mem_resp) begin 
            forward5_sel = 2'b11;
        end

        else begin 
            forward5_sel = 2'b00;
        end
    end
    //forward regfilemux_out to cmp rs2 
    else if (rd_mem_wb != 5'b0 && rd_mem_wb == rs2 && ctrl_opcode == op_br && (mem_read_mem_wb == 1'b0 || mem_read_mem_wb == 1'b1))begin
        forward5_sel = 2'b10;
    end
    else begin 
        forward5_sel = 2'b00;
    end
end
endmodule:forwarding
