# Packages / HRM

Use this directory to keep installation packages of the HRM itself, and
reference them from the corresponding `DISTRIBUTION/SUITE` directory, like so:

```bash
DL_VER="3.5.0"
cd packages/hrm
wget https://github.com/aarpon/hrm/releases/download/$DL_VER/hrm_$DL_VER.zip
cd ../../distributions/debian/8_jessie
ln -s ../../../packages/hrm/hrm_$DL_VER.zip hrm.zip
```