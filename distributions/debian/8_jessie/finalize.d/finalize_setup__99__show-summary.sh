#!/bin/bash

MARK="*************************************************************************"
EXT_IP=$(ip -o -f inet addr show eth0 | sed -n 's,.*inet \([0-9\.]*\)/.*,\1,p')

set +x

echo -e "\n$MARK"
echo "Installation finsihed, connect to the HRM via"
echo -e "\n   -- URI: http://${EXT_IP}/hrm/"
echo "   -- user: admin"
echo "   -- pass: pwd4hrm"
echo -e "\n$MARK"