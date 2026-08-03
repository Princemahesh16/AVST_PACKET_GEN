


module slave_read_fsm #(
    parameter DATA_WIDTH = 512,
    parameter EMPTY_W    = 6
)(
    input  wire                  clk,
    input  wire                  rst,

    // Internal Standard RX FIFO Connections
    input  wire                  fifo_empty,
    output wire                  fifo_rd_en,
    input  wire [DATA_WIDTH-1:0] fifo_rdata,
    input  wire                  fifo_sop,
    input  wire                  fifo_eop,
    input  wire [EMPTY_W-1:0]    fifo_empty_bits,

    // External Request and Output Interface
    input  wire                  slave_read_req,
    output wire [DATA_WIDTH-1:0] rx_payload_data,
    output reg                   rx_data_valid,
    output wire                  rx_sop,
    output wire                  rx_eop,
    output wire [EMPTY_W-1:0]    rx_empty
);

    // Read enable asserts when core requests data and FIFO is not empty
    assign fifo_rd_en = slave_read_req && !fifo_empty;

    // Pipeline valid signal by 1 clock cycle to match Standard FIFO output latency
    always @(posedge clk) begin
        if (rst) begin
            rx_data_valid <= 1'b0;
        end else begin
            rx_data_valid <= fifo_rd_en;
        end
    end

    // Gated combinational outputs
    assign rx_payload_data = fifo_rdata;
    assign rx_sop          = rx_data_valid ? fifo_sop        : 1'b0;
    assign rx_eop          = rx_data_valid ? fifo_eop        : 1'b0;
    assign rx_empty        = rx_data_valid ? fifo_empty_bits : {EMPTY_W{1'b0}};

endmodule