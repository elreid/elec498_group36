#!/bin/bash
if [ -z "$1" ]; then
    echo "Give arg pls"
    return 1
fi


module load openmpi cuda
mpicc -c cpu.c -o cpu.o

echo "TESTING FOR BLOCK SIZE $1" > ./results/$1.txt
echo "" >> ./results/$1.txt

# Test 1
echo "" >> ./results/$1.txt
echo "Test 1: N/A Optimizer" >> ./results/$1.txt
nvcc -c gpu.cu -o gpu.o
mpicc cpu.o gpu.o -lcudart
./a.out >> ./results/$1.txt

# Test 2
echo "" >> ./results/$1.txt
echo "Test 2: -G Optimizer" >> ./results/$1.txt
nvcc -G -c gpu.cu -o gpu.o
mpicc cpu.o gpu.o -lcudart
./a.out >> ./results/$1.txt

# Test 3
echo "" >> ./results/$1.txt
echo "Test 3: -O0 Optimizer" >> ./results/$1.txt
nvcc -O0 -c gpu.cu -o gpu.o
mpicc cpu.o gpu.o -lcudart
./a.out >> ./results/$1.txt

# Test 4
echo "" >> ./results/$1.txt
echo "Test 4: -O1 Optimizer" >> ./results/$1.txt
nvcc -O1 -c gpu.cu -o gpu.o
mpicc cpu.o gpu.o -lcudart
./a.out >> ./results/$1.txt

# Test 5
echo "" >> ./results/$1.txt
echo "Test 5: -O2 Optimizer" >> ./results/$1.txt
nvcc -O2 -c gpu.cu -o gpu.o
mpicc cpu.o gpu.o -lcudart
./a.out >> ./results/$1.txt


