#!/bin/bash
if [  "$#" -ne 1 ]; then
    echo "Usage: $0 <target_ip> "
fi
echo "$@    overwrite.uploadvulns.thm shell.uploadvulns.thm java.uploadvulns.thm annex.uploadvulns.thm magic.uploadvulns.thm jewel.uploadvulns.thm demo.uploadvulns.thm" >> /etc/hosts