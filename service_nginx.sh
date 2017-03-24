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
