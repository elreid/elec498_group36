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
#define D 1024 // num of elements in a row/column
#define N 16
#define USECPSEC 1000000ULL
#define NUMPARTITIONS 4

// GLOBAL CHECKSUM VARIABLE
// int  CHECKSUM[NUMNODES] = {0};
struct workload
{
	int *data_arr;
	int *check_sum;
	int id;
	int numnodes;
};

// GLOBAL FLAG VARIABLE
int flag = 0;

// Global Time Variables
time_t t;
clock_t start_test, end_test;

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
	for (int j = 0; j < 100; j++)
	{
		j = j + i;
	}
}

void CUDART_CB myStreamCallback(cudaStream_t event, cudaError_t status, void *data)
{
	printf("============================================\n");
	
	struct workload *workload = (struct workload *)data;

	printf("Workload ID: [%d],  Event: [%08X]\n", workload->id, event);
	if (status != cudaSuccess)
		printf("ERR: %s\n", cudaGetErrorString(status));
	
	
	workload->check_sum[workload->id] = 1;

	workload->data_arr[workload->id * 3] = 0xACCED000 | workload->id;

	printf("Checksum: ");
	for (int i = 0; i < workload->numnodes; i++)
	{
		printf("%d ", workload->check_sum[i]);
	}
	printf(", Time Finished: %0.2f\n", (double)(clock() - start_test));
	printf("============================================\n");
	printf("\n\n");
}
/**
 * @brief Launching the master kernel with the params. from cpu.c
 */
extern "C" void launch_master(int *data_arr, int *check_sum, int num_nodes)
{
	srand((unsigned)time(&t));
	start_test = clock();

	dim3 threadsPerBlock(TPB, TPB);
	dim3 numberOfBlocks(ceil(D / threadsPerBlock.x), ceil(D / threadsPerBlock.y));

	/***
	 * Checking if the d_arr is passed over correctly
	 */
	printf("[LAUNCH_MASTER]: Printing the data_arr\n");
	printArray(data_arr, 3 * num_nodes);
	printf("\n");

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
		if (response != cudaSuccess)
		{
			printf("[ERROR]: Stream creation failed for stream %d\n", i);
			printf("\t- CUDA error: %s\n", cudaGetErrorString(response));
		}
		else
		{
			printf("Stream %d created as [%08X]\n", i, streams[i]);
		}

		/**
		 * @brief
		 *  Creating the workload and attaching the callback function to the stream
		 */
		workload *workload = (struct workload *)malloc(sizeof(struct workload));

		workload->data_arr = data_arr;
		workload->check_sum = check_sum;
		workload->numnodes = num_nodes;
		workload->id = i;

		response = cudaStreamAddCallback(streams[i], myStreamCallback, workload, 0);
		if (response != cudaSuccess)
		{
			printf("[ERROR]: Attaching callback function failed for stream %d\n", i);
			printf("\t- CUDA error: %s\n", cudaGetErrorString(response));
		}
		else
		{
			printf("Callback function attached to stream %d, Object: [%08X]\n", i, streams[i]);
		}
		/**
		 * End of cb_
		 *
		 */
	}
	printf("\n\n");

	//***
	// @brief Wiring up the kernels to their specific streams
	for (int i = 0; i < num_nodes; i++)
	{

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

		// send in values into the host 2 input matrices, randomness in the arrays
		for (int x = 0; x < D; x++)
		{
			for (int y = 0; y < D; y++)
			{
				int rand1 = rand() % 10;
				int rand2 = rand() % 10;
				*(h_A + x * D + y) = rand1;
				*(h_B + x * D + y) = rand2;
			}
		}
		/**
		 * @brief Construct a new cuda Memcpy Async object
		 *
		 */
		// copy contents of host input matrices to the device
		cudaMemcpyAsync(d_A, h_A, size, cudaMemcpyHostToDevice, streams[i]);
		cudaMemcpyAsync(d_B, h_B, size, cudaMemcpyHostToDevice, streams[i]);
		/**
		 * @brief kernel inst.
		 *
		 * INSTANTIATE THE KERNEL
		 *
		 */
		matrixAddition<<<1, 1, streams[i]>>>(d_A, d_B, d_C, D);
		// print_kernel<<<1, 1, 0, streams[i]>>>();
	}
	printf("\n\n");

	cudaDeviceSynchronize();

	//***
	// @brief Destroying the streams
	// for (int i = 0; i < num_nodes; i++)
	// {
	// 	cudaStreamDestroy(streams[i]);
	// }

	// printf("Checksum: ");
	// for (int i = 0; i < num_nodes; i++){
	// 	printf("%d ", check_sum[i]);
	// }
	// printf("\n");

	printf("Finished launching master function\n");
}

void launch_bogus()
{
	dim3 threadsPerBlock(TPB, TPB);
	dim3 numberOfBlocks(ceil(D / threadsPerBlock.x), ceil(D / threadsPerBlock.y));

	cudaStream_t stream1, stream2, stream3;
	cudaError_t response;
	response = cudaStreamCreate(&stream1);
	printf("CUDA error: %s, %d\n", cudaGetErrorString(response), response);
	response = cudaStreamCreate(&stream2);
	printf("CUDA error: %s, %d\n", cudaGetErrorString(response), response);
	response = cudaStreamCreate(&stream3);
	printf("CUDA error: %s, %d\n", cudaGetErrorString(response), response);

	for (int i = 0; i < 100; i++)
	{
		print_kernel<<<numberOfBlocks, threadsPerBlock, 0, stream1>>>();
		print_kernel<<<numberOfBlocks, threadsPerBlock, 0, stream2>>>();
		print_kernel<<<numberOfBlocks, threadsPerBlock, 0, stream3>>>();
		cudaDeviceSynchronize();
	}
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

// int main(int argc, char **argv)
// {
// 	// launch_matrix_multiply();
// 	size_t size_list_arr = (NUMNODES*3)*sizeof(int);

// 	int *d_list_arr;
//     cudaMalloc( (void**) &d_list_arr , size_list_arr );

// 	// launch_master(d_list_arr, CHECKSUM, NUMNODES);

// 	launch_bogus();

// 	return 0;
// }