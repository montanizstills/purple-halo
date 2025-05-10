#!/bin/bash
set -x
cp /media/sf_vbox/kali-archive-keyring.gpg /usr/share/keyrings/kali-archive-keyring.gpg
expected_sha1="603374c107a90a69d983dbcb4d31e0d6eedfc325"
sha1sum /usr/share/keyrings/kali-archive-keyring.gpg | grep -q "$expected_sha1" || {
    echo "The SHA1 checksum does not match. Please check the file."
    exit 1
}