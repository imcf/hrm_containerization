#!/bin/bash

set -e

cd $(dirname $0)

for SCRIPT in finalize_setup__*.sh ; do
	echo "--------------------------------------"
	echo -e "Running [$SCRIPT]...\n"
	bash -x $SCRIPT
	echo -e "\n\n"
done