#include <stdio.h>
#include <mpi.h>
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
