#include <Windows.h>
#include <iostream>

typedef NTSTATUS(WINAPI* NtEnumerateSystemEnvironmentValuesEx_t)(
    ULONG InformationClass,
    PVOID Buffer,
    PULONG BufferLength
);

int main() {
    // Load ntdll.dll
    HMODULE ntdll = LoadLibraryW(L"ntdll.dll");
    if (!ntdll) {
        std::cout << "[!] Failed to load ntdll.dll" << std::endl;
        return 1;
    }

    // Try to get the function
    auto NtEnumerateSystemEnvironmentValuesEx =
    reinterpret_cast<NtEnumerateSystemEnvironmentValuesEx_t>(
        GetProcAddress(ntdll, "NtEnumerateSystemEnvironmentValuesEx")
    );

    if (NtEnumerateSystemEnvironmentValuesEx) {
        std::cout << "[+] NtEnumerateSystemEnvironmentValuesEx is present!" << std::endl;
        std::cout << "    => Your system likely supports UEFI and is not tampered." << std::endl;
    } else {
        std::cout << "[-] NtEnumerateSystemEnvironmentValuesEx NOT found!" << std::endl;
        std::cout << "    => System may be BIOS, or function is tampered/stripped." << std::endl;
    }

    // Cleanup
    FreeLibrary(ntdll);
    return 0;
}
