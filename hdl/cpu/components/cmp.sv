module branch
import rv32i_types::*;
(
    input rv32i_word s1,
    input rv32i_word s2,
    input branch_funct3_t cmpop,
    output logic br_en
);
always_comb begin
    unique case (cmpop)
        beq:br_en = (s1 == s2);
        bne:br_en = (s1 != s2);
        blt:br_en = ($signed(s1) < $signed(s2));
        bge:br_en = ($signed(s1) >= $signed(s2));
        bltu:br_en = ($unsigned(s1) < $unsigned(s2));
        bgeu:br_en = ($unsigned(s1) >= $unsigned(s2));
        default: br_en=1'b0;
    endcase
end
endmodule: branch