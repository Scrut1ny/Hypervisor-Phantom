#include <unistd.h>
#include <stdbool.h>
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>

bool is_admin() {
    const uid_t uid = getuid();
    const uid_t euid = geteuid();

    return (
        (uid != euid) ||
        (euid == 0)
    );
}


int main() {
    if (!is_admin()) {
        fprintf(stderr, "Run the program as root, aborting\n");
        return 1;
    }

    // situated in type 4 handle 0 of the smbios
    const char* file = "/sys/firmware/dmi/entries/4-0/raw";

    unsigned char data[0x32];

    FILE *fptr = fopen(file, "rb");  // r for read, b for binary

    if (fptr == NULL) {
        perror("SMBIOS file access error");
        return 1;
    }

    fread(data, sizeof(data), 1, fptr);

    fclose(fptr);

    unsigned char processor_upgrade = data[0x19];
    unsigned short processor_family = data[0x06];
    unsigned short processor_family2 = (data[0x29] << 8 | data[0x28]);

    printf("processor_upgrade: 0x%X\n", processor_upgrade);
    printf("processor_family: 0x%X\n", processor_family);
    printf("processor_family2: 0x%X\n", processor_family2);

    return 0;
}