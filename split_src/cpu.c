#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>
#include <mpi.h>
#include <cuda_runtime.h>


#define N 16
#define USECPSEC 1000000ULL
#define NUMPARTITIONS 4
#define NUMNODES 10
// #define TPB 16	//num threads in a block
// #define D 256

// callable cuda functions from "gpu.cu"
void launch_master(int * d_arr, int * check_sum, int num_nodes);
void launch_matrix_multiply();

// GLOBAL CHECKSUM VARIABLE
int  CHECKSUM[NUMNODES] = {0};

// TO-DO ADAM: needs to be made into global, cpu, etc.
// TIMING KERNEL EXECUTION WITH CPU TIMERS:
unsigned long long myCPUTimer(unsigned long long start)
{
    struct timeval tv;
    gettimeofday(&tv, 0);
    return ((tv.tv_sec * USECPSEC) + tv.tv_usec) - start;
} // returns time in microseconds

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
    clock_t start_test, end_test;
	double cpu_time_used;
	start_test = clock();

    struct node *head = NULL;
    struct node *prev = NULL;

    for (int i = 0; i < NUMNODES; i += 1)
    {
        struct node *curr = (struct node *)malloc(sizeof(struct node));
        curr->buffer = 0x00000000 + i;
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

    end_test = clock();
	cpu_time_used = ((double)(end_test - start_test));
	printf("populate_list time:\t\t%0.2f\n", cpu_time_used);

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
    clock_t start_test, end_test;
	double cpu_time_used;
	start_test = clock();

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
            (*arr)[i]    = (int)(current->buffer);
            // (*arr)[i]       = i; // TODO: Remove and change back
            (*arr)[i + 1]   = current->size;
            (*arr)[i + 2]   = current->partitions;
            current         = current->next;
        }
    }

    end_test = clock();
	cpu_time_used = ((double)(end_test - start_test));
	printf("populateArray time:\t\t%0.2f\n", cpu_time_used);
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


int main(int argc, char **argv)
{
    int process_Rank, size_Of_Cluster;
    int buf[100], provided;
    // MPI_Init(&argc, &argv);
    MPI_Init_thread(&argc, &argv, MPI_THREAD_MULTIPLE, &provided);
    MPI_Comm_size(MPI_COMM_WORLD, &size_Of_Cluster);
    MPI_Comm_rank(MPI_COMM_WORLD, &process_Rank);

    // printf("Hello World from process %d of %d: ", process_Rank, size_Of_Cluster);
    // printf("Provides = %d\n", provided);

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
    // printList(head); // TODO: Remove this line

    /**
     * @brief Allocate memory for the array on the CPU and GPU,
     * then populating the arraay and checking it 
     * 
     */

    //do host and device memory inits
    size_t size_list_arr = (NUMNODES*3)*sizeof(int);

    int *h_list_arr = (int*)malloc(size_list_arr);

    populateArray(head, &h_list_arr);
    // printArray(h_list_arr, NUMNODES * 3); // TODO: Remove this line

    int *d_list_arr;
    cudaMalloc( (void**) &d_list_arr , size_list_arr );

    // matrix_add(h_A, h_B, h_C, size);
    cudaMemcpy(d_list_arr, h_list_arr, size_list_arr, cudaMemcpyHostToDevice);

    launch_master(h_list_arr, CHECKSUM, NUMNODES);

    // printf("CHECKSUM in cpu.c: \n");
    // printArray(CHECKSUM, NUMNODES);

    // printf("h_list_arr in cpu.c: \n");
    // printArray(h_list_arr, NUMNODES * 3);

    // launch_matrix_multiply();

    cudaFreeHost(h_list_arr);

    cudaFree(d_list_arr);

    // Finishing touches
    MPI_Finalize();
    return 0;
}
