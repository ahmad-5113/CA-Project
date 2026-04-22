
`timescale 1ns / 1ps

module tb_StandaloneProcessor();

    // --- Testbench Signals ---
    reg clk;
    reg rst;
    reg [15:0] sw;
    wire [15:0] led;

    // --- Instantiate the Processor ---
    TopLevelProcessor uut (
        .clk(clk),
        .rst(rst),
        .sw(sw),
        .led(led)
    );

    // --- 100 MHz Clock Generation (10ns period) ---
    always #5 clk = ~clk;

    initial begin
        // Initialize basic inputs
        clk = 0;
        rst = 1;
        sw = 0;

        $display("\n==================================================");
        $display("   STANDALONE INSTRUCTION VERIFICATION TESTBENCH  ");
        $display("==================================================");

        // --- Manual Memory Initialization ---
        // Injecting the machine code byte-by-byte directly into the
        // instructionMemory module, bypassing the need for a .mem file.

        // Inst 1: addi x5, x0, 10
        uut.IM.memory[0] = 8'h93; uut.IM.memory[1] = 8'h02; uut.IM.memory[2] = 8'ha0; uut.IM.memory[3] = 8'h00;
       
        // Inst 2: slti x6, x5, 15  (x6 should become 1)
        uut.IM.memory[4] = 8'h13; uut.IM.memory[5] = 8'ha3; uut.IM.memory[6] = 8'hf2; uut.IM.memory[7] = 8'h00;
       
        // Inst 3: slti x7, x5, 5   (x7 should become 0)
        uut.IM.memory[8] = 8'h93; uut.IM.memory[9] = 8'ha3; uut.IM.memory[10] = 8'h52; uut.IM.memory[11] = 8'h00;
       
        // Inst 4: addi x8, x0, 16
        uut.IM.memory[12] = 8'h13; uut.IM.memory[13] = 8'h04; uut.IM.memory[14] = 8'h00; uut.IM.memory[15] = 8'h01;
       
        // Inst 5: addi x2, x0, 2
        uut.IM.memory[16] = 8'h13; uut.IM.memory[17] = 8'h01; uut.IM.memory[18] = 8'h20; uut.IM.memory[19] = 8'h00;
       
        // Inst 6: srl x9, x8, x2   (x9 should become 4)
        uut.IM.memory[20] = 8'hb3; uut.IM.memory[21] = 8'h54; uut.IM.memory[22] = 8'h24; uut.IM.memory[23] = 8'h00;
       
        // Inst 7: bge x5, x2, +8   (10 >= 2 is true, jumps over Inst 8)
        uut.IM.memory[24] = 8'h63; uut.IM.memory[25] = 8'hd4; uut.IM.memory[26] = 8'h22; uut.IM.memory[27] = 8'h00;
       
        // Inst 8: addi x10, x0, 99 (Trap! Should be skipped)
        uut.IM.memory[28] = 8'h13; uut.IM.memory[29] = 8'h05; uut.IM.memory[30] = 8'h30; uut.IM.memory[31] = 8'h06;
       
        // Inst 9: addi x10, x0, 100(Target of BGE, x10 should become 100)
        uut.IM.memory[32] = 8'h13; uut.IM.memory[33] = 8'h05; uut.IM.memory[34] = 8'h40; uut.IM.memory[35] = 8'h06;

        // Hold reset for a few cycles to clear all registers and apply memory
        #50;
        rst = 0;

        // Wait for processor to fetch and execute.
        // Clock is 100MHz, but internal clock divider makes it 10MHz.
        // 9 instructions = 900ns minimum. Waiting 1500ns to be safe.
        #1500;

        // --- Console Output / Register Verification ---
        $display("\n--- SLTI (Set Less Than Immediate) Test ---");
        $display("x5 (Base value)   = %0d", uut.RF.registers[5]);
        $display("x6 (SLTI x5 < 15) = %0d  <-- EXPECTED: 1 (True)", uut.RF.registers[6]);
        $display("x7 (SLTI x5 < 5)  = %0d  <-- EXPECTED: 0 (False)", uut.RF.registers[7]);

        $display("\n--- SRL (Shift Right Logical) Test ---");
        $display("x8 (Base value)   = %0d", uut.RF.registers[8]);
        $display("x2 (Shift amount) = %0d", uut.RF.registers[2]);
        $display("x9 (x8 >> x2)     = %0d  <-- EXPECTED: 4", uut.RF.registers[9]);

        $display("\n--- BGE (Branch Greater/Equal) Test ---");
        $display("Condition tested  : Is 10 (x5) >= 2 (x2)?");
        $display("x10 (Final State) = %0d  <-- EXPECTED: 100 (If 99, the branch failed!)", uut.RF.registers[10]);

        $display("\n==================================================");
        $display("                 TEST FINISHED                    ");
        $display("==================================================\n");

        $finish;
    end

endmodule
