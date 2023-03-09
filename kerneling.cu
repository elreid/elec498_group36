#include "cuda_runtime.h"
#include "stdio.h"
#include <stdlib.h>
#include <math.h>
#include <assert.h>
#include <cuda.h>
#include <time.h>
#include <sys/time.h>

#define N 16
#define USECPSEC 1000000ULL





__global__ void MultiBlock(int numThreads){
//find thread index so we can interate through 
int index = blockIdx.x * blockDim.x + threadIdx.x;

//seperate the threads into blocks
dim3 threadsPerBlock (1, 1);
dim3 numBlocks((N + threadsPerBlock.x -1) / threadsPerBlock.x, (N+threadsPerBlock.y -1) / threadsPerBlock.y);
//run through every block and every thread
for (int j = 0; numBlocks > j; j++){
    for (int i = 0; index > i ; i++){
        //vector at index, plus next vector
        vector_add<<<1, threadsPerBlock>>>();
    }
}
}

//TO-DO ADAM: needs to be made into global, cpu, etc.
//TIMING KERNEL EXECUTION WITH CPU TIMERS:
unsigned long long myCPUTimer(unsigned long long start=0){

  timeval tv;
  gettimeofday(&tv, 0);
  return ((tv.tv_sec*USECPSEC)+tv.tv_usec)-start;
} //returns time in microseconds 


int main(){
    //allocate host mem
    float *a, *b, *out;
    float *d_a, *d_b, *d_out; 

    //update size
    size_t size = D*D*sizeof(int);

 	int *h_A = (int*)malloc(size);
    int *h_C1 = (int*)malloc(size);

    int *d_A;
    cudaMalloc((void**)&d_A, size);

    cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);

    MultiBlock<<<1, N>>>();

    //free mem
    cudaFree(h_A);
    cudaFree(h_C1);

    free(d_A); 
}