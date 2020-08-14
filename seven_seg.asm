;**********************************************************************
;   This file is a basic code template for assembly code generation   *
;   on the PIC16F54. This file contains the basic code                *
;   building blocks to build upon.                                    *
;                                                                     *
;   Refer to the MPASM User's Guide for additional information on     *
;   features of the assembler (Document DS33014).                     *
;                                                                     *
;   Refer to the respective PIC data sheet for additional             *
;   information on the instruction set.                               *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Filename:	   seven_seg.asm                                      *
;    Date:                                                            *
;    File Version:                                                    *
;                                                                     *
;    Author:                                                          *
;    Company:                                                         *
;                                                                     * 
;                                                                     *
;**********************************************************************
;                                                                     *
;    Files Required: P16F54.INC                                       *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;                                                                     *
;**********************************************************************

    list      p=16F54             ; list directive to define processor
#include <p16f5x.inc>
; processor specific variable definitions

    __CONFIG   _CP_OFF & _WDT_OFF & _RC_OSC

; '__CONFIG' directive is used to embed configuration word within .asm file.
; The lables following the directive are located in the respective .inc file. 
; See respective data sheet for additional information on configuration word.




;***** VARIABLE DEFINITIONS
porta equ PORTA
portb equ PORTB
; FSR equ 0x04
 
general    EQU  0x07        ;example variable definition
counter    EQU  0x08        ;example variable definition
state      EQU  0x09
config_reg EQU  0x0A
digit0     Equ	0x0B
digit1     Equ	0x0C
digit2     Equ	0x0D
loop_cnt   EQU	0x0E
bit_count  EQU	0x0F
char_count EQU	0x10
character0 EQU	0x11
character1 EQU	0x12
character2 EQU	0x13
fsr_bck    EQU	0x14
crc_reg    EQU	0x15
crc_data   EQU	0x16
crc_sum    EQU	0x17
  
#define WAIT_CONST 			0x0F
#define IDLE 	  			0x00
#define WAIT_DATA  			0x01
#define WAIT_FALLING_EDGE	0x02
#define WAIT_HIGH_PULS		0x03
#define EXTRACT_BYTE		0x04
  
;**********************************************************************
	ORG     0x1FF             ; processor reset vector
	goto    start
	ORG     0x000


init	
    clrf PORTA
    clrf PORTB
    
    movlw 0x00
    tris PORTB
        
    movlw 0xf8
    tris PORTA
    
    clrf char_count
    clrf crc_reg
    clrf state
    clrf loop_cnt
    clrf config_reg
    
    movlw WAIT_CONST
    movwf counter
   
    movlw 0x0B
    movwf FSR
    clrf INDF
        
    movlw 0x01
    movwf digit0
    movlw 0x30
    movwf digit1
    movlw 0x7
    movwf digit2
    retlw 0

init0        
    movlw 0x00
    tris PORTB
        
    movlw 0xf8
    tris PORTA
    
    clrf char_count
    clrf crc_reg
    clrf state
    bcf config_reg, 7
   
    movlw 0x0B
    movwf FSR
    retlw 0    

start
    btfsc STATUS, 3
    call init
    btfss STATUS, 3
    call init0
    
main
    btfsc config_reg, 7
    sleep
    btfsc config_reg, 6
    goto clear_display
    
	decfsz counter
	goto clear_display
	
	movlw 0x3F
	andwf config_reg, w
	movwf counter
    incf counter
	
	decfsz general
    goto small_display
      
display
    movlw 0x03
    movwf general
    movlw 0x0D
    movwf FSR
small_display
    
    movlw 0xf8
    movwf porta
    
    movfw INDF
    movwf portb
    decf FSR
    
    movlw 0x01
    subwf general,w
     
    call power_2
    movwf porta 
    
    goto read_io
    
end_read_io    
        
    goto main

clear_display
    clrf portb

read_io
	movlw IDLE
	subwf state, w
	btfsc STATUS, Z
	goto IDLE_STATE
	
	movlw WAIT_FALLING_EDGE
	subwf state, w
	btfsc STATUS, Z
	goto wait_falling_edge_state
	
	movlw WAIT_DATA
	subwf state, w
	btfsc STATUS, Z
	goto WAIT_DATA_STATE
	
	movlw WAIT_HIGH_PULS
	subwf state, w
	btfsc STATUS, Z
	goto WAIT_HIGH_PULS_STATE
	
	movlw EXTRACT_BYTE
	subwf state, w
	btfsc STATUS, Z
	goto EXTRACT_BYTE_STATE
	goto end_read_io

IDLE_STATE
	btfsc porta, 0x03
	goto byte_timeout
	
	movlw 0x0A
	movwf loop_cnt
	movlw 0x07
	movwf bit_count
	clrf character0
	movlw WAIT_DATA
	movwf state
	
byte_timeout	
	decfsz loop_cnt
	goto end_read_io
	clrf char_count
	clrf crc_reg
	goto end_read_io

WAIT_DATA_STATE		
	decfsz loop_cnt
	goto end_read_io
		
	btfss porta, 0x03
	goto weiter0
	incf character0
	movlw WAIT_FALLING_EDGE
	movwf state
	movlw 0xf0
	movwf loop_cnt
	goto end_read_io
weiter0
	movlw WAIT_HIGH_PULS
	movwf state
	movlw 0x30
	movwf loop_cnt
	goto end_read_io

EXTRACT_BYTE_STATE
	incf char_count
	movlw 0x01
	subwf char_count, w
	btfsc STATUS, Z
	goto extract_character2
	movlw 0x02
	subwf char_count, w
	btfsc STATUS, Z
	goto extract_character1
	movlw 0x03
	subwf char_count, w
	btfsc STATUS, Z
	goto extract_character0
extract_character2
	movfw character0
	movwf character2
	movwf crc_data
	call crc_table
	clrf state
	goto end_read_io
extract_character1
	movfw character0
	movwf character1
	movwf crc_data
	call crc_table
	clrf state
	goto end_read_io
extract_character0
	movfw character0
	movwf crc_data
	call crc_table
	clrf loop_cnt
	clrf char_count
	clrf crc_reg
	clrf state
	movlw 0x00
	subwf crc_reg
	btfsc STATUS, Z
	call set_digit
	goto end_read_io
	
wait_falling_edge_state
	movlw 0x00
	subwf bit_count, w
	
	btfss STATUS, Z
	goto bit_count_positif

	movlw EXTRACT_BYTE
	movwf state
	goto end_read_io
	
bit_count_positif	
	btfss porta, 0x03
	goto weiter0_wait_falling_edge_state
	decfsz loop_cnt
	goto not_time_out_wait_falling_edge_state
	clrf char_count
	clrf crc_reg
	clrf state
not_time_out_wait_falling_edge_state
	goto end_read_io
weiter0_wait_falling_edge_state
	rlf character0
	bcf character0, 0
	
	decf bit_count

weiter_wait_data
	movlw WAIT_DATA
	movwf state
	movlw 0x0A
	movwf loop_cnt
	goto end_read_io
	
WAIT_HIGH_PULS_STATE		
	btfss porta, 0x03
	goto weiter0_wait_high_puls_state
	movlw WAIT_FALLING_EDGE
	movwf state
	movlw 0xf0
	movwf loop_cnt
	goto end_read_io
weiter0_wait_high_puls_state
	decfsz loop_cnt
	goto not_time_out_wait_high_puls_state
	clrf char_count
	clrf crc_reg
	clrf state
not_time_out_wait_high_puls_state
	goto end_read_io
		
set_digit
    movfw FSR
    movwf fsr_bck
    movlw 0x0A
    movwf FSR
    
    movfw character2
    andlw 0x03
    
    addwf FSR
    movfw character1
    movwf INDF
    movlw 0x1F
    andwf fsr_bck, w
    movwf FSR
     
    retlw 0x00   
    
power_2
    andlw 0x03
    addwf PCL
    retlw 0x01
    retlw 0x02
    retlw 0x04
    retlw 0x08
    
crc_table
	movlw 0x08
	movwf fsr_bck
crc_loop
	movfw crc_reg
	xorwf crc_data, w
	movwf crc_sum
	rlf crc_reg
	bcf crc_reg, 0
	
	btfss crc_sum, 7
	goto crc_weiter
	movlw 0x1D
	xorwf crc_reg
crc_weiter
	rlf crc_data
	bcf crc_data, 0
	decfsz fsr_bck
	goto crc_loop
	retlw 0
	
	
; remaining code goes here

    END ; directive 'end of program'
