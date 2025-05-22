# unzip tar.gz to folder
# tar -xvzf 10.10.86.49_tcpdump.tar.gz -C 10.10.86.49_tcpdump

wpaclean 10.10.86.49_tcpdump/NinjaJc01-01.cleaned.cap 10.10.86.49_tcpdump/NinjaJc01-01.cap
aircrack-ng -e <access_point_name> 10.10.86.49_tcpdump/NinjaJc01-01.cleaned.cap 10.10.86.49_tcpdump/rockyou.txt
hashcat -m 22000 -a 0 10.10.86.49_tcpdump/hash.22000 10.10.86.49_tcpdump/rockyou.txtz