import lc3b_types::*; /* Import types defined in lc3b_types.sv */

module control
(
	input clk,
	
	/* Datapath controls */
	input logic bit5, bit11, bit4,
	input lc3b_opcode opcode,
	input logic branch_enable,
	input lc3b_word mem_address,
	output logic load_pc,
	output logic load_ir,
	output logic load_regfile,
	output logic load_cc,
	output logic load_mar,
	output logic load_mdr,
	output logic [2:0] marmux_sel,
	output logic mdrmux_sel,
	output logic storemux_sel,
	output logic off9_off11_sel,
	output logic [2:0] alumux_sel,
	output logic [1:0] pcmux_sel,
	output logic [2:0] regfilemux_sel,
	output logic sr1_mux_sel,
	output logic destmux_sel,
	output lc3b_aluop aluop,

	/* Memory signals */
	input mem_resp,
	output logic mem_read,
	output logic mem_write,
	output lc3b_mem_wmask mem_byte_enable
);

enum int unsigned {

    /* List of states */
	 fetch1, 
	 fetch2,
	 fetch3,
	 decode,
	 s_add,
	 s_and,
	 s_not,
	 br,
	 br_taken,
	 calc_addr,
	 ldr1,
	 ldr2,
	 str1,
	 str2,
	 jmp_ret, 
	 lea,
	 ldb,
	 ldi1,
	 ldi2,
	 ldi3,
	 ldi4,
	 jsr_jsrr,
	 sti1,
	 sti2,
	 sti3,
	 sti4,
	 shf,
	 trap1,
	 trap2,
	 trap3,
	 trap4,
	 stb1,
	 stb2,
	 stb3,
	 ldb1,
	 ldb2,
	 ldb3
	 
	 
} state, next_state;

always_comb
begin : state_actions
    /* Default output assignments */
	load_pc= 1'b0;
	load_ir= 1'b0;
	load_regfile= 1'b0;
	aluop= alu_add;
	mem_read= 1'b0;
	mem_write= 1'b0;
	mem_byte_enable= 2'b11;
	load_mar= 1'b0;
	load_mdr= 1'b0;
	load_cc= 1'b0;
	pcmux_sel= 1'b0; 
	storemux_sel= 1'b0;
	alumux_sel= 1'b0;
	off9_off11_sel= 1'b0;
	regfilemux_sel= 1'b0;
	marmux_sel= 1'b0;
	mdrmux_sel= 1'b0;
	destmux_sel= 1'b0;
	sr1_mux_sel = 1'b0;
	
    /* Actions for each state */
	case(state)
		fetch1: begin
			/* MAR <= PC */
			marmux_sel= 1;
			load_mar= 1;
			/* PC <= PC + 2 */
			pcmux_sel= 0;
			load_pc= 1;
		end
		
		fetch2: begin
			/* Read memory */
			mem_read= 1;
			mdrmux_sel= 1;
			load_mdr= 1;
		end
		
		fetch3: begin
			/* Load IR */
			load_ir= 1;
		end
		
		decode: /* Do nothing */;
		
		s_add: begin
			
			aluop= alu_add;
			load_regfile= 1;
			regfilemux_sel= 0;
			load_cc= 1;
			
			if (bit5== 0)
				/* DR <= SRA + SRB */
				alumux_sel= 0;
			else if (bit5== 1)
				/* DR <= SRA + IMM5 */
				alumux_sel= 2;
			
		end
		
		s_and: begin

			aluop= alu_and;
			load_regfile= 1;
			load_cc= 1;
			
			if (bit5== 0)
				/* DR <= SRA & SRB */
				alumux_sel= 0;
			else if (bit5== 1)
				/* DR <= SRA & IMM5 */
				alumux_sel= 2;
		end

		s_not: begin

			aluop= alu_not;
			load_regfile= 1;
			load_cc= 1;
		end
		
		br: /* NONE */ ;
		
		br_taken: begin
			off9_off11_sel= 0;
			pcmux_sel= 1;
			load_pc= 1;
		end
		
		calc_addr: begin
			alumux_sel= 1;
			aluop= alu_add;
			load_mar= 1;
		end
		
		//LDR
		
		ldr1: begin
			mdrmux_sel= 1;
			load_mdr= 1;
			mem_read= 1;
		end
		
		ldr2: begin
			regfilemux_sel= 1;
			load_regfile= 1;
			load_cc= 1;
		end
		
		//STR
		
		str1: begin
			storemux_sel= 1;
			aluop= alu_pass;
			load_mdr= 1;
		end
		 
		str2: begin
			mem_write= 1;
		end
		
		//JUMP
		
		jmp_ret: begin
			load_pc= 1;
			pcmux_sel= 2;
		end
		
		//LEA
		
		lea: begin
			//DR= PC† + (SEXT(PCoffset9) << 1);
			// (SEXT(PCoffset9) << 1).. This part already done by the adj.. The br_adder will produce br_add_out which then will be chosen by regfilemux_sel which then will
			// be loaded because load_regfile= 1
			load_cc= 1;
			load_regfile= 1; 
			regfilemux_sel= 2;
		end
		
		//LDI
		
		// similar to ldr but we have to load MDR to MAR then load M[MDR] to MAR again
		ldi1: begin
			mdrmux_sel= 1;
			load_mdr= 1;
			mem_read= 1;
		end
		
		// used the mem_wdata coming out of MDR as a third input to the MAR mux
		ldi2: begin
			marmux_sel= 2;
			load_mar= 1;

		end
		
		ldi3: begin
			mdrmux_sel= 1;
			load_mdr= 1;
			mem_read= 1;
		end
		
		ldi4: begin
			regfilemux_sel= 1;
			load_regfile= 1;
			load_cc= 1;
		end
		
		//JSR_JSRR
		
		jsr_jsrr: begin
		
			load_regfile= 1; 
			regfilemux_sel= 3;
			destmux_sel= 1;
			
			if(bit11== 0)
				begin
					pcmux_sel= 2;
					load_pc= 1;
				end
				
			else if(bit11== 1)
				begin
					off9_off11_sel= 1;
					pcmux_sel= 1;
					load_pc= 1;
				end
		end
		
		
		//STI
		
		sti1: begin
			mdrmux_sel= 1;
			load_mdr= 1;
			mem_read= 1;
		end
		 
		sti2: begin
			load_mar= 1;
			marmux_sel= 2;
		end
		
		sti3: begin
			aluop= alu_pass;
			storemux_sel= 1;
			load_mdr= 1;
		end
		 
		sti4: begin
			mem_write= 1;
		end

		//SHF
		
		shf: begin 
			
			load_cc = 1;
			load_regfile = 1;
			regfilemux_sel = 0;
			alumux_sel = 3; 

			if(!bit4)
				aluop = alu_sll;
			else
				if(!bit5)
					aluop = alu_srl;
				else 
					aluop = alu_sra;
		end 
		
		//TRAP

		trap1: begin
		
			destmux_sel= 1;
			load_regfile = 1; 
			regfilemux_sel = 3;
			
		end
		trap2: begin
			// load MAR
			load_mar = 1; 
			marmux_sel = 3;
		end
		trap3: begin
			// load MDR with m[MAR]
			mem_read = 1; 
			load_mdr = 1;
			mdrmux_sel = 1;
		end
		trap4: begin
			load_pc = 1;
			pcmux_sel = 3;
		end
		
		//STB
		
		stb1: begin
		
			load_mar = 1; 
			marmux_sel = 4;
		end
		
		stb2: begin
		
			sr1_mux_sel = 1;	
			aluop= alu_pass;
			
			storemux_sel= 1;
			mdrmux_sel= 0;
			load_mdr= 1;
		
		end
		stb3: begin
		
			// because of 'mem' we need to figure weather we will write into the low or high byte
			if(mem_address[0]==0)
					// low byte
					mem_byte_enable=  1;
			else 
					//upper byte
					mem_byte_enable=  2;

			mem_write = 1; 
		end	
			
		//LDB

		ldb1: begin 
			// load MAR with the sbr addition.. same as ldb in this case: 
			load_mar = 1; 
			marmux_sel = 4;
		end 
		
		ldb2: begin

			mdrmux_sel = 1;
			load_mdr = 1; 
			mem_read = 1;
		end
		
		ldb3: begin

			load_regfile = 1;
			load_cc = 1;
			regfilemux_sel = 4;
		end
		
		
	
		default: /* NONE */;
	endcase

end

always_comb
begin : next_state_logic

	next_state= state; 
	case(state)
	
		fetch1: begin
			next_state= fetch2;
		end
		
		fetch2: begin
			if (mem_resp== 0)
				next_state= state; 
			else
				next_state= fetch3; 
		end
		
		fetch3: begin
			next_state= decode;
		end
		
		decode: begin 
			if(opcode==  op_br)
				next_state= br; 
			else if(opcode==  op_add)
				next_state= s_add; 
			else if(opcode==  op_and)
				next_state= s_and; 
			else if(opcode==  op_not)
				next_state= s_not; 
			else if(opcode==  op_ldr || opcode==  op_sti || opcode==  op_str || opcode== op_ldi)
				next_state= calc_addr; 
			else if(opcode== op_jmp)
				next_state= jmp_ret;
			else if (opcode==  op_lea)
				next_state= lea;
			else if(opcode== op_jsr)
				next_state= jsr_jsrr;
			else if(opcode == op_shf)
				next_state = shf;
			else if(opcode == op_trap)
				next_state = trap1;
			else if(opcode == op_stb)
				next_state = stb1;
			else if(opcode == op_ldb)
				next_state = ldb1;

		end
		
		s_add: begin
			next_state= fetch1;
		end
		
		s_and: begin
			next_state= fetch1;
		end
		
		s_not: begin
			next_state= fetch1;
		end
		
		br: begin
			if (branch_enable== 1)
				next_state= br_taken;
			else
				next_state= fetch1;
		end
		
		br_taken: begin
			next_state= fetch1;
		end
		
		calc_addr: begin
			if (opcode== op_str)
				next_state= str1; 
			else if(opcode== op_ldr)
				next_state= ldr1;
			else if (opcode== op_ldi)
				next_state= ldi1;
			else if (opcode== op_sti)
				next_state= sti1; 

		end
		
		// LDR
		
		ldr1: begin
			if (mem_resp== 0)
				next_state= state; 
			else
				next_state= ldr2; 
		end
		
		ldr2: begin
			next_state= fetch1;
		end
		
		// STR
		
		str1: begin
			next_state= str2;
		end
		 
		str2: begin
			if (mem_resp== 0)
				next_state= state; 
			else
				next_state= fetch1; 
		end 
		
		// JUMP/RET
		
		jmp_ret: begin
			next_state= fetch1;
		end
		
		// LEA
		
		lea: begin
			next_state= fetch1;
		end
		
		// LDI 
		
		ldi1: begin
			if(mem_resp== 0)
				next_state= state;
			else
				next_state= ldi2;
		end
		ldi2: begin
			next_state= ldi3;
		end
		ldi3: begin
			if(mem_resp== 0)
				next_state= state;
			else
				next_state= ldi4;
		end
		ldi4: begin
			next_state= fetch1;
		end
		
		// JSR_JSRR 
		
		jsr_jsrr: begin
			next_state= fetch1;
		end
		
		// STI
		
		sti1: begin
			if(mem_resp== 0)
				next_state= state;
			else
				next_state= sti2;
		end
		sti2: begin
			next_state= sti3;
		end
		sti3: begin
			next_state= sti4;
		end
		sti4: begin
			if(mem_resp== 0)
				next_state= state;
			else
				next_state= fetch1;
		end
		
		//SHF
		
		shf: begin 
			next_state = fetch1;
		end 
		
		//TRAP
		
		trap1: begin
			next_state = trap2;
		end
		trap2: begin	
			next_state = trap3;
		end
		trap3: begin
			if(mem_resp == 0)
				next_state = state;
			else
				next_state = trap4;
		end
		trap4: begin
			next_state = fetch1;
		end
		
		//STB
		
		stb1: begin
			next_state= stb2;
		end
		stb2: begin
			next_state= stb3;
		end
		stb3: begin
			if(mem_resp== 0)
				next_state= state; 
			else
			next_state= fetch1;
		end
		
		//LDB
		
		ldb1: begin 
			next_state = ldb2;
		end 
		ldb2: begin
			if(mem_resp == 0)
				next_state = state;
			else
				next_state = ldb3;
		end
		ldb3: begin 
			next_state = fetch1;
		end
		
		
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end

endmodule : control
