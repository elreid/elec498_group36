/**
 * @file main.cu
 * @author Vanya Kootchin & Adam Bayley
 * @brief
 * @version 0.1
 * @date 2023-04-01
 *
 * @copyright Copyright (c) 2023
 *
 */
/**
 *
 *
 *
 */
/********* INITIALIZATION *********/
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
/**
 *
 *
 *
 */
/***** GLOBAL VARIABLES *****/
#define TPB 16                // num threads in a block
#define D 1024                // num of elements in a row/column
#define N 16                  // num of elements in a matrix
#define USECPSEC 1000000ULL   // Idk what this is, cuda specific things
#define NUMPARTITIONS 10      // Number of partitions for OMPI?// TODO: Remove
#define NUMNODES 5            // Number of nodes in the graph
int CHECKSUM[NUMNODES] = {0}; // Global Checksum array
/**
 *
 *
 *
 */
/********* STRUCTURES *********/
struct node
{
    /**
     * Linked list node structure
     *
     */
    int buffer;
    int size;
    int partitions;
    struct node *next;
};

struct workload
{
    /**
     * GPU Workload Structure
     *
     */
    int *data_arr;
    int *check_sum;
    int id;
    int numnodes;
};
/**
 *
 *
 *
 */
/********* FUNCTIONS *********/
struct node *populate_list()
{
    /**
     *  Populate a linked list with the following values:
     *  - Returns a node structure that points to the head of the linked list
     */
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
    return head;
}

void print_list(struct node *head)
{
    /**
     *  Print the linked list
     *
     */
    struct node *current = head;
    int i = 0;

    while (current != NULL)
    {
        printf("[%03d:%08X:%08X]:{buf:%08X,siz:%03d,par:%03d} ", i, current, current->next, current->buffer, current->size, current->partitions);
        if (current->next != NULL)
            printf(" -> \n");
        current = current->next;
        i++;
    }
    printf("\n");
}

void populate_array(struct node *head, int **arr)
{
    /**
     *  Make the array from the linekd list
     *  - Returns nothing, takes in a pointer to the head and a pointer to the array
     */
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
            (*arr)[i]       = current->buffer;
            (*arr)[i + 1]   = current->size;
            (*arr)[i + 2]   = current->partitions;
            current         = current->next;
        }
    }
}

void print_array(int *array, int length)
{
    /**
     * @ Print the array
     *
     */
    for (int i = 0; i < length; i++)
    {
        if (i % 3 == 0)
            printf("\n");
        printf("%08X ", array[i]);
    }
    printf("\n");
}

/**
 *
 *
 *
 */
/********* MAIN *********/
int main(int argc, char **argv)
{

    struct node *head = populate_list();
    print_list(head); // TODO: Remove this line

    // do host and device memory inits
    size_t size_list_arr = (NUMNODES * 3) * sizeof(int);

    int *h_list_arr = (int *)malloc(size_list_arr);

    populate_array(head, &h_list_arr);
    print_array(h_list_arr, NUMNODES * 3); // TODO: Remove this line

    return 0;
}