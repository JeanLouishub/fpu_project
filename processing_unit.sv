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
fp_unpacked_t ua, ub; //unpacker --> cmp + align 
//cmp + align + add/sub + normalizer output/input 

fp_unpacked_t u_norm; //normalizer -> rounder
logic rnd, stk; //normalizer -> rounder

fp_unpacked_t u_rounded; //rounder-> packer

logic [31:0] normal_result; //packer -> mux

logic [31:0] packed_result; //mux -> output

always_ff @(posedge CLK, posedge RST)
    if (RST) done <= 0; else done <= start;
always_ff @(posedge CLK)
    if (start) result <= packed_result;

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
normalize norm (
    .u_in (u_alu), 
    .u_out (u_norm), 
    .rnd (rnd), 
    .stk (stk),
    .result_sign (result_sign),
    .result_exp (result_exp),
    .result_mant (result_mant)
);

//5. Round 
rounder u_round (
    .u_in (u_norm), 
    .rnd (rnd), 
    .stk (stk), 
    .u_out (u_rounded)
);


//5.5 mux_result
mux_result mr(
    .u_rounded (u_rounded),
    .normal_result (normal_result),
    .packed_result (packed_result)
);

//6. packer
packer u_pack (
    .u (u_rounded),
    .result (normal_result)
);
 

assign packed_result = normal_result; //for now, check special cases 

endmodule