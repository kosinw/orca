#!/usr/bin/env python3
import sys
import random

codepoints = [["00" for _ in range(160)] for _ in range(45)]
attributes = [["00" for _ in range(160)] for _ in range(45)]

if __name__ == "__main__":
    if len(sys.argv) < 2:
        exit()

    file = sys.argv[1]

    for r in range(45):
        for c in range(160):
            character = bytes([((r*160)+c)%256]).hex()
            codepoints[r][c] = "00"
            attributes[r][c] = "4f"

    # text = "HELLO, WORLD!"

    # for i in range(len(text)):
    #     r = i // 160
    #     c = i % 160

    #     codepoints[r][c] = f"{ord(text[i]):x}"
    #     attributes[r][c] = "0f"

    with open(file, 'w') as f:
        for r in range(len(codepoints)):
            for c in range(0, len(codepoints[0]), 2):
                f.write(f"{attributes[r][c+1]}")
                f.write(f"{codepoints[r][c+1]}")
                f.write(f"{attributes[r][c]}")
                f.write(f"{codepoints[r][c]}")
                f.write("\n")
