.ifndef CSR_E__INCLUDED
.equ CSR_E__INCLUDED,1

.equ CSR_MSTATUS_MPP,  0x00001800  # [12:11]  machine prev priv mode
.equ CSR_MSTATUS_SPP,  0x00000100  # [8]  supervisor prev prev mode
.equ CSR_MSTATUS_MPIE, 0x00000080  # [7]  machine prev int enable
.equ CSR_MSTATUS_SPIE, 0x00000020  # [5]  supervisor prev int enable
.equ CSR_MSTATUS_MIE,  0x00000008  # [3]  machine int enable
.equ CSR_MSTATUS_SIE,  0x00000002  # [1]  supervisor int enable

.equ CSR_MIE_MEIE,     0x00000800  # [11]  machine external int enable
.equ CSR_MIE_SEIE,     0x00000200  # [9]  supervisor external int enable
.equ CSR_MIE_MTIE,     0x00000080  # [7]  machine timer int enable
.equ CSR_MIE_STIE,     0x00000020  # [5]  supervisor int enable
.equ CSR_MIE_MSIE,     0x00000008  # [3]  machine software int enable
.equ CSR_MIE_SSIE,     0x00000002  # [1]  supervisor software int enable

.equ CSR_MIP_MEIP,     0x00000800  # [11]  machine external int pending
.equ CSR_MIP_SEIP,     0x00000200  # [9]  supervisor external int pending
.equ CSR_MIP_MTIP,     0x00000080  # [7]  machine timer int pending
.equ CSR_MIP_STIP,     0x00000020  # [5]  supervisor int pending
.equ CSR_MIP_MSIP,     0x00000008  # [3]  machine software int pending
.equ CSR_MIP_SSIP,     0x00000002  # [1]  supervisor software int pending

.equ CSR_MCAUSE_EC,    0x0000003F # 0x3ff ???  # [9:0] exception code

.endif  # CSR_E__INCLUDED
