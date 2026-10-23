module cmp_align
	import fpu_pkg::*;
(
	input fp_unpacked_t a,
	input fp_unpacked_t b,
	output logic [7:0] exp_out,
	output logic [24:0] mant_a, // 23 mantissa bits + 1 hidden bit + 1 guard bit
	output logic [24:0] mant_b,

);
assign mant_a = {a.mant, 2'b00}; // add guard bit

assign mant_b = {b.mant, 2'b00}; // add guard bit

//compare the exponents of a and b, and align the mantissas accordingly
	logic [7:0] exp_a;
	logic [7:0] exp_b;

	if(a.exp > b.exp) begin
		exp_out = a.exp;
		mant_a = a.mant;
		mant_b = b.mant >> (a.exp - b.exp);
	end else begin
		exp_out = b.exp;
		mant_a = a.mant >> (b.exp - a.exp);
		mant_b = b.mant;
	end

//	
endmodule