
`timescale 1ns/1ps

module tb_cmp_align;

    import fpu_pkg::*;

    fp_unpacked_t a;
    fp_unpacked_t b;

    logic [7:0]  exp_out;
    logic [25:0] mant_a;
    logic [25:0] mant_b;

    cmp_align dut (
        .a(a),
        .b(b),
        .exp_out(exp_out),
        .mant_a(mant_a),
        .mant_b(mant_b)
    );

    initial begin

        // Test 1 : exposants egaux
        a.exp  = 8'd10;
        a.mant = 24'hC00000;

        b.exp  = 8'd10;
        b.mant = 24'hA00000;

        #10;
        $display("TEST 1");
        $display("exp_out = %d", exp_out);
        $display("mant_a  = %b", mant_a);
        $display("mant_b  = %b", mant_b);


        // Test 2 : exposant de a plus grand
        a.exp  = 8'd12;
        a.mant = 24'hC00000;

        b.exp  = 8'd10;
        b.mant = 24'hA00000;

        #10;
        $display("TEST 2");
        $display("exp_out = %d", exp_out);
        $display("mant_a  = %b", mant_a);
        $display("mant_b  = %b", mant_b);


        // Test 3 : exposant de b plus grand
        a.exp  = 8'd8;
        a.mant = 24'hC00000;

        b.exp  = 8'd11;
        b.mant = 24'hA00000;

        #10;
        $display("TEST 3");
        $display("exp_out = %d", exp_out);
        $display("mant_a  = %b", mant_a);
        $display("mant_b  = %b", mant_b);

        $finish;

    end

endmodule
