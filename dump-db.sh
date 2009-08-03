#! /bin/sh

DB='craigr'
#LST='content log user'
PWD=''

mysqldump -Bd $DB > db-$DB.sql

for i in $LST; do
    mysqldump -e  $DB $i > $i.sql
done

mysqldump -B $DB > db-data.sql

