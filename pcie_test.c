#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>

#define PCIE_DEVICE_VENDOR_ID 0x1234
#define PCIE_DEVICE_DEVICE_ID 0x5678
#define PCIE_DEVICE_BAR 0 // BAR number of the PCIe device

int main()
{
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0)
    {
        perror("open");
        exit(EXIT_FAILURE);
    }

    // Find the PCIe device
    int bus_id = 0x01;
    int device_id = 0x00;
    int function_id = 0x0;
    unsigned long pcie_device_address = 0;

    printf("Hello turtle");

    // char line[256];
    // FILE *fp = popen("lspci", "r");
    // while (fgets(line, sizeof(line), fp))
    // {
    //     if (sscanf(line, "%02x:%02x.%d", &bus_id, &device_id, &function_id) == 3)
    //     {
    //         unsigned int vendor_id, device;
    //         sscanf(line + 8, "%4hx:%4hx", &vendor_id, &device);
    //         if (vendor_id == PCIE_DEVICE_VENDOR_ID && device == PCIE_DEVICE_DEVICE_ID)
    //         {
    //             break;
    //         }
    //     }
    // }
    // pclose(fp);

    // return 0;

    // // Map the PCIe device memory to user space
    // unsigned long bar_size = 0;
    // char sysfs_path[256];
    // sprintf(sysfs_path, "/sys/bus/pci/devices/%04x:%02x:%02x.%d/resource%d",
    //         PCIE_DEVICE_VENDOR_ID, bus_id, device_id, function_id, PCIE_DEVICE_BAR);
    // FILE *sysfs_file = fopen(sysfs_path, "r");
    // if (sysfs_file == NULL)
    // {
    //     perror("fopen");
    //     exit(EXIT_FAILURE);
    // }
    // fscanf(sysfs_file, "%lx", &pcie_device_address);
    // fclose(sysfs_file);

    // sprintf(sysfs_path, "/sys/bus/pci/devices/%04x:%02x:%02x.%d/size%d",
    //         PCIE_DEVICE_VENDOR_ID, bus_id, device_id, function_id, PCIE_DEVICE_BAR);
    // sysfs_file = fopen(sysfs_path, "r");
    // if (sysfs_file == NULL)
    // {
    //     perror("fopen");
    //     exit(EXIT_FAILURE);
    // }
    // fscanf(sysfs_file, "%lx", &bar_size);
    // fclose(sysfs_file);

    // void *pcie_device_ptr = mmap(NULL, bar_size, PROT_WRITE, MAP_SHARED, fd, pcie_device_address);
    // if (pcie_device_ptr == MAP_FAILED)
    // {
    //     perror("mmap");
    //     exit(EXIT_FAILURE);
    // }

    // // Write to the PCIe device memory
    // unsigned int data = 0x12345678;
    // volatile unsigned int *pcie_reg = (volatile unsigned int *)(pcie_device_ptr + 0x10);
    // *pcie_reg = data;

    // Un
    // This is a little tester comment
    // Tester two
}
