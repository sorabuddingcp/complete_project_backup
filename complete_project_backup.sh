#!/bin/bash

#####Script to backup all or selected projects along with database.
##### NOTE: TO MAKE DATABASE BACKUP WORKING MAKE SURE DATABASE NAME IS SAME AS PROJECT FOLDER NAME

echo "Script to backup all or selected projects along with database";
echo
echo "*******TO MAKE DATABASE BACKUP WORKING MAKE SURE DATABASE NAME IS SAME AS PROJECT FOLDER NAME**********"
echo
echo

###### User configurable area#############
############MYSQL SETTINGS#################
MUSER="root" 					#MySql Username
MPASS="******"					#MySql Password
MHOST="localhost"				#MySql Host Name

###########DIRECTORY SETTINGS################
SOURCED="/var/www/html"				
DIRS="*"         					#seperate directories by space. put * for all directories

DEST="/home/myfolder/project_backup"

###############REMOTE SETTINGS (optional)#####################
ENABLEREMOTE="N";                 	#Options are Y and N, If Y A copy of backup will be send to remote server
DELETELOCAL="N";                  	#Options are Y and N, If Y local backup will be deleted.
REMOTEURL="192.168.0.__"			#Remote url
REMOTEUSER="remote_username"        #Remote username
REMOTEPASS="*********"				#Remote user's password
REMOTEDIR="/home/software/SHANTINATH/project_backup"
###### USER CONFIGURABLE AREA END #############

######PLEASE DO NOT MAKE MODIFICATION BELOW #####

NOW=$(date +"%Y%m%d")
DEST=$DEST/$NOW

echo "*************Your Settings *****************"
echo "Source: $SOURCED"
echo "Local Destination: $DEST"
echo "Remote Enabled: $ENABLEREMOTE"
echo "Delete Local Backup: $DELETELOCAL"
echo "*********************************************"
echo
read -p "Press Enter to continue..."

MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"

GZIP="$(which gzip)"
TAR="$(which tar)"


until $MYSQL -u $MUSER -p$MPASS  -e ";" ; do
       read -p "Can't connect to MySql, please retry: " MPASS
done

#############INSTALL MISSING PACKAGES#################
if ! type "sshpass" > /dev/null; then
	echo "It seems sshpass not installed, Please wait while we are installing the same."
	sudo apt-get install sshpass -y
fi

SSHPAS="$(which sshpass)"

DBDIR="DATABASE_BACKUP"

mkdir -p $DEST
cd $SOURCED
for d in $DIRS ; do
    if [[ -d $d ]]; then
    	DBS="$($MYSQL -u $MUSER -h $MHOST -p$MPASS -Bse 'show databases')"
    	for db in $DBS
		do
		  	if [ $db = $d ]
		  	then
		  		mkdir -p $SOURCED/$d/$DBDIR
			    DBFILE=$SOURCED/$d/$DBDIR/$db.sql.gz
			    echo "$db Dumping Database..."; $MYSQLDUMP --add-drop-table --allow-keywords -q -c -u $MUSER -h $MHOST -p$MPASS $db | $GZIP -9 > $DBFILE
			    echo "Dump completed. location : project directory/$DBDIR/$db.sql.gz"
		  	fi			
		done
	 	FILE=$DEST/$d.tar.gz
        echo "$d Compressing..."; $TAR czf $FILE $d
		if [ $ENABLEREMOTE = "Y" ]
		then
			echo "$d Uploading..."; $SSHPAS -p $REMOTEPASS scp $FILE  $REMOTEUSER@$REMOTEURL:$REMOTEDIR
			if [ $DELETELOCAL = "Y" ]
			then
				echo "$d Deleting local copy..."; rm -f $FILE
			fi
		fi
    fi
done 
