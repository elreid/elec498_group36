#!/bin/bash

if module load openmpi cuda; then 
    if mpicc -c cpu.c -o cpu.o; then 
        if nvcc -c gpu.cu -o gpu.o; then
            if mpicc cpu.o gpu.o -lcudart; then
                ./a.out
            fi
        else
            echo -e "\n == GPU compilation failed == \n\n"
        fi
    else
        echo -e "\n == CPU compilation failed == \n\n"
    fi
fi


#     mpicc -c cpu.c -o cpu.o
#     nvcc -c gpu.cu -o gpu.o
#     mpicc cpu.o gpu.o -lcudart
#     ssh vmck18@graham.computecanada.ca
#     chmod +x run.sh
#     mpicc -I/usr/local/cuda/include -L/usr/local/cuda/lib64 cpu.c -lcudart -o cpu.o