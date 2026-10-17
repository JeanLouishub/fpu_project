package fpu_pkg;
  localparam int EXP_W  = 8;
  localparam int FRAC_W = 23;
  localparam int BIAS   = 127;

  typedef struct packed {
    logic              sign;
    logic [EXP_W-1:0]  exp;      
    logic [FRAC_W:0]   mant;     // {hidden bit, fraction} = 24 bits
    logic              is_zero;
    logic              is_inf;
    logic              is_nan;
  } fp_unpacked_t;

    
endpackage
