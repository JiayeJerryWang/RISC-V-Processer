module hazard_control
import rv32i_types::*;
(

    input i_read,
    input logic data_read,
    input logic data_write,
    input logic i_resp,
    input logic data_resp,
    output logic stall_pc,
    output logic stall_datamem
);


always_comb begin 
    //instruction miss
    if (i_read==1'b1 && i_resp == 1'b0) begin 
        stall_pc = 1'b0; //stall PC
    end
    else if(i_read==1'b1 && i_resp == 1'b1) begin 
        stall_pc = 1'b1; //resume PC
    end
    else begin 
        stall_pc = 1'b1;
    end
    
    //data miss: stall everything before 
    if ((data_read || data_write) && data_resp==1'b0) begin 
        stall_datamem = 1'b0; // stall everything 
    end

    else if((data_read || data_write) && data_resp==1'b1) begin 
        stall_datamem = 1'b1;
    end
    else begin 
        stall_datamem = 1'b1;
    end
end

endmodule: hazard_control
