module alu
    import fpu_pkg::*;
(
    input  fp_unpacked_t a,
    input  fp_unpacked_t b,
    input  logic         op,       // 0 = addition, 1 = soustraction
    input  logic [7:0]   exp_out,
    input  logic [25:0]  mant_a,
    input  logic [25:0]  mant_b,

    output logic         result_sign,
    output logic [7:0]   result_exp,
    output logic [26:0]  result_mant
);

    logic b_sign_eff;

    logic signed [27:0] signed_a;
    logic signed [27:0] signed_b;
    logic signed [27:0] mant_sum;

    logic        [27:0] magnitude;

    always_comb begin

        // effective sign of b for the operation
        b_sign_eff = b.sign ^ op;

        if (a.sign)
            signed_a = -$signed({2'b00, mant_a});
        else
            signed_a =  $signed({2'b00, mant_a});

        if (b_sign_eff)
            signed_b = -$signed({2'b00, mant_b});
        else
            signed_b =  $signed({2'b00, mant_b});


        mant_sum = signed_a + signed_b;

        // extract the sign and magnitude of the result
        if (mant_sum < 0) begin
            result_sign = 1'b1;
            magnitude   = -mant_sum;
        end
        else begin
            result_sign = 1'b0;
            magnitude   = mant_sum;
        end

        result_mant = magnitude[26:0];
        result_exp  = exp_out;

    end

endmodule

