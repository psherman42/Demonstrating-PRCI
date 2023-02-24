################################################
## START.S
##
## entry point main reset vector
##
## https://github.com/psherman42/Demonstrating-MTVEC
## 
## 2020-04-02 pds    initial cut
## 2021-11-24 pds    add read_csr and write_csr
##

.include "csr.e"  # for interrupt stuff

.section .text

.globl _start
_start:
  lui a1, 0x80004  # top of ram
  addi sp, a1, -4

  csrrci x0, mstatus, (CSR_MSTATUS_MIE | CSR_MSTATUS_SIE)  # disable interrupts

  lui t0, %hi(CSR_MIE_MEIE | CSR_MIE_MTIE | CSR_MIE_MSIE)
  addi t0, t0, %lo(CSR_MIE_MEIE | CSR_MIE_MTIE | CSR_MIE_MSIE)
  csrrc zero, mie, t0

  # BUG FIX: must explicitly clear pending bits
  lui t0, %hi(CSR_MIP_MEIP | CSR_MIP_MTIP | CSR_MIP_MSIP)
  addi t0, t0, %lo(CSR_MIP_MEIP | CSR_MIP_MTIP | CSR_MIP_MSIP)
  csrrc zero, mip, t0

  # set trap handler
  lui t0, %hi(clint_trap_handler) 
  addi t0, t0, %lo(clint_trap_handler)
#  srl t0, t0, 2  # mtvec.MODE [1:0] = 0
#  sll t0, t0, 2
#  andi t0, t0, 0xFFFFFFFC  # mtvec.BASE [1:0] 0=direct, 1=vector
  csrrw zero, mtvec, t0

  jal main
  j .

.balign 8  # required 64-bit alignment for mtvec in vectored (non-direct) mode
clint_trap_handler: .weak clint_trap_handler

.end
