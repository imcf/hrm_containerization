#!/bin/bash

set -e

apt-get install -y sudo vim bash-completion multitail apache2 libapache2-mod-php5 php5 php5-cli php5-common php5-json php5-mysql mysql-server postfix libfontconfig1 libx11-6 libxft2

source ./hrm_defaults.inc.sh


# user / group setup:
groupadd --system hrm
useradd hrm --system --gid hrm
usermod www-data --append --groups hrm

# create data dir, set permissions:
mkdir -pv $HRM_DATA
chown -R hrm:hrm ${HRM_DATA}
chmod -R u+s,g+ws ${HRM_DATA}
chown -R hrm:hrm ${HRM_LOG}
chmod -R u+s,g+ws ${HRM_LOG}


# extract hrm package:
unzip /home/hrm/hrm_3.5.0.zip -d $WWW_ROOT

cp -v $HRM_SAMPLES/hrm.conf.sample /etc/hrm.conf
