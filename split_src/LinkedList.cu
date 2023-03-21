#define NUMNODES 5

void conversion(Node *head, int* IOVector, int length){
    Node *current = head;

    int i = 0;

    while(current != NULL && i < length*3){

        IOVector[i] = current-> size;
        IOVector[i+1] = current->partition;
        IOVector[i+2] = current->buffer;
        current = current->next;
        i+= 3;
    }
}

int *h_io = (int *)malloc(NUMNODES*3*sizeof(int));
int* d_io;

cudaMalloc((void**)&d_io, (NUMNODES*3*sizeof(int)));

conversion(*head, *h_io, NUMNODES);

cudamemcpy(d_io,h_io, NUMNODES*3*sizeof(int), cudaMemcpyHostToDevice);
