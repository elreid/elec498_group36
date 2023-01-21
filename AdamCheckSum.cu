/*
Development of the CheckSum Feature and Timestamps.

CHECK-DONE/SUM




TIMESTAMPS
- few methods of doing. NOTE: TIMING THE THREADS.
    1. we could use a cuda event
    2. use something like clock()
    3. clock in kernel code?


  ------------------------------  


  cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);

    <some kernel here>    

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float gpuTime = 0.0f;
    cudaEventElapsedTime(&gpuTime, start, stop);
    cout << "Time to complete: " << gpuTime << " milliseconds" << endl;

    ----------------------
    3. clock in kernel code:
    t1 = myCPUTimer();
    t2 = myCPUTimer();





*/


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <iostream>
#include <time.h>
#include <sys/time.h>

#define USECPSEC 1000000ULL

//definition of number of threads per block. 


//TIMING KERNEL EXECUTION WITH CPU TIMERS:
unsigned long long myCPUTimer(unsigned long long start=0){

  timeval tv;
  gettimeofday(&tv, 0);
  return ((tv.tv_sec*USECPSEC)+tv.tv_usec)-start;
} //returns time in microseconds 

//https://stackoverflow.com/questions/7876624/timing-cuda-operations
//https://stackoverflow.com/questions/69136940/timing-kernel-execution-with-cpu-timers

//TO-DO:
//1. breakdown of how many elements for the checksum.
//2. similarly, need an array for keeping track of times. can store together. 

