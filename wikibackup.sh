#!/bin/sh
# Usage:
# sudo wikibackup /home/andy/backup
# made by Andrew Leifer
# leifer@princeton.edu

#How many files do we want there to be per directory
FILEBUFFSIZE=$((21))
FILESPER=$((3)) #Number of files created per backup

backupdir=$1
#backupdir="/home/andy/backup"
LocalSettings="/etc/mediawiki/LocalSettings.php"
dumpBackup="/usr/share/mediawiki/maintenance/dumpBackup.php"
Images="/var/lib/mediawiki/images/"


echo "Checking to make sure that the backup directory exists"

if [ -d $backupdir ]
then

        echo Backupdirectory: $backupdir exists!
else
        ./mountUSB #run the mount USB script
fi

timestamp=$(date +%Y-%m-%d)

echo "Dumping the MySQL Database"

#Dump the MySQL database
/usr/bin/nice -n 19 mysqldump -uroot -pc.elegans --add-drop-table wiki_db -c | /bin/gzip -9 --rsyncable > $backupdir/wiki-$DATABASE-$timestamp.sql.gz

echo "Taring and the Gzipping the image files and LocalSettings"

#Create a tar of all of the associate files:
/usr/bin/nice -n 19 tar -czvf $backupdir/wiki-supportfiles-$timestamp.tgz $LocalSettings $Images


sleep 1
echo "Starting the XML Dump"

/usr/bin/nice -n 19 php $dumpBackup --full | gzip > $backupdir/wiki-XML-$timestamp.xml.gz


echo "Deleting files if there are too many.."

#Count number of files in the directory
NUMFILES=$(ls $backupdir/ | wc -w)
echo Found $NUMFILES
###If there are too many files
NUMTODELETE=$(($FILESPER *2))
if [ $NUMFILES > $FILEBUFFSIZE ]; then
        echo Deleting the oldest
        for i in $( ls $backupdir/ -t | tail -n $NUMTODELETE); do
                echo rm $backupdir/$i
                rm $backupdir/$i
        done
fi

echo "Finished"
exit 0
