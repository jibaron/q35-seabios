ACPI_EXTRACT_ALL_CODE ssdp_pcihp_aml

DefinitionBlock ("ssdt-pcihp.aml", "SSDT", 0x01, "BXPC", "BXSSDTPCIHP", 0x1)
{

/****************************************************************
 * PCI hotplug
 ****************************************************************/

    /* Objects supplied by DSDT */
    External (\_SB.PCI0, DeviceObj)
    External (\_SB.PCI0.PCEJ, MethodObj)

    Scope(\_SB.PCI0) {
        /* Bulk generated PCI hotplug devices */
        // Method _EJ0 can be patched by BIOS to EJ0_
        // at runtime, if the slot is detected to not support hotplug.
        // Extract the offset of the address dword and the
        // _EJ0 name to allow this patching.
#define hotplug_level2_slot(slot1, slot2)                   \
        Device (S##slot2) {                                 \
           Name (_ADR, 0x##slot2##0000)                     \
           Method (_EJ0, 1) { Return(PCEJ(0x##slot1, 0x##slot2)) } \
           Name (_SUN, 0x##slot2)                           \
        }                                                   \

#define hotplug_top_level_slot(slot)                          \
        Device (S##slot) {                                    \
            ACPI_EXTRACT_NAME_DWORD_CONST aml_adr_dword       \
            Name (_ADR,0x##slot##0000)                        \
            ACPI_EXTRACT_METHOD_STRING aml_ej0_name           \
            Method (_EJ0, 1) { Return(PCEJ(0x##slot, 0x00)) } \
            Name (_SUN, 0x##slot)                             \
            hotplug_level2_slot(slot, 01)                     \
            hotplug_level2_slot(slot, 02)                     \
            hotplug_level2_slot(slot, 03)                     \
            hotplug_level2_slot(slot, 04)                     \
            hotplug_level2_slot(slot, 05)                     \
            hotplug_level2_slot(slot, 06)                     \
            hotplug_level2_slot(slot, 07)                     \
            hotplug_level2_slot(slot, 08)                     \
            hotplug_level2_slot(slot, 09)                     \
            hotplug_level2_slot(slot, 0a)                     \
            hotplug_level2_slot(slot, 0b)                     \
            hotplug_level2_slot(slot, 0c)                     \
            hotplug_level2_slot(slot, 0d)                     \
            hotplug_level2_slot(slot, 0e)                     \
            hotplug_level2_slot(slot, 0f)                     \
            hotplug_level2_slot(slot, 10)                     \
            hotplug_level2_slot(slot, 11)                     \
            hotplug_level2_slot(slot, 12)                     \
            hotplug_level2_slot(slot, 13)                     \
            hotplug_level2_slot(slot, 14)                     \
            hotplug_level2_slot(slot, 15)                     \
            hotplug_level2_slot(slot, 16)                     \
            hotplug_level2_slot(slot, 17)                     \
            hotplug_level2_slot(slot, 18)                     \
            hotplug_level2_slot(slot, 19)                     \
            hotplug_level2_slot(slot, 1a)                     \
            hotplug_level2_slot(slot, 1b)                     \
            hotplug_level2_slot(slot, 1c)                     \
            hotplug_level2_slot(slot, 1d)                     \
            hotplug_level2_slot(slot, 1e)                     \
            hotplug_level2_slot(slot, 1f)                     \
        }                                                     \

        hotplug_top_level_slot(01)
        hotplug_top_level_slot(02)
        hotplug_top_level_slot(03)
        hotplug_top_level_slot(04)
        hotplug_top_level_slot(05)
        hotplug_top_level_slot(06)
        hotplug_top_level_slot(07)
        hotplug_top_level_slot(08)
        hotplug_top_level_slot(09)
        hotplug_top_level_slot(0a)
        hotplug_top_level_slot(0b)
        hotplug_top_level_slot(0c)
        hotplug_top_level_slot(0d)
        hotplug_top_level_slot(0e)
        hotplug_top_level_slot(0f)
        hotplug_top_level_slot(10)
        hotplug_top_level_slot(11)
        hotplug_top_level_slot(12)
        hotplug_top_level_slot(13)
        hotplug_top_level_slot(14)
        hotplug_top_level_slot(15)
        hotplug_top_level_slot(16)
        hotplug_top_level_slot(17)
        hotplug_top_level_slot(18)
        hotplug_top_level_slot(19)
        hotplug_top_level_slot(1a)
        hotplug_top_level_slot(1b)
        hotplug_top_level_slot(1c)
        hotplug_top_level_slot(1d)
        hotplug_top_level_slot(1e)
        hotplug_top_level_slot(1f)

#define gen_pci_level2_hotplug(slot1, slot2) \
            If (LEqual(Arg0, 0x##slot1)) { \
                If (LEqual(Arg1, 0x##slot2)) { \
                    Notify(\_SB.PCI0.S##slot1.S##slot2, Arg2) \
                } \
            } \

#define gen_pci_top_level_hotplug(slot)   \
            If (LEqual(Arg1, Zero)) { \
                If (LEqual(Arg0, 0x##slot)) { \
                    Notify(S##slot, Arg2) \
                } \
            } \
            gen_pci_level2_hotplug(slot, 01) \
            gen_pci_level2_hotplug(slot, 02) \
            gen_pci_level2_hotplug(slot, 03) \
            gen_pci_level2_hotplug(slot, 04) \
            gen_pci_level2_hotplug(slot, 05) \
            gen_pci_level2_hotplug(slot, 06) \
            gen_pci_level2_hotplug(slot, 07) \
            gen_pci_level2_hotplug(slot, 08) \
            gen_pci_level2_hotplug(slot, 09) \
            gen_pci_level2_hotplug(slot, 0a) \
            gen_pci_level2_hotplug(slot, 0b) \
            gen_pci_level2_hotplug(slot, 0c) \
            gen_pci_level2_hotplug(slot, 0d) \
            gen_pci_level2_hotplug(slot, 0e) \
            gen_pci_level2_hotplug(slot, 0f) \
            gen_pci_level2_hotplug(slot, 10) \
            gen_pci_level2_hotplug(slot, 11) \
            gen_pci_level2_hotplug(slot, 12) \
            gen_pci_level2_hotplug(slot, 13) \
            gen_pci_level2_hotplug(slot, 14) \
            gen_pci_level2_hotplug(slot, 15) \
            gen_pci_level2_hotplug(slot, 16) \
            gen_pci_level2_hotplug(slot, 17) \
            gen_pci_level2_hotplug(slot, 18) \
            gen_pci_level2_hotplug(slot, 19) \
            gen_pci_level2_hotplug(slot, 1a) \
            gen_pci_level2_hotplug(slot, 1b) \
            gen_pci_level2_hotplug(slot, 1c) \
            gen_pci_level2_hotplug(slot, 1d) \
            gen_pci_level2_hotplug(slot, 1e) \
            gen_pci_level2_hotplug(slot, 1f) \

        Method(PCNT, 3) {
            gen_pci_top_level_hotplug(01)
            gen_pci_top_level_hotplug(02)
            gen_pci_top_level_hotplug(03)
            gen_pci_top_level_hotplug(04)
            gen_pci_top_level_hotplug(05)
            gen_pci_top_level_hotplug(06)
            gen_pci_top_level_hotplug(07)
            gen_pci_top_level_hotplug(08)
            gen_pci_top_level_hotplug(09)
            gen_pci_top_level_hotplug(0a)
            gen_pci_top_level_hotplug(0b)
            gen_pci_top_level_hotplug(0c)
            gen_pci_top_level_hotplug(0d)
            gen_pci_top_level_hotplug(0e)
            gen_pci_top_level_hotplug(0f)
            gen_pci_top_level_hotplug(10)
            gen_pci_top_level_hotplug(11)
            gen_pci_top_level_hotplug(12)
            gen_pci_top_level_hotplug(13)
            gen_pci_top_level_hotplug(14)
            gen_pci_top_level_hotplug(15)
            gen_pci_top_level_hotplug(16)
            gen_pci_top_level_hotplug(17)
            gen_pci_top_level_hotplug(18)
            gen_pci_top_level_hotplug(19)
            gen_pci_top_level_hotplug(1a)
            gen_pci_top_level_hotplug(1b)
            gen_pci_top_level_hotplug(1c)
            gen_pci_top_level_hotplug(1d)
            gen_pci_top_level_hotplug(1e)
            gen_pci_top_level_hotplug(1f)
        }
    }

    Scope(\) {
/****************************************************************
 * Suspend
 ****************************************************************/

    /*
     * S3 (suspend-to-ram), S4 (suspend-to-disk) and S5 (power-off) type codes:
     * must match piix4 emulation.
     */

        ACPI_EXTRACT_NAME_STRING acpi_s3_name
        Name (_S3, Package (0x04)
        {
            One,  /* PM1a_CNT.SLP_TYP */
            One,  /* PM1b_CNT.SLP_TYP */
            Zero,  /* reserved */
            Zero   /* reserved */
        })
        ACPI_EXTRACT_NAME_STRING acpi_s4_name
        ACPI_EXTRACT_PKG_START acpi_s4_pkg
        Name (_S4, Package (0x04)
        {
            0x2,  /* PM1a_CNT.SLP_TYP */
            0x2,  /* PM1b_CNT.SLP_TYP */
            Zero,  /* reserved */
            Zero   /* reserved */
        })
        Name (_S5, Package (0x04)
        {
            Zero,  /* PM1a_CNT.SLP_TYP */
            Zero,  /* PM1b_CNT.SLP_TYP */
            Zero,  /* reserved */
            Zero   /* reserved */
        })
    }
}
