
`default_nettype none

// Self-checking testbench for rounder (round to nearest even)
//  Part 1: directed tests (ties, carry, overflow, denormal -> normal, pass-through)
//  Part 2: random tests checked against a reference model that does NOT use
//          the rnd & (L | stk) equation, but the definition of rounding:
//          "go to the closest neighbour, on a tie pick the even one"

module tb_rounder;
  import fpu_pkg::*;

  fp_unpacked_t u_in, u_out;
  logic         rnd, stk;

  rounder dut (.u_in(u_in), .rnd(rnd), .stk(stk), .u_out(u_out));

  int errors  = 0;
  int n_tests = 0;

  // Build a struct in a readable way
  function automatic fp_unpacked_t mk(input logic        s,
                                      input logic [7:0]  e,
                                      input logic [23:0] m,
                                      input logic        z, inf, nan);
    fp_unpacked_t v;
    v.sign    = s;
    v.exp     = e;
    v.mant    = m;
    v.is_zero = z;
    v.is_inf  = inf;
    v.is_nan  = nan;
    return v;
  endfunction

  // ---------------------------------------------------------------
  // Reference model, written from the definition of rounding.
  // The dropped part, in units of the last kept bit (ulp), is:
  //   rnd=0 stk=0 : exactly 0
  //   rnd=0 stk=1 : between 0 and 1/2      -> stay
  //   rnd=1 stk=0 : exactly 1/2  (tie)     -> go to the even neighbour
  //   rnd=1 stk=1 : between 1/2 and 1      -> go up
  // ---------------------------------------------------------------
  function automatic fp_unpacked_t ref_round(input fp_unpacked_t in,
                                             input logic rnd_i, stk_i);
    fp_unpacked_t o;
    int unsigned  m;
    o = in;
    m = in.mant;
    case ({rnd_i, stk_i})
      2'b00, 2'b01: m = m;                         // less than half: keep
      2'b10:        m = (m % 2 == 1) ? m + 1 : m;  // tie: make it even
      2'b11:        m = m + 1;                     // more than half: up
    endcase
    if (m == 32'h0100_0000) begin                  // 1.111...1 + 1 = 10.000...0
      o.mant = 24'h800000;
      o.exp  = in.exp + 8'd1;
      if (in.exp == 8'd254) o.is_inf = 1'b1;       // 2^128: too big -> inf
    end else
      o.mant = m[23:0];
    return o;
  endfunction

  // Apply inputs and compare the whole struct with the expected one
  task automatic check(input fp_unpacked_t in,
                       input logic         rnd_i, stk_i,
                       input fp_unpacked_t expected,
                       input string        name);
    u_in = in; rnd = rnd_i; stk = stk_i;
    #1;
    n_tests++;
    if (u_out !== expected) begin
      errors++;
      $display("FAIL %-26s in: s=%b exp=%3d mant=%h z=%b i=%b n=%b  rnd=%b stk=%b",
               name, in.sign, in.exp, in.mant, in.is_zero, in.is_inf, in.is_nan, rnd_i, stk_i);
      $display("     got      s=%b exp=%3d mant=%h z=%b i=%b n=%b",
               u_out.sign, u_out.exp, u_out.mant, u_out.is_zero, u_out.is_inf, u_out.is_nan);
      $display("     expected s=%b exp=%3d mant=%h z=%b i=%b n=%b",
               expected.sign, expected.exp, expected.mant,
               expected.is_zero, expected.is_inf, expected.is_nan);
    end else if (name != "")
      $display("ok   %-26s -> exp=%3d mant=%h inf=%b", name, u_out.exp, u_out.mant, u_out.is_inf);
  endtask

  fp_unpacked_t in;
  logic [31:0]  r;

  initial begin
    $display("=== Directed tests ===");
    //              input                              rnd stk  expected                            name
    // The four rounding cases (L = mant[0])
    check(mk(0,130,24'h800000,0,0,0), 0,0, mk(0,130,24'h800000,0,0,0), "exact");
    check(mk(0,130,24'h800000,0,0,0), 0,1, mk(0,130,24'h800000,0,0,0), "below half -> keep");
    check(mk(0,130,24'h800000,0,0,0), 1,1, mk(0,130,24'h800001,0,0,0), "above half -> up");
    check(mk(0,130,24'h800000,0,0,0), 1,0, mk(0,130,24'h800000,0,0,0), "tie, L=0 -> keep");
    check(mk(0,130,24'h800001,0,0,0), 1,0, mk(0,130,24'h800002,0,0,0), "tie, L=1 -> up (even)");
    check(mk(0,130,24'h800001,0,0,0), 0,1, mk(0,130,24'h800001,0,0,0), "L=1 below half -> keep");

    // Carry out of the significand
    check(mk(0,130,24'hFFFFFF,0,0,0), 1,1, mk(0,131,24'h800000,0,0,0), "carry: exp+1");
    check(mk(0,130,24'hFFFFFF,0,0,0), 1,0, mk(0,131,24'h800000,0,0,0), "carry from a tie (L=1)");
    check(mk(0,130,24'hFFFFFF,0,0,0), 0,1, mk(0,130,24'hFFFFFF,0,0,0), "all ones, no round up");

    // Overflow: largest normal rounding up
    check(mk(0,254,24'hFFFFFF,0,0,0), 1,1, mk(0,255,24'h800000,0,1,0), "overflow -> inf");
    check(mk(1,254,24'hFFFFFF,0,0,0), 1,1, mk(1,255,24'h800000,0,1,0), "-overflow -> -inf");
    check(mk(0,254,24'hFFFFFF,0,0,0), 0,1, mk(0,254,24'hFFFFFF,0,0,0), "exp 254, no carry: no inf");

    // Denormals (hidden bit 0)
    check(mk(0,  1,24'h7FFFFF,0,0,0), 1,1, mk(0,  1,24'h800000,0,0,0), "largest denormal -> normal");
    check(mk(0,  1,24'h000000,0,0,0), 1,1, mk(0,  1,24'h000001,0,0,0), "0 -> smallest denormal");

    // Pass-through of the other fields
    check(mk(1,130,24'h800001,0,0,0), 1,0, mk(1,130,24'h800002,0,0,0), "sign passes through");
    check(mk(0,255,24'hC00000,0,0,1), 0,0, mk(0,255,24'hC00000,0,0,1), "NaN flag passes through");
    check(mk(1,255,24'h800000,0,1,0), 0,0, mk(1,255,24'h800000,0,1,0), "inf flag passes through");
    check(mk(0,  1,24'h000000,1,0,0), 0,0, mk(0,  1,24'h000000,1,0,0), "zero flag passes through");

    $display("=== Random tests against reference model ===");
    repeat (50000) begin
      r = $urandom();

      in.sign = r[31];

      // Exponent: often 254 to hit the overflow case
      in.exp = ($urandom_range(4) == 0) ? 8'd254 : 8'($urandom_range(1, 254));

      // Mantissa: often all ones (carry), sometimes denormal (hidden bit 0)
      case ($urandom_range(3))
        0:       in.mant = 24'hFFFFFF;
        1:       in.mant = {1'b0, r[22:0]};
        default: in.mant = {1'b1, r[22:0]};
      endcase

      // Flags: rarely set, must just pass through
      in.is_zero = ($urandom_range(9) == 0);
      in.is_inf  = ($urandom_range(9) == 0);
      in.is_nan  = ($urandom_range(9) == 0);

      rnd = $urandom_range(1);
      stk = $urandom_range(1);

      check(in, rnd, stk, ref_round(in, rnd, stk), "");   // "" = print only on failure
    end

    $display("==============================");
    if (errors == 0) $display("PASS: %0d tests", n_tests);
    else             $display("FAIL: %0d errors out of %0d tests", errors, n_tests);
    $display("==============================");
    $finish;
  end

endmodule

`default_nettype wire