#!/bin/sh

DEVON_CONSTANTS='{
  "service": {
    "commonUserName": "paleo",
    "commonUserId": 21001,
    "commonServicePort": 8000,
    "healthcheckCmd": "healthcheck.sh",
    "serviceCmd": "start.sh",
    "serviceDir": "/opt/service"
  },
  "redis": {
    "homeDir": "/opt/prg/redis"
  },
  "fileserver": {
    "dataDir": "/opt/data"
  },
  "mariadb": {
    "dataDir": "/opt/data/mariadb",
    "homeDir": "/opt/prg/mariadb",
    "mysqlUser": "mysql",
    "mysqlGroup": "mysql",
    "ssl": {
      "certFile": "cert.pem",
      "keyFile": "key.pem",
      "caFile": "ca.pem",
      "certFileEnc": "cert.txt",
      "keyFileEnc": "key.txt",
      "caFileEnc": "ca.txt",
      "certDir": "/opt/prg/mariadb/cert"
    }
  },
  "build": {
    "ociCommand": "podman --cgroup-manager=cgroupfs",
    "baseImage": "alpine:3.16",
    "imagesUri": "https://people.inf.elte.hu/hiaiaat/img"
  }
}'

function devon_exit_if_last_failed() {
  local err=$?
  local msg=$1

  [ "$err" -ne "0" ] && echo -e "\n*** Failure ($err) : $msg" && set -e && exit 1
}

jq --version > /dev/null

devon_exit_if_last_failed "jq is not found"

function devon_get_json_property() {
  local json_data=$1
  local expr=$2

  local result=$(echo $json_data | jq -r $expr)
  devon_exit_if_last_failed "Cannot get JSON property - $json_data $expr"
  echo "$result"
}

function devon_get_constant() {
  local expr=$1

  echo $(devon_get_json_property "$DEVON_CONSTANTS" $expr)
}

DEVON_OCI=$(devon_get_constant ".build.ociCommand")

DEVON_IMAGES_URL=$(devon_get_constant ".build.imagesUrl")

DEVON_BASE_IMAGE=$(devon_get_constant ".build.baseImage")

function devon_build_image() {
  local image=$1
  local params=$2

  echo "Building image $image"
  $DEVON_OCI image rm -f $image
  $DEVON_OCI build --no-cache $params -t $image .
  devon_exit_if_last_failed "Cannot build $image"
  echo -e "\nImage successfully built: $image"
}

function devon_run_image() {
  local image_name=$1
  local image=$2
  local params=$3

  $DEVON_OCI run $params --name $image_name $image /bin/sh
}

function devon_assert_equals_str() {
  [ "$1" != "$2" ] && echo -e "Assertion failure:\n $1\nnot equals\n $2\n" && set -e && exit 1
}

function devon_add_group() {
  local group_name=$1
  local group_id=$2

  if [ -z "$group_id" ]
  then
    addgroup $group_name
    devon_exit_if_last_failed "Cannot add group $group_name"
  else
    addgroup -g $group_id $group_name
    devon_exit_if_last_failed "Cannot add group $group_name/$group_id"
  fi
}

function devon_add_user() {
  local user_name=$1
  local user_id=$2
  local group_name=$3

  adduser -H -D -s /bin/sh $user_name
  devon_exit_if_last_failed "Cannot add user $user_name"

  if [ -n "$user_id" ]
  then
    usermod -u $user_id $user_name
    devon_exit_if_last_failed "Cannot set user ID for  $user_name  to  $user_id"
  fi

  if [ -n "$group_name" ]
  then
    usermod -a -G $group_name $user_name
    devon_exit_if_last_failed "Cannot add user  $user_name  to group  $group_name"
  fi
}

function devon_fetch_extract_tgz_file() {
  local base_url=$1
  local file_name=$2
  local destination_dir=$3

  wget -O "/tmp/$file_name" "$base_url/$file_name"
  devon_exit_if_last_failed "Cannot fetch file from $base_url/$file_name"

  tar -xzf "/tmp/$file_name" -C $destination_dir
  devon_exit_if_last_failed "Cannot extract to $destination_dir/$file_name"

  rm "/tmp/$file_name"
}

function devon_set_dir_contents_executable() {
  local dir=$1

  chmod -cR 755 "$dir/"
  devon_exit_if_last_failed "Cannot chmod contents of $dir"
}

function devon_mkdir() {
  local dir=$1

  mkdir -p $dir
  devon_exit_if_last_failed "Cannot create dir $dir"
}

function devon_rmdir() {
  local dir=$1

  rm -rf $dir
  devon_exit_if_last_failed "Cannot remove dir $dir"
}

function devon_chown_chgrp_dir() {
  local dir=$1
  local user=$2
  local group=$3
  
  chown -cR $user "$dir/"
  devon_exit_if_last_failed "Cannot chown dir  $dir  for  $user"

  if [ -n "$group" ]
  then
    chgrp -cR $group "$dir/"
    devon_exit_if_last_failed "Cannot chgrp dir  $dir  for  $group"
  fi
}

function devon_su() {
  local cmd=$1
  local user=$2

  su -s /bin/sh -c "$cmd" $user
  devon_exit_if_last_failed "Error while executing command as $user\n$cmd"
}

function devon_create_fileserver() {
  local user_name=$(devon_get_constant "service.commonUserName")
  local user_id=$(devon_get_constant "service.commonUserId")
  local port=$(devon_get_constant "service.commonServicePort")
  local service_dir=$(devon_get_constant "service.serviceDir")
  local healthcheck_cmd=$(devon_get_constant "service.healthcheckCmd")
  local start_cmd=$(devon_get_constant "service.serviceCmd")
  local data_dir=$(devon_get_constant "fileServer.dataDir")
  local start_script="#!/bin/sh\nsu -s /bin/sh -c 'httpd -f -p \`hostname -i\`:$port -h $data_dir > /dev/null 2>&1' $user_name\n"
  local healthcheck_script="#!/bin/sh\ncurl \`hostname -i\`:$port/ping\n"

  apk add curl busybox-extras
  devon_exit_if_last_failed "cannot install packages"

  devon_add_user $user_name $user_id

  devon_mkdir $data_dir

  devon_mkdir $service_dir

  echo -e $start_script > $service_dir/$start_cmd
  devon_exit_if_last_failed "cannot add start cmd"

  echo -e $healthcheck_script > $service_dir/$healthcheck_cmd
  devon_exit_if_last_failed "cannot add healthcheck cmd"

  echo "0" > $data_dir/ping
  devon_exit_if_last_failed "cannot add ping file"

  devon_set_dir_contents_executable $service_dir

  devon_chown_chgrp_dir $service_dir $user_name

  devon_chown_chgrp_dir $service_dir $data_dir
}

function devon_setup_redis() {
  local user_name=$(devon_get_constant "service.commonUserName")
  local user_id=$(devon_get_constant "service.commonUserId")
  local home_dir=$(devon_get_constant "redis.homeDir")

  devon_fetch_extract_tgz_file $DEVON_IMAGES_URL redis7tls-alpine.tar.gz /

  devon_adduser $user_name $user_id

  devon_chown_chgrp_dir $home_dir $user_name

  devon_set_dir_contents_executable "$home_dir/bin"

  devon_su "$home_dir/bin/redis-server --version" $user
}

DEVON_MARIADB_HOME_DIR=$(devon_get_constant ".mariadb.homeDir")
DEVON_MARIADB_DATA_DIR=$(devon_get_constant ".mariadb.dataDir")
DEVON_MYSQL_USER_NAME=$(devon_get_constant ".mariadb.mysqlUser")
DEVON_MYSQL_GROUP_NAME=$(devon_get_constant ".mariadb.mysqlGroup")

function devon_get_mariadb_cert_section() {
  local ssl_cert_file=$(devon_get_constant ".mariadb.ssl.certFile")
  local ssl_key_file=$(devon_get_constant ".mariadb.ssl.keyFile")
  local ssl_ca_file=$(devon_get_constant ".mariadb.ssl.caFile")

  echo -e "  ssl_cert=$ssl_cert_file\n  ssl_key=$ssl_key_file\n  ssl_ca=$ssl_ca_file\n"
}

function devon_do_as_mysql() {
  local cmd=$1

  su -s /bin/sh -c "$cmd" $DEVON_MYSQL_USER_NAME
}

function devon_mysqlize_file() {
  local file_name=$1

  chown -c $DEVON_MYSQL_USER_NAME $file_name
  devon_exit_if_last_failed "Could not chown to $DEVON_MYSQL_USER_NAME: $file_name"

  chgrp -c $DEVON_MYSQL_GROUP_NAME $file_name
  devon_exit_if_last_failed "Could not chgrp to $DEVON_MYSQL_GROUP_NAME: $file_name" 
}

function devon_ssl_decrypt_files_sql() {
  local secret=$1

  echo "
select load_file('$SSL_CA_ENC_FILE') into dumpfile '$SSL_CA_FILE';
select load_file('$SSL_CERT_ENC_FILE') into dumpfile '$SSL_CERT_FILE';
select load_file('$SSL_KEY_ENC_FILE') into dumpfile '$SSL_KEY_FILE';
"
}

function start_local_mariadb() {
  devon_do_as_mysql "$DEVON_MARIADB_HOME_DIR/bin/mariadbd --bind-address=127.0.0.1 --datadir=$DEVON_MARIADB_DATA_DIR &"
  devon_exit_if_last_failed "Could not start mariadbd"
  sleep 5
}

function devon_stop_local_mariadb() {
  $DEVON_MARIADB_HOME_DIR/bin/mariadb-admin -h localhost -u root shutdown
  devon_exit_if_last_failed "Could not shutdown server"
  sleep 2
}

function devon_setup_datadir_and_root() {
  local root_password=$1
  local setup_sql_file=$2 
  
  $DEVON_MARIADB_HOME_DIR/scripts/mariadb-install-db --user=mysql --datadir=$DEVON_MARIADB_DATA_DIR --basedir=$DEVON_MARIADB_HOME_DIR
  devon_exit_if_last_failed "Could not initialize DB"
  
  devon_start_local_mariadb 
 
  $DEVON_MARIADB_HOME_DIR/bin/mariadb-admin -h localhost -u root password $root_password
  devon_exit_if_last_failed "Could not set root password"

  $DEVON_MARIADB_HOME_DIR/bin/mariadb --host=127.0.0.1 --user=$DEVON_MYSQL_USER --password=$root_password < $setup_sql_file  
  devon_exit_if_last_failed "Could not set up grants"  
  rm $setup_sql_file 
 
  devon_stop_local_mariadb
 
  echo "MariaDB has been initialized successfully"  
}
 
function devon_start_database() {
  local root_password=$1
  local setup_sql_file=$2 
  local cfg_file=$3

  [ ! -d "$DEVON_MARIADB_DATA_DIR/mysql" ] && devon_setup_datadir_and_root $root_password $setup_sql_file

  devon_do_as_mysql "$DEVON_MARIADB_HOME_DIR/bin/mariadbd --defaults-file=$cfg_file"

  echo -e "\nThe server has started\n"  
}

function devon_setup_mariadb() {
  apk add libstdc++ ncurses
  devon_exit_if_last_failed "Could install packages" 

  cd /tmp
  wget $IMG_BASE_URL/$MARIADB_TGZ
  tar -xzf $MARIADB_TGZ
  rm $MARIADB_TGZ

  addgroup -g $MYSQL_GROUP_ID $DEVON_MYSQL_GROUP_NAME
  adduser -G $DEVON_MYSQL_GROUP_NAME -H -D -u $MYSQL_USER_ID -s /bin/sh $DEVON_MYSQL_USER_NAME

  chown -cR $DEVON_MYSQL_USER_NAME $DEVON_MARIADB_HOME_DIR
  chgrp -cR $DEVON_MYSQL_GROUP_NAME $DEVON_MARIADB_HOME_DIR
  chmod -cR 755 "$DEVON_MARIADB_HOME_DIR/bin/"
  chmod -cR 755 "$DEVON_MARIADB_HOME_DIR/scripts/"

  devon_do_as_mysql "$DEVON_MARIADB_HOME_DIR/bin/mariadb --version"
  devon_exit_if_last_failed "Error checking server"
}

function devon_setup_mongodb() {
  echo "Hello World!"
}

function devon_setup_service() {
  echo "Hello World!"
}

