#!/bin/bash

APP_NAME='gitea'
BACKUP_DIR=/mnt/ds02/backup/$APP_NAME

# Verify containers exist before starting
if ! $(docker ps |grep -qi "$APP_NAME"); then
	##echo "App Not Found"
	exit 1
fi


# Reset Temp Directory in case files were left behind
if [ -d "$BACKUP_DIR/temp" ]; then
	##echo "folder exists, resetting"
	rm -rf $BACKUP_DIR/temp/
else
	mkdir $BACKUP_DIR/temp
fi

# Get Version
docker ps -a --format "table {{.Names}}\t{{.Image}}" |grep -i $APP_NAME > $BACKUP_DIR/temp/version

# Backup Gitea
docker exec -i ix-gitea-gitea-1 gitea dump -c /etc/gitea/app.ini
mv /mnt/ds02/apps/gitea/config/*.zip $BACKUP_DIR/temp/

# Backup Gitea Database
#echo "beginning backup"
#echo "backing up database"

docker exec -i ix-gitea-postgres-1 pg_dump -U gitea -F t | gzip > $BACKUP_DIR/temp/postgres.tar.gz

# Backup Gitea Folder
##echo "stopping container"
#midclt call app.stop gitea

# Verify container has stopped
#until [ $(midclt call app.query '[["name", "=", "gitea"]]' | jq -r '.[].state') = "STOPPED" ]; do
	##echo "waiting .."
	#sleep 2
#done

##echo "container stopped"
#sleep 5

# Backup appdata
#tar -czvf $BACKUP_DIR/temp/appdata.tar.gz -C /mnt/ds02/apps/gitea/appdata .
#tar -czvf $BACKUP_DIR/temp/config.tar.gz -C /mnt/ds02/apps/gitea/config .
#sleep 5


# Start Container and Verify
##echo "starting container"
#midclt call app.start gitea

# Fix this later to send an alert if the container fails to start
#until [ $(midclt call app.query '[["name", "=", "gitea"]]' | jq -r '.[].state') = "RUNNING" ]; do
#	#echo "waiting.."
#	sleep 2
#done
##echo "container started"

## Tar the appdata and postgres
tar -czf $BACKUP_DIR/gitea-$(date +%Y-%m-%d).tar.gz -C $BACKUP_DIR/temp .


# Cleanup Files
rm -rf $BACKUP_DIR/temp/


##echo "process complete."
exit 0
