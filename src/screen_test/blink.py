from machine import Pin
import time
while True:
    led = Pin(25, Pin.OUT)
    led.on()
    time.sleep(10)
    led.o