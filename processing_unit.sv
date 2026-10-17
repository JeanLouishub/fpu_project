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


//3. ALU


//4. Normalize


//5. Round 
rounder u_round (
    .u_in (u_norm), 
    .rnd (rnd), 
    .stk (stk), 
    .u_out (u_rounded)
);

//6. packer
packer u_pack (
    .u (u_rounded),
    .result (normal_result)
);

//7. mux result 


assign packed_result = normal_result; //for now, check special cases 

endmodule