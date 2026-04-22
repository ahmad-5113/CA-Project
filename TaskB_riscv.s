# Initial setup
addi    s1, zero, 16      # 93 04 00 10
addi    s2, zero, 260     # 13 09 40 10

# Load and process
lw      t0, 4(s1)         # 83 a2 04 00
slti    s4, t0, 5         # 13 a4 52 00 (Check if t0 < 5)
srl     s0, s1, s1        # 33 d4 94 00 (Shift Right Logical)

# Conditional Branch
bge     t4, zero, 8       # 63 d4 02 00 (Branch if t4 >= 0)

# Register adjustment and store
addi    s0, zero, 1       # 13 04 10 00
sw      s1, 0(s2)         # 23 20 89 00

# Jump back to start
jal     zero, -12         # 6f f0 9f ff
