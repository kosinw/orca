#!/usr/bin/env python3
import sys

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("usage: util/font_gen.py [input_filename] [output_filename]")
        exit()

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    fonts = []

    with open(input_file, 'r') as f:
        i = 0
        lines = list(f.readlines())

        while i < 256:
            font_slice = lines[i*17:(i+1)*17][1:]
            current_font = bytearray()

            for line in font_slice:
                current_font.append(int(line[:4], 16))

            fonts.append(current_font)
            i+=1

    with open(output_file, 'w') as f:
        for font in fonts:
            f.write(f"{font.hex()}\n")

