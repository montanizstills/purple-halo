FROM kalilinux/kali-rolling

WORKDIR /media

ARG DEBIAN_FRONTEND=noninteractive

COPY update-kali-docker-image-gpg-key.sh /media/sf_vbox/update-kali-docker-image-gpg-key.sh
COPY kali-archive-keyring.gpg /media/sf_vbox/kali-archive-keyring.gpg

RUN \
    sh sf_vbox/update-kali-docker-image-gpg-key.sh && \    
    apt-get update && \
    apt-get --fix-broken install && \
    apt-get full-upgrade -y && \
    apt-get install -y kali-linux-headless man-db hashcat-utils && \
    sudo apt-get update && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*


CMD ["/bin/bash"] 