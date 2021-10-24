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
;    Filename:     seven_seg.asm                                      *
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
;FSR   equ 0x04
 
act_gigit   EQU  0x07        ;example variable definition
counter     EQU  0x08        ;example variable definition
state       EQU  0x09
config_reg  EQU  0x0A
digit0      Equ  0x0B
digit1      Equ  0x0C
digit2      Equ  0x0D
digit3      Equ  0x0E
shift_state EQU  0x0F
shift_reg   EQU  0x10
shift_count EQU  0x11
bit_count   EQU  0x12
char_count  EQU  0x13
character   EQU  0x14
read_state  EQU  0x15
fsr_read    EQU  0x16
fsr_shift   EQU  0x17
help_reg    EQU  0x18

#define SER                 0x00
#define SRCLK               0x01
#define RCLK                0x02
#define SRCLR               0x03

#define CS                  0x00
#define CLK                 0x01
#define DIO                 0x02

#define WAIT_CONST          0x00

#define SHIFT_IDLE          0x00
#define SHIFT_FALLING       0x01
#define SHIFT_RISING        0x02
#define SHIFT_RCLK          0x03

#define READ_IDLE           0x00
#define READ_FALLING        0x01
#define READ_RISING         0x02
#define READ_EXTRACT        0x03
#define READ_REINIT         0x04
  
;**********************************************************************
    ORG     0x1FF             ; processor reset vector
    goto    start
    ORG     0x000


init    
    clrf PORTA
    clrf PORTB
    
    movlw 0x00
    tris PORTB
    bcf portb, SRCLR
    bsf portb, SRCLR    
    
    movlw 0xf7
    tris PORTA
    
    clrf char_count
    clrf shift_state
    clrf shift_reg
    
    clrf read_state
    clrf counter
   
    movlw 0x0E
    movwf fsr_read
    movwf fsr_shift
    
    movlw 0x0E
    movwf FSR
    clrf INDF

    movlw 0x08
    movwf config_reg
    movlw 0x01
    movwf digit0
    movlw 0x03
    movwf digit1
    movlw 0x07
    movwf digit2
    movlw 0x0f
    movwf digit3
    retlw 0

start
    btfsc STATUS, 3
    call init
    
main
    btfsc config_reg, 4
    goto turn_off_leds
    
    movlw 0x00
    subwf act_gigit, f
    btfss STATUS, Z
    goto dimming
      
display
    movlw 0x04
    movwf act_gigit
    movlw digit3
    movwf FSR
dimming    
    incf counter, f
    movlw 0x0F
    andwf counter, f
    andwf config_reg, w
    subwf counter, w
    btfsc STATUS, C
    goto small_display
turn_off_leds    
    movlw 0xf0;
    iorwf portb, f
    goto end_display
    
small_display
        
    movlw SHIFT_IDLE
    subwf shift_state, w
    btfsc STATUS, Z
    goto SHIFT_IDLE_STATE
    
    movlw SHIFT_FALLING
    subwf shift_state, w
    btfsc STATUS, Z
    goto SHIFT_FALLING_STATE
    
    movlw SHIFT_RISING
    subwf shift_state, w
    btfsc STATUS, Z
    goto SHIFT_RISING_STATE
    
    movlw SHIFT_RCLK
    subwf shift_state, w
    btfsc STATUS, Z
    goto SHIFT_RCLK_STATE
end_display
    
    movfw FSR
    movwf fsr_shift
    movlw 0x1F
    andwf fsr_read, w
    movwf FSR

    movlw READ_IDLE
    subwf read_state, w
    btfsc STATUS, Z
    goto READ_IDLE_STATE
    
    movlw READ_FALLING
    subwf read_state, w
    btfsc STATUS, Z
    goto READ_FALLING_STATE
    
    movlw READ_RISING
    subwf read_state, w
    btfsc STATUS, Z
    goto READ_RISING_STATE
    
    movlw READ_EXTRACT  
    subwf read_state, w
    btfsc STATUS, Z
    goto READ_EXTRACT_STATE
    
    movlw READ_REINIT  
    subwf read_state, w
    btfsc STATUS, Z
    goto READ_REINIT_STATE
end_read
    
    movfw FSR
    movwf fsr_read
    movlw 0x1F
    andwf fsr_shift, w
    movwf FSR
        
    goto main


READ_IDLE_STATE

    btfss porta, CS
    btfsc porta, CLK
    goto end_read

    bsf porta, 3
;    bcf porta, 3    
    
    clrf character
    clrf char_count
    movlw 0x08
    movwf bit_count
    
    movlw READ_RISING
    movwf read_state
    goto end_read


READ_RISING_STATE
    
    bcf porta, 3
 
    btfsc porta, CS
    goto next_idle_state

    btfss porta, CLK
    goto end_read
    
    btfsc porta, DIO
    incf character, f
    
    movlw READ_FALLING
    movwf read_state
    goto end_read


READ_FALLING_STATE

    btfsc porta, CS
    goto next_idle_state
    
    btfsc porta, CLK
    goto end_read
    
    decfsz bit_count, f
    goto rising_falling_state
    
    movlw READ_EXTRACT
    movwf read_state
    goto end_read
    
rising_falling_state
    rlf character, f
    movlw 0xFE
    andwf character, f
    
    movlw READ_RISING
    movwf read_state
    goto end_read


READ_EXTRACT_STATE

    btfsc porta, CS
    goto next_idle_state

    movlw 0x00
    subwf char_count, w
    btfss STATUS, Z
    goto weiter_extract
    goto first_charachter_extract_state

first_charachter_extract_state
    movlw 0x05
    subwf character, w
    btfsc STATUS, C
    goto next_reinit_state
    movlw 0x09
    addwf character, w
    movwf FSR
    goto next_rising_state
    
weiter_extract
    movlw 0x1F
    andwf FSR, w
    movwf fsr_read
    movlw 0x0E
    subwf fsr_read, w
    btfsc STATUS, Z
    goto next_reinit_state
    incf FSR  
    movfw character
    movwf INDF

next_rising_state    
    clrf character
    movlw 0x08
    movwf bit_count
    incf char_count, f
    movlw READ_RISING
    movwf read_state
    goto end_read

next_idle_state
    clrf char_count
    movlw READ_IDLE
    movwf read_state
    goto end_read

next_reinit_state
    clrf character
    movlw READ_REINIT
    movwf read_state
    goto end_read
    
READ_REINIT_STATE

    btfss porta, CS
    goto end_read
    
    movlw READ_IDLE
    movwf read_state
    goto end_read
    
    
SHIFT_IDLE_STATE
    bcf portb, SRCLR
    bsf portb, SRCLR 
    bcf portb, RCLK
    
    movfw INDF
    movwf shift_reg
    decf FSR, f
    decf act_gigit, f
    
    movlw 0x08
    movwf shift_count
    
    movlw SHIFT_FALLING
    movwf shift_state
    goto end_display

SHIFT_FALLING_STATE
    
    bcf portb, SRCLK
    btfss shift_reg, 0x00
    goto shift_falling_state_1
    bcf portb, SER
shift_falling_state_1_ret
    rrf shift_reg, f
    
    movlw SHIFT_RISING
    movwf shift_state
    goto end_display
    
shift_falling_state_1
    bsf portb, SER
    goto shift_falling_state_1_ret
    
SHIFT_RISING_STATE

    bsf portb, SRCLK
    
    decfsz shift_count, f
    goto shift_rising_state_0
    
    movlw SHIFT_RCLK
shift_rising_state_ret        
    movwf shift_state
    goto end_display

shift_rising_state_0
    movlw SHIFT_FALLING
    goto shift_rising_state_ret

SHIFT_RCLK_STATE
    
    bcf portb, SRCLK
   
    movlw 0xf0;
    iorwf portb, f
    
    bsf portb, RCLK
       
    movfw act_gigit
    
    call set_output_digit
    andwf portb

    movlw SHIFT_IDLE
    movwf shift_state
    goto end_display  
    
set_output_digit
    andlw 0x03
    addwf PCL
    retlw 0xEF
    retlw 0xDF
    retlw 0xBF
    retlw 0x7F
    
    
; remaining code goes here

    END ; directive 'end of program'
