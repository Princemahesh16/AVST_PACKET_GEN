# Avalon-ST Packet Streaming System using Dual FIFO (Verilog)

## Overview

This project implements a complete Avalon Streaming (Avalon-ST) packet transfer system in Verilog HDL.

The design demonstrates reliable packet transmission from a Master to a Slave using:

- Avalon-ST Ready/Valid Handshake
- TX FIFO
- RX FIFO
- Master Packet Generator
- Master Read FSM
- Slave Write FSM
- Slave Read FSM
- End-to-End Packet Transfer

The project is designed using modular RTL architecture and verified through simulation in Vivado.

---

## Features

- Avalon-ST Streaming Interface
- 512-bit Data Width
- Parameterizable Packet Size
- SOP (Start of Packet)
- EOP (End of Packet)
- EMPTY Byte Handling
- Ready/Valid Handshake
- TX FIFO Buffering
- RX FIFO Buffering
- Zero-Gap Packet Streaming
- Backpressure Support
- Modular FSM Design
- Fully Parameterized RTL

---

## System Architecture

```
                +----------------------+
                |  Master Packet FSM   |
                +----------+-----------+
                           |
                           |
                           v
                    +-------------+
                    |   TX FIFO   |
                    +-------------+
                           |
                           |
                           v
                 +-------------------+
                 | Master Read FSM   |
                 +-------------------+
                           |
                           |
        Avalon-ST Interface
  ----------------------------------------
  DATA
  VALID
  READY
  SOP
  EOP
  EMPTY
  ----------------------------------------
                           |
                           |
                           v
                 +-------------------+
                 | Slave Write FSM   |
                 +-------------------+
                           |
                           |
                           v
                    +-------------+
                    |   RX FIFO   |
                    +-------------+
                           |
                           |
                           v
                 +-------------------+
                 | Slave Read FSM    |
                 +-------------------+
                           |
                           |
                           v
                       Receiver
```

---

## Project Modules

### 1. master_fsm

Generates packet data.

Functions:

- Packet Generation
- SOP Generation
- EOP Generation
- EMPTY Generation
- Beat Counter
- Packet Counter

States

- IDLE
- FIRST
- MIDDLE
- LAST
- DONE

---

### 2. master_tx_read_fsm

Reads packets from TX FIFO.

Functions

- FIFO Read
- Avalon-ST Valid Generation
- Data Transfer
- SOP/EOP Forwarding

---

### 3. master_top

Integrates

- Master FSM
- TX FIFO
- Master Read FSM

---

### 4. slave_rx_write_fsm

Receives Avalon-ST packets.

Functions

- Accept DATA
- Accept VALID
- Generate READY
- Write RX FIFO

---

### 5. slave_read_fsm

Reads data from RX FIFO.

Functions

- FIFO Read
- Packet Delivery
- Receiver Interface

---

### 6. slave_top

Integrates

- Slave Write FSM
- RX FIFO
- Slave Read FSM

---

### 7. system_top

Top-level module connecting

Master → Avalon-ST Bus → Slave

---

## Avalon-ST Signals

| Signal | Description |
|---------|-------------|
| DATA | Packet Data |
| VALID | Data is valid |
| READY | Receiver is ready |
| SOP | Start of Packet |
| EOP | End of Packet |
| EMPTY | Unused bytes in last beat |

---

## Packet Flow

```
Packet Generator
        │
        ▼
TX FIFO
        │
        ▼
Master Read FSM
        │
        ▼
Avalon-ST Interface
        │
        ▼
Slave Write FSM
        │
        ▼
RX FIFO
        │
        ▼
Slave Read FSM
        │
        ▼
Receiver
```

---

## Test Cases

### Case 1

Normal Streaming

Checks

- Continuous Packet Transfer

---

### Case 2

Delayed Receiver Start

Checks

- Receiver starts late
- Data remains buffered

---

### Case 3

Single Backpressure

Checks

- Receiver Pause
- RX FIFO Buffering
- Resume Transfer

---

### Case 4

Random Backpressure

Checks

- Random Receiver Stalls
- Ready/Valid Robustness

---

### Case 5

Multiple Backpressure Events

Checks

- Multiple Pause/Resume Cycles

---

### Case 6

Continuous Backpressure

Checks

- RX FIFO Full
- READY Deassertion
- Master Stall

---

### Case 7

Single Beat Packet

Checks

- SOP and EOP in same beat

---

### Case 8

Multi Beat Packet

Checks

- SOP
- Middle Beats
- EOP
- EMPTY

---

### Case 9

FIFO Empty Condition

Checks

- No Invalid Reads

---

### Case 10

Reset During Transfer

Checks

- Recovery after Reset

---

## Simulation

Tool

- Xilinx Vivado 2023.2

Language

- Verilog HDL

---

## Parameters

| Parameter | Default |
|------------|----------|
| DATA WIDTH | 512 bits |
| BUS BYTES | 64 Bytes |
| TOTAL BYTES | 16384 |
| PACKET SIZE | Parameterizable |

---

## Verification

Verified using

- Functional Simulation
- Waveform Analysis
- SOP/EOP Validation
- Beat Counter Verification
- Packet Counter Verification
- FIFO Read/Write Verification
- Backpressure Verification
- End-to-End Packet Transfer

---

## Future Improvements

- Avalon-ST Error Signal
- Multi-Channel Streaming
- CRC Generation
- Packet Checker
- Performance Counters
- UVM Verification Environment

---

## 👨‍💻 Author

**Princemahesh16**

GitHub: https://github.com/Princemahesh16

RTL Design | FPGA | Verilog HDL | Avalon-ST | FIFO Design

---

## License

This project is intended for educational and learning purposes.
