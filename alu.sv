module alu
    import fpu_pkg::*;
(
    input fp_unpacked_t a,
    input fp_unpacked_t b,
    input logic op, // 0 = add, 1 = sub
    output logic [7:0] exp_out,
	output logic [24:0] mant_a, // 23 mantissa bits + 1 hidden bit + 1 guard bit
	output logic [24:0] mant_b, // 23 mantissa bits + 1 hidden bit + 1 guard bit
    output logic overflow
    output fp_unpacked_t result
);

assign logic mant_a_ = {1'b0, a.mant }; // 2's complement of mant_a
assign logic mant_b_ = {1'b0, b.mant }; // 2's complement of mant_b

if(a.sign) begin
    mant_a_ = ~mant_a_ + 1;
end
if(b.sign ^ op) begin
    mant_b_ = ~mant_b_ + 1;
end

// now do the addition between mant_a_ and mant_b_
assign logic [25:0] mant_sum = mant_a_ + mant_b_;

assign overflow = ~(mant_a_[25] ^ mant_b_[25]) & (mant_a_[25] ^ mant_sum[25]);

// if the sum is negative, we need to take the 2's complement of the sum and set the sign bit of the result to 1
if(mant_sum[25]) begin
    result.sign = 1;
    result.mant = ~mant_sum[24:0] + 1;
    result.exp = exp_out;
end else begin
    result.sign = 0;
    result.mant = mant_sum[24:0];
    result.exp = exp_out;
end




endmodule