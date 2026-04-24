# Setup constants and base addresses
addi s1, zero, 0x100    # s1 = Switch Address
addi s2, zero, 0x104    # s2 = LED Address
addi t2, zero, 1        # t2 = Constant 1 (used for shifting and BGE)

start:
    lw s0, 0(s1)        # Read the current value of the switches into s0
    slti t0, s0, 8      # [NEW INSTRUCTION] If s0 < 8, set t0 to 1. Else, 0.
    beq t0, zero, loop  # If input is >= 8, skip the override
    lui s0, 0x00008     # Override: Set s0 to 0x8000 (32768) for a long sequence

loop:
    sw s0, 0(s2)        # Display current number on the LEDs
    
    # --- Delay Loop (so human eyes can see the LEDs) ---
    lui t1, 0x00500     # UPDATED: Load ~5,242,880 iterations for the 10MHz clock
delay:
    addi t1, t1, -1
    bne t1, zero, delay
    # ---------------------------------------------------

    srl s0, s0, t2      # [NEW INSTRUCTION] Divide s0 by 2 (Shift right by 1)
    bge s0, t2, loop    # [NEW INSTRUCTION] If s0 >= 1, loop back up

    jal zero, start     # When sequence hits 0, restart from the beginning
