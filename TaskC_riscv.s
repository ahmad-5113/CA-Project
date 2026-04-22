.section .text
.globl _start

_start:
    # --- Initialization ---
    addi    s1, zero, 16        # 93 04 00 10 -> s1 = 16
    addi    s2, zero, 260       # 13 09 40 10 -> s2 = 260
    addi    t2, zero, 1         # 93 03 10 00 -> t2 = 1

    # --- Memory Access & Comparison ---
loop:
    lw      s4, 0(s1)           # 03 a4 04 00 -> Load word from [s1] into s4
    slti    t0, s4, 8           # 93 22 84 00 -> t0 = 1 if s4 < 8, else 0
    bge     s0, s4, skip_store  # 63 84 02 00 -> If s0 >= s4, jump to skip_store

    # --- Write to Peripheral ---
    lui     s4, 8               # 37 84 00 00 -> Load 0x8 into upper bits of s4
    sw      s1, 0(s2)           # 23 20 89 00 -> Store s1 (16) at address [s2]

    # --- Delay Loop Setup ---
skip_store:
    lui     t1, 0x50            # 37 03 50 00 -> Load 0x50000 into t1
delay:
    addi    t1, t1, -1          # 13 03 f3 ff -> Decrement t1
    bne     t1, zero, delay     # e3 1e 03 fe -> Loop until t1 is 0

    # --- Bit Manipulation & Control ---
    srl     s0, s0, t4          # 33 54 74 00 -> Shift Right Logical: s0 = s0 >> t4
    bge     s0, t4, loop        # e3 56 74 fe -> If s0 >= t4, jump back to 'loop'

    # --- Final Jump ---
    jal     zero, start_over    # 6f f0 9f fd -> Jump back to start/initialization
