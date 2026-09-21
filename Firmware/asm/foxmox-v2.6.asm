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
seconds_mod64   EQU       0x10
tmr0_wait_count EQU       0x11
message_seconds EQU       0x12
phase_counter_hi EQU      0x13
phase_counter_lo EQU      0x14
callsign_cooldown_hi EQU  0x15
callsign_cooldown_lo EQU  0x16
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
tone_pattern    EQU       0x29
message_index   EQU       0x2B
timing_record_addr EQU    0x2C
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
        GOTO      startup
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)

interrupt_vector:
        GOTO      tmr0_isr

tmr0_isr:
        MOVWF     isr_w_save
        MOVF      STATUS, W
        MOVWF     isr_status_save
        BCF       INTCON, T0IF
        BCF       STATUS, RP0 ; bank 0
        MOVF      porta_shadow, W
        MOVWF     PORTA

        DECFSZ    second_div_lo, F
        GOTO      isr_tone_update
        DECFSZ    second_div_hi, F
        GOTO      isr_tone_update
        MOVLW     0xA6
        MOVWF     second_div_lo
        MOVLW     0x0E
        MOVWF     second_div_hi

        MOVF      message_seconds, F
        BTFSS     STATUS, Z
        DECF      message_seconds, F

        MOVF      phase_counter_hi, F
        BTFSS     STATUS, Z
        GOTO      isr_decrement_phase
        MOVF      phase_counter_lo, F
        BTFSC     STATUS, Z
        GOTO      isr_update_cooldown
isr_decrement_phase:
        MOVLW     0x01
        SUBWF     phase_counter_lo, F
        MOVLW     0x00
        BTFSS     STATUS, C ; borrow from high byte
        MOVLW     0x01
        SUBWF     phase_counter_hi, F

isr_update_cooldown:
        MOVF      callsign_cooldown_hi, F
        BTFSS     STATUS, Z
        GOTO      isr_decrement_cooldown
        MOVF      callsign_cooldown_lo, F
        BTFSC     STATUS, Z
        GOTO      isr_second_epoch_update
isr_decrement_cooldown:
        MOVLW     0x01
        SUBWF     callsign_cooldown_lo, F
        MOVLW     0x00
        BTFSS     STATUS, C
        MOVLW     0x01
        SUBWF     callsign_cooldown_hi, F

isr_second_epoch_update:
        INCF      seconds_mod64, F
        MOVF      seconds_mod64, W
        ANDLW     0x3F
        BTFSS     STATUS, Z
        GOTO      isr_tone_update
        BSF       interrupt_flag, 1 ; 64-second epoch marker
        MOVF      timing_trim, W
        ADDWF     second_div_lo, F ; lengthen one interval per epoch
        BTFSC     STATUS, C
        INCF      second_div_hi, F

isr_tone_update:
        INCF      tone_phase, F
        MOVLW     0x88
        ADDWF     tone_phase, W ; carry when phase reaches 0x78
        BTFSC     STATUS, C
        CLRF      tone_phase ; 120-entry waveform period
        BCF       porta_shadow, 0
        BTFSC     tone_state, 7 ; silence suppresses waveform
        GOTO      isr_aux_output
        MOVF      tone_phase, W
        CALL      tone_pattern_lookup
        MOVWF     tone_pattern
        CALL      bit_mask_lookup
        ANDWF     tone_pattern, F
        BTFSC     STATUS, Z
        BSF       porta_shadow, 0

isr_aux_output:
        BCF       porta_shadow, 2
        BTFSS     tone_state, 7
        BSF       porta_shadow, 2
        BTFSS     tone_phase, 0
        GOTO      isr_signal_event
        BTFSS     tone_phase, 1
        GOTO      isr_signal_event
        MOVF      tmr0_wait_count, F
        BTFSS     STATUS, Z
        DECF      tmr0_wait_count, F ; every fourth overflow

isr_signal_event:
        BSF       interrupt_flag, 0
        MOVF      isr_status_save, W
        MOVWF     STATUS
        SWAPF     isr_w_save, F
        SWAPF     isr_w_save, W
        RETFIE

startup:
        CLRF      INTCON ; interrupts off
        BCF       STATUS, RP0 ; bank 0
        MOVLW     0x08 ; RA3 latch high for service strap
        MOVWF     PORTA
        MOVLW     0x00
        MOVWF     PORTB
        BSF       STATUS, RP0 ; bank 1
        MOVLW     0x08
        MOVWF     OPTION_REG_FILE ; TMR0 from Fosc/4, no prescaler
        MOVLW     0xE4
        MOVWF     TRISA_FILE ; RA3 output, RA2 input
        MOVLW     0x00
        MOVWF     TRISB_FILE
        BCF       STATUS, RP0 ; bank 0
        MOVLW     0x03
        MOVWF     PCLATH ; computed tables live at 0x300

        MOVLW     0x0C
        MOVWF     FSR
clear_ram:
        CLRF      INDF ; clear RAM 0x0C..0x3F
        INCF      FSR, F
        BTFSS     FSR, 6
        GOTO      clear_ram

        MOVLW     0xA6
        MOVWF     second_div_lo
        MOVLW     0x0E
        MOVWF     second_div_hi
        MOVLW     0x83
        MOVWF     tone_state
        MOVLW     0x46
        MOVWF     morse_unit_ticks
        MOVLW     0x28
        CALL      eeprom_read
        MOVWF     timing_trim
        BTFSS     PORTA, 2 ; low selects calibration mode
        GOTO      service_mode

        CLRF      TMR0
        BSF       INTCON, T0IE
        BSF       INTCON, GIE
        BSF       STATUS, RP0 ; bank 1
        MOVLW     0xE8
        MOVWF     TRISA_FILE ; RA2 output, RA3 input
        CALL      read_switches ; returns in bank 0
        MOVLW     0x0F
        ANDWF     switch_state, W ; isolate S1
        MOVWF     message_index
        CALL      lfsr_seed_lookup
        MOVWF     lfsr_state

        BSF       porta_shadow, 1 ; assert PTT
        MOVLW     0x04
        MOVWF     message_seconds
        CALL      send_three_space_units
        CALL      message_dispatch
startup_wait_message:
        MOVF      message_seconds, F
        BTFSS     STATUS, Z
        GOTO      startup_wait_message
        BCF       porta_shadow, 1 ; release PTT

; Select one of four startup-delay records. The compact carry tests classify
; S1/S2 combinations into record numbers 0..3; doubling and adding 0x20 maps
; them to EEPROM pairs 0x20, 0x22, 0x24, or 0x26 (0/30/60/120 minutes).
select_startup_delay:
        CLRF      timing_record_addr
        SWAPF     switch_state, W
        ADDLW     0xB0
        BTFSS     STATUS, C
        GOTO      startup_delay_low_s2
        MOVF      switch_state, W
        ADDLW     0x80
        BTFSC     STATUS, C
        GOTO      startup_delay_inc_2
        GOTO      startup_delay_scale
startup_delay_low_s2:
        MOVF      switch_state, W
        ADDLW     0x10
        BTFSC     STATUS, C
        GOTO      startup_delay_inc_1
        ADDLW     0x60
        BTFSC     STATUS, C
        GOTO      startup_delay_inc_2
        ADDLW     0x20
        BTFSC     STATUS, C
        GOTO      startup_delay_inc_3
        GOTO      startup_delay_scale
startup_delay_inc_1:
        INCF      timing_record_addr, F
startup_delay_inc_2:
        INCF      timing_record_addr, F
startup_delay_inc_3:
        INCF      timing_record_addr, F
startup_delay_scale:
        MOVF      timing_record_addr, W
        ADDWF     timing_record_addr, F ; pair offset = 2*n
        CALL      wait_for_tmr0_interrupt ; align counter load
        MOVLW     0x20
        ADDWF     timing_record_addr, F ; startup table base
        MOVF      timing_record_addr, W
        CALL      eeprom_read
        MOVWF     phase_counter_hi
        INCF      timing_record_addr, W
        CALL      eeprom_read
        MOVWF     phase_counter_lo
wait_startup_delay:
        MOVF      phase_counter_hi, F
        BTFSS     STATUS, Z
        GOTO      wait_startup_delay
        MOVF      phase_counter_lo, F
        BTFSS     STATUS, Z
        GOTO      wait_startup_delay
wait_phase_counter_zero:
        CALL      wait_for_tmr0_interrupt
        MOVF      phase_counter_hi, F
        BTFSS     STATUS, Z
        GOTO      wait_phase_counter_zero
        MOVF      phase_counter_lo, F
        BTFSS     STATUS, Z
        GOTO      wait_phase_counter_zero

; Select the repeating timing pair. S1 0..4 uses EEPROM 0x00..0x0F; S1 5..F
; uses 0x10..0x1F. S2 bits 2:0 choose one of eight two-byte records.
load_timing_profile:
        CALL      read_switches
        CLRF      timing_record_addr
        SWAPF     switch_state, W
        ADDLW     0xB0 ; carry iff S1 >= 5
        CLRW ; preserves carry on this core
        BTFSC     STATUS, C
        MOVLW     0x10
        ADDWF     timing_record_addr, F ; select timing table half
        SWAPF     switch_state, W
        MOVWF     service_delay_lo ; scratch register
        RLF       service_delay_lo, W
        ANDLW     0x0E ; 2*(S2 & 7)
        ADDWF     timing_record_addr, F
        MOVLW     0x00 ; preserved no-op from original
        ADDWF     timing_record_addr, F
        MOVF      timing_record_addr, W
        CALL      eeprom_read ; first byte = transmit seconds
        MOVWF     phase_counter_lo

transmit_message:
        MOVLW     0x04
        MOVWF     message_seconds
        CALL      message_dispatch
transmit_phase_loop:
        CALL      wait_for_tmr0_interrupt
        MOVF      phase_counter_hi, F
        BTFSS     STATUS, Z
        GOTO      check_message_interval
        MOVF      phase_counter_lo, W
        BTFSC     STATUS, Z
        GOTO      begin_silent_phase
        XORLW     0x04
        BTFSC     STATUS, Z
        GOTO      maybe_send_callsign
check_message_interval:
        MOVF      message_seconds, F
        BTFSS     STATUS, Z
        GOTO      transmit_phase_loop
        GOTO      transmit_message

maybe_send_callsign:
        MOVF      callsign_cooldown_hi, F
        BTFSS     STATUS, Z
        GOTO      transmit_message
        MOVF      callsign_cooldown_lo, F
        BTFSS     STATUS, Z
        GOTO      transmit_message
        MOVLW     0x04
        MOVWF     message_seconds
        MOVLW     0x02
        MOVWF     callsign_cooldown_hi
        MOVLW     0x58 ; cooldown = 0x0258 = 600 s
        MOVWF     callsign_cooldown_lo
        CALL      send_callsign_n0puf
        GOTO      transmit_phase_loop

begin_silent_phase:
        INCF      timing_record_addr, W
        CALL      eeprom_read ; second byte = silent seconds
        MOVWF     phase_counter_lo
        MOVF      phase_counter_lo, F
        BTFSC     STATUS, Z
        GOTO      wait_phase_counter_zero
        BCF       porta_shadow, 1 ; release PTT
        BSF       tone_state, 7 ; suppress tone waveform

; Non-fox S2 modes C/D/E optionally add 0..31 seconds of LFSR jitter to the
; silent phase. Other modes proceed directly to the common phase wait.
maybe_add_silent_jitter:
        SWAPF     switch_state, W
        ADDLW     0xB0
        BTFSS     STATUS, C
        GOTO      wait_phase_counter_zero
        MOVF      switch_state, W
        ADDLW     0x90
        ANDLW     0x70
        ADDLW     0xB0
        BTFSS     STATUS, C
        GOTO      wait_phase_counter_zero
        CALL      wait_for_tmr0_interrupt
        MOVLW     0x1F
        ANDWF     lfsr_state, W
        ADDWF     phase_counter_lo, F
        CALL      advance_lfsr_3
        GOTO      wait_phase_counter_zero

send_callsign_n0puf:
        MOVLW     0x31 ; faster Morse timing
        MOVWF     morse_unit_ticks
        CALL      send_character_space
        CALL      send_morse_n
        CALL      send_morse_0
        CALL      send_morse_p
        CALL      send_morse_u
        CALL      send_morse_f
        RETURN

; Wait for the next TMR0 interrupt. The ISR sets interrupt_flag bit 0 on every
; overflow; clearing it first prevents a stale event from satisfying the wait.
wait_for_tmr0_interrupt:
        BCF       interrupt_flag, 0
wait_for_tmr0_interrupt_loop:
        BTFSS     interrupt_flag, 0
        GOTO      wait_for_tmr0_interrupt_loop
        RETURN

; Read the EEPROM byte whose address arrives in W and return its value in W.
; RP0 transitions are kept explicit because EEADR/EEDATA and EECON1 share file
; addresses across banks on the PIC16F84A.
eeprom_read:
        BCF       STATUS, RP0 ; bank 0
        MOVWF     EEADR
        BSF       STATUS, RP0 ; bank 1
        BSF       EECON1_FILE, RD ; initiate read
        BCF       STATUS, RP0 ; bank 0
        MOVF      EEDATA, W
        RETURN

; Write the byte in W to the EEPROM address already loaded into EEADR. This is
; the standard PIC16F84A unlock sequence. The recovered code restores GIE
; unconditionally after starting the write, then polls EEIF for completion.
eeprom_write:
        BCF       STATUS, RP0 ; bank 0
        MOVWF     EEDATA
        BSF       STATUS, RP0 ; bank 1
        BCF       INTCON, GIE ; protect unlock sequence
        BSF       EECON1_FILE, WREN
        MOVLW     0x55
        MOVWF     EECON2_FILE
        MOVLW     0xAA
        MOVWF     EECON2_FILE
        BSF       EECON1_FILE, WR ; begin write
        BSF       INTCON, GIE
wait_for_eeprom_write:
        BTFSS     EECON1_FILE, EEIF
        GOTO      wait_for_eeprom_write
        BCF       EECON1_FILE, EEIF
        BCF       EECON1_FILE, WREN
        BCF       STATUS, RP0 ; bank 0
        RETURN

; Advance the seven-bit pseudo-random state three times.
advance_lfsr_3:
        MOVLW     0x03
        MOVWF     lfsr_steps
advance_lfsr_3_loop:
        CALL      advance_lfsr_1
        DECFSZ    lfsr_steps, F
        GOTO      advance_lfsr_3_loop
        RETURN

; Advance the seven-bit LFSR in bits 6:0 of lfsr_state. Carry is loaded with
; bit0 XOR bit6, then rotated into bit0 while the old bit6 rotates into bit7.
advance_lfsr_1:
        BCF       STATUS, C ; default feedback = 0
        BTFSC     lfsr_state, 0
        GOTO      lfsr_bit0_set
        BTFSC     lfsr_state, 6 ; bit0=0 -> feedback=bit6
        BSF       STATUS, C
        GOTO      lfsr_rotate
lfsr_bit0_set:
        BTFSS     lfsr_state, 6 ; bit0=1 -> feedback=!bit6
        BSF       STATUS, C
lfsr_rotate:
        RLF       lfsr_state, F
        RETURN

; Read the two active-low hexadecimal switches on PORTB. The pins are inputs
; only for the sample; afterwards they return to outputs for the tone sequencer.
read_switches:
        BSF       STATUS, RP0 ; bank 1
        MOVLW     0xFF
        MOVWF     TRISB_FILE ; all PORTB pins inputs
        BCF       STATUS, RP0 ; bank 0
        COMF      PORTB, W ; sample and invert active-low bits
        MOVWF     switch_state ; S2 in high nibble, S1 in low
        BSF       STATUS, RP0 ; bank 1
        CLRF      TRISB_FILE ; restore PORTB outputs
        BCF       STATUS, RP0 ; bank 0
        RETURN

; Send W as two hexadecimal Morse digits, high nibble first, and preserve the
; original byte in W on return.
send_hex_byte:
        MOVWF     hex_byte
        SWAPF     hex_byte, W
        ANDLW     0x0F
        CALL      hex_digit_dispatch
        MOVF      hex_byte, W
        ANDLW     0x0F
        CALL      hex_digit_dispatch
        MOVF      hex_byte, W
        RETURN

; Calibration/service mode entered when RA2 is held low during startup.
service_mode:
service_wait_release_restart:
        CLRF      service_delay_lo
        MOVLW     0x7F
        MOVWF     service_delay_hi
service_wait_release:
        BTFSS     PORTA, 2 ; restart until RA2 is released
        GOTO      service_wait_release_restart
        DECFSZ    service_delay_lo, F
        GOTO      service_wait_release
        DECFSZ    service_delay_hi, F
        GOTO      service_wait_release

        BSF       STATUS, RP0 ; bank 1
        MOVLW     0xE8
        MOVWF     TRISA_FILE ; RA2 output, RA3 input
        BCF       STATUS, RP0 ; bank 0
        CALL      read_switches
        MOVF      switch_state, F
        BTFSC     STATUS, Z
        GOTO      halt_blink ; both switches zero

        BSF       porta_shadow, 1 ; assert PTT
        CLRF      TMR0
        BSF       INTCON, T0IE
        BSF       INTCON, GIE

service_announce:
        CLRF      service_delay_lo
        MOVLW     0x7F
        MOVWF     service_delay_hi
service_announce_delay:
        DECFSZ    service_delay_lo, F
        GOTO      service_announce_delay
        DECFSZ    service_delay_hi, F
        GOTO      service_announce_delay
        CALL      send_three_space_units
        MOVF      timing_trim, W
        CALL      send_hex_byte
        MOVLW     0x05
        MOVWF     message_seconds

service_poll_switch:
        CALL      read_switches
        MOVF      switch_state, W
        ANDLW     0xF0 ; inspect S2 only
        BTFSS     STATUS, Z
        GOTO      service_apply_switch
        MOVF      message_seconds, F
        BTFSS     STATUS, Z
        GOTO      service_apply_switch
        CALL      send_three_space_units
        MOVLW     0x28
        CALL      eeprom_read
        CALL      send_hex_byte
        GOTO      startup

service_apply_switch:
        BTFSS     switch_state, 7 ; S2 8-F decrements
        GOTO      service_test_increment
        DECF      timing_trim, F
        GOTO      service_save_trim
service_test_increment:
        BTFSS     switch_state, 4 ; odd S2 1,3,5,7 increments
        GOTO      service_poll_switch
        INCF      timing_trim, F
service_save_trim:
        MOVLW     0x28
        MOVWF     EEADR
        MOVF      timing_trim, W
        CALL      eeprom_write
        GOTO      service_announce

halt_blink:
        BSF       PORTA, 2
        BCF       INTCON, GIE
        NOP
        BCF       PORTA, 2
        GOTO      halt_blink

; Emit tone for one Morse time unit. W is preserved because these helpers are
; chained through nested letter routines. Clearing tone_state bit 7 enables the
; ISR's waveform path; the polarity is therefore opposite the old placeholder
; label inherited from the raw disassembly.
morse_tone_unit:
        MOVWF     saved_w
        MOVF      morse_unit_ticks, W
        MOVWF     tmr0_wait_count
        BCF       tone_state, 7 ; enable ISR tone waveform
morse_tone_wait:
        MOVF      tmr0_wait_count, F ; ISR decrements this counter
        BTFSS     STATUS, Z
        GOTO      morse_tone_wait
        MOVF      saved_w, W
        RETURN

; Emit silence for one Morse time unit, preserving W.
morse_silence_unit:
        MOVWF     saved_w
        MOVF      morse_unit_ticks, W
        MOVWF     tmr0_wait_count
        BSF       tone_state, 7 ; suppress ISR tone waveform
morse_silence_wait:
        MOVF      tmr0_wait_count, F
        BTFSS     STATUS, Z
        GOTO      morse_silence_wait
        MOVF      saved_w, W
        RETURN

morse_s_sequence:
        CALL      send_dot
        GOTO      morse_i_sequence

morse_d_sequence:
        CALL      send_dash

morse_i_sequence:
        CALL      send_dot

morse_e_sequence:
        CALL      send_dot
        RETURN

morse_w_sequence:
        CALL      send_dot
        GOTO      morse_m_sequence

morse_o_sequence:
        CALL      send_dash

morse_m_sequence:
        CALL      send_dash
morse_t_sequence:
        CALL      send_dash
        RETURN

morse_r_sequence:
        CALL      send_dot
        GOTO      morse_n_sequence

morse_g_sequence:
        CALL      send_dash

morse_n_sequence:
        CALL      send_dash
        CALL      send_dot
        RETURN

morse_u_sequence:
        CALL      send_dot
        GOTO      morse_u_tail

morse_k_sequence:
        CALL      send_dash
morse_u_tail:
        CALL      send_dot
        CALL      send_dash
        RETURN

; Element builders. A dot is one tone unit plus one silence unit; a dash is
; three tone units plus one silence unit.
send_dot:
        CALL      morse_tone_unit
        CALL      morse_silence_unit
        RETURN

send_dash:
        CALL      morse_tone_unit
        CALL      morse_tone_unit
        CALL      morse_tone_unit
        CALL      morse_silence_unit
        RETURN

send_character_space:
        CALL      morse_silence_unit
send_three_space_units:
        CALL      morse_silence_unit
finish_character_space:
        CALL      morse_silence_unit
        CALL      morse_silence_unit
        RETURN

send_morse_g:
        CALL      morse_g_sequence
        GOTO      finish_character_space

send_morse_h:
        CALL      morse_s_sequence
        CALL      morse_e_sequence
        GOTO      finish_character_space

send_morse_i:
        CALL      morse_i_sequence
        GOTO      finish_character_space

send_morse_j:
        CALL      morse_w_sequence
        CALL      morse_t_sequence
        GOTO      finish_character_space

send_morse_k:
        CALL      morse_k_sequence
        GOTO      finish_character_space

send_morse_l:
        CALL      morse_r_sequence
        CALL      morse_e_sequence
        GOTO      finish_character_space

send_morse_m:
        CALL      morse_m_sequence
        GOTO      finish_character_space

send_morse_n:
        CALL      morse_n_sequence
        GOTO      finish_character_space

send_morse_o:
        CALL      morse_o_sequence
        GOTO      finish_character_space

send_morse_p:
        CALL      morse_w_sequence
        CALL      morse_e_sequence
        GOTO      finish_character_space

send_morse_q:
        CALL      morse_g_sequence
        CALL      morse_t_sequence
        GOTO      finish_character_space

send_morse_r:
        CALL      morse_r_sequence
        GOTO      finish_character_space

send_morse_s:
        CALL      morse_s_sequence
        GOTO      finish_character_space

send_morse_t:
        CALL      morse_t_sequence
        GOTO      finish_character_space

send_morse_u:
        CALL      morse_u_sequence
        GOTO      finish_character_space

send_morse_v:
        CALL      morse_s_sequence
        CALL      morse_t_sequence
        GOTO      finish_character_space

send_morse_w:
        CALL      morse_w_sequence
        GOTO      finish_character_space

send_morse_x:
        CALL      morse_d_sequence
        CALL      morse_t_sequence
        GOTO      finish_character_space

send_morse_y:
        CALL      morse_k_sequence
        CALL      morse_t_sequence
        GOTO      finish_character_space

send_morse_z:
        CALL      morse_g_sequence
        CALL      morse_e_sequence
        GOTO      finish_character_space

message_moe:
        MOVLW     0x71
        MOVWF     morse_unit_ticks
        MOVLW     0x83
        MOVWF     tone_state
        CALL      send_three_space_units
        CALL      send_morse_m
        CALL      send_morse_o
        CALL      send_morse_e
        RETURN

message_moi:
        MOVLW     0x69
        MOVWF     morse_unit_ticks
        MOVLW     0x83
        MOVWF     tone_state
        CALL      send_three_space_units
        CALL      send_morse_m
        CALL      send_morse_o
        CALL      send_morse_i
        RETURN

message_mos:
        MOVLW     0x63
        MOVWF     morse_unit_ticks
        MOVLW     0x83
        MOVWF     tone_state
        CALL      send_three_space_units
        CALL      send_morse_m
        CALL      send_morse_o
        CALL      send_morse_s
        RETURN

message_moh:
        MOVLW     0x5E
        MOVWF     morse_unit_ticks
        MOVLW     0x83
        MOVWF     tone_state
        CALL      send_three_space_units
        CALL      send_morse_m
        CALL      send_morse_o
        CALL      send_morse_h
        RETURN

message_mo5:
        MOVLW     0x59
        MOVWF     morse_unit_ticks
        MOVLW     0x83
        MOVWF     tone_state
        CALL      send_three_space_units
        CALL      send_morse_m
        CALL      send_morse_o
        CALL      send_morse_5
        RETURN

message_mo:
        MOVLW     0x81
        MOVWF     morse_unit_ticks
        MOVLW     0x83
        MOVWF     tone_state
        CALL      send_three_space_units
        CALL      send_morse_m
        CALL      send_morse_o
        RETURN

message_a:
        MOVLW     0x74
        MOVWF     morse_unit_ticks
        MOVLW     0x80
        MOVWF     tone_state
        CALL      finish_character_space
        CALL      send_morse_a
        CALL      finish_character_space
        CALL      send_morse_a
        CALL      finish_character_space
        CALL      send_morse_a
        RETURN

message_b:
        MOVLW     0x74
        MOVWF     morse_unit_ticks
        MOVLW     0x81
        MOVWF     tone_state
        CALL      send_three_space_units
        CALL      send_morse_b
        CALL      send_three_space_units
        CALL      send_morse_b
        RETURN

message_f:
        MOVLW     0x74
        MOVWF     morse_unit_ticks
        MOVLW     0x82
        MOVWF     tone_state
        CALL      send_three_space_units
        CALL      send_morse_f
        CALL      send_three_space_units
        CALL      send_morse_f
        RETURN

message_l:
        MOVLW     0x74
        MOVWF     morse_unit_ticks
        MOVLW     0x84
        MOVWF     tone_state
        CALL      send_three_space_units
        CALL      send_morse_l
        CALL      send_three_space_units
        CALL      send_morse_l
        RETURN

message_n:
        MOVLW     0x74
        MOVWF     morse_unit_ticks
        MOVLW     0x85
        MOVWF     tone_state
        CALL      finish_character_space
        CALL      send_morse_n
        CALL      finish_character_space
        CALL      send_morse_n
        CALL      finish_character_space
        CALL      send_morse_n
        RETURN

message_p:
        MOVLW     0x66
        MOVWF     morse_unit_ticks
        MOVLW     0x86
        MOVWF     tone_state
        CALL      send_three_space_units
        CALL      send_morse_p
        CALL      send_three_space_units
        CALL      send_morse_p
        RETURN

message_v:
        MOVLW     0x74
        MOVWF     morse_unit_ticks
        MOVLW     0x87
        MOVWF     tone_state
        CALL      send_three_space_units
        CALL      send_morse_v
        CALL      send_three_space_units
        CALL      send_morse_v
        RETURN

message_x:
        MOVLW     0x66
        MOVWF     morse_unit_ticks
        MOVLW     0x80
        MOVWF     tone_state
        CALL      send_three_space_units
        CALL      send_morse_x
        CALL      send_three_space_units
        CALL      send_morse_x
        RETURN

message_z:
        MOVLW     0x66
        MOVWF     morse_unit_ticks
        MOVLW     0x81
        MOVWF     tone_state
        CALL      send_three_space_units
        CALL      send_morse_z
        CALL      send_three_space_units
        CALL      send_morse_z
        RETURN

message_fox:
        MOVLW     0x52
        MOVWF     morse_unit_ticks
        MOVLW     0x83
        MOVWF     tone_state
        CALL      send_three_space_units
        CALL      send_morse_f
        CALL      send_morse_o
        CALL      send_morse_x
        RETURN
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)
        DW        0x3FFF ; erased (instruction encoding: addlw 0xFF)

; Send the low nibble of W as a hexadecimal Morse character. Every table entry
; occupies three words so 3*n can index it directly; NOP pads short A/D/E forms.
hex_digit_dispatch:
        ANDLW     0x0F
        MOVWF     hex_digit_index
        ADDWF     hex_digit_index, W ; 2*n
        ADDWF     hex_digit_index, W ; 3*n
        ADDWF     PCL, F
send_morse_0:
        CALL      morse_o_sequence ; ---
        CALL      morse_m_sequence ; --
        GOTO      finish_character_space
send_morse_1:
        CALL      morse_w_sequence ; .--
        CALL      morse_m_sequence ; --
        GOTO      finish_character_space
send_morse_2:
        CALL      morse_u_sequence ; ..-
        CALL      morse_m_sequence ; --
        GOTO      finish_character_space
send_morse_3:
        CALL      morse_s_sequence ; ...
        CALL      morse_m_sequence ; --
        GOTO      finish_character_space
send_morse_4:
        CALL      morse_s_sequence ; ...
        CALL      morse_u_tail ; .-
        GOTO      finish_character_space
send_morse_5:
        CALL      morse_s_sequence ; ...
        CALL      morse_i_sequence ; ..
        GOTO      finish_character_space
send_morse_6:
        CALL      morse_d_sequence ; -..
        CALL      morse_i_sequence ; ..
        GOTO      finish_character_space
send_morse_7:
        CALL      morse_g_sequence ; --.
        CALL      morse_i_sequence ; ..
        GOTO      finish_character_space
send_morse_8:
        CALL      morse_o_sequence ; ---
        CALL      morse_i_sequence ; ..
        GOTO      finish_character_space
send_morse_9:
        CALL      morse_o_sequence ; ---
        CALL      morse_n_sequence ; -.
        GOTO      finish_character_space
send_morse_a:
        CALL      morse_u_tail ; .-
        GOTO      finish_character_space
        NOP ; table padding
send_morse_b:
        CALL      morse_d_sequence ; -..
        CALL      morse_e_sequence ; .
        GOTO      finish_character_space
send_morse_c:
        CALL      morse_n_sequence ; -.
        CALL      morse_n_sequence ; -.
        GOTO      finish_character_space
send_morse_d:
        CALL      morse_d_sequence ; -..
        GOTO      finish_character_space
        NOP ; table padding
send_morse_e:
        CALL      morse_e_sequence ; .
        GOTO      finish_character_space
        NOP ; table padding
send_morse_f:
        CALL      morse_u_sequence ; ..-
        CALL      morse_e_sequence ; .
        GOTO      finish_character_space

; Convert tone_state bits 2:0 into the corresponding PORTB bit mask.
bit_mask_lookup:
        MOVF      tone_state, W
        ANDLW     0x07
        ADDWF     PCL, F
        RETLW     0x10
        RETLW     0x40
        RETLW     0x01
        RETLW     0x20
        RETLW     0x08
        RETLW     0x02
        RETLW     0x80
        RETLW     0x04

; Key the transmitter, resample S1, and tail-dispatch its low nibble to one of
; the sixteen message routines. PCLATH was initialized to page 3 at startup.
message_dispatch:
        BSF       porta_shadow, 1 ; assert PTT through RA1
        CALL      read_switches
        MOVF      switch_state, W
        ANDLW     0x0F ; S1 only
        MOVWF     message_index
        ADDWF     PCL, F
        GOTO      message_moe ; S1=0
        GOTO      message_moi ; S1=1
        GOTO      message_mos ; S1=2
        GOTO      message_moh ; S1=3
        GOTO      message_mo5 ; S1=4
        GOTO      message_mo ; S1=5
        GOTO      message_a ; S1=6
        GOTO      message_b ; S1=7
        GOTO      message_f ; S1=8
        GOTO      message_l ; S1=9
        GOTO      message_n ; S1=A
        GOTO      message_p ; S1=B
        GOTO      message_v ; S1=C
        GOTO      message_x ; S1=D
        GOTO      message_z ; S1=E
        GOTO      message_fox ; S1=F

; Map the low-nibble switch index in W to a nonzero pseudo-random seed.
; Callers prove W is in the range 0..15 and PCLATH selects this code page.
lfsr_seed_lookup:
        ADDWF     PCL, F
        RETLW     0xFE ; S1=0
        RETLW     0xCE ; S1=1
        RETLW     0x5B ; S1=2
        RETLW     0x34 ; S1=3
        RETLW     0x4F ; S1=4
        RETLW     0x40 ; S1=5
        RETLW     0x54 ; S1=6
        RETLW     0x70 ; S1=7
        RETLW     0x7B ; S1=8
        RETLW     0x30 ; S1=9
        RETLW     0xE9 ; S1=A
        RETLW     0xBE ; S1=B
        RETLW     0x14 ; S1=C
        RETLW     0x63 ; S1=D
        RETLW     0x57 ; S1=E
        RETLW     0x24 ; S1=F

tone_pattern_lookup:
        ADDWF     PCL, F
        RETLW     0xFF
        RETLW     0x3B
        RETLW     0x8D
        RETLW     0x43
        RETLW     0xA0
        RETLW     0x34
        RETLW     0xDA
        RETLW     0x0E
        RETLW     0xA9
        RETLW     0x63
        RETLW     0x95
        RETLW     0x11
        RETLW     0xEE
        RETLW     0x2A
        RETLW     0x88
        RETLW     0x56
        RETLW     0xB1
        RETLW     0x25
        RETLW     0xCB
        RETLW     0x0B
        RETLW     0xBC
        RETLW     0x72
        RETLW     0x84
        RETLW     0x00
        RETLW     0xEB
        RETLW     0x3F
        RETLW     0x99
        RETLW     0x47
        RETLW     0xA0
        RETLW     0x20
        RETLW     0xDE
        RETLW     0x1A
        RETLW     0xAD
        RETLW     0x63
        RETLW     0x81
        RETLW     0x15
        RETLW     0xFA
        RETLW     0x2E
        RETLW     0x88
        RETLW     0x42
        RETLW     0xB5
        RETLW     0x31
        RETLW     0xCF
        RETLW     0x0B
        RETLW     0xA8
        RETLW     0x76
        RETLW     0x90
        RETLW     0x04
        RETLW     0xEB
        RETLW     0x2B
        RETLW     0x9D
        RETLW     0x53
        RETLW     0xA4
        RETLW     0x20
        RETLW     0xCA
        RETLW     0x1E
        RETLW     0xB9
        RETLW     0x67
        RETLW     0x81
        RETLW     0x01
        RETLW     0xFE
        RETLW     0x3A
        RETLW     0x8C
        RETLW     0x42
        RETLW     0xA1
        RETLW     0x35
        RETLW     0xDB
        RETLW     0x0F
        RETLW     0xA8
        RETLW     0x62
        RETLW     0x94
        RETLW     0x10
        RETLW     0xEF
        RETLW     0x2B
        RETLW     0x89
        RETLW     0x57
        RETLW     0xB0
        RETLW     0x24
        RETLW     0xCA
        RETLW     0x0A
        RETLW     0xBD
        RETLW     0x73
        RETLW     0x85
        RETLW     0x01
        RETLW     0xEA
        RETLW     0x3E
        RETLW     0x98
        RETLW     0x46
        RETLW     0xA1
        RETLW     0x21
        RETLW     0xDF
        RETLW     0x1B
        RETLW     0xAC
        RETLW     0x62
        RETLW     0x80
        RETLW     0x14
        RETLW     0xFB
        RETLW     0x2F
        RETLW     0x89
        RETLW     0x43
        RETLW     0xB4
        RETLW     0x30
        RETLW     0xCE
        RETLW     0x0A
        RETLW     0xA9
        RETLW     0x77
        RETLW     0x91
        RETLW     0x05
        RETLW     0xEA
        RETLW     0x2A
        RETLW     0x9C
        RETLW     0x52
        RETLW     0xA5
        RETLW     0x21
        RETLW     0xCB
        RETLW     0x1F
        RETLW     0xB8
        RETLW     0x66
        RETLW     0x80
        RETLW     0x00
        RETLW     0xA1
        RETLW     0x21
        RETLW     0xDF
        RETLW     0x1B
        RETLW     0xAC
        RETLW     0x62
        RETLW     0x80
        RETLW     0x14
        RETLW     0xFB
        RETLW     0x2F
        RETLW     0x89
        RETLW     0x43
        RETLW     0xB4
        RETLW     0x30
        RETLW     0xCE
        RETLW     0x0A
        RETLW     0xA9
        RETLW     0x77
        RETLW     0x91
        RETLW     0x05
        RETLW     0xEA
        RETLW     0x2A
        RETLW     0x9C
        RETLW     0x52
        RETLW     0xA5
        RETLW     0x21
        RETLW     0xCB
        RETLW     0x1F
        RETLW     0xB8
        RETLW     0x66
        RETLW     0x80
        RETLW     0x00

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
