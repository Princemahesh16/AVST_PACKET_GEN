`timescale 1ns / 1ps

module master_fsm #(
    parameter integer TOTAL_BYTES = 16384,
    parameter integer BUS_BYTES   = 64,
    parameter integer PACKET_SIZE = 244,
    parameter integer DATA_WIDTH  = 512
) (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    start,
    input  wire                    fifo_full,

    output wire                    fifo_wr_en,
    output wire                    busy,
    output reg                     valid,
    output reg                     sop,
    output reg                     eop,
    output reg  [5:0]              empty,
    output wire [DATA_WIDTH-1:0]   data_out,
    output reg                     packet_done,
    output reg  [15:0]             beat_count
);

    localparam integer BUS_BITS      = BUS_BYTES * 8;
    localparam integer FULL_PACKETS  = TOTAL_BYTES / PACKET_SIZE;
    localparam integer TAIL_BYTES    = TOTAL_BYTES - (FULL_PACKETS * PACKET_SIZE);
    localparam integer HAS_TAIL_PKT  = (TAIL_BYTES > 0) ? 1 : 0;
    localparam integer TOTAL_PACKETS = FULL_PACKETS + HAS_TAIL_PKT;
    localparam integer FULL_BEATS    = (PACKET_SIZE + BUS_BYTES - 1) / BUS_BYTES;
    localparam integer FULL_EMPTY    = (FULL_BEATS * BUS_BYTES) - PACKET_SIZE;
    localparam integer TAIL_BEATS    = (HAS_TAIL_PKT) ? ((TAIL_BYTES + BUS_BYTES - 1) / BUS_BYTES) : 0;
    localparam integer TAIL_EMPTY    = (HAS_TAIL_PKT) ? ((TAIL_BEATS * BUS_BYTES) - TAIL_BYTES) : 0;

    // 7 State Encodings matching the Design Diagram
    localparam [2:0]
        S0_IDLE        = 3'd0,
        S1_SINGLE_BEAT = 3'd1,
        S2_FIRST_BEAT  = 3'd2,
        S3_MIDDLE_BEAT = 3'd3,
        S4_LAST_BEAT   = 3'd4,
        S5_HOLD        = 3'd5,
        S6_DONE        = 3'd6;

    reg [2:0] current_state, next_state, return_state;
    reg [15:0] packet_count;
    reg [DATA_WIDTH-1:0] data_counter;
    reg [DATA_WIDTH-1:0] tx_data;

    wire is_last_packet    = (packet_count == (TOTAL_PACKETS - 1));
    wire is_tail_active    = (HAS_TAIL_PKT && is_last_packet);
    wire [15:0] beats_per_pack = is_tail_active ? TAIL_BEATS : FULL_BEATS;
    wire [5:0]  target_empty   = is_tail_active ? TAIL_EMPTY[5:0] : FULL_EMPTY[5:0];

    assign data_out   = valid ? tx_data : {DATA_WIDTH{1'b0}};
    assign fifo_wr_en = (current_state != S0_IDLE && current_state != S5_HOLD && current_state != S6_DONE) && !fifo_full;
    assign busy       = (current_state != S0_IDLE && current_state != S6_DONE);

    initial begin
        if (DATA_WIDTH < BUS_BITS) begin
            $display("ERROR: DATA_WIDTH (%0d) < BUS_BYTES*8 (%0d)", DATA_WIDTH, BUS_BITS);
            $finish;
        end
    end

    // 1. CURRENT STATE REGISTER
    always @(posedge clk) begin
        if (rst) begin
            current_state <= S0_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // 2. NEXT STATE LOGIC
    always @(*) begin
        next_state = current_state;

        if (fifo_full && current_state != S0_IDLE && current_state != S5_HOLD && current_state != S6_DONE) 
        begin
            next_state = S5_HOLD;
        end 
        else 
        
        begin
         case (current_state)
                S0_IDLE: begin
                    if (start && !fifo_full) begin
                        if (beats_per_pack == 1)
                            next_state = S1_SINGLE_BEAT;
                        else
                            next_state = S2_FIRST_BEAT;
                        end
                         end

                S1_SINGLE_BEAT: begin
                    if (packet_count == TOTAL_PACKETS - 1)
                        next_state = S6_DONE;
                    else begin
                        if (beats_per_pack == 1)
                            next_state = S1_SINGLE_BEAT;
                        else
                            next_state = S2_FIRST_BEAT;
                    end
                end

                S2_FIRST_BEAT: begin
                    if (beat_count == beats_per_pack - 1)
                        next_state = S4_LAST_BEAT;
                    else
                        next_state = S3_MIDDLE_BEAT;
                end

                S3_MIDDLE_BEAT: begin
                    if (beat_count == beats_per_pack - 1)
                        next_state = S4_LAST_BEAT;
                    else
                        next_state = S3_MIDDLE_BEAT;
                end

                S4_LAST_BEAT: begin
                    if (packet_count == TOTAL_PACKETS - 1)
                        next_state = S6_DONE;
                    else begin
                        if (beats_per_pack == 1)
                            next_state = S1_SINGLE_BEAT;
                        else
                            next_state = S2_FIRST_BEAT;
                    end
                end

                S5_HOLD: begin
                    if (!fifo_full)
                        next_state = return_state;
                end

                S6_DONE: begin
                    next_state = S0_IDLE;
                end

                default: next_state = S0_IDLE;
            endcase
        end
    end

    // 3. OUTPUT LOGIC & DATAPATH COUNTERS
    always @(posedge clk) begin
        if (rst) begin
            return_state <= S0_IDLE;
            beat_count   <= 16'd0;
            packet_count <= 16'd0;
            data_counter <= {DATA_WIDTH{1'b0}} + 1'b1;
            tx_data      <= {DATA_WIDTH{1'b0}};
            valid        <= 1'b0;
            sop          <= 1'b0;
            eop          <= 1'b0;
            empty        <= 6'd0;
            packet_done  <= 1 me1'b0;
        end else begin
            packet_done <= 1'b0;

            if (fifo_full && current_state != S0_IDLE && current_state != S5_HOLD && current_state != S6_DONE) begin
                return_state <= current_state;
                valid        <= 1'b0;
            end else 
            begin
                case (current_state)
                    S0_IDLE: begin
                        valid        <= 1'b0;
                        sop          <= 1'b0;
                        eop          <= 1'b0;
                        empty        <= 6'd0;
                        beat_count   <= 16'd0;
                        packet_count <= 16'd0;
                        data_counter <= {DATA_WIDTH{1'b0}} + 1'b1;
                        tx_data      <= {DATA_WIDTH{1'b0}};

                        if (start && !fifo_full) begin
                            tx_data      <= {DATA_WIDTH{1'b0}} + 1'b1;
                            data_counter <= {DATA_WIDTH{1'b0}} + 2'd2;
                            valid        <= 1'b1;
                            sop          <= 1'b1;
                            
                            if (beats_per_pack == 1) begin
                                eop   <= 1'b1;
                                empty <= target_empty;
                            end else begin
                                eop   <= 1'b0;
                                empty <= 6'd0;
                                beat_count <= 16'd1;
                            end
                        end
                    end

                    S1_SINGLE_BEAT: begin
                        packet_count <= packet_count + 1'b1;
                        if (packet_count == TOTAL_PACKETS - 1) 
                        begin
                            valid <= 1'b0;
                            sop   <= 1'b0;
                            eop   <= 1'b0;
                        end 
                        else 
                        begin
                            tx_data      <= data_counter;
                            data_counter <= data_counter + 1'b1;
                            valid        <= 1'b1;
                            sop          <= 1'b1;
                            if (beats_per_pack == 1) begin
                                eop   <= 1'b1;
                                empty <= target_empty;
                            end else begin
                                eop        <= 1'b0;
                                empty      <= 6'd0;
                                beat_count <= 16'd1;
                            end
                        end
                    end

                    S2_FIRST_BEAT: begin
                        tx_data      <= data_counter;
                        data_counter <= data_counter + 1'b1;
                        sop          <= 1'b0;

                        if (beat_count == beats_per_pack - 1) begin
                            eop   <= 1'b1;
                            empty <= target_empty;
                        end else begin
                            beat_count <= beat_count + 1'b1;
                            eop        <= 1'b0;
                        end
                    end

                    S3_MIDDLE_BEAT: begin
                        tx_data      <= data_counter;
                        data_counter <= data_counter + 1'b1;

                        if (beat_count == beats_per_pack - 1) begin
                            eop   <= 1'b1;
                            empty <= target_empty;
                        end else begin
                            beat_count <= beat_count + 1'b1;
                        end
                    end

                    S4_LAST_BEAT: begin
                        beat_count <= 16'd0;
                        if (packet_count == TOTAL_PACKETS - 1) begin
                            valid <= 1'b0;
                            sop   <= 1 me1'b0;
                            eop   <= 1'b0;
                            empty <= 6'd0;
                        end else begin
                            packet_count <= packet_count + 1'b1;
                            tx_data      <= data_counter;
                            data_counter <= data_counter + 1'b1;
                            valid        <= 1'b1;
                            sop          <= 1'b1;
                            
                            if (beats_per_pack == 1) begin
                                eop   <= 1'b1;
                                empty <= target_empty;
                            end else begin
                                eop        <= 1'b0;
                                empty      <= 6'd0;
                                beat_count <= 16'd1;
                            end
                        end
                    end

                    S5_HOLD: begin
                        valid <= 1'b0;
                        if (!fifo_full) begin
                            valid <= 1'b1;
                        end
                    end

                    S6_DONE: begin
                        packet_done <= 1'b1;
                        valid       <= 1'b0;
                        sop         <= 1'b0;
                        eop         <= 1'b0;
                        empty       <= 6'd0;
                    end

                    default: ;
                endcase
            end
        end
    end

endmodule