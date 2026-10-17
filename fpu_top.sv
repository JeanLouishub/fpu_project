module fpu_top
  import fpu_pkg::*;
(
    input  logic        CLK,
    input  logic        RST,
    input  logic [31:0] input_data_reg,
    input  logic [7:0]  input_ctrl_reg1,   // [0] load_a, [1] load_b, [2] start, [3] clear
    input  logic [7:0]  input_config_reg2, // [1:0] op (00 add, 01 sub, ...)
    output logic [31:0] output_data_reg
);

typedef enum logic [1:0] {IDLE, BUSY, DONE} state_t;
state_t state, next;

// control
logic load_a, load_b, start, clear;
logic a_valid, b_valid, ready;
logic [1:0] op;

assign load_a = input_ctrl_reg1[0];
assign load_b = input_ctrl_reg1[1];
assign start  = input_ctrl_reg1[2];
assign clear  = input_ctrl_reg1[3];
assign op     = input_config_reg2[1:0];

// data
logic [31:0] a_reg, b_reg, result_reg;

// processing unit
logic pu_start, dp_done;
logic [31:0] dp_result;
logic [4:0]  dp_flags;

logic start_d;
always_ff @(posedge CLK, posedge RST)
    if (RST) start_d <= 0; else start_d <= start; //start_d -> value of start at previous cycle 

wire start_pulse = start & ~start_d;   // rising edge of start

// operand loading
always_ff @(posedge CLK, posedge RST) begin
    if (RST) begin
        a_valid <= 0;   b_valid <= 0;
        a_reg   <= '0;  b_reg   <= '0;
    end
    else if (clear) begin
        a_valid <= 0;   b_valid <= 0;
    end
    else if (state != BUSY) begin
        if (load_a) begin a_reg <= input_data_reg; a_valid <= 1; end
        if (load_b) begin b_reg <= input_data_reg; b_valid <= 1; end
    end
end

assign ready = a_valid & b_valid;

// FSM
always_ff @(posedge CLK, posedge RST)
    if (RST) state <= IDLE; else state <= next;

always_comb begin
    next = state;
    case (state)
        IDLE: if (start_pulse && ready) next = BUSY;
        BUSY: if (dp_done)        next = DONE;
        DONE: if (clear)          next = IDLE;
              else if (start_pulse && ready) next = BUSY;
        default:                  next = IDLE;
    endcase
end

// capture result
always_ff @(posedge CLK, posedge RST)
    if (RST)                          result_reg <= '0;
    else if (state == BUSY && dp_done) result_reg <= dp_result;

assign output_data_reg = result_reg;

// processing unit
assign pu_start = (state != BUSY) && start_pulse && ready;

processing_unit u_pu (
    .CLK    (CLK),
    .RST    (RST),
    .start  (pu_start),
    .op     (op),
    .a      (a_reg),
    .b      (b_reg),
    .result (dp_result),
    .done   (dp_done),
    .flags  (dp_flags)
);

endmodule