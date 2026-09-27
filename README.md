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

### Simulation Terminal
<img width="835" height="446" alt="image" src="https://github.com/user-attachments/assets/156bd4ce-c5ef-453b-81a8-c6a4ddc76e15" />
