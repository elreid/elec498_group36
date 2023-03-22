#!/bin/bash
#SBATCH --account=def-regrant
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1

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