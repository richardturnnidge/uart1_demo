Agon Light UART1 Serial Input Demo

This simple z80 assembly demo shows the basics needed to read data from the UART1 serial port.

This demo takes potentiometer readings from games paddles via a Raspberry Pi Pico's ADC pins.

I chose the Pico as the voltage levels are 3.3v, the same as The Agon's and would not require any level shifting. The Pico also uses very little power and was just as economical as buying specific ADC chips.

The diagram shows the wiring. I made a small modification to the paddles as they had potentiometers with just two wires connected. I added a ground to provide a proper voltage divider.

If using a Pico, save the Python code as main.py and will will run when just provided with power.

The Pico sends a command byte, followed by a hex code of the value as it is not easy to send full byte values over serial.

In this example, a command 'R' is sent to indicate the Right potentiometer, followed by a value such as A6. The hex is then converted back to a single decimal byte and stored.

The demo code simply loops round until some data is available and then deals with it.

NOTE: The main.py python code runs on the Pico, the uart1_demo.bin runs on the Agon. The Agon's assembly source is the asm file!!
