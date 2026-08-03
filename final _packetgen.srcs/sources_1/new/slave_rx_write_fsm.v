

module slave_rx_write_fsm #(
    parameter DATA_WIDTH = 512,
    parameter EMPTY_W    = 6
)(
    input  wire                  clk,
    input  wire                  rst,

    input  wire                  valid,
    input  wire [DATA_WIDTH-1:0] data,
    input  wire                  sop,
    input  wire                  eop,
    input  wire [EMPTY_W-1:0]    empty,
    output wire                  ready,

    input  wire                  rx_fifo_full,
    output wire                  rx_fifo_wr_en,
    output wire [520:0]          rx_fifo_din
);

    assign ready         = !rx_fifo_full;
    assign rx_fifo_wr_en = valid && ready;

    // Explicit bit mapping:
    // [511:0] = Data, [512] = SOP, [513] = EOP, [519:514] = Empty, [520] = Valid
    assign rx_fifo_din[511:0]   = data;
    assign rx_fifo_din[512]     = valid ? sop   : 1'b0;
    assign rx_fifo_din[513]     = valid ? eop   : 1'b0;
    assign rx_fifo_din[519:514] = valid ? empty : {EMPTY_W{1'b0}};
    assign rx_fifo_din[520]     = valid;

endmodule

