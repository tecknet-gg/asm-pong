from machine import Pin, SPI
import ssd1306
import time

width = 128
height = 64

spi = SPI(0, baudrate=10_000_000, sck=Pin(18), mosi=Pin(19))

dc = Pin(16)
rst = Pin(20)
cs = Pin(17)

oled = ssd1306.SSD1306_SPI(width, height, spi, dc, rst, cs)

counter = 0

while True:
    oled.fill(0)

    oled.rect(0, 0, 128, 64, 1)
    oled.text("Hi!", 5, 5)
    oled.show()

    counter += 1
    time.sleep(1)