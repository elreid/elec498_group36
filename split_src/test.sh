#!/bin/bash
module load openmpi cuda
mpicc -c cpu.c -o cpu.o

echo "TESTING FOR BLOCK SIZE $1" > myfile.txt
echo "\n" >> myfile.txt

nvcc -c gpu.cu -o gpu.o
mpicc cpu.o gpu.o -lcudart
./a.out >

nvcc -G -c gpu.cu -o gpu.o
nvcc -O0 -c gpu.cu -o gpu.o
nvcc -O1 -c gpu.cu -o gpu.o
nvcc -O2 -c gpu.cu -o gpu.o

mpicc cpu.o gpu.o -lcudart
./a.out 