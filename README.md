# Problem-82-Ping-Pong-Double-Buffer-Controller-
A two-bank memory wrapper where Bank A is written while Bank B is read, swapping roles on a frame_done signal to prevent data corruption during continuous streaming.
### Bank Synchronization Constraint

The bank swap (`bank_sel <= ~bank_sel`) occurs **only after every single memory location in the active write bank has been completely written AND every single memory location in the active read bank has been completely read**. 

Because each memory bank contains 16 locations (addresses `0` through `15`), a swap cannot trigger mid-frame. 

If the writer fills Bank B up to location 15 while the reader is still reading Bank A at location 10, the system waits until the reader also finishes reading location 15. Only when all 16 slots of the writing bank are filled **and** all 16 slots of the reading bank are consumed on the exact same clock cycle will the `frame_done` condition evaluate to true, safely toggling `bank_sel` to swap the banks for the next frame.
# Ping-Pong (Double) Buffer Controller

A light, dual-bank memory controller written in Verilog to prevent read-write data corruption in real-time streaming architectures.

## Overview

In high-throughput RTL design (such as video pipelines or digital signal processing), reading and writing to a single memory array at the same time causes data race conditions or requires idling the producer while the consumer reads. 

This repository implements a **Ping-Pong (Double) Buffer Controller**. By swapping between two independent memory arrays (`mem_a` and `mem_b`) using a `frame_done` trigger, the producer writes to one memory bank while the consumer simultaneously reads the previous frame from the other.

---

## How It Works: The Analogy

Think of a Ping-Pong buffer like **two buckets** used by two people: a **Painter** (Write) and a **Cleaner** (Read).

### The Problem with One Bucket
* The painter fills the bucket.
* The cleaner has to wait doing nothing while the painter fills it up.
* If both try to access the bucket at the same time, water spills and gets messy (**Data Corruption**).

### The Solution: Two Buckets (Bucket A & Bucket B)
1. **Step 1:** The painter fills **Bucket A**. Meanwhile, the cleaner empties **Bucket B** (which was filled in the previous cycle).
2. **Step 2:** When the painter finishes filling Bucket A, a signal triggers: **"SWAP!"** (`frame_done`).
3. **Step 3:** The painter immediately starts filling **Bucket B**, while the cleaner starts emptying **Bucket A**.

Both sides run in parallel with **zero wait states** and **zero memory contention**.

---
## Frame Completion & Bank Swap Mechanism

### Internal `frame_done` Definition
Instead of relying on an external input port, `frame_done` is calculated internally using a continuous combinational assignment (`wire`):

```verilog
// Internal continuous assignment wire
wire frame_done;

// Triggers HIGH only when BOTH writer and reader reach address 15 (4'd15) simultaneously
assign frame_done = (wr_en && (wr_addr == 4'd15)) && (rd_en && (rd_addr == 4'd15));

## Block Diagram

```text
                       Ping-Pong Buffer Architecture
                       
                       +---------------------------+
                       |   Ping-Pong Controller    |
                       |                           |
                       |   bank_sel = 0 (Bank A)   |
                       |   bank_sel = 1 (Bank B)   |
                       +-------------+-------------+
                                     |
               +---------------------+---------------------+
               |                                           |
               v                                           v
      +------------------+                        +------------------+
      |   RAM Bank A     |                        |   RAM Bank B     |
      |   (Depth = 16)   |                        |   (Depth = 16)   |
      +------------------+                        +------------------+
        ^              |                            ^              |
        |              |                            |              |
   WRITE|              |READ                   WRITE|              |READ
        |              v                            |              v
+-------+--------------+----+              +--------+--------------+----+
| Write Demux (sel = ~bank) |              | Read Mux (sel = bank)      |
+---------------------------+              +----------------------------+
              ^                                          |
              |                                          v
      Incoming Data Stream                       Outgoing Data Stream


```
# Design Pattern: Transient Event vs. Persistent Register

In digital hardware design (Verilog/VHDL), connecting a temporary signal to long-term memory operations requires a fundamental structural relationship between a **Transient Event** and a **Persistent Register**.

---

## 1. Core Relationship

```text
               +--------------------------------------+
               |      Transient / Temporary Signal    |
               |             (frame_done)             |
               +------------------+-------------------+
                                  |
                                  | Trigger on posedge
                                  v
               +--------------------------------------+
               |          Persistent Register         |
               |              (bank_sel)              |
               +------------------+-------------------+
                                  |
            +---------------------+---------------------+
            |                                           |
            v                                           v
   +------------------+                        +------------------+
   | Write Target     |                        | Read Target      |
   | (mem_a or mem_b) |                        | (mem_b or mem_a) |
   +------------------+                        +------------------+
```
## Output 
### Waveforms
<img width="953" height="112" alt="image" src="https://github.com/user-attachments/assets/b51435f5-0745-40c3-bb69-431a8d454302" />
# Ping-Pong Buffer — Waveform Walkthrough

This document explains the simulation waveform for a **ping-pong (double) buffer**
module. The waveform shows two frames of operation: writing into one buffer
while the other buffer is read, then swapping roles at the frame boundary.

## Signal Overview

| Signal          | Width | Direction | Description                                                    |
|------------------|:----:|:---------:|------------------------------------------------------------------|
| `clk`            | 1    | in        | System clock, drives all synchronous logic                       |
| `rst_n`          | 1    | in        | Active-low asynchronous/synchronous reset                        |
| `wr_en`          | 1    | in        | Write enable, qualifies `wr_addr` / `wr_data`                    |
| `wr_addr[3:0]`   | 4    | in        | Write address into the "active write" buffer (0–15)              |
| `wr_data[7:0]`   | 8    | in        | Data written on each clock while `wr_en` is high                 |
| `rd_en`          | 1    | in        | Read enable, qualifies `rd_addr` / `rd_data`                     |
| `rd_addr[3:0]`   | 4    | in        | Read address into the "active read" buffer (0–15)                |
| `rd_data[7:0]`   | 8    | out       | Data read back from the buffer, valid one cycle after `rd_addr`  |
| `i`              | —    | internal  | Frame counter / testbench index, counts 0 → 16 then wraps        |
| `frame_done`     | 1    | out       | Pulses for one cycle when a full frame (16 words) completes       |

## What "Ping-Pong" Means Here

A ping-pong buffer uses **two independent memories (A and B)**. At any given
time:

- One buffer is the **write target** — the producer fills it with a new
  frame of data.
- The other buffer is the **read source** — the consumer drains the
  *previous* completed frame.

When a frame finishes (`frame_done`), the two roles swap: the buffer that
was just written becomes the new read buffer, and the buffer that was being
read becomes the new write target for the next frame. This lets writing and
reading happen simultaneously without corrupting data that is still being
consumed.

## Waveform Walkthrough

### Frame 0 (index `i = 0 … 15`, first pass)

| Event | Behavior |
|---|---|
| `rst_n` deasserts | Counters and control logic come out of reset |
| `wr_en` = 1 | Write side is active immediately |
| `wr_addr` = 0…15, `wr_data` = 160…175 | 16 words are written into **Buffer A** |
| `rd_en` = 0 (mostly) | Read side is idle — no valid buffer exists yet |
| `rd_data` = `NaN`/`0` | Output is invalid because nothing has been read yet |
| `i` reaches 16 | Frame is complete |
| `frame_done` pulses | Signals the write of Buffer A is finished — buffers swap |

### Frame 1 (index `i = 0 … 15`, second pass)

| Event | Behavior |
|---|---|
| `wr_addr` = 0…15, `wr_data` = 176…191 | A **new** frame is now written into **Buffer B** |
| `rd_en` = 1 | Read side turns on now that Buffer A holds valid data |
| `rd_addr` = 0…15 | Steps through the same addresses just written in Frame 0 |
| `rd_data` = 160…175 | **Matches `wr_data` from Frame 0** — confirms Buffer A is being read back correctly while Buffer B is being written |
| `i` reaches 16 again | `frame_done` pulses again, buffers swap back |

### Key Timing Relationships

- `rd_data[t]` corresponds to `rd_addr[t-1]` (one-cycle read latency, typical
  of synchronous single-port/BRAM-style memories).
- `rd_data` values in Frame 1 exactly reproduce `wr_data` values from Frame
  0 (`160 → 175`), which is the functional proof that the ping-pong swap
  worked: **you always read the buffer that was completed one frame ago**,
  never the buffer currently being written.
- `wr_data` keeps incrementing continuously across frame boundaries
  (`160…175`, then `176…191`), showing the producer never stalls even
  though the underlying physical buffer changed.
- `frame_done` is asserted for a single cycle right at `i == 16`, acting as
  the swap trigger for both read and write pointers.

## Simulation Image

![Ping-pong buffer waveform](waveform.png)

*(Place the waveform screenshot alongside this README, e.g. as
`waveform.png`, and update the path above if your repo structure differs.)*

## Summary

This waveform demonstrates correct double-buffered operation:

1. Frame *N* is written to one physical buffer while frame *N-1* is
   simultaneously read from the other.
2. `rd_data` in frame *N* equals `wr_data` from frame *N-1`, byte for byte.
3. `frame_done` cleanly marks the swap boundary with no overlap or data
   corruption between the read and write sides.

### Simulation Terminal
<img width="835" height="446" alt="image" src="https://github.com/user-attachments/assets/156bd4ce-c5ef-453b-81a8-c6a4ddc76e15" />
