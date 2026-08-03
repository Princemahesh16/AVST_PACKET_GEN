module master_top #(
    parameter TOTAL_BYTES = 16384,
    parameter BUS_BYTES   = 64,
    parameter PACKET_SIZE = 256,
    localparam DATA_WIDTH = BUS_BYTES * 8, // Width = 512 bits
    localparam EMPTY_W    = 6
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  start,

    output wire                  master_done,

    input  wire                  ready,  
    output wire                  valid,  
    output wire [DATA_WIDTH-1:0] data,   
    output wire                  sop,    
    output wire                  eop,    
    output wire [EMPTY_W-1:0]    empty,  
    output wire [15:0]           beat_count
);

    // Internal interconnect signals
    wire                 m_fifo_wr_en;
    wire                 m_valid;
    wire                 m_sop;
    wire                 m_eop;
    wire [EMPTY_W-1:0]   m_empty;
    wire [DATA_WIDTH-1:0] m_data;

    wire f_full;
    wire f_empty;
    wire f_rd_en;

     
    // Combinational interconnect nets between submodules
    wire [520:0] fifo_din = {m_valid, m_empty, m_eop, m_sop, m_data};
    wire [520:0] fifo_dout;

    // Combinational unpack of FIFO output bundle
    wire [DATA_WIDTH-1:0] f_rdata      = fifo_dout[511:0];
    wire                  f_sop        = fifo_dout[512];
    wire                  f_eop        = fifo_dout[513];
    wire [EMPTY_W-1:0]    f_empty_bits = fifo_dout[519:514];
    wire                  f_valid      = fifo_dout[520];

    // Instantiate Master Generator FSM
    master_fsm #(
        .TOTAL_BYTES (TOTAL_BYTES),
        .BUS_BYTES   (BUS_BYTES),
        .PACKET_SIZE (PACKET_SIZE),
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_master_fsm (
        .clk         (clk),
        .rst         (rst),
        .start       (start),
        .fifo_full   (f_full),
        .fifo_wr_en  (m_fifo_wr_en),
        .valid       (m_valid),
        .sop         (m_sop),
        .eop         (m_eop),
        .empty       (m_empty),
        .data_out    (m_data),
        .busy        (),
        .packet_done (master_done),
        .beat_count  (beat_count)
    );

    // Instantiate Standard Hardware FIFO IP Block (521 bits wide, Non-FWFT)
    fifo_generator_0 u_tx_fifo (
        .clk   (clk),
        .srst  (rst),
        .din   (fifo_din),
        .wr_en (m_fifo_wr_en),
        .rd_en (f_rd_en),
        .dout  (fifo_dout),
        .full  (f_full),
        .empty (f_empty)
    );

    // Instantiate Master Read Egress FSM Controller
    master_tx_read_fsm #(
        .DATA_WIDTH (DATA_WIDTH),
        .EMPTY_W    (EMPTY_W)
    ) u_master_tx_read_fsm (
        .clk             (clk),
        .rst             (rst),
        .fifo_empty      (f_empty),
        .fifo_rd_en      (f_rd_en),
        .fifo_rdata      (f_rdata),
        .fifo_sop        (f_sop),
        .fifo_eop        (f_eop),
        .fifo_empty_bits (f_empty_bits),
        .fifo_valid      (f_valid),
        .ready           (ready),
        .valid           (valid),
        .data            (data),
        .sop             (sop),
        .eop             (eop),
        .empty           (empty)
    );

endmodule
