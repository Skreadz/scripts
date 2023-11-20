#!/bin/bash

## Script sauvegarde toutes les 10 min un dossier avec le nom et la date avec le fonction TAR
 
## sudo apt install bzip2
 
## sudo mkdir /BACKUP
 
## sudo nano backup.sh
 
SOURCE_DIR="/etc"
BACKUP_DIR="/BACKUP" ## Backup du dossier etc dans le dossier BACKUP
 
while true
do
    TIMESTAMP=$(date +%Y%m%d.%H:%M:%S)
    BACKUP_FILE="backup_$TIMESTAMP.tar.gz"
 
    tar -Pcjf "$BACKUP_DIR/$BACKUP_FILE" "$SOURCE_DIR"
 
    echo $$
    sleep 600
   
done
 
## kill -9 numero de PID