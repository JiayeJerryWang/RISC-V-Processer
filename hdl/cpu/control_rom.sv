import rv32i_types::*;

module control_rom
(
    input rv32i_opcode opcode,
    input logic[4:0] rs1, //when to store this value in struct
    input logic[4:0] rs2,
    input logic[4:0] rd,
    input logic[2:0] funct3,
    input logic[6:0] funct7,
    /* ... other inputs ... */
    output rv32i_control_word ctrl,
    output logic instr_read
);

//used
branch_funct3_t branch_funct3;
alu_ops alu_funct3;

//not used
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

//used
assign branch_funct3 = branch_funct3_t'(funct3);
assign alu_funct3 = alu_ops'(funct3);


//not used
assign arith_funct3 = arith_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);

assign instr_read = 1'b1; //just for cp1

function void loadPC(pcmux::pcmux_sel_t sel);
    ctrl.pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    ctrl.Regwrite_en = 1'b1;
    ctrl.rd = rd;
    ctrl.regfilemux_sel = sel; //select reg file mux according to input
endfunction

function void load_memrdata_mux(mem_rdatamux::mem_rdatamux_sel_t sel);
    ctrl.mem_rdatamux_sel = sel; //select reg file mux according to input
endfunction

function void setALU(alumux::alumux1_sel_t sel1, alumux::alumux2_sel_t sel2, logic setop , alu_ops op);
    /* Student code here */
    ctrl.alumux1_sel = sel1;
    ctrl.alumux2_sel = sel2;
    if (setop)
        ctrl.aluop = op; // else default value
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
    ctrl.cmpmux_sel=sel;
    ctrl.cmpop = op;
endfunction

function void set_defaults();
    ctrl.opcode = opcode;
    ctrl.rs1 = 5'b00000;
    ctrl.rs2 = 5'b00000;
    ctrl.rd = 5'b00000;
    ctrl.cmpop = branch_funct3;
    ctrl.aluop = alu_funct3;
    ctrl.pcmux_sel = pcmux::pc_plus4;
    ctrl.alumux1_sel = alumux::rs1_out;
    ctrl.alumux2_sel = alumux::i_imm;
    ctrl.regfilemux_sel = regfilemux::alu_out;
    ctrl.cmpmux_sel = cmpmux::rs2_out;
    ctrl.mem_read = 1'b0;
    ctrl.mem_write = 1'b0;
    ctrl.mem_byte_enable = 4'b0000;
    ctrl.Regwrite_en= 1'b0;
    ctrl.mem_rdatamux_sel=mem_rdatamux::alu_out;
endfunction

always_comb
begin
    /* Default assignments */
    set_defaults();

    /* Assign control signals based on opcode */
    case(opcode)

        op_lui: begin
            loadPC(pcmux::pc_plus4);
            loadRegfile(regfilemux::u_imm);
            load_memrdata_mux(mem_rdatamux::u_imm);
        end

        op_auipc: begin
            loadRegfile(regfilemux::alu_out);
			setALU(alumux::pc_out, alumux::u_imm, 1'b1, alu_add);
            
        end

        op_jal: begin
            loadPC(pcmux::alu_mod2);
            loadRegfile(regfilemux::pc_plus4);
			setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_add);
            // branch later cp2
        end

        op_jalr: begin
            loadPC(pcmux::alu_mod2);
            loadRegfile(regfilemux::pc_plus4);
			setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
            ctrl.rs1 = rs1;
            // branch later cp2
        end

        op_br: begin
            setALU(alumux::pc_out, alumux::b_imm, 1'b1, alu_add);
            setCMP(cmpmux::rs2_out, branch_funct3);
            ctrl.rs1 = rs1;
            ctrl.rs2 = rs2;
        end

        op_load: begin
            loadPC(pcmux::pc_plus4);
            ctrl.mem_read = 1'b1;
            ctrl.rs1 = rs1;
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);//alu problem
            case(load_funct3) //shift problem
            	lw: begin 
                    loadRegfile(regfilemux::lw);
                    load_memrdata_mux(mem_rdatamux::lw);
                end
				lb: begin 
                    loadRegfile(regfilemux::lb);
                    load_memrdata_mux(mem_rdatamux::lb);
                end
                lbu: begin 
                    loadRegfile(regfilemux::lbu);
                    load_memrdata_mux(mem_rdatamux::lbu);
                end
                lh: begin 
                    loadRegfile(regfilemux::lh);
                    load_memrdata_mux(mem_rdatamux::lh);
                end
                lhu: begin 
                    loadRegfile(regfilemux::lhu);
                    load_memrdata_mux(mem_rdatamux::lhu);
                end
			endcase  
        end

        op_store: begin
            loadPC(pcmux::pc_plus4);
            setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);
            ctrl.mem_write = 1'b1;
            ctrl.rs1 = rs1;
            ctrl.rs2 = rs2;
            case(store_funct3)  
                sw: ctrl.mem_byte_enable = 4'b1111;
                sh: ctrl.mem_byte_enable = 4'b0011;
                sb: ctrl.mem_byte_enable = 4'b0001;
            endcase

        end

        op_imm: begin 
            ctrl.rs1 = rs1;
            loadPC(pcmux::pc_plus4);
            case(arith_funct3)
                slt:begin  //Sets destination reg to 1 if the first reg's val less than second reg's val. Otherwise, set to 0.
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::i_imm, blt);
                end

                sltu:begin //used with unsaigned integers
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::i_imm, bltu);
                end
                sr:begin //read value from reg and subtract from the argument
                    loadRegfile(regfilemux::alu_out);
                    //SRAI case               
                    if (funct7[5] == 1'b1) begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sra) ;
                    end
                    //SRLI case
                    else begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_srl) ;
                    end
                end   

                default:begin  
                        loadRegfile(regfilemux::alu_out);
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_ops'(arith_funct3) );
                    end
            endcase
        end

        op_reg: begin 
            ctrl.rs1 = rs1;
            ctrl.rs2 = rs2;
            loadPC(pcmux::pc_plus4);
             case(arith_funct3)
                slt: begin 
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::rs2_out,blt);
                end

                sltu: begin 
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::rs2_out,bltu);
                end
                
                sr: begin 
                    if(funct7[5] ==1'b1)begin
                    loadRegfile(regfilemux::alu_out);
                    setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sra);
                    end

                    else begin
                    loadRegfile(regfilemux::alu_out);
                    setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_srl);
                    end
                end
                add: begin
                    if(funct7[5] == 1'b1)begin 
                        loadRegfile(regfilemux::alu_out);
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sub);
                    end
                    else begin
                        loadRegfile(regfilemux::alu_out);
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_add);
                    end
                end

                default: begin                 
                    loadRegfile(regfilemux::alu_out);
                    setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_ops'(arith_funct3));
                end
            endcase
        end

        op_csr: begin
            
        end

        default: begin
          /* Unknown opcode, set control word to zero */
        end
        

    endcase
end
endmodule : control_rom