`timescale 1ns / 1ps

module master_tx_read_fsm #(
    parameter DATA_WIDTH = 512,
    parameter EMPTY_W    = 6
)(
    input  wire                  clk,
    input  wire                  rst,

    // Interface connected directly to internal Standard TX FIFO
    input  wire                  fifo_empty,
    output reg                   fifo_rd_en,
    input  wire [DATA_WIDTH-1:0] fifo_rdata,
    input  wire                  fifo_sop,
    input  wire                  fifo_eop,
    input  wire [EMPTY_W-1:0]    fifo_empty_bits,
    input  wire                  fifo_valid,

    // External Avalon-ST Bus Connection to Slave Block
    input  wire                  ready, // Ready input from slave
    output reg                   valid,
    output wire [DATA_WIDTH-1:0] data,
    output wire                  sop,
    output wire                  eop,
    output wire [EMPTY_W-1:0]    empty
);

    // State Encoding matching Diagram
    localparam S0_IDLE   = 2'b00;
    localparam S1_STREAM = 2'b01;
    localparam S2_HOLD   = 2'b10;

    reg [1:0] current_state, next_state;

    // Unpack Standard FIFO output directly onto bus outputs
    assign data  = fifo_rdata;
    assign sop   = fifo_sop;
    assign eop   = fifo_eop;
    assign empty = fifo_empty_bits;

     //   STATE REGISTER
     always @(posedge clk) begin
        if (rst) begin
            current_state <= S0_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

     // COMBINATIONAL NEXT-STATE LOGIC (Straight from Diagram Transitions)
     always @(*) begin
        next_state = current_state;

        case (current_state)
            S0_IDLE: begin
                if (ready && !fifo_empty)
                    next_state = S1_STREAM;
            end

            S1_STREAM: begin
                if (!ready || fifo_empty)
                    next_state = S2_HOLD; // Pause Reading
                else
                    next_state = S1_STREAM;
            end

            S2_HOLD: begin
                if (fifo_empty)
                    next_state = S0_IDLE;   // Return Idle
                else if (ready && !fifo_empty)
                    next_state = S1_STREAM; // Resume Read
                else
                    next_state = S2_HOLD;   // Hold (!ready && !fifo_empty)
            end

            default: next_state = S0_IDLE;
        endcase
    end

     // STATE OUTPUT LOGIC (Matching Diagram Definitions Exactly)
     always @(*) begin
        case (current_state)
            S0_IDLE: begin
                valid      = 1'b0;
                fifo_rd_en = ready && !fifo_empty;
            end

            S1_STREAM: begin
                valid      = 1'b1;
                fifo_rd_en = ready && !fifo_empty;
            end

            S2_HOLD: begin
                valid      = 1'b0;
                fifo_rd_en = 1'b0; // Explicitly 0 in HOLD
            end

            default: begin
                valid      = 1'b0;
                fifo_rd_en = 1'b0;
            end
        endcase
    end

endmodule
