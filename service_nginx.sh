#!/bin/bash

majversion=$(lsb_release -rs | cut -f1 -d.)
minversion=$(lsb_release -rs | cut -f2 -d.)

configureRepo ()
{
dist=`cat /etc/system-release | awk '{print $1}'`
case $dist in
  CentOS)
    OS=centos
    ;;
  RedHat)
    OS=rhel
    ;;
  *)
  exit 127
  ;;
esac

if [[ ! -f /etc/yum.repos.d/nginx.repo ]]
then
  cat <<EOF >> /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/$OS/\$releasever/\$basearch/
gpgcheck=0
enabled=1
priority=19
EOF
fi
}

installNginx ()
{
  yum install -y nginx nginx-module-\* 2>&1 > /root/nginx_install.log
}

lowerCliqrRepoPriority ()
{
  #cliqr Repo
  sed -i s/priority=1/priority=20/ /etc/yum.repos.d/cliqr.repo
}

raiseCliqrRepoPriority ()
{
  sed -i s/priority=20/priority=1/ /etc/yum.repos.d/cliqr.repo

}

startNginx ()
{
  if [[ $majversion -le 6 ]]
  then
    service nginx start
  elif [[ $majversion -ge 7 ]]
  then
    systemctl start nginx
  fi
}

stopNginx ()
{
  if [[ $majversion -le 6 ]]
  then
    service nginx stop
  elif [[ $majversion -ge 7 ]]
  then
    systemctl stop nginx
  fi
}

configureNginx ()
{
  sed -i s/^/\#/ /etc/nginx/conf.d/default.conf
  cat << FOE > /etc/nginx/conf.d/main.conf
  server {
      listen       80;
      server_name  _;

      #charset koi8-r;
      #access_log  /var/log/nginx/log/host.access.log  main;

      location / {
          root   /var/www/html;
          index  index.html index.htm;
      }

      #error_page  404              /404.html;

      # redirect server error pages to the static page /50x.html
      #
      error_page   500 502 503 504  /50x.html;
      location = /50x.html {
          root   /usr/share/nginx/html;
      }

      # proxy the PHP scripts to Apache listening on 127.0.0.1:80
      #
      #location ~ \.php$ {
      #    proxy_pass   http://127.0.0.1;
      #}

      # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
      #
      #location ~ \.php$ {
      #    root           html;
      #    fastcgi_pass   127.0.0.1:9000;
      #    fastcgi_index  index.php;
      #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
      #    include        fastcgi_params;
      #}

      # deny access to .htaccess files, if Apache's document root
      # concurs with nginx's one
      #
      #location ~ /\.ht {
      #    deny  all;
      #}
  }
FOE
}

deployContent ()
{
  mkdir /var/www/html
  cd /var/www/html
  git clone $cccGitHubRepoURL
  # chmod 000 .git
}

case $1 in
  install)
    configureRepo
    lowerCliqrRepoPriority
    installNginx
    raiseCliqrRepoPriority
    ;;
  stop)
    stopNginx
    ;;
  start)
    startNginx
    ;;
  restart)
    stopNginx
    sleep 3
    startNginx
    ;;
  deploy)
    configureNginx
    deployContent
    ;;
  upgrade)
    stopNginx
    lowerCliqrRepoPriority
    yum update -y nginx
    yum update -y nginx-module\*
    raiseCliqrRepoPriority
    startNginx
    ;;
  *)
    exit 127
esac
