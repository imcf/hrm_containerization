# Packages / HuCore

Use this directory to keep installation packages of hucore, and
reference them from the corresponding `DISTRIBUTION/SUITE` directory, like so:

```bash
HC_VER="17.04.1-p2"
cd packages/hucore
# download the package from svi.nl
cd ../../distributions/debian/8_jessie
ln -s ../../../packages/hucore/huygens_${HC_VER}_amd64.deb
```