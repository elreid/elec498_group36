#!/bin/bash
if [ -z "$1" ]; then
    echo "Give arg pls"
    return 1
fi


module load openmpi cuda
mpicc -c cpu.c -o cpu.o

echo "TESTING FOR BLOCK SIZE $1" > ./results/$1.txt
echo "\n" >> ./results/$1.txt

nvcc -c gpu.cu -o gpu.o
mpicc cpu.o gpu.o -lcudart
./a.out >> ./results/$1.txt
echo "\n" >> ./results/$1.txt


nvcc -G -c gpu.cu -o gpu.o
mpicc cpu.o gpu.o -lcudart
./a.out >> ./results/$1.txt
echo "\n" >> ./results/$1.txt


nvcc -O0 -c gpu.cu -o gpu.o
mpicc cpu.o gpu.o -lcudart
./a.out >> ./results/$1.txt
echo "\n" >> ./results/$1.txt


nvcc -O1 -c gpu.cu -o gpu.o
mpicc cpu.o gpu.o -lcudart
./a.out >> ./results/$1.txt
echo "\n" >> ./results/$1.txt


nvcc -O2 -c gpu.cu -o gpu.o
mpicc cpu.o gpu.o -lcudart
./a.out >> ./results/$1.txt
echo "\n" >> ./results/$1.txt


