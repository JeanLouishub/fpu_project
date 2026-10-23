
module result_mux
    import fpu_pkg::*;
(
    input  fp_unpacked_t a,
    input  fp_unpacked_t b,
    input  logic         op, // 0 = addition, 1 = soustraction
    input  fp_unpacked_t result,

    output fp_unpacked_t final_result
);

    logic b_sign_eff;

    always_comb begin

        // Par défaut
        final_result = result;

        b_sign_eff = b.sign ^ op;

       // Nan
        if (a.is_nan || b.is_nan) begin
            final_result.sign    = 1'b0;
            final_result.exp     = 8'hFF;
            final_result.mant    = 24'h1;
            final_result.is_zero = 1'b0;
            final_result.is_inf  = 1'b0;
            final_result.is_nan  = 1'b1;
        end

        else if (a.is_inf || b.is_inf) begin

            if (a.is_inf && b.is_inf) begin

                // Même signe effectif 
                if (a.sign == b_sign_eff) begin
                    final_result = a;
                end

                // Signes opposés 
                else begin
                    final_result.sign    = 1'b0;
                    final_result.exp     = 8'hFF;
                    final_result.mant    = 24'h1;
                    final_result.is_zero = 1'b0;
                    final_result.is_inf  = 1'b0;
                    final_result.is_nan  = 1'b1;
                end

            end

            // Seul a est infini
            else if (a.is_inf) begin
                final_result = a;
            end

            else begin
                final_result = b;
                final_result.sign = b_sign_eff;
            end
        end


        else if (a.is_zero && b.is_zero) begin

            final_result.sign = (a.sign == b_sign_eff)
                              ? a.sign : 1'b0;

            final_result.exp     = 8'h00;
            final_result.mant    = 24'h000000;
            final_result.is_zero = 1'b1;
            final_result.is_inf  = 1'b0;
            final_result.is_nan  = 1'b0;
        end

        else if (a.is_zero) begin
            final_result = b;
            final_result.sign = b_sign_eff;
        end


        else if (b.is_zero) begin
            final_result = a;
        end

    end

endmodule
