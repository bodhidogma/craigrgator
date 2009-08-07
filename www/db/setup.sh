#! /bin/sh

cd ..
chown apache -R *
chmod g+r -R *
chmod 777 data
chmod 777 templates_c
rm -f templates_c/*
