
`timescale 1ns / 1ps

`define ZERO_WORD  64'h00000000_00000000
`define ONE_WORD   64'hffffffff_ffffffff
`define PC_START   64'h00000000_80000000  
`define REG_BUS    63 : 0     

//exe_stage ,inst_opcode 
`define INST_ADD   8'h00
`define INST_AND   8'h01
`define INST_OR    8'h02
`define INST_SUB   8'h03
`define INST_XOR   8'h04
`define INST_SRL   8'h05
`define INST_SLL   8'h06
`define INST_SLT   8'h07
`define INST_SLTU  8'h08
`define INST_SRA   8'h09
`define INST_BGE   8'h0a
