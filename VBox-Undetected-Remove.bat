:: ==================================================
::  VBox-Undetected
:: ==================================================
::  Dev  - Scut1ny
::  Help - 
::  Link - https://github.com/Scrut1ny/VBox-Undetected
:: ==================================================

@echo off
setlocal enableDelayedExpansion


fltmc >nul 2>&1 || (
    echo( && echo   [33m# Administrator privileges are required. && echo([0m
    PowerShell Start -Verb RunAs '%0' 2> nul || (
        echo   [33m# Right-click on the script and select "Run as administrator".[0m
        >nul pause && exit 1
    )
    exit 0
)


:: HKLM\HARDWARE\ACPI

:: DSDT
PowerShell Rename-Item -Path "'HKLM:\HARDWARE\ACPI\DSDT\VBOX__'" -NewName "'ALASKA'" -Force
PowerShell Rename-Item -Path "'HKLM:\HARDWARE\ACPI\DSDT\ALASKA\VBOXBIOS'" -NewName "'A_M_I_'" -Force

:: FADT
PowerShell Rename-Item -Path "'HKLM:\HARDWARE\ACPI\FADT\VBOX__'" -NewName "'ALASKA'" -Force
PowerShell Rename-Item -Path "'HKLM:\HARDWARE\ACPI\FADT\ASUS__'" -NewName "'ALASKA'" -Force
PowerShell Rename-Item -Path "'HKLM:\HARDWARE\ACPI\FADT\ALASKA\VBOXFACP'" -NewName "'A_M_I_'" -Force

:: RSDT
PowerShell Rename-Item -Path "'HKLM:\HARDWARE\ACPI\RSDT\VBOX__'" -NewName "'ALASKA'" -Force
PowerShell Rename-Item -Path "'HKLM:\HARDWARE\ACPI\RSDT\ASUS__'" -NewName "'ALASKA'" -Force
PowerShell Rename-Item -Path "'HKLM:\HARDWARE\ACPI\RSDT\ALASKA\VBOXXSDT'" -NewName "'A_M_I_'" -Force

:: SSDT
PowerShell Rename-Item -Path "'HKLM:\HARDWARE\ACPI\SSDT\VBOX__'" -NewName "'AMD'" -Force
PowerShell Rename-Item -Path "'HKLM:\HARDWARE\ACPI\SSDT\AMD\VBOXCPUT'" -NewName "'AmdTable'" -Force




:: HKLM\HARDWARE\DESCRIPTION\System

reg add "HKLM\HARDWARE\DESCRIPTION\System" /v "SystemBiosDate" /t REG_SZ /d "04/23/21" /f
reg add "HKLM\HARDWARE\DESCRIPTION\System" /v "VideoBiosVersion" /t REG_MULTI_SZ /d "Version 90.06.2E.40.0D\0Version 90.06.2E.40.0D\0Version 90.06.2E.40.0D" /f