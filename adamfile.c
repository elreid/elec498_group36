#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>
#include "cuda_runtime.h"
#include <cuda.h>
#include <mpi.h>
#include "device_launch_parameters.h"
// #include <ctime>

#define N 16
#define USECPSEC 1000000ULL
#define NUMPARTITIONS 4
#define NUMNODES 5
#define TPB 16	//num threads in a block
#define D 256

// TO-DO ADAM: needs to be made into global, cpu, etc.
// TIMING KERNEL EXECUTION WITH CPU TIMERS:
// unsigned long long myCPUTimer(unsigned long long start = 0)
// {
//     struct timeval tv;
//     gettimeofday(&tv, 0);
//     return ((tv.tv_sec * USECPSEC) + tv.tv_usec) - start;
// } // returns time in microseconds

// LinkedList Construction
struct node
{
    int *buffer;
    int size;
    int partitions;
    struct node *next;
};

// length of LinkedList testing function
int LengthLinkedList(struct node *head)
{
    struct node *current = head;
    int count = 0;
    while (current != NULL)
    {
        count++;
        current = current->next;
    }
    return count;
}

// add Node function
// void AddNode(struct node **headRef, int* buffer, int size, int partitions)
// {
//     struct node *newNode = malloc(sizeof(struct node));
//     newNode->buffer = buffer;
//     newNode->size = size;
//     newNode->partitions = partitions;
//     newNode->next = *headRef;
//     *headRef = newNode;
// }

struct node *populate_list()
{
    struct node *head = NULL;
    struct node *prev = NULL;

    int allocator = 0;

    for (int i = 0; i < NUMNODES; i += 1)
    {
        struct node *curr = (struct node *)malloc(sizeof(struct node));
        curr->buffer = &allocator + i;
        curr->size = 256;
        curr->partitions = 16;
        curr->next = NULL;

        if (prev != NULL)
        {
            prev->next = curr;
        }
        else
        {
            head = curr;
        }

        prev = curr;
        if (i == NUMNODES - 1)
        {
            prev->next = NULL;
        }
    }
    return head;
}

void printList(struct node *head)
{
    struct node *current = head;
    int i = 0;

    while (current != NULL)
    {
        printf("[%03d:%08X:%08X]:{buf:%08X,siz:%03d,par:%03d} ", i, current, current->next, current->buffer, current->size, current->partitions);
        if (current->next != NULL) printf(" -> \n");
        current = current->next;
        i++;
    }
    printf("\n");
}


void populateArray(struct node *head, int **arr)
{
    struct node *current = head;

    free(*arr);
    *arr = (int *)malloc((NUMNODES * 3) * sizeof(int));
    if (*arr == NULL)
    {
        printf("ERR: Void array.\n");
        return;
    }
    else
    {
        for (int i = 0; i < NUMNODES * 3; i += 3)
        {
            // (*arr)[i]    = (int)(current->buffer);
            (*arr)[i]       = i; // TODO: Remove and change back
            (*arr)[i + 1]   = current->size;
            (*arr)[i + 2]   = current->partitions;
            current         = current->next;
        }
    }
}


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


/***
 * @brief From "forvanya.txt"
*/
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
 * @brief From "forvanya.txt"
 */



int main(int argc, char **argv)
{
    int process_Rank, size_Of_Cluster;
    int buf[100], provided;
    // MPI_Init(&argc, &argv);
    MPI_Init_thread(&argc, &argv, MPI_THREAD_MULTIPLE, &provided);
    MPI_Comm_size(MPI_COMM_WORLD, &size_Of_Cluster);
    MPI_Comm_rank(MPI_COMM_WORLD, &process_Rank);

    printf("Hello World from process %d of %d\n", process_Rank, size_Of_Cluster);
    printf("%d\n", provided);

    if (process_Rank == 0)
    {
        /* Rank 0 sends an integer to each of the other process ranks */
        int i;
        int value = 0;
        for (i = 1; i < size_Of_Cluster; i++)
        {
            value = value + i;
            MPI_Send(&value, 1, MPI_INT, i, 0, MPI_COMM_WORLD);
            // printf("%d\n", value);
        }
    }
    else
    {
        /* All other process ranks receive one number from Rank 0 */
        int value;
        MPI_Status status;
        MPI_Recv(&value, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, &status);
        printf("Rank %d received value %d\n", process_Rank, value);
    }
    
    /**
     * @brief Creating the linked list, printing it
     * 
     */
    struct node *head = populate_list();
    printList(head); // TODO: Remove this line

    /**
     * @brief Allocate memory for the array on the CPU and GPU,
     * then populating the arraay and checking it 
     * 
     */

    //do host and device memory inits
    size_t size_list_arr = (NUMNODES*3)*sizeof(int);
    int *h_list_arr = (int*)malloc(size_list_arr);

    populateArray(head, &h_list_arr);
    printArray(h_list_arr, NUMNODES * 3); // TODO: Remove this line

    int *d_list_arr;
    cudaMalloc((void**)&d_list_arr, size_list_arr);

    // matrix_add(h_A, h_B, h_C, size);
    cudaMemcpy(d_list_arr, h_list_arr, size_list_arr, cudaMemcpyHostToDevice);

    cudaFreeHost(h_list_arr);

    cudaFree(d_list_arr);

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
	int *h_A = (int*)malloc(size);
	int *h_B = (int*)malloc(size);
	int *h_C = (int*)malloc(size);
	int *h_C1 = (int*)malloc(size);

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
	matrixAddition <<<numberOfBlocks, threadsPerBlock>>>(d_A, d_B, d_C, D);
	cudaEventRecord(stop1, 0);
	cudaEventSynchronize(stop1);
	cudaMemcpy(h_C1, d_C, size, cudaMemcpyDeviceToHost);
	cudaEventElapsedTime(&gpu_time1, start1, stop1);
	printf("\n normal matrix addition: %0.2f\n", gpu_time1);









    // Finishing touches
    MPI_Finalize();
    return 0;
}
