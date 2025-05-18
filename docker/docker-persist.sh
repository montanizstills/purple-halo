# wrap in a trap -- to save on exit
# docker run --name kali-vbox --rm -v sf_vboxsf:/media/vboxsf -v $HOME/vboxsf-studio:/media/host -it kalilinux/kali-rolling tar -cvzf /media/host/mybackup.tar.gz /media/vboxsf

# run, unzip and keep container alive
# docker run --name kali-vbox -v sf_vboxsf:/media/vboxsf -v "$HOME/vboxsf-studio":/media/host -it kalilinux/kali-rolling bash -c 'tar -xvzf /media/host/mybackup.tar.gz -C /media/vboxsf; bash'


# use privilege to run nmap
docker run --privileged --rm -it -v sf_vbox:/media/sf_vbox -v $GDRIVE/dev/projects/purple-halo/:/med