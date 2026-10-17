`default_nettype none

// Self-checking testbench for unpacker
//  Part 1: directed vectors with hand-computed expected fields
//  Part 2: random vectors, checked against ModelSim's own float conversion
//          ($bitstoshortreal), which is independent of your RTL

module tb_unpacker;
  import fpu_pkg::*;

  logic [31:0]  x;
  fp_unpacked_t u;
  int           errors = 0;
  int           n_tests = 0;

  unpacker dut (.x(x), .u(u));

  // ---------------------------------------------------------------
  // Directed check: apply x, compare every field with the expected one
  // ---------------------------------------------------------------
  task automatic check(input logic [31:0] in,
                       input logic        s,
                       input logic [7:0]  e,
                       input logic [23:0] m,
                       input logic        z, inf, nan,
                       input string       name);
    x = in;
    #1;
    n_tests++;
    if (u.sign !== s || u.exp !== e || u.mant !== m ||
        u.is_zero !== z || u.is_inf !== inf || u.is_nan !== nan) begin
      errors++;
      $display("FAIL %-18s x=%h", name, in);
      $display("     got      s=%b exp=%3d mant=%h zero=%b inf=%b nan=%b",
               u.sign, u.exp, u.mant, u.is_zero, u.is_inf, u.is_nan);
      $display("     expected s=%b exp=%3d mant=%h zero=%b inf=%b nan=%b",
               s, e, m, z, inf, nan);
    end else
      $display("ok   %-18s x=%h", name, in);
  endtask

  // ---------------------------------------------------------------
  // Rebuild the real value from the unpacked fields:
  //   value = (-1)^sign * mant * 2^(exp - 127 - 23)
  // mant is a 24-bit integer here, hence the extra -23.
  // ---------------------------------------------------------------
  function automatic real value_of(fp_unpacked_t v);
    real r;
    r = real'(v.mant) * (2.0 ** (int'(v.exp) - 150));
    return v.sign ? -r : r;
  endfunction

  real         ref_v;
  logic [31:0] r;

  initial begin
    $display("=== Directed tests ===");
    //      input         s  exp   mant       z  i  n   name
    check(32'h41CC0000, 0, 131, 24'hCC0000, 0, 0, 0, "25.5");
    check(32'hC27D0000, 1, 132, 24'hFD0000, 0, 0, 0, "-63.25");
    check(32'h43640000, 0, 134, 24'hE40000, 0, 0, 0, "228");
    check(32'h3F800000, 0, 127, 24'h800000, 0, 0, 0, "1.0");
    check(32'h00000000, 0,   1, 24'h000000, 1, 0, 0, "+0");
    check(32'h80000000, 1,   1, 24'h000000, 1, 0, 0, "-0");
    check(32'h00000001, 0,   1, 24'h000001, 0, 0, 0, "smallest denormal");
    check(32'h80000001, 1,   1, 24'h000001, 0, 0, 0, "-smallest denormal");
    check(32'h007FFFFF, 0,   1, 24'h7FFFFF, 0, 0, 0, "largest denormal");
    check(32'h00800000, 0,   1, 24'h800000, 0, 0, 0, "smallest normal");
    check(32'h7F7FFFFF, 0, 254, 24'hFFFFFF, 0, 0, 0, "largest normal");
    check(32'h7F800000, 0, 255, 24'h800000, 0, 1, 0, "+inf");
    check(32'hFF800000, 1, 255, 24'h800000, 0, 1, 0, "-inf");
    check(32'h7FC00000, 0, 255, 24'hC00000, 0, 0, 1, "quiet NaN");
    check(32'h7F800001, 0, 255, 24'h800001, 0, 0, 1, "signaling NaN");

    $display("=== Random tests ===");
    repeat (30000) begin
      // Bias the random inputs so zeros/denormals and inf/NaN
      // are tested often, not just 1 time in 256
      r = $urandom();
      case ($urandom_range(2))
        0: x = r;                          // any value
        1: x = {r[31], 8'h00, r[22:0]};    // zero or denormal
        2: x = {r[31], 8'hFF, r[22:0]};    // inf or NaN
      endcase
      #1;
      n_tests++;

      if (x[30:23] != 8'hFF) begin
        // Finite number: value rebuilt from fields must equal the
        // simulator's own interpretation of the 32 bits
        ref_v = real'($bitstoshortreal(x));
        if (value_of(u) != ref_v || u.is_zero !== (ref_v == 0.0) ||
            u.is_inf !== 1'b0 || u.is_nan !== 1'b0) begin
          errors++;
          $display("FAIL random x=%h  value from fields=%g  expected=%g  zero=%b inf=%b nan=%b",
                   x, value_of(u), ref_v, u.is_zero, u.is_inf, u.is_nan);
        end
      end else begin
        // Exponent all ones: only the flags matter
        if (u.is_inf !== (x[22:0] == 0) || u.is_nan !== (x[22:0] != 0) ||
            u.is_zero !== 1'b0) begin
          errors++;
          $display("FAIL random x=%h  inf=%b nan=%b zero=%b", x, u.is_inf, u.is_nan, u.is_zero);
        end
      end
    end

    $display("==============================");
    if (errors == 0) $display("PASS: %0d tests", n_tests);
    else             $display("FAIL: %0d errors out of %0d tests", errors, n_tests);
    $display("==============================");
    $finish;
  end

endmodule

`default_nettype wire
