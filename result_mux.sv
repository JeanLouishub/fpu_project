module result_mux
    import fpu_pkg::*;
(
    input fp_unpacked_t a,
    input fp_unpacked_t b,
    input logic op, // 0 = add, 1 = sub
    input fp_unpacked_t result
    output fp_unpacked_t final_result
);

logic a_nan,a_inf,a_zero;
logic b_nan,b_inf,b_zero;

if(a.is_nan || b.is_nan) begin
    final_result = {1'b0, 8'hFF, 1'b1, 23'h0, 1'b0, 1'b0, 1'b1}; // return NaN
end else if(a.is_inf || b.is_inf) begin
    if(a.is_inf && b.is_inf) begin
        // a and b same sign, return a or b
        if(a.sign == (b.sign ^ op)) begin
            final_result = a;
        end else begin
            final_result = {1'b0, 8'hFF, 1'b1, 23'h0, 1'b0, 1'b0, 1'b1}; // return NaN
        end

    end
    else if(~a.is_inf) begin
        final_result = b;
    end else begin
        final_result = a;
    end
end


endmodule