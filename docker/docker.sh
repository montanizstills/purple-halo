#!/bin/bash
set -e

IMAGE_NAME="kalilinux/kali-rolling" # docker container ps -la --format '{{json .}}' | jq -r 'select(.Image == "kalilinux/kali-rolling") | .Names'
CONTAINER_NAME="kali-vbox" # CONTAINER_NAME="kali-vbox-$(getCurrentTimestamp)"
BACKUP_FILE="$(echo $CONTAINER_NAME)-backup.tar.gz"
VOLUME_NAME="sf_vboxsf"


echo "Attempting to backup container: '$CONTAINER_NAME' to $BACKUP_FILE"
if [[ $(docker container ps -a --format "{{.Names}}" | grep $CONTAINER_NAME) == $CONTAINER_NAME ]]; then
    echo "Previously existing container, '$CONTAINER_NAME' found. Backing up image OS file system."
    create_backup
    # upload_to_s3
    delete_container
else
    echo "Existing container not found."
fi
# upload_to_s3
echo "Uploading $BACKUP_FILE to S3"
aws s3 cp $BACKUP_FILE s3://montaniz-bucket/$BACKUP_FILE
restore_from_backup 
run


########## Functions ##########
getCurrentTimestamp() {
    date +%Y%m%d%H%M%s
}

create_backup(){
     docker export -o $BACKUP_FILE $VOLUME_NAME
}

restore_from_backup(){
    echo "Restoring from $BACKUP_FILE."
    docker import $BACKUP_FILE $CONTAINER_NAME > /dev/null; 
}

delete_container(){
    echo "Deleting existing container '$CONTAINER_NAME'"
    docker container rm $CONTAINER_NAME > /dev/null
}

run(){
    echo "Running container '$CONTAINER_NAME'"
    docker run --name $CONTAINER_NAME -it $IMAGE_NAME
    # docker run -it --name kali-vbox-container kali-vbox /bin/bash
}

upload_to_s3(){
    echo "Uploading $BACKUP_FILE to S3"
    aws s3 cp $BACKUP_FILE s3://montaniz-bucket/$BACKUP_FILE
}
