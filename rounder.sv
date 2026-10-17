module rounder //default rounder (round to the nearest)
    import fpu_pkg::*;
(
    input fp_unpacked_t u_in,
    input logic rnd, 
    input logic stk, //rnd = first bit after L (last bit we keep), stck = (or of all_bits_after_R)
    output fp_unpacked_t u_out
);
    logic increment;
    logic [24:0] sum;

    assign increment = rnd & (u_in.mant[0] | stk);
    assign sum = {1'b0 , u_in.mant} + increment;

    

    always_comb begin
        u_out = u_in;
        if (sum[24]) begin //carry out generated 1.111...11 + 1 = 10.000...0
            u_out.mant = 24'h800000; //1.000...0
            u_out.exp = u_in.exp + 8'd1;
            u_out.is_inf = u_in.is_inf | (u_in.exp == 8'd254); //overflow of exponent 
        end
        else begin 
            u_out.mant = sum[23:0];
        end
    end


endmodule
