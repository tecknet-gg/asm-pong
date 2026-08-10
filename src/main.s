
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

;************************************** REGISTER BITS *************************************

C equ 0x00 ; carry 
Z equ 0x02 ; zero

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

    dir: ds 1; bit0 - x direction (0=left, 1=right), bit1 - y direction (0=up, 1=down)

    xVelS: ds 1; x velocity subpixel of the ball
    yVelS: ds 1; y velocity subpixel of the ball

    s1: ds 1; score of player 1
    s2: ds 1; score of player 2

    yTemp: ds 1;
    substeps: ds 1; sub step counter



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
        movlw 0b00110000 ; set RA4 and RA5 to input
        movwf TRISA

        banksel TRISB
        movlw 0b01100000 ; set RB4 and RB5 to input
        movwf TRISB

        banksel TRISC
        clrf TRISC
    
        banksel ANSELA
        movlw 0b00110000 ; set pots on RA4 and RA5 to analog
        movwf ANSELA

        banksel ANSELB
        clrf ANSELB ; set all pins on PORTB to digital

        banksel ANSELC
        clrf ANSELC ; set all pins on PORTC to digital

        return

    setup_pps:

        banksel LATC
        movlw 0b10100000 ; 
        movwf LATC ; Latching RC7 (RESET - active low) and RC5 (CS - chip select) to HIGH

        bcf INTCON, 7 ; disable global interrupts (pg. 103)
        banksel PPSLOCK ;required sequence (pg.161)
        movlw 0x55
        movwf PPSLOCK
        movlw 0xAA
        movwf PPSLOCK 
        bcf PPSLOCK, 0 ; unlock PPS

        banksel RC3PPS
        movlw 0b00011000 ;11000 = SCK1/SCL1 (pg 163)
        movwf RC3PPS 

        banksel RC4PPS
        movlw 0b00011001 ;11001 = SDO1/SDA1 (pg 163)
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
        movlw 0b01110000
        movwf ADCON1 ; left justified, dedicated RC oscillator, VREFs connected to VDD and VSS (pg 240, 241, 245)

        banksel ADCON0
        bsf ADCON0, 0 ; turn on ADC (pg 244)
        return
    
    reset_paddles:
        movlw 32; set y1 and y2 of the paddles to 32
        movwf y1
        movwf y2

    read_paddle1:
        banksel ADCON0
        movlw 0b00010001 ; select RA4 as input channel (pg241)
        movwf ADCON0
        call run_adc
        return

    read_paddle2:
        banksel ADCON0
        movlw 0b00010101 ; select RA5 as input channel (pg241)
        movwf ADCON0
        call run_adc
        return

    run_adc:
        call wait125us ; wait for acquisition (pg241)
        banksel ADCON0
        bsf ADCON0, 1
        goto wait_adc

    wait_adc:
        banksel ADCON0
        btfsc ADCON0, 1; test to see if conversion is done
        goto wait_adc; go back to btsf if not done
        banksel ADRESH
        movf ADRESH, W; get the 8 upper bits
        return


    check_score:
        banksel s1
        movf s1, W
        xorlw 9 ; check if player 1 has 9 points
        btfsc STATUS, Z ; read the Z status bit.
        ;goto player1_wins

        banksel s2
        movf s2, W
        xorlw 9
        btfsc STATUS, Z
        ;goto player2_wins

        return

    reset_ball:
        movlw 64
        movwf xF ; set x coordinate
    
        movlw 32
        movwf yF ; set y coordinate

        clrf xS ; clear the sub pixel values
        clrf yS

        movlw 192
        movwf xVelS
        movlw 0
        movwf yVelS

        movlw 0b00000011 
        movwf dir
        return

    update_ball:
        btfsc dir, 0 ; 0 - left, 1 - right
        goto ball_right
        goto ball_left
    
    ball_right:
        movf xVelS, W
        addwf xS, F
        btfsc STATUS, C ; did it overflow?
        incf xF, F
        goto update_y

    ball_left:
        movf xVelS, W
        subwf xS, F
        btfss STATUS, C ; did it carry?
        decf xF, F
        goto update_y

    update_y:
        btfss dir, 1 ; 0 - up, 1 - down
        goto ball_up
        goto ball_down
    
    ball_up:

        movf yVelS, W
        subwf yS, F
        btfss STATUS, C ; did it carry?
        decf yF, F
        return

    ball_down:

        movf yVelS, W
        addwf yS, F
        btfsc STATUS, C ; did it overflow?
        incf yF, F
        return

    update_paddle1:
        call read_paddle1
        
        call scale_paddle
        call clamp
        
        banksel y1
        movwf y1
        return
    
    update_paddle2:
        call read_paddle2
        
        call scale_paddle
        call clamp

        banksel y2
        movwf y2
        return

    scale_paddle:
        movwf yTemp
        lsrf yTemp, F ; right shift
        lsrf yTemp, F ; right shift
        return
    
    clamp:
        movlw 5
        subwf yTemp, W 
        btfss STATUS, C
        goto clamp_low

        movlw 59
        subwf yTemp, W
        btfsc STATUS, C
        goto clamp_high
    
        movf yTemp, W
        return

    clamp_low:
        movlw 5
        return
    
    clamp_high:
        movlw 59
        return
    




;****************************************** STARTUP ******************************************

start:
    call set_frq
    call setup_ports
    call setup_pps
    call setup_adc

    call reset_paddles
    call reset_ball

    movlw 2 ;two updates per frame
    movwf substeps

    ;x1 = 1 - paddle 2px wide
    ;x2 = 126 - paddle 2px wide
    ;paddle is 11 px tall
        


;***************************************** MAIN LOOP *****************************************

main:
    call update_paddle1
    call update_paddle2

    goto physics_loop


physics_loop:
    call update_ball
    ;all wall_collisions
    ;all paddle_collisions

    decfsz substeps, F
    goto physics_loop

    ;

    goto main

;**************************************** INTERRUPTS *****************************************

isr:
    retfie ;return from interrupt

end

