module processing_unit 
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
import fpu_pkg::*;

logic [31:0] packed_result;

always_ff @(posedge CLK, posedge RST)
    if (RST) done <= 0; else done <= start;
always_ff @(posedge CLK)
    if (start) result <= packed_result;


endmodule