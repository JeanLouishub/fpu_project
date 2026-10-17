`default_nettype none

// Self-checking testbench for packer
//  Part 1: directed tests, driving the struct directly (as round/special
//          blocks will do in the adder), including flag priority and
//          flags set on top of garbage data
//  Part 2: random round trip  x -> unpacker -> packer -> y,  y must equal x
//          (NaNs must come out as the canonical quiet NaN 0x7FC00000)

module tb_packer;
  import fpu_pkg::*;

  // DUT 1: packer driven directly by the testbench
  fp_unpacked_t u_in;
  logic [31:0]  result;
  packer dut (.u(u_in), .result(result));

  // DUT 2: round trip chain
  logic [31:0]  x, y;
  fp_unpacked_t u_rt;
  unpacker u_unp (.x(x),    .u(u_rt));
  packer   u_pak (.u(u_rt), .result(y));

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

  // Directed check
  task automatic check(input fp_unpacked_t in,
                       input logic [31:0]  expected,
                       input string        name);
    u_in = in;
    #1;
    n_tests++;
    if (result !== expected) begin
      errors++;
      $display("FAIL %-28s in: s=%b exp=%3d mant=%h z=%b i=%b n=%b",
               name, in.sign, in.exp, in.mant, in.is_zero, in.is_inf, in.is_nan);
      $display("     got %h  expected %h", result, expected);
    end else
      $display("ok   %-28s -> %h", name, result);
  endtask

  logic [31:0] r;

  initial begin
    $display("=== Directed tests ===");
    //        s  exp   mant       z  i  n        expected       name
    // Normal numbers
    check(mk(0, 131, 24'hCC0000, 0, 0, 0), 32'h41CC0000, "25.5");
    check(mk(1, 132, 24'hFD0000, 0, 0, 0), 32'hC27D0000, "-63.25");
    check(mk(0, 127, 24'h800000, 0, 0, 0), 32'h3F800000, "1.0");
    check(mk(0, 254, 24'hFFFFFF, 0, 0, 0), 32'h7F7FFFFF, "largest normal");
    check(mk(0,   1, 24'h800000, 0, 0, 0), 32'h00800000, "smallest normal");

    // Denormals: exp = 1 with hidden bit 0 must give exponent field 0
    check(mk(0,   1, 24'h000001, 0, 0, 0), 32'h00000001, "smallest denormal");
    check(mk(1,   1, 24'h000001, 0, 0, 0), 32'h80000001, "-smallest denormal");
    check(mk(0,   1, 24'h7FFFFF, 0, 0, 0), 32'h007FFFFF, "largest denormal");

    // Zero without flag (all-zero mantissa from the datapath)
    check(mk(0,   1, 24'h000000, 0, 0, 0), 32'h00000000, "+0 from data");

    // Flags must win over whatever is in exp/mant (garbage data)
    check(mk(0,  77, 24'h123456, 1, 0, 0), 32'h00000000, "+0 flag, garbage data");
    check(mk(1,  77, 24'h123456, 1, 0, 0), 32'h80000000, "-0 flag, garbage data");
    check(mk(0,   3, 24'hABCDEF, 0, 1, 0), 32'h7F800000, "+inf flag, garbage data");
    check(mk(1,   3, 24'hABCDEF, 0, 1, 0), 32'hFF800000, "-inf flag, garbage data");
    check(mk(1,   3, 24'hABCDEF, 0, 0, 1), 32'h7FC00000, "NaN flag, garbage data");

    // Flag priority: NaN > inf > zero
    check(mk(0,   0, 24'h000000, 0, 1, 1), 32'h7FC00000, "NaN and inf flags");
    check(mk(0,   0, 24'h000000, 1, 0, 1), 32'h7FC00000, "NaN and zero flags");
    check(mk(1,   0, 24'h000000, 1, 1, 0), 32'hFF800000, "inf and zero flags");

    $display("=== Random round trip: pack(unpack(x)) == x ===");
    repeat (30000) begin
      r = $urandom();
      case ($urandom_range(2))
        0: x = r;                          // any value
        1: x = {r[31], 8'h00, r[22:0]};    // zero or denormal
        2: x = {r[31], 8'hFF, r[22:0]};    // inf or NaN
      endcase
      #1;
      n_tests++;

      if (x[30:23] == 8'hFF && x[22:0] != 0) begin
        // Input is a NaN: output must be the canonical quiet NaN
        if (y !== 32'h7FC00000) begin
          errors++;
          $display("FAIL round trip NaN x=%h y=%h (expected 7fc00000)", x, y);
        end
      end else if (y !== x) begin
        errors++;
        $display("FAIL round trip x=%h y=%h", x, y);
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
