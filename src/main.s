
;***************************************** CONFIG *******************************************

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

;************************************** REGISTER BITS ***************************************

C equ 0x00 ; carry 
Z equ 0x02 ; zero

;**************************************** CONSTANTS *****************************************

T equ 6 ; set collision threshold for speed increment to 6
DC equ 6 ; DC on SPI screen
CS equ 5 ; CS on SPI screen

;***************************************** VECTORS ******************************************

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
    y2: ds 1 ; y of paddle 2

    xF: ds 1 ; full x pixel of the ball
    yF: ds 1 ; full y pixel of the ball

    xS: ds 1 ; x subpixel of the ball
    yS: ds 1 ; y subpixel of the ball

    dir: ds 1 ; bit0 - x direction (0=left, 1=right), bit1 - y direction (0=up, 1=down)

    xVelS: ds 1 ; x velocity subpixel of the ball
    yVelS: ds 1 ; y velocity subpixel of the ball

    yTemp: ds 1 ;
    substeps: ds 1 ; sub step counter
    substep_speed: ds 1 ; sub step speed register

    diff: ds 1 ; difference between paddle - ball
    temp: ds 1 ; temp register

    collisions: ds 1 ; counts numbe of collisions for speed increments

    ;score: ds 1 ; bit 0 -> 3 - player 1, bit 4 -> 7 - player 2 worth it or not? 

    

    ;15/16 common bytes used :]

psect bank0, class=BANK0, space=1 

    WAIT1: ds 1 ; wait counters
    WAIT125: ds 1
    WAIT10: ds 1
    WAIT100: ds 1
    WAIT1000: ds 1

    s1: ds 1 ; score of player 1
    s2: ds 1 ; score of player 2


;***************************************** SUBROUTINES ***************************************

psect code, class=CODE, space=0, delta=2
;******************************************** WAIT *******************************************
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
;******************************************** SETUP ******************************************
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
        movlw 0b11100000 ; 
        movwf LATC ; Latching RC7 (RESET - active low), RC6(DC - direct command) and RC5 (CS - chip select) to HIGH

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
    full_reset_ball:
        movlw 64
        movwf xF ; set x coordinate
    
        movlw 32
        movwf yF ; set y coordinate

        clrf xS ; clear the sub pixel values
        clrf yS

        movlw 2
        movwf substep_speed
        

        movlw 64
        movwf xVelS
        movlw 0
        movwf yVelS

        movlw 0b00000011 
        movwf dir

        movlw 0
        movwf collisions ; set collisions to zero
        return

    reset_ball: ; retain direction data
        movlw 64
        movwf xF

        movlw 32
        movwf yF

        clrf xS
        clrf yS

        movlw 2 
        movwf substep_speed

        movlw 64
        movwf xVelS
        movlw 0
        movwf yVelS

        movlw 0
        movwf collisions
        return
    clear_scores:
        banksel s1
        clrf s1
        clrf s2
        return
    
    clear_registers: ; clear other miscellaneous registers
        clrf yTemp
        clrf substeps
        clrf diff
        clrf temp


;***************************************** ADC ***********************************************
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

;**************************************** SCORE ***********************************************
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

    increment_score1: ; increments score 1 by .... 1
        banksel s1
        incf s1, F
        return

    increment_score2: ; increments score 2 by .... 1
        banksel s2
        incf s2, F
        return

    p1_scores:
        call increment_score1
        call reset_ball
        bcf dir, 0 ; point towards paddle one
        ; round reset game
        return
    p2_scores:
        call increment_score2
        bsf dir, 0 ; point towards paddle 2
        ; round reset game
        return
;**************************************** GAME ************************************************
    round_reset:
        return
    
    wait_start:
        return
    
    diplay_start:
        return
    
    display_win1:
        return
    
    display_win2:
        return
;**************************************** BALL ************************************************
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

    check_collisions:
        
        incf collisions, F ; update collision count    

        movlw T ; load threhold
        xorwf collisions, W ; check if number of collisions is equal to threshold
        btfss STATUS, Z
        return
        
        clrf collisions
        call increment_velocity ; if equal to threshold, increment speed, otherwise return
        return

    increment_velocity:
        movlw 2 ; check substep speed
        xorwf substep_speed, W
        btfsc STATUS, Z
        goto ramp_2 ; if 2 substeps, use the substep 2 ramp
        goto ramp_3 ; if 3 substeps, use the substep 3 ramp
        
    ramp_2:
        movlw 224
        xorwf xVelS, W ; check if max speed reached for 2 substeps
        btfsc STATUS, Z
        goto transition_3 ; if so, transition to 3 substeps

        movlw 32 ; otherwise add 32 to speed
        addwf xVelS, F
        return

    transition_3:
        movlw 3
        movwf substep_speed
        movlw 170
        movwf xVelS
        return

    ramp_3:
        movlw 255
        xorwf xVelS, W
        btfsc STATUS, Z
        return

        movlw 22 ; increment by 22 instead of 32
        addwf xVelS, F

        btfss STATUS, C
        return ; if no carry occured we didn't overflow and become slow

        movlw 255
        movwf xVelS
        return

        movlw 255
        movwf xVelS

        return
    

;************************************** PADDLE ADC ********************************************
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
        movlw 58
        return

;*************************************  COLLISION *********************************************
    check_walls:
        call check_top
        call check_bottom
        return

    check_top:
        btfsc dir, 1
        return ; skip collision if moving down
        movlw 0
        subwf yF, W
        btfsc STATUS, Z
        call top_bounce
        return
        ;undeflow logic? check if it hits 255 (or above 128)

    check_bottom:
        btfss dir, 1
        return ; skip collision if moving up
        movlw 63
        subwf yF, W
        btfss STATUS, C
        return
        call bottom_bounce
        return
    
    top_bounce:
        bsf dir, 1
        movlw 0
        movwf yF ; clamp yF to 0
        return
        
    bottom_bounce:
        bcf dir, 1
        movlw 63
        movwf yF ; clamp yF to 63
        return

    paddle1_collision:
        btfsc dir, 0 ; 0 = left
        return ; return if moving right
        
        movlw 3
        xorwf xF, W
        btfss STATUS, Z ; 1 = equal
        return

        movf y1, W ; W = yF - y1
        subwf yF, W  ; calculate difference and store in working        
        
        btfsc STATUS, Z ; yF == y1 (center)
        goto middle_paddle1
        btfss STATUS, C
        goto top_paddle1
        goto bottom_paddle1
        

    top_paddle1:
        movf yF, W ;convert value to positive
        subwf y1, W
    
        movwf diff
        sublw 5
        btfss STATUS, C ; diff>5, carry=0, ball missed
        return

        bsf dir, 0
        bcf dir, 1

        movlw 3
        movwf xF ; clamp ball to coordinate of 3
        
        call check_collisions

        movf diff, W ; pass distance to the router
        goto offset_router

    middle_paddle1:
        bsf dir, 0
        
        movlw 3
        movwf xF ; clamp to coordinate 3

        call check_collisions

        clrf yVelS ; set y velocity to zero
        return

    bottom_paddle1:
        movwf diff
        sublw 5 ; 

        btfss STATUS, C ; if diff > 5, carry = 0, ball missed
        return

        bsf dir, 0
        bsf dir, 1

        movlw 3
        movwf xF

        call check_collisions

        movf diff, W
        goto offset_router


    paddle2_collision:
        btfss dir, 0 ; 0 = left
        return ; return if moving right
        
        movlw 124
        xorwf xF, W
        btfss STATUS, Z ; 1 = equal
        return

        movf y2, W ; W = yF - y2
        subwf yF, W  ; calculate difference and store in working

        btfsc STATUS, Z ; yF == y2 (center)
        goto middle_paddle2

        btfss STATUS, C
        goto top_paddle2
        goto bottom_paddle2

    top_paddle2:
        
        movf yF, W
        subwf y2, W ; converting to positive
    
        movwf diff
        sublw 5
        btfss STATUS, C ; diff>5, carry=0, ball missed
        return

        bcf dir, 0
        bcf dir, 1

        movlw 124
        movwf xF ; clamp ball to coordinate of 124

        call check_collisions

        movf diff, W ; pass distance to the router
        goto offset_router

    middle_paddle2:
        bcf dir, 0
        
        movlw 124
        movwf xF ; clamp to coordinate 124

        call check_collisions
        
        clrf yVelS ; set y velocity to zero
        return

    bottom_paddle2:
        movwf diff
        sublw 5 ; 5 - diff (if underflows, 5 - diff will overflow)

        btfss STATUS, C ; if diff > 5, carry = 0, ball missed
        return

        bcf dir, 0
        bsf dir, 1

        movlw 124
        movwf xF

        call check_collisions

        movf diff, W
        goto offset_router
    

    offset_router:
        movwf temp
        
        decf temp, F ; decrement difference, if equal to zero, route offset 1, if diff > 1, move onto next decrement check cycle
        btfsc STATUS, Z
        goto offset_1

        decf temp, F
        btfsc STATUS, Z
        goto offset_2

        decf temp, F
        btfsc STATUS, Z
        goto offset_3

        decf temp, F
        btfsc STATUS, Z
        goto offset_4
        goto offset_5

    offset_0:
        clrf yVelS
        return

    offset_1:
        movf xVelS, W
        movwf yVelS ; move xVelS into yVelS
        
        lsrf yVelS, F ; divide by 4 (1/4)
        lsrf yVelS, F
        movf yVelS, W
        movwf yTemp

        lsrf yVelS, F ; divide by 32 (1/32)
        lsrf yVelS, F
        lsrf yVelS, F

        movf yVelS, W
        subwf yTemp, W ; 1/4 - 1/32 ~ 0.2 = 12º
        movwf yVelS
        return
    
    offset_2:
        movf xVelS, W
        movwf yVelS

        lsrf yVelS, F ; divide by 2 (1/2)
        movf yVelS, W
        movwf yTemp

        lsrf yVelS, F ; divide by 16 (1/16)
        lsrf yVelS, F
        lsrf yVelS, F

        movf yVelS, W
        subwf yTemp, W ; 1/2 - 1/16 ~ 0.45 = 24º
        movwf yVelS
        return

    offset_3:
        movf xVelS, W
        movwf yVelS

        lsrf yVelS, F ; divide by 2 (1/2)
        movf yVelS, W ; store 1/2 xVelS in working
        lsrf yVelS, F ; divided by 4 (1/4)
        addwf yVelS, F ; 1/2 + 1/4 = 3/4

        movf yVelS, W
        movwf yTemp ; yTemp storing 3/4 xVelS

        movf xVelS, W
        movwf yVelS

        lsrf yVelS, F ;divide by 32 (1/32)
        lsrf yVelS, F
        lsrf yVelS, F
        lsrf yVelS, F
        lsrf yVelS, F

        movf yVelS, W ; move 1/32 into working
        subwf yTemp, W ; 1/32 - 3/4 ~ 0.72 = 36º
        movwf yVelS
        return

    offset_4:
        movf xVelS, W
        movwf yVelS

        lsrf yVelS, F ; divide by 8 (1/8)
        lsrf yVelS, F
        lsrf yVelS, F

        movf xVelS, W
        addwf yVelS, F ; 1 + 1/8 ~ 1.1 = 48º
        return
    
    offset_5:
        movf xVelS, W
        movwf yVelS

        lsrf yVelS, F ; divide by 2 (1/2)
        movf yVelS, W ; store in working

        movf yVelS, W
        lsrf yVelS, F ; divide by 4 (1/4)
        addwf yVelS, F ; 1/2 + 1/4 = 3/4 xVelS

        movf xVelS, W
        addwf yVelS, F ; 1+3/4 ~ 1.73 = 60º
        return

    check_backwalls:
        call check_backwall1
        call check_backwall2
        return
    
    check_backwall1:
        movlw 0
        xorwf xF, W 
        btfsc STATUS, Z ;if set, xF == 0, so scores
        call p2_scores

        btfsc xF, 7 
        goto p2_scores ; just in case it underflows 0 -> 255
        return
    
    check_backwall2:
        movlw 127
        subwf xF, W ; (xF - 127)>=0
        btfsc STATUS, C  ; if set, no borrow, so xF>=127
        call p1_scores
        return 

;*************************************** SCREEN **********************************************
    render_frame:
        return
    
    setup_spi:
        ;left to defaults for the most part
        banksel SSP1CON1 ; synchronous serial port, (pg 317)
        ;bit 5 (SSPEN) = 1 enable serial port (pg 360)
        ;3-0 (SSPM) = 0000 SPI Master mode, clock = FOSC (32) / 4 = 8MHz (pg 360)
        ;rest of config bits as default (pg 317 - 5:0 bit reference)
        movlw 0b00100000
        movwf SSP1CON1

        banksel SSP1STAT
        ;bit 6 (CKE) = 1 - falling edge triggered (pg 359) 
        ;bit 7 (SMP) = 0 - input data sampled at middle of data output (pg 359) 
        movlw 0b01000000
        movwf SSP1STAT

    spi_send:
        banksel SSP1BUF ; write byte to SPI Buffer from W
        movwf SSP1BUF
    
    wait_spi:
        banksel SSP1STAT
        btfss SSP1STAT, 0
        goto wait_spi
        
        banksel SSP1BUF, W
        movf SSP1BUF, W
        return

    send_command:
        banksel LATC ; write command from working to screen
        bcf LATC, DC ; pull DC low to indicate command
        bcf LATC, CS ; pull CS low to select screen
        
        call spi_send
        
        banksel LATC, CS
        bsf LATC, CS ; pull CS high to end transfer
        return
    
    send_data:
        banksel LATC ; write pixel data to screen
        bsf LATC, DC ; pull DC high to indicate data
        bcf LATC, CS ; pull CS low to select screen

        call spi_send

        banksel LATC, CS
        bsf LATC, CS
        return

;**************************************** STARTUP ********************************************
start:
    call set_frq
    call setup_ports
    call setup_pps
    call setup_adc
    call reset_paddles
    call full_reset_ball
    call clear_scores
    call clear_registers

    call display_start
    
    call wait1000ms ;wait
    ; wait for start button
    ; say starting
    ; wait 1s after start hit



    goto main

    ;x1 = 1 - paddle 2px wide
    ;x2 = 126 - paddle 2px wide
    ;paddle is 11 px tall
        
;***************************************** MAIN LOOP *****************************************

main:
    movf substep_speed, W ; load substep_speed into substep counter
    movwf substeps
    goto physics_loop


physics_loop:
    call check_score
    call update_paddle1
    call update_paddle2

    call update_ball
    
    call check_walls
    
    call paddle1_collision
    call paddle2_collision

    call check_backwalls

    decfsz substeps, F
    
    goto physics_loop
    goto main

;**************************************** INTERRUPTS *****************************************

isr:
    retfie ;return from interrupt
    ; have reset button call isr

end

