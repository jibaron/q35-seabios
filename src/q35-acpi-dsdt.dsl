/*
 * Bochs/QEMU ACPI DSDT ASL definition
 *
 * Copyright (c) 2006 Fabrice Bellard
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2 as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
 */
/*
 * Copyright (c) 2010 Isaku Yamahata
 *                    yamahata at valinux co jp
 * Based on acpi-dsdt.dsl, but heavily modified for q35 chipset.
 */

DefinitionBlock (
    "q35-acpi-dsdt.aml",// Output Filename
    "DSDT",             // Signature
    0x01,               // DSDT Compliance Revision
    "BXPC",             // OEMID
    "BXDSDT",           // TABLE ID
    0x2                 // OEM Revision
    )
{
    Scope (\)
    {
        /* Debug Output */
        OperationRegion (DBG, SystemIO, 0x0402, 0x01)
        Field (DBG, ByteAcc, NoLock, Preserve)
        {
            DBGB,   8,
        }

        /* Debug method - use this method to send output to the QEMU
         * BIOS debug port.  This method handles strings, integers,
         * and buffers.  For example: DBUG("abc") DBUG(0x123) */
        Method(DBUG, 1) {
            ToHexString(Arg0, Local0)
            ToBuffer(Local0, Local0)
            Subtract(SizeOf(Local0), 1, Local1)
            Store(Zero, Local2)
            While (LLess(Local2, Local1)) {
                Store(DerefOf(Index(Local0, Local2)), DBGB)
                Increment(Local2)
            }
            Store(0x0A, DBGB)
        }
    }


    Scope (\_SB)
    {
        OperationRegion(PCST, SystemIO, 0xae00, 0x0c)
        OperationRegion(PCSB, SystemIO, 0xae0c, 0x01)
        Field (PCSB, AnyAcc, NoLock, WriteAsZeros)
        {
            PCIB, 8,
        }
    }

    /* Zero => PIC mode, One => APIC Mode */
    Name (\PICF, Zero)
    Method (\_PIC, 1, NotSerialized)
    {
        Store (Arg0, \PICF)
    }

    /* PCI Bus definition */
    Scope(\_SB) {

        Device(PCI0) {
            Name (_HID, EisaId ("PNP0A08"))
            Name (_CID, EisaId ("PNP0A03"))
            Name (_ADR, 0x00)
            Name (_UID, 1)

            // _OSC: based on sample of ACPI3.0b spec
            Name(SUPP,0) // PCI _OSC Support Field value
            Name(CTRL,0) // PCI _OSC Control Field value
            Method(_OSC,4)
            {
                // Create DWORD-addressable fields from the Capabilities Buffer
                CreateDWordField(Arg3,0,CDW1)

                // Check for proper UUID
                If(LEqual(Arg0,ToUUID("33DB4D5B-1FF7-401C-9657-7441C03DD766")))
                {
                    // Create DWORD-addressable fields from the Capabilities Buffer
                    CreateDWordField(Arg3,4,CDW2)
                    CreateDWordField(Arg3,8,CDW3)

                    // Save Capabilities DWORD2 & 3
                    Store(CDW2,SUPP)
                    Store(CDW3,CTRL)

                    // Always allow native PME, AER (no dependencies)
                    // Never allow SHPC (no SHPC controller in this system)
                    And(CTRL,0x1D,CTRL)

#if 0 // For now, nothing to do
                    If(Not(And(CDW1,1))) // Query flag clear?
                    {   // Disable GPEs for features granted native control.
                        If(And(CTRL,0x01)) // Hot plug control granted?
                        {
                            Store(0,HPCE) // clear the hot plug SCI enable bit
                            Store(1,HPCS) // clear the hot plug SCI status bit
                        }
                        If(And(CTRL,0x04)) // PME control granted?
                        {
                            Store(0,PMCE) // clear the PME SCI enable bit
                            Store(1,PMCS) // clear the PME SCI status bit
                        }
                        If(And(CTRL,0x10)) // OS restoring PCI Express cap structure?
                        {
                            // Set status to not restore PCI Express cap structure
                            // upon resume from S3
                            Store(1,S3CR)
                        }

                    }
#endif
                    If(LNotEqual(Arg1,One))
                    {   // Unknown revision
                        Or(CDW1,0x08,CDW1)
                    }
                    If(LNotEqual(CDW3,CTRL))
                    {   // Capabilities bits were masked
                        Or(CDW1,0x10,CDW1)
                    }
                    // Update DWORD3 in the buffer
                    Store(CTRL,CDW3)
                } Else {
                    Or(CDW1,4,CDW1) // Unrecognized UUID
                }
                Return(Arg3)
            }

#define prt_slot_lnk(nr, lnk0, lnk1, lnk2, lnk3) \
       Package() { nr##ffff, 0, lnk0, 0 },       \
       Package() { nr##ffff, 1, lnk1, 0 },       \
       Package() { nr##ffff, 2, lnk2, 0 },       \
       Package() { nr##ffff, 3, lnk3, 0 }

#define prt_slot_lnkA(nr) prt_slot_lnk(nr, LNKA, LNKB, LNKC, LNKD)
#define prt_slot_lnkB(nr) prt_slot_lnk(nr, LNKB, LNKC, LNKD, LNKA)
#define prt_slot_lnkC(nr) prt_slot_lnk(nr, LNKC, LNKD, LNKA, LNKB)
#define prt_slot_lnkD(nr) prt_slot_lnk(nr, LNKD, LNKA, LNKB, LNKC)

#define prt_slot_lnkE(nr) prt_slot_lnk(nr, LNKE, LNKF, LNKG, LNKH)
#define prt_slot_lnkF(nr) prt_slot_lnk(nr, LNKF, LNKG, LNKH, LNKE)
#define prt_slot_lnkG(nr) prt_slot_lnk(nr, LNKG, LNKH, LNKE, LNKF)
#define prt_slot_lnkH(nr) prt_slot_lnk(nr, LNKH, LNKE, LNKF, LNKG)

#define prt_slot_gsi(nr, gsi0, gsi1, gsi2, gsi3) \
       Package() { nr##ffff, 0, gsi0, 0 },       \
       Package() { nr##ffff, 1, gsi1, 0 },       \
       Package() { nr##ffff, 2, gsi2, 0 },       \
       Package() { nr##ffff, 3, gsi3, 0 }

#define prt_slot_gsiA(nr) prt_slot_gsi(nr, GSIA, GSIB, GSIC, GSID)
#define prt_slot_gsiB(nr) prt_slot_gsi(nr, GSIB, GSIC, GSID, GSIA)
#define prt_slot_gsiC(nr) prt_slot_gsi(nr, GSIC, GSID, GSIA, GSIB)
#define prt_slot_gsiD(nr) prt_slot_gsi(nr, GSID, GSIA, GSIB, GSIC)

#define prt_slot_gsiE(nr) prt_slot_gsi(nr, GSIE, GSIF, GSIG, GSIH)
#define prt_slot_gsiF(nr) prt_slot_gsi(nr, GSIF, GSIG, GSIH, GSIE)
#define prt_slot_gsiG(nr) prt_slot_gsi(nr, GSIG, GSIH, GSIE, GSIF)
#define prt_slot_gsiH(nr) prt_slot_gsi(nr, GSIH, GSIE, GSIF, GSIG)

	    NAME(PRTP, package()
            {
             prt_slot_lnkE(0x0000),
             prt_slot_lnkF(0x0001),
             prt_slot_lnkG(0x0002),
             prt_slot_lnkH(0x0003),
             prt_slot_lnkE(0x0004),
             prt_slot_lnkF(0x0005),
             prt_slot_lnkG(0x0006),
             prt_slot_lnkH(0x0007),
             prt_slot_lnkE(0x0008),
             prt_slot_lnkF(0x0009),
             prt_slot_lnkG(0x000a),
             prt_slot_lnkH(0x000b),
             prt_slot_lnkE(0x000c),
             prt_slot_lnkF(0x000d),
             prt_slot_lnkG(0x000e),
             prt_slot_lnkH(0x000f),
             prt_slot_lnkE(0x0010),
             prt_slot_lnkF(0x0011),
             prt_slot_lnkG(0x0012),
             prt_slot_lnkH(0x0013),
             prt_slot_lnkE(0x0014),
             prt_slot_lnkF(0x0015),
             prt_slot_lnkG(0x0016),
             prt_slot_lnkH(0x0017),
             prt_slot_lnkE(0x0018),

             /* INTA -> PIRQA for slot 25 - 31
                see the default value of D<N>IR */
             prt_slot_lnkA(0x0019),
             prt_slot_lnkA(0x001a),
             prt_slot_lnkA(0x001b),
             prt_slot_lnkA(0x001c),
             prt_slot_lnkA(0x001d),

             /* PCIe->PCI bridge. use PIRQ[E-H] */
             prt_slot_lnkE(0x001e),

             prt_slot_lnkA(0x001f)
            })

	    NAME(PRTA, package()
            {
	     prt_slot_gsiE(0x0000),
	     prt_slot_gsiF(0x0001),
	     prt_slot_gsiG(0x0002),
	     prt_slot_gsiH(0x0003),
	     prt_slot_gsiE(0x0004),
	     prt_slot_gsiF(0x0005),
	     prt_slot_gsiG(0x0006),
	     prt_slot_gsiH(0x0007),
	     prt_slot_gsiE(0x0008),
	     prt_slot_gsiF(0x0009),
	     prt_slot_gsiG(0x000a),
	     prt_slot_gsiH(0x000b),
	     prt_slot_gsiE(0x000c),
	     prt_slot_gsiF(0x000d),
	     prt_slot_gsiG(0x000e),
	     prt_slot_gsiH(0x000f),
	     prt_slot_gsiE(0x0010),
	     prt_slot_gsiF(0x0011),
	     prt_slot_gsiG(0x0012),
	     prt_slot_gsiH(0x0013),
	     prt_slot_gsiE(0x0014),
	     prt_slot_gsiF(0x0015),
	     prt_slot_gsiG(0x0016),
	     prt_slot_gsiH(0x0017),
	     prt_slot_gsiE(0x0018),

             /* INTA -> PIRQA for slot 25 - 31, but 30
	        see the default value of D<N>IR */
	     prt_slot_gsiA(0x0019),
	     prt_slot_gsiA(0x001a),
	     prt_slot_gsiA(0x001b),
	     prt_slot_gsiA(0x001c),
	     prt_slot_gsiA(0x001d),

             /* PCIe->PCI bridge. use PIRQ[E-H] */
	     prt_slot_gsiE(0x001e),

	     prt_slot_gsiA(0x001f)
	    })

            Method(_PRT, 0, NotSerialized)
            {
                /* PCI IRQ routing table, example from ACPI 2.0a specification,
                   section 6.2.8.1 */
                /* Note: we provide the same info as the PCI routing
                   table of the Bochs BIOS */
                If (LEqual (\PICF, Zero))
		{
		 Return (PRTP)
		}
                Else
		{
		 Return (PRTA)
		}
            }

            Name (CRES, ResourceTemplate ()
            {
                WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                    0x0000,             // Address Space Granularity
                    0x0000,             // Address Range Minimum
                    0x00FF,             // Address Range Maximum
                    0x0000,             // Address Translation Offset
                    0x0100,             // Address Length
                    ,, )
                IO (Decode16,
                    0x0CF8,             // Address Range Minimum
                    0x0CF8,             // Address Range Maximum
                    0x01,               // Address Alignment
                    0x08,               // Address Length
                    )
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000,             // Address Space Granularity
                    0x0000,             // Address Range Minimum
                    0x0CF7,             // Address Range Maximum
                    0x0000,             // Address Translation Offset
                    0x0CF8,             // Address Length
                    ,, , TypeStatic)
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000,             // Address Space Granularity
                    0x0D00,             // Address Range Minimum
                    0xFFFF,             // Address Range Maximum
                    0x0000,             // Address Translation Offset
                    0xF300,             // Address Length
                    ,, , TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Address Space Granularity
                    0x000A0000,         // Address Range Minimum
                    0x000BFFFF,         // Address Range Maximum
                    0x00000000,         // Address Translation Offset
                    0x00020000,         // Address Length
                    ,, , AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, NonCacheable, ReadWrite,
                    0x00000000,         // Address Space Granularity
                    0xC0000000,         // Address Range Minimum
                    0xFEBFFFFF,         // Address Range Maximum
                    0x00000000,         // Address Translation Offset
                    0x3EC00000,         // Address Length
                    ,, PW32, AddressRangeMemory, TypeStatic)
            })
            Name (CR64, ResourceTemplate ()
            {
                QWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,          // Address Space Granularity
                    0x8000000000,        // Address Range Minimum
                    0xFFFFFFFFFF,        // Address Range Maximum
                    0x00000000,          // Address Translation Offset
                    0x8000000000,        // Address Length
                    ,, PW64, AddressRangeMemory, TypeStatic)
            })
            Method (_CRS, 0)
            {
        /* see see acpi.h, struct bfld */
        External (BDAT, OpRegionObj)
        Field(BDAT, QWordAcc, NoLock, Preserve) {
                    P0S, 64,
                    P0E, 64,
                    P0L, 64,
                    P1S, 64,
                    P1E, 64,
                    P1L, 64,
        }
        Field(BDAT, DWordAcc, NoLock, Preserve) {
                    P0SL, 32,
                    P0SH, 32,
                    P0EL, 32,
                    P0EH, 32,
                    P0LL, 32,
                    P0LH, 32,
                    P1SL, 32,
                    P1SH, 32,
                    P1EL, 32,
                    P1EH, 32,
                    P1LL, 32,
                    P1LH, 32,
        }

                /* fixup 32bit pci io window */
        CreateDWordField (CRES,\_SB.PCI0.PW32._MIN, PS32)
        CreateDWordField (CRES,\_SB.PCI0.PW32._MAX, PE32)
        CreateDWordField (CRES,\_SB.PCI0.PW32._LEN, PL32)
        Store (P0SL, PS32)
        Store (P0EL, PE32)
        Store (P0LL, PL32)

        If (LAnd(LEqual(P1SL, 0x00), LEqual(P1SH, 0x00))) {
            Return (CRES)
        } Else {
            /* fixup 64bit pci io window */
            CreateQWordField (CR64,\_SB.PCI0.PW64._MIN, PS64)
            CreateQWordField (CR64,\_SB.PCI0.PW64._MAX, PE64)
            CreateQWordField (CR64,\_SB.PCI0.PW64._LEN, PL64)
            Store (P1S, PS64)
            Store (P1E, PE64)
            Store (P1L, PL64)
            /* add window and return result */
            ConcatenateResTemplate (CRES, CR64, Local0)
            Return (Local0)
        }
            }
        }
    }

    Scope(\_SB.PCI0) {
        Device (VGA) {
                 Name (_ADR, 0x00020000)
                 Method (_S1D, 0, NotSerialized)
                 {
                         Return (0x00)
                 }
                 Method (_S2D, 0, NotSerialized)
                 {
                         Return (0x00)
                 }
                 Method (_S3D, 0, NotSerialized)
                 {
                         Return (0x00)
                 }
        }


        /* PCI D31:f0 LPC ISA bridge */
        Device (LPC) {
            /* PCI D31:f0 */
            Name (_ADR, 0x001f0000)

            /* ICH9 PCI to ISA irq remapping */
            OperationRegion (PIRQ, PCI_Config, 0x60, 0x0C)
            Field (PIRQ, ByteAcc, NoLock, Preserve)
            {
                PRQA,   8,
                PRQB,   8,
                PRQC,   8,
                PRQD,   8,

                Offset (0x08),
                PRQE,   8,
                PRQF,   8,
                PRQG,   8,
                PRQH,   8
            }

            OperationRegion (LPCD, PCI_Config, 0x80, 0x2)
            Field (LPCD, AnyAcc, NoLock, Preserve)
            {
                COMA,   3,
                    ,   1,
                COMB,   3,

                Offset(0x01),
                LPTD,   2,
                    ,   2,
                FDCD,   2
            }
            OperationRegion (LPCE, PCI_Config, 0x82, 0x2)
            Field (LPCE, AnyAcc, NoLock, Preserve)
            {
                CAEN,   1,
                CBEN,   1,
                LPEN,   1,
                FDEN,   1
            }

            /* High Precision Event Timer */
            Device(HPET) {
                Name(_HID,  EISAID("PNP0103"))
                Name(_UID, 0)
                Method (_STA, 0, NotSerialized) {
                        Return(0x0F)
                }
                Name(_CRS, ResourceTemplate() {
                    DWordMemory(
                        ResourceConsumer, PosDecode, MinFixed, MaxFixed,
                        NonCacheable, ReadWrite,
                        0x00000000,
                        0xFED00000,
                        0xFED003FF,
                        0x00000000,
                        0x00000400 /* 1K memory: FED00000 - FED003FF */
                    )
                })
            }
            /* Real-time clock */
            Device (RTC)
            {
                Name (_HID, EisaId ("PNP0B00"))
                Name (_CRS, ResourceTemplate ()
                {
                    IO (Decode16, 0x0070, 0x0070, 0x10, 0x02)
                    IRQNoFlags () {8}
                    IO (Decode16, 0x0072, 0x0072, 0x02, 0x06)
                })
            }

            /* Keyboard seems to be important for WinXP install */
            Device (KBD)
            {
                Name (_HID, EisaId ("PNP0303"))
                Method (_STA, 0, NotSerialized)
                {
                    Return (0x0f)
                }

                Method (_CRS, 0, NotSerialized)
                {
                     Name (TMP, ResourceTemplate ()
                     {
                    IO (Decode16,
                        0x0060,             // Address Range Minimum
                        0x0060,             // Address Range Maximum
                        0x01,               // Address Alignment
                        0x01,               // Address Length
                        )
                    IO (Decode16,
                        0x0064,             // Address Range Minimum
                        0x0064,             // Address Range Maximum
                        0x01,               // Address Alignment
                        0x01,               // Address Length
                        )
                    IRQNoFlags ()
                        {1}
                    })
                    Return (TMP)
                }
            }

	    /* PS/2 mouse */
            Device (MOU)
            {
                Name (_HID, EisaId ("PNP0F13"))
                Method (_STA, 0, NotSerialized)
                {
                    Return (0x0f)
                }

                Method (_CRS, 0, NotSerialized)
                {
                    Name (TMP, ResourceTemplate ()
                    {
                         IRQNoFlags () {12}
                    })
                    Return (TMP)
                }
            }

	    /* PS/2 floppy controller */
	    Device (FDC0)
	    {
	        Name (_HID, EisaId ("PNP0700"))
		Method (_STA, 0, NotSerialized)
		{
                    Store (\_SB.PCI0.LPC.FDEN, Local0)
                    If (LEqual (Local0, 0))
                    {
                         Return (0x00)
                    }
                    Else
                    {
                         Return (0x0F)
                    }
		}
		Method (_CRS, 0, NotSerialized)
		{
		    Name (BUF0, ResourceTemplate ()
                    {
                        IO (Decode16, 0x03F2, 0x03F2, 0x00, 0x04)
                        IO (Decode16, 0x03F7, 0x03F7, 0x00, 0x01)
                        IRQNoFlags () {6}
                        DMA (Compatibility, NotBusMaster, Transfer8) {2}
                    })
		    Return (BUF0)
		}
	    }

	    /* Parallel port */
	    Device (LPT)
	    {
	        Name (_HID, EisaId ("PNP0400"))
		Method (_STA, 0, NotSerialized)
		{
		    Store (\_SB.PCI0.LPC.LPEN, Local0)
		    If (LEqual (Local0, 0))
		    {
			Return (0x00)
		    }
		    Else
		    {
			Return (0x0F)
		    }
		}
		Method (_CRS, 0, NotSerialized)
		{
		    Name (BUF0, ResourceTemplate ()
                    {
			IO (Decode16, 0x0378, 0x0378, 0x08, 0x08)
			IRQNoFlags () {7}
		    })
		    Return (BUF0)
		}
	    }

	    /* Serial Ports */
	    Device (COM1)
	    {
	        Name (_HID, EisaId ("PNP0501"))
		Name (_UID, 0x01)
		Method (_STA, 0, NotSerialized)
		{
		    Store (\_SB.PCI0.LPC.CAEN, Local0)
		    If (LEqual (Local0, 0))
		    {
			Return (0x00)
		    }
		    Else
		    {
			Return (0x0F)
		    }
		}
		Method (_CRS, 0, NotSerialized)
		{
		    Name (BUF0, ResourceTemplate ()
                    {
			IO (Decode16, 0x03F8, 0x03F8, 0x00, 0x08)
                	IRQNoFlags () {4}
		    })
		    Return (BUF0)
		}
	    }

	    Device (COM2)
	    {
	        Name (_HID, EisaId ("PNP0501"))
		Name (_UID, 0x02)
		Method (_STA, 0, NotSerialized)
		{
		    Store (\_SB.PCI0.LPC.CBEN, Local0)
		    If (LEqual (Local0, 0))
		    {
			Return (0x00)
		    }
		    Else
		    {
			Return (0x0F)
		    }
		}
		Method (_CRS, 0, NotSerialized)
		{
		    Name (BUF0, ResourceTemplate ()
                    {
			IO (Decode16, 0x02F8, 0x02F8, 0x00, 0x08)
                	IRQNoFlags () {3}
		    })
		    Return (BUF0)
		}
	    }
        }
    }

    /* PCI express root port */
#define pcie_root_port(id, dev, fn)	\
    Scope (\_SB.PCI0) {                 \
        Device (PRP##id) {              \
            Name (_ADR, 0x##dev##fn)	\
         }                              \
    }
    pcie_root_port(0,  4, 0000)
    pcie_root_port(1, 18, 0000)
    pcie_root_port(2, 18, 0001)
    pcie_root_port(3, 18, 0002)
    pcie_root_port(4, 18, 0003)
    pcie_root_port(5, 18, 0004)
    pcie_root_port(6, 18, 0005)

    Scope (\_SB.PCI0) {
        Device (PRP7) {
            Name (_ADR, 0x00190000)
         }
    }

    /* PCI express upstream port */
#define pcie_downstream_port(dev)	\
    Device (PDP##dev) {                 \
        Name (_ADR, 0x##dev##0000)      \
    }

#define pcie_upstream_port(fn)		\
    Scope (\_SB.PCI0.PRP7) {            \
        Device (PUP##fn) {              \
            Name (_ADR, 0x##0000##fn)	\
            pcie_downstream_port(0)     \
            pcie_downstream_port(1)     \
            pcie_downstream_port(2)     \
            pcie_downstream_port(3)     \
            pcie_downstream_port(4)     \
            pcie_downstream_port(5)     \
            pcie_downstream_port(6)     \
            pcie_downstream_port(7)     \
            pcie_downstream_port(8)     \
            pcie_downstream_port(9)     \
            pcie_downstream_port(a)     \
            pcie_downstream_port(b)     \
            pcie_downstream_port(c)     \
            pcie_downstream_port(d)     \
            pcie_downstream_port(e)     \
            pcie_downstream_port(f)     \
        }				\
    }
    pcie_upstream_port(0)
    pcie_upstream_port(1)
    pcie_upstream_port(2)
    pcie_upstream_port(3)
    pcie_upstream_port(4)
    pcie_upstream_port(5)
    pcie_upstream_port(6)
    pcie_upstream_port(7)


    /* PCI to PCI Bridge on bus 0*/
    Scope (\_SB.PCI0) {
        Device (PCI9) {
            Name (_ADR, 0x1e0000)       /* 0:1e.00 */
            Name (_UID, 9)
        }
    }

#define pci_bridge(id, dev, uid)	\
    Scope (\_SB.PCI0.PCI9) {            \
        Device (PCI##id) {              \
            Name (_ADR, 0x##dev##0000)  \
            Name (_UID, uid)            \
        }                               \
    }
    pci_bridge(0, 1c, 5)
    pci_bridge(1, 1d, 6)
    pci_bridge(2, 1e, 7)
    pci_bridge(3, 1f, 8)

    /* PCI IRQs */
    Scope(\_SB) {
#define define_link(link, uid, reg)                     \
        Device(link){                                   \
                Name(_HID, EISAID("PNP0C0F"))           \
                Name(_UID, uid)                         \
                Name(_PRS, ResourceTemplate(){          \
                    Interrupt (, Level, ActiveHigh,     \
                               Shared)                  \
                        { 5, 10, 11 }                   \
                })                                      \
                Method (_STA, 0, NotSerialized)         \
                {                                       \
                    Store (0x0B, Local0)                \
                    If (And (0x80, reg, Local1))        \
                    {                                   \
                         Store (0x09, Local0)           \
                    }                                   \
                    Return (Local0)                     \
                }                                       \
                Method (_DIS, 0, NotSerialized)         \
                {                                       \
                    Or (reg, 0x80, reg)                 \
                }                                       \
                Method (_CRS, 0, NotSerialized)         \
                {                                       \
                    Name (PRR0, ResourceTemplate ()     \
                    {                                   \
                        Interrupt (, Level, ActiveHigh, \
                                   Shared)              \
                             {1}                        \
                    })                                  \
                    CreateDWordField (PRR0, 0x05, TMP)  \
                    And (reg, 0x0F, Local0)             \
                    Store (Local0, TMP)                 \
                    Return (PRR0)                       \
                }                                       \
                Method (_SRS, 1, NotSerialized)         \
                {                                       \
                    CreateDWordField (Arg0, 0x05, TMP)  \
                    Store (TMP, reg)                    \
                }                                       \
        }

        define_link(LNKA, 0, \_SB.PCI0.LPC.PRQA)
        define_link(LNKB, 1, \_SB.PCI0.LPC.PRQB)
        define_link(LNKC, 2, \_SB.PCI0.LPC.PRQC)
        define_link(LNKD, 3, \_SB.PCI0.LPC.PRQD)
        define_link(LNKE, 4, \_SB.PCI0.LPC.PRQE)
        define_link(LNKF, 5, \_SB.PCI0.LPC.PRQF)
        define_link(LNKG, 6, \_SB.PCI0.LPC.PRQG)
        define_link(LNKH, 7, \_SB.PCI0.LPC.PRQH)

#define define_gsi_link(link, uid, gsi)                 \
        Device(link){                                   \
                Name(_HID, EISAID("PNP0C0F"))           \
                Name(_UID, uid)                         \
                Name(_PRS, ResourceTemplate() {         \
                    Interrupt (, Level, ActiveHigh,     \
                               Shared)                  \
                        { gsi }                         \
                })                                      \
                Method (_CRS, 0, NotSerialized)         \
                {                                       \
                    Return (ResourceTemplate () {       \
                        Interrupt (, Level, ActiveHigh, \
                                   Shared)              \
                             { gsi }                    \
                    })                                  \
                }                                       \
                Method (_SRS, 1, NotSerialized) { }     \
        }                                               \

        define_gsi_link(GSIA, 0, 0x10)
        define_gsi_link(GSIB, 0, 0x11)
        define_gsi_link(GSIC, 0, 0x12)
        define_gsi_link(GSID, 0, 0x13)
        define_gsi_link(GSIE, 0, 0x14)
        define_gsi_link(GSIF, 0, 0x15)
        define_gsi_link(GSIG, 0, 0x16)
        define_gsi_link(GSIH, 0, 0x17)
    }

    /* CPU hotplug */
    Scope(\_SB) {
        /* Objects filled in by run-time generated SSDT */
        External(NTFY, MethodObj)
        External(CPON, PkgObj)

        /* Methods called by run-time generated SSDT Processor objects */
        Method (CPMA, 1, NotSerialized) {
            // _MAT method - create an madt apic buffer
            // Local0 = CPON flag for this cpu
            Store(DerefOf(Index(CPON, Arg0)), Local0)
            // Local1 = Buffer (in madt apic form) to return
            Store(Buffer(8) {0x00, 0x08, 0x00, 0x00, 0x00, 0, 0, 0}, Local1)
            // Update the processor id, lapic id, and enable/disable status
            Store(Arg0, Index(Local1, 2))
            Store(Arg0, Index(Local1, 3))
            Store(Local0, Index(Local1, 4))
            Return (Local1)
        }
        Method (CPST, 1, NotSerialized) {
            // _STA method - return ON status of cpu
            // Local0 = CPON flag for this cpu
            Store(DerefOf(Index(CPON, Arg0)), Local0)
            If (Local0) { Return(0xF) } Else { Return(0x0) }
        }
        Method (CPEJ, 2, NotSerialized) {
            // _EJ0 method - eject callback
            Sleep(200)
        }

        /* CPU hotplug notify method */
        OperationRegion(PRST, SystemIO, 0xaf00, 32)
        Field (PRST, ByteAcc, NoLock, Preserve)
        {
            PRS, 256
        }
        Method(PRSC, 0) {
            // Local5 = active cpu bitmap
            Store (PRS, Local5)
            // Local2 = last read byte from bitmap
            Store (Zero, Local2)
            // Local0 = cpuid iterator
            Store (Zero, Local0)
            While (LLess(Local0, SizeOf(CPON))) {
                // Local1 = CPON flag for this cpu
                Store(DerefOf(Index(CPON, Local0)), Local1)
                If (And(Local0, 0x07)) {
                    // Shift down previously read bitmap byte
                    ShiftRight(Local2, 1, Local2)
                } Else {
                    // Read next byte from cpu bitmap
                    Store(DerefOf(Index(Local5, ShiftRight(Local0, 3))), Local2)
                }
                // Local3 = active state for this cpu
                Store(And(Local2, 1), Local3)

                If (LNotEqual(Local1, Local3)) {
                    // State change - update CPON with new state
                    Store(Local3, Index(CPON, Local0))
                    // Do CPU notify
                    If (LEqual(Local3, 1)) {
                        NTFY(Local0, 1)
                    } Else {
                        NTFY(Local0, 3)
                    }
                }
                Increment(Local0)
            }
            Return(One)
        }
    }

    Scope (\_GPE)
    {
        Name(_HID, "ACPI0006")

        Method(_L00) {
            Return(0x01)
        }
        Method(_L01) {
             // CPU hotplug event
	     Return(\_SB.PRSC())
        }
        Method(_L02) {
            Return(0x01)
        }
        Method(_L03) {
            Return(0x01)
        }
        Method(_L04) {
            Return(0x01)
        }
        Method(_L05) {
            Return(0x01)
        }
        Method(_L06) {
            Return(0x01)
        }
        Method(_L07) {
            Return(0x01)
        }
        Method(_L08) {
            Return(0x01)
        }
        Method(_L09) {
            Return(0x01)
        }
        Method(_L0A) {
            Return(0x01)
        }
        Method(_L0B) {
            Return(0x01)
        }
        Method(_L0C) {
            Return(0x01)
        }
        Method(_L0D) {
            Return(0x01)
        }
        Method(_L0E) {
            Return(0x01)
        }
        Method(_L0F) {
            Return(0x01)
        }
    }
}
