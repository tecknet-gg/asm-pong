
;***************************************** CONFIG *****************************************

PROCESSOR 16F18346

;CONFIG BITS

;CONFIG 1
CONFIG FEXTOSC = OFF ; disable external oscillator
CONFIG RSTOSC = HFINT32 ; enable 32Mhz internal oscillator
CONFIG CLKOUTEN = OFF
CONFIG CSWEN = ON
CONFIG FCMEN = ON

;CONFIG 2
CONFIG MCLRE = ON 
CONFIG PWRTE = OFF
CONFIG WDTE = OFF ; watchdog timer disabled
CONFIG LPBOREN = OFF
CONFIG BOREN = ON ; brown-out reset enabled
CONFIG BORV = LOW
CONFIG PPS1WAY = OFF
CONFIG STVREN = ON
CONFIG DEBUG = OFF

;CONFIG 3
CONFIG WRT = OFF
CONFIG LVP = ON

;CONFIG 4
CONFIG CP = OFF
CONFIG CPD = OFF

#include <xc.inc>

;***************************************** VECTORS *****************************************


;RESET VECTOR
psect resetVec, class=CODE, space=0, delta=2, abs
org 0x0000
    goto start


;INTERUPT VECTOR
psect intVec, class=CODE, space=0, delta=2, abs
org 0x0004
    goto isr

;***************************************** REGISTERS *****************************************


psect common, class=COMMON, space=1; pg(30, 47sg). ds reserves 1 byte. COMMON has 16 bytes accessible independent of banks. space=1 - RAM space=0 - ROM

y1: ds 1 ;y of paddle 1
y2: ds 1; y of paddle 2

xF: ds 1; full x pixel of the ball
yF: ds 1; full y pixel of the ball

xS: ds 1; x subpixel of the ball
yS: ds 1; y subpixel of the ball

xVelS: ds 1; x velocity subpixel of the ball
yVelS: ds 1; y velocity subpixel of the ball

s1: ds 1; score of player 1
s2: ds 1; score of player 2

psect bank0, class=BANK0, space=1 

WAIT1: ds 1
WAIT125: ds 1
WAIT10: ds 1
WAIT100: ds 1
WAIT1000: ds 1



;***************************************** SUBROUTINES *****************************************


psect code, class=CODE, space=0, delta=2


wait125us:
    movlw 199
    banksel WAIT125
    movwf WAIT125; ~125us at 32Mhz -> 199 * 625ns = 124375ns
    loop5ns: ;1+1+1+2 = 5
        clrwdt ; 1
        nop; 1
        decfsz WAIT125, F ;1
        goto loop5ns; 2
        nop; 1
    return; 2

wait1ms:
    movlw 8
    banksel WAIT1
    movwf WAIT1;
    loop1ms:
        call wait125us; 2
        decfsz WAIT1, F ;1
        goto loop1ms; 2
    return; 2

wait10ms:
    movlw 10
    banksel WAIT10
    movwf WAIT10;
    loop10ms:
        call wait1ms; 2
        decfsz WAIT10, F ;1
        goto loop10ms; 2
    return; 2

wait100ms:
    movlw 100
    banksel WAIT100
    movwf WAIT100;
    loop100ms:
        call wait1ms; 2
        decfsz WAIT100, F ;1
        goto loop100ms; 2
    return; 2

wait1000ms:
    movlw 10
    banksel WAIT1000
    movwf WAIT1000;
    loop1000ms:
        call wait100ms; 2
        decfsz WAIT1000, F ;1
        goto loop1000ms; 2
    return; 2


set_frq:
    banksel OSCFRQ
    movlw 0110B
    movwf OSCFRQ ; set to 32Mhz (pg.93)
    return

setup_ports:
    banksel TRISA
    movlw 00110000B ; set RA4 and RA5 to input
    movwf TRISA

    banksel TRISB
    movlw 01100000B ; set RB4 and RB5 to input
    movwf TRISB

    banksel TRISC
    clrf TRISC
    
    banksel ANSELA
    movlw 00110000B ; set pots on RA4 and RA5 to analog
    movwf ANSELA

    banksel ANSELB
    clrf ANSELB ; set all pins on PORTB to digital

    banksel ANSELC
    clrf ANSELC ; set all pins on PORTC to digital

    return

setup_pps:

    banksel LATC
    movlw 10100000B ; 
    movwf LATC ; Latching RC7 (RESET - active low) and RC5 (CS - chip select) to HIGH

    bcf INTCON, 7 ; disable global interrupts (pg. 103)
    banksel PPSLOCK ;required sequence (pg.161)
    movlw 0x55
    movwf PPSLOCK
    movlw 0xAA
    movwf PPSLOCK 
    bcf PPSLOCK, 0 ; unlock PPS

    banksel RC3PPS
    movlw 00011000B ;11000 = SCK1/SCL1 (pg 163)
    movwf RC3PPS 

    banksel RC4PPS
    movlw 00011001B ;11001 = SDO1/SDA1 (pg 163)
    movwf RC4PPS

    banksel PPSLOCK
    movlw 0x55
    movwf PPSLOCK
    movlw 0xAA
    movwf PPSLOCK
    bsf PPSLOCK, 0 ; lock PPS

    return

setup_adc:
    banksel ADCON1
    movlw 01110000B
    movwf ADCON1 ; left justified, dedicated RC oscillator, VREFs connected to VDD and VSS (pg 240, 241, 245)

    banksel ADCON0
    bsf ADCON0, 0 ; turn on ADC (pg 244)
    return

read_paddle1:
    banksel ADCON0
    movlw 00010001B ; select RA4 as input channel (pg241)
    movwf ADCON0
    goto run_adc

read_paddle2:
    banksel ADCON0
    movlw 00010101B ; select RA5 as input channel (pg241)
    movwf ADCON0
    goto run_adc

run_adc:
    call wait125us ; wait for acquisition (pg241)
    banksel ADCON0
    bsf ADCON0, 1
    goto wait_adc


wait_adc:
    btfsc ADCON0, 1; test to see if conversion is done
    goto wait_adc; go back to btsf if not done
    banksel ADRESH
    movf ADRESH, W; get the 8 upper bits
    return


check_score:
    banksel s1
    movf s1, W
    xorlw 9 ; check if player 1 has 9 points
    btfsc STATUS, Z
    goto player1_wins

    banksel s2
    movf s2, W
    xorlw 9
    btfsc STATUS, Z
    goto player2_wins

    return

;****************************************** STARTUP ******************************************

start:
    call set_frq
    call setup_ports
    call setup_pps
    call setup_adc

;***************************************** MAIN LOOP *****************************************

main:
    call read_paddle1
    banksel y1
    movwf y1 ; store paddle 1 position

    call read_paddle2
    banksel y2
    movwf y2 ; store paddle 2 position

    goto main


;**************************************** INTERRUPTS *****************************************

isr:
    retfie ;return from interrupt

end

