#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>

#define SMBIOS_FILE "/sys/firmware/dmi/entries/4-0/raw"
#define DATA_SIZE   0x32

static inline bool is_admin(void) {
    return geteuid() == 0;
}

int main(void) {
    if (!is_admin()) {
        fprintf(stderr, "Run the program as root, aborting\n");
        return EXIT_FAILURE;
    }

    unsigned char data[DATA_SIZE];
    FILE *fptr = fopen(SMBIOS_FILE, "rb");
    if (!fptr) {
        perror("SMBIOS file access error");
        return EXIT_FAILURE;
    }

    size_t bytes_read = fread(data, 1, DATA_SIZE, fptr);
    fclose(fptr);
    if (bytes_read != DATA_SIZE) {
        fprintf(stderr, "Could not read SMBIOS entry: expected %d bytes, got %zu\n", DATA_SIZE, bytes_read);
        return EXIT_FAILURE;
    }

    unsigned char processor_upgrade = data[0x19];
    unsigned char processor_family = data[0x06];
    unsigned short processor_family2 = (unsigned short)(data[0x29] << 8 | data[0x28]);

    printf("processor_upgrade: 0x%X\n", processor_upgrade);
    printf("processor_family: 0x%X\n", processor_family);
    printf("processor_family2: 0x%X\n", processor_family2);

    return EXIT_SUCCESS;
}
