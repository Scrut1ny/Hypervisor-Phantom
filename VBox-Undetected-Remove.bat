:: ==================================================
::  VBox-Undetected
:: ==================================================
::  Dev  - Scut1ny
::  Help - 
::  Link - https://github.com/Scrut1ny/VBox-Undetected
:: ==================================================

@echo off
setlocal enableDelayedExpansion


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