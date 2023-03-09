//Adam Bayley 20176309 19ahb Question 1
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
//void PrintDeviceProperties: print off all the device properties for each device. 
void PrintDeviceProperties(cudaDeviceProp dp) {
	printf("device name and type: %s \n", dp.name);
	printf(" clock rate: %d\n", dp.clockRate);
	printf("Total Global memory: %d\n ", dp.totalGlobalMem);
	printf("Total Constant memory: %d\n ", dp.totalConstMem);
	printf("Shared memory per block: %d\n ", dp.sharedMemPerBlock);
	printf("Warp size: %d\n ", dp.warpSize);
	printf("Number of registers available per block: %d\n", dp.regsPerBlock);
	printf("Max threads per block: %d\n ", dp.maxThreadsPerBlock);
	printf("Number of multiprocessors: %d\n", dp.multiProcessorCount);
	for (int i = 0; i < 3; ++i)
		printf("Maximum dimension %d of block:  %d\n", i, dp.maxThreadsDim[i]);
	for (int i = 0; i < 3; ++i)
		printf("Maximum dimension %d of grid:   %d\n", i, dp.maxGridSize[i]);
  //core calculation 
	int major = dp.major;
	int mpc = dp.multiProcessorCount;
	int cores = 0;
	switch (major) {
	case 2:
		cores = 32 * mpc;
		printf("This device has %d cores.\n", cores);
		break;
	case 3:
		cores = 192 * mpc;
		printf("This device has %d cores.\n", cores);
		break;
	case 5:
		cores = 128 * mpc;
		printf("This device has %d cores.\n", cores);
		break;
	case 6:
		cores = 64 * mpc;
		printf("This device has %d cores.\n", cores);
		break;
	case 7:
		cores = 64 * mpc;
		printf("This device has %d cores.\n", cores);
		break;
	case 8:
		cores = 64 * mpc;
		printf("This device has %d cores.\n", cores);
		break;
	default:
		cores = -1;
		printf("Error getting number of cores.\n");
		break;
	}//close case 
}//close void device info 
int main()
{
	int count;
	cudaGetDeviceCount(&count);
	printf("there are %d devices\n", count);
	for (int i = 0; i < count; i++) {
		cudaDeviceProp dp;
		cudaGetDeviceProperties(&dp, i);
		printf("-------------------\n");
		PrintDeviceProperties(dp);
	}
}