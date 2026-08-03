// System-level top wrapper connecting master and slave top modules
// - Structural interconnect only, no direct sequential logic here
module system_top #(
    parameter TOTAL_BYTES = 16384,
    parameter BUS_BYTES   = 64,
    parameter PACKET_SIZE = 256
)(
    input  wire          clk,              
    input  wire          rst,              
    input  wire          start,            
    output wire          master_done,      
    input  wire          slave_read_req,  
    output wire [511:0]  rx_payload_data,  
    output wire          rx_data_valid,    
    output wire          rx_sop,           
    output wire          rx_eop,           
    output wire [5:0]    rx_empty,         
    output wire [15:0]   beat_count,       
    output wire [15:0]   tx_beat_count     
);

    
    // Combinational interconnect wires between master and slave top modules
    wire         bus_ready;
    wire         bus_valid;
    wire [511:0] bus_data;
    wire         bus_sop;
    wire         bus_eop;
    wire [5:0]   bus_empty;

     // MASTER TOP INSTANTIATION
     master_top #(
        .TOTAL_BYTES (TOTAL_BYTES),
        .BUS_BYTES   (BUS_BYTES),
        .PACKET_SIZE (PACKET_SIZE)
    ) u_master_top (
        .clk         (clk),
        .rst         (rst),
        .start       (start),
        .master_done (master_done),
        .ready       (bus_ready),
        .valid       (bus_valid),
        .data        (bus_data),
        .sop         (bus_sop),
        .eop         (bus_eop),
        .empty       (bus_empty),
        .beat_count  (tx_beat_count)
    );

     // SLAVE TOP INSTANTIATION
     slave_top #(
        .DATA_WIDTH (512),
        .EMPTY_W    (6)
    ) u_slave_top (
        .clk             (clk),
        .rst             (rst),
        .valid           (bus_valid),
        .data            (bus_data),
        .sop             (bus_sop),
        .eop             (bus_eop),
        .empty           (bus_empty),
        .ready           (bus_ready),
        .slave_read_req  (slave_read_req),
        .rx_payload_data (rx_payload_data),
        .rx_data_valid   (rx_data_valid),
        .rx_sop          (rx_sop),
        .rx_eop          (rx_eop),
        .rx_empty        (rx_empty),
        .beat_count      (beat_count)
    );

endmodule