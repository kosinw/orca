#!/usr/bin/env python3
import struct
import sys
import serial
import time

PORT = "/dev/cu.usbserial-8874292302161"
BAUDRATE = 3000000

if __name__ == "__main__":
    if len(sys.argv) < 2:
        exit()

    input_file = sys.argv[1]

    with open(input_file, 'rb') as f:
        binary_data = f.read()

    chunks = [binary_data[i:i+4] for i in range(0, len(binary_data), 4)]

    print(f"sending '{input_file}' to orca computer...")

    with serial.Serial(PORT, BAUDRATE) as uart:
        for i in range(len(chunks)):
            addr = struct.pack("<I", i*4)
            data = chunks[i].ljust(4, b"\x00")
            print(f"addr={addr[::-1].hex()},data={data[::-1].hex()}")
            message = b"".join([b"W", addr, data, b"\r\n"])
            uart.write(message)
            time.sleep(0.01)


    print("done!")
