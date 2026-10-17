module unpacker
    import fpu_pkg::*;
(
    input logic [31:0] x,
    output fp_unpacked_t u
);
    //Input x, 32-bit IEEE-754 floating point number
    //Output u, unpacked floating point number with fields u.sign, u.exp, u.mant, u.is_zero, u.is_inf, u.nan

    logic [7:0] exp_field;
    logic [22:0] frac;

    assign exp_field = x[30:23];
    assign frac = x[22:0];

    always_comb begin
        u.sign = x[31];
        u.exp = (exp_field == 8'h0) ? 8'h1 : exp_field; //denormals (values close to 0) use a exp_field = 0
        u.mant = {(exp_field != 8'h0), frac}; //hidden bit = 1 only if exp_field != all_0

        u.is_zero = (exp_field == 8'h0) && (frac == 23'h0); //exp_field = all_0 and frac = all_0
        u.is_inf =  (exp_field == 8'hFF) && (frac == 23'h0); //exp_field = all_1 and frac = all_0
        u.is_nan =  (exp_field == 8'hFF) && (frac != 23'h0); //exp_field = all_1 and frac !=  all_0
    end  


endmodule
