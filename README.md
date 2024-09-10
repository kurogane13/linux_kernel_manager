# Created on September 10th, 2024

# Kernel Management Script

This script is designed to help manage Linux kernels. It can detect the package manager, show the currently running kernel, list available kernels, and allow you to install or uninstall specific kernels. Additionally, it supports switching kernels without rebooting by using `kexec-tools`.

## Features
1. **Detect Package Manager**: Automatically detects whether your system is using `apt`, `yum`, or `dnf` to manage packages.
2. **Show Running Kernel**: Displays the currently running kernel version and details.
3. **List Available Kernels**: Lists all available kernels that can be installed.
4. **Search for Kernels**: Allows searching for kernels using a regular expression or listing all available kernels.
5. **Install Kernel**: Allows you to install a specific kernel package.
6. **Uninstall Kernel**: Uninstall a specific kernel package.
7. **Switch Kernel Without Rebooting**: Uses `kexec-tools` to load a new kernel without a system reboot.

## How to Use the program

### 1. Clone the repo
### 2. Access the downloaded folder
```bash
cd linux_kernel_manager
```
### 3. Provide read and write permissions
```bash
sudo chmod +rx linux_kernel_manager.sh
```
### 4. Run the script with sudo
```bash
sudo bash linux_kernel_manager.sh
```
### 5. Navigate through the console using the numbered options
```bash
************************************
*      Kernel Management Console   *
************************************

1. Show running kernel

2. Install a kernel

3. Uninstall a kernel

4. Search for kernels

5. Show installed kernels | Switch to an existing kernel

6. Exit

Choose an option: 

```



