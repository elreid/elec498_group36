#!/bin/bash
if mpicc -c cpu.c -o cpu.o; then 
    if nvcc -c gpu.cu -o gpu.o; then
        mpicc cpu.o gpu.o -lcudart
    else
        echo "\033[1;31mGPU compilation failed\e[0m"
        return
    fi
else
    echo "\033[1;31mCPU compilation failed\e[0m"
    return
fi

./a.out
