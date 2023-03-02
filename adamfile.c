#include <stdio.h>
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <iostream>
#include <time.h>
#include <sys/time.h>

#define N 16
#define USECPSEC 1000000ULL
#define NUMPARTITIONS 4



//TO-DO ADAM: needs to be made into global, cpu, etc.
//TIMING KERNEL EXECUTION WITH CPU TIMERS:
unsigned long long myCPUTimer(unsigned long long start=0){

  timeval tv;
  gettimeofday(&tv, 0);
  return ((tv.tv_sec*USECPSEC)+tv.tv_usec)-start;
} //returns time in microseconds 


//LinkedList Construction
struct node {
int data;
struct node* next;
};

//length of LinkedList testing function
int LengthLinkedList(struct node* head) {
struct node* current = head;
int count = 0;
while (current != NULL) {
count++;
current = current->next;
}
return count;
}

//add Node function
void AddNode(struct node** headRef, int data) {
struct node* newNode = malloc(sizeof(struct node));
newNode->data = data;
newNode->next = *headRef; 
*headRef = newNode;
}


/*
for(int i = 0; i < NUMPARTITIONS*3; i++){
    iterate through each partition to add required number of nodes using functions above. 
 (insert nodes to list with specified values)


}
*/

int main(int argc, char** argv) {
    int process_Rank, size_Of_Cluster;
    int buf[100], provided;
   // MPI_Init(&argc, &argv);
    MPI_Init_thread(&argc, &argv, MPI_THREAD_MULTIPLE, &provided);
    MPI_Comm_size(MPI_COMM_WORLD, &size_Of_Cluster);
    MPI_Comm_rank(MPI_COMM_WORLD, &process_Rank);

    printf("Hello World from process %d of %d\n", process_Rank, size_Of_Cluster);
    printf("%d\n", provided);


   if ( process_Rank == 0 ) {
        /* Rank 0 sends an integer to each of the other process ranks */
        int i;
        int value = 0;
        for (i = 1; i < size_Of_Cluster; i++) {
            value = value + i;
            MPI_Send(&value, 1, MPI_INT, i, 0, MPI_COMM_WORLD);
	   // printf("%d\n", value);
        }
    }
    else {
        /* All other process ranks receive one number from Rank 0 */
        int value;
        MPI_Status status;
        MPI_Recv(&value, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, &status);
        printf("Rank %d received value %d\n",process_Rank, value);
	
    }

    MPI_Finalize();
    return 0;
}