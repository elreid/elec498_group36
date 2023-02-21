#include <stdio.h>

//Separates and runs code for a defined numThreads
int numThreads = 16;

void MultiBlock (){
    //Define the number of threads to be in each block
    int threadsPerBlock = 1;

    //Define the number of blocks to be created depending on block size and numThreads
    int numBlocks = ceilf(numThreads/threadsPerBlock);
    //For-loop to run the code in thread blocks
    for (int j = 0; numBlocks > j; j++){
        for (int i = 0; threadsPerBlock > i ; i++){
            
            ////// PLACE FUNCTION CALL HERE //////

        }
    }
}

int main(int argc, char argv[]){
    //Allocate Memory
 	int *h_A = (int*)malloc(sizeof(int));
    int *h_C1 = (int*)malloc(sizeof(int));

    //Block threading function call
    MultiBlock();

    //Free memory
    free(*h_A);
    free(*h_C1); 
    return 0;
}