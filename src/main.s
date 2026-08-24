
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

;**************************************** SSD1306 *****************************************

OLED_RS equ 7 ; RES on SPI screen
OLED_DC equ 6 ; DC on SPI screen
OLED_CS equ 5 ; CS on SPI screen

; SPI boot sequence - call each command in sequence using send_command
; numeric description pertains to command number for specific config, as opposed to different config options or such

OLED_OFF equ 0xAE ; turn display off
CLK_DIV equ 0xD5
CLK_FRQ equ 0x80
OFFSET1 equ 0xD3
OFFSET2 equ 0x00
START_LINE equ 0x40
ENA_CPUMP1 equ 0x8D
ENA_CPUMP2 equ 0x14
SET_ADDR_MODE equ 0x20 ; ADDR mode
PAGE_MODE equ 0x02 ; PAGE mode
REMAP equ 0xA1
SET_COM equ 0xC0
SET_COM_CONFIG1 equ 0xDA
SET_COM_CONFIG2 equ 0x12 ; 128x64
SET_CONT1 equ 0x81
SET_CONT2 equ 0xCF 
SET_PREC1 equ 0xD9
SET_PREC2 equ 0xF1
SET_VCOMH1 equ 0xDB 
SET_VCOMH2 equ 0x40
RES_RAM equ 0xA4
SET_NORM equ 0xA6
OLED_ON equ 0xAF ; turn display on

HORIZ_MODE equ 0x00

;**************************************** Pixels ********************************************
; Asset byte definitions - load page and x value and then pass bytes in sequentially
; All assets fit on one page

p_1 equ 0b01111100 ; Letter P - 3 wide
p_2 equ 0b01010000
p_3 equ 0b01110000

o_1 equ 0b01111100 ; Letter O - 3 wide
o_2 equ 0b01000100
o_3 equ 0b01111100

n_1 equ 0b01111100 ; Letter N - 4 wide ;-;
n_2 equ 0b00110000
n_3 equ 0b00001000
n_4 equ 0b01111100

g_1 equ 0b01111100 ; Letter G - 3 wide
g_2 equ 0b01000100
g_3 equ 0b01011100

s_1 equ 0b01100100 ; Letter S - 3 wide
s_2 equ 0b01010100
s_3 equ 0b01011100

t_1 equ 0b01000000 ; Letter T - 3 wide
t_2 equ 0b01111100
t_3 equ 0b01000000

a_1 equ 0b01111100 ; Letter A - 3 wide
a_2 equ 0b01010000
a_3 equ 0b01111100 

r_1 equ 0b01111100 ; Letter R - 3 wide
r_2 equ 0b01011000
r_3 equ 0b01110100

e_1 equ 0b01111100 ; Letter E - 3 wide
e_2 equ 0b01010100
e_3 equ 0b01000100

symbol_exc equ 0b01110100 ; Symbol ! - 1 wide

arrow_left_1 equ 0b00010000 ; Left pointing arrow - 12 wide
arrow_left_2 equ 0b00111000
arrow_left_3 equ 0b01111100
arrow_left_4_12 equ 0b00010000

arrow_right_1_9 equ 0b00010000 ; Right pointing arrow - 12 wide
arrow_right_10 equ 0b01111100
arrow_right_11 equ 0b00111000
arrow_right_12 equ 0b00010000

number_1_1 equ 0b00100100 ; Number 1 - 3 wide
number_1_2 equ 0b01111100
number_1_3 equ 0b00000100

number_2_1 equ 0b01011100 ; Number 2 - 3 wide
number_2_2 equ 0b01010100
number_2_3 equ 0b01110100

arrow_down_1 equ 0b00001000 ; Arrow down - 5 wide
arrow_down_2 equ 0b00001100
arrow_down_3 equ 0b11111110
arrow_down_4 equ 0b00001100
arrow_down_5 equ 0b00001000

empty equ 0b00000000 ; Empty byte to clear screen 
;***************************************** SEVEN SEG ***************************************
SER equ 0 ; RC0 - Serial Data in - set the segment bits
SRCLK equ 1 ; RC1 - Pushes SER into the chip on rising edges
RCLK equ 2  ; RC2 - Latch



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

    x_vel: ds 1 ; x velocity subpixel of the ball
    y_vel: ds 1 ; y velocity subpixel of the ball

    y_temp: ds 1 ;
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

    old_xF: ds 1 ; old x pixel for ball
    old_yF: ds 1 ; old y pixel for ball

    cursor_page: ds 1 ; cursor page (0-7), each 8 bits tall
    cursor_x: ds 1 ; cursor x value (0-127)

    old_y1: ds 1 ; old paddle 1 y 
    old_y2: ds 1 ; old paddle 2 y

    mask0: ds 1 ; paddle bit mask can take upto 3 individual byte segments (11 tall, each segment 8 bits) 
    mask1: ds 1 
    mask2: ds 1 

    page_counter: ds 1 ; page tracker for clear screen subroutine
    x_counter: ds 1 

    loop_counter: ds 1 ; yet another temporary counter
 

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
        banksel old_y1
        movwf old_y1
        movwf old_y2
    full_reset_ball:
        banksel old_xF
        movlw 64
        movwf xF ; set x coordinate
        movwf old_xF

        banksel old_yF
        movlw 32
        movwf yF ; set y coordinate
        movwf old_yF

        clrf xS ; clear the sub pixel values
        clrf yS

        movlw 2
        movwf substep_speed
        

        movlw 64
        movwf x_vel
        movlw 0
        movwf y_vel

        movlw 0b00000011; temp 
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
        movwf x_vel
        movlw 0
        movwf y_vel

        movlw 0
        movwf collisions
        return
    clear_scores:
        banksel s1
        clrf s1
        clrf s2
        return
    
    clear_registers: ; clear other miscellaneous registers
        clrf y_temp
        clrf substeps
        clrf diff
        clrf temp


;***************************************** ADC ***********************************************
    read_paddle1:
        banksel ADCON0
        movlw 0b00010101 ; select RA5 as input channel (pg241)
        movwf ADCON0
        call run_adc
        return

    read_paddle2:
        banksel ADCON0
        movlw 0b00010001 ; select RA4 as input channel (pg241)
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

    increment_score1: ; increments score 1 by 1
        banksel s1
        incf s1, F
        return

    increment_score2: ; increments score 2 by 1
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
        call reset_ball
        bsf dir, 0 ; point towards paddle 2
        ; round reset game
        return

    display_scores:
        banksel s2 ; shift out the two score bytes to the seven segment displays
        movf s2, W ; load score 2 into working

        call get_segment
        call shift_out

        banksel s1
        movf s1, W
        call get_segment
        call shift_out

        banksel LATC
        bcf LATC, RCLK ; latch low
        nop
        bsf LATC, RCLK ; latch high
        nop 
        bcf LATC, RCLK ; latch low - latch both seven segments 

        return

    get_segment:
        brw
        retlw 0b00111111 ; 0
        retlw 0b00000110 ; 1
        retlw 0b01011011 ; 2
        retlw 0b01001111 ; 3
        retlw 0b01100110 ; 4
        retlw 0b01101101 ; 5
        retlw 0b01111101 ; 6
        retlw 0b00000111 ; 7
        retlw 0b01111111 ; 8
        retlw 0b01101111 ; 9

    shift_out:
        movwf temp ; store byte temporarily
        movlw 8
        movwf loop_counter ; send out 8 bytes
    
    bit_loop:
        banksel LATC
        bcf LATC, SER ;  clear serial data first
        btfsc temp, 7 ; check MSB, if 1, set SER to 1, otherwise leave as zero
        bsf LATC, SER ; set SER high if 1

        bsf LATC, SRCLK ; clock high
        nop
        bcf LATC, SRCLK ; clock low - push SER into chip

        rlf temp, F ; rotate left to shift next bit into MSB
        banksel loop_counter
        decfsz loop_counter, F ; loop 8 times to send all 8 bits
        goto bit_loop

        return



;************************************ ASSETS DRAWER *******************************************

    draw_p: ; all asset drawers assume cursor is loaded
        movlw p_1
        call send_data

        movlw p_2
        call send_data

        movlw p_3
        call send_data

        return

    draw_o:
        movlw o_1
        call send_data

        movlw o_2
        call send_data

        movlw o_3
        call send_data

        return

    draw_n:
        movlw n_1 
        call send_data

        movlw n_2
        call send_data

        movlw n_3
        call send_data

        movlw n_4
        call send_data

        return

    draw_g:
        movlw g_1
        call send_data

        movlw g_2
        call send_data

        movlw g_3
        call send_data

        return

    draw_s:
        movlw s_1
        call send_data

        movlw s_2
        call send_data

        movlw s_3
        call send_data

        return

    draw_t:
        movlw t_1
        call send_data

        movlw t_2
        call send_data

        movlw t_3
        call send_data

        return

    draw_a:
        movlw a_1
        call send_data

        movlw a_2
        call send_data

        movlw a_3
        call send_data

        return

    draw_r:
        movlw r_1
        call send_data

        movlw r_2
        call send_data

        movlw r_3
        call send_data

        return

    draw_e:
        movlw e_1
        call send_data

        movlw e_2
        call send_data

        movlw e_3
        call send_data

        return

    draw_1:
        movlw number_1_1
        call send_data

        movlw number_1_2
        call send_data

        movlw number_1_3
        call send_data

        return

    draw_2:
        movlw number_2_1
        call send_data

        movlw number_2_2
        call send_data

        movlw number_2_3
        call send_data

        return

    draw_exc:
        movlw symbol_exc
        call send_data

        return

    draw_left_arrow:
        movlw arrow_left_1
        call send_data

        movlw arrow_left_2
        call send_data

        movlw arrow_left_3 
        call send_data

        banksel loop_counter
        movlw 9
        movwf loop_counter
        movlw arrow_left_4_12
        movwf temp
        call loop_draw
        
        return

    draw_right_arrow:
        banksel loop_counter
        movlw 9
        movwf loop_counter
        movlw arrow_right_1_9
        movwf temp
        call loop_draw

        movlw arrow_right_10
        call send_data

        movlw arrow_right_11
        call send_data

        movlw arrow_right_12
        call send_data

        return

    draw_down_arrow:
        movlw arrow_down_1
        call send_data

        movlw arrow_down_2
        call send_data

        movlw arrow_down_3
        call send_data

        movlw arrow_down_4
        call send_data

        movlw arrow_down_5
        call send_data

        return

    draw_pong:
        ; draws the word pong given a loaded cursor
        call draw_p
        call draw_empty_2
        call draw_o
        call draw_empty_2
        call draw_n
        call draw_empty_2
        call draw_g
        call draw_empty_2
        call draw_exc

        return

    draw_start:
        ; draws the word start given a loaded cursor
        call draw_s
        call draw_empty_2
        call draw_t
        call draw_empty_2
        call draw_a
        call draw_empty_2
        call draw_r
        call draw_empty_2
        call draw_t

        return

    draw_reset:
        call draw_r
        call draw_empty_2
        call draw_e
        call draw_empty_2
        call draw_s
        call draw_empty_2
        call draw_e
        call draw_empty_2
        call draw_t

        return

    draw_p1:
        call draw_p
        call draw_empty_2
        call draw_1
        
        return
    
    draw_p2:
        call draw_p
        call draw_empty_2
        call draw_2
        
        return

    draw_empty_2: ; draw two empty bytes
        movlw empty
        call send_data

        movlw empty
        call send_data

        return

    loop_draw:
        movf temp, W ; movwf temp before calling loop_draw
        call send_data
        banksel loop_counter
        decfsz loop_counter, F
        goto loop_draw
        return
        
        

;**************************************** GAME ************************************************
    round_reset:
        return
    
    wait_start:
        return
    
    display_start:
        
        banksel cursor_page
        movlw 6
        movwf cursor_page ; PONG drawn on page 1 
        movlw 55
        movwf cursor_x
        call set_cursor
        call draw_pong

        banksel cursor_page
        movlw 4
        movwf cursor_page ; left arrow drawn on page 2 
        movlw 4
        movwf cursor_x
        call set_cursor 
        call draw_left_arrow 

        banksel cursor_page
        movlw 4
        movwf cursor_page
        movlw 23
        movwf cursor_x
        call set_cursor
        call draw_start

        banksel cursor_page
        movlw 4
        movwf cursor_page
        movlw 83
        movwf cursor_x
        call set_cursor
        call draw_reset

        banksel cursor_page
        movlw 4
        movwf cursor_page
        movlw 111
        movwf cursor_x
        call set_cursor
        call draw_right_arrow

        banksel cursor_page
        movlw 2
        movwf cursor_page
        movlw 30
        movwf cursor_x
        call set_cursor
        call draw_p1

        banksel cursor_page
        movlw 2
        movwf cursor_page
        movlw 91
        movwf cursor_x
        call set_cursor
        call draw_p2

        banksel cursor_page
        movlw 1
        movwf cursor_page
        movlw 33
        movwf cursor_x
        call set_cursor
        call draw_down_arrow

        banksel cursor_page
        movlw 1
        movwf cursor_page
        movlw 94
        movwf cursor_x
        call set_cursor
        call draw_down_arrow
        
        return
        
        banksel cursor_page
        clrf cursor_page
        banksel cursor_x
        ;clrf cursor_x
        movlw 50
        movwf cursor_x
        call set_cursor
        call draw_pong

        banksel cursor_page
        movlw 7
        movwf cursor_page
        banksel cursor_x
        clrf cursor_x
        call set_cursor
        call draw_pong

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
        movf x_vel, W
        addwf xS, F
        btfsc STATUS, C ; did it overflow?
        incf xF, F
        goto update_y

    ball_left:
        movf x_vel, W
        subwf xS, F
        btfss STATUS, C ; did it carry?
        decf xF, F
        goto update_y

    update_y:
        btfss dir, 1 ; 0 - up, 1 - down
        goto ball_up
        goto ball_down
    
    ball_up:

        movf y_vel, W
        subwf yS, F
        btfss STATUS, C ; did it carry?
        decf yF, F
        return

    ball_down:
        movf y_vel, W
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
        xorwf x_vel, W ; check if max speed reached for 2 substeps
        btfsc STATUS, Z
        goto transition_3 ; if so, transition to 3 substeps

        movlw 32 ; otherwise add 32 to speed
        addwf x_vel, F
        return

    transition_3:
        movlw 3
        movwf substep_speed
        movlw 170
        movwf x_vel
        return

    ramp_3:
        movlw 255
        xorwf x_vel, W
        btfsc STATUS, Z
        return

        movlw 22 ; increment by 22 instead of 32
        addwf x_vel, F

        btfss STATUS, C
        return ; if no carry occured we didn't overflow and become slow

        movlw 255
        movwf x_vel
        return

        movlw 255
        movwf x_vel

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
        movwf y_temp
        lsrf y_temp, F ; right shift
        lsrf y_temp, F ; right shift
        return
    clamp:
        movlw 5
        subwf y_temp, W 
        btfss STATUS, C
        goto clamp_low

        movlw 59
        subwf y_temp, W
        btfsc STATUS, C
        goto clamp_high
    
        movf y_temp, W
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

        btfsc yF, 7
        call top_bounce 

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

        clrf y_vel ; set y velocity to zero
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
        
        clrf y_vel ; set y velocity to zero
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
        movwf temp ; replace with brw? 
        
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
        clrf y_vel
        return

    offset_1:
        movf x_vel, W
        movwf y_vel ; move x_vel into y_vel
        
        lsrf y_vel, F ; divide by 4 (1/4)
        lsrf y_vel, F
        movf y_vel, W
        movwf y_temp

        lsrf y_vel, F ; divide by 32 (1/32)
        lsrf y_vel, F
        lsrf y_vel, F

        movf y_vel, W
        subwf y_temp, W ; 1/4 - 1/32 ~ 0.2 = 12º
        movwf y_vel
        return
    
    offset_2:
        movf x_vel, W
        movwf y_vel

        lsrf y_vel, F ; divide by 2 (1/2)
        movf y_vel, W
        movwf y_temp

        lsrf y_vel, F ; divide by 16 (1/16)
        lsrf y_vel, F
        lsrf y_vel, F

        movf y_vel, W
        subwf y_temp, W ; 1/2 - 1/16 ~ 0.45 = 24º
        movwf y_vel
        return

    offset_3:
        movf x_vel, W
        movwf y_vel

        lsrf y_vel, F ; divide by 2 (1/2)
        movf y_vel, W ; store 1/2 x_vel in working
        lsrf y_vel, F ; divided by 4 (1/4)
        addwf y_vel, F ; 1/2 + 1/4 = 3/4

        movf y_vel, W
        movwf y_temp ; y_temp storing 3/4 x_vel

        movf x_vel, W
        movwf y_vel

        lsrf y_vel, F ;divide by 32 (1/32)
        lsrf y_vel, F
        lsrf y_vel, F
        lsrf y_vel, F
        lsrf y_vel, F

        movf y_vel, W ; move 1/32 into working
        subwf y_temp, W ; 1/32 - 3/4 ~ 0.72 = 36º
        movwf y_vel
        return

    offset_4:
        movf x_vel, W
        movwf y_vel

        lsrf y_vel, F ; divide by 8 (1/8)
        lsrf y_vel, F
        lsrf y_vel, F

        movf x_vel, W
        addwf y_vel, F ; 1 + 1/8 ~ 1.1 = 48º
        return
    
    offset_5:
        movf x_vel, W
        movwf y_vel

        lsrf y_vel, F ; divide by 2 (1/2)
        movf y_vel, W ; store in working

        movf y_vel, W
        lsrf y_vel, F ; divide by 4 (1/4)
        addwf y_vel, F ; 1/2 + 1/4 = 3/4 x_vel

        movf x_vel, W
        addwf y_vel, F ; 1+3/4 ~ 1.73 = 60º
        return

    check_backwalls:
        btfsc xF, 7 ; did xF underflow
        goto p2_scores

        movf xF, W
        btfsc STATUS, Z
        goto p2_scores

        movlw 126
        subwf xF, W
        btfsc STATUS, C
        goto p1_scores

        return

;*************************************** SCREEN **********************************************
    setup_spi:
        ;left to defaults for the most part
        banksel SSP1CON1 ; synchronous serial port, (pg 317)
        ; bit 5 (SSPEN) = 1 enable serial port (pg 360)
        ;3-0 (SSPM) = 0000 SPI Master mode, clock = FOSC (32) / 4 = 8MHz (pg 360)
        ;rest of config bits as default (pg 317 - 5:0 bit reference)
        movlw 0b00100000
        movwf SSP1CON1

        banksel SSP1STAT
        ;bit 6 (CKE) = 1 - falling edge triggered (pg 359) 
        ;bit 7 (SMP) = 0 - input data sampled at middle of data output (pg 359) 
        movlw 0b01000000
        movwf SSP1STAT
        return

    spi_send:
        banksel SSP1BUF ; write byte to SPI Buffer from W
        movwf SSP1BUF
    
    wait_spi:
        banksel SSP1STAT
        btfss SSP1STAT, 0
        goto wait_spi
        
        banksel SSP1BUF
        movf SSP1BUF, W
        return

    send_command:
        banksel LATC ; write command from working to screen
        bcf LATC, OLED_DC; pull DC low to indicate command
        bcf LATC, OLED_CS ; pull CS low to select screen
        
        call spi_send
        
        banksel LATC
        bsf LATC, OLED_CS ; pull CS high to end transfer
        return
    
    send_data:
        banksel LATC ; write pixel data to screen
        bsf LATC, OLED_DC; pull DC high to indicate data
        bcf LATC, OLED_CS ; pull CS low to select screen

        call spi_send

        banksel LATC
        bsf LATC, OLED_CS
        return

    boot_sequence:
        banksel LATC ;
        
        bcf LATC, OLED_RS ; enable reset
        call wait10ms
        bsf LATC, OLED_RS ; disable reset

        movlw OLED_OFF
        call send_command

        movlw CLK_DIV
        call send_command

        movlw CLK_FRQ
        call send_command

        movlw OFFSET1 
        call send_command

        movlw OFFSET2
        call send_command

        movlw START_LINE
        call send_command

        movlw ENA_CPUMP1
        call send_command

        movlw ENA_CPUMP2
        call send_command

        movlw SET_ADDR_MODE 
        call send_command

        movlw PAGE_MODE
        call send_command

        movlw REMAP
        call send_command

        movlw SET_COM
        call send_command

        movlw SET_COM_CONFIG1 
        call send_command

        movlw SET_COM_CONFIG2
        call send_command

        movlw SET_CONT1
        call send_command

        movlw SET_CONT2
        call send_command

        movlw SET_PREC1
        call send_command

        movlw SET_PREC2
        call send_command

        movlw SET_VCOMH1
        call send_command

        movlw SET_VCOMH2
        call send_command

        movlw RES_RAM
        call send_command
        
        movlw SET_NORM
        call send_command

        movlw OLED_ON
        call send_command

        return


    set_cursor:
        banksel cursor_page ; load cursor page (binary 0-7)
        movf cursor_page, W ; to select a page, 0xB0 - 0xB7
        andlw 0b00000111 ; keep last three bits, and keeps the page data
        ;sublw 7 ; invert because the screen indexes pages 0-7 bottom to top weridly enough
        iorlw 0xB0 ; combine with base cursor page command
        call send_command ; send command to select page to screen

        banksel cursor_x
        movf cursor_x, W ; load bottom 4 bits for bottom column address
        andlw 0b00001111 ; keep last 4 bits to address the bottom four bits of the x value
        iorlw 0x00 ; combine with base command - redudnant = 0b00000000
        call send_command

        banksel cursor_x
        swapf cursor_x, W ; swap top 4 bits with bottom 4 bits for top column address
        andlw 0b00001111 ; keep last 4 bits for top four bits of the column address
        iorlw 0x10 ; combine with base command
        call send_command
        return
    
    get_bitmask: ; draw one pixel - ball
        ;  pass in y coordinate mod 8  - tells which pixel to be turned on, i.e 7 says turn on bit 7. 
        brw ; PC = PC + W - for example if PC = 3, skip to 3rd retlw
        retlw 0b00000001 ; change this back maybe?
        retlw 0b00000010
        retlw 0b00000100
        retlw 0b00001000
        retlw 0b00010000
        retlw 0b00100000
        retlw 0b01000000
        retlw 0b10000000
        
        
        
        
        
        
        

    render_ball:
        banksel old_xF
        movf old_xF, W
        movwf cursor_x ; move old x coordinate to cursor x - takes full 8 bits

        banksel old_yF
        movf old_yF, W
        movwf temp ; move to temp

        lsrf temp
        lsrf temp
        lsrf temp ; divide by 8 to get page
        
        movf temp, W
        movwf cursor_page

        call set_cursor ; set cursor with cursor_x and cursor_page
        movlw 0b00000000 ; send empty byte
        call send_data

        movf xF, W ; load new x value
        banksel cursor_x
        movwf cursor_x

        movf yF, W
        movwf temp
        
        lsrf temp
        lsrf temp
        lsrf temp ; divide by 8 to get page

        movf temp, W
        banksel cursor_page
        movwf cursor_page
        
        call set_cursor ; set cursor with x and page

        movf yF, W ; load y back into working
        andlw 0b00000111 ; mod with 0b0111 (number & (2^n - 1)) - equivalent of mod 8 - gives you the position on that page
        call get_bitmask ; get the corresponding bitmask 
        call send_data

        movf xF, W ; cache coordinates to erase next cycle
        banksel old_xF
        movwf old_xF

        movf yF, W
        banksel old_yF
        movwf old_yF

        return

    calc_paddle:
        movwf temp

        banksel cursor_page
        movwf cursor_page
        lsrf cursor_page, F ; calculate start page (y1 or y2 / 8)
        lsrf cursor_page, F
        lsrf cursor_page, F

        
        movf temp, W 
        andlw 0b00000111 ; calculate offset by doing mod 8 
        movwf temp ; temp holds required offset passes for shift_loop

        movlw 0b11111111 ; default mask with zero offset. mask 0 is full, mask 1 has remaining three bytes, and mask 2 has no bytes. - 11111111 (mask 0), 111 (mask 1), 0 (mask 2)
        banksel mask0
        movwf mask0
        
        movlw 0b00000111
        movwf mask1

        clrf mask2

        movf temp, F ; default mask if offset is zero
        btfsc STATUS, Z
        return

        shift_loop:
        ; decrement offset counter (temp) by shifting bits in mask to the left. 
        bcf STATUS, C ; clear CARRY
        banksel mask0
        rlf mask0, F ; rotate left, MSB dropped into C
        rlf mask1, F ; rotate left, C drops into LSB
        rlf mask2, F ; rotate left, C drops into LSB
        decfsz temp, F ; decrement till zero
        goto shift_loop

        return

    erase_paddle:
        ; set cursor_x store y in W
        movwf temp
            
        banksel cursor_page
        movwf cursor_page
        lsrf cursor_page, F ; find page by dividing by 8 
        lsrf cursor_page, F
        lsrf cursor_page, F

        call set_cursor
        movlw 0b00000000
        call send_data ; clear page 0
        movlw 0b00000000
        call send_data ; ssd1306 auto increments column address pointer

        banksel cursor_page
        incf cursor_page, F ; clear page 1
        call set_cursor ; resets cursor to register value for cursor_x
        movlw 0b00000000
        call send_data
        movlw 0b00000000
        call send_data 

        banksel cursor_page
        incf cursor_page, F ; clear page 2
        call set_cursor ; resets cursor to register value for cursor_x
        movlw 0b00000000
        call send_data
        movlw 0b00000000 ; send data changes working
        call send_data

        return

    draw_paddle:
        call calc_paddle

        call set_cursor
        banksel mask0 
        movf mask0, W ; load mask0 
        call send_data
        banksel mask0 ; in case loaded out of bank
        movf mask0, W
        call send_data ; auto increments cursor column, drawing a two wide paddle

        banksel cursor_page
        incf cursor_page, F
        call set_cursor ; increment page
        banksel mask1
        movf mask1, W ; load mask1
        call send_data
        banksel mask1
        movf mask1, W
        call send_data

        banksel cursor_page
        incf cursor_page, F
        call set_cursor
        banksel mask2
        movf mask2, W; load mask2
        call send_data
        banksel mask2
        movf mask2, W
        call send_data

        return

    render_paddles:
        banksel cursor_x
        movlw 1
        movwf cursor_x

        banksel old_y1
        movlw 5
        subwf old_y1, W ; old_y1 - 5 (to move reference from center to top pixel)
        call erase_paddle ; handles both columns

        banksel y1
        movlw 5
        subwf y1, W ; y1 - 5 (to move reference from center to top pixel)
        call draw_paddle

        banksel y1
        movf y1, W
        banksel old_y1
        movwf old_y1


        banksel cursor_x
        movlw 125
        movwf cursor_x

        banksel old_y2
        movlw 5
        subwf old_y2, W
        call erase_paddle

        banksel y2
        movlw 5
        subwf y2, W
        call draw_paddle

        banksel y2
        movf y2, W
        banksel old_y2
        movwf old_y2 ; cache used y coordinate to be erased later

        banksel y2
        movf y2, W
        banksel old_y2
        movwf old_y2

        return

    render_frame:
        ;call clear_screen
        call render_ball
        call render_paddles
        return
    clear_screen:
        banksel page_counter
        movlw 8 ; 8 pages to clear
        movwf page_counter
        call loop_clear_screen

        return

    loop_clear_screen:
        banksel page_counter
        movf page_counter, W
        decf page_counter, W
        call clear_page
        banksel page_counter
        decfsz page_counter, F
        goto loop_clear_screen
        return
        
    clear_page:
        banksel cursor_page
        movwf cursor_page ; pass the target page via working
        
        banksel cursor_x
        clrf cursor_x ; set cursor x to 0 to start
        call set_cursor


        movlw 128
        movwf x_counter
        call loop_clear_page ; send 128 empty bytes sequentially to clear entire page

        return

    loop_clear_page:
        banksel x_counter
        movlw empty
    
        call send_data
        banksel x_counter
        decfsz x_counter, F
        goto loop_clear_page
        return
        
;**************************************** STARTUP ********************************************
start:
    call set_frq
    call setup_ports
    call setup_pps
    call setup_spi
    call setup_adc
    call reset_paddles
    call full_reset_ball
    call clear_scores
    call clear_registers
    call boot_sequence 
    call clear_screen 
    ;call display_start  
    ;call clear_screen

    ;call temp_loop


    ;call wait1000ms ;wait
    ; wait for start button
    ; say starting
    ; wait 1s after start hit

    call wait1000ms
    call wait1000ms
    call wait1000ms
    call wait1000ms
    call wait1000ms
    

    goto main

    ;x1 = 1 - paddle 2px wide
    ;x2 = 126 - paddle 2px wide
    ;paddle is 11 px tall
        
;***************************************** MAIN LOOP *****************************************

main: 
    movf substep_speed, W ; load substep_speed into substep counter
    movwf substeps

    call update_paddle1
    call update_paddle2

    

    goto physics_loop

physics_loop:
    call update_ball
    call check_walls
    ;call paddle1_collision
    ;call paddle2_collision

    call check_backwalls
    call render_frame

    decfsz substeps, F
    goto physics_loop

    call wait10ms
    goto main

temp_loop:
    call update_paddle1
    call update_paddle2

    call render_paddles

    call wait10ms

    goto temp_loop

temp_loop2:
    call wait1000ms
    call clear_screen
    call display_start
    goto temp_loop2


    

;**************************************** INTERRUPTS *****************************************

isr:
    retfie ;return from interrupt
    ; have reset button call isr

end

