`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2026 11:41:14 AM
// Design Name: 
// Module Name: Taska
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//TASK A
//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 04/20/2026 04:14:44 PM
// Design Name:
// Module Name: Processor
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

// ===================================================================================
// TOP LEVEL MODULE
// ===================================================================================
module TopLevelProcessor(
    input wire clk,          // 100MHz Basys 3 clock
    input wire rst,
    input wire [15:0] sw,    // Physical Basys 3 Switches
    output reg [15:0] led    // Physical Basys 3 LEDs
);

    // --- 10 MHz Clock Divider ---
    reg [2:0] clk_div_counter;
    reg clk_10MHz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div_counter <= 0;
            clk_10MHz <= 0;
        end else begin
            if (clk_div_counter == 4) begin
                clk_10MHz <= ~clk_10MHz;
                clk_div_counter <= 0;
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end
        end
    end

    // --- Internal Wires ---
    wire [31:0] PC_out, PC_in, instr, imm, PC4, branch_target;
    wire [31:0] readData1, readData2, alu_result, mem_read_data, writeData;
    wire [31:0] alu_in2, final_read_data, mem_or_alu, pc_branch_next;
    wire [3:0] alu_control;
    wire [1:0] aluOp;
    wire branch, memRead, memToReg, memWrite, aluSrc, regWrite, zero;
    wire jump, jalr_sel, PCSrc;

    // --- Core Modules ---
    ProgramCounter PC_unit (.clk(clk_10MHz), .rst(rst), .PC_in(PC_in), .PC_out(PC_out));
    pcAdder pcAdd (.PC_out(PC_out), .PC4_out(PC4));
    instructionMemory IM (.instAddress(PC_out), .instruction(instr));

    mainControl CU (
        .opcode(instr[6:0]),
        .jump(jump),
        .jalr_sel(jalr_sel),
        .branch(branch),
        .memRead(memRead),
        .memToReg(memToReg),
        .aluOp(aluOp),
        .memWrite(memWrite),
        .aluSrc(aluSrc),
        .regWrite(regWrite)
    );

    registerFile RF (
        .clk(clk_10MHz),
        .rf_en(regWrite),
        .rs1(instr[19:15]),
        .rs2(instr[24:20]),
        .rd(instr[11:7]),
        .writeData(writeData),
        .readData1(readData1),
        .readData2(readData2)
    );

    immGen imm_unit (.instr_in(instr), .imm(imm));

    aluControlUnit ACU (
        .aluOp(aluOp),
        .funct3(instr[14:12]),
        .funct7(instr[30]),
        .alu_control(alu_control)
    );

    mux2 alumux (.PC4_in(readData2), .target_in(imm), .select(aluSrc), .PC_next(alu_in2));

    alu MyALU (
        .a(readData1),
        .b(alu_in2),
        .alu_control(alu_control),
        .result(alu_result),
        .zero(zero)
    );

    assign PCSrc = jump | (branch & zero);
    branchAdder brAdd (.PC_out(PC_out), .imm(imm), .branch_target(branch_target));

    mux2 pcmux (.PC4_in(PC4), .target_in(branch_target), .select(PCSrc), .PC_next(pc_branch_next));
    mux2 jalr_pcmux (.PC4_in(pc_branch_next), .target_in(alu_result), .select(jalr_sel), .PC_next(PC_in));

    dataMemory DM (
        .clk(clk_10MHz),
        .memWrite(memWrite),
        .memRead(memRead),
        .address(alu_result),
        .writeData(readData2),
        .readData(mem_read_data)
    );

    // MMIO
    assign final_read_data = (alu_result == 32'h00000100) ? {16'b0, sw} : mem_read_data;

    always @(posedge clk_10MHz or posedge rst) begin
        if (rst) led <= 16'b0;
        else if (memWrite && alu_result == 32'h00000104) led <= readData2[15:0];
    end

    mux2 wbmux (.PC4_in(alu_result), .target_in(final_read_data), .select(memToReg), .PC_next(mem_or_alu));
    mux2 jump_wb_mux (.PC4_in(mem_or_alu), .target_in(PC4), .select(jump), .PC_next(writeData));

endmodule

// ===================================================================================
// SUB-MODULES
// ===================================================================================

module ProgramCounter(input wire clk, rst, input wire [31:0] PC_in, output reg [31:0] PC_out);
    always @(posedge clk or posedge rst) begin
        if (rst) PC_out <= 32'd0;
        else PC_out <= PC_in;
    end
endmodule

module pcAdder(input wire [31:0] PC_out, output wire [31:0] PC4_out);
    assign PC4_out = PC_out + 32'd4;
endmodule

module branchAdder(input wire [31:0] PC_out, input wire [31:0] imm, output wire [31:0] branch_target);
    assign branch_target = PC_out + (imm << 1);
endmodule

module mux2(input wire [31:0] PC4_in, target_in, input wire select, output wire [31:0] PC_next);
    assign PC_next = select ? target_in : PC4_in;
endmodule

module immGen(input wire [31:0] instr_in, output reg [31:0] imm);
    always @ (*) begin
        case(instr_in[6:0])
            7'b0010011, 7'b0000011, 7'b1100111: imm = $signed(instr_in[31:20]);
            7'b0100011: imm = $signed({instr_in[31:25], instr_in[11:7]});
            7'b1100011: imm = $signed({instr_in[31], instr_in[7], instr_in[30:25], instr_in[11:8]});
            7'b0110111: imm = {instr_in[31:12], 12'b0};
            7'b1101111: imm = $signed({instr_in[31], instr_in[19:12], instr_in[20], instr_in[30:21]});
            default: imm = 32'd0;
        endcase
    end
endmodule

module mainControl(input wire [6:0] opcode, output reg jump, jalr_sel, branch, memRead, memToReg, output reg [1:0] aluOp, output reg memWrite, aluSrc, regWrite);
    always @(*) begin
        jump = 0; jalr_sel = 0; branch = 0; memRead = 0; memToReg = 0; aluOp = 2'b00; memWrite = 0; aluSrc = 0; regWrite = 0;
        case(opcode)
            7'b0110011: begin regWrite = 1; aluOp = 2'b10; end
            7'b0010011: begin aluSrc = 1; regWrite = 1; aluOp = 2'b11; end
            7'b0000011: begin aluSrc = 1; memToReg = 1; regWrite = 1; memRead = 1; end
            7'b0100011: begin aluSrc = 1; memWrite = 1; end
            7'b1100011: begin branch = 1; aluOp = 2'b01; end
            7'b0110111: begin aluSrc = 1; regWrite = 1; aluOp = 2'b00; end
            7'b1101111: begin jump = 1; regWrite = 1; end
            7'b1100111: begin jump = 1; jalr_sel = 1; aluSrc = 1; regWrite = 1; aluOp = 2'b00; end
        endcase
    end
endmodule

module registerFile(input wire clk, rf_en, input wire [4:0] rs1, rs2, rd, input wire [31:0] writeData, output wire [31:0] readData1, readData2);
    reg [31:0] registers [0:31];
    integer i;
    initial for(i=0; i<32; i=i+1) registers[i] = 32'b0;
    assign readData1 = (rs1 == 5'b0) ? 32'b0 : registers[rs1];
    assign readData2 = (rs2 == 5'b0) ? 32'b0 : registers[rs2];
    always @(posedge clk) if(rf_en && rd != 5'b0) registers[rd] <= writeData;
endmodule

module aluControlUnit(input wire [1:0] aluOp, input wire [2:0] funct3, input wire funct7, output reg [3:0] alu_control);
    always @(*) begin
        case(aluOp)
            2'b00: alu_control = 4'b0010;
            2'b01: alu_control = (funct3 == 3'b001) ? 4'b0111 : 4'b0110;
            2'b10: begin
                if(funct3 == 3'b000 && funct7 == 0) alu_control = 4'b0010;
                else if(funct3 == 3'b000 && funct7 == 1) alu_control = 4'b0110;
                else if(funct3 == 3'b111) alu_control = 4'b0000;
                else if(funct3 == 3'b110) alu_control = 4'b0001;
                else alu_control = 4'b0010;
            end
            2'b11: alu_control = 4'b0010;
            default: alu_control = 4'b0010;
        endcase
    end
endmodule

module alu(input wire [31:0] a, b, input wire [3:0] alu_control, output reg [31:0] result, output wire zero);
    always @(*) begin
        case(alu_control)
            4'b0000: result = a & b;
            4'b0001: result = a | b;
            4'b0010: result = a + b;
            4'b0110: result = a - b;
            4'b0111: result = a - b;
            default: result = 32'b0;
        endcase
    end
    assign zero = (alu_control == 4'b0111) ? (result != 32'b0) : (result == 32'b0);
endmodule

module dataMemory(input wire clk, memWrite, memRead, input wire [31:0] address, writeData, output wire [31:0] readData);
    reg [31:0] memory [0:255];
    integer i;
    initial for(i=0; i<256; i=i+1) memory[i] = 32'b0;
    assign readData = memRead ? memory[address >> 2] : 32'b0;
    always @(posedge clk) if(memWrite) memory[address >> 2] <= writeData;
endmodule

module instructionMemory#(parameter OPERAND_LENGTH = 31)(input wire [OPERAND_LENGTH:0] instAddress, output reg [31:0] instruction);
    reg [7:0] memory [0:255];
    initial $readmemh("inst_mem.mem", memory);
    always @(*) instruction = {memory[instAddress + 3], memory[instAddress + 2], memory[instAddress + 1], memory[instAddress]};
endmodule
