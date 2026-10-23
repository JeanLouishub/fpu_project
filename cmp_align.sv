
module cmp_align
    import fpu_pkg::*;
(
    input  fp_unpacked_t a,
    input  fp_unpacked_t b,

    output logic [7:0]  exp_out,
    output logic [25:0] mant_a,
    output logic [25:0] mant_b
);

    logic [7:0] shift_amount;
    logic [25:0] mant_a_ext;
    logic [25:0] mant_b_ext;
    logic sticky;

    always_comb begin

        // Ajouter les deux bits supplementaires
        mant_a_ext = {a.mant, 2'b00};
        mant_b_ext = {b.mant, 2'b00};
        sticky = 0;

        if (a.exp > b.exp) begin
            exp_out = a.exp;
            shift_amount = a.exp - b.exp;
            mant_b = mant_b_ext >> shift_amount;
            mant_a = mant_a_ext;

            if (shift_amount > 26) begin
                mant_b = 26'b0;
                sticky = 1'b1;
            end else begin
                for (int i = 0; i < shift_amount; i++) begin
                    sticky = sticky | mant_b_ext[i];
                end

                mant_b[0] = mant_b[0] | sticky;
            end

        end
        else begin
            exp_out = b.exp;
            shift_amount = b.exp - a.exp;
            mant_a = mant_a_ext >> shift_amount;
            mant_b = mant_b_ext;

            if (shift_amount > 26) begin
                mant_a = 26'b0;
                sticky = 1'b1;
            end else begin
                for (int i = 0; i < shift_amount; i++) begin
                    sticky = sticky | mant_a_ext[i];
                end

                mant_a[0] = mant_a[0] | sticky;
            end
        end

    end

endmodule
