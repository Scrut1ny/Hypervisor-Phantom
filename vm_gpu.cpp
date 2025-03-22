#include <windows.h>
#include <iostream>

int main() {
    DISPLAY_DEVICEW dd;
    dd.cb = sizeof(DISPLAY_DEVICEW);
    DWORD deviceNum = 0;

    // Iterate through the display devices
    while (EnumDisplayDevicesW(nullptr, deviceNum, &dd, 0)) {
        std::wcout << L"Device #" << deviceNum << std::endl;
        std::wcout << L"Device Name: " << dd.DeviceName << std::endl;
        std::wcout << L"Device String: " << dd.DeviceString << std::endl;
        std::wcout << L"State Flags: " << dd.StateFlags << std::endl;  // Use StateFlags instead of State
        std::wcout << L"DeviceID: " << dd.DeviceID << std::endl;

        deviceNum++;
        std::wcout << L"--------------------" << std::endl;
    }

    return 0;
}

https://github.com/kernelwernel/VMAware/actions/runs/14009559144/artifacts/2801113057
