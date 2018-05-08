#!/bin/bash

set -e

systemctl enable hrmd.service
systemctl start hrmd.service
sleep 1
systemctl status hrmd.service

sleep 5
systemctl status hrmd.service