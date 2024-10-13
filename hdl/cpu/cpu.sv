module cpu
import rv32i_types::*;
(
    input clk,
    input rst,

    //I-cache
    input rv32i_word i_data,
    output rv32i_word i_addr,
    input logic i_resp,
    output logic i_read,

    //D-cache
    input rv32i_word data_r,
    input logic data_resp,
    output rv32i_word data_address,
    output rv32i_word data_w,
    output logic [3:0] data_mem_byte_enable,
    output logic data_read,
    output logic data_write,
    output logic [31:0] prefetch_pc
);

/******************* Signals Needed for RVFI Monitor *************************/
//ctrl word
rv32i_opcode opcode;
rv32i_control_word ctrl;
logic br_en;
logic[4:0] rs1; //when to store this value in struct
logic[4:0] rs2;
logic[4:0] rd;
logic[2:0] funct3;
logic[6:0] funct7;
logic instr_read;

//hazard detection signal
logic flush;
logic stall_pc;
logic stall_datamem;
logic commit;
assign i_read = 1'b1;
/*****************************************************************************/

/**************************** Control Rom Signals ********************************/

/*****************************************************************************/
// Keep control named `control` for RVFI Monitor
control_rom control(.*);

// Keep datapath named `datapath` for RVFI Monitor
datapath datapath(.*);

hazard_control hzard_control(.*);


endmodule : cpu
