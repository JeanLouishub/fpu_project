
module normalize
    import fpu_pkg::*;
(
    output fp_unpacked_t u_out,
    output logic         rnd,
    output logic         stk,

    input logic         sign,
    input logic [7:0]   exp,
    input logic [26:0]  mant
);

    

    always_comb begin

        logic [26:0] mant_work;
        logic [7:0]  exp_work;

        mant_work = mant;
        exp_work  = exp;

        u_out.is_zero = 0;
        u_out.is_inf  = 0;
        u_out.is_nan  = 0;

        // Overflow : décalage à droite
        if (mant_work[26]) begin

            if(exp == 8'b11111110) begin
                // +/- inf
                u_out.is_inf = 1;
                exp_work = 8'b11111111;
                mant_work = 27'b0;
            end else begin
            mant_work = mant_work >> 1;
            mant_work[0] = mant[0] | mant[1];
            exp_work  = exp_work + 1'b1;
            end

            end

        else begin
                // on s'arrête à exp = 1 : en dessous, le résultat est dénormal
                // (bit caché à 0), le packer met alors l'exposant à 0
                while (mant_work[25] == 1'b0 && exp_work > 1) begin
                    mant_work = mant_work << 1;
                    exp_work  = exp_work - 1'b1;
                end

                if(mant_work == 27'b0)begin
                    // 0
                    u_out.is_zero = 1;
                    mant_work = 27'b0;
                end
        end

        // Mise à jour de la structure de sortie
        u_out.sign    = sign;
        u_out.exp     = exp_work;
        u_out.mant    = mant_work[25:2];

        // Récupération des bits d'arrondi
        rnd = mant_work[1];
        stk = mant_work[0];
    end

endmodule
