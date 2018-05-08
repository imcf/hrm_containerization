#!/bin/bash

set -e

mysql --user root --password=mysqlrootpw \
  --execute="CREATE DATABASE hrm CHARACTER SET utf8;
             CREATE USER 'hrm'@'localhost' IDENTIFIED BY 'dbpasswd';
             GRANT ALL ON hrm.* to 'hrm'@'localhost';"
