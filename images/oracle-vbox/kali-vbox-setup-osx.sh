#!/bin/bash

# Check if ISO path is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/kali-linux-arm64.iso"
    echo "Please provide the path to a Kali Linux ARM64 ISO file"
    exit 1
fi

# VM Name
VM_NAME="KaliLinuxARM"
# ISO path from command line parameter
ISO_PATH="$1"

# Detect if running on Apple Silicon
if [ "$(uname -m)" = "arm64" ]; then
    echo "Detected Apple Silicon (ARM64) architecture"
    OS_TYPE="Debian_ARM64"
    echo "WARNING: VirtualBox on Apple Silicon is experimental and has limitations"
    echo "Consider using UTM for better ARM virtualization support"
    
    # Check if the ISO is ARM-compatible
    if [[ "$ISO_PATH" != *"arm64"* ]] && [[ "$ISO_PATH" != *"aarch64"* ]]; then
        echo "WARNING: The ISO file doesn't appear to be ARM64-compatible"
        echo "For ARM64 Macs, you need an ARM64 version of Kali Linux"
        read -p "Do you want to continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    echo "Detected x86_64 architecture"
    OS_TYPE="Debian_64"
fi

# Create VM
echo "Creating virtual machine: $VM_NAME"
VBoxManage createvm --name "$VM_NAME" --ostype "$OS_TYPE" --register

# Configure VM - reduced resources for ARM emulation which is more resource-intensive
VBoxManage modifyvm "$VM_NAME" --memory 2048 --cpus 1
VBoxManage modifyvm "$VM_NAME" --vram 128 --graphicscontroller vmsvga
VBoxManage modifyvm "$VM_NAME" --nic1 nat
VBoxManage modifyvm "$VM_NAME" --audio none
VBoxManage modifyvm "$VM_NAME" --usb on

# Create and attach storage
echo "Creating virtual disk"
VBoxManage createhd --filename "$VM_NAME.vdi" --size 40960 --format VDI

echo "Setting up storage controllers"
VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VM_NAME.vdi"
VBoxManage storagectl "$VM_NAME" --name "IDE Controller" --add ide --controller PIIX4
VBoxManage storageattach "$VM_NAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$ISO_PATH"

# Start VM
echo "Starting virtual machine"
if [ "$(uname -m)" = "arm64" ]; then
    echo "Note: On Apple Silicon, performance may be significantly reduced"
    echo "VirtualBox emulates x86 rather than using native ARM virtualization"
    
    # Use headless mode for potentially better performance on ARM
    read -p "Would you like to start in headless mode? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        VBoxManage startvm "$VM_NAME" --type headless
        echo "VM started in headless mode. To connect to it, use:"
        echo "VBoxManage controlvm \"$VM_NAME\" screenshotpng screenshot.png"
        echo "or"
        echo "VBoxHeadless --startvm \"$VM_NAME\""
    else
        VBoxManage startvm "$VM_NAME"
    fi
else
    VBoxManage startvm "$VM_NAME"
fi