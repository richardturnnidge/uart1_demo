from machine import Pin,UART, ADC
import time

# ------------------------------------------------------------
#
#    SETUP IO PORTS & DEFAULT VALUES
#
# ------------------------------------------------------------

uart = UART(1, baudrate=9600, tx=Pin(4), rx=Pin(5))
uart.init(bits=8, parity=None, stop=1)
led = Pin("LED", Pin.OUT)

potL = ADC(Pin(26)) # potentiometer input
potL_value = 0
old_potL_value = 0

potR = ADC(Pin(27)) # potentiometer input
potR_value = 0
old_potR_value = 0

btnL = Pin(16, mode=Pin.IN, pull=Pin.PULL_UP) # button input
btnL_state = 0
old_btnL_state = 0

btnR = Pin(17, mode=Pin.IN, pull=Pin.PULL_UP) # button input
btnR_state = 0
old_btnR_state = 0

# ------------------------------------------------------------
#
#    MAIN LOOP
#
# ------------------------------------------------------------

while True:

#   --- LEFT BUTTON ------------------------------------------

    btnL_state = btnL.value()
    
    if btnL_state != old_btnL_state:
        old_btnL_state = btnL_state # store old value to check next time

        toSend="0x%02X" % btnL_state # convert to hex format
        print("L btn - " + toSend) # just to see it is working
        
        sendA = toSend[2] # split into two hex bytes
        sendB = toSend[3]
        
        uart.write("l") # send control code
        uart.write(sendB) # send LSB
        uart.write(sendA) # send MSB
        led.toggle() # visual feedback that dat is being processed
        
 #   --- RIGHT BUTTON ------------------------------------------
 
    btnR_state = btnR.value()
    
    if btnR_state != old_btnR_state:
        old_btnR_state = btnR_state # store old value to check next time

        toSend="0x%02X" % btnR_state # convert to hex format
        print("R btn - " + toSend) # just to see it is working
        
        sendA = toSend[2] # split into two hex bytes
        sendB = toSend[3]

        uart.write("r") # send control code
        uart.write(sendB) # send LSB
        uart.write(sendA) # send MSB  
        led.toggle() # visual feedback that dat is being processed
        
#   --- LEFT DIAL ------------------------------------------
    
    potL_value = int(potL.read_u16()/256) # give 0-255 read value, 0-65535 across voltage range 0.0v - 3.3v
                                            
    if abs(potL_value - old_potL_value) > 2: # needs to change more than 2 to avoid jutter
        toSend="0x%02X" % potL_value # convert to hex format
        
        print("L pot - " + toSend) # just to see it is working
        
        sendA= toSend[2] # split into two hex bytes
        sendB= toSend[3]
        
        uart.write("L") # send control code
        uart.write(sendB) # send LSB
        uart.write(sendA) # send MSB
        
        old_potL_value  = potL_value # store old value to check next time
        led.toggle() # visual feedback that dat is being processed

#   --- RIGHT DIAL ------------------------------------------

    potR_value = int(potR.read_u16()/256) # give 0-255 read value, 0-65535 across voltage range 0.0v - 3.3v

    if abs(potR_value - old_potR_value) > 2: # needs to change more than 2 to avoid jutter
        toSend="0x%02X" % potR_value # convert to hex format
    
        print("R pot - " + toSend) # just to see it is working
        
        sendA= toSend[2] # split into two hex bytes
        sendB= toSend[3]

        uart.write("R") # send control code
        uart.write(sendB) # send LSB
        uart.write(sendA) # send MSB
        
        old_potR_value  = potR_value # store old value to check next time
        led.toggle() # visual feedback that dat is being processed
        
    time.sleep(0.01) # short delay then repeat
    
# ------------------------------------------------------------
# END
