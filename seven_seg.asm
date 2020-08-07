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
;    Filename:	    blink.asm                                           *
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
#include <p16f5x.inc>         ; processor specific variable definitions

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
char_count EQU	0x0F
character0 EQU	0x10
character1 EQU	0x11
character2 EQU	0x12
fsr_bck    EQU	0x13
  
#define WAIT_CONST 			0x0F
#define IDLE 	   			0x00
#define WAIT_DATA  			0x01
#define WAIT_FALLING_EDGE	0x02
#define WAIT_HIGH_PULS		0x03
  
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
    
    movlw 0x03
    option 
    
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
    

start
    call init
    
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
;    call timer
;    movwf general
;    btfsc general, 0
;    goto main
      
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
    
;    goto display
        
    goto main

clear_display
    clrf portb

read_io
	movlw IDLE
	subwf state, w
	btfsc STATUS, Z
	goto idle_state
	
	movlw WAIT_FALLING_EDGE
	subwf state, w
	btfsc STATUS, Z
	goto wait_falling_edge_state
	
	movlw WAIT_DATA
	subwf state, w
	btfsc STATUS, Z
	goto wait_data_state
	
	movlw WAIT_HIGH_PULS
	subwf state, w
	btfsc STATUS, Z
	goto wait_high_puls_state
;end_read_io
	
	;btfsc porta, 0x03
	;bsf portb, 0x07
	;bcf portb, 0x07
	;retlw 0x00

idle_state
;	bsf portb, 0x07 ; Debug
	
	btfsc porta, 0x03
	goto end_read_io
	
	movlw 0x11
	movwf loop_cnt
	movlw 0x0F
	movwf char_count
	clrf character0
	clrf character1
	movlw WAIT_DATA
	movwf state
		 
	goto end_read_io

wait_data_state	
	
	decfsz loop_cnt
	goto end_read_io
	
;	bcf portb, 0x07 ; Debug
		
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
	
wait_falling_edge_state
;	bsf portb, 0x07 ; Debug
	
	movlw 0x00
	subwf char_count, w
	
	btfss STATUS, Z
	goto char_count_positif
	call set_digit
	clrf state
	goto end_read_io
	
char_count_positif	
	btfss porta, 0x03
	goto weiter0_wait_falling_edge_state
	decfsz loop_cnt
	goto not_time_out_wait_falling_edge_state
	clrf state
not_time_out_wait_falling_edge_state
	goto end_read_io
weiter0_wait_falling_edge_state
	rlf character0
	rlf character1
	bcf character0, 0
	
	decf char_count
;	goto end_read_io
weiter_wait_data
	movlw WAIT_DATA
	movwf state
	movlw 0x11
	movwf loop_cnt
	goto end_read_io
	
wait_high_puls_state
;	bsf portb, 0x07 ; Debug
		
	btfss porta, 0x03
	goto weiter0_wait_high_puls_state
;	bsf portb, 0x07 ; Debug
	movlw WAIT_FALLING_EDGE
	movwf state
	movlw 0xf0
	movwf loop_cnt
	goto end_read_io
weiter0_wait_high_puls_state
	decfsz loop_cnt
	goto not_time_out_wait_high_puls_state
	clrf state
not_time_out_wait_high_puls_state
	goto end_read_io
		
set_digit
    movfw FSR
    movwf fsr_bck
    movlw 0x0A
    movwf FSR
    
    movfw character1
    andlw 0x03
    
    addwf FSR
    movfw character0
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

; remaining code goes here

    END ; directive 'end of program'
