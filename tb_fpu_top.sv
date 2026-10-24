
`timescale 1ns/1ps

module tb_fpu_top;

    import fpu_pkg::*;

    // Bits de input_ctrl_reg1
    localparam int LOAD_A = 0;
    localparam int LOAD_B = 1;
    localparam int START  = 2;
    localparam int CLEAR  = 3;

    // Codes d'operation (input_config_reg2[1:0])
    localparam logic [1:0] OP_ADD = 2'b00;
    localparam logic [1:0] OP_SUB = 2'b01;

    // Etat DONE de la FSM de fpu_top (IDLE=0, BUSY=1, DONE=2)
    localparam logic [1:0] ST_DONE = 2'd2;

    localparam int TIMEOUT_CYCLES = 50;
    localparam int N_RANDOM       = 200;

    logic        CLK;
    logic        RST;
    logic [31:0] input_data_reg;
    logic [7:0]  input_ctrl_reg1;
    logic [7:0]  input_config_reg2;
    logic [31:0] output_data_reg;

    int n_pass = 0;
    int n_fail = 0;

    // Instanciation du module à tester
    fpu_top dut (
        .CLK(CLK),
        .RST(RST),
        .input_data_reg(input_data_reg),
        .input_ctrl_reg1(input_ctrl_reg1),
        .input_config_reg2(input_config_reg2),
        .output_data_reg(output_data_reg)
    );

    // Horloge 100 MHz
    initial CLK = 1'b0;
    always #5 CLK = ~CLK;

    // ------------------------------------------------------------------
    // Modèle de référence : arithmétique IEEE-754 du simulateur
    // ------------------------------------------------------------------
    function automatic logic [31:0] ref_model(input logic [31:0] a,
                                              input logic [31:0] b,
                                              input logic [1:0]  op);
        shortreal ra, rb;
        ra = $bitstoshortreal(a);
        rb = $bitstoshortreal(b);
        if (op[0]) return $shortrealtobits(ra - rb);
        else       return $shortrealtobits(ra + rb);
    endfunction

    function automatic logic is_nan32(input logic [31:0] x);
        return (x[30:23] == 8'hFF) && (x[22:0] != 23'h0);
    endfunction

    // ------------------------------------------------------------------
    // Accès aux registres
    // ------------------------------------------------------------------
    task automatic do_reset();
        RST               = 1'b1;
        input_data_reg    = '0;
        input_ctrl_reg1   = '0;
        input_config_reg2 = '0;
        repeat (2) @(posedge CLK);
        #1 RST = 1'b0;
        @(posedge CLK);
    endtask

    // Une impulsion d'un cycle sur un bit de contrôle
    task automatic pulse_ctrl(input int bit_idx, input logic [31:0] data = '0);
        @(negedge CLK);
        input_data_reg           = data;
        input_ctrl_reg1          = '0;
        input_ctrl_reg1[bit_idx] = 1'b1;
        @(negedge CLK);
        input_ctrl_reg1          = '0;
    endtask

    // Charge A et B, lance l'opération et attend l'état DONE
    task automatic run_op(input  logic [31:0] a,
                          input  logic [31:0] b,
                          input  logic [1:0]  op,
                          output logic [31:0] res,
                          output logic        timeout,
                          output int          cycles );

        input_config_reg2 = {6'b0, op};
        pulse_ctrl(CLEAR);
        pulse_ctrl(LOAD_A, a);
        pulse_ctrl(LOAD_B, b);
        pulse_ctrl(START);

        cycles  = 0;
        timeout = 1'b0;
        while (dut.state != ST_DONE) begin
            @(posedge CLK);
            cycles++;
            if (cycles >= TIMEOUT_CYCLES) begin
                timeout = 1'b1;
                break;
            end
        end
        #1 res = output_data_reg;
    endtask

    // Exécute une opération et compare au modèle de référence
    task automatic check_op(input string       name,
                            input logic [31:0] a,
                            input logic [31:0] b,
                            input logic [1:0]  op);
        logic [31:0] res, expected;
        logic        timeout, ok;
        int          cycles;

        run_op(a, b, op, res, timeout, cycles);
        expected = ref_model(a, b, op);

        // Tous les NaN sont acceptés si un NaN est attendu
        if (is_nan32(expected)) ok = is_nan32(res);
        else                    ok = (res == expected);

        if (timeout) begin
            n_fail++;
            $display("[FAIL] %-28s TIMEOUT (pas d'état DONE après %0d cycles)",
                     name, TIMEOUT_CYCLES);
        end
        else if (ok) begin
            n_pass++;
            $display("[PASS] %-28s %h %s %h = %h , %0d cycles",
                     name, a, (op[0] ? "-" : "+"), b, res, cycles);
        end
        else begin
            n_fail++;
            $display("[FAIL] %-28s %h %s %h = %h (attendu %h)",
                     name, a, (op[0] ? "-" : "+"), b, res, expected);
        end
    endtask

    // ------------------------------------------------------------------
    // Scénario de test
    // ------------------------------------------------------------------
    initial begin
        logic [31:0] ra, rb;
        logic [1:0]  rop;

        do_reset();

        // Opérations normales
        check_op("1.0 + 1.0",            32'h3F800000, 32'h3F800000, OP_ADD);
        check_op("1.5 + 2.25",           32'h3FC00000, 32'h40100000, OP_ADD);
        check_op("3.0 - 1.0",            32'h40400000, 32'h3F800000, OP_SUB);
        check_op("1.0 - 3.0",            32'h3F800000, 32'h40400000, OP_SUB);
        check_op("-2.5 + 1.0",           32'hC0200000, 32'h3F800000, OP_ADD);
        check_op("-2.5 - 1.0",           32'hC0200000, 32'h3F800000, OP_SUB);
        check_op("1.0 + 2^-24 (arrondi)", 32'h3F800000, 32'h33800000, OP_ADD);
        check_op("1.0 + 1e-10 (absorb.)", 32'h3F800000, 32'h2EDBE6FF, OP_ADD);
        check_op("1.0 - 1.0 (annul.)",   32'h3F800000, 32'h3F800000, OP_SUB);
        check_op("1.0000001 - 1.0",      32'h3F800001, 32'h3F800000, OP_SUB);

        // Zéros
        check_op("+0 + +0",              32'h00000000, 32'h00000000, OP_ADD);
        check_op("-0 + -0",              32'h80000000, 32'h80000000, OP_ADD);
        check_op("+0 - +0",              32'h00000000, 32'h00000000, OP_SUB);
        check_op("+0 + 1.5",             32'h00000000, 32'h3FC00000, OP_ADD);
        check_op("+0 - 1.5",             32'h00000000, 32'h3FC00000, OP_SUB);
        check_op("1.5 + -0",             32'h3FC00000, 32'h80000000, OP_ADD);

        // Infinis et NaN
        check_op("+Inf + 1.0",           32'h7F800000, 32'h3F800000, OP_ADD);
        check_op("1.0 - +Inf",           32'h3F800000, 32'h7F800000, OP_SUB);
        check_op("+Inf + +Inf",          32'h7F800000, 32'h7F800000, OP_ADD);
        check_op("+Inf + -Inf",          32'h7F800000, 32'hFF800000, OP_ADD);
        check_op("+Inf - -Inf",          32'h7F800000, 32'hFF800000, OP_SUB);
        check_op("+Inf - +Inf",          32'h7F800000, 32'h7F800000, OP_SUB);
        check_op("NaN + 1.0",            32'h7FC00000, 32'h3F800000, OP_ADD);
        check_op("1.0 - NaN",            32'h3F800000, 32'h7FC00001, OP_SUB);

        // Débordement
        check_op("MAX + MAX (overflow)", 32'h7F7FFFFF, 32'h7F7FFFFF, OP_ADD);
        check_op("-MAX - MAX",           32'hFF7FFFFF, 32'h7F7FFFFF, OP_SUB);

        // Dénormaux
        check_op("MIN_NORM - denorm",    32'h00800000, 32'h00000001, OP_SUB);
        check_op("denorm + denorm",      32'h00000001, 32'h00000001, OP_ADD);
        check_op("MIN_NORM - MIN_NORM/2", 32'h00800000, 32'h00400000, OP_SUB);

        // Tests aléatoires (nombres normaux, exposants proches)
        for (int i = 0; i < N_RANDOM; i++) begin
            ra = $urandom;
            rb = $urandom;
            ra[30:23] = 8'd100 + ($urandom % 50);
            rb[30:23] = 8'd100 + ($urandom % 50);
            rop = {1'b0, $urandom_range(0, 1)};
            check_op($sformatf("aleatoire #%0d", i), ra, rb, rop);
        end

        // Résumé
        $display("--------------------------------------------------");
        $display("Résultat : %0d PASS, %0d FAIL sur %0d tests",
                 n_pass, n_fail, n_pass + n_fail);
        if (n_fail == 0) $display("TOUS LES TESTS SONT PASSES");
        $display("--------------------------------------------------");

        #20;
        $finish;
    end

endmodule
