#!/usr/bin/env bash
set -e

rm -rf /tmp/mysql-connector-odbc.*
wget https://dev.mysql.com/get/Downloads/Connector-ODBC/8.0/mysql-connector-odbc-8.0.19-linux-ubuntu19.10-x86-64bit.tar.gz -O /tmp/mysql-connector-odbc.tar.gz
tar zxvfCP /tmp/mysql-connector-odbc.tar.gz /tmp
cp /tmp/mysql-connector-odbc-8.0.19-linux-ubuntu19.10-x86-64bit/lib/libmyodbc8* /usr/lib/x86_64-linux-gnu/odbc/
/tmp/mysql-connector-odbc-8.0.19-linux-ubuntu19.10-x86-64bit/bin/myodbc-installer -d -a -n "MySQL" -t "DRIVER=/usr/lib/x86_64-linux-gnu/odbc/libmyodbc8w.so;SETUP=/usr/lib/x86_64-linux-gnu/odbc/libmyodbc8S.so;"
cat /etc/odbcinst.ini
rm -rf /tmp/mysql-connector-odbc.*
