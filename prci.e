.ifndef PRCI_E__INCLUDED
.equ PRCI_E__INCLUDED,1

.equ PRCI_BASE, 0x10008

#------ clock.s ------
.equ PRCI_HFROSCCFG,  0x00
.equ PRCI_HFXOSCCFG,  0x04
.equ PRCI_PLLCFG,     0x08
.equ PRCI_PLLOUTDIV,  0x0C
.equ PRCI_PROCMONCFG, 0xF0

#
# everything below should be aon.e, really
#

.equ AON_BASE, 0x10000000

#------ timer.s ------
.equ AON_WDOGCFG,     0x000
.equ AON_WDOGCOUNT,   0x008
.equ AON_WDOGS,       0x010
.equ AON_WDOGFEED,    0x018
.equ AON_WDOGKEY,     0x01C
.equ AON_WDOGCMP0,    0x020

.equ AON_WDOGCFG_KEYVAL,  0x0051F15E
.equ AON_WDOGCFG_FOODVAL, 0x0D09F00D

.equ AON_RTCCFG,      0x040
.equ AON_RTCCOUNT_LO, 0x048
.equ AON_RTCCOUNT_HI, 0x04C
.equ AON_RTCS,        0x050
.equ AON_RTCCMP0,     0x060

#------ clock.s ------
.equ AON_LFROSCCFG,  0x070
.equ AON_LFCLKMUX,   0x07C

#------ backup.s ------
.equ AON_BACKUP_0,   0x080
.equ AON_BACKUP_1,   0x084
.equ AON_BACKUP_2,   0x088
.equ AON_BACKUP_3,   0x08C
.equ AON_BACKUP_4,   0x090
.equ AON_BACKUP_5,   0x094
.equ AON_BACKUP_6,   0x098
.equ AON_BACKUP_7,   0x09C
.equ AON_BACKUP_8,   0x0A0
.equ AON_BACKUP_9,   0x0A4
.equ AON_BACKUP_10,  0x0A8
.equ AON_BACKUP_11,  0x0AC
.equ AON_BACKUP_12,  0x0B0
.equ AON_BACKUP_13,  0x0B4
.equ AON_BACKUP_14,  0x0B8
.equ AON_BACKUP_15,  0x0BC

#------ pmu.s ------
.equ AON_PMUWAKEUP_I0, 0x100
.equ AON_PMUWAKEUP_I1, 0x104
.equ AON_PMUWAKEUP_I2, 0x108
.equ AON_PMUWAKEUP_I3, 0x10C
.equ AON_PMUWAKEUP_I4, 0x110
.equ AON_PMUWAKEUP_I5, 0x114
.equ AON_PMUWAKEUP_I6, 0x118
.equ AON_PMUWAKEUP_I7, 0x11C
.equ AON_PMUSLEEP_I0,  0x120
.equ AON_PMUSLEEP_I1,  0x124
.equ AON_PMUSLEEP_I2,  0x128
.equ AON_PMUSLEEP_I3,  0x12C
.equ AON_PMUSLEEP_I4,  0x130
.equ AON_PMUSLEEP_I5,  0x134
.equ AON_PMUSLEEP_I6,  0x138
.equ AON_PMUSLEEP_I7,  0x13C
.equ AON_PMUIE,        0x140
.equ AON_PMUCAUSE,     0x144
.equ AON_PMUSLEEP,     0x148
.equ AON_PMUKEY,       0x14C

#------ aon.s ------
.equ AON_SIFUVEBANDGAP, 0x210
.equ AON_AONCFG,        0x300

.endif  # PRCI_E__INCLUDED
