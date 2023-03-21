#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>
#include "cuda_runtime.h"
#include <cuda.h>
#include "device_launch_parameters.h"

#define TPB 16	//num threads in a block
#define D 256	//num of elements in a row/column

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
	for (int i = 0; i < size; i++) {
		for (int j = 0; j < size; j++) {
			C[i*size + j] = A[i*size + j] + B[i*size + j];
		}
	}
}//close hostaddition

__global__ void matrixAddition(int *A, int *B, int *C, int size) {
	int row = blockIdx.y*blockDim.y + threadIdx.y;
	int col = blockIdx.x*blockDim.x + threadIdx.x;

	if (row < size && col < size) {
		int temp = row * size + col;
		C[temp] = A[temp] + B[temp];
	}//close if
}

/**
 * @brief Master kernel for checksum flaggin
 * 
 * 
 */
__global__ void master_kernel(int * d_arr, int * check_sum, int num_nodes)
{
	check_sum[num_nodes-1] = 1;
}


/**
 * @brief Launching the master kernel with the params. from cpu.c
 */
extern "C" void launch_master(int * d_arr, int * check_sum, int num_nodes)
{
	// printf("d_arr: %X\n", d_arr);
	// for(int i = 0; i < num_nodes*3; i++){
	// 	printf("d_arr[%d]: %d\n", i, d_arr[i]);
	// }
	// for(int i = 0; i < num_nodes; i++){
	// 	printf("check_sum[%d]: %d\n", i, check_sum[i]);
	// 	if (i==3){
	// 		check_sum[i] = 1;
	// 	}
	// }
	// dim3 threadsPerBlock(TPB, TPB);
	// dim3 numberOfBlocks(ceil(D / threadsPerBlock.x), ceil(D / threadsPerBlock.y));

	// master_kernel <<<numberOfBlocks, threadsPerBlock>>>(d_arr, check_sum, num_nodes);
	// printArray(check_sum, num_nodes);
	// check_sum[num_nodes-1] = 1;

	cudaStrem_t stream_arr[num_nodes];

   	for(int i=0;i<num_nodes;i++){

		cudaStream_t stream
		stream_arr[i] = stream;
   		cudaStreamCreate(&stream)
    	matrix_add<<<blocks,threads,0,stream>>>(d_a,d_b);
    	
  	}
	
	cudaDeviceSynchronize();


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

    size_t size = D*D*sizeof(int);

    //create pointers for host related stuff, allocate the memory required
	int *h_A 	= (int*)malloc(size);
	int *h_B 	= (int*)malloc(size);
	int *h_C 	= (int*)malloc(size);
	int *h_C1 	= (int*)malloc(size);

	//create pointers for device related stuff, allocate the memory required
	int *d_A, *d_B, *d_C;
	cudaMalloc((void**)&d_A, size);
	cudaMalloc((void**)&d_B, size);
	cudaMalloc((void**)&d_C, size);

	//seed that THICC BOI
	srand((unsigned)time(&t));

    //send in values into the host 2 input matrices
	for (int i = 0; i < D; i++) {
		for (int j = 0; j < D; j++) {
			int rand1 = rand() % 10;
			int rand2 = rand() % 10;
			*(h_A + i * D + j) = rand1;
			*(h_B + i * D + j) = rand2;
		}
	}

    //run it back baby, host addition start, stop and method call
	//general function timing // banya stuff 
	clock_t start_test, end_test;
	double cpu_time_used;
	start_test = clock();
	// banya stuff
	cudaEventRecord(start, 0);
	hostAddition(h_A, h_B, h_C, D);
	cudaEventRecord(stop, 0);

	//print out the results
	cudaEventElapsedTime(&gpu_time, start, stop);
	printf("host addition time:\t\t%0.2f\n", gpu_time);
	// banya stuff
	end_test = clock();
    cpu_time_used = ((double) (end_test - start_test));
	printf("(banya) h add time :\t\t%0.2f\n", cpu_time_used);
	// banya stuff

	//copy contents of host input matrices to the device
	cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);

    //setup threads per block and number of blocks.
	//should change D to just be strictly 16 later based on documentation ??...
	dim3 threadsPerBlock(TPB, TPB);
	dim3 numberOfBlocks(ceil(D / threadsPerBlock.x), ceil(D / threadsPerBlock.y));

	//addition by individual threads:
	start_test = clock();
	//
	cudaEventRecord(start1, 0);
	matrixAddition <<<numberOfBlocks, threadsPerBlock>>>(d_A, d_B, d_C, D);
	cudaEventRecord(stop1, 0);
	cudaEventSynchronize(stop1);
	cudaMemcpy(h_C1, d_C, size, cudaMemcpyDeviceToHost);
	cudaEventElapsedTime(&gpu_time1, start1, stop1);
	printf("normal matrix addition:\t\t%0.2f\n", gpu_time1);
	//
	end_test = clock();
    cpu_time_used = ((double) (end_test - start_test));
	printf("(banya) norm mat add :\t\t%0.2f\n", cpu_time_used);
	//

}