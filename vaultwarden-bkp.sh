#!/bin/bash

BACKUP_DIR=/mnt/ds02/backup/vaultwarden

# Verify containers exist before starting
if ! $(docker ps |grep -qi "vaultwarden"); then
	#echo "App Not Found"
	exit 1
fi


# Reset Temp Directory in case files were left behind
if [ -d "$BACKUP_DIR/temp" ]; then
	#echo "folder exists, resetting"
	rm -rf $BACKUP_DIR/temp/
else
	mkdir $BACKUP_DIR/temp
fi

# Get Container Version
#cat /mnt/.ix-apps/app_configs/vaultwarden/metadata.yaml|grep human_version| awk -F': ' '{print $2}' > $BACKUP_DIR/temp/version
docker ps -a --format "table {{.Names}}\t{{.Image}}" |grep -i vaultwarden > $BACKUP_DIR/temp/version

# Backup Vaultwarden Database
#echo "beginning backup"
#echo "backing up database"
docker exec -i ix-vaultwarden-postgres-1 pg_dump -U vaultwarden -F t | gzip > $BACKUP_DIR/temp/postgres.tar.gz

# Backup Vaultwarden Folder
#echo "stopping container"
midclt call app.stop vaultwarden

# Verify container has stopped
until [ $(midclt call app.query '[["name", "=", "vaultwarden"]]' | jq -r '.[].state') = "STOPPED" ]; do
	#echo "waiting .."
	sleep 2
done

#echo "container stopped"
sleep 5

# Backup appdata
tar -czvf $BACKUP_DIR/temp/appdata.tar.gz -C /mnt/ds02/apps/vaultwarden/appdata .
sleep 5


# Start Container and Verify
#echo "starting container"
midclt call app.start vaultwarden

# Fix this later to send an alert if the container fails to start
#until [ $(midclt call app.query '[["name", "=", "vaultwarden"]]' | jq -r '.[].state') = "RUNNING" ]; do
#	echo "waiting.."
#	sleep 2
#done
#echo "container started"

## Tar the appdata and postgres
tar -czf $BACKUP_DIR/vaultwarden-$(date +%Y-%m-%d).tar.gz -C $BACKUP_DIR/temp .


# Cleanup Files
rm -rf $BACKUP_DIR/temp/


#echo "process complete."
exit 0
