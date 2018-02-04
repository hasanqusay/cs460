module nzp
(
	input [2:0] a, 
	input [2:0] b, 
	output logic br_enable
);

always_comb
begin 
	if((a[2] && b[2]) ||	(a[1] && b[1]) || (a[0] && b[0]))
		br_enable = 1;
	else
		br_enable = 0;	
end 

endmodule : nzp