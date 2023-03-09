//Adam Bayley 20176309 19ahb Machine Problem 2
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <ctime>

#define D 1024	//16x16, 256x256....
#define TPB 16	//num threads in a block

/*
__host__ void validateMatrix(int *m, int *h, int size) {
int success = 0;
for (int i = 0; i < size; i++) {
for (int j = 0; j < size; j++) {
if (m[i][j] != h[i][j]) {
success = 1;
}//close if
}//close for
}//close for
if (success == 0)
printf("Test Passed.\n");
else
printf("Test Failed.\n");
}//close validateMatrix
*/


void hostAddition(int *A, int *B, int *C, int size) { //might need __host__ ??....
	for (int i = 0; i < size; i++) {
		for (int j = 0; j < size; j++) {
			C[i*size + j] = A[i*size + j] + B[i*size + j];
		}//close j
	}//close i
}//close hostaddition

__global__ void matrixAddition(int *A, int *B, int *C, int size) {
	int row = blockIdx.y*blockDim.y + threadIdx.y;
	int col = blockIdx.x*blockDim.x + threadIdx.x;

	if (row < size && col < size) {
		int temp = row * size + col;
		C[temp] = A[temp] + B[temp];
	}//close if

}//close matrixAddition

__global__ void rowAddition(int *A, int *B, int*C, int size) {
	int i = blockIdx.y * blockDim.y + threadIdx.y;
	int y;
	if (i < size) {
		for (int k = 0; k < size; k++) {
			y = i*size + k;
			C[y] = B[y] + A[y];
		}//close for
	}//close if
}//close rowAddition

__global__ void colAddition(int *d_A, int *d_B, int*d_C, int size) {
	int i = blockIdx.x * blockDim.x + threadIdx.x;
	int y;
	if (i < size) {
		for (int k = 0; k < size; k++) {
			y = k*size + i;
			d_C[y] = d_B[y] + d_A[y];
		}//close for
	}//close if
}//close colAddition



int main() {

	//keep track of t for use with rand
	time_t t;

	//flags for each individual check (row, col, individual val)
	int correctFlag1 = 0;
	int correctFlag2 = 0;
	int correctFlag3 = 0;
	//int correctFlag[] = { 0,0,0 };

	//event variables
	cudaEvent_t start, stop, start1, stop1, start2, stop2, start3, stop3;

	//create events for start times
	cudaEventCreate(&start);
	cudaEventCreate(&start1);
	cudaEventCreate(&start2);
	cudaEventCreate(&start3);

	//create events for stop times
	cudaEventCreate(&stop);
	cudaEventCreate(&stop1);
	cudaEventCreate(&stop2);
	cudaEventCreate(&stop3);
	cudaDeviceSynchronize();

	//variables for difference between start and stop times
	float gpu_time = 0.0f, gpu_time1 = 0.0, gpu_time2 = 0.0f, gpu_time3 = 0.0f;

	//size of matrix calculation
	size_t size = D*D*sizeof(int);

	//create pointers for host related stuff, allocate the memory required
	int *h_A = (int*)malloc(size);
	int *h_B = (int*)malloc(size);
	int *h_C = (int*)malloc(size);
	int *h_C1 = (int*)malloc(size);
	int *h_C2 = (int*)malloc(size);
	int *h_C3 = (int*)malloc(size);


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
	cudaEventRecord(start, 0);
	hostAddition(h_A, h_B, h_C, D);
	cudaEventRecord(stop, 0);

	//print out the results
	cudaEventElapsedTime(&gpu_time, start, stop);
	printf("host addition time: %0.2f\n", gpu_time);

	//copy contents of host input matrices to the device
	cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);


	//setup threads per block and number of blocks.
	//should change D to just be strictly 16 later based on documentation ??...
	dim3 threadsPerBlock(TPB, TPB);
	dim3 numberOfBlocks(ceil(D / threadsPerBlock.x), ceil(D / threadsPerBlock.y));

	//addition by individual threads:
	cudaEventRecord(start1, 0);
	matrixAddition << < numberOfBlocks, threadsPerBlock >> >(d_A, d_B, d_C, D);
	cudaEventRecord(stop1, 0);
	cudaEventSynchronize(stop1);
	cudaMemcpy(h_C1, d_C, size, cudaMemcpyDeviceToHost);
	cudaEventElapsedTime(&gpu_time1, start1, stop1);
	printf("\n normal matrix addition: %0.2f\n", gpu_time1);

	//addition by rows:
	cudaEventRecord(start2, 0);
	rowAddition << <ceil(D / TPB), TPB >> >(d_A, d_B, d_C, D);
	cudaEventRecord(stop2, 0);
	cudaEventSynchronize(stop2);
	cudaMemcpy(h_C2, d_C, size, cudaMemcpyDeviceToHost);
	cudaEventElapsedTime(&gpu_time2, start2, stop2);
	printf("\n Row time: %0.2f\n", gpu_time2);

	//addition by columns:
	cudaEventRecord(start3, 0);
	colAddition << <ceil(D / TPB), TPB >> >(d_A, d_B, d_C, D);
	cudaEventRecord(stop3, 0);
	cudaEventSynchronize(stop3);
	cudaMemcpy(h_C3, d_C, size, cudaMemcpyDeviceToHost);
	cudaEventElapsedTime(&gpu_time3, start3, stop3);
	printf("\n Column time: %0.2f\n", gpu_time3);

	//check if they stuff is equal
	for (int i = 0; i < D; i++) {
		for (int j = 0; j < D; j++) {
			if (*(h_C1 + i * D + j) != *(h_C + i * D + j))
				correctFlag1 = 1;
			if (*(h_C2 + i * D + j) != *(h_C + i * D + j))
				correctFlag2 = 1;
			if (*(h_C2 + i * D + j) != *(h_C + i * D + j))
				correctFlag3 = 1;
		}//end for j
	}//end for i

	if (correctFlag1 == 0)
		printf(" normal addition passed.\n");
	else
		printf(" normal addition failed.\n");

	if (correctFlag2 == 0)
		printf(" row addition passed.\n");
	else
		printf(" Row  addition failed.\n");

	if (correctFlag3 == 0)
		printf(" Column addition passed.\n\n");
	else
		printf(" Column addition failed.\n\n");

	//free host 
	cudaFreeHost(h_A);
	cudaFreeHost(h_B);
	cudaFreeHost(h_C);
	cudaFreeHost(h_C1);
	cudaFreeHost(h_C2);
	cudaFreeHost(h_C3);

	//free device
	cudaFree(d_A);
	cudaFree(d_B);
	cudaFree(d_C);

}
