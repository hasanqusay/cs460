module mux5 #(parameter width = 16)
(
	input logic [1:0] sel,
	input [width-1:0] a, b, c, d,e,
	output logic [width-1:0] f
);

always_comb
begin
	if (sel == 0)
		f = a;
	else if (sel == 1)
		f = b;
	else if (sel == 2)
		f = c;
	else if (sel == 3)
		f = d;
	else
		f = e;
end

endmodule : mux5