#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>
#include "cuda_runtime.h"
#include "cuda_runtime_api.h"
#include <cuda.h>
#include "device_launch_parameters.h"
// #include "cuPrintf.cu"

#define TPB 16 // num threads in a block
#define D 256  // num of elements in a row/column
#define N 16
#define USECPSEC 1000000ULL
#define NUMPARTITIONS 4
#define NUMNODES 5


// GLOBAL CHECKSUM VARIABLE
int  CHECKSUM[NUMNODES] = {0};

// GLOBAL FLAG VARIABLE 
int flag = 0;

/***
 * @brief From "forvanya.txt"
 */
void printArray(int *array, int length)
{
	for (int i = 0; i < length; i++)
	{
		if (i % 3 == 0)
			printf("\n");
		printf("%08X ", array[i]);
	}
	printf("\n");
}

void hostAddition(int *A, int *B, int *C, int size)
{
	for (int i = 0; i < size; i++)
	{
		for (int j = 0; j < size; j++)
		{
			C[i * size + j] = A[i * size + j] + B[i * size + j];
		}
	}
} // close hostaddition

__global__ void matrixAddition(int *A, int *B, int *C, int size)
{

	if (threadIdx.x == 0)
	{
		printf("[MAT_ADD]: Ping from block %d, thread %d\n", blockIdx.x, threadIdx.x);
	}

	int row = blockIdx.y * blockDim.y + threadIdx.y;
	int col = blockIdx.x * blockDim.x + threadIdx.x;

	if (row < size && col < size)
	{
		int temp = row * size + col;
		C[temp] = A[temp] + B[temp];
	} // close if
}

/**
 * @brief Master kernel for checksum flaggin
 *
 *
 */
__global__ void master_kernel(int *d_arr, int *check_sum, int num_nodes)
{
	check_sum[num_nodes - 1] = 1;
}
/**
 * @brief Test kernel
 *  - for printing functionality
 *
 */
__global__ void print_kernel()
{
	int i = 0; 
	i = i + 1;
	for(int j = 0; j < 100; j++){
		j = j+i;
	}
}

void myStreamCallback(cudaStream_t event, cudaError_t status, void *data)
{

	int *check_sum = (int *) data ;
	check_sum[0] = 1;
	printf("Callback function called\n");
	flag = 1;

}
/**
 * @brief Launching the master kernel with the params. from cpu.c
 */
extern "C" void launch_master(int *d_arr, int *check_sum, int num_nodes)
{

	dim3 threadsPerBlock(TPB, TPB);
	dim3 numberOfBlocks(ceil(D / threadsPerBlock.x), ceil(D / threadsPerBlock.y));

	/***
	 * @brief Creating streams for each node
	 * Undefined number of streams
	 */

	cudaStream_t streams[num_nodes];

	//***
	// @brief Creating streams for each node
	for (int i = 0; i < num_nodes; i++)
	{
		cudaError_t response;

		response = cudaStreamCreate(&streams[i]);
		if(response != cudaSuccess){
			printf("[ERROR]: Stream creation failed for stream %d\n", i);
			printf("\t- CUDA error: %s\n", cudaGetErrorString(response));
		}
		
		response = cudaStreamAddCallback(streams[i], myStreamCallback, check_sum, 0);
		if(response != cudaSuccess){
			printf("[ERROR]: Attaching callback function failed for stream %d\n", i);
			printf("\t- CUDA error: %s\n", cudaGetErrorString(response));
		}

		printf("\n");

	}

	//***
	// @brief Wiring up the kernels to their specific streams
	for (int i = 0; i < num_nodes; i++)
	{
		print_kernel<<<1, 1, 0, streams[i]>>>();
	}
	cudaDeviceSynchronize();

	//***
	// @brief Destroying the streams
	for (int i = 0; i < num_nodes; i++)
	{
		cudaStreamDestroy(streams[i]);
	}

	printf("Flag: %d\n", flag);

	printf("Finished launching master function\n");
}

extern "C" void launch_matrix_multiply()
{
	/**
	 * @brief Doing the matrix multiplication
	 *
	 */
	time_t t;
	cudaEvent_t start, stop, start1, stop1;

	cudaEventCreate(&start);
	cudaEventCreate(&start1);

	cudaEventCreate(&stop);
	cudaEventCreate(&stop1);

	float gpu_time = 0.0f, gpu_time1 = 0.0;

	size_t size = D * D * sizeof(int);

	// create pointers for host related stuff, allocate the memory required
	int *h_A = (int *)malloc(size);
	int *h_B = (int *)malloc(size);
	int *h_C = (int *)malloc(size);
	int *h_C1 = (int *)malloc(size);

	// create pointers for device related stuff, allocate the memory required
	int *d_A, *d_B, *d_C;
	cudaMalloc((void **)&d_A, size);
	cudaMalloc((void **)&d_B, size);
	cudaMalloc((void **)&d_C, size);

	// seed that THICC BOI
	srand((unsigned)time(&t));

	// send in values into the host 2 input matrices
	for (int i = 0; i < D; i++)
	{
		for (int j = 0; j < D; j++)
		{
			int rand1 = rand() % 10;
			int rand2 = rand() % 10;
			*(h_A + i * D + j) = rand1;
			*(h_B + i * D + j) = rand2;
		}
	}

	// run it back baby, host addition start, stop and method call
	// general function timing // banya stuff
	clock_t start_test, end_test;
	double cpu_time_used;
	start_test = clock();
	// banya stuff
	cudaEventRecord(start, 0);
	hostAddition(h_A, h_B, h_C, D);
	cudaEventRecord(stop, 0);

	// print out the results
	cudaEventElapsedTime(&gpu_time, start, stop);
	printf("host addition time:\t\t%0.2f\n", gpu_time);
	// banya stuff
	end_test = clock();
	cpu_time_used = ((double)(end_test - start_test));
	printf("(banya) h add time :\t\t%0.2f\n", cpu_time_used);
	// banya stuff

	// copy contents of host input matrices to the device
	cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);

	// setup threads per block and number of blocks.
	// should change D to just be strictly 16 later based on documentation ??...
	dim3 threadsPerBlock(TPB, TPB);
	dim3 numberOfBlocks(ceil(D / threadsPerBlock.x), ceil(D / threadsPerBlock.y));

	// addition by individual threads:
	start_test = clock();
	//
	cudaEventRecord(start1, 0);
	matrixAddition<<<numberOfBlocks, threadsPerBlock>>>(d_A, d_B, d_C, D);

	cudaEventRecord(stop1, 0);
	cudaEventSynchronize(stop1);
	cudaMemcpy(h_C1, d_C, size, cudaMemcpyDeviceToHost);
	cudaEventElapsedTime(&gpu_time1, start1, stop1);
	printf("normal matrix addition:\t\t%0.2f\n", gpu_time1);
	//
	end_test = clock();
	cpu_time_used = ((double)(end_test - start_test));
	printf("(banya) norm mat add :\t\t%0.2f\n", cpu_time_used);
	//
}


int main(int argc, char **argv)
{
	// launch_matrix_multiply();
	size_t size_list_arr = (NUMNODES*3)*sizeof(int);

	int *d_list_arr;
    cudaMalloc( (void**) &d_list_arr , size_list_arr );

	launch_master(d_list_arr, CHECKSUM, NUMNODES);

	return 0;
}