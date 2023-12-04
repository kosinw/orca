#!/usr/bin/env python3
from manta import Manta
from struct import unpack
import sys
import os
import time

memory = [0x13 for _ in range(16384)]

if __name__ == "__main__":
    if len(sys.argv) < 3:
        exit()

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    with open(input_file, 'rb') as f:
        sz = os.path.getsize(input_file)
        instrs = sz // 4
        data = f.read()
        datas = [unpack('<I', data[i*4:(i+1)*4])[0] for i in range(0, instrs)]

        for i in range(len(datas)):
            memory[i] = datas[i]

    with open(output_file, 'w') as f:
        for word in memory:
            f.write(f"{word:08x}\n")