#!/bin/sh

. /opt/prg/mariadb/scripts/database_tasks.sh

ROOT_PASSWORD=$1
HOSTNAME=$2
SECRET=$3

MARIADB_CONF_FILE=$MARIADB_HOME_DIR/etc/mariadb.cfg
SETUP_SQL_FILE=$MARIADB_HOME_DIR/scripts/setup.sql

echo "
create database middleware;
create user 'mwadmin'@'%' identified by 'mwadminpwd';
grant all privileges on middleware.* to 'mwadmin'@'%';
flush privileges;
$(ssl_decrypt_files_sql $SECRET)
" > $SETUP_SQL_FILE

echo "
[mariadb]
$SSL_CERT_SECTION

[mariadbd]
datadir=/opt/data/mariadb
bind-address=$HOSTNAME
port=3306
" > $MARIADB_CONF_FILE

mysqlize_file $MARIADB_CONF_FILE
mysqlize_file $SETUP_SQL_FILE

start_database $ROOT_PASSWORD $SETUP_SQL_FILE $MARIADB_CONF_FILE

echo
echo "Mariadb is running"
echo

