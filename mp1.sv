import lc3b_types::*;

module mp1
(
    input clk,

    /* Memory signals */
    input mem_resp,
    input lc3b_word mem_rdata,
    output mem_read,
    output mem_write,
    output lc3b_mem_wmask mem_byte_enable,
    output lc3b_word mem_address,
    output lc3b_word mem_wdata
);

/* Control to datapath */
logic load_pc;
logic load_ir;
logic load_regfile;
logic load_mar;
logic load_mdr;
logic load_cc;
logic [1:0] pcmux_sel;
logic storemux_sel;
logic destmux_sel;
logic off9_off11_sel;
logic [2:0] alumux_sel;
logic [2:0] regfilemux_sel;
logic [2:0] marmux_sel;
logic mdrmux_sel;
logic sr1_mux_sel;
lc3b_aluop aluop;


/* Datapath to control */
lc3b_opcode opcode; 
logic branch_enable;
logic bit4;
logic bit5;
logic bit11;

/* Instantiate MP 0 top level blocks here */

datapath datapath
(
	 .clk(clk),
    .pcmux_sel(pcmux_sel),
	 .storemux_sel(storemux_sel),
	 .marmux_sel(marmux_sel),
	 .mdrmux_sel(mdrmux_sel),
	 .load_mdr(load_mdr),
	 .load_mar(load_mar),
	 .load_ir(load_ir),
	 .load_regfile(load_regfile),
	 .load_cc(load_cc),
	 .load_pc(load_pc),
	 .alumux_sel(alumux_sel),
	 .destmux_sel(destmux_sel),
	 .aluop(aluop),
	 .regfilemux_sel(regfilemux_sel),
	 .off9_off11_sel(off9_off11_sel),
	 .mem_rdata(mem_rdata),
	 .branch_enable(branch_enable),
	 .opcode(opcode),
	 .mem_address(mem_address),
	 .mem_wdata(mem_wdata),
	 .bit5(bit5),
	 .bit11(bit11),
	 .bit4(bit4),
	 .sr1_mux_sel(sr1_mux_sel)
	 
);

control controller
(
	 .clk(clk),
    .pcmux_sel(pcmux_sel),
    .load_pc(load_pc),
	 .storemux_sel(storemux_sel),
	 .marmux_sel(marmux_sel),
	 .load_mar(load_mar),
	 .mdrmux_sel(mdrmux_sel),
	 .load_mdr(load_mdr),
	 .load_ir(load_ir),
	 .load_regfile(load_regfile),
	 .alumux_sel(alumux_sel),
	 .off9_off11_sel(off9_off11_sel),
	 .aluop(aluop),
	 .regfilemux_sel(regfilemux_sel),
	 .load_cc(load_cc),
	 .branch_enable(branch_enable),
	 .destmux_sel(destmux_sel),
	 .opcode(opcode),
	 .mem_read(mem_read),
	 .mem_write(mem_write),
	 .mem_byte_enable(mem_byte_enable),
	 .mem_resp(mem_resp),
	 .bit4(bit4),
	 .bit5(bit5),
	 .bit11(bit11),
	 .mem_address(mem_address),
	 .sr1_mux_sel(sr1_mux_sel)
);

endmodule : mp1
