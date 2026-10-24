
`timescale 1ns/1ps

module tb_fpu_top_2;

    import fpu_pkg::*;



    // Codes d'operation (input_config_reg2)
    localparam logic [7:0] OP_ADD = 8'b00;
    localparam logic [7:0] OP_SUB = 8'b01;

    // Etat DONE de la FSM de fpu_top (IDLE=0, BUSY=1, DONE=2)
    localparam logic [1:0] ST_IDLE = 2'd0;
    localparam logic [1:0] ST_BUSY = 2'd1;
    localparam logic [1:0] ST_DONE = 2'd2;


    logic        CLK;
    logic        RST;
    logic [31:0] input_data_reg;
    logic [7:0]  input_ctrl_reg1;
    logic [7:0]  input_config_reg2;
    logic [31:0] output_data_reg;

    // Bits de input_ctrl_reg1
    localparam logic [7:0] LOAD_A = 8'b00000001;
    localparam logic [7:0] LOAD_B = 8'b00000010;
    localparam logic [7:0] START  = 8'b00000100;
    localparam logic [7:0] CLEAR  = 8'b00001000;

    // Instanciation du module à tester
    fpu_top dut (
        .CLK(CLK),
        .RST(RST),
        .input_data_reg(input_data_reg),
        .input_ctrl_reg1(input_ctrl_reg1),
        .input_config_reg2(input_config_reg2),
        .output_data_reg(output_data_reg)
    );

    // Horloge 50 MHz
    initial CLK = 1'b0;
    always #10 CLK = ~CLK;

    task automatic _(input logic [31:0] data, input logic [7:0] opcode1, input logic [7:0] opcode2);
        @(negedge CLK);
        input_data_reg     = data;
        input_ctrl_reg1    = opcode1;
        input_config_reg2  = opcode2;
    endtask

    task automatic reset();
        @(negedge CLK);
        RST = 1'b1;
        input_ctrl_reg1    = 8'b00000000;
        input_config_reg2  = 8'b00000000;
        input_data_reg     = 32'b0;
        @(negedge CLK);
        RST = 1'b0;
    endtask

    initial begin

        reset();
        // 1+2 = 3
        _(32'h3f800000, LOAD_A, 8'b00000000); // 1.0 
        _(32'h40000000, LOAD_B, 8'b00000000); // 2.0
        _(32'h00000000, START, OP_ADD);
        _(32'h00000000, 8'b00000000, 8'b00000000);
        _(32'h00000000, CLEAR, 8'b00000000);
        reset();
            

    end


endmodule
