#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>
#include <cuda_runtime.h>
#include "cuda_runtime.h"
#include "cuda_runtime_api.h"
#include <cuda.h>
#include "device_launch_parameters.h"

#define N 16
#define USECPSEC 1000000ULL
#define NUMPARTITIONS 4
#define NUMNODES 5000

__global__ void matrixAddition(int *A, int *B, int *C, int size)
{
	// if (threadIdx.x == 0)
	// {
	// 	printf("[MAT_ADD]: Ping from block %d, thread %d\n", blockIdx.x, threadIdx.x);
	// }

	int row = blockIdx.y * blockDim.y + threadIdx.y;
	int col = blockIdx.x * blockDim.x + threadIdx.x;

	if (row < size && col < size)
	{
		int temp = row * size + col;
		C[temp] = A[temp] + B[temp];
	} // close if
}

