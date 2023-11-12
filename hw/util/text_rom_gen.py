#!/usr/bin/env python3
import sys
import random

corpus = """a quick brown fox jumps over the lazy dog. A QUICK BROWN FOX JUMPS OVER THE LAZY DOG? 0123456789
┌─┬─┐ ╔═╦═╗ ╒═╤═╕ ╓─╥─╖
│ │ │ ║ ║ ║ │ │ │ ║ ║ ║
├─┼─┤ ╠═╬═╣ ╞═╪═╡ ╟─╫─╢
└─┴─┘ ╚═╩═╝ ╘═╧═╛ ╙─╨─╜
░░░░░ ▐▀█▀▌
▒▒▒▒▒ ▐ █ ▌
▓▓▓▓▓ ▐▀█▀▌
█████ ▐▄█▄▌
"""

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: util/text_rom_gen.py [output_filename]")
        exit()

    output_filename = sys.argv[1]

    words = 7200

    with open(output_filename, 'w') as f:
        for ch in corpus:
            if ch == "\n" or ch == " ":
                text = b"\x00"
            else:
                text = ch.encode('cp437')

            color = f"0f"

            f.write(f"{text.hex()}{color}\n")
            words -= 1

        f.write(f"{'█'.encode('cp437').hex()}8f\n")
        words -= 1

        while words:
            f.write("0000\n")
            words -= 1


