#!/bin/bash
# This script is used to update the Kali Linux GPG keyring for Docker images.

set -x
expected_sha1="603374c107a90a69d983dbcb4d31e0d6eedfc325"
key_ring_path="/media/sf_vbox/kali-archive-keyring.gpg"

if ! [ -f $key_ring_path ]; then
  echo "File /media/sf_vbox/kali-archive-keyring.gpg does not exist."
  echo "Please download it from https://www.kali.org/blog/new-kali-archive-signing-key/ and upload it to the image docker 'run -v /media/sf_vbox:/media/sf_vbox -it kali-vbox'"
  keyring_path="kali-archive-keyring.gpg"
fi

# cp "$keyring_path" /usr/share/keyrings/kali-archive-keyring.gpg
cp /media/sf_vbox/kali-archive-keyring.gpg /usr/share/keyrings/kali-archive-keyring.gpg

actual_sha1=$(sha1sum $key_ring_path | cut -d' ' -f1)

if [ "$actual_sha1" != "$expected_sha1" ]; then
  echo "SHA1 checksum does not match, please check https://www.kali.org/blog/new-kali-archive-signing-key/"
  exit 1
fi

echo "Kali Linux GPG keyring updated successfully."
