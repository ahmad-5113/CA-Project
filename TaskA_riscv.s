# =================================================================
# LAB 10: MEMORY-MAPPED FSM COUNTDOWN
# =================================================================
.equ SWITCH_ADDR, 0x100
.equ LED_ADDR,    0x104

.text
.globl start

# --- Hardware Setup ---
# Load the memory-mapped addresses into base registers
addi s1, zero, 0x100        # s1 = 0x100 (Switches)
addi s2, zero, 0x104        # s2 = 0x104 (LEDs)

# =================================================================
# MAIN LOOP: WAITING FOR INPUT
# =================================================================
start:
    lw t0, 0(s1)            # Read physical switches into t0
    beq t0, zero, start     # If switches == 0, loop back and keep waiting
    
    addi a0, t0, 0          # Move the switch value into the argument register (a0)
    sw a0, 0(s2)            # Immediately write the value to the LEDs
    
    jal ra, countdown_state # Jump to the countdown subroutine (saves return address)
    j start                 # When subroutine finishes, loop back to the very beginning

# =================================================================
# SUBROUTINE: COUNTDOWN FSM
# =================================================================
countdown_state:
    # --- Stack Allocation ---
    # Save the return address and s0 register to the stack so we don't lose them
    addi sp, sp, -8         
    sw ra, 4(sp)            
    sw s0, 0(sp)            
    
    addi s0, a0, 0          # Move the starting number (from a0) into s0 to manipulate

count_loop:
    beq s0, zero, done      # If counter hits 0, exit the loop!
    sw s0, 0(s2)            # Output current counter value to the physical LEDs

    # --- Hardware Delay Timer (~0.5 seconds at 10MHz) ---
    # li t1, 2498432 (Expands to lui and addi)
    lui t1, 0x262           # Load upper bits
    addi t1, t1, -128       # Subtract 128 to get exactly 2,498,432 iterations
delay:
    addi t1, t1, -1         # Decrement delay counter
    bne t1, zero, delay     # Keep looping until delay counter hits 0
    # ----------------------------------------------------
    
    addi s0, s0, -1         # Decrement the actual LED counter by 1
    j count_loop            # Jump back up to check condition and update LEDs

done:
    sw zero, 0(s2)          # Turn off all LEDs to signify the sequence is over
    
    # --- Stack Deallocation ---
    # Restore the original values of s0 and ra from the stack
    lw s0, 0(sp)            
    lw ra, 4(sp)            
    addi sp, sp, 8          
    
    jalr zero, 0(ra)        # Return to the main loop using the saved Return Address
