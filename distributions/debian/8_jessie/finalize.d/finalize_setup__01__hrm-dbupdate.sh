#!/bin/bash

set -e

source hrm_defaults.inc.sh
cd $HRM_SETUP
php dbupdate.php
