module slave_top #(
    parameter DATA_WIDTH = 512,
    parameter EMPTY_W    = 6
)(
    input  wire                  clk,
    input  wire                  rst,

    // System Bus Inputs (From Master / Bus Interface)
    input  wire                  valid,
    input  wire [DATA_WIDTH-1:0] data,
    input  wire                  sop,
    input  wire                  eop,
    input  wire [EMPTY_W-1:0]    empty,
    output wire                  ready,

    // Slave Control & Data Interface (To Internal Core Processing Logic)
    input  wire                  slave_read_req,
    output wire [DATA_WIDTH-1:0] rx_payload_data,
    output wire                  rx_data_valid,
    output wire                  rx_sop,
    output wire                  rx_eop,
    output wire [EMPTY_W-1:0]    rx_empty,
    output wire [15:0]           beat_count
);

    // =========================================================================
    // INTERNAL INTERCONNECT LINES
    // =========================================================================
    wire         rx_f_full;
    wire         rx_f_empty;
    wire         rx_f_wr_en;
    wire         rx_f_rd_en;
    wire [520:0] rx_f_din;
    wire [520:0] rx_f_dout;

    // Unpack 521-bit bundle from Standard RX FIFO (combinational wire slicing)
    // Bit mapping: [520] = Valid, [519:514] = Empty, [513] = EOP, [512] = SOP, [511:0] = Data

    wire [DATA_WIDTH-1:0] f_rdata      = rx_f_dout[511:0];
    wire                  f_sop        = rx_f_dout[512];
    wire                  f_eop        = rx_f_dout[513];
    wire [EMPTY_W-1:0]    f_empty_bits = rx_f_dout[519:514];
 
    // RECEIVER BEAT COUNTER LOGIC (aligned to registered RX outputs)
    // 
    reg [15:0] rx_beat_cnt;

// Combinational assign guarantees beat_count is 0 on the exact cycle rx_sop is 1
assign beat_count = rx_sop ? 16'd0 : rx_beat_cnt;

always @(posedge clk) begin
    if (rst) begin
        rx_beat_cnt <= 16'd0;
    end else if (rx_data_valid) begin
        if (rx_sop)
            rx_beat_cnt <= 16'd1;
        else if (rx_eop)
            rx_beat_cnt <= 16'd0;
        else
            rx_beat_cnt <= rx_beat_cnt + 1'b1;
    end else begin
        rx_beat_cnt <= 16'd0;
    end
end
    // 
    // SUBMODULE INSTANTIATIONS
    // 

    // 1. Slave Ingress Write Interface FSM
    slave_rx_write_fsm #(
        .DATA_WIDTH (DATA_WIDTH),
        .EMPTY_W    (EMPTY_W)
    ) u_slave_rx_write_fsm (
        .clk           (clk),
        .rst           (rst),
        .valid         (valid),
        .data          (data),
        .sop           (sop),
        .eop           (eop),
        .empty         (empty),
        .ready         (ready),
        .rx_fifo_full  (rx_f_full),
        .rx_fifo_wr_en (rx_f_wr_en),
        .rx_fifo_din   (rx_f_din)
    );

    // 2. Standard Synchronous RX FIFO Core (Non-FWFT)
    fifo_generator_0 u_rx_fifo (
        .clk   (clk),
        .srst  (rst),
        .din   (rx_f_din),
        .wr_en (rx_f_wr_en),
        .rd_en (rx_f_rd_en),
        .dout  (rx_f_dout),
        .full  (rx_f_full),
        .empty (rx_f_empty)
    );

    // 3. Slave Read Egress Controller FSM
    slave_read_fsm #(
        .DATA_WIDTH (DATA_WIDTH),
        .EMPTY_W    (EMPTY_W)
    ) u_slave_read_fsm (
        .clk             (clk),
        .rst             (rst),
        .fifo_empty      (rx_f_empty),
        .fifo_rd_en      (rx_f_rd_en),
        .fifo_rdata      (f_rdata),
        .fifo_sop        (f_sop),
        .fifo_eop        (f_eop),
        .fifo_empty_bits (f_empty_bits),
        .slave_read_req  (slave_read_req),
        .rx_payload_data (rx_payload_data),
        .rx_data_valid   (rx_data_valid),
        .rx_sop          (rx_sop),
        .rx_eop          (rx_eop),
        .rx_empty        (rx_empty)
    );

endmodule