import lc3b_types::*;

module datapath
(
    input clk,

    /* control signals */
    input [1:0] pcmux_sel,
	 input storemux_sel,
	 input [2:0] alumux_sel,
	 input [2:0] regfilemux_sel,
	 input [2:0] marmux_sel,
	 input mdrmux_sel,
	 input off9_off11_sel,
	 input destmux_sel,
	 input sr1_mux_sel,
	 input load_ir,
	 input load_regfile,
	 input load_mar,
	 input load_mdr,
	 input load_cc,
    input load_pc,
	 input lc3b_aluop aluop,
	 input lc3b_word mem_rdata,
	 
    /* declare more ports here */
	 
	 output lc3b_word mem_address,
	 output lc3b_word mem_wdata,
	 output lc3b_opcode opcode,
	 output logic branch_enable,
	 output logic bit5, 
	 output logic bit11,
	 output logic bit4
	 
);

/* declare internal signals */

lc3b_word pcmux_out;
lc3b_word pc_out;
lc3b_word br_add_out;
lc3b_word stb_add_out;
lc3b_word pc_plus2_out;
lc3b_word sr1_out;
lc3b_word sr2_out;
lc3b_word adj6_out;
lc3b_word adj9_out;
lc3b_word adj11_out;
lc3b_word alumux_out;
lc3b_word off9_off11_out;
lc3b_word regfilemux_out;
lc3b_word marmux_out;
lc3b_word mdrmux_out;
lc3b_word alu_out;
lc3b_word custom_sr1_out;

lc3b_offset6 offset6;
lc3b_offset9 offset9;
lc3b_offset11 offset11
;
lc3b_reg sr1;
lc3b_reg sr2;
lc3b_reg dest;
lc3b_reg storemux_out;
lc3b_reg destmux_out;

lc3b_nzp gencc_out;
lc3b_nzp cc_out;


lc3b_imm5 imm5;
//created word type of the imm5 because it needs to be sign-extended. A word is 16 bits. 
lc3b_word imm5_sext;

lc3b_imm5 imm4;
lc3b_word imm4_sext;

lc3b_byte trapvect8;
lc3b_word trapvect8_zext;

lc3b_word offset6_sext;
lc3b_word memwrite_zext_out;
/*
 * PC
 */
mux4 pcmux
(
    .sel(pcmux_sel),
    .a(pc_plus2_out),
    .b(br_add_out),
    .c(sr1_out),
	 .d(mem_wdata),
    .f(pcmux_out)
);

mux2 mdrmux
(
    .sel(mdrmux_sel),
    .a(alu_out),
    .b(mem_rdata),
    .f(mdrmux_out)
);

mux2 off9_off11
(
    .sel(off9_off11_sel),
    .a(adj9_out),
    .b(adj11_out),
    .f(off9_off11_out)
);

mux5 marmux
(
    .sel(marmux_sel),
    .a(alu_out),
    .b(pc_out),
	 .c(mem_wdata),
	 .d(trapvect8_zext),
	 .e(stb_add_out),
    .f(marmux_out)
);

mux2 #(.width(3)) storemux
(
    .sel(storemux_sel),
    .a(sr1),
    .b(dest),
    .f(storemux_out)
);

mux2 #(.width(3)) destmux 
(
    .sel(destmux_sel),
    .a(dest),
    .b(7),
    .f(destmux_out)
);

mux2 sr1_mux
(
    .sel(sr1_mux_sel),
    .a(sr1_out),
    .b({sr1_out[7:0],sr1_out[7:0]}),
    .f(custom_sr1_out)
);


mux4 alumux
(
    .sel(alumux_sel),
    .a(sr2_out),
    .b(adj6_out),
	 .c(imm5_sext),
	 .d(imm4_sext),
    .f(alumux_out)
);

mux5 regfilemux
(
    .sel(regfilemux_sel),
    .a(alu_out),
    .b(mem_wdata),
	 .c(br_add_out),
	 .d(pc_out),
	 .e(memwrite_zext_out),
    .f(regfilemux_out)
);

register pc
(
    .clk,
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
);

register #(.width(3)) cc
(
    .clk,
    .load(load_cc),
    .in(gencc_out),
    .out(cc_out)
);

register mdr
(
    .clk,
    .load(load_mdr),
    .in(mdrmux_out),
    .out(mem_wdata)
);

register mar
(
   .clk,
   .load(load_mar),
   .in(marmux_out),
   .out(mem_address)
);

alu alu
(
	.aluop(aluop),
	.a(custom_sr1_out),
	.b(alumux_out),
	.f(alu_out)
);


adj #(.width(6)) adj_6
(
   .in(offset6),
	.out(adj6_out)
);

adj #(.width(9)) adj_9
(
   .in(offset9),
	.out(adj9_out)
);

adj #(.width(11)) adj_11
(
   .in(offset11),
	.out(adj11_out)
);

ir ir
(
	.clk,
   .load(load_ir),
   .in(mem_wdata),
   .opcode(opcode),
   .dest(dest), 
	.src1(sr1), 
	.src2(sr2),
   .offset6(offset6),
	.offset9(offset9),
	.offset11(offset11),
	.bit5(bit5),
	.imm5(imm5),
	.imm4(imm4),
	.bit11(bit11),
	.bit4(bit4),
	.trapvect8(trapvect8)
);

gencc gencc
(
	.in(regfilemux_out),
	.out(gencc_out)
);

regfile regfile
(
	.clk,
   .load(load_regfile),
   .in(regfilemux_out),
   .src_a(storemux_out), 
	.src_b(sr2), 
	.dest(destmux_out),
   .reg_a(sr1_out),
	.reg_b(sr2_out)
);


plus2 pc_plus2
(
	.in(pc_out),
	.out(pc_plus2_out)
);

nzp cccomp
(
	.a(dest),
	.b(cc_out),
	.br_enable(branch_enable)
);

adder br_add
(
	.a(off9_off11_out),
	.b(pc_out), 
	.f(br_add_out)
);

adder stb_add
(
	.a(sr1_out),
	.b(offset6_sext), 
	.f(stb_add_out)
);

sext #(.width(5)) sext_5
(
	.in(imm5),
	.out(imm5_sext)
);

sext #(.width(4)) sext_4
(
	.in(imm4),
	.out(imm4_sext)
);

sext #(.width(6))sext_6
(
	.in(offset6),
	.out(offset6_sext)
);


zext #(.width(8)) zext_1
(
	.in(trapvect8),
	.shift(1'b1),
	.address(mem_address),
	.out(trapvect8_zext)
);

zext #(.width(16)) zext_2
(
	.in(mem_wdata),
	.shift(1'b0),
	.address(mem_address),
	.out(memwrite_zext_out)
);

endmodule : datapath
