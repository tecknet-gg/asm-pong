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
CONFIG LVP = OFF

;CONFIG 4
CONFIG CP = OFF
CONFIG CPD = OFF

#include <xc.inc>

;RESET VECTOR
psect resetVec, class=CODE, space=0, delta=2, abs
org 0x0000
    goto start


;INTERUPT VECTOR
psect intVec, class=CODE, space=0, delta=2, abs
org 0x0004
    goto isr

psect register, class=COMMON, space=1; pg(30, 47sg). ds reserves 1 byte. COMMON has 16 bytes accessible independent of banks

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

WAIT1: ds 1;
WAIT125: ds 1;
WAIT10: ds 1;
wait100: ds 1;
wait1000: ds 1;


psect code, class=CODE, space=0, delta=2

wait125us:
    movlw 199
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
    movwf WAIT1;
    loop1ms:
        call wait125us; 2
        decfsz WAIT1, F ;1
        goto loop1ms; 2
    return; 2

wait10ms:
    movlw 10
    movwf WAIT10;
    loop10ms:
        call wait1ms; 2
        decfsz WAIT, F ;1
        goto loop10ms; 2
    return; 2

wait100ms:
    movlw 10
    movwf WAIT100;
    loop100ms:
        call wait1ms; 2
        decfsz WAIT100, F ;1
        goto loop100ms; 2
    return; 2

wait1000ms:
    movlw 10
    movwf WAIT1000;
    loop1000ms:
        call wait100ms; 2
        decfsz WAIT1000, F ;1
        goto loop1000ms; 2
    return; 2


    start:


isr:
    retfie ;return from interrupt

end
