#!/usr/bin/env python3
import sys
import random

codepoints = [["00" for _ in range(160)] for _ in range(45)]
attributes = [["00" for _ in range(160)] for _ in range(45)]

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("usage: util/text_gen.py [codepoint_file] [attribute_file]")
        exit()

    codepoint_file = sys.argv[1]
    attribute_file = sys.argv[2]

    for r in range(45):
        for c in range(160):
            character = bytes([((r*160)+c)%256]).hex()
            attributes[r][c] = "4f"
            codepoints[r][c] = f"{character}"


    with open(codepoint_file, 'w') as f:
        for r in range(len(codepoints)):
            for c in range(len(codepoints[0])):
                f.write(f"{codepoints[r][c]}\n")

    with open(attribute_file, 'w') as f:
        for r in range(len(attributes)):
            for c in range(len(attributes[0])):
                f.write(f"{attributes[r][c]}\n")


