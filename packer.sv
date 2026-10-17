module packer
    import fpu_pkg::*;
(
    input fp_unpacked_t u,
    output logic [31:0] result
);

    always_comb begin
        if      (u.is_nan)  result = 32'h7FC00000;               // canonical quiet NaN
        else if (u.is_inf)  result = {u.sign, 8'hFF, 23'h0};
        else if (u.is_zero) result = {u.sign, 31'h0};
        else result = {u.sign, (u.mant[23] ? u.exp : 8'h00), u.mant[22:0]};
    end

endmodule
