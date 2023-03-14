#!/bin/bash

if module load openmpi cuda; then 
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
fi


#     mpicc -c cpu.c -o cpu.o
#     nvcc -c gpu.cu -o gpu.o
#     mpicc cpu.o gpu.o -lcudart
#     ssh vmck18@graham.computecanada.ca
#     chmod +x run.sh
