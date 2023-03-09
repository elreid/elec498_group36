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

// TO-DO ADAM: needs to be made into global, cpu, etc.
// TIMING KERNEL EXECUTION WITH CPU TIMERS:
// unsigned long long myCPUTimer(unsigned long long start = 0)
// {
//     timeval tv;
//     gettimeofday(&tv, 0);
//     return ((tv.tv_sec * USECPSEC) + tv.tv_usec) - start;
// } // returns time in microseconds

// LinkedList Construction
struct bogus_mpi_request{
    void *real_request;
    void *data;
    int partitions;
};

struct node
{
    struct bogus_mpi_request *request;
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
void AddNode(struct node **headRef, struct bogus_mpi_request *request)
{
    struct node *newNode = malloc(sizeof(struct node));
    newNode->request = request;
    newNode->next = *headRef;
    *headRef = newNode;
}

void printList(struct node *head)
{
    struct node *current = head;
    int i = 0;
    while (current != NULL)
    {
        printf("[%03d:%08X:%08X]:{rreq:%d,data:%d,parts:%d} ", i, current, current->next, current->request->real_request, current->request->data, current->request->partitions);
        if (current->next != NULL) printf(" -> \n");
        current = current->next;
        i++;
    }
    printf("\n");
}

int main(int argc, char **argv)
{
    struct bogus_mpi_request req1 = {NULL, NULL, 0};
    struct bogus_mpi_request req2 = {NULL, NULL, 0};
    
    struct node *head = NULL;
    AddNode(&head, &req1);
    AddNode(&head, &req2);
    printList(head);

}