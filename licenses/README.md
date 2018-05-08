# Licenses

Use this directory to keep licenses for `hucore`, one per file. They will be
used by the setup scripts to be placed in the corresponding `huygensLicense`
file inside the container and have to be referenced through a symlink from the
`DISTRIBUTION/SUITE` directory, e.g. keep a file

* `licenses/floating_17.04_2018-07-01`

and point to it like

* `ln -s ../../../licenses/floating_17.04_2018-07-01 distribution/debian/8_jessie/huygensLicense`
