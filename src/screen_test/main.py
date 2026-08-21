from machine import Pin
import time

# Now using GP15 (Physical Pin 20)
buzzer = Pin(15, Pin.OUT)


# Beep 3 times
for _ in range(100):
    buzzer.value(1)   
    time.sleep(0.2)
    buzzer.value(0)  
    time.sleep(0.2)

