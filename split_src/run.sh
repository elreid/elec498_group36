#!/bin/bash
if mpicc -c cpu.c -o cpu.o; then 
    if nvcc -c gpu.cu -o gpu.o; then
        if mpicc cpu.o gpu.o -lcudart; then
            ./a.out
        fi
    else
        echo "GPU compilation failed"
    fi
else
    echo "CPU compilation failed"
fi

