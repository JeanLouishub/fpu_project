
`timescale 1ns/1ps

module tb_result_mux;

    import fpu_pkg::*;

    fp_unpacked_t a;
    fp_unpacked_t b;
    fp_unpacked_t result;
    fp_unpacked_t final_result;

    logic op;

    // Instanciation du module à tester
    result_mux dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .final_result(final_result)
    );

    initial begin

        // Valeurs initiales
        a = '0;
        b = '0;
        result = '0;
        op = 1'b0;

        // TEST 1 : NaN + nombre fini => NaN
        a.sign    = 1'b0;
        a.exp     = 8'hFF;
        a.mant    = 24'h400000;
        a.is_zero = 1'b0;
        a.is_inf  = 1'b0;
        a.is_nan  = 1'b1;

        b.sign    = 1'b0;
        b.exp     = 8'd127;
        b.mant    = 24'hC00000;
        b.is_zero = 1'b0;
        b.is_inf  = 1'b0;
        b.is_nan  = 1'b0;

        op = 1'b0;
        result = '0;

        #10;
        $display("TEST 1 : NaN + nombre fini");
        $display("Output: sign=%b exp=%h mant=%h zero=%b inf=%b nan=%b",
                 final_result.sign, final_result.exp, final_result.mant,
                 final_result.is_zero, final_result.is_inf, final_result.is_nan);


        // TEST 2 : +Inf + +Inf => +Inf
        a.sign    = 1'b0;
        a.exp     = 8'hFF;
        a.mant    = 24'h800000;
        a.is_zero = 1'b0;
        a.is_inf  = 1'b1;
        a.is_nan  = 1'b0;

        b.sign    = 1'b0;
        b.exp     = 8'hFF;
        b.mant    = 24'h800000;
        b.is_zero = 1'b0;
        b.is_inf  = 1'b1;
        b.is_nan  = 1'b0;

        op = 1'b0;

        #10;
        $display("TEST 2 : +Inf + +Inf");
        $display("Output: sign=%b exp=%h mant=%h zero=%b inf=%b nan=%b",
                 final_result.sign, final_result.exp, final_result.mant,
                 final_result.is_zero, final_result.is_inf, final_result.is_nan);


        // TEST 3 : +Inf + -Inf => NaN
        a.sign = 1'b0;
        b.sign = 1'b1;
        op = 1'b0;

        #10;
        $display("TEST 3 : +Inf + -Inf");
        $display("Output: sign=%b exp=%h mant=%h zero=%b inf=%b nan=%b",
                 final_result.sign, final_result.exp, final_result.mant,
                 final_result.is_zero, final_result.is_inf, final_result.is_nan);


        // TEST 4 : +Inf - -Inf => +Inf
        a.sign = 1'b0;
        b.sign = 1'b1;
        op = 1'b1;

        #10;
        $display("TEST 4 : +Inf - -Inf");
        $display("Output: sign=%b exp=%h mant=%h zero=%b inf=%b nan=%b",
                 final_result.sign, final_result.exp, final_result.mant,
                 final_result.is_zero, final_result.is_inf, final_result.is_nan);


        // TEST 5 : zéro + nombre fini => nombre fini
        a = '0;
        a.sign    = 1'b0;
        a.exp     = 8'h00;
        a.mant    = 24'h000000;
        a.is_zero = 1'b1;
        a.is_inf  = 1'b0;
        a.is_nan  = 1'b0;

        b.sign    = 1'b0;
        b.exp     = 8'd127;
        b.mant    = 24'hC00000;
        b.is_zero = 1'b0;
        b.is_inf  = 1'b0;
        b.is_nan  = 1'b0;

        op = 1'b0;
        result = b;

        #10;
        $display("TEST 5 : +0 + nombre fini");
        $display("Output: sign=%b exp=%h mant=%h zero=%b inf=%b nan=%b",
                 final_result.sign, final_result.exp, final_result.mant,
                 final_result.is_zero, final_result.is_inf, final_result.is_nan);


        // TEST 6 : zéro - nombre fini => opposé du nombre fini
        op = 1'b1;
        result = b;
        result.sign = 1'b1;

        #10;
        $display("TEST 6 : +0 - nombre fini");
        $display("Output: sign=%b exp=%h mant=%h zero=%b inf=%b nan=%b",
                 final_result.sign, final_result.exp, final_result.mant,
                 final_result.is_zero, final_result.is_inf, final_result.is_nan);


        // TEST 7 : nombre fini + zéro => nombre fini
        a.sign    = 1'b0;
        a.exp     = 8'd127;
        a.mant    = 24'hC00000;
        a.is_zero = 1'b0;
        a.is_inf  = 1'b0;
        a.is_nan  = 1'b0;

        b.sign    = 1'b0;
        b.exp     = 8'h00;
        b.mant    = 24'h000000;
        b.is_zero = 1'b1;
        b.is_inf  = 1'b0;
        b.is_nan  = 1'b0;

        op = 1'b0;
        result = a;

        #10;
        $display("TEST 7 : nombre fini + zéro");
        $display("Output: sign=%b exp=%h mant=%h zero=%b inf=%b nan=%b",
                 final_result.sign, final_result.exp, final_result.mant,
                 final_result.is_zero, final_result.is_inf, final_result.is_nan);


        // TEST 8 : deux nombres finis => résultat du datapath
        a = '0;
        a.sign    = 1'b0;
        a.exp     = 8'd127;
        a.mant    = 24'hC00000;
        a.is_zero = 1'b0;
        a.is_inf  = 1'b0;
        a.is_nan  = 1'b0;

        b = '0;
        b.sign    = 1'b0;
        b.exp     = 8'd127;
        b.mant    = 24'h800000;
        b.is_zero = 1'b0;
        b.is_inf  = 1'b0;
        b.is_nan  = 1'b0;

        result = '0;
        result.sign    = 1'b0;
        result.exp     = 8'd128;
        result.mant    = 24'hC00000;
        result.is_zero = 1'b0;
        result.is_inf  = 1'b0;
        result.is_nan  = 1'b0;

        op = 1'b0;

        #10;
        $display("TEST 8 : deux nombres finis");
        $display("Output: sign=%b exp=%h mant=%h zero=%b inf=%b nan=%b",
                 final_result.sign, final_result.exp, final_result.mant,
                 final_result.is_zero, final_result.is_inf, final_result.is_nan);

        #10;
        $finish;

    end

endmodule
