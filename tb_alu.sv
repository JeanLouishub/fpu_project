
`timescale 1ns/1ps

module tb_alu;

    import fpu_pkg::*;

    fp_unpacked_t a;
    fp_unpacked_t b;

    logic        op;
    logic [7:0]  exp_out;
    logic [25:0] mant_a;
    logic [25:0] mant_b;

    logic        result_sign;
    logic [7:0]  result_exp;
    logic [26:0] result_mant;

    // Instanciation du module à tester
    alu dut (
        .a(a),
        .b(b),
        .op(op),
        .exp_out(exp_out),
        .mant_a(mant_a),
        .mant_b(mant_b),
        .result_sign(result_sign),
        .result_exp(result_exp),
        .result_mant(result_mant)
    );

    initial begin

        // Valeurs initiales
        a = '0;
        b = '0;
        op = 1'b0;
        exp_out = 8'd127;
        mant_a = '0;
        mant_b = '0;

        // TEST 1 : (+5) + (+3) = +8
        a.sign = 1'b0;
        b.sign = 1'b0;
        mant_a = 26'd5;
        mant_b = 26'd3;
        op = 1'b0;

        #10;
        $display("TEST 1 : (+5) + (+3)");
        $display("sign = %b, mant = %0d, exp = %0d",
                 result_sign, result_mant, result_exp);

        // TEST 2 : (+5) - (+3) = +2
        a.sign = 1'b0;
        b.sign = 1'b0;
        mant_a = 26'd5;
        mant_b = 26'd3;
        op = 1'b1;

        #10;
        $display("TEST 2 : (+5) - (+3)");
        $display("sign = %b, mant = %0d, exp = %0d",
                 result_sign, result_mant, result_exp);

        // TEST 3 : (+3) - (+5) = -2
        a.sign = 1'b0;
        b.sign = 1'b0;
        mant_a = 26'd3;
        mant_b = 26'd5;
        op = 1'b1;

        #10;
        $display("TEST 3 : (+3) - (+5)");
        $display("sign = %b, mant = %0d, exp = %0d",
                 result_sign, result_mant, result_exp);

        // TEST 4 : (-5) + (+3) = -2
        a.sign = 1'b1;
        b.sign = 1'b0;
        mant_a = 26'd5;
        mant_b = 26'd3;
        op = 1'b0;

        #10;
        $display("TEST 4 : (-5) + (+3)");
        $display("sign = %b, mant = %0d, exp = %0d",
                 result_sign, result_mant, result_exp);

        // TEST 5 : (-5) + (+5) = 0
        a.sign = 1'b1;
        b.sign = 1'b0;
        mant_a = 26'd5;
        mant_b = 26'd5;
        op = 1'b0;

        #10;
        $display("TEST 5 : (-5) + (+5)");
        $display("sign = %b, mant = %0d, exp = %0d",
                 result_sign, result_mant, result_exp);

        // TEST 6 : (-5) - (+3) = -8
        a.sign = 1'b1;
        b.sign = 1'b0;
        mant_a = 26'd5;
        mant_b = 26'd3;
        op = 1'b1;

        #10;
        $display("TEST 6 : (-5) - (+3)");
        $display("sign = %b, mant = %0d, exp = %0d",
                 result_sign, result_mant, result_exp);

        #10;
        $finish;
    end

endmodule
