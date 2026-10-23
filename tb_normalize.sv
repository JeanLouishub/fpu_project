
`timescale 1ns/1ps

module tb_normalize;

    import fpu_pkg::*;

    fp_unpacked_t u_in;
    fp_unpacked_t u_out;

    logic rnd;
    logic stk;

    // Instanciation du module à tester
    normalize dut (
        .u_in(u_in),
        .u_out(u_out),
        .rnd(rnd),
        .stk(stk)
    );

    initial begin

        // Valeurs initiales
        u_in = '0;

        // TEST 1 : Mantisse avec overflow
        u_in.sign    = 1'b0;
        u_in.exp     = 8'd127;
        u_in.mant    = 24'hC00000;
        u_in.is_zero = 1'b0;
        u_in.is_inf  = 1'b0;
        u_in.is_nan  = 1'b0;

        #10;
        $display("TEST 1 : Overflow");
        $display("Input  : sign=%b exp=%0d mant=%h",
                 u_in.sign, u_in.exp, u_in.mant);
        $display("Output : sign=%b exp=%0d mant=%h rnd=%b stk=%b",
                 u_out.sign, u_out.exp, u_out.mant, rnd, stk);

        // TEST 2 : Mantisse nécessitant une normalisation à gauche
        u_in.sign    = 1'b0;
        u_in.exp     = 8'd127;
        u_in.mant    = 24'h200000;
        u_in.is_zero = 1'b0;
        u_in.is_inf  = 1'b0;
        u_in.is_nan  = 1'b0;

        #10;
        $display("TEST 2 : Décalage à gauche");
        $display("Input  : sign=%b exp=%0d mant=%h",
                 u_in.sign, u_in.exp, u_in.mant);
        $display("Output : sign=%b exp=%0d mant=%h rnd=%b stk=%b",
                 u_out.sign, u_out.exp, u_out.mant, rnd, stk);

        // TEST 3 : Mantisse déjà normalisée
        u_in.sign    = 1'b0;
        u_in.exp     = 8'd127;
        u_in.mant    = 24'h800000;
        u_in.is_zero = 1'b0;
        u_in.is_inf  = 1'b0;
        u_in.is_nan  = 1'b0;

        #10;
        $display("TEST 3 : Déjà normalisée");
        $display("Input  : sign=%b exp=%0d mant=%h",
                 u_in.sign, u_in.exp, u_in.mant);
        $display("Output : sign=%b exp=%0d mant=%h rnd=%b stk=%b",
                 u_out.sign, u_out.exp, u_out.mant, rnd, stk);

        // TEST 4 : Nombre spécial zéro
        u_in.sign    = 1'b0;
        u_in.exp     = 8'd0;
        u_in.mant    = 24'h000000;
        u_in.is_zero = 1'b1;
        u_in.is_inf  = 1'b0;
        u_in.is_nan  = 1'b0;

        #10;
        $display("TEST 4 : Zéro");
        $display("Input  : sign=%b exp=%0d mant=%h is_zero=%b",
                 u_in.sign, u_in.exp, u_in.mant, u_in.is_zero);
        $display("Output : sign=%b exp=%0d mant=%h rnd=%b stk=%b",
                 u_out.sign, u_out.exp, u_out.mant, rnd, stk);

        // TEST 5 : Nombre spécial infini
        u_in.sign    = 1'b1;
        u_in.exp     = 8'hFF;
        u_in.mant    = 24'h800000;
        u_in.is_zero = 1'b0;
        u_in.is_inf  = 1'b1;
        u_in.is_nan  = 1'b0;

        #10;
        $display("TEST 5 : Infini");
        $display("Input  : sign=%b exp=%0d mant=%h is_inf=%b",
                 u_in.sign, u_in.exp, u_in.mant, u_in.is_inf);
        $display("Output : sign=%b exp=%0d mant=%h rnd=%b stk=%b",
                 u_out.sign, u_out.exp, u_out.mant, rnd, stk);

        #10;
        $finish;
    end

endmodule
