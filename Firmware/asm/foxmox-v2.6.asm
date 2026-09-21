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
isr_w_save      EQU       0x0C
isr_status_save EQU       0x0D
second_div_hi   EQU       0x0E
second_div_lo   EQU       0x0F
subsecond_phase EQU       0x10
tmr0_wait_count EQU       0x11
message_seconds EQU       0x12
morse_unit_ticks EQU      0x19
porta_shadow    EQU       0x1A
switch_state    EQU       0x1B
service_delay_lo EQU      0x1E
service_delay_hi EQU      0x1F
tone_phase      EQU       0x1C
tone_state      EQU       0x1D
lfsr_state      EQU       0x20
hex_digit_index EQU       0x22
lfsr_steps      EQU       0x23
saved_w         EQU       0x25
interrupt_flag  EQU       0x27
hex_byte        EQU       0x28
message_index   EQU       0x2B
timing_trim     EQU       0x3F

; PIC14 instructions encode seven file-address bits; RP0 supplies the bank.
; These aliases keep bank-1 register names visible without gpasm's expected
; "register not in bank 0" advisory for their absolute header values.
OPTION_REG_FILE EQU       (OPTION_REG & 0x7F)
TRISA_FILE      EQU       (TRISA & 0x7F)
TRISB_FILE      EQU       (TRISB & 0x7F)
EECON1_FILE     EQU       (EECON1 & 0x7F)
EECON2_FILE     EQU       (EECON2 & 0x7F)

        ORG       0x0000

reset_vector:
        GOTO      startup             ; 0x000
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
        CLRF      INTCON              ; 0x058: interrupts off
        BCF       STATUS, RP0         ; 0x059: bank 0
        MOVLW     0x08                ; 0x05A: RA3 latch high for service strap
        MOVWF     PORTA               ; 0x05B
        MOVLW     0x00                ; 0x05C
        MOVWF     PORTB               ; 0x05D
        BSF       STATUS, RP0         ; 0x05E: bank 1
        MOVLW     0x08                ; 0x05F
        MOVWF     OPTION_REG_FILE     ; 0x060: TMR0 from Fosc/4, no prescaler
        MOVLW     0xE4                ; 0x061
        MOVWF     TRISA_FILE          ; 0x062: RA3 output, RA2 input
        MOVLW     0x00                ; 0x063
        MOVWF     TRISB_FILE          ; 0x064
        BCF       STATUS, RP0         ; 0x065: bank 0
        MOVLW     0x03                ; 0x066
        MOVWF     PCLATH              ; 0x067: computed tables live at 0x300

        MOVLW     0x0C                ; 0x068
        MOVWF     FSR                 ; 0x069
clear_ram:
        CLRF      INDF                ; 0x06A: clear RAM 0x0C..0x3F
        INCF      FSR, F              ; 0x06B
        BTFSS     FSR, 6              ; 0x06C
        GOTO      clear_ram           ; 0x06D

        MOVLW     0xA6                ; 0x06E
        MOVWF     second_div_lo       ; 0x06F
        MOVLW     0x0E                ; 0x070
        MOVWF     second_div_hi       ; 0x071
        MOVLW     0x83                ; 0x072
        MOVWF     tone_state          ; 0x073
        MOVLW     0x46                ; 0x074
        MOVWF     morse_unit_ticks    ; 0x075
        MOVLW     0x28                ; 0x076
        CALL      eeprom_read         ; 0x077
        MOVWF     timing_trim         ; 0x078
        BTFSS     PORTA, 2            ; 0x079: low selects calibration mode
        GOTO      service_mode        ; 0x07A

        CLRF      TMR0                ; 0x07B
        BSF       INTCON, T0IE        ; 0x07C
        BSF       INTCON, GIE         ; 0x07D
        BSF       STATUS, RP0         ; 0x07E: bank 1
        MOVLW     0xE8                ; 0x07F
        MOVWF     TRISA_FILE          ; 0x080: RA2 output, RA3 input
        CALL      read_switches       ; 0x081: returns in bank 0
        MOVLW     0x0F                ; 0x082
        ANDWF     switch_state, W     ; 0x083: isolate S1
        MOVWF     message_index       ; 0x084
        CALL      lfsr_seed_lookup    ; 0x085
        MOVWF     lfsr_state          ; 0x086

        BSF       porta_shadow, 1     ; 0x087: assert PTT
        MOVLW     0x04                ; 0x088
        MOVWF     message_seconds     ; 0x089
        CALL      send_three_space_units ; 0x08A
        CALL      message_dispatch    ; 0x08B
startup_wait_message:
        MOVF      message_seconds, F  ; 0x08C
        BTFSS     STATUS, Z           ; 0x08D
        GOTO      startup_wait_message ; 0x08E
        BCF       porta_shadow, 1     ; 0x08F: release PTT
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

; Calibration/service mode entered when RA2 is held low during startup.
service_mode:
service_wait_release_restart:
        CLRF      service_delay_lo    ; 0x151
        MOVLW     0x7F                ; 0x152
        MOVWF     service_delay_hi    ; 0x153
service_wait_release:
        BTFSS     PORTA, 2            ; 0x154: restart until RA2 is released
        GOTO      service_wait_release_restart ; 0x155
        DECFSZ    service_delay_lo, F ; 0x156
        GOTO      service_wait_release ; 0x157
        DECFSZ    service_delay_hi, F ; 0x158
        GOTO      service_wait_release ; 0x159

        BSF       STATUS, RP0         ; 0x15A: bank 1
        MOVLW     0xE8                ; 0x15B
        MOVWF     TRISA_FILE          ; 0x15C: RA2 output, RA3 input
        BCF       STATUS, RP0         ; 0x15D: bank 0
        CALL      read_switches       ; 0x15E
        MOVF      switch_state, F     ; 0x15F
        BTFSC     STATUS, Z           ; 0x160
        GOTO      halt_blink          ; 0x161: both switches zero

        BSF       porta_shadow, 1     ; 0x162: assert PTT
        CLRF      TMR0                ; 0x163
        BSF       INTCON, T0IE        ; 0x164
        BSF       INTCON, GIE         ; 0x165

service_announce:
        CLRF      service_delay_lo    ; 0x166
        MOVLW     0x7F                ; 0x167
        MOVWF     service_delay_hi    ; 0x168
service_announce_delay:
        DECFSZ    service_delay_lo, F ; 0x169
        GOTO      service_announce_delay ; 0x16A
        DECFSZ    service_delay_hi, F ; 0x16B
        GOTO      service_announce_delay ; 0x16C
        CALL      send_three_space_units ; 0x16D
        MOVF      timing_trim, W      ; 0x16E
        CALL      send_hex_byte       ; 0x16F
        MOVLW     0x05                ; 0x170
        MOVWF     message_seconds     ; 0x171

service_poll_switch:
        CALL      read_switches       ; 0x172
        MOVF      switch_state, W     ; 0x173
        ANDLW     0xF0                ; 0x174: inspect S2 only
        BTFSS     STATUS, Z           ; 0x175
        GOTO      service_apply_switch ; 0x176
        MOVF      message_seconds, F  ; 0x177
        BTFSS     STATUS, Z           ; 0x178
        GOTO      service_apply_switch ; 0x179
        CALL      send_three_space_units ; 0x17A
        MOVLW     0x28                ; 0x17B
        CALL      eeprom_read         ; 0x17C
        CALL      send_hex_byte       ; 0x17D
        GOTO      startup             ; 0x17E

service_apply_switch:
        BTFSS     switch_state, 7     ; 0x17F: S2 8-F decrements
        GOTO      service_test_increment ; 0x180
        DECF      timing_trim, F      ; 0x181
        GOTO      service_save_trim   ; 0x182
service_test_increment:
        BTFSS     switch_state, 4     ; 0x183: odd S2 1,3,5,7 increments
        GOTO      service_poll_switch ; 0x184
        INCF      timing_trim, F      ; 0x185
service_save_trim:
        MOVLW     0x28                ; 0x186
        MOVWF     EEADR              ; 0x187
        MOVF      timing_trim, W      ; 0x188
        CALL      eeprom_write        ; 0x189
        GOTO      service_announce    ; 0x18A

halt_blink:
        BSF       PORTA, 2            ; 0x18B
        BCF       INTCON, GIE         ; 0x18C
        NOP                            ; 0x18D
        BCF       PORTA, 2            ; 0x18E
        GOTO      halt_blink          ; 0x18F

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

morse_s_sequence:
        CALL      send_dot                ; 0x1A2
        GOTO      morse_i_sequence        ; 0x1A3

morse_d_sequence:
        CALL      send_dash               ; 0x1A4

morse_i_sequence:
        CALL      send_dot                ; 0x1A5

morse_e_sequence:
        CALL      send_dot                ; 0x1A6
        RETURN                            ; 0x1A7

morse_w_sequence:
        CALL      send_dot                ; 0x1A8
        GOTO      morse_m_sequence        ; 0x1A9

morse_o_sequence:
        CALL      send_dash               ; 0x1AA

morse_m_sequence:
        CALL      send_dash               ; 0x1AB
morse_t_sequence:
        CALL      send_dash               ; 0x1AC
        RETURN                            ; 0x1AD

morse_r_sequence:
        CALL      send_dot                ; 0x1AE
        GOTO      morse_n_sequence        ; 0x1AF

morse_g_sequence:
        CALL      send_dash               ; 0x1B0

morse_n_sequence:
        CALL      send_dash               ; 0x1B1
        CALL      send_dot                ; 0x1B2
        RETURN                            ; 0x1B3

morse_u_sequence:
        CALL      send_dot                ; 0x1B4
        GOTO      morse_u_tail            ; 0x1B5

morse_k_sequence:
        CALL      send_dash               ; 0x1B6
morse_u_tail:
        CALL      send_dot                ; 0x1B7
        CALL      send_dash               ; 0x1B8
        RETURN                            ; 0x1B9

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
send_three_space_units:
        CALL      morse_silence_unit  ; 0x1C3
finish_character_space:
        CALL      morse_silence_unit  ; 0x1C4
        CALL      morse_silence_unit  ; 0x1C5
        RETURN                        ; 0x1C6

send_morse_g:
        CALL      morse_g_sequence        ; 0x1C7
        GOTO      finish_character_space  ; 0x1C8

send_morse_h:
        CALL      morse_s_sequence        ; 0x1C9
        CALL      morse_e_sequence        ; 0x1CA
        GOTO      finish_character_space  ; 0x1CB

send_morse_i:
        CALL      morse_i_sequence        ; 0x1CC
        GOTO      finish_character_space  ; 0x1CD

send_morse_j:
        CALL      morse_w_sequence        ; 0x1CE
        CALL      morse_t_sequence        ; 0x1CF
        GOTO      finish_character_space  ; 0x1D0

send_morse_k:
        CALL      morse_k_sequence        ; 0x1D1
        GOTO      finish_character_space  ; 0x1D2

send_morse_l:
        CALL      morse_r_sequence        ; 0x1D3
        CALL      morse_e_sequence        ; 0x1D4
        GOTO      finish_character_space  ; 0x1D5

send_morse_m:
        CALL      morse_m_sequence        ; 0x1D6
        GOTO      finish_character_space  ; 0x1D7

send_morse_n:
        CALL      morse_n_sequence        ; 0x1D8
        GOTO      finish_character_space  ; 0x1D9

send_morse_o:
        CALL      morse_o_sequence        ; 0x1DA
        GOTO      finish_character_space  ; 0x1DB

send_morse_p:
        CALL      morse_w_sequence        ; 0x1DC
        CALL      morse_e_sequence        ; 0x1DD
        GOTO      finish_character_space  ; 0x1DE

send_morse_q:
        CALL      morse_g_sequence        ; 0x1DF
        CALL      morse_t_sequence        ; 0x1E0
        GOTO      finish_character_space  ; 0x1E1

send_morse_r:
        CALL      morse_r_sequence        ; 0x1E2
        GOTO      finish_character_space  ; 0x1E3

send_morse_s:
        CALL      morse_s_sequence        ; 0x1E4
        GOTO      finish_character_space  ; 0x1E5

send_morse_t:
        CALL      morse_t_sequence        ; 0x1E6
        GOTO      finish_character_space  ; 0x1E7

send_morse_u:
        CALL      morse_u_sequence        ; 0x1E8
        GOTO      finish_character_space  ; 0x1E9

send_morse_v:
        CALL      morse_s_sequence        ; 0x1EA
        CALL      morse_t_sequence        ; 0x1EB
        GOTO      finish_character_space  ; 0x1EC

send_morse_w:
        CALL      morse_w_sequence        ; 0x1ED
        GOTO      finish_character_space  ; 0x1EE

send_morse_x:
        CALL      morse_d_sequence        ; 0x1EF
        CALL      morse_t_sequence        ; 0x1F0
        GOTO      finish_character_space  ; 0x1F1

send_morse_y:
        CALL      morse_k_sequence        ; 0x1F2
        CALL      morse_t_sequence        ; 0x1F3
        GOTO      finish_character_space  ; 0x1F4

send_morse_z:
        CALL      morse_g_sequence        ; 0x1F5
        CALL      morse_e_sequence        ; 0x1F6
        GOTO      finish_character_space  ; 0x1F7

message_moe:
        MOVLW     0x71                     ; 0x1F8
        MOVWF     morse_unit_ticks         ; 0x1F9
        MOVLW     0x83                     ; 0x1FA
        MOVWF     tone_state               ; 0x1FB
        CALL      send_three_space_units   ; 0x1FC
        CALL      send_morse_m             ; 0x1FD
        CALL      send_morse_o             ; 0x1FE
        CALL      send_hex_e               ; 0x1FF
        RETURN                             ; 0x200

message_moi:
        MOVLW     0x69                     ; 0x201
        MOVWF     morse_unit_ticks         ; 0x202
        MOVLW     0x83                     ; 0x203
        MOVWF     tone_state               ; 0x204
        CALL      send_three_space_units   ; 0x205
        CALL      send_morse_m             ; 0x206
        CALL      send_morse_o             ; 0x207
        CALL      send_morse_i             ; 0x208
        RETURN                             ; 0x209

message_mos:
        MOVLW     0x63                     ; 0x20A
        MOVWF     morse_unit_ticks         ; 0x20B
        MOVLW     0x83                     ; 0x20C
        MOVWF     tone_state               ; 0x20D
        CALL      send_three_space_units   ; 0x20E
        CALL      send_morse_m             ; 0x20F
        CALL      send_morse_o             ; 0x210
        CALL      send_morse_s             ; 0x211
        RETURN                             ; 0x212

message_moh:
        MOVLW     0x5E                     ; 0x213
        MOVWF     morse_unit_ticks         ; 0x214
        MOVLW     0x83                     ; 0x215
        MOVWF     tone_state               ; 0x216
        CALL      send_three_space_units   ; 0x217
        CALL      send_morse_m             ; 0x218
        CALL      send_morse_o             ; 0x219
        CALL      send_morse_h             ; 0x21A
        RETURN                             ; 0x21B

message_mo5:
        MOVLW     0x59                     ; 0x21C
        MOVWF     morse_unit_ticks         ; 0x21D
        MOVLW     0x83                     ; 0x21E
        MOVWF     tone_state               ; 0x21F
        CALL      send_three_space_units   ; 0x220
        CALL      send_morse_m             ; 0x221
        CALL      send_morse_o             ; 0x222
        CALL      send_hex_5               ; 0x223
        RETURN                             ; 0x224

message_mo:
        MOVLW     0x81                     ; 0x225
        MOVWF     morse_unit_ticks         ; 0x226
        MOVLW     0x83                     ; 0x227
        MOVWF     tone_state               ; 0x228
        CALL      send_three_space_units   ; 0x229
        CALL      send_morse_m             ; 0x22A
        CALL      send_morse_o             ; 0x22B
        RETURN                             ; 0x22C

message_a:
        MOVLW     0x74                     ; 0x22D
        MOVWF     morse_unit_ticks         ; 0x22E
        MOVLW     0x80                     ; 0x22F
        MOVWF     tone_state               ; 0x230
        CALL      finish_character_space   ; 0x231
        CALL      send_hex_a               ; 0x232
        CALL      finish_character_space   ; 0x233
        CALL      send_hex_a               ; 0x234
        CALL      finish_character_space   ; 0x235
        CALL      send_hex_a               ; 0x236
        RETURN                             ; 0x237

message_b:
        MOVLW     0x74                     ; 0x238
        MOVWF     morse_unit_ticks         ; 0x239
        MOVLW     0x81                     ; 0x23A
        MOVWF     tone_state               ; 0x23B
        CALL      send_three_space_units   ; 0x23C
        CALL      send_hex_b               ; 0x23D
        CALL      send_three_space_units   ; 0x23E
        CALL      send_hex_b               ; 0x23F
        RETURN                             ; 0x240

message_f:
        MOVLW     0x74                     ; 0x241
        MOVWF     morse_unit_ticks         ; 0x242
        MOVLW     0x82                     ; 0x243
        MOVWF     tone_state               ; 0x244
        CALL      send_three_space_units   ; 0x245
        CALL      send_hex_f               ; 0x246
        CALL      send_three_space_units   ; 0x247
        CALL      send_hex_f               ; 0x248
        RETURN                             ; 0x249

message_l:
        MOVLW     0x74                     ; 0x24A
        MOVWF     morse_unit_ticks         ; 0x24B
        MOVLW     0x84                     ; 0x24C
        MOVWF     tone_state               ; 0x24D
        CALL      send_three_space_units   ; 0x24E
        CALL      send_morse_l             ; 0x24F
        CALL      send_three_space_units   ; 0x250
        CALL      send_morse_l             ; 0x251
        RETURN                             ; 0x252

message_n:
        MOVLW     0x74                     ; 0x253
        MOVWF     morse_unit_ticks         ; 0x254
        MOVLW     0x85                     ; 0x255
        MOVWF     tone_state               ; 0x256
        CALL      finish_character_space   ; 0x257
        CALL      send_morse_n             ; 0x258
        CALL      finish_character_space   ; 0x259
        CALL      send_morse_n             ; 0x25A
        CALL      finish_character_space   ; 0x25B
        CALL      send_morse_n             ; 0x25C
        RETURN                             ; 0x25D

message_p:
        MOVLW     0x66                     ; 0x25E
        MOVWF     morse_unit_ticks         ; 0x25F
        MOVLW     0x86                     ; 0x260
        MOVWF     tone_state               ; 0x261
        CALL      send_three_space_units   ; 0x262
        CALL      send_morse_p             ; 0x263
        CALL      send_three_space_units   ; 0x264
        CALL      send_morse_p             ; 0x265
        RETURN                             ; 0x266

message_v:
        MOVLW     0x74                     ; 0x267
        MOVWF     morse_unit_ticks         ; 0x268
        MOVLW     0x87                     ; 0x269
        MOVWF     tone_state               ; 0x26A
        CALL      send_three_space_units   ; 0x26B
        CALL      send_morse_v             ; 0x26C
        CALL      send_three_space_units   ; 0x26D
        CALL      send_morse_v             ; 0x26E
        RETURN                             ; 0x26F

message_x:
        MOVLW     0x66                     ; 0x270
        MOVWF     morse_unit_ticks         ; 0x271
        MOVLW     0x80                     ; 0x272
        MOVWF     tone_state               ; 0x273
        CALL      send_three_space_units   ; 0x274
        CALL      send_morse_x             ; 0x275
        CALL      send_three_space_units   ; 0x276
        CALL      send_morse_x             ; 0x277
        RETURN                             ; 0x278

message_z:
        MOVLW     0x66                     ; 0x279
        MOVWF     morse_unit_ticks         ; 0x27A
        MOVLW     0x81                     ; 0x27B
        MOVWF     tone_state               ; 0x27C
        CALL      send_three_space_units   ; 0x27D
        CALL      send_morse_z             ; 0x27E
        CALL      send_three_space_units   ; 0x27F
        CALL      send_morse_z             ; 0x280
        RETURN                             ; 0x281

message_fox:
        MOVLW     0x52                     ; 0x282
        MOVWF     morse_unit_ticks         ; 0x283
        MOVLW     0x83                     ; 0x284
        MOVWF     tone_state               ; 0x285
        CALL      send_three_space_units   ; 0x286
        CALL      send_hex_f               ; 0x287
        CALL      send_morse_o             ; 0x288
        CALL      send_morse_x             ; 0x289
        RETURN                             ; 0x28A
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

; Send the low nibble of W as a hexadecimal Morse character. Every table entry
; occupies three words so 3*n can index it directly; NOP pads short A/D/E forms.
hex_digit_dispatch:
        ANDLW     0x0F                ; 0x300
        MOVWF     hex_digit_index     ; 0x301
        ADDWF     hex_digit_index, W  ; 0x302: 2*n
        ADDWF     hex_digit_index, W  ; 0x303: 3*n
        ADDWF     PCL, F              ; 0x304
send_hex_0:
        CALL      morse_o_sequence    ; 0x305: ---
        CALL      morse_m_sequence    ; 0x306: --
        GOTO      finish_character_space ; 0x307
send_hex_1:
        CALL      morse_w_sequence    ; 0x308: .--
        CALL      morse_m_sequence    ; 0x309: --
        GOTO      finish_character_space ; 0x30A
send_hex_2:
        CALL      morse_u_sequence    ; 0x30B: ..-
        CALL      morse_m_sequence    ; 0x30C: --
        GOTO      finish_character_space ; 0x30D
send_hex_3:
        CALL      morse_s_sequence    ; 0x30E: ...
        CALL      morse_m_sequence    ; 0x30F: --
        GOTO      finish_character_space ; 0x310
send_hex_4:
        CALL      morse_s_sequence    ; 0x311: ...
        CALL      morse_u_tail        ; 0x312: .-
        GOTO      finish_character_space ; 0x313
send_hex_5:
        CALL      morse_s_sequence    ; 0x314: ...
        CALL      morse_i_sequence    ; 0x315: ..
        GOTO      finish_character_space ; 0x316
send_hex_6:
        CALL      morse_d_sequence    ; 0x317: -..
        CALL      morse_i_sequence    ; 0x318: ..
        GOTO      finish_character_space ; 0x319
send_hex_7:
        CALL      morse_g_sequence    ; 0x31A: --.
        CALL      morse_i_sequence    ; 0x31B: ..
        GOTO      finish_character_space ; 0x31C
send_hex_8:
        CALL      morse_o_sequence    ; 0x31D: ---
        CALL      morse_i_sequence    ; 0x31E: ..
        GOTO      finish_character_space ; 0x31F
send_hex_9:
        CALL      morse_o_sequence    ; 0x320: ---
        CALL      morse_n_sequence    ; 0x321: -.
        GOTO      finish_character_space ; 0x322
send_hex_a:
        CALL      morse_u_tail        ; 0x323: .-
        GOTO      finish_character_space ; 0x324
        NOP                             ; 0x325: table padding
send_hex_b:
        CALL      morse_d_sequence    ; 0x326: -..
        CALL      morse_e_sequence    ; 0x327: .
        GOTO      finish_character_space ; 0x328
send_hex_c:
        CALL      morse_n_sequence    ; 0x329: -.
        CALL      morse_n_sequence    ; 0x32A: -.
        GOTO      finish_character_space ; 0x32B
send_hex_d:
        CALL      morse_d_sequence    ; 0x32C: -..
        GOTO      finish_character_space ; 0x32D
        NOP                             ; 0x32E: table padding
send_hex_e:
        CALL      morse_e_sequence    ; 0x32F: .
        GOTO      finish_character_space ; 0x330
        NOP                             ; 0x331: table padding
send_hex_f:
        CALL      morse_u_sequence    ; 0x332: ..-
        CALL      morse_e_sequence    ; 0x333: .
        GOTO      finish_character_space ; 0x334

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
        GOTO      message_f           ; 0x34E: S1=8
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
        ADDWF     PCL, F                   ; 0x367
        RETLW     0xFF                     ; 0x368
        RETLW     0x3B                     ; 0x369
        RETLW     0x8D                     ; 0x36A
        RETLW     0x43                     ; 0x36B
        RETLW     0xA0                     ; 0x36C
        RETLW     0x34                     ; 0x36D
        RETLW     0xDA                     ; 0x36E
        RETLW     0x0E                     ; 0x36F
        RETLW     0xA9                     ; 0x370
        RETLW     0x63                     ; 0x371
        RETLW     0x95                     ; 0x372
        RETLW     0x11                     ; 0x373
        RETLW     0xEE                     ; 0x374
        RETLW     0x2A                     ; 0x375
        RETLW     0x88                     ; 0x376
        RETLW     0x56                     ; 0x377
        RETLW     0xB1                     ; 0x378
        RETLW     0x25                     ; 0x379
        RETLW     0xCB                     ; 0x37A
        RETLW     0x0B                     ; 0x37B
        RETLW     0xBC                     ; 0x37C
        RETLW     0x72                     ; 0x37D
        RETLW     0x84                     ; 0x37E
        RETLW     0x00                     ; 0x37F
        RETLW     0xEB                     ; 0x380
        RETLW     0x3F                     ; 0x381
        RETLW     0x99                     ; 0x382
        RETLW     0x47                     ; 0x383
        RETLW     0xA0                     ; 0x384
        RETLW     0x20                     ; 0x385
        RETLW     0xDE                     ; 0x386
        RETLW     0x1A                     ; 0x387
        RETLW     0xAD                     ; 0x388
        RETLW     0x63                     ; 0x389
        RETLW     0x81                     ; 0x38A
        RETLW     0x15                     ; 0x38B
        RETLW     0xFA                     ; 0x38C
        RETLW     0x2E                     ; 0x38D
        RETLW     0x88                     ; 0x38E
        RETLW     0x42                     ; 0x38F
        RETLW     0xB5                     ; 0x390
        RETLW     0x31                     ; 0x391
        RETLW     0xCF                     ; 0x392
        RETLW     0x0B                     ; 0x393
        RETLW     0xA8                     ; 0x394
        RETLW     0x76                     ; 0x395
        RETLW     0x90                     ; 0x396
        RETLW     0x04                     ; 0x397
        RETLW     0xEB                     ; 0x398
        RETLW     0x2B                     ; 0x399
        RETLW     0x9D                     ; 0x39A
        RETLW     0x53                     ; 0x39B
        RETLW     0xA4                     ; 0x39C
        RETLW     0x20                     ; 0x39D
        RETLW     0xCA                     ; 0x39E
        RETLW     0x1E                     ; 0x39F
        RETLW     0xB9                     ; 0x3A0
        RETLW     0x67                     ; 0x3A1
        RETLW     0x81                     ; 0x3A2
        RETLW     0x01                     ; 0x3A3
        RETLW     0xFE                     ; 0x3A4
        RETLW     0x3A                     ; 0x3A5
        RETLW     0x8C                     ; 0x3A6
        RETLW     0x42                     ; 0x3A7
        RETLW     0xA1                     ; 0x3A8
        RETLW     0x35                     ; 0x3A9
        RETLW     0xDB                     ; 0x3AA
        RETLW     0x0F                     ; 0x3AB
        RETLW     0xA8                     ; 0x3AC
        RETLW     0x62                     ; 0x3AD
        RETLW     0x94                     ; 0x3AE
        RETLW     0x10                     ; 0x3AF
        RETLW     0xEF                     ; 0x3B0
        RETLW     0x2B                     ; 0x3B1
        RETLW     0x89                     ; 0x3B2
        RETLW     0x57                     ; 0x3B3
        RETLW     0xB0                     ; 0x3B4
        RETLW     0x24                     ; 0x3B5
        RETLW     0xCA                     ; 0x3B6
        RETLW     0x0A                     ; 0x3B7
        RETLW     0xBD                     ; 0x3B8
        RETLW     0x73                     ; 0x3B9
        RETLW     0x85                     ; 0x3BA
        RETLW     0x01                     ; 0x3BB
        RETLW     0xEA                     ; 0x3BC
        RETLW     0x3E                     ; 0x3BD
        RETLW     0x98                     ; 0x3BE
        RETLW     0x46                     ; 0x3BF
        RETLW     0xA1                     ; 0x3C0
        RETLW     0x21                     ; 0x3C1
        RETLW     0xDF                     ; 0x3C2
        RETLW     0x1B                     ; 0x3C3
        RETLW     0xAC                     ; 0x3C4
        RETLW     0x62                     ; 0x3C5
        RETLW     0x80                     ; 0x3C6
        RETLW     0x14                     ; 0x3C7
        RETLW     0xFB                     ; 0x3C8
        RETLW     0x2F                     ; 0x3C9
        RETLW     0x89                     ; 0x3CA
        RETLW     0x43                     ; 0x3CB
        RETLW     0xB4                     ; 0x3CC
        RETLW     0x30                     ; 0x3CD
        RETLW     0xCE                     ; 0x3CE
        RETLW     0x0A                     ; 0x3CF
        RETLW     0xA9                     ; 0x3D0
        RETLW     0x77                     ; 0x3D1
        RETLW     0x91                     ; 0x3D2
        RETLW     0x05                     ; 0x3D3
        RETLW     0xEA                     ; 0x3D4
        RETLW     0x2A                     ; 0x3D5
        RETLW     0x9C                     ; 0x3D6
        RETLW     0x52                     ; 0x3D7
        RETLW     0xA5                     ; 0x3D8
        RETLW     0x21                     ; 0x3D9
        RETLW     0xCB                     ; 0x3DA
        RETLW     0x1F                     ; 0x3DB
        RETLW     0xB8                     ; 0x3DC
        RETLW     0x66                     ; 0x3DD
        RETLW     0x80                     ; 0x3DE
        RETLW     0x00                     ; 0x3DF
        RETLW     0xA1                     ; 0x3E0
        RETLW     0x21                     ; 0x3E1
        RETLW     0xDF                     ; 0x3E2
        RETLW     0x1B                     ; 0x3E3
        RETLW     0xAC                     ; 0x3E4
        RETLW     0x62                     ; 0x3E5
        RETLW     0x80                     ; 0x3E6
        RETLW     0x14                     ; 0x3E7
        RETLW     0xFB                     ; 0x3E8
        RETLW     0x2F                     ; 0x3E9
        RETLW     0x89                     ; 0x3EA
        RETLW     0x43                     ; 0x3EB
        RETLW     0xB4                     ; 0x3EC
        RETLW     0x30                     ; 0x3ED
        RETLW     0xCE                     ; 0x3EE
        RETLW     0x0A                     ; 0x3EF
        RETLW     0xA9                     ; 0x3F0
        RETLW     0x77                     ; 0x3F1
        RETLW     0x91                     ; 0x3F2
        RETLW     0x05                     ; 0x3F3
        RETLW     0xEA                     ; 0x3F4
        RETLW     0x2A                     ; 0x3F5
        RETLW     0x9C                     ; 0x3F6
        RETLW     0x52                     ; 0x3F7
        RETLW     0xA5                     ; 0x3F8
        RETLW     0x21                     ; 0x3F9
        RETLW     0xCB                     ; 0x3FA
        RETLW     0x1F                     ; 0x3FB
        RETLW     0xB8                     ; 0x3FC
        RETLW     0x66                     ; 0x3FD
        RETLW     0x80                     ; 0x3FE
        RETLW     0x00                     ; 0x3FF

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
