import lc3b_types::*;


module zext #(parameter width = 16)
(
    input [width-1:0] in, address,
	 input logic shift,
    output lc3b_word out
);

always_comb

	if(shift)
	
		out = $unsigned({in, 1'b0});
	
	else
		out = $unsigned(in);
	
endmodule : zext