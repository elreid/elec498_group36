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





struct node *populate_list()
{
    struct node *head = NULL;
    struct node *prev = NULL;

    for (int i = 0; i < NUMNODES; i += 1)
    {
        struct node *curr = (struct node *)malloc(sizeof(struct node));
        // curr->buffer = 0x0000000000000000 + i;
        int allocator = 0;
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
        printf("[%03d:%08X:%08X]:{buf:%08X,siz:%d,par:%d} ", i, current, current->next, current->buffer, current->size, current->partitions);
        if (current->next != NULL)
            printf(" -> \n");
        current = current->next;
        i++;
    }
    printf("\n");
}






void print_array(int *array, int length)
{
    for (int i = 0; i < length; i++)
    {
        if (i % 3 == 0)
            printf("\n");
        printf("%08X ", array[i]);
    }
    printf("\n");
}






void populateArray(struct node *head, int **arr)
{

    struct node *current = head;

    free(*arr);
    *arr = malloc((NUMNODES * 3) * sizeof(int));
    if (*arr == NULL)
    {
        printf("Void array.\n");
        return;
    }
    else
    {
        for (int i = 0; i < NUMNODES * 3; i += 3)
        {
            (*arr)[i] = current->buffer;
            (*arr)[i + 1] = current->size;
            (*arr)[i + 2] = current->partitions;
            current = current->next;
        }
    }
}







int main(int argc, char **argv)
{

    struct node *head = populate_list();
    *(head->buffer) = 2;
    printList(head);

    // int array[256] = {0};

    int *array;
    array = NULL;
    populateArray(head, &array);
    // change(&array, 256);
    print_array(array, NUMNODES * 3);

    return 0;
}