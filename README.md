<div align="center">

# 🕵️ Advanced Malware Analysis Tool 🕵️

This tool provides an automated setup solution designed to evade detection from advanced malware, enabling thorough analysis. It employs a highly customized version of QEMU/KVM, EDK2, and the Linux Kernel. This also spoofs many unique hypervisor identifiers, effectively disguising the environment. This setup enhances the accuracy and reliability of malware analysis by minimizing the risk of detection.

</div>

![pic](https://github.com/user-attachments/assets/1329110e-62f9-456b-9816-83975d52a9df)







## 📖 Setup Instruction Guide

<details>
<summary>Expand for details...</summary>

```
# 1. Clone into the repository
git clone --single-branch --depth=1 https://github.com/Scrut1ny/Hypervisor-Phantom

# 2. CD into the repository
cd Hypervisor-Phantom

# 3. Set executable permissions
sudo chmod +x *.sh
```

</details>








## 📝 Documentation & References

<details>
<summary>Expand for details...</summary>

- **Official**
  - [QEMU v9.1.0](https://qemu.readthedocs.io/en/v9.1.0/)
    - [Man Page (command args)](https://qemu.readthedocs.io/en/v9.1.0/system/qemu-manpage.html)
    - [Hyper-V Enlightenments](https://www.qemu.org/docs/master/system/i386/hyperv.html)
  - [KVM for x86 systems (Linux Kernel)](https://www.kernel.org/doc/html/next/virt/kvm/x86/index.html)
  - [Domain XML format](https://libvirt.org/formatdomain.html)
  - [ACPI System Management Bus Interface Specification](https://uefi.org/specs/ACPI/6.5/13_System_Mgmt_Bus_Interface_Specification.html)
  - [System Management BIOS (SMBIOS) Reference Specification](https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf)
- **General**
  - [https://evasions.checkpoint.com/](https://evasions.checkpoint.com/)
  - [https://r0ttenbeef.github.io/](https://r0ttenbeef.github.io/Deploy-Hidden-Virtual-Machine-For-VMProtections-Evasion-And-Dynamic-Analysis/)
  - [https://secret.club/](https://secret.club/)
    - [how-anti-cheats-detect-system-emulation.html](https://secret.club/2020/04/13/how-anti-cheats-detect-system-emulation.html)
    - [battleye-hypervisor-detection.html](https://secret.club/2020/01/12/battleye-hypervisor-detection.html)
- **Reddit Posts**
  - [spoof_and_make_your_vm_undetectable_no_more](https://www.reddit.com/r/VFIO/comments/i071qx/spoof_and_make_your_vm_undetectable_no_more/)
  - [be_is_banning_kvm_on_r6](https://www.reddit.com/r/VFIO/comments/hts1o1/be_is_banning_kvm_on_r6/)
- **Unknowncheats**
  - [418885-kvm-detection-fixes.html](https://www.unknowncheats.me/forum/escape-from-tarkov/418885-kvm-detection-fixes.html) 
- **Git Repos**
  - [pve-patch](https://github.com/Distance10086/pve-patch)
  - [kvm-hidden](https://gitlab.com/DonnerPartyOf1/kvm-hidden)
  - [KVM-Spoofing](https://github.com/A1exxander/KVM-Spoofing)
  - [linux-5.15-hardened-kvm-svm-qemu-win10](https://alt.deliktas.de/git/adeliktas/linux-5.15-hardened-kvm-svm-qemu-win10)
- **VirtualBox**
  - [VirtualBox RDTSC Fix](https://www.reddit.com/r/virtualbox/comments/g6ky8a/disabling_vm_exit_for_rdtsc_access/)
  - [https://forums.virtualbox.org/viewtopic.php?t=78859](https://forums.virtualbox.org/viewtopic.php?t=78859)
  - [https://forums.virtualbox.org/viewtopic.php?t=81600](https://forums.virtualbox.org/viewtopic.php?t=81600)
  - [https://superuser.com/questions/625648/virtualbox-how-to-force-a-specific-cpu-to-the-guest](https://superuser.com/questions/625648/virtualbox-how-to-force-a-specific-cpu-to-the-guest)
  - [https://berhanbingol.medium.com/virtualbox-detection-anti-detection-30614691f108](https://berhanbingol.medium.com/virtualbox-detection-anti-detection-30614691f108)
  - [https://github.com/d4rksystem/VBoxCloak](https://github.com/d4rksystem/VBoxCloak)
  - [https://github.com/nsmfoo/antivmdetection](https://github.com/nsmfoo/antivmdetection)
- **VMware**
  - [https://sanbarrow.com/vmx.html](https://sanbarrow.com/vmx.html)
  - [https://www.hexacorn.com/blog/2014/08/25/protecting-vmware-from-cpuid-hypervisor-detection/](https://www.hexacorn.com/blog/2014/08/25/protecting-vmware-from-cpuid-hypervisor-detection/)
  - [https://rayanfam.com/topics/defeating-malware-anti-vm-techniques-cpuid-based-instructions/](https://rayanfam.com/topics/defeating-malware-anti-vm-techniques-cpuid-based-instructions/)
  - [https://tulach.cc/bypassing-vmprotect-themida-vm-checks-in-vmware/](https://tulach.cc/bypassing-vmprotect-themida-vm-checks-in-vmware/)

</details>






