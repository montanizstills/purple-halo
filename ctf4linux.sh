#!/bin/zsh

## TODO - create Kali Linux Virtual Machine (with VirtualBox) 
#
#
#####

# Install Misc Tools
sudo apt install -y nmap
snap install enum4linux
sudo apt install -y smbclient
sudo apt install -y smbmap
#sudo apt install -y crackmapexec
sudo apt install -y john
sudo apt install -y hydra
#sudo apt install -y ghidra
sudo apt install -y hashcat
sudo apt install -y nikto
sudo apt install -y gobuster
sudo apt install -y dirb
#sudo apt install -y wpscan
sudo apt install -y sqlmap
#sudo apt install -y burpsuite

# sudo apt install -y metasploit
# sudo snap metasploit-framework
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && \
  chmod 755 msfinstall && \
  ./msfinstall

#sudo apt install -y owasp-zap
#sudo apt install -y wpscanteam/tap/wpscan
#sudo apt install -y exploitdb
#sudo apt install -y sambabrew install -y binwalk
sudo apt install -y exiftool
#sudo apt install -y airckrack-ng
sudo apt install -y john



