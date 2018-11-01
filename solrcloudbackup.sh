#!/bin/bash

# To run this script first create and mount AWS EFS volumes in all solrcloud instances and configure aws credentials in script running instance.
# #script variables
BAK_DATETIME=`date +%F-%H%M`
TEMP_BAK_FOLDER=/tmp/

#Clear main shared backup EFS volume
cd /home/ubuntu/efs
sudo rm -rf *
echo "backup started"
#Run solrcloud backup collection API scripts
curl "http://$ip:8983/solr/admin/collections?action=BACKUP&name=$collectionname&collection=$collectionname&location=/home/ubuntu/efs/"

#give 10 minute delay to complete the backup process
sleep 5

# compress and move main backup to temporary backup location
tar -czf ${TEMP_BAK_FOLDER}/solrcloudbackup_${BAK_DATETIME}.tar.gz /home/ubuntu/efs

# move the compressed file to s3
/usr/local/bin/aws s3 cp ${TEMP_BAK_FOLDER}/solrcloudbackup_${BAK_DATETIME}.tar.gz s3://qasolrcloudbackup/

# delete backup files older than 7 days from temporary backup location
find ${TEMP_BAK_FOLDER} -type f -mtime +7 -name '*.gz' -execdir rm -- {} \;
echo "backup completed"
