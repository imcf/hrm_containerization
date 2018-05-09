#!/bin/bash

set -e

# fix permissions on uploader directories:
chmod g+w -v ${HRM_DATA}/.hrm_*