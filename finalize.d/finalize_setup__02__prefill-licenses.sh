#!/bin/bash

# This script fills the 'hucore_license' table as otherwise the queue manager
# is unable to start up.

set -e

mysql --user hrm --password=dbpasswd hrm \
  --execute="INSERT INTO hucore_license SET feature = 'all-formats-reader';
             INSERT INTO hucore_license SET feature = 'chromaticS';
             INSERT INTO hucore_license SET feature = 'coloc';
             INSERT INTO hucore_license SET feature = 'confocal';
             INSERT INTO hucore_license SET feature = 'floating-license';
             INSERT INTO hucore_license SET feature = 'gpuMaxCores-1024';
             INSERT INTO hucore_license SET feature = 'gpuMaxMemory-2048';
             INSERT INTO hucore_license SET feature = 'maxGBIndexed-200';
             INSERT INTO hucore_license SET feature = 'multi-photon';
             INSERT INTO hucore_license SET feature = 'nipkow-disk';
             INSERT INTO hucore_license SET feature = 'server=desktop';
             INSERT INTO hucore_license SET feature = 'spim';
             INSERT INTO hucore_license SET feature = 'stabilizer';
             INSERT INTO hucore_license SET feature = 'sted';
             INSERT INTO hucore_license SET feature = 'sted3D';
             INSERT INTO hucore_license SET feature = 'time';
             INSERT INTO hucore_license SET feature = 'widefield';
             SELECT * FROM hucore_license;"
