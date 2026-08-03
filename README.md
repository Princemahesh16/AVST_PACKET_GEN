# AVST_PACKET_GEN

## 📌 Project Overview

This project implements an **Avalon Streaming (AVST) Packet Generator** in Verilog HDL. The design generates parameterizable packets using the **Ready/Valid handshake protocol** and is suitable for FPGA/ASIC communication interfaces.

The packet generator follows the AVST protocol by generating:
- Start of Packet (SOP)
- End of Packet (EOP)
- Valid
- Empty
- 512-bit Data Bus

---

## 🚀 Features

- 512-bit Data Bus
- Parameterizable Packet Size
- Ready/Valid Handshake
- SOP & EOP Generation
- Empty Signal Support
- FSM-Based Design
- Synthesizable Verilog
- Vivado Compatible

---

## 📂 Project Structure

```
AVST_PACKET_GEN/
│
├── avst_packet_gen.v        # Packet Generator RTL
├── avst_packet_gen_tb.v     # Testbench
├── README.md
├── simulation/
├── waveform/
└── docs/
```

---

## 📖 AVST Interface

| Signal | Width | Description |
|---------|------:|-------------|
| clk | 1 | System Clock |
| rst | 1 | Active High Reset |
| ready | 1 | Receiver Ready |
| valid | 1 | Data Valid |
| sop | 1 | Start of Packet |
| eop | 1 | End of Packet |
| empty | 6 | Number of Invalid Bytes |
| data | 511:0 | Packet Data |

---

## ⚙️ Parameters

| Parameter | Description |
|-----------|-------------|
| TOTAL_BYTES | Total Data Generated |
| BUS_BYTES | Data Width in Bytes |
| PACKET_SIZE | Packet Size |

Example:

```
TOTAL_BYTES = 16384
BUS_BYTES   = 64
PACKET_SIZE = 256
```

---

## 🧠 FSM

The design uses a Finite State Machine (FSM).

```
          +------+
          | IDLE |
          +------+
              |
              v
          +------+
          | SEND |
          +------+
              |
              v
          +------+
          | DONE |
          +------+
```

---

## ▶️ Simulation

The project was verified using:

- Xilinx Vivado Simulator
- Verilog HDL

Simulation checks:

- Reset operation
- Ready/Valid handshake
- SOP generation
- EOP generation
- Packet counting
- Empty signal generation

---

## 🛠️ How to Run

### Clone Repository

```bash
git clone https://github.com/Princemahesh16/AVST_PACKET_GEN.git
```

### Open Vivado

- Create a new project
- Add RTL files
- Add Testbench
- Run Behavioral Simulation

---

## 📊 Expected Output

The waveform should show:

- Valid asserted when Ready is High
- SOP at first beat
- EOP at last beat
- Correct packet size
- Continuous packet generation

---

## 💻 Tools Used

- Verilog HDL
- Xilinx Vivado
- Git
- GitHub

---

## 📚 Applications

- FPGA Data Streaming
- Network Packet Generation
- Avalon Streaming Interfaces
- SoC Design
- ASIC Verification

---

## 👨‍💻 Author

**Princemahesh16**

GitHub: https://github.com/Princemahesh16

---

## ⭐ Repository

If you found this project useful, consider giving it a ⭐ on GitHub.
