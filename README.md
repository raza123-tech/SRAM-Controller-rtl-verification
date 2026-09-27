# SRAM Controller RTL Design and Verification

## Overview

This project implements a 256 × 8 SRAM controller using Verilog RTL.

The controller uses an FSM-based architecture to control read and write operations through a bidirectional data bus.

## Features

- 256 × 8 SRAM memory model
- 8-bit address
- 8-bit bidirectional data bus
- Chip Select (CS)
- Write Enable (WE)
- Output Enable (OE)
- Read and write completion indication
- FSM-based control
- Separate READ_DONE and WRITE_DONE states
- Self-checking verification testbench
- Independent expected-memory reference model
- Waveform-based verification

## Architecture

![SRAM Controller Block Diagram](docs/block_diagram.png)

## FSM Architecture

```text
                    +-----------+
                    |   IDLE    |
                    +-----+-----+
                          |
              +-----------+-----------+
              |                       |
        READ REQUEST             WRITE REQUEST
              |                       |
              v                       v
         +---------+             +---------+
         |  READ   |             |  WRITE  |
         +----+----+             +----+----+
              |                       |
              v                       v
        +-----------+           +------------+
        | READ_DONE |           | WRITE_DONE |
        +-----+-----+           +------+-----+
              |                        |
              +-----------+------------+
                          |
                          v
                         IDLE
