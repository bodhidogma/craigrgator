#! /bin/sh

DB='craigr'
LST='cars'

for i in $LST; do
    mysql $DB -e "truncate $i"
done
