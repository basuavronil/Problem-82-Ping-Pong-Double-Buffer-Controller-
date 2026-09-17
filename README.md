# Problem-82-Ping-Pong-Double-Buffer-Controller-
A two-bank memory wrapper where Bank A is written while Bank B is read, swapping roles on a frame_done signal to prevent data corruption during continuous streaming.

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
