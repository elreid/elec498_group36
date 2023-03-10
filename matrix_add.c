#include <stdio.h>

#define D   16

void matrix_add(int a*, int b*, int c*, int size){
    int i, j;
    for (i = 0; i < size; i++){
        for (j = 0; j < size ; j++){
            c[i*size+j] = a[i*size+j] + b[i*size+j];
        }
    } 
}

int main(){
    //do host and device memory inits
    size_t size = D*D*sizeof(int);

    int *h_A = (int*)malloc(size);
    int *h_B = (int*)malloc(size);
    int *h_C = (int*)malloc(size);

    int *d_A, *d_B, *d_C;
	cudaMalloc((void**)&d_A, size);
	cudaMalloc((void**)&d_B, size);
	cudaMalloc((void**)&d_C, size);

    matrix_add(h_A, h_B, h_C, size);

    cudaFreeHost(h_A);
    cudaFreeHost(h_B);
    cudaFreeHost(h_C);

    cudaFree(d_A);
	cudaFree(d_B);
	cudaFree(d_C);


}