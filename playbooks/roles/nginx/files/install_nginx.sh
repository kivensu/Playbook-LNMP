#!/bin/bash=
superstack_dir=/usr/local/src
run_user=www
pcre_version=8.41
nginx_version=1.12.2
openssl_version=1.0.2l
nginx_install_dir=/usr/local/nginx
wwwroot_dir=/data/wwwroot
wwwlogs_dir=/data/wwwlogs
OS=CentOS
PHP_yn=y

Install_Nginx() {
 
  pushd ${superstack_dir}
  yum update
  yum -y install gcc-c++ zlib zlib-devel gcc autoconf automake make kernel-devel
  mkdir -p /data/{wwwroot,wwwlogs}
  id -u $run_user >/dev/null 2>&1
  [ $? -ne 0 ] && useradd -M -s /sbin/nologin $run_user
  
  tar xzf pcre-$pcre_version.tar.gz
  tar xzf nginx-$nginx_version.tar.gz
  tar xzf openssl-$openssl_version.tar.gz

  pushd nginx-$nginx_version
  # close gcc debug
  sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc
  # make install
  [ ! -d "$nginx_install_dir" ] && mkdir -p $nginx_install_dir
  ./configure --prefix=$nginx_install_dir --user=$run_user --group=$run_user --with-http_stub_status_module --with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module --with-http_realip_module --with-http_flv_module --with-http_mp4_module --with-openssl=../openssl-$openssl_version --with-pcre=../pcre-$pcre_version --with-pcre-jit
  make && make install
  if [ -e "$nginx_install_dir/conf/nginx.conf" ]; then
    popd
    echo "Nginx installed successfully!"
  else
    echo "Nginx install failed, Please Contact the author!"
    kill -9 $$
  fi

  [ -z "`grep ^'export PATH=' /etc/profile`" ] && echo "export PATH=$nginx_install_dir/sbin:\$PATH" >> /etc/profile
  [ -n "`grep ^'export PATH=' /etc/profile`" -a -z "`grep $nginx_install_dir /etc/profile`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=$nginx_install_dir/sbin:\1@" /etc/profile
  . /etc/profile

  [ "$OS" == 'CentOS' ] && { /bin/cp ./Nginx-init-CentOS /etc/init.d/nginx;chmod +x /etc/init.d/nginx;chkconfig --add nginx; chkconfig nginx on; }
  sed -i "s@/usr/local/nginx@$nginx_install_dir@g" /etc/init.d/nginx
  mv $nginx_install_dir/conf/nginx.conf{,_bk}
    /bin/cp ./nginx.conf $nginx_install_dir/conf/nginx.conf
    [ "$PHP_yn" == 'y' ] && [ -z "`grep '/php-fpm_status' $nginx_install_dir/conf/nginx.conf`" ] &&  sed -i "s@index index.html index.php;@index index.html index.php;\n    location ~ /php-fpm_status {\n        #fastcgi_pass remote_php_ip:9000;\n        fastcgi_pass unix:/dev/shm/php-cgi.sock;\n        fastcgi_index index.php;\n        include fastcgi.conf;\n        allow 127.0.0.1;\n        deny all;\n        }@" $nginx_install_dir/conf/nginx.conf
  cat > $nginx_install_dir/conf/proxy.conf << EOF
proxy_connect_timeout 300s;
proxy_send_timeout 900;
proxy_read_timeout 900;
proxy_buffer_size 32k;
proxy_buffers 4 64k;
proxy_busy_buffers_size 128k;
proxy_redirect off;
proxy_hide_header Vary;
proxy_set_header Accept-Encoding '';
proxy_set_header Referer \$http_referer;
proxy_set_header Cookie \$http_cookie;
proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
EOF
  sed -i "s@/data/wwwroot/default@$wwwroot_dir@g" $nginx_install_dir/conf/nginx.conf
  sed -i "s@/data/wwwlogs@$wwwlogs_dir@g" $nginx_install_dir/conf/nginx.conf
  sed -i "s@^user www www@user $run_user $run_user@g" $nginx_install_dir/conf/nginx.conf

  # logrotate nginx log
  cat > /etc/logrotate.d/nginx << EOF
$wwwlogs_dir/*nginx.log {
  daily
  rotate 5
  missingok
  dateext
  compress
  notifempty
  sharedscripts
  postrotate
    [ -e /var/run/nginx.pid ] && kill -USR1 \`cat /var/run/nginx.pid\`
  endscript
}
EOF
  popd
  ldconfig
  systemctl daemon-reload
  service nginx start
}
Install_Nginx
