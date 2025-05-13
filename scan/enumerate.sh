#!/bin/bash

# Check if at least one argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <target_ip1> [target_ip2 target_ip3 ...]"
    echo "Example: $0 192.168.1.1 10.0.0.1"
    exit 1
fi

# Create a timestamp for log identification
timestamp=$(date +%Y%m%d_%H%M%S)

# Process each target
for target_ip in "$@"; do
    echo "[+] Starting enumeration for $target_ip"
    
    # Create a directory for this target
    mkdir -p "$target_ip"
    
    # Start nmap scan in background and capture PID
    echo "[*] Enumerating open ports on $target_ip"
    nmap -A -sS "$target_ip" --top-ports 1000 -Pn -oN "${target_ip}/${target_ip}_nmap.out" -vv --reason > /dev/null 2>&1 &
    # nmap -A -sS "$target_ip" -p- -Pn -oN "${target_ip}/${target_ip}_nmap.out" -vv --reason > /dev/null 2>&1 &
    nmap_pid=$!
    
    # Start enum4linux in background with script
    echo "[*] Running enum4linux on $target_ip"
    script -c "enum4linux -a $target_ip" "${target_ip}/${target_ip}_e4l.out" > /dev/null 2>&1 &
    e4l_pid=$!
    
    # Start gobuster directory scan in background
    echo "[*] Starting gobuster directory scan on $target_ip"
    gobuster dir -u "http://$target_ip" -w /usr/share/wordlists/dirb/common.txt -o "${target_ip}/${target_ip}_gobuster_dir.out" > /dev/null 2>&1 &
    gobuster_dir_pid=$!
    
    # Start gobuster DNS scan in background
    echo "[*] Starting gobuster DNS scan on $target_ip"
    gobuster dns -d "$target_ip" -w /usr/share/wordlists/dns.txt -o "${target_ip}/${target_ip}_gobuster_dns.out" > /dev/null 2>&1 &
    gobuster_dns_pid=$!
    
    # Create a background process to monitor the completion of each task
    (
        # Wait for nmap to complete
        wait $nmap_pid
        echo "[+] $(date +"%T") - Nmap scan completed for $target_ip - saved to ${target_ip}/${target_ip}_nmap.out"
        
        # Wait for enum4linux to complete
        wait $e4l_pid
        echo "[+] $(date +"%T") - Enum4linux completed for $target_ip - saved to ${target_ip}/${target_ip}_e4l.out"
        
        # Wait for gobuster dir to complete
        wait $gobuster_dir_pid
        echo "[+] $(date +"%T") - Gobuster directory scan completed for $target_ip - saved to ${target_ip}/${target_ip}_gobuster_dir.out"
        
        # Wait for gobuster dns to complete
        wait $gobuster_dns_pid
        echo "[+] $(date +"%T") - Gobuster DNS scan completed for $target_ip - saved to ${target_ip}/${target_ip}_gobuster_dns.out"
        
        # Final completion message
        echo "[+] $(date +"%T") - All scans completed for $target_ip"
    ) &
    
    echo "[*] All scans initiated for $target_ip. Continuing to next target if any..."
    echo ""
done

echo "[*] All targets have been queued for scanning. Scans are running in background."
echo "[*] You can continue using the terminal. Status updates will appear as scans complete."