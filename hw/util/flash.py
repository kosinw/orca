#!/usr/bin/env python3
import struct
import sys
import serial

PORT = "/dev/cu.usbserial-8874292302161"
BAUDRATE = 3000000

if __name__ == "__main__":
    if len(sys.argv) < 2:
        exit()

    input_file = sys.argv[1]

    with open(input_file, 'rb') as f:
        binary_data = f.read()

    chunks = [binary_data[i:i+4] for i in range(0, len(binary_data), 4)]

    with serial.Serial(PORT, BAUDRATE) as uart:
        for i in range(len(chunks)):
            addr = struct.pack("<I", i)
            data = chunks[i]
            uart.write(b"W")
            uart.write(addr)
            uart.write(data)
