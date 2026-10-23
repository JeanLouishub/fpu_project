module processing_unit
import fpu_pkg::*;
(
  input  logic        CLK,
  input  logic        RST,
  input  logic        start,      // 1-cycle pulse from fpu_top
  input  logic [1:0]  op,         // 00 add, 01 sub, ...
  input  logic [31:0] a,
  input  logic [31:0] b,
  output logic [31:0] result,
  output logic        done,       // 1-cycle pulse when result is valid
  output logic [4:0]  flags       // optional: invalid, div0, overflow, underflow, inexact
);

//signals between stages
fp_unpacked_t ua, ub; //unpacker --> cmp + align, alu, mux

logic [7:0]  exp_out;         //cmp + align -> alu
logic [25:0] mant_a, mant_b;  //cmp + align -> alu

logic        result_sign;     //alu -> normalizer
logic [7:0]  result_exp;      //alu -> normalizer
logic [26:0] result_mant;     //alu -> normalizer

fp_unpacked_t u_norm; //normalizer -> rounder
logic rnd, stk; //normalizer -> rounder

fp_unpacked_t u_rounded; //rounder -> mux

fp_unpacked_t u_final; //mux -> packer

logic [31:0] packed_result; //packer -> output

always_ff @(posedge CLK, posedge RST)
    if (RST) done <= 0; else done <= start;
always_ff @(posedge CLK)
    if (start) result <= packed_result;

assign flags = '0; //not implemented yet

//data Path
// 1. Unpacker

unpacker u_unpack_a (.x (a), .u (ua));
unpacker u_unpack_b (.x (b), .u (ub));

//2. cmp + align

cmp_align u_cmp_align (
    .a (ua),
    .b (ub),
    .exp_out (exp_out),
    .mant_a (mant_a),
    .mant_b (mant_b)
);

//3. ALU
alu u_alu (
    .a (ua),
    .b (ub),
    .op (op[0]),
    .exp_out (exp_out),
    .mant_a (mant_a),
    .mant_b (mant_b),
    .result_sign (result_sign),
    .result_exp (result_exp),
    .result_mant (result_mant)
);

//4. Normalize
normalize u_norm_stage (
    .u_out (u_norm),
    .rnd (rnd),
    .stk (stk),
    .sign (result_sign),
    .exp (result_exp),
    .mant (result_mant)
);

//5. Round
rounder u_round (
    .u_in (u_norm),
    .rnd (rnd),
    .stk (stk),
    .u_out (u_rounded)
);

//5.5 result mux (special cases: NaN, Inf, zero)
result_mux u_mux (
    .a (ua),
    .b (ub),
    .op (op[0]),
    .result (u_rounded),
    .final_result (u_final)
);

//6. packer
packer u_pack (
    .u (u_final),
    .result (packed_result)
);

endmodule
