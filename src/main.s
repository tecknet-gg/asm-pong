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

;**************************************** BUTTONS *****************************************

START equ 5
RST equ 6

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

s_1 equ 0b00100100 ; Letter S - 3 wide
s_2 equ 0b01010100
s_3 equ 0b01001000

t_1 equ 0b01000000 ; Letter T - 3 wide
t_2 equ 0b01111100
t_3 equ 0b01000000

a_1 equ 0b01111100 ; Letter A - 3 wide
a_2 equ 0b01010000
a_3 equ 0b01111100 

r_1 equ 0b01111100 ; Letter R - 3 wide
r_2 equ 0b01011000
r_3 equ 0b00110100

e_1 equ 0b01111100 ; Letter E - 3 wide
e_2 equ 0b01010100
e_3 equ 0b01000100

m_1 equ 0b01111100
m_2 equ 0b00100000
m_3 equ 0b00010000
m_4 equ 0b00100000
m_5 equ 0b01111100

v_1 equ 0b01111000
v_2 equ 0b00000100
v_3 equ 0b01111000

w_1 equ 0b01110000
w_2 equ 0b00001100
w_3 equ 0b00010000
w_4 equ 0b00001100
w_5 equ 0b01110000

i_1 equ 0b01000100
i_2 equ 0b01111100
i_3 equ 0b01000100

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
    goto reset_isr

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
    countdown_timer: ds 1 ; countdown timer for countdown subroutine

    ;score: ds 1 ; bit 0 -> 3 - player 1, bit 4 -> 7 maybe?

    

    ;16/16 common bytes used

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
    x_counter: ds 1 ; counter for x value for page addressing

    loop_counter: ds 1 ; yet another temporary counter

    buzzer_timer: ds 1 ; store buzzer time - read every main loop
 

;***************************************** SUBROUTINES ***************************************

psect code, class=CODE, space=0, delta=2
;******************************************** WAIT *******************************************
    wait125us: ;modified template code to work at 32Mhz
        movlw 199
        banksel WAIT125
        movwf WAIT125 ; ~125us at 32Mhz -> 199 * 625ns = 124375ns
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
        movlw 0b00110000 ; set RA4 and RA5 to input - potentiometers
        movwf TRISA

        banksel TRISB
        movlw 0b01100000 ; set RB4 and RB5 to input - buttons
        movwf TRISB

        banksel TRISC
        clrf TRISC
    
        banksel ANSELA
        movlw 0b00110000 ; set pots on RA4 and RA5 to analog - potentiometers
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
        banksel PPSLOCK ; required sequence (pg.161)
        movlw 0x55
        movwf PPSLOCK
        movlw 0xAA
        movwf PPSLOCK 
        bcf PPSLOCK, 0 ; unlock PPS

        banksel RC3PPS
        movlw 0b00011000 ;11000 = SCK1/SCL1 (pg 163) - set RC3 to SCK for Screen
        movwf RC3PPS 

        banksel RC4PPS
        movlw 0b00011001 ;11001 = SDO1/SDA1 (pg 163) - Serial Data Out for screen
        movwf RC4PPS

        banksel PPSLOCK ; required sequence (pg.161)
        movlw 0x55
        movwf PPSLOCK
        movlw 0xAA
        movwf PPSLOCK
        bsf PPSLOCK, 0 ; lock PPS

        return

    setup_adc:
        banksel ADCON1 ; ADCON1 - setup ADC, ADCON0 - use ADC
        movlw 0b01110000
        movwf ADCON1 ; left justified, dedicated RC oscillator, VREFs connected to VDD and VSS (pg 240, 241, 245) - left as defaults

        banksel ADCON0
        bsf ADCON0, 0 ; turn on ADC (pg 244)
        return
    
    reset_paddles:
        movlw 32; set y1 and y2 of the paddles to 32
        movwf y1
        movwf y2
        banksel old_y1
        movwf old_y1 ; initialise old coordiantes to 32 too
        movwf old_y2
    full_reset_ball:
        call clear_screen
        
        movlw 64
        movwf xF ; set x coordinate
        banksel old_xF
        movwf old_xF

        movlw 32
        movwf yF ; set y coordinate
        banksel old_yF
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

    reset_ball: ; retain prior direction and speed - reset ball to the middle
        call clear_screen
        
        movlw 64
        movwf xF
        banksel old_xF
        movwf old_xF ; save old_xF

        movlw 32
        movwf yF
        banksel old_yF
        movwf old_yF

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
        banksel s1 ; just clear the scores
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
        movlw 0b00010101 ; select RA5 as input channel (pg241) - pot 1
        movwf ADCON0
        call run_adc
        return

    read_paddle2:
        banksel ADCON0 ;
        movlw 0b00010001 ; select RA4 as input channel (pg241) - pot 2
        movwf ADCON0
        call run_adc
        return

    run_adc:
        call wait125us ; wait for acquisition (pg241)
        banksel ADCON0
        bsf ADCON0, 1 ; 1st bit is ADC status
        goto wait_adc ; wait for adc to finish

    wait_adc:
        banksel ADCON0
        btfsc ADCON0, 1; test to see if conversion is done
        goto wait_adc; go back to btsf if not done
        banksel ADRESH 
        movf ADRESH, W; get the 8 upper bits and return to working
        return

;**************************************** SCORE ***********************************************
    check_score:
        banksel s1
        movf s1, W
        xorlw 9 ; check if player 1 has 9 points, if so Z flag is set
        btfsc STATUS, Z ; read the Z status bit
        goto p1_wins ; handler for p1 wins

        banksel s2
        movf s2, W
        xorlw 9 ; check if player 2 has 9 points, if so Z flag is set
        btfsc STATUS, Z ; read the Z status bit
        goto p2_wins ; handler for p2 wins

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
        call increment_score1 ; increment player 1 score
        call display_scores ; update seven segment displays
        bcf dir, 0
        goto round_reset_handler ; reset game systems for new round
 
    p2_scores:
        call increment_score2
        call display_scores
        bcf dir, 0  
        goto round_reset_handler

    display_scores:
        banksel s2 ; shift out the two score bytes to the seven segment displays
        movf s2, W ; load score 2 into working

        call get_segment ; branching logic to get the segment byte to shift out
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
        brw ; branch with respect to w - enhanced mid range pics only
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
        banksel loop_counter
        movwf loop_counter ; send out 8 bits

        goto bit_loop ; shift out each bit one by one
    
    bit_loop:
        banksel LATC
        bcf LATC, SER ; clear serial data first
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

    draw_p: ; all asset drawers assume cursor is loaded - relies on the ssd1306 auto incrementing x address after each byte is sent
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

    draw_m:
        movlw m_1
        call send_data

        movlw m_2
        call send_data

        movlw m_3
        call send_data

        movlw m_4
        call send_data

        movlw m_5
        call send_data

        return

    draw_v:
        movlw v_1
        call send_data

        movlw v_2
        call send_data

        movlw v_3
        call send_data
        
        return

    draw_w:
        movlw w_1
        call send_data

        movlw w_2
        call send_data

        movlw w_3
        call send_data

        movlw w_4
        call send_data

        movlw w_5
        call send_data

        return

    draw_i:
        movlw i_1
        call send_data

        movlw i_2
        call send_data

        movlw i_3
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
        movlw 9 ; draw the same byte pattern 9 times
        movwf loop_counter
        movlw arrow_left_4_12
        movwf temp
        call loop_draw
        
        return

    draw_right_arrow:
        banksel loop_counter
        movlw 9 ; draw the same byte pattern 9 times
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
        call draw_empty_1
        call draw_t
        call draw_empty_1
        call draw_a
        call draw_empty_1
        call draw_r
        call draw_empty_1
        call draw_t

        return

    draw_reset:
        call draw_r
        call draw_empty_1
        call draw_e
        call draw_empty_1
        call draw_s
        call draw_empty_1
        call draw_e
        call draw_empty_1
        call draw_t

        return

    draw_press:
        call draw_p
        call draw_empty_1
        call draw_r
        call draw_empty_1
        call draw_e
        call draw_empty_1
        call draw_s
        call draw_empty_1
        call draw_s

        return

    draw_game:
        call draw_g
        call draw_empty_1
        call draw_a
        call draw_empty_1
        call draw_m
        call draw_empty_1
        call draw_e
        call draw_empty_1

        return

    draw_over:
        call draw_o
        call draw_empty_1
        call draw_v
        call draw_empty_1
        call draw_e
        call draw_empty_1
        call draw_r
        call draw_empty_1

        return

    draw_wins:
        call draw_w
        call draw_empty_1
        call draw_i
        call draw_empty_1
        call draw_n
        call draw_empty_1
        call draw_s
        call draw_empty_1

        return

    draw_p1:
        call draw_p
        call draw_empty_1
        call draw_1
        
        return
    
    draw_p2:
        call draw_p
        call draw_empty_1
        call draw_2
        
        return

    draw_empty_2: ; draw two empty bytes
        movlw empty
        call send_data

        movlw empty
        call send_data

        return

    draw_empty_1: ; draw one empty byte
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
    round_reset_handler:
        call check_score ; check to see if either player got 9 points
        call reset_ball ; reset the ball
        call render_frame ; render the frame - probably redundant
        call wait_1s ; wait a second before displaying the countown so score is visible
        movlw 3 ; set countdown timer to 3
        call run_countdown ; run the countdown
        call display_scores ; update the seven segment displays back to the score
        goto main ; resume game
    
    display_start: ; asseble the assets to draw the score screen
        
        banksel cursor_page
        movlw 5
        movwf cursor_page ; PONG drawn on page 2
        movlw 55
        movwf cursor_x
        call set_cursor
        call draw_pong

        banksel cursor_page
        movlw 3
        movwf cursor_page ; press drawn on page 3
        movlw 43
        movwf cursor_x
        call set_cursor
        call draw_press

        banksel cursor_page
        movlw 3
        movwf cursor_page ; start drawn on page 3
        movlw 66
        movwf cursor_x
        call set_cursor
        call draw_start

        banksel cursor_page
        movlw 3
        movwf cursor_page
        movlw 86
        movwf cursor_x
        call set_cursor
        call draw_exc

        return

    draw_game_over: ; basically the ame as the start screen, but with the game over screen - used as the base ending screen
        call clear_screen

        banksel cursor_page
        movlw 6
        movwf cursor_page
        movlw 46
        movwf cursor_x
        call set_cursor
        call draw_game

        banksel cursor_page
        movlw 6
        movwf cursor_page
        movlw 67
        movwf cursor_x
        call set_cursor
        call draw_over

        banksel cursor_page
        movlw 6
        movwf cursor_page
        movlw 83
        movwf cursor_x
        call set_cursor
        call draw_exc

        banksel cursor_page
        movlw 4
        movwf cursor_page
        movlw 62
        movwf cursor_x
        call set_cursor
        call draw_wins

        banksel cursor_page
        movlw 2
        movwf cursor_page
        movlw 44
        movwf cursor_x
        call set_cursor
        call draw_press

        banksel cursor_page
        movlw 2
        movwf cursor_page
        movlw 67
        movwf cursor_x
        call set_cursor
        call draw_reset
        
        return

    display_win1: ;  player specific win screen - can probably be combined with a paramater to save space but oh well
        call clear_screen
        call draw_game_over

        banksel cursor_page
        movlw 4
        movwf cursor_page
        movlw 51
        movwf cursor_x
        call set_cursor
        call draw_p1

        return
        
    display_win2: ; same as before, but p2 instead of p1
        call clear_screen
        call draw_game_over

        banksel cursor_page
        movlw 4
        movwf cursor_page
        movlw 51
        movwf cursor_x
        call set_cursor
        call draw_p2

        return

    p1_wins: ; win handler for player 1 
        call reset_paddles
        call reset_ball
        call display_win1
        call wait_start_press
        goto game_init

    p2_wins: ; win handler for player 2 - copy of p1_wins but routes to display_win2
        call reset_paddles
        call reset_ball
        call display_win2
        call wait_start_press
        goto game_init
;**************************************** BALL ************************************************
    update_ball: ; main entry point for ball updates
        btfsc dir, 0 ; 0 - left, 1 - right, check direction and branch accordingly
        goto ball_right 
        goto ball_left
    
    ball_right:
        movf x_vel, W
        addwf xS, F ; add sub pixel velocity to sub pixel position - x only
        btfsc STATUS, C ; did it overflow - if so add one to full pixel position
        incf xF, F
        goto update_y

    ball_left:
        movf x_vel, W
        subwf xS, F ; subtract sub pixel velocity from sub pixel position - x only
        btfss STATUS, C ; did it carry - if so subtract one from full pixel position
        decf xF, F
        goto update_y

    update_y: ; main entry point to update the ball's y position
        btfss dir, 1 ; 0 - up, 1 - down, check direction and branch accordingly
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

    check_collisions: ; a bit misleading - checks to see if collisions passes threshold to make ball faster
        
        incf collisions, F ; update collision count    
        call sound_paddle ; centralised sound call for paddle collisions - attempted putting it the router, but this is more elegant

        movlw T ; load threhold (6)
        xorwf collisions, W ; check if number of collisions is equal to threshold
        btfss STATUS, Z ; if equal, Z is set (skip), otherwise return
        return
        
        clrf collisions ; reset collision counter
        call increment_velocity ; if equal to threshold, increment speed, otherwise return
        return

    increment_velocity: ; main entry point for velocity ramping
        movlw 2 ; check substep speed - if already 3, skip to ramp_3 as that handles that substep layer (see canvas for more details)
        xorwf substep_speed, W
        btfsc STATUS, Z 
        goto ramp_2 ; if 2 substeps, use the substep 2 ramp
        goto ramp_3 ; if 3 substeps, use the substep 3 ramp
        
    ramp_2:
        movlw 224
        xorwf x_vel, W ; check if max speed reached for 2 substeps (maxed out at 224)
        btfsc STATUS, Z
        goto transition_3 ; if maxed, transition to 3 substeps

        movlw 32 ; otherwise add 32 to speed (approximation but close enough)
        addwf x_vel, F
        return

    transition_3:
        movlw 3
        movwf substep_speed
        movlw 170
        movwf x_vel
        return

    ramp_3:
        movlw 255 ; if 255, don't change - speed saturate (~0.6s between paddles)
        xorwf x_vel, W
        btfsc STATUS, Z
        return

        movlw 22 ; increment by 22 instead of 32 - 3 substeps mean each substep is quicker, so increment by less to keep speed progression close to linear
        addwf x_vel, F

        btfss STATUS, C
        return ; if no carry occured we didn't overflow and become very slow
        movlw 255 ; if carried - overflowed, clamping to max value (just in case, should never hit this with current values)
        movwf x_vel
        return
    

;************************************** PADDLE ADC ********************************************
    update_paddle1:
        call read_paddle1 ;  adc on paddle 1
        
        call scale_paddle ; scale paddles to 64 tall
        call clamp ; clamp values between 5-59 (so it doesn't go off screen)
        
        banksel y1 ; store working into y1 
        movwf y1
        return
    
    update_paddle2:
        call read_paddle2 ; same as paddle 1 but for paddle 2
        
        call scale_paddle
        call clamp

        banksel y2 
        movwf y2
        return

    scale_paddle:
        movwf y_temp
        lsrf y_temp, F ; right shift
        lsrf y_temp, F ; right shift ; divide y by 4 (256/4 gives a range of 64)
        return

    clamp:
        movlw 5 ; if smaller than 5, clamp to 5
        subwf y_temp, W 
        btfss STATUS, C
        goto clamp_low

        movlw 59 ; if greater than 59, clamp to 59
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
    check_walls: ; main entry point for wall collision checks checks ceiling an floor (walls is also a bit misleading)
        call check_top
        call check_bottom
        return

    check_top:
        btfsc dir, 1
        return ; skip collision if moving down

        movf yF, W
        btfsc STATUS, Z ; if zero, call top_bounce
        goto top_bounce

        btfsc yF, 7 ; check for underflow - if it decrements below 0 and becomes a number bigger than 128
        goto top_bounce
        return

    check_bottom:
        btfss dir, 1
        return ; skip collision if moving up
        
        movlw 63
        subwf yF, W ; W = yF - 63
        btfsc STATUS, C ; yF>= 63 -> C=1
        goto bottom_bounce
        return
        
    
    top_bounce:
        bsf dir, 1 ; invert direction if it hits the ceiling
        movlw 0
        movwf yF ; clamp yF to 0
        call sound_wall ; play wall sound
        return
        
    bottom_bounce: ; also invert direction if it hits the floor
        bcf dir, 1
        movlw 63
        movwf yF ; clamp yF to 63
        call sound_wall 
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
        goto top_paddle1 ; if yF<y1, ball hit top of paddle
        goto bottom_paddle1 ; if yF>y1, ball hit bottom of paddle
        

    top_paddle1: ; handler for if is above the center of the paddle
        movf yF, W ;convert value to positive
        subwf y1, W
    
        movwf diff
        sublw 5 ; L - W = 5 - diff
        btfss STATUS, C ; diff>5, carry=0, ball missed
        return

        bsf dir, 0
        bcf dir, 1

        movlw 3
        movwf xF ; clamp ball to coordinate of 3
        
        call check_collisions ; check to see if ball should speed up

        movf diff, W ; pass distance to the router
        goto offset_router ; sets the y speed based on precomputed angle offsets depending on collision region to simulate different reflection angles

    middle_paddle1: ; handler for if it hits the center of the paddle
        bsf dir, 0
        
        movlw 3
        movwf xF ; clamp to coordinate 3

        call check_collisions

        clrf y_vel ; set y velocity to zero
        return

    bottom_paddle1: ; handler if it is below the center of the paddle
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
        movwf temp ; 
        ; could be looped, but would probably take more lines
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

    ; offset handlers assume preset directions (particularly y) - sets the value of y velocity based on a ratio to achieve specific angles
    ; if angle θ targeted, tan(θ) = y_vel/x_vel, so y_vel = tan(θ) * x_vel
    ; tan(θ) is precomputed, then approximated by using the sum of fractions with denominator to the power of 2 (1/2^n) to get past the lack of multiplication/division instructions
    ; the approximations are close enough - they are as follow:

    offset_0:
        clrf y_vel ; zero y velocity - stright reflection
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

    check_backwalls: ; entry point to check back wall collisions for scoring

        btfss dir, 0
        goto check_backwall1        
        goto check_backwall2


    check_backwall1:
        movf xF, W
        btfsc STATUS, Z ; if == 0, p2 scores
        retlw 2
        btfsc xF, 7 ; xF >=128 - has underflown
        retlw 2
        retlw 0 ; status instead of routing to update score due to stack overflow

    check_backwall2:
        movf xF, W ; xF >=127 return
        sublw 127
        btfss STATUS, C
        retlw 1 ; status instead of routing to update score due to stack overflow
        retlw 0
    

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
        call wait10ms ; nop was too fast
        bsf LATC, OLED_RS ; disable reset

        ; i don't rememeber what half of these commands do, pulled for the ssd1306 datasheet
        ; only thing to note is that it sets it to page address mode instead of horizontal addressing (would require a full frame buffer - (128x64)/8 = 1024 bytes of RAM = 50% of total RAM) 
        ; side note final project took up 1.8% of RAM - plenty of overhead for a full page buffer

        ; page addressing mode splits the 128x64 pixel screen into 8 vertical pages (each 128x8 pixels)
        ; to draw on the screen you select a page (0-7), then set an x value (0-127), and then you pass a byte for those 8 pixels at (x, page), and that is rendered

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
        retlw 0b00000001 
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
        
        ; the paddle being 11 pixels tall, and pages being 8 pixels tall means the paddle is a massive inconvenience (but an 8 pixel paddle looks too small)
        ; to get around it, we have 3 masks, one for each page that it could take up
        ; we get the top pixel of the paddle (by subtracting 5 from the center y coordinate)
        ; then we divide by 8 to get the page, and mod 8 to get its location on the page (for example 43 would be page 5, offset 3 - offset meaning 3rd pixel on that page)
        ; the masks default to the values of 0b11111111, 0b00000111 and 0b00000000. thats read LSB to MSB, mask0 to mask2. 
        ; to get the approprimate masks, we shif the masks left by the offset, and then we draw each mask at the corresponding pages and x value. 

        ; for y coordinate of 43, it would be page 5, offset 3, so masks would be shifted thrice to 0b00011111, 0b00011111 and 0b00000000. mask0 - page 5, mask1 - page 6, mask2 - page 7
    
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

        clrf mask2 ; 0b00000000

        movf temp, F ; default mask if offset is zero
        btfss STATUS, Z
        goto shift_loop
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

;**************************************** BUZZER ********************************************

    buzzer_off: ; latch the buzzer off
        banksel LATB
        bcf LATB, 4
        return
    
    buzzer_on: ; latch the buzzer on
        banksel LATB
        bsf LATB, 4
        return
    
    process_audio:
        banksel buzzer_timer ; buzzer_timer stores number of cycles to keep buzzer on for, process_audio called once every main loop, and updates the buzzer state
        movf buzzer_timer, W
        btfsc STATUS, Z
        goto buzzer_off
        decf buzzer_timer, F
        call buzzer_on
        return

    ; different sounds load different values into buzzer_timer
    ; could explore using pwm to generate different frequencies for more complex sounds

    sound_wall:
        movlw 2
        banksel buzzer_timer
        movwf buzzer_timer
        return

    sound_paddle:
        movlw 2
        banksel buzzer_timer
        movwf buzzer_timer

    sound_score:
        movlw 5
        banksel buzzer_timer
        movwf buzzer_timer
        return
    

;**************************************** BUTTONS ********************************************
    wait_start: ; waits for the start button to be pressed - deprecated
        banksel PORTB
        btfsc PORTB, START ; check RB5 - active low
        goto button_unpressed
        goto button_pressed
    
    button_unpressed:
        call buzzer_off
        goto wait_start

    button_pressed:
        call buzzer_on 
        goto wait_start

    wait_start_press: ; waits for start to be pressed whilst also letting the paddle move around making it more fun
        
        call update_paddle1
        call update_paddle2
        call render_paddles
        call wait10ms
    
        banksel PORTB
        btfsc PORTB, START
        goto wait_start_press

        call buzzer_on
        call wait100ms
        call buzzer_off
        call wait10ms
        return
    
    wait_button_release: ; not used
        banksel PORTB
        btfss PORTB, START
        goto wait_button_release
        call wait10ms
        return

;**************************************** STARTUP ********************************************
start:
    call set_frq ; all the setup functions
    call setup_ports
    call setup_pps
    call setup_spi
    call setup_adc
    call reset_paddles
    call full_reset_ball
    call clear_scores
    call clear_registers
    call buzzer_off
    call boot_sequence 

    banksel IOCBN ; interrupt on change PORTB - negative edge register (RST is active low - enable interrupt on falling edge)
    bsf IOCBN, RST

    banksel PIE0 ; peripheral interrupt enable register (pg 101)
    bsf PIE0, 4 ; interrupt on change interrupt enable (pg 101)

    banksel INTCON
    bsf INTCON, 6 ; enable peripherial interrupts (pg 100)
    bsf INTCON, 7 ; global interrupt enable (pg 100)
    
    goto game_init

game_init:
    call clear_scores ; game state initialisation
    call clear_screen
    call display_start
    call display_scores
    call wait_start_press
    call full_reset_ball
    call render_frame
    movlw 5
    call run_countdown
    call display_scores
    goto main


    ; wait for start button
    ; say starting
    ; wait 1s after start hit


    ;x1 = 1 - paddle 2px wide
    ;x2 = 126 - paddle 2px wide
    ;paddle is 11 px tall

;***************************************** COUNTDOWN *****************************************

run_countdown:
    movwf countdown_timer ; W holds the upper bound when called
    goto countdown_loop

countdown_loop: ; performs the countdown whilst letting the paddles move - keep in theme with the start also letting you move paddles - also prevents the paddles from snapping to position at game start
    
    call update_paddle1
    call update_paddle2
    call render_paddles

    movf countdown_timer, W
    call get_segment
    call shift_out

    movf countdown_timer, W
    call get_segment
    call shift_out

    banksel LATC
    bcf LATC, RCLK 
    nop
    bsf LATC, RCLK
    nop
    bcf LATC, RCLK

    call wait_1s

    decfsz countdown_timer, F
    goto countdown_loop
    return

    wait_1s: 
        movlw 100
        banksel loop_counter
        movwf loop_counter
        goto countdown_paddle_loop

    countdown_paddle_loop:
        call update_paddle1
        call update_paddle2
        call render_paddles
        call process_audio
        call wait10ms
        banksel loop_counter
        decfsz loop_counter, F
        goto countdown_paddle_loop
        return
    
        
;***************************************** MAIN LOOP *****************************************

main: 
    movf substep_speed, W ; load substep_speed into substep counter
    movwf substeps

    call update_paddle1
    call update_paddle2
    call buzzer_off


    goto physics_loop

physics_loop:
    call update_ball
    call check_walls
    call paddle1_collision
    call paddle2_collision

    call check_backwalls
    movwf temp

    movlw 0 ; read status flag - 0 = no score, 1 = p1 scored, 2 = p2 scored - status flag because stack overflow with the gotos during backwall collision branching
    xorwf temp, W
    btfss STATUS, Z 
    call sound_paddle

    movlw 1
    xorwf temp, W
    btfsc STATUS, Z ; if set W = temp
    call sound_score
    goto p1_scores

    movlw 2
    xorwf temp, W
    btfsc STATUS, Z ; if set W = temp
    call sound_score
    goto p2_scores

    call render_frame

    decfsz substeps, F
    goto physics_loop

    call process_audio ; called once every physics loop - actually a bug now that i comment - it should be once every main loop, makes the sound dependent on ball speed
    call wait10ms
    goto main

temp_loop: ; temporary testing loops
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

reset_isr:  
    banksel IOCBF ; interrupt on change PORTB - flag register (pg176)
    movf IOCBF, W ; move to working
    btfsc STATUS, Z ; if no interrupt flag, return 
    retfie
    clrf IOCBF ; clear interrupt flag
    banksel IOCAF ; 
    ;clrf IOCAF ; get rid of this
    call buzzer_on ; beep buzzer
    call wait100ms
    call buzzer_off
    reset ; reset PIC (pg 480)

end   

