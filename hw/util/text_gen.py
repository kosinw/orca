#!/usr/bin/env python3
import sys
import random

screen = [["0000" for _ in range(160)] for _ in range(45)]

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: util/text_rom_gen.py [output_filename]")
        exit()

    output_filename = sys.argv[1]

    for r in range(len(screen)):
        for c in range(len(screen[0])):
            character = bytes([((r*160)+c)%256]).hex()
            color = "4f"
            screen[r][c] = f"{character}{color}"


    with open(output_filename, 'w') as f:
        for r in range(len(screen)):
            for c in range(len(screen[0])):
                f.write(f"{screen[r][c]}\n")


