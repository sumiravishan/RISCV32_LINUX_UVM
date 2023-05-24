package riscv_uvm_model_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	
	typedef enum bit[2:0] { byte0=0, byte1,bytes2,bytes3,bytes4} mem_byte_size;
	typedef enum bit { sign_Ext=0, no_sign_Ext } sign_format;
	typedef struct packed { bit [24:0] non_opcode; bit [6:0] opcode; } riscv_instruction;
	
	typedef enum bit[6:0] { Load=7'h03, Store=7'h23, Branch=7'h63, Jal=7'h6f, Jalr=7'h67, Lui=7'h37, Auipc=7'h17, Imm_Comp=7'h13, Reg_Comp=7'h33, Zicsr_Ecall_Ebreak=7'h73, RV32_Ext_A=7'h2f } opcodes;
	
	typedef struct packed { bit [6:0] funct7; bit[4:0] rs2; bit [4:0] rs1; bit [2:0] funct3; bit[4:0] rd; } R_format;
	typedef struct packed { bit [11:0] imm; bit [4:0] rs1; bit [2:0] funct3; bit[4:0] rd; } I_format;
	typedef struct packed { bit [19:0] imm; bit[4:0] rd; } U_format;

	typedef struct packed { bit [11:0] imm; bit[4:0] rs2; bit [4:0] rs1; bit [2:0] funct3; } S_format;
	typedef struct packed { bit [12:1] imm; bit[4:0] rs2; bit [4:0] rs1; bit [2:0] funct3; } B_format;
	typedef struct packed { bit [20:1] imm; bit[4:0] rd; } J_format;
	typedef struct packed { bit [4:0] funct5; bit aq; bit rl; bit [4:0] rs2; bit [4:0] rs1; bit [2:0] funct3; bit[4:0] rd; } Ext_A_format;
	
	typedef struct packed { bit [11:0] csr; bit [4:0] rs1; bit [2:0] funct3; bit[4:0] rd; } EXT_Zicsr_Ecall_Ebreak_format;
	
	typedef enum bit[2:0] { LB=0, LH, LW, LRESERVE1, LBU, LHU, LRESERVE2, LRESERVE3 } load_funct3;
	typedef enum bit[2:0] { SB=0, SH, SW, SRESERVE } store_funct3;
	typedef enum bit[2:0] { BEQ=0, BNE, BRESERVE1, BRESERVE2, BLT, BGE, BLTU, BGEU } branch_funct3; 
	typedef enum bit[4:0] { AMOADD_W=0, AMOSWAP, LR_W, SC_W, AMOXOR_W, AMOOR_W=5'h08, AMOAND_W=5'h0C, AMOMIN_W=5'h10, AMOMAX_W=5'h14, AMOMINU_W=5'h18, AMOMAXU_W=5'h1C } Ext_A_funct5;
	
	
	typedef enum bit[2:0] { ADDI=0, SLLI, SLTI, SLTIU, XORI, SRI, ORI, ANDI } Imm_Comp_funct3;
	typedef enum bit { SRLI=0, SRAI } SRI_funct;
	typedef enum bit[2:0] { ADD_SUB=0, SLL, SLT, SLTU, XOR_, SR, OR_, AND_ } Reg_Comp_funct3;
	typedef enum bit { ADD=0, SUB } Add_Sub_funct;
	typedef enum bit { SRL=0, SRA } SR_funct;
	typedef enum bit { noM_EXT=0, M_EXT } Reg_M_Ext;
	typedef enum bit[2:0] { MUL=0,MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU } Reg_Ext_M_funct3;
	typedef enum bit[2:0] { ecall_ebreak=0, CSRRW, CSRRS, CSRRC, CSRESERVE, CSRRWI, CSRRSI, CSRRCI } EXT_Zicsr_Ecall_Ebreak_Funct;
	
	typedef enum bit[11:0] { UR0_cycle=12'hC00, UR0_time, UR0_cycleh=12'hC80, UR0_timeh, addrMSTATUS=12'h300, addrMIE=12'h304, addrMTVEC, addrMEPC=12'h341,addrMCAUSE,
						addrMTVAL, addrMIP } CSRS_ADDR;
						
						
	`include "riscv_memory.svh"
	`include "riscv_isa_register_set.svh"
	`include "csr_registers.svh"
	`include "riscv_core.svh"
	`include "riscv_core_functions.svh"
	
endpackage 
