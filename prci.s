################################################
## PRCI.S
## 
## 2022-09-01 pds    initial cut
##

.include "prci.e"

.section .bss

PRCI_STATE:
.word 0

PLLDAT:
.byte 0, 0, 0, 0
.equ PLLR, 0
.equ PLLF, 1
.equ PLLQ, 2
.equ PLLD, 3

HFCLK_HZ:
.word 0

.section .text

clock_set_pll_dat:
  lui t0, %hi(PLLDAT)
  addi t0, t0, %lo(PLLDAT)
  sb a0, PLLR(t0)
  sb a1, PLLF(t0)
  sb a2, PLLQ(t0)
  sb a3, PLLD(t0)
  ret

clock_get_clk_hz:
  lui t0, %hi(HFCLK_HZ)
  addi t0, t0, %lo(HFCLK_HZ)
  lw a0, 0(t0)
  ret

clock_set_clk_hz:
  lui t0, %hi(HFCLK_HZ)
  addi t0, t0, %lo(HFCLK_HZ)
  sw a0, 0(t0)
  ret

#
# primitives
#
#   clock_hfrosc_ena   clock_hfxosc_ena
#   clock_hfrosc_dis   clock_hfxosc_dis
#
#   clock_pllsel_hfr   clock_pllrefsel_hfr   clock_bypass_pll_on
#   clock_pllsel_pll   clock_pllrefsel_hfx   clock_bypass_pll_off
#
#   clock_hfrosc_adj   clock_pll_adj
#   clock_wait_pll_lock
#

clock_pll_adj: .global clock_pll_adj
#  lui t0, %hi(PLLDAT)
#  addi t0, t0, %lo(PLLDAT)
#  lb a0, PLLR(t0)
#  lb a1, PLLF(t0)
#  lb a2, PLLQ(t0)
#  lb a3, PLLD(t0)
  #
  lui t0, PRCI_BASE
  # pllr=a0, pllf=a1, pllq=a2, plloutdiv=a3
  lui t1, %hi((0x7 << 0) | (0x3f << 4) | (0x3 << 10))
  addi t1, t1, %lo((0x7 << 0) | (0x3f << 4) | (0x3 << 10))
  not t1, t1
  lw t2, PRCI_PLLCFG(t0)      # x = PLLCFG
  and t2, t2, t1              # x &= ~()
  slli t1, a0, 0
  or t2, t2, t1
  slli t1, a1, 4
  or t2, t2, t1
  slli t1, a2, 10
  or t2, t2, t1
  sw t2, PRCI_PLLCFG(t0)      # PLLCFG = x
  #
  addi t1, x0, %lo((0x3f << 0) | (0x1 << 8))
  not t1, t1
  lw t2, PRCI_PLLOUTDIV(t0)   # x = PLLOUTDIV
  and t2, t2, t1
  slli t1, a3, 0
  or t2, t2, t1
  sw t2, PRCI_PLLOUTDIV(t0)   # PLLOUTDIV = x
  #
  ret

clock_hfrosc_adj: .global clock_hfrosc_adj
  lui a3, PRCI_BASE
  # hfroscdiv = a0, hfrosctrim = a1
  lui a2, %hi(0x1f << 16)     # [20:16]
  addi a2, a2, %lo(0x3f << 0) # [5:0]
  not a2, a2
  lw a5, PRCI_HFROSCCFG(a3)   # x = HFROSCCFG
  and a5, a5, a2              # x &= ~((0x1f << 16) | (0x3f << 0))
  slli a2, a0, 0              # x = a0 << 0
  or a5, a5, a2
  slli a2, a1, 16             # x = a1 << 16
  or a5, a5, a2
  sw a5, PRCI_HFROSCCFG(a3)   # HFROSCCFG = x
  #
  ret

clock_hfrosc_dis: .global clock_hfrosc_dis
  lui a3, PRCI_BASE
  # hfrosc_en = 0
  lui a2, %hi(1 << 30)
  not a2, a2                  # ~(1 << 30)
  lw a5, PRCI_HFROSCCFG(a3)   # x = HFROSCCFG
  and a5, a5, a2              # x &= ~(1 << 30)
  sw a5, PRCI_HFROSCCFG(a3)   # HFROSCCFG = x
  #
  ret

clock_hfxosc_dis: .global clock_hfxosc_dis
  lui a3, PRCI_BASE
  # hfxosc_en = 0
  lui a2, %hi(1 << 30)
  not a2, a2                  # ~(1 << 30)
  lw a5, PRCI_HFXOSCCFG(a3)   # x = HFXOSCCFG
  and a5, a5, a2              # x &= ~(1 << 30)
  sw a5, PRCI_HFXOSCCFG(a3)   # HFXOSCCFG = x
  #
  ret


clock_hfrosc_ena: .global clock_hfrosc_ena
  lui a3, PRCI_BASE
  # hfrosc_en = 1
  lui a2, %hi(1 << 30)
  lw a5, PRCI_HFROSCCFG(a3)   # x = HFROSCCFG
  or a5, a5, a2               # x |= (1 << 30)
  sw a5, PRCI_HFROSCCFG(a3)   # HFROSCCFG = x
  # while (hfroscrdy != 1)
  lui a2, %hi(1 << 31)
hfrena_loop:
  lw a5, PRCI_HFROSCCFG(a3)
  and a5, a5, a2              # x &= (1 << 31)
  beqz a5, hfrena_loop        # while (x == 0)
  #
  ret

clock_hfxosc_ena: .global clock_hfxosc_ena
  lui a3, PRCI_BASE
  # hfxosc_en = 1
  lui a2, %hi(1 << 30)
  lw a5, PRCI_HFXOSCCFG(a3)   # x = HFXOSCCFG
  or a5, a5, a2               # x |= (1 << 30)
  sw a5, PRCI_HFXOSCCFG(a3)   # HFXOSCCFG = x
  # while (hfxoscrdy != 1)
  lui a2, %hi(1 << 31)
hfxena_loop:
  lw a5, PRCI_HFXOSCCFG(a3)
  and a5, a5, a2              # x &= (1 << 31)
  beqz a5, hfxena_loop        # while (x == 0)
  #
  ret


clock_pllsel_hfr: .global clock_pllsel_hfr
  lui a3, PRCI_BASE
  # pllsel = 0
  lui a2, %hi(1 << 16)
  not a2, a2                  # ~(1 << 16)
  lw a5, PRCI_PLLCFG(a3)      # x = PLLCFG
  and a5, a5, a2              # x &= ~(1 << 16)
  sw a5, PRCI_PLLCFG(a3)      # PLLCFG = x
  #
  ret

clock_pllsel_pll: .global clock_pllsel_pll
  lui a3, PRCI_BASE
  # pllsel = 1
  lui a2, %hi(1 << 16)
  lw a5, PRCI_PLLCFG(a3)      # x = PLLCFG
  or a5, a5, a2               # x |= (1 << 16)
  sw a5, PRCI_PLLCFG(a3)      # PLLCFG = x
  #
  ret

clock_pllrefsel_hfr: .global clock_pllrefsel_hfr
  lui a3, PRCI_BASE
  # pllrefsel = 0
  lui a2, %hi(1 << 17)
  not a2, a2                  # ~(1 << 17)
  lw a5, PRCI_PLLCFG(a3)      # x = PLLCFG
  and a5, a5, a2              # x &= ~(1 << 17)
  sw a5, PRCI_PLLCFG(a3)      # PLLCFG = x
  #
  ret

clock_pllrefsel_hfx: .global clock_pllrefsel_hfx
  lui a3, PRCI_BASE
  # pllrefsel = 1
  lui a2, %hi(1 << 17)
  lw a5, PRCI_PLLCFG(a3)      # x = PLLCFG
  or a5, a5, a2               # x |= (1 << 17)
  sw a5, PRCI_PLLCFG(a3)      # PLLCFG = x
  #
  ret

clock_bypass_pll_on: .global clock_bypass_pll_on
  lui a3, PRCI_BASE
  # bypass = 0
  lui a2, %hi(1 << 18)
  not a2, a2                  # ~(1 << 18)
  lw a5, PRCI_PLLCFG(a3)      # x = PLLCFG
  and a5, a5, a2              # x &= ~(1 << 18)
  sw a5, PRCI_PLLCFG(a3)      # PLLCFG = x
  #
  ret

clock_bypass_pll_off: .global clock_bypass_pll_off
  lui a3, PRCI_BASE
  # bypass = 1
  lui a2, %hi(1 << 18)
  lw a5, PRCI_PLLCFG(a3)      # x = PLLCFG
  or a5, a5, a2               # x |= (1 << 18)
  sw a5, PRCI_PLLCFG(a3)      # PLLCFG = x
  #
  ret

.equ CLINT_MTIME, 0x200BFF8
.equ CLINT_MTIME_LO, 0x0
.equ CLINT_MTIME_HI, 0x4
.equ CLINT_MTIMECMP0, 0x2004000
.equ CLINT_MTIMECMP0_LO, 0x0
.equ CLINT_MTIMECMP0_HI, 0x4

clock_wait_pll_lock: .global clock_wait_pll_lock
  # settle 100us, first
  lui a3, %hi(CLINT_MTIME)
  addi a3, a3, %lo(CLINT_MTIME)
  sw x0, CLINT_MTIME_LO(a3)   # prevent wrap-around
  lw a2, CLINT_MTIME_LO(a3)   # current time
  addi a2, a2, 4              # 4 = 100us * 32768 cyc/sec
dwellpll_loop:
  lw a5, CLINT_MTIME_LO(a3)   # current time
  blt a5, a2, dwellpll_loop    # while (mtime < (mtime0 + 100us))
  #
  lui a3, PRCI_BASE
  # while (plllock != 1)
  lui a2, %hi(1 << 31)
waitpll_loop:
  lw a5, PRCI_PLLCFG(a3)      # x = PLLCFG
  and a5, a5, a2              # x &= (1 << 31)
  beqz a5, waitpll_loop       # while (x == 0)
  #
  ret

#
# state machine transitions
#
#   begin                            end state
#   state      INIT         XDIR         RDIR         XPLL          RPLL
#   INIT    _init_init   _init_xdir   _init_rdir   _init_xpll   _init_rpll
#   XDIR    _xdir_init   _xdir_xdir   _xdir_rdir   _xdir_xpll   _xdir_rpll
#   RDIR    _rdir_init   _rdir_xdir   _rdir_rdir   _rdir_xpll   _rdir_rpll
#   XPLL    _xpll_init   _xpll_xdir   _xpll_rdir   _xpll_xpll   _xpll_rpll
#   RPLL    _rpll_init   _rpll_xdir   _rpll_rdir   _rpll_xpll   _rpll_rpll
#

# INIT state

clock_init_init: .global clock_init_init
  j clock_init_xdir

clock_init_xdir: .global clock_init_xdir
  csrw mscratch, ra
  jal clock_hfrosc_ena
  jal clock_pllsel_hfr
  jal clock_bypass_pll_off
  jal clock_hfxosc_ena
  jal clock_pllrefsel_hfx
  jal clock_pllsel_pll
  jal clock_hfrosc_dis
  csrr ra, mscratch
  ret

clock_init_rdir: .global clock_init_rdir
  j clock_init_xdir

clock_init_xpll: .global clock_init_xpll
  j clock_init_xdir

clock_init_rpll: .global clock_init_rpll
  j clock_init_xdir

# HFX_DIR state

clock_xdir_xdir: .global clock_xdir_xdir
  # nada
  ret

clock_xdir_rdir: .global clock_xdir_rdir
  csrw mscratch, ra
  jal clock_hfrosc_ena
  jal clock_pllsel_hfr  # run from hfr when changing refsel
  jal clock_hfxosc_dis
  jal clock_pllrefsel_hfr
  addi a0, x0, 5   # div
  addi a1, x0, 8   # trim
  jal clock_hfrosc_adj  # a0=div, a=trim
  jal clock_pllsel_pll
  csrr ra, mscratch
  ret

clock_xdir_xpll: .global clock_xdir_xpll
  csrw mscratch, ra
  jal clock_hfrosc_ena
  jal clock_pllsel_hfr
  addi a0, x0, 1   # r  0
  addi a1, x0, 31  # f  11
  addi a2, x0, 3   # q  1
  addi a3, x0, (1<<8)   # d  5
  jal clock_pll_adj  # ao=r, a1=f, a2=q, a3=d
  jal clock_bypass_pll_on
  jal clock_wait_pll_lock
  jal clock_pllsel_pll
  jal clock_hfrosc_dis
  csrr ra, mscratch
  ret

clock_xdir_rpll: .global clock_xdir_rpll
  csrw mscratch, ra
  jal clock_hfrosc_ena
  jal clock_pllsel_hfr
  jal clock_hfxosc_dis
  jal clock_pllrefsel_hfr
  addi a0, x0, 5   # div
  addi a1, x0, 8   # trim
  jal clock_hfrosc_adj  # a0=div, a=trim
  addi a0, x0, 0   # r
  addi a1, x0, 11  # f
  addi a2, x0, 1   # q
  addi a3, x0, 5   # d
  jal clock_pll_adj  # ao=r, a1=f, a2=q, a3=d
  jal clock_bypass_pll_on
  jal clock_wait_pll_lock
  jal clock_pllsel_pll
  csrr ra, mscratch
  ret

clock_xdir_init: .global clock_xdir_init
  j clock_init_xdir

# HFR_DIR state

clock_rdir_rdir: .global clock_rdir_rdir
  csrw mscratch, ra
  #jal clock_pllsel_hfr  # not needed because HFR can adj while running
  addi a0, x0, 5   # div
  addi a1, x0, 8   # trim
  jal clock_hfrosc_adj
  #jal clock_pllsel_pll  # not needed because HFR can adj while running
  csrr ra, mscratch
  ret

clock_rdir_xdir: .global clock_rdir_xdir
  csrw mscratch, ra
  jal clock_pllsel_hfr  # run from hfr when changing refsel
  jal clock_hfxosc_ena
  jal clock_pllrefsel_hfx
  jal clock_pllsel_pll
  jal clock_hfrosc_dis
  csrr ra, mscratch
  ret

clock_rdir_xpll: .global clock_rdir_xpll
  csrw mscratch, ra
  jal clock_pllsel_hfr
  jal clock_hfxosc_ena
  jal clock_pllrefsel_hfx
  addi a0, x0, 0   # r
  addi a1, x0, 11  # f
  addi a2, x0, 1   # q
  addi a3, x0, 2   # d
  jal clock_pll_adj  # ao=r, a1=f, a2=q, a3=d
  jal clock_bypass_pll_on
  jal clock_wait_pll_lock
  jal clock_pllsel_pll
  jal clock_hfrosc_dis
  csrr ra, mscratch
  ret

clock_rdir_rpll: .global clock_rdir_rpll
  csrw mscratch, ra
  jal clock_pllsel_hfr
  addi a0, x0, 5   # div
  addi a1, x0, 8   # trim
  jal clock_hfrosc_adj  # a0=div, a=trim
  addi a0, x0, 0   # r
  addi a1, x0, 11  # f
  addi a2, x0, 1   # q
  addi a3, x0, 4   # d
  jal clock_pll_adj  # ao=r, a1=f, a2=q, a3=d
  jal clock_bypass_pll_on
  jal clock_wait_pll_lock
  jal clock_pllsel_pll
  csrr ra, mscratch
  ret

clock_rdir_init: .global clock_rdir_init
  j clock_init_xdir

# HFX_PLL state

clock_xpll_xpll: .global clock_xpll_xpll
  csrw mscratch, ra
  jal clock_hfrosc_ena
  jal clock_pllsel_hfr
  jal clock_bypass_pll_off
  addi a0, x0, 0   # r
  addi a1, x0, 11  # f
  addi a2, x0, 1   # q
  addi a3, x0, 5   # d
  jal clock_pll_adj  # ao=r, a1=f, a2=q, a3=d
  jal clock_bypass_pll_on
  jal clock_wait_pll_lock
  jal clock_pllsel_pll
  jal clock_hfrosc_dis
  csrr ra, mscratch
  ret

clock_xpll_xdir: .global clock_xpll_xdir
  csrw mscratch, ra
  jal clock_hfrosc_ena
  jal clock_pllsel_hfr
  jal clock_bypass_pll_off
  jal clock_pllsel_pll
  jal clock_hfrosc_dis
  csrr ra, mscratch
  ret

clock_xpll_rpll: .global clock_xpll_rpll
  csrw mscratch, ra
  jal clock_hfrosc_ena
  jal clock_pllsel_hfr
  jal clock_bypass_pll_off
  jal clock_hfxosc_dis
  jal clock_pllrefsel_hfr
  addi a0, x0, 5   # div
  addi a1, x0, 8   # trim
  jal clock_hfrosc_adj  # a0=div, a=trim
  addi a0, x0, 0   # r
  addi a1, x0, 11  # f
  addi a2, x0, 1   # q
  addi a3, x0, 5   # d
  jal clock_pll_adj  # ao=r, a1=f, a2=q, a3=d
  jal clock_bypass_pll_on
  jal clock_wait_pll_lock
  jal clock_pllsel_pll
  csrr ra, mscratch
  ret

clock_xpll_rdir: .global clock_xpll_rdir
  csrw mscratch, ra
  jal clock_hfrosc_ena
  jal clock_pllsel_hfr
  jal clock_bypass_pll_off
  jal clock_hfxosc_dis
  jal clock_pllrefsel_hfr
  addi a0, x0, 5   # div
  addi a1, x0, 8   # trim
  jal clock_hfrosc_adj  # a0=div, a=trim
  jal clock_pllsel_pll
  csrr ra, mscratch
  ret

clock_xpll_init: .global clock_xpll_init
  j clock_init_xdir

# HFR_PLL state

clock_rpll_rpll: .global clock_rpll_rpll
  csrw mscratch, ra
  jal clock_pllsel_hfr
  jal clock_bypass_pll_off
  addi a0, x0, 5   # div
  addi a1, x0, 8   # trim
  jal clock_hfrosc_adj  # a0=div, a=trim
  addi a0, x0, 0   # r
  addi a1, x0, 11  # f
  addi a2, x0, 1   # q
  addi a3, x0, 5   # d
  jal clock_pll_adj  # ao=r, a1=f, a2=q, a3=d
  jal clock_bypass_pll_on
  jal clock_wait_pll_lock
  jal clock_pllsel_pll
  csrr ra, mscratch
  ret

clock_rpll_xdir: .global clock_rpll_xdir
  csrw mscratch, ra
  jal clock_pllsel_hfr
  jal clock_bypass_pll_off
  jal clock_hfxosc_ena
  jal clock_pllrefsel_hfx
  jal clock_pllsel_pll
  jal clock_hfrosc_dis
  csrr ra, mscratch
  ret

clock_rpll_rdir: .global clock_rpll_rdir
  csrw mscratch, ra
  jal clock_pllsel_hfr
  jal clock_bypass_pll_off
  addi a0, x0, 5   # div
  addi a1, x0, 8   # trim
  jal clock_hfrosc_adj  # a0=div, a=trim
  jal clock_pllsel_pll
  csrr ra, mscratch
  ret

clock_rpll_xpll: .global clock_rpll_xpll
  csrw mscratch, ra
  jal clock_pllsel_hfr
  jal clock_bypass_pll_off
  jal clock_hfxosc_ena
  jal clock_pllrefsel_hfx
  addi a0, x0, 0   # r
  addi a1, x0, 11  # f
  addi a2, x0, 1   # q
  addi a3, x0, 5   # d
  jal clock_pll_adj  # ao=r, a1=f, a2=q, a3=d
  jal clock_bypass_pll_on
  jal clock_wait_pll_lock
  jal clock_pllsel_pll
  jal clock_hfrosc_dis
  csrr ra, mscratch
  ret

clock_rpll_init: .global clock_rpll_init
  j clock_init_xdir


#
# void clock_init_ext (uint32_t hfclk_hz);
#
# Returns:
#  a0 - hfclk_hz
#
# Uses: a2, a3, a5
#

clock_init_ext: .global clock_init_ext
  addi sp, sp, -16     # alloc 3 words
  sw ra, 12(sp)        # push ra
  sw s0, 8(sp)         # push s0
  sw s1, 4(sp)         # push s1

  # ...

  # hfclk_hz = ...
  lui a0, %hi(13800000)        # 13800000 >> 12
  addi a0, a0, %lo(13800000)   # 13800000 - ((13800000 >> 12) << 12)

  lw s1, 4(sp)         # pop s1
  lw s0, 8(sp)         # pop s0
  lw ra, 12(sp)        # pop ra
  addi sp, sp, 16      # dealloc 3 words
  #
  ret
