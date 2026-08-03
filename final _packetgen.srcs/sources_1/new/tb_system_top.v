`timescale 1ns / 1ps

// ============================================================================
// Testbench: tb_system_top
// Description: Multi-run simulation asserting start and slave_read_req.
// ============================================================================
module tb_system_top;

    localparam CLK_PERIOD = 10;

    reg clk;
    reg rst;
    reg start;
    reg slave_read_req;

    wire         master_done;
    wire [511:0] rx_payload_data;
    wire         rx_data_valid;
    wire         rx_sop;
    wire         rx_eop;
    wire [5:0]   rx_empty;
    wire [15:0]  beat_count;

    integer packet_count = 0;
    integer run_count    = 0;

    // DUT Instance
    system_top #(
        .TOTAL_BYTES (16384),
        .BUS_BYTES   (64),
        .PACKET_SIZE (256)
    ) dut (
        .clk             (clk),
        .rst             (rst),
        .start           (start),
        .master_done     (master_done),
        .slave_read_req  (slave_read_req),
        .rx_payload_data (rx_payload_data),
        .rx_data_valid   (rx_data_valid),
        .rx_sop          (rx_sop),
        .rx_eop          (rx_eop),
        .rx_empty        (rx_empty),
        .beat_count      (beat_count)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Monitor
    always @(posedge clk) begin
        if (rx_data_valid && rx_eop) begin
            packet_count <= packet_count + 1;
        end
    end

    // Test Sequence
    initial begin
        rst            = 1;
        start          = 0;
        slave_read_req = 0;
        run_count      = 0;

        repeat(5) @(posedge clk);
        rst <= 0; // Release reset cleanly

  // --- Case 1: Normal Condition ---
      slave_read_req <= 1'b1;
      @(posedge clk); start <= 1'b1;
      @(posedge clk); start <= 1'b0;
      wait(master_done);

//  // --- Case 5: System Reset Test ---
//      @(posedge clk); start <= 1;
//      @(posedge clk); start <= 0;
//      repeat(3) @(posedge clk);
//      rst <= 1; 
//      repeat(2) @(posedge clk); 
//      rst <= 0;

//    // --- Case 3: Slave Backpressure Test ---
//        slave_read_req <= 1;
//        @(posedge clk); 
//        start <= 1; 
//        @(posedge clk); 
//        start <= 0;

//        wait(rx_data_valid);
//        slave_read_req <= 0; // Pause reading
//        repeat(5) @(posedge clk);
//        slave_read_req <= 1; // Resume reading
//        wait(master_done);

//  // --- Case 4: Master FIFO Full Test ---
//      slave_read_req <= 0;
//      @(posedge clk); start <= 1;
//      @(posedge clk); start <= 0;
//      wait(dut.u_master_top.f_full);
//      @(posedge clk);
//      slave_read_req <= 1;
//      wait(master_done);

//  // --- Case 6 & 7: Check Flags on Small / Odd Packets ---
//      @(posedge clk); start <= 1;
//      @(posedge clk); start <= 0;
//      wait(rx_data_valid && rx_eop);

        repeat(10) @(posedge clk);
        $finish;
    end

endmodule