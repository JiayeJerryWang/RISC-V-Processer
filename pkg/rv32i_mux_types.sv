package pcmux;
typedef enum bit [1:0] {
    pc_plus4  = 2'b00
    ,alu_out  = 2'b01
    ,alu_mod2 = 2'b10
    ,pc_exe_plus4 = 2'b11
} pcmux_sel_t;
endpackage

package marmux;
typedef enum bit {
    pc_out = 1'b0
    ,alu_out = 1'b1
} marmux_sel_t;
endpackage

package cmpmux;
typedef enum bit {
    rs2_out = 1'b0
    ,i_imm = 1'b1
} cmpmux_sel_t;
endpackage

package alumux;
typedef enum bit {
    rs1_out = 1'b0
    ,pc_out = 1'b1
} alumux1_sel_t;

typedef enum bit [2:0] {
    i_imm    = 3'b000
    ,u_imm   = 3'b001
    ,b_imm   = 3'b010
    ,s_imm   = 3'b011
    ,j_imm   = 3'b100
    ,rs2_out = 3'b101
} alumux2_sel_t;
endpackage

package regfilemux;
typedef enum bit [3:0] {
    alu_out   = 4'b0000
    ,br_en    = 4'b0001
    ,u_imm    = 4'b0010
    ,lw       = 4'b0011
    ,pc_plus4 = 4'b0100
    ,lb        = 4'b0101
    ,lbu       = 4'b0110  // unsigned byte
    ,lh        = 4'b0111
    ,lhu       = 4'b1000  // unsigned halfword
} regfilemux_sel_t;
endpackage



package forward1mux; //connected to alumux1
typedef enum bit [1:0] {
    stay = 2'b00
    ,forward1 = 2'b01
    ,forward2 = 2'b10
    ,forward3 = 2'b11
} forward1mux_sel_t;
endpackage



package forward2mux; //connected to alumux2
typedef enum bit [1:0] {
    stay = 2'b00
    ,forward1 = 2'b01
    ,forward2 = 2'b10
    ,forward3 = 2'b11
} forward2mux_sel_t;
endpackage


package forward3mux; // connected to ex_mem rs2 register
typedef enum bit [1:0] {
    stay = 2'b00
    ,forward1 = 2'b01
    ,forward2 = 2'b10 
} forward3mux_sel_t;
endpackage

package forward4mux; //connected to cmpmux1
typedef enum bit [1:0] {
    stay = 2'b00
    ,forward1 = 2'b01
    ,forward2 = 2'b10
    ,forward3 = 2'b11
} forward4mux_sel_t;
endpackage

package forward5mux; //connected to cmpmux2
typedef enum bit [1:0] {
    stay = 2'b00
    ,forward1 = 2'b01
    ,forward2 = 2'b10
    ,forward3 = 2'b11
} forward5mux_sel_t;
endpackage

package pc_wdata_mux; 
typedef enum bit {
    plus4 = 1'b0
    ,br = 1'b1
} pc_wdata_sel_t;
endpackage

package mem_rdatamux;
typedef enum bit [3:0] {
    alu_out   = 4'b0000
    ,br_en    = 4'b0001
    ,u_imm    = 4'b0010
    ,lw       = 4'b0011
    ,pc_plus4 = 4'b0100
    ,lb        = 4'b0101
    ,lbu       = 4'b0110  // unsigned byte
    ,lh        = 4'b0111
    ,lhu       = 4'b1000  // unsigned halfword
} mem_rdatamux_sel_t;
endpackage