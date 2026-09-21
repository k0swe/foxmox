; FoxMox V2.6 — lossless PIC16F84A reconstruction
;
; This first preservation source intentionally emits recovered instruction
; words with DW. Labels and decoded comments are documentary; replacing a DW
; with a mnemonic is safe only when verification still reports exact equality.
; Canonical image: ../foxmox-v2.6.hex

        LIST      P=16F84A, F=INHX8M
        INCLUDE   <p16f84a.inc>
        RADIX     HEX

; RAM aliases established by the interrupt and main-loop data flow.
tmr0_wait_count EQU       0x11
morse_unit_ticks EQU      0x19
porta_shadow    EQU       0x1A
switch_state    EQU       0x1B
tone_state      EQU       0x1D
lfsr_state      EQU       0x20
lfsr_steps      EQU       0x23
saved_w         EQU       0x25
interrupt_flag  EQU       0x27
hex_byte        EQU       0x28
message_index   EQU       0x2B

; PIC14 instructions encode seven file-address bits; RP0 supplies the bank.
; These aliases keep bank-1 register names visible without gpasm's expected
; "register not in bank 0" advisory for their absolute header values.
TRISB_FILE      EQU       (TRISB & 0x7F)
EECON1_FILE     EQU       (EECON1 & 0x7F)
EECON2_FILE     EQU       (EECON2 & 0x7F)

        ORG       0x0000

reset_vector:
        DW        0x2858    ; 0x000: goto 0x058
        DW        0x3FFF    ; 0x001: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x002: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x003: erased (instruction encoding: addlw 0xFF)

interrupt_vector:
        DW        0x2805    ; 0x004: goto 0x005
        DW        0x008C    ; 0x005: movwf 0x0C
        DW        0x0803    ; 0x006: movf STATUS,W
        DW        0x008D    ; 0x007: movwf 0x0D
        DW        0x110B    ; 0x008: bcf INTCON,2
        DW        0x1283    ; 0x009: bcf STATUS,5
        DW        0x081A    ; 0x00A: movf 0x1A,W
        DW        0x0085    ; 0x00B: movwf PORTA[b0]/TRISA[b1]
        DW        0x0B8F    ; 0x00C: decfsz 0x0F,F
        DW        0x2839    ; 0x00D: goto 0x039
        DW        0x0B8E    ; 0x00E: decfsz 0x0E,F
        DW        0x2839    ; 0x00F: goto 0x039
        DW        0x30A6    ; 0x010: movlw 0xA6
        DW        0x008F    ; 0x011: movwf 0x0F
        DW        0x300E    ; 0x012: movlw 0x0E
        DW        0x008E    ; 0x013: movwf 0x0E
        DW        0x0892    ; 0x014: movf 0x12,F
        DW        0x1D03    ; 0x015: btfss STATUS,2
        DW        0x0392    ; 0x016: decf 0x12,F
        DW        0x0893    ; 0x017: movf 0x13,F
        DW        0x1D03    ; 0x018: btfss STATUS,2
        DW        0x281D    ; 0x019: goto 0x01D
        DW        0x0894    ; 0x01A: movf 0x14,F
        DW        0x1903    ; 0x01B: btfsc STATUS,2
        DW        0x2823    ; 0x01C: goto 0x023
        DW        0x3001    ; 0x01D: movlw 0x01
        DW        0x0294    ; 0x01E: subwf 0x14,F
        DW        0x3000    ; 0x01F: movlw 0x00
        DW        0x1C03    ; 0x020: btfss STATUS,0
        DW        0x3001    ; 0x021: movlw 0x01
        DW        0x0293    ; 0x022: subwf 0x13,F
        DW        0x0895    ; 0x023: movf 0x15,F
        DW        0x1D03    ; 0x024: btfss STATUS,2
        DW        0x2829    ; 0x025: goto 0x029
        DW        0x0896    ; 0x026: movf 0x16,F
        DW        0x1903    ; 0x027: btfsc STATUS,2
        DW        0x282F    ; 0x028: goto 0x02F
        DW        0x3001    ; 0x029: movlw 0x01
        DW        0x0296    ; 0x02A: subwf 0x16,F
        DW        0x3000    ; 0x02B: movlw 0x00
        DW        0x1C03    ; 0x02C: btfss STATUS,0
        DW        0x3001    ; 0x02D: movlw 0x01
        DW        0x0295    ; 0x02E: subwf 0x15,F
        DW        0x0A90    ; 0x02F: incf 0x10,F
        DW        0x0810    ; 0x030: movf 0x10,W
        DW        0x393F    ; 0x031: andlw 0x3F
        DW        0x1D03    ; 0x032: btfss STATUS,2
        DW        0x2839    ; 0x033: goto 0x039
        DW        0x14A7    ; 0x034: bsf 0x27,1
        DW        0x083F    ; 0x035: movf 0x3F,W
        DW        0x078F    ; 0x036: addwf 0x0F,F
        DW        0x1803    ; 0x037: btfsc STATUS,0
        DW        0x0A8E    ; 0x038: incf 0x0E,F
        DW        0x0A9C    ; 0x039: incf 0x1C,F
        DW        0x3088    ; 0x03A: movlw 0x88
        DW        0x071C    ; 0x03B: addwf 0x1C,W
        DW        0x1803    ; 0x03C: btfsc STATUS,0
        DW        0x019C    ; 0x03D: clrf 0x1C
        DW        0x101A    ; 0x03E: bcf 0x1A,0
        DW        0x1B9D    ; 0x03F: btfsc 0x1D,7
        DW        0x2848    ; 0x040: goto 0x048
        DW        0x081C    ; 0x041: movf 0x1C,W
        DW        0x2367    ; 0x042: call 0x367
        DW        0x00A9    ; 0x043: movwf 0x29
        DW        0x2335    ; 0x044: call 0x335
        DW        0x05A9    ; 0x045: andwf 0x29,F
        DW        0x1903    ; 0x046: btfsc STATUS,2
        DW        0x141A    ; 0x047: bsf 0x1A,0
        DW        0x111A    ; 0x048: bcf 0x1A,2
        DW        0x1F9D    ; 0x049: btfss 0x1D,7
        DW        0x151A    ; 0x04A: bsf 0x1A,2
        DW        0x1C1C    ; 0x04B: btfss 0x1C,0
        DW        0x2852    ; 0x04C: goto 0x052
        DW        0x1C9C    ; 0x04D: btfss 0x1C,1
        DW        0x2852    ; 0x04E: goto 0x052
        DW        0x0891    ; 0x04F: movf 0x11,F
        DW        0x1D03    ; 0x050: btfss STATUS,2
        DW        0x0391    ; 0x051: decf 0x11,F
        DW        0x1427    ; 0x052: bsf 0x27,0
        DW        0x080D    ; 0x053: movf 0x0D,W
        DW        0x0083    ; 0x054: movwf STATUS
        DW        0x0E8C    ; 0x055: swapf 0x0C,F
        DW        0x0E0C    ; 0x056: swapf 0x0C,W
        DW        0x0009    ; 0x057: retfie

startup:
        DW        0x018B    ; 0x058: clrf INTCON
        DW        0x1283    ; 0x059: bcf STATUS,5
        DW        0x3008    ; 0x05A: movlw 0x08
        DW        0x0085    ; 0x05B: movwf PORTA[b0]/TRISA[b1]
        DW        0x3000    ; 0x05C: movlw 0x00
        DW        0x0086    ; 0x05D: movwf PORTB[b0]/TRISB[b1]
        DW        0x1683    ; 0x05E: bsf STATUS,5
        DW        0x3008    ; 0x05F: movlw 0x08
        DW        0x0081    ; 0x060: movwf TMR0[b0]/OPTION_REG[b1]
        DW        0x30E4    ; 0x061: movlw 0xE4
        DW        0x0085    ; 0x062: movwf PORTA[b0]/TRISA[b1]
        DW        0x3000    ; 0x063: movlw 0x00
        DW        0x0086    ; 0x064: movwf PORTB[b0]/TRISB[b1]
        DW        0x1283    ; 0x065: bcf STATUS,5
        DW        0x3003    ; 0x066: movlw 0x03
        DW        0x008A    ; 0x067: movwf PCLATH
        DW        0x300C    ; 0x068: movlw 0x0C
        DW        0x0084    ; 0x069: movwf FSR
        DW        0x0180    ; 0x06A: clrf INDF
        DW        0x0A84    ; 0x06B: incf FSR,F
        DW        0x1F04    ; 0x06C: btfss FSR,6
        DW        0x286A    ; 0x06D: goto 0x06A
        DW        0x30A6    ; 0x06E: movlw 0xA6
        DW        0x008F    ; 0x06F: movwf 0x0F
        DW        0x300E    ; 0x070: movlw 0x0E
        DW        0x008E    ; 0x071: movwf 0x0E
        DW        0x3083    ; 0x072: movlw 0x83
        DW        0x009D    ; 0x073: movwf 0x1D
        DW        0x3046    ; 0x074: movlw 0x46
        DW        0x0099    ; 0x075: movwf 0x19
        DW        0x3028    ; 0x076: movlw 0x28
        DW        0x2116    ; 0x077: call 0x116
        DW        0x00BF    ; 0x078: movwf 0x3F
        DW        0x1D05    ; 0x079: btfss PORTA[b0]/TRISA[b1],2
        DW        0x2951    ; 0x07A: goto 0x151
        DW        0x0181    ; 0x07B: clrf TMR0[b0]/OPTION_REG[b1]
        DW        0x168B    ; 0x07C: bsf INTCON,5
        DW        0x178B    ; 0x07D: bsf INTCON,7
        DW        0x1683    ; 0x07E: bsf STATUS,5
        DW        0x30E8    ; 0x07F: movlw 0xE8
        DW        0x0085    ; 0x080: movwf PORTA[b0]/TRISA[b1]
        DW        0x213E    ; 0x081: call 0x13E
        DW        0x300F    ; 0x082: movlw 0x0F
        DW        0x051B    ; 0x083: andwf 0x1B,W
        DW        0x00AB    ; 0x084: movwf 0x2B
        DW        0x2356    ; 0x085: call 0x356
        DW        0x00A0    ; 0x086: movwf 0x20
        DW        0x149A    ; 0x087: bsf 0x1A,1
        DW        0x3004    ; 0x088: movlw 0x04
        DW        0x0092    ; 0x089: movwf 0x12
        DW        0x21C3    ; 0x08A: call 0x1C3
        DW        0x2340    ; 0x08B: call 0x340
        DW        0x0892    ; 0x08C: movf 0x12,F
        DW        0x1D03    ; 0x08D: btfss STATUS,2
        DW        0x288C    ; 0x08E: goto 0x08C
        DW        0x109A    ; 0x08F: bcf 0x1A,1
        DW        0x01AC    ; 0x090: clrf 0x2C
        DW        0x0E1B    ; 0x091: swapf 0x1B,W
        DW        0x3EB0    ; 0x092: addlw 0xB0
        DW        0x1C03    ; 0x093: btfss STATUS,0
        DW        0x289A    ; 0x094: goto 0x09A
        DW        0x081B    ; 0x095: movf 0x1B,W
        DW        0x3E80    ; 0x096: addlw 0x80
        DW        0x1803    ; 0x097: btfsc STATUS,0
        DW        0x28A6    ; 0x098: goto 0x0A6
        DW        0x28A8    ; 0x099: goto 0x0A8
        DW        0x081B    ; 0x09A: movf 0x1B,W
        DW        0x3E10    ; 0x09B: addlw 0x10
        DW        0x1803    ; 0x09C: btfsc STATUS,0
        DW        0x28A5    ; 0x09D: goto 0x0A5
        DW        0x3E60    ; 0x09E: addlw 0x60
        DW        0x1803    ; 0x09F: btfsc STATUS,0
        DW        0x28A6    ; 0x0A0: goto 0x0A6
        DW        0x3E20    ; 0x0A1: addlw 0x20
        DW        0x1803    ; 0x0A2: btfsc STATUS,0
        DW        0x28A7    ; 0x0A3: goto 0x0A7
        DW        0x28A8    ; 0x0A4: goto 0x0A8
        DW        0x0AAC    ; 0x0A5: incf 0x2C,F
        DW        0x0AAC    ; 0x0A6: incf 0x2C,F
        DW        0x0AAC    ; 0x0A7: incf 0x2C,F
        DW        0x082C    ; 0x0A8: movf 0x2C,W
        DW        0x07AC    ; 0x0A9: addwf 0x2C,F
        DW        0x2112    ; 0x0AA: call 0x112
        DW        0x3020    ; 0x0AB: movlw 0x20
        DW        0x07AC    ; 0x0AC: addwf 0x2C,F
        DW        0x082C    ; 0x0AD: movf 0x2C,W
        DW        0x2116    ; 0x0AE: call 0x116
        DW        0x0093    ; 0x0AF: movwf 0x13
        DW        0x0A2C    ; 0x0B0: incf 0x2C,W
        DW        0x2116    ; 0x0B1: call 0x116
        DW        0x0094    ; 0x0B2: movwf 0x14
        DW        0x0893    ; 0x0B3: movf 0x13,F
        DW        0x1D03    ; 0x0B4: btfss STATUS,2
        DW        0x28B3    ; 0x0B5: goto 0x0B3
        DW        0x0894    ; 0x0B6: movf 0x14,F
        DW        0x1D03    ; 0x0B7: btfss STATUS,2
        DW        0x28B3    ; 0x0B8: goto 0x0B3
        DW        0x2112    ; 0x0B9: call 0x112
        DW        0x0893    ; 0x0BA: movf 0x13,F
        DW        0x1D03    ; 0x0BB: btfss STATUS,2
        DW        0x28B9    ; 0x0BC: goto 0x0B9
        DW        0x0894    ; 0x0BD: movf 0x14,F
        DW        0x1D03    ; 0x0BE: btfss STATUS,2
        DW        0x28B9    ; 0x0BF: goto 0x0B9
        DW        0x213E    ; 0x0C0: call 0x13E
        DW        0x01AC    ; 0x0C1: clrf 0x2C
        DW        0x0E1B    ; 0x0C2: swapf 0x1B,W
        DW        0x3EB0    ; 0x0C3: addlw 0xB0
        DW        0x0103    ; 0x0C4: clrw
        DW        0x1803    ; 0x0C5: btfsc STATUS,0
        DW        0x3010    ; 0x0C6: movlw 0x10
        DW        0x07AC    ; 0x0C7: addwf 0x2C,F
        DW        0x0E1B    ; 0x0C8: swapf 0x1B,W
        DW        0x009E    ; 0x0C9: movwf 0x1E
        DW        0x0D1E    ; 0x0CA: rlf 0x1E,W
        DW        0x390E    ; 0x0CB: andlw 0x0E
        DW        0x07AC    ; 0x0CC: addwf 0x2C,F
        DW        0x3000    ; 0x0CD: movlw 0x00
        DW        0x07AC    ; 0x0CE: addwf 0x2C,F
        DW        0x082C    ; 0x0CF: movf 0x2C,W
        DW        0x2116    ; 0x0D0: call 0x116
        DW        0x0094    ; 0x0D1: movwf 0x14
        DW        0x3004    ; 0x0D2: movlw 0x04
        DW        0x0092    ; 0x0D3: movwf 0x12
        DW        0x2340    ; 0x0D4: call 0x340
        DW        0x2112    ; 0x0D5: call 0x112
        DW        0x0893    ; 0x0D6: movf 0x13,F
        DW        0x1D03    ; 0x0D7: btfss STATUS,2
        DW        0x28DF    ; 0x0D8: goto 0x0DF
        DW        0x0814    ; 0x0D9: movf 0x14,W
        DW        0x1903    ; 0x0DA: btfsc STATUS,2
        DW        0x28F1    ; 0x0DB: goto 0x0F1
        DW        0x3A04    ; 0x0DC: xorlw 0x04
        DW        0x1903    ; 0x0DD: btfsc STATUS,2
        DW        0x28E3    ; 0x0DE: goto 0x0E3
        DW        0x0892    ; 0x0DF: movf 0x12,F
        DW        0x1D03    ; 0x0E0: btfss STATUS,2
        DW        0x28D5    ; 0x0E1: goto 0x0D5
        DW        0x28D2    ; 0x0E2: goto 0x0D2
        DW        0x0895    ; 0x0E3: movf 0x15,F
        DW        0x1D03    ; 0x0E4: btfss STATUS,2
        DW        0x28D2    ; 0x0E5: goto 0x0D2
        DW        0x0896    ; 0x0E6: movf 0x16,F
        DW        0x1D03    ; 0x0E7: btfss STATUS,2
        DW        0x28D2    ; 0x0E8: goto 0x0D2
        DW        0x3004    ; 0x0E9: movlw 0x04
        DW        0x0092    ; 0x0EA: movwf 0x12
        DW        0x3002    ; 0x0EB: movlw 0x02
        DW        0x0095    ; 0x0EC: movwf 0x15
        DW        0x3058    ; 0x0ED: movlw 0x58
        DW        0x0096    ; 0x0EE: movwf 0x16
        DW        0x2109    ; 0x0EF: call 0x109
        DW        0x28D5    ; 0x0F0: goto 0x0D5
        DW        0x0A2C    ; 0x0F1: incf 0x2C,W
        DW        0x2116    ; 0x0F2: call 0x116
        DW        0x0094    ; 0x0F3: movwf 0x14
        DW        0x0894    ; 0x0F4: movf 0x14,F
        DW        0x1903    ; 0x0F5: btfsc STATUS,2
        DW        0x28B9    ; 0x0F6: goto 0x0B9
        DW        0x109A    ; 0x0F7: bcf 0x1A,1
        DW        0x179D    ; 0x0F8: bsf 0x1D,7
        DW        0x0E1B    ; 0x0F9: swapf 0x1B,W
        DW        0x3EB0    ; 0x0FA: addlw 0xB0
        DW        0x1C03    ; 0x0FB: btfss STATUS,0
        DW        0x28B9    ; 0x0FC: goto 0x0B9
        DW        0x081B    ; 0x0FD: movf 0x1B,W
        DW        0x3E90    ; 0x0FE: addlw 0x90
        DW        0x3970    ; 0x0FF: andlw 0x70
        DW        0x3EB0    ; 0x100: addlw 0xB0
        DW        0x1C03    ; 0x101: btfss STATUS,0
        DW        0x28B9    ; 0x102: goto 0x0B9
        DW        0x2112    ; 0x103: call 0x112
        DW        0x301F    ; 0x104: movlw 0x1F
        DW        0x0520    ; 0x105: andwf 0x20,W
        DW        0x0794    ; 0x106: addwf 0x14,F
        DW        0x212E    ; 0x107: call 0x12E
        DW        0x28B9    ; 0x108: goto 0x0B9

send_callsign_n0puf:
        DW        0x3031    ; 0x109: movlw 0x31
        DW        0x0099    ; 0x10A: movwf 0x19
        DW        0x21C2    ; 0x10B: call 0x1C2
        DW        0x21D8    ; 0x10C: call 0x1D8
        DW        0x2305    ; 0x10D: call 0x305
        DW        0x21DC    ; 0x10E: call 0x1DC
        DW        0x21E8    ; 0x10F: call 0x1E8
        DW        0x2332    ; 0x110: call 0x332
        DW        0x0008    ; 0x111: return

; Wait for the next TMR0 interrupt. The ISR sets interrupt_flag bit 0 on every
; overflow; clearing it first prevents a stale event from satisfying the wait.
wait_for_tmr0_interrupt:
        BCF       interrupt_flag, 0        ; 0x112
wait_for_tmr0_interrupt_loop:
        BTFSS     interrupt_flag, 0        ; 0x113
        GOTO      wait_for_tmr0_interrupt_loop ; 0x114
        RETURN                            ; 0x115

; Read the EEPROM byte whose address arrives in W and return its value in W.
; RP0 transitions are kept explicit because EEADR/EEDATA and EECON1 share file
; addresses across banks on the PIC16F84A.
eeprom_read:
        BCF       STATUS, RP0        ; 0x116: bank 0
        MOVWF     EEADR              ; 0x117
        BSF       STATUS, RP0        ; 0x118: bank 1
        BSF       EECON1_FILE, RD    ; 0x119: initiate read
        BCF       STATUS, RP0        ; 0x11A: bank 0
        MOVF      EEDATA, W          ; 0x11B
        RETURN                       ; 0x11C

; Write the byte in W to the EEPROM address already loaded into EEADR. This is
; the standard PIC16F84A unlock sequence. The recovered code restores GIE
; unconditionally after starting the write, then polls EEIF for completion.
eeprom_write:
        BCF       STATUS, RP0         ; 0x11D: bank 0
        MOVWF     EEDATA              ; 0x11E
        BSF       STATUS, RP0         ; 0x11F: bank 1
        BCF       INTCON, GIE         ; 0x120: protect unlock sequence
        BSF       EECON1_FILE, WREN   ; 0x121
        MOVLW     0x55                ; 0x122
        MOVWF     EECON2_FILE         ; 0x123
        MOVLW     0xAA                ; 0x124
        MOVWF     EECON2_FILE         ; 0x125
        BSF       EECON1_FILE, WR     ; 0x126: begin write
        BSF       INTCON, GIE         ; 0x127
wait_for_eeprom_write:
        BTFSS     EECON1_FILE, EEIF   ; 0x128
        GOTO      wait_for_eeprom_write ; 0x129
        BCF       EECON1_FILE, EEIF   ; 0x12A
        BCF       EECON1_FILE, WREN   ; 0x12B
        BCF       STATUS, RP0         ; 0x12C: bank 0
        RETURN                        ; 0x12D

; Advance the seven-bit pseudo-random state three times.
advance_lfsr_3:
        MOVLW     0x03                ; 0x12E
        MOVWF     lfsr_steps          ; 0x12F
advance_lfsr_3_loop:
        CALL      advance_lfsr_1      ; 0x130
        DECFSZ    lfsr_steps, F       ; 0x131
        GOTO      advance_lfsr_3_loop ; 0x132
        RETURN                        ; 0x133

; Advance the seven-bit LFSR in bits 6:0 of lfsr_state. Carry is loaded with
; bit0 XOR bit6, then rotated into bit0 while the old bit6 rotates into bit7.
advance_lfsr_1:
        BCF       STATUS, C           ; 0x134: default feedback = 0
        BTFSC     lfsr_state, 0       ; 0x135
        GOTO      lfsr_bit0_set       ; 0x136
        BTFSC     lfsr_state, 6       ; 0x137: bit0=0 -> feedback=bit6
        BSF       STATUS, C           ; 0x138
        GOTO      lfsr_rotate         ; 0x139
lfsr_bit0_set:
        BTFSS     lfsr_state, 6       ; 0x13A: bit0=1 -> feedback=!bit6
        BSF       STATUS, C           ; 0x13B
lfsr_rotate:
        RLF       lfsr_state, F       ; 0x13C
        RETURN                        ; 0x13D

; Read the two active-low hexadecimal switches on PORTB. The pins are inputs
; only for the sample; afterwards they return to outputs for the tone sequencer.
read_switches:
        BSF       STATUS, RP0         ; 0x13E: bank 1
        MOVLW     0xFF                ; 0x13F
        MOVWF     TRISB_FILE          ; 0x140: all PORTB pins inputs
        BCF       STATUS, RP0         ; 0x141: bank 0
        COMF      PORTB, W            ; 0x142: sample and invert active-low bits
        MOVWF     switch_state        ; 0x143: S2 in high nibble, S1 in low
        BSF       STATUS, RP0         ; 0x144: bank 1
        CLRF      TRISB_FILE          ; 0x145: restore PORTB outputs
        BCF       STATUS, RP0         ; 0x146: bank 0
        RETURN                        ; 0x147

; Send W as two hexadecimal Morse digits, high nibble first, and preserve the
; original byte in W on return.
send_hex_byte:
        MOVWF     hex_byte            ; 0x148
        SWAPF     hex_byte, W         ; 0x149
        ANDLW     0x0F                ; 0x14A
        CALL      hex_digit_dispatch  ; 0x14B
        MOVF      hex_byte, W         ; 0x14C
        ANDLW     0x0F                ; 0x14D
        CALL      hex_digit_dispatch  ; 0x14E
        MOVF      hex_byte, W         ; 0x14F
        RETURN                        ; 0x150

service_mode:
        DW        0x019E    ; 0x151: clrf 0x1E
        DW        0x307F    ; 0x152: movlw 0x7F
        DW        0x009F    ; 0x153: movwf 0x1F
        DW        0x1D05    ; 0x154: btfss PORTA[b0]/TRISA[b1],2
        DW        0x2951    ; 0x155: goto 0x151
        DW        0x0B9E    ; 0x156: decfsz 0x1E,F
        DW        0x2954    ; 0x157: goto 0x154
        DW        0x0B9F    ; 0x158: decfsz 0x1F,F
        DW        0x2954    ; 0x159: goto 0x154
        DW        0x1683    ; 0x15A: bsf STATUS,5
        DW        0x30E8    ; 0x15B: movlw 0xE8
        DW        0x0085    ; 0x15C: movwf PORTA[b0]/TRISA[b1]
        DW        0x1283    ; 0x15D: bcf STATUS,5
        DW        0x213E    ; 0x15E: call 0x13E
        DW        0x089B    ; 0x15F: movf 0x1B,F
        DW        0x1903    ; 0x160: btfsc STATUS,2
        DW        0x298B    ; 0x161: goto 0x18B
        DW        0x149A    ; 0x162: bsf 0x1A,1
        DW        0x0181    ; 0x163: clrf TMR0[b0]/OPTION_REG[b1]
        DW        0x168B    ; 0x164: bsf INTCON,5
        DW        0x178B    ; 0x165: bsf INTCON,7
        DW        0x019E    ; 0x166: clrf 0x1E
        DW        0x307F    ; 0x167: movlw 0x7F
        DW        0x009F    ; 0x168: movwf 0x1F
        DW        0x0B9E    ; 0x169: decfsz 0x1E,F
        DW        0x2969    ; 0x16A: goto 0x169
        DW        0x0B9F    ; 0x16B: decfsz 0x1F,F
        DW        0x2969    ; 0x16C: goto 0x169
        DW        0x21C3    ; 0x16D: call 0x1C3
        DW        0x083F    ; 0x16E: movf 0x3F,W
        DW        0x2148    ; 0x16F: call 0x148
        DW        0x3005    ; 0x170: movlw 0x05
        DW        0x0092    ; 0x171: movwf 0x12
        DW        0x213E    ; 0x172: call 0x13E
        DW        0x081B    ; 0x173: movf 0x1B,W
        DW        0x39F0    ; 0x174: andlw 0xF0
        DW        0x1D03    ; 0x175: btfss STATUS,2
        DW        0x297F    ; 0x176: goto 0x17F
        DW        0x0892    ; 0x177: movf 0x12,F
        DW        0x1D03    ; 0x178: btfss STATUS,2
        DW        0x297F    ; 0x179: goto 0x17F
        DW        0x21C3    ; 0x17A: call 0x1C3
        DW        0x3028    ; 0x17B: movlw 0x28
        DW        0x2116    ; 0x17C: call 0x116
        DW        0x2148    ; 0x17D: call 0x148
        DW        0x2858    ; 0x17E: goto 0x058
        DW        0x1F9B    ; 0x17F: btfss 0x1B,7
        DW        0x2983    ; 0x180: goto 0x183
        DW        0x03BF    ; 0x181: decf 0x3F,F
        DW        0x2986    ; 0x182: goto 0x186
        DW        0x1E1B    ; 0x183: btfss 0x1B,4
        DW        0x2972    ; 0x184: goto 0x172
        DW        0x0ABF    ; 0x185: incf 0x3F,F
        DW        0x3028    ; 0x186: movlw 0x28
        DW        0x0089    ; 0x187: movwf EEADR[b0]/EECON2[b1]
        DW        0x083F    ; 0x188: movf 0x3F,W
        DW        0x211D    ; 0x189: call 0x11D
        DW        0x2966    ; 0x18A: goto 0x166

halt_blink:
        DW        0x1505    ; 0x18B: bsf PORTA[b0]/TRISA[b1],2
        DW        0x138B    ; 0x18C: bcf INTCON,7
        DW        0x0000    ; 0x18D: nop
        DW        0x1105    ; 0x18E: bcf PORTA[b0]/TRISA[b1],2
        DW        0x298B    ; 0x18F: goto 0x18B

; Emit tone for one Morse time unit. W is preserved because these helpers are
; chained through nested letter routines. Clearing tone_state bit 7 enables the
; ISR's waveform path; the polarity is therefore opposite the old placeholder
; label inherited from the raw disassembly.
morse_tone_unit:
        MOVWF     saved_w             ; 0x190
        MOVF      morse_unit_ticks, W ; 0x191
        MOVWF     tmr0_wait_count     ; 0x192
        BCF       tone_state, 7       ; 0x193: enable ISR tone waveform
morse_tone_wait:
        MOVF      tmr0_wait_count, F  ; 0x194: ISR decrements this counter
        BTFSS     STATUS, Z           ; 0x195
        GOTO      morse_tone_wait     ; 0x196
        MOVF      saved_w, W          ; 0x197
        RETURN                        ; 0x198

; Emit silence for one Morse time unit, preserving W.
morse_silence_unit:
        MOVWF     saved_w             ; 0x199
        MOVF      morse_unit_ticks, W ; 0x19A
        MOVWF     tmr0_wait_count     ; 0x19B
        BSF       tone_state, 7       ; 0x19C: suppress ISR tone waveform
morse_silence_wait:
        MOVF      tmr0_wait_count, F  ; 0x19D
        BTFSS     STATUS, Z           ; 0x19E
        GOTO      morse_silence_wait  ; 0x19F
        MOVF      saved_w, W          ; 0x1A0
        RETURN                        ; 0x1A1

morse_i:
        DW        0x21BA    ; 0x1A2: call 0x1BA
        DW        0x29A5    ; 0x1A3: goto 0x1A5

morse_a:
        DW        0x21BD    ; 0x1A4: call 0x1BD

morse_s:
        DW        0x21BA    ; 0x1A5: call 0x1BA

morse_h:
        DW        0x21BA    ; 0x1A6: call 0x1BA
        DW        0x0008    ; 0x1A7: return

morse_m:
        DW        0x21BA    ; 0x1A8: call 0x1BA
        DW        0x29AB    ; 0x1A9: goto 0x1AB

morse_t:
        DW        0x21BD    ; 0x1AA: call 0x1BD

morse_o:
        DW        0x21BD    ; 0x1AB: call 0x1BD
        DW        0x21BD    ; 0x1AC: call 0x1BD
        DW        0x0008    ; 0x1AD: return

morse_g:
        DW        0x21BA    ; 0x1AE: call 0x1BA
        DW        0x29B1    ; 0x1AF: goto 0x1B1

morse_n:
        DW        0x21BD    ; 0x1B0: call 0x1BD

morse_d:
        DW        0x21BD    ; 0x1B1: call 0x1BD
        DW        0x21BA    ; 0x1B2: call 0x1BA
        DW        0x0008    ; 0x1B3: return

morse_u:
        DW        0x21BA    ; 0x1B4: call 0x1BA
        DW        0x29B7    ; 0x1B5: goto 0x1B7

morse_v:
        DW        0x21BD    ; 0x1B6: call 0x1BD
        DW        0x21BA    ; 0x1B7: call 0x1BA
        DW        0x21BD    ; 0x1B8: call 0x1BD
        DW        0x0008    ; 0x1B9: return

; Element builders. A dot is one tone unit plus one silence unit; a dash is
; three tone units plus one silence unit.
send_dot:
        CALL      morse_tone_unit     ; 0x1BA
        CALL      morse_silence_unit  ; 0x1BB
        RETURN                        ; 0x1BC

send_dash:
        CALL      morse_tone_unit     ; 0x1BD
        CALL      morse_tone_unit     ; 0x1BE
        CALL      morse_tone_unit     ; 0x1BF
        CALL      morse_silence_unit  ; 0x1C0
        RETURN                        ; 0x1C1

send_character_space:
        CALL      morse_silence_unit  ; 0x1C2
        CALL      morse_silence_unit  ; 0x1C3
        CALL      morse_silence_unit  ; 0x1C4
        CALL      morse_silence_unit  ; 0x1C5
        RETURN                        ; 0x1C6

morse_z:
        DW        0x21B0    ; 0x1C7: call 0x1B0
        DW        0x29C4    ; 0x1C8: goto 0x1C4

morse_f:
        DW        0x21A2    ; 0x1C9: call 0x1A2
        DW        0x21A6    ; 0x1CA: call 0x1A6
        DW        0x29C4    ; 0x1CB: goto 0x1C4

morse_e:
        DW        0x21A5    ; 0x1CC: call 0x1A5
        DW        0x29C4    ; 0x1CD: goto 0x1C4

morse_q:
        DW        0x21A8    ; 0x1CE: call 0x1A8
        DW        0x21AC    ; 0x1CF: call 0x1AC
        DW        0x29C4    ; 0x1D0: goto 0x1C4

morse_j:
        DW        0x21B6    ; 0x1D1: call 0x1B6
        DW        0x29C4    ; 0x1D2: goto 0x1C4

morse_b:
        DW        0x21AE    ; 0x1D3: call 0x1AE
        DW        0x21A6    ; 0x1D4: call 0x1A6
        DW        0x29C4    ; 0x1D5: goto 0x1C4

morse_m_alias:
        DW        0x21AB    ; 0x1D6: call 0x1AB
        DW        0x29C4    ; 0x1D7: goto 0x1C4

morse_n_alias:
        DW        0x21B1    ; 0x1D8: call 0x1B1
        DW        0x29C4    ; 0x1D9: goto 0x1C4

morse_o_alias:
        DW        0x21AA    ; 0x1DA: call 0x1AA
        DW        0x29C4    ; 0x1DB: goto 0x1C4

morse_p:
        DW        0x21A8    ; 0x1DC: call 0x1A8
        DW        0x21A6    ; 0x1DD: call 0x1A6
        DW        0x29C4    ; 0x1DE: goto 0x1C4

morse_x:
        DW        0x21B0    ; 0x1DF: call 0x1B0
        DW        0x21AC    ; 0x1E0: call 0x1AC
        DW        0x29C4    ; 0x1E1: goto 0x1C4

morse_t_alias:
        DW        0x21AE    ; 0x1E2: call 0x1AE
        DW        0x29C4    ; 0x1E3: goto 0x1C4

morse_i_alias:
        DW        0x21A2    ; 0x1E4: call 0x1A2
        DW        0x29C4    ; 0x1E5: goto 0x1C4

morse_l:
        DW        0x21AC    ; 0x1E6: call 0x1AC
        DW        0x29C4    ; 0x1E7: goto 0x1C4

morse_u_alias:
        DW        0x21B4    ; 0x1E8: call 0x1B4
        DW        0x29C4    ; 0x1E9: goto 0x1C4

morse_v_alias:
        DW        0x21A2    ; 0x1EA: call 0x1A2
        DW        0x21AC    ; 0x1EB: call 0x1AC
        DW        0x29C4    ; 0x1EC: goto 0x1C4

morse_w:
        DW        0x21A8    ; 0x1ED: call 0x1A8
        DW        0x29C4    ; 0x1EE: goto 0x1C4

morse_x_alias:
        DW        0x21A4    ; 0x1EF: call 0x1A4
        DW        0x21AC    ; 0x1F0: call 0x1AC
        DW        0x29C4    ; 0x1F1: goto 0x1C4

morse_y:
        DW        0x21B6    ; 0x1F2: call 0x1B6
        DW        0x21AC    ; 0x1F3: call 0x1AC
        DW        0x29C4    ; 0x1F4: goto 0x1C4

morse_z_alias:
        DW        0x21B0    ; 0x1F5: call 0x1B0
        DW        0x21A6    ; 0x1F6: call 0x1A6
        DW        0x29C4    ; 0x1F7: goto 0x1C4

message_moe:
        DW        0x3071    ; 0x1F8: movlw 0x71
        DW        0x0099    ; 0x1F9: movwf 0x19
        DW        0x3083    ; 0x1FA: movlw 0x83
        DW        0x009D    ; 0x1FB: movwf 0x1D
        DW        0x21C3    ; 0x1FC: call 0x1C3
        DW        0x21D6    ; 0x1FD: call 0x1D6
        DW        0x21DA    ; 0x1FE: call 0x1DA
        DW        0x232F    ; 0x1FF: call 0x32F
        DW        0x0008    ; 0x200: return

message_moi:
        DW        0x3069    ; 0x201: movlw 0x69
        DW        0x0099    ; 0x202: movwf 0x19
        DW        0x3083    ; 0x203: movlw 0x83
        DW        0x009D    ; 0x204: movwf 0x1D
        DW        0x21C3    ; 0x205: call 0x1C3
        DW        0x21D6    ; 0x206: call 0x1D6
        DW        0x21DA    ; 0x207: call 0x1DA
        DW        0x21CC    ; 0x208: call 0x1CC
        DW        0x0008    ; 0x209: return

message_mos:
        DW        0x3063    ; 0x20A: movlw 0x63
        DW        0x0099    ; 0x20B: movwf 0x19
        DW        0x3083    ; 0x20C: movlw 0x83
        DW        0x009D    ; 0x20D: movwf 0x1D
        DW        0x21C3    ; 0x20E: call 0x1C3
        DW        0x21D6    ; 0x20F: call 0x1D6
        DW        0x21DA    ; 0x210: call 0x1DA
        DW        0x21E4    ; 0x211: call 0x1E4
        DW        0x0008    ; 0x212: return

message_moh:
        DW        0x305E    ; 0x213: movlw 0x5E
        DW        0x0099    ; 0x214: movwf 0x19
        DW        0x3083    ; 0x215: movlw 0x83
        DW        0x009D    ; 0x216: movwf 0x1D
        DW        0x21C3    ; 0x217: call 0x1C3
        DW        0x21D6    ; 0x218: call 0x1D6
        DW        0x21DA    ; 0x219: call 0x1DA
        DW        0x21C9    ; 0x21A: call 0x1C9
        DW        0x0008    ; 0x21B: return

message_mo5:
        DW        0x3059    ; 0x21C: movlw 0x59
        DW        0x0099    ; 0x21D: movwf 0x19
        DW        0x3083    ; 0x21E: movlw 0x83
        DW        0x009D    ; 0x21F: movwf 0x1D
        DW        0x21C3    ; 0x220: call 0x1C3
        DW        0x21D6    ; 0x221: call 0x1D6
        DW        0x21DA    ; 0x222: call 0x1DA
        DW        0x2314    ; 0x223: call 0x314
        DW        0x0008    ; 0x224: return

message_mo:
        DW        0x3081    ; 0x225: movlw 0x81
        DW        0x0099    ; 0x226: movwf 0x19
        DW        0x3083    ; 0x227: movlw 0x83
        DW        0x009D    ; 0x228: movwf 0x1D
        DW        0x21C3    ; 0x229: call 0x1C3
        DW        0x21D6    ; 0x22A: call 0x1D6
        DW        0x21DA    ; 0x22B: call 0x1DA
        DW        0x0008    ; 0x22C: return

message_a:
        DW        0x3074    ; 0x22D: movlw 0x74
        DW        0x0099    ; 0x22E: movwf 0x19
        DW        0x3080    ; 0x22F: movlw 0x80
        DW        0x009D    ; 0x230: movwf 0x1D
        DW        0x21C4    ; 0x231: call 0x1C4
        DW        0x2323    ; 0x232: call 0x323
        DW        0x21C4    ; 0x233: call 0x1C4
        DW        0x2323    ; 0x234: call 0x323
        DW        0x21C4    ; 0x235: call 0x1C4
        DW        0x2323    ; 0x236: call 0x323
        DW        0x0008    ; 0x237: return

message_b:
        DW        0x3074    ; 0x238: movlw 0x74
        DW        0x0099    ; 0x239: movwf 0x19
        DW        0x3081    ; 0x23A: movlw 0x81
        DW        0x009D    ; 0x23B: movwf 0x1D
        DW        0x21C3    ; 0x23C: call 0x1C3
        DW        0x2326    ; 0x23D: call 0x326
        DW        0x21C3    ; 0x23E: call 0x1C3
        DW        0x2326    ; 0x23F: call 0x326
        DW        0x0008    ; 0x240: return

message_c:
        DW        0x3074    ; 0x241: movlw 0x74
        DW        0x0099    ; 0x242: movwf 0x19
        DW        0x3082    ; 0x243: movlw 0x82
        DW        0x009D    ; 0x244: movwf 0x1D
        DW        0x21C3    ; 0x245: call 0x1C3
        DW        0x2332    ; 0x246: call 0x332
        DW        0x21C3    ; 0x247: call 0x1C3
        DW        0x2332    ; 0x248: call 0x332
        DW        0x0008    ; 0x249: return

message_l:
        DW        0x3074    ; 0x24A: movlw 0x74
        DW        0x0099    ; 0x24B: movwf 0x19
        DW        0x3084    ; 0x24C: movlw 0x84
        DW        0x009D    ; 0x24D: movwf 0x1D
        DW        0x21C3    ; 0x24E: call 0x1C3
        DW        0x21D3    ; 0x24F: call 0x1D3
        DW        0x21C3    ; 0x250: call 0x1C3
        DW        0x21D3    ; 0x251: call 0x1D3
        DW        0x0008    ; 0x252: return

message_n:
        DW        0x3074    ; 0x253: movlw 0x74
        DW        0x0099    ; 0x254: movwf 0x19
        DW        0x3085    ; 0x255: movlw 0x85
        DW        0x009D    ; 0x256: movwf 0x1D
        DW        0x21C4    ; 0x257: call 0x1C4
        DW        0x21D8    ; 0x258: call 0x1D8
        DW        0x21C4    ; 0x259: call 0x1C4
        DW        0x21D8    ; 0x25A: call 0x1D8
        DW        0x21C4    ; 0x25B: call 0x1C4
        DW        0x21D8    ; 0x25C: call 0x1D8
        DW        0x0008    ; 0x25D: return

message_p:
        DW        0x3066    ; 0x25E: movlw 0x66
        DW        0x0099    ; 0x25F: movwf 0x19
        DW        0x3086    ; 0x260: movlw 0x86
        DW        0x009D    ; 0x261: movwf 0x1D
        DW        0x21C3    ; 0x262: call 0x1C3
        DW        0x21DC    ; 0x263: call 0x1DC
        DW        0x21C3    ; 0x264: call 0x1C3
        DW        0x21DC    ; 0x265: call 0x1DC
        DW        0x0008    ; 0x266: return

message_v:
        DW        0x3074    ; 0x267: movlw 0x74
        DW        0x0099    ; 0x268: movwf 0x19
        DW        0x3087    ; 0x269: movlw 0x87
        DW        0x009D    ; 0x26A: movwf 0x1D
        DW        0x21C3    ; 0x26B: call 0x1C3
        DW        0x21EA    ; 0x26C: call 0x1EA
        DW        0x21C3    ; 0x26D: call 0x1C3
        DW        0x21EA    ; 0x26E: call 0x1EA
        DW        0x0008    ; 0x26F: return

message_x:
        DW        0x3066    ; 0x270: movlw 0x66
        DW        0x0099    ; 0x271: movwf 0x19
        DW        0x3080    ; 0x272: movlw 0x80
        DW        0x009D    ; 0x273: movwf 0x1D
        DW        0x21C3    ; 0x274: call 0x1C3
        DW        0x21EF    ; 0x275: call 0x1EF
        DW        0x21C3    ; 0x276: call 0x1C3
        DW        0x21EF    ; 0x277: call 0x1EF
        DW        0x0008    ; 0x278: return

message_z:
        DW        0x3066    ; 0x279: movlw 0x66
        DW        0x0099    ; 0x27A: movwf 0x19
        DW        0x3081    ; 0x27B: movlw 0x81
        DW        0x009D    ; 0x27C: movwf 0x1D
        DW        0x21C3    ; 0x27D: call 0x1C3
        DW        0x21F5    ; 0x27E: call 0x1F5
        DW        0x21C3    ; 0x27F: call 0x1C3
        DW        0x21F5    ; 0x280: call 0x1F5
        DW        0x0008    ; 0x281: return

message_fox:
        DW        0x3052    ; 0x282: movlw 0x52
        DW        0x0099    ; 0x283: movwf 0x19
        DW        0x3083    ; 0x284: movlw 0x83
        DW        0x009D    ; 0x285: movwf 0x1D
        DW        0x21C3    ; 0x286: call 0x1C3
        DW        0x2332    ; 0x287: call 0x332
        DW        0x21DA    ; 0x288: call 0x1DA
        DW        0x21EF    ; 0x289: call 0x1EF
        DW        0x0008    ; 0x28A: return
        DW        0x3FFF    ; 0x28B: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x28C: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x28D: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x28E: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x28F: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x290: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x291: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x292: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x293: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x294: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x295: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x296: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x297: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x298: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x299: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x29A: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x29B: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x29C: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x29D: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x29E: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x29F: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2A0: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2A1: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2A2: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2A3: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2A4: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2A5: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2A6: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2A7: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2A8: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2A9: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2AA: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2AB: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2AC: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2AD: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2AE: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2AF: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2B0: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2B1: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2B2: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2B3: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2B4: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2B5: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2B6: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2B7: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2B8: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2B9: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2BA: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2BB: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2BC: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2BD: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2BE: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2BF: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2C0: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2C1: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2C2: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2C3: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2C4: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2C5: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2C6: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2C7: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2C8: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2C9: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2CA: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2CB: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2CC: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2CD: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2CE: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2CF: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2D0: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2D1: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2D2: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2D3: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2D4: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2D5: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2D6: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2D7: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2D8: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2D9: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2DA: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2DB: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2DC: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2DD: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2DE: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2DF: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2E0: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2E1: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2E2: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2E3: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2E4: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2E5: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2E6: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2E7: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2E8: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2E9: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2EA: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2EB: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2EC: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2ED: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2EE: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2EF: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2F0: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2F1: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2F2: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2F3: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2F4: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2F5: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2F6: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2F7: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2F8: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2F9: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2FA: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2FB: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2FC: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2FD: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2FE: erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF    ; 0x2FF: erased (instruction encoding: addlw 0xFF)

hex_digit_dispatch:
        DW        0x390F    ; 0x300: andlw 0x0F
        DW        0x00A2    ; 0x301: movwf 0x22
        DW        0x0722    ; 0x302: addwf 0x22,W
        DW        0x0722    ; 0x303: addwf 0x22,W
        DW        0x0782    ; 0x304: addwf PCL,F
        DW        0x21AA    ; 0x305: call 0x1AA
        DW        0x21AB    ; 0x306: call 0x1AB
        DW        0x29C4    ; 0x307: goto 0x1C4
        DW        0x21A8    ; 0x308: call 0x1A8
        DW        0x21AB    ; 0x309: call 0x1AB
        DW        0x29C4    ; 0x30A: goto 0x1C4
        DW        0x21B4    ; 0x30B: call 0x1B4
        DW        0x21AB    ; 0x30C: call 0x1AB
        DW        0x29C4    ; 0x30D: goto 0x1C4
        DW        0x21A2    ; 0x30E: call 0x1A2
        DW        0x21AB    ; 0x30F: call 0x1AB
        DW        0x29C4    ; 0x310: goto 0x1C4
        DW        0x21A2    ; 0x311: call 0x1A2
        DW        0x21B7    ; 0x312: call 0x1B7
        DW        0x29C4    ; 0x313: goto 0x1C4
        DW        0x21A2    ; 0x314: call 0x1A2
        DW        0x21A5    ; 0x315: call 0x1A5
        DW        0x29C4    ; 0x316: goto 0x1C4
        DW        0x21A4    ; 0x317: call 0x1A4
        DW        0x21A5    ; 0x318: call 0x1A5
        DW        0x29C4    ; 0x319: goto 0x1C4
        DW        0x21B0    ; 0x31A: call 0x1B0
        DW        0x21A5    ; 0x31B: call 0x1A5
        DW        0x29C4    ; 0x31C: goto 0x1C4
        DW        0x21AA    ; 0x31D: call 0x1AA
        DW        0x21A5    ; 0x31E: call 0x1A5
        DW        0x29C4    ; 0x31F: goto 0x1C4
        DW        0x21AA    ; 0x320: call 0x1AA
        DW        0x21B1    ; 0x321: call 0x1B1
        DW        0x29C4    ; 0x322: goto 0x1C4
        DW        0x21B7    ; 0x323: call 0x1B7
        DW        0x29C4    ; 0x324: goto 0x1C4
        DW        0x0000    ; 0x325: nop
        DW        0x21A4    ; 0x326: call 0x1A4
        DW        0x21A6    ; 0x327: call 0x1A6
        DW        0x29C4    ; 0x328: goto 0x1C4
        DW        0x21B1    ; 0x329: call 0x1B1
        DW        0x21B1    ; 0x32A: call 0x1B1
        DW        0x29C4    ; 0x32B: goto 0x1C4
        DW        0x21A4    ; 0x32C: call 0x1A4
        DW        0x29C4    ; 0x32D: goto 0x1C4
        DW        0x0000    ; 0x32E: nop
        DW        0x21A6    ; 0x32F: call 0x1A6
        DW        0x29C4    ; 0x330: goto 0x1C4
        DW        0x0000    ; 0x331: nop
        DW        0x21B4    ; 0x332: call 0x1B4
        DW        0x21A6    ; 0x333: call 0x1A6
        DW        0x29C4    ; 0x334: goto 0x1C4

; Convert tone_state bits 2:0 into the corresponding PORTB bit mask.
bit_mask_lookup:
        MOVF      tone_state, W       ; 0x335
        ANDLW     0x07                ; 0x336
        ADDWF     PCL, F              ; 0x337
        RETLW     0x10                ; 0x338
        RETLW     0x40                ; 0x339
        RETLW     0x01                ; 0x33A
        RETLW     0x20                ; 0x33B
        RETLW     0x08                ; 0x33C
        RETLW     0x02                ; 0x33D
        RETLW     0x80                ; 0x33E
        RETLW     0x04                ; 0x33F

; Key the transmitter, resample S1, and tail-dispatch its low nibble to one of
; the sixteen message routines. PCLATH was initialized to page 3 at startup.
message_dispatch:
        BSF       porta_shadow, 1     ; 0x340: assert PTT through RA1
        CALL      read_switches       ; 0x341
        MOVF      switch_state, W     ; 0x342
        ANDLW     0x0F                ; 0x343: S1 only
        MOVWF     message_index       ; 0x344
        ADDWF     PCL, F              ; 0x345
        GOTO      message_moe         ; 0x346: S1=0
        GOTO      message_moi         ; 0x347: S1=1
        GOTO      message_mos         ; 0x348: S1=2
        GOTO      message_moh         ; 0x349: S1=3
        GOTO      message_mo5         ; 0x34A: S1=4
        GOTO      message_mo          ; 0x34B: S1=5
        GOTO      message_a           ; 0x34C: S1=6
        GOTO      message_b           ; 0x34D: S1=7
        GOTO      message_c           ; 0x34E: S1=8
        GOTO      message_l           ; 0x34F: S1=9
        GOTO      message_n           ; 0x350: S1=A
        GOTO      message_p           ; 0x351: S1=B
        GOTO      message_v           ; 0x352: S1=C
        GOTO      message_x           ; 0x353: S1=D
        GOTO      message_z           ; 0x354: S1=E
        GOTO      message_fox         ; 0x355: S1=F

; Map the low-nibble switch index in W to a nonzero pseudo-random seed.
; Callers prove W is in the range 0..15 and PCLATH selects this code page.
lfsr_seed_lookup:
        ADDWF     PCL, F              ; 0x356
        RETLW     0xFE                ; 0x357: S1=0
        RETLW     0xCE                ; 0x358: S1=1
        RETLW     0x5B                ; 0x359: S1=2
        RETLW     0x34                ; 0x35A: S1=3
        RETLW     0x4F                ; 0x35B: S1=4
        RETLW     0x40                ; 0x35C: S1=5
        RETLW     0x54                ; 0x35D: S1=6
        RETLW     0x70                ; 0x35E: S1=7
        RETLW     0x7B                ; 0x35F: S1=8
        RETLW     0x30                ; 0x360: S1=9
        RETLW     0xE9                ; 0x361: S1=A
        RETLW     0xBE                ; 0x362: S1=B
        RETLW     0x14                ; 0x363: S1=C
        RETLW     0x63                ; 0x364: S1=D
        RETLW     0x57                ; 0x365: S1=E
        RETLW     0x24                ; 0x366: S1=F

tone_pattern_lookup:
        DW        0x0782    ; 0x367: addwf PCL,F
        DW        0x34FF    ; 0x368: retlw 0xFF
        DW        0x343B    ; 0x369: retlw 0x3B
        DW        0x348D    ; 0x36A: retlw 0x8D
        DW        0x3443    ; 0x36B: retlw 0x43
        DW        0x34A0    ; 0x36C: retlw 0xA0
        DW        0x3434    ; 0x36D: retlw 0x34
        DW        0x34DA    ; 0x36E: retlw 0xDA
        DW        0x340E    ; 0x36F: retlw 0x0E
        DW        0x34A9    ; 0x370: retlw 0xA9
        DW        0x3463    ; 0x371: retlw 0x63
        DW        0x3495    ; 0x372: retlw 0x95
        DW        0x3411    ; 0x373: retlw 0x11
        DW        0x34EE    ; 0x374: retlw 0xEE
        DW        0x342A    ; 0x375: retlw 0x2A
        DW        0x3488    ; 0x376: retlw 0x88
        DW        0x3456    ; 0x377: retlw 0x56
        DW        0x34B1    ; 0x378: retlw 0xB1
        DW        0x3425    ; 0x379: retlw 0x25
        DW        0x34CB    ; 0x37A: retlw 0xCB
        DW        0x340B    ; 0x37B: retlw 0x0B
        DW        0x34BC    ; 0x37C: retlw 0xBC
        DW        0x3472    ; 0x37D: retlw 0x72
        DW        0x3484    ; 0x37E: retlw 0x84
        DW        0x3400    ; 0x37F: retlw 0x00
        DW        0x34EB    ; 0x380: retlw 0xEB
        DW        0x343F    ; 0x381: retlw 0x3F
        DW        0x3499    ; 0x382: retlw 0x99
        DW        0x3447    ; 0x383: retlw 0x47
        DW        0x34A0    ; 0x384: retlw 0xA0
        DW        0x3420    ; 0x385: retlw 0x20
        DW        0x34DE    ; 0x386: retlw 0xDE
        DW        0x341A    ; 0x387: retlw 0x1A
        DW        0x34AD    ; 0x388: retlw 0xAD
        DW        0x3463    ; 0x389: retlw 0x63
        DW        0x3481    ; 0x38A: retlw 0x81
        DW        0x3415    ; 0x38B: retlw 0x15
        DW        0x34FA    ; 0x38C: retlw 0xFA
        DW        0x342E    ; 0x38D: retlw 0x2E
        DW        0x3488    ; 0x38E: retlw 0x88
        DW        0x3442    ; 0x38F: retlw 0x42
        DW        0x34B5    ; 0x390: retlw 0xB5
        DW        0x3431    ; 0x391: retlw 0x31
        DW        0x34CF    ; 0x392: retlw 0xCF
        DW        0x340B    ; 0x393: retlw 0x0B
        DW        0x34A8    ; 0x394: retlw 0xA8
        DW        0x3476    ; 0x395: retlw 0x76
        DW        0x3490    ; 0x396: retlw 0x90
        DW        0x3404    ; 0x397: retlw 0x04
        DW        0x34EB    ; 0x398: retlw 0xEB
        DW        0x342B    ; 0x399: retlw 0x2B
        DW        0x349D    ; 0x39A: retlw 0x9D
        DW        0x3453    ; 0x39B: retlw 0x53
        DW        0x34A4    ; 0x39C: retlw 0xA4
        DW        0x3420    ; 0x39D: retlw 0x20
        DW        0x34CA    ; 0x39E: retlw 0xCA
        DW        0x341E    ; 0x39F: retlw 0x1E
        DW        0x34B9    ; 0x3A0: retlw 0xB9
        DW        0x3467    ; 0x3A1: retlw 0x67
        DW        0x3481    ; 0x3A2: retlw 0x81
        DW        0x3401    ; 0x3A3: retlw 0x01
        DW        0x34FE    ; 0x3A4: retlw 0xFE
        DW        0x343A    ; 0x3A5: retlw 0x3A
        DW        0x348C    ; 0x3A6: retlw 0x8C
        DW        0x3442    ; 0x3A7: retlw 0x42
        DW        0x34A1    ; 0x3A8: retlw 0xA1
        DW        0x3435    ; 0x3A9: retlw 0x35
        DW        0x34DB    ; 0x3AA: retlw 0xDB
        DW        0x340F    ; 0x3AB: retlw 0x0F
        DW        0x34A8    ; 0x3AC: retlw 0xA8
        DW        0x3462    ; 0x3AD: retlw 0x62
        DW        0x3494    ; 0x3AE: retlw 0x94
        DW        0x3410    ; 0x3AF: retlw 0x10
        DW        0x34EF    ; 0x3B0: retlw 0xEF
        DW        0x342B    ; 0x3B1: retlw 0x2B
        DW        0x3489    ; 0x3B2: retlw 0x89
        DW        0x3457    ; 0x3B3: retlw 0x57
        DW        0x34B0    ; 0x3B4: retlw 0xB0
        DW        0x3424    ; 0x3B5: retlw 0x24
        DW        0x34CA    ; 0x3B6: retlw 0xCA
        DW        0x340A    ; 0x3B7: retlw 0x0A
        DW        0x34BD    ; 0x3B8: retlw 0xBD
        DW        0x3473    ; 0x3B9: retlw 0x73
        DW        0x3485    ; 0x3BA: retlw 0x85
        DW        0x3401    ; 0x3BB: retlw 0x01
        DW        0x34EA    ; 0x3BC: retlw 0xEA
        DW        0x343E    ; 0x3BD: retlw 0x3E
        DW        0x3498    ; 0x3BE: retlw 0x98
        DW        0x3446    ; 0x3BF: retlw 0x46
        DW        0x34A1    ; 0x3C0: retlw 0xA1
        DW        0x3421    ; 0x3C1: retlw 0x21
        DW        0x34DF    ; 0x3C2: retlw 0xDF
        DW        0x341B    ; 0x3C3: retlw 0x1B
        DW        0x34AC    ; 0x3C4: retlw 0xAC
        DW        0x3462    ; 0x3C5: retlw 0x62
        DW        0x3480    ; 0x3C6: retlw 0x80
        DW        0x3414    ; 0x3C7: retlw 0x14
        DW        0x34FB    ; 0x3C8: retlw 0xFB
        DW        0x342F    ; 0x3C9: retlw 0x2F
        DW        0x3489    ; 0x3CA: retlw 0x89
        DW        0x3443    ; 0x3CB: retlw 0x43
        DW        0x34B4    ; 0x3CC: retlw 0xB4
        DW        0x3430    ; 0x3CD: retlw 0x30
        DW        0x34CE    ; 0x3CE: retlw 0xCE
        DW        0x340A    ; 0x3CF: retlw 0x0A
        DW        0x34A9    ; 0x3D0: retlw 0xA9
        DW        0x3477    ; 0x3D1: retlw 0x77
        DW        0x3491    ; 0x3D2: retlw 0x91
        DW        0x3405    ; 0x3D3: retlw 0x05
        DW        0x34EA    ; 0x3D4: retlw 0xEA
        DW        0x342A    ; 0x3D5: retlw 0x2A
        DW        0x349C    ; 0x3D6: retlw 0x9C
        DW        0x3452    ; 0x3D7: retlw 0x52
        DW        0x34A5    ; 0x3D8: retlw 0xA5
        DW        0x3421    ; 0x3D9: retlw 0x21
        DW        0x34CB    ; 0x3DA: retlw 0xCB
        DW        0x341F    ; 0x3DB: retlw 0x1F
        DW        0x34B8    ; 0x3DC: retlw 0xB8
        DW        0x3466    ; 0x3DD: retlw 0x66
        DW        0x3480    ; 0x3DE: retlw 0x80
        DW        0x3400    ; 0x3DF: retlw 0x00
        DW        0x34A1    ; 0x3E0: retlw 0xA1
        DW        0x3421    ; 0x3E1: retlw 0x21
        DW        0x34DF    ; 0x3E2: retlw 0xDF
        DW        0x341B    ; 0x3E3: retlw 0x1B
        DW        0x34AC    ; 0x3E4: retlw 0xAC
        DW        0x3462    ; 0x3E5: retlw 0x62
        DW        0x3480    ; 0x3E6: retlw 0x80
        DW        0x3414    ; 0x3E7: retlw 0x14
        DW        0x34FB    ; 0x3E8: retlw 0xFB
        DW        0x342F    ; 0x3E9: retlw 0x2F
        DW        0x3489    ; 0x3EA: retlw 0x89
        DW        0x3443    ; 0x3EB: retlw 0x43
        DW        0x34B4    ; 0x3EC: retlw 0xB4
        DW        0x3430    ; 0x3ED: retlw 0x30
        DW        0x34CE    ; 0x3EE: retlw 0xCE
        DW        0x340A    ; 0x3EF: retlw 0x0A
        DW        0x34A9    ; 0x3F0: retlw 0xA9
        DW        0x3477    ; 0x3F1: retlw 0x77
        DW        0x3491    ; 0x3F2: retlw 0x91
        DW        0x3405    ; 0x3F3: retlw 0x05
        DW        0x34EA    ; 0x3F4: retlw 0xEA
        DW        0x342A    ; 0x3F5: retlw 0x2A
        DW        0x349C    ; 0x3F6: retlw 0x9C
        DW        0x3452    ; 0x3F7: retlw 0x52
        DW        0x34A5    ; 0x3F8: retlw 0xA5
        DW        0x3421    ; 0x3F9: retlw 0x21
        DW        0x34CB    ; 0x3FA: retlw 0xCB
        DW        0x341F    ; 0x3FB: retlw 0x1F
        DW        0x34B8    ; 0x3FC: retlw 0xB8
        DW        0x3466    ; 0x3FD: retlw 0x66
        DW        0x3480    ; 0x3FE: retlw 0x80
        DW        0x3400    ; 0x3FF: retlw 0x00

; The four user-ID words are erased (low nibble F in each word).
        __IDLOCS  0xFFFF

; XT oscillator, WDT off, power-up timer on, code protection off.
        __CONFIG  0x3FF1

; PIC16F84A data EEPROM begins at word address 0x2100.
        ORG       0x2100
        DB        0x14, 0x28, 0x14, 0x64, 0x18, 0x60, 0x24, 0x90    ; EEPROM 0x00-0x07
        DB        0x28, 0x50, 0x30, 0xC0, 0x3C, 0xF0, 0x3C, 0xF0    ; EEPROM 0x08-0x0F
        DB        0x0C, 0x18, 0x14, 0x14, 0x14, 0x28, 0x14, 0x64    ; EEPROM 0x10-0x17
        DB        0x0C, 0x24, 0x10, 0x30, 0x10, 0x40, 0x3C, 0x00    ; EEPROM 0x18-0x1F
        DB        0x00, 0x00, 0x07, 0x08, 0x0E, 0x10, 0x1C, 0x20    ; EEPROM 0x20-0x27
        DB        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF    ; EEPROM 0x28-0x2F
        DB        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF    ; EEPROM 0x30-0x37
        DB        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF    ; EEPROM 0x38-0x3F

        END
