#!/bin/bash
superstack_dir=/usr/local/src
php_version=7.0.2
php_install_dir=/usr/local/php
run_user=www
OS=CentOS
Install_PHP70(){
  yum install gcc libxml2 libxml2-devel openssl openssl-devel bzip2-devel.x86_64 curl-devel libjpeg-devel libXpm-devel gmp-devel icu libicu libicu-devel -y
  yum install php-mcrypt libmcrypt libmcrypt-devel postgresql-devel libpng-devel libpng freetype-devel libxslt libxslt-devel -y
  id -u $run_user >/dev/null 2>&1
  [ $? -ne 0 ] && useradd -M -s /sbin/nologin $run_user
  pushd ${superstack_dir}
  tar -xvf php-$php_version.tar.gz
  [ ! -d "$php_install_dir" ] && mkdir -p $php_install_dir
  pushd php-$php_version
  #./configure --prefix=$php_install_dir --with-config-file-path=$php_install_dir/etc \
  #--with-config-file-scan-dir=$php_install_dir/etc/php.d \
  #--with-fpm-user=$run_user --with-fpm-group=$run_user --enable-fpm $PHP_cache_tmp --disable-fileinfo \
  #--enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
  #--with-iconv-dir=/usr/local --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib \
  #--with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-exif \
  #--enable-sysvsem --enable-inline-optimization --with-curl=/usr/local --enable-mbregex \
  #--enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-openssl=${openssl_install_dir} \
  #--with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-ftp --enable-intl --with-xsl \
  #--with-gettext --enable-zip --enable-soap --disable-debug $php_modules_options
  ./configure --prefix=$php_install_dir --with-pdo-pgsql --with-zlib-dir --with-freetype-dir \
  --enable-mbstring --with-libxml-dir=/usr --enable-soap --enable-calendar --with-curl --with-mcrypt \
  --with-gd --with-pgsql --disable-rpath --enable-inline-optimization --with-bz2 --with-zlib --enable-sockets \
  --enable-sysvsem --enable-sysvshm --enable-pcntl --enable-mbregex --enable-exif --enable-bcmath \
  --with-mhash --enable-zip --with-pcre-regex --with-pdo-mysql --with-mysqli --with-jpeg-dir=/usr \
  --with-png-dir=/usr --enable-gd-native-ttf --with-openssl --with-fpm-user=$run_user --with-fpm-group=$run_user \
  --with-libdir=/lib/x86_64-linux-gnu/ --enable-ftp --with-gettext --with-xmlrpc --with-xsl --enable-opcache \
  --enable-fpm --with-iconv --with-xpm-dir=/usr
  make
  make install
  if [ -e "$php_install_dir/bin/phpize" ]; then
    echo "${CSUCCESS}PHP installed successfully! ${CEND}"
  else
    echo "${CFAILURE}PHP install failed, Please Contact the author! ${CEND}"
    kill -9 $$
  fi
  [ -z "`grep ^'export PATH=' /etc/profile`" ] && echo "export PATH=$php_install_dir/bin:\$PATH" >> /etc/profile
  [ -n "`grep ^'export PATH=' /etc/profile`" -a -z "`grep $php_install_dir /etc/profile`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=$php_install_dir/bin:\1@" /etc/profile
  source /etc/profile
  [ ! -e "$php_install_dir/etc/php.d" ] && mkdir -p $php_install_dir/etc/php.d
  /bin/cp php.ini-production $php_install_dir/etc/php.ini
  sed -i "s@^memory_limit.*@memory_limit = ${Memory_limit}M@" $php_install_dir/etc/php.ini
  sed -i 's@^output_buffering =@output_buffering = On\noutput_buffering =@' $php_install_dir/etc/php.ini
  sed -i 's@^;cgi.fix_pathinfo.*@cgi.fix_pathinfo=0@' $php_install_dir/etc/php.ini
  sed -i 's@^short_open_tag = Off@short_open_tag = On@' $php_install_dir/etc/php.ini
  sed -i 's@^expose_php = On@expose_php = Off@' $php_install_dir/etc/php.ini
  sed -i 's@^request_order.*@request_order = "CGP"@' $php_install_dir/etc/php.ini
  sed -i 's@^;date.timezone.*@date.timezone = Asia/Shanghai@' $php_install_dir/etc/php.ini
  sed -i 's@^post_max_size.*@post_max_size = 100M@' $php_install_dir/etc/php.ini
  sed -i 's@^upload_max_filesize.*@upload_max_filesize = 50M@' $php_install_dir/etc/php.ini
  sed -i 's@^max_execution_time.*@max_execution_time = 600@' $php_install_dir/etc/php.ini
  sed -i 's@^;realpath_cache_size.*@realpath_cache_size = 2M@' $php_install_dir/etc/php.ini
  sed -i 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket,popen@' $php_install_dir/etc/php.ini

  /bin/cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
  chmod +x /etc/init.d/php-fpm
  [ "$OS" == 'CentOS' ] && { chkconfig --add php-fpm; chkconfig php-fpm on; }

  cat > $php_install_dir/etc/php-fpm.conf <<EOF
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;
; Global Options ;
;;;;;;;;;;;;;;;;;;

[global]
pid = run/php-fpm.pid
error_log = log/php-fpm.log
log_level = warning

emergency_restart_threshold = 30
emergency_restart_interval = 60s
process_control_timeout = 5s
daemonize = yes

;;;;;;;;;;;;;;;;;;;;
; Pool Definitions ;
;;;;;;;;;;;;;;;;;;;;

[$run_user]
listen = /dev/shm/php-cgi.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = $run_user
listen.group = $run_user
listen.mode = 0666
user = $run_user
group = $run_user

pm = dynamic
pm.max_children = 12
pm.start_servers = 8
pm.min_spare_servers = 6
pm.max_spare_servers = 12
pm.max_requests = 2048
pm.process_idle_timeout = 10s
request_terminate_timeout = 120
request_slowlog_timeout = 0

pm.status_path = /php-fpm_status
slowlog = log/slow.log
rlimit_files = 51200
rlimit_core = 0

catch_workers_output = yes
;env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
EOF
service php-fpm start
popd
[ -e "$php_install_dir/bin/phpize" ] && rm -rf php-$php70_version
popd
source /etc/profile
}
Install_PHP70
