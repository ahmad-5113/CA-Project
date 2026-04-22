# Initialization and Setup
0x00: 93 04 00 10    li      s1, 16           # Load immediate 16 into s1
0x04: 13 09 40 10    addi    s2, zero, 260    # Load immediate 260 into s2
0x08: 83 a2 04 00    lw      t0, 4(s1)        # Load word from address (s1 + 4)

# Loop and Branching Logic
0x0C: e3 8e 02 fe    beq     t0, zero, -4     # If t0 == 0, branch back (infinite wait loop)
0x10: 13 85 02 00    addi    a0, t0, 0        # Move t0 to argument register a0
0x14: 23 20 a9 00    sw      a0, 0(s2)        # Store a0 into address pointed by s2

# Jump to Function/Return
0x18: ef 00 80 00    jal     ra, 8            # Jump to offset +8 and link (calling a function)
0x1C: 6f f0 df fe    j       -32              # Jump back to start (Main loop)

# Stack and Frame Management (Epilogue style)
0x20: 13 01 81 ff    addi    sp, sp, -8       # Allocate stack space
0x24: 23 22 11 00    sw      a1, 4(sp)        # Save a1 to stack
0x28: 23 20 81 00    sw      s0, 0(sp)        # Save s0 to stack

# Comparison and Arithmetic
0x2C: 13 04 05 00    addi    s0, a0, 0        # Copy a0 to s0
0x30: 63 00 04 02    beq     s0, zero, 4      # If s0 is zero, skip next instruction
0x34: 23 20 89 00    sw      s1, 0(s2)        # Store s1 into address s2

# Large Constant Loading (Upper Immediate)
0x38: 37 23 26 00    lui     t1, 0x262        # Load 0x262000 into t1
0x3C: 13 03 03 f8    addi    t1, t1, -125     # Fine-tune t1 value
0x40: 13 03 f3 ff    addi    t1, t1, -1       # Adjust t1

# Loop/Branch Control
0x44: e3 1e 03 fe    bne     t1, zero, -4     # Loop until t1 is zero (delay loop)
0x48: 13 04 f4 ff    addi    s0, s0, -1       # Decrement s0
0x4C: 6f f0 5f fe    j       -28              # Jump back

# Cleanup and Return
0x50: 23 20 09 00    sw      zero, 0(s2)      # Clear memory at s2
0x54: 03 24 01 00    lw      s0, 0(sp)        # Restore s0
0x58: 83 20 41 00    lw      ra, 4(sp)        # Restore return address (ra)
0x5C: 13 01 81 00    addi    sp, sp, 8        # Deallocate stack
0x60: 67 80 00 00    ret                      # Return to caller
