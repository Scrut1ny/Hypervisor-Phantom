/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20240927 (64-bit version)
 * Copyright (c) 2000 - 2023 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of SSDT1.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000000A1 (161)
 *     Revision         0x01
 *     Checksum         0x80
 *     OEM ID           "BOCHS"
 *     OEM Table ID     "BXPCSSDT"
 *     OEM Revision     0x00000001 (1)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20240927 (539232551)
 */
 DefinitionBlock ("", "SSDT", 1, "BOCHS", "BXPCSSDT", 0x00000001)
 {
     External (_SB_.PCI0, DeviceObj)
 
     Scope (_SB.PCI0)
     {
         Device (BAT0)
         {
             Name (_HID, EisaId ("PNP0C0A") /* Control Method Battery */)  // _HID: Hardware ID
             Name (_UID, Zero)  // _UID: Unique ID
             Method (_STA, 0, NotSerialized)  // _STA: Status
             {
                 Return (0x1F)
             }
 
             Method (_BIF, 0, NotSerialized)  // _BIF: Battery Information
             {
                 Return (Package (0x0D)
                 {
                     One, 
                     0x1770, 
                     0x1770, 
                     One, 
                     0x39D0, 
                     0x0258, 
                     0x012C, 
                     0x3C, 
                     0x3C, 
                     "", 
                     "", 
                     "LION", 
                     ""
                 })
             }
 
             Method (_BST, 0, NotSerialized)  // _BST: Battery Status
             {
                 Return (Package (0x04)
                 {
                     Zero, 
                     Zero, 
                     0x1770, 
                     0x39D0
                 })
             }
         }
     }
 }
