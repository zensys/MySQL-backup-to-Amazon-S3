#!/bin/sh

# Updates etc at: https://github.com/woxxy/MySQL-backup-to-Amazon-S3
# Under a MIT license

# change these variables to what you need
MYSQLROOT=root
MYSQLPASS=password
S3BUCKET=my-db-backup-bucket
# when running via cron, the PATHs MIGHT be different. If you have a custom/manual MYSQL install, you should set this manually like MYSQLDUMPPATH=/usr/local/mysql/bin/
MYSQLDUMPPATH=

PERIOD=${1-day}

echo "Selected period: $PERIOD."

echo "Starting backing up the database to a file..."

# dump all databases
${MYSQLDUMPPATH}mysqldump --quick --user=${MYSQLROOT} --password=${MYSQLPASS} --all-databases > ~/all-databases.sql

echo "Done backing up the database to a file."
echo "Starting compression..."

tar czf ~/all-databases.tar.gz ~/all-databases.sql

echo "Done compressing the backup file."

# we want at least two backups, two months, two weeks, and two days
echo "Removing old backup (2 ${PERIOD}s ago)..."
s3cmd del --recursive s3://${S3BUCKET}/previous_${PERIOD}/
echo "Old backup removed."

echo "Moving the backup from past $PERIOD to another folder..."
s3cmd mv --recursive s3://${S3BUCKET}/${PERIOD}/ s3://${S3BUCKET}/previous_${PERIOD}/
echo "Past backup moved."

# upload all databases
echo "Uploading the new backup..."
s3cmd put -f ~/all-databases.tar.gz s3://${S3BUCKET}/${PERIOD}/
echo "New backup uploaded."

echo "Removing the cache files..."
# remove databases dump
rm ~/all-databases.sql
rm ~/all-databases.tar.gz
echo "Files removed."
echo "All done."