#!/usr/bin/env python3
from manta import Manta
from struct import unpack
import sys
import os

if __name__ == "__main__":
    if len(sys.argv) < 2:
        exit()

    input_file = sys.argv[1]

    m = Manta('manta.yml')

    with open(input_file, 'rb') as f:
        sz = os.path.getsize(input_file)
        instrs = sz // 4
        data = f.read()
        addrs = list(range(0, instrs))
        datas = [unpack('<I', data[i*4:(i+1)*4])[0] for i in range(0, instrs)]
        print(addrs, datas)

        m.instruction_memory.write(addrs, datas)
        print(m.instruction_memory.read(addrs))