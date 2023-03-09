#include <stdio.h>
// #include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
// #include <iostream>
#include <time.h>
#include <sys/time.h>

#define N 16
#define USECPSEC 1000000ULL
#define NUMPARTITIONS 4
#define NUMNODES 5

// TO-DO ADAM: needs to be made into global, cpu, etc.
// // TIMING KERNEL EXECUTION WITH CPU TIMERS:
// unsigned long long myCPUTimer(unsigned long long start = 0)
// {

//     timeval tv;
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
// void AddNode(struct node **headRef, int data)
// {
//     struct node *newNode = malloc(sizeof(struct node));
//     newNode->data = data;
//     newNode->next = *headRef;
//     *headRef = newNode;
// }

struct node *populate_list()
{
    struct node *head = NULL;
    struct node *prev = NULL;

    for (int i = 0; i < NUMNODES; i += 1)
    {
        struct node *curr = (struct node *)malloc(sizeof(struct node));
        curr->buffer = 0x0000000000000000 + i;
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

// void populateArray(struct node *head, int NUMNODES)
// {

//     struct node *current = head;

//     for (int i = 0; i < NUMNODES; i++)
//     {
//         tempArray[i] = current->buffer;
//         tempArray[i + 1] = current->size;
//         tempArray[i + 2] = current->partitions;
//         current = current->next;
//     }
// }

void printList(struct node *head)
{
    struct node *current = head;
    int i = 0;

    while (current != NULL)
    {
        printf("[%03d:%08X:%08X]:{buf:%d,siz:%d,par:%d} ", i, current, current->next, current->buffer, current->size, current->partitions);
        if (current->next != NULL) printf(" -> \n");
        current = current->next;
        i++;
    }
    printf("\n");
}

int main(int argc, char **argv)
{
    
    struct node *head = populate_list();
    printList(head);


    return 0; 
}