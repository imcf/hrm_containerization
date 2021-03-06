#!/bin/bash

# exit immediately on any error
set -e

usage_exit() {
    echo
    echo "Usage:"
    echo
    echo "    $0 container_name /path/to/ssh_pubkey_or_authorized_keys"
    echo
    exit $1
}

SCRIPTS_DIR="$(dirname $0)/lxc-create.d"
echo "Processing scripts in [${SCRIPTS_DIR}/]..."
for INC in ${SCRIPTS_DIR}/[0-9][0-9]_*\.inc\.sh ; do
    echo "Sourcing [$INC]"
    source $INC
done

#############################################################
# LXC base setup
#############################################################

echo
echo ------------------------ settings ------------------------
echo SUITE=$SUITE
echo VM_HOSTNAME=$VM_HOSTNAME
echo TGT_ROOT=$TGT_ROOT
echo TGT_LOCALE=$TGT_LOCALE
echo BRIDGE_IP=$BRIDGE_IP
echo -------------------- lxc-create command ------------------
echo lxc-create --lxcpath=$BASEDIR --name=$VM_HOSTNAME -t $DISTRIBUTION -- --release=$SUITE
echo
if [ -n "$DRY_RUN" ] ; then
    echo ">>> dry-run requested, stopping here! <<<"
    exit 0
fi
lxc-create --lxcpath=$BASEDIR --name=$VM_HOSTNAME -t $DISTRIBUTION -- --release=$SUITE

echo "deb $MIRROR $SUITE main" > $TGT_ROOT/etc/apt/sources.list
# configure apt to use the local apt-cacher-ng:
echo "Acquire::http { Proxy \"http://$BRIDGE_IP:3142\"; };" > $TGT_ROOT/etc/apt/apt.conf.d/01proxy

if [ -z "$LOCALPKGS" ] ; then
    chroot $TGT_ROOT apt-get update
else
    echo "Using local packges and lists: $LOCALPKGS"
    cp "$LOCALPKGS/lists/"* "$TGT_ROOT/var/lib/apt/lists/"
    cp "$LOCALPKGS/archives/"*.deb "$TGT_ROOT/var/cache/apt/archives/"
    chroot $TGT_ROOT apt-cache gencaches
fi
chroot $TGT_ROOT apt-get -y install eatmydata

# on older host systems it was necesary to install sysvinit-core and
# systemd-shim (see Debian bug #766233 for details), this is not required on
# Ubuntu 17.04 any more, hence this line is commented:
## chroot $TGT_ROOT eatmydata apt-get -y install sysvinit-core systemd-shim

source $(dirname $0)/debian_defaults.inc.sh

# ensure hostname resolution is working
echo "127.0.1.1 $VM_HOSTNAME.local $VM_HOSTNAME" >> $TGT_ROOT/etc/hosts

# prevent sshd's stupid behaviour of overriding the locale environment:
sed -i 's,^AcceptEnv,#AcceptEnv,' $TGT_ROOT/etc/ssh/sshd_config
# configure default locale
sed -i "s,^# $TGT_LOCALE,$TGT_LOCALE," $TGT_ROOT/etc/locale.gen
chroot $TGT_ROOT eatmydata locale-gen
chroot $TGT_ROOT eatmydata update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# configure ssh-access for the root account
mkdir -pv $TGT_ROOT/root/.ssh
cp $AUTH_KEYS $TGT_ROOT/root/.ssh/authorized_keys


#############################################################
# HRM dependencies
#############################################################
# prepare installation of packages requiring configuration:
echo "
mysql-server mysql-server/root_password password $MYSQL_ROOTPW
mysql-server mysql-server/root_password_again password $MYSQL_ROOTPW
postfix postfix/mailname string $VM_HOSTNAME
postfix postfix/main_mailer_type string 'Local only'
" | chroot $TGT_ROOT debconf-set-selections

# prevent daemons from being started right after installation, which would fail
# inside the chroot environment:
echo -e '#!/bin/bash\nexit 101' > $TGT_ROOT/usr/sbin/policy-rc.d
chmod +x $TGT_ROOT/usr/sbin/policy-rc.d

chroot $TGT_ROOT eatmydata apt-get -y install \
    sudo \
    vim \
    bash-completion \
    multitail \
    apache2 \
    libapache2-mod-php5 \
    php5 \
    php5-cli \
    php5-common \
    php5-json \
    php5-mysql \
    mysql-server \
    postfix \
    libfontconfig1 \
    libx11-6 \
    libxft2

# copy hucore DEB, install it and set up the license:
HUCORE=$(cd $(dirname $0); ls huygens_*.deb)
echo -e "\n---\nUsing [$HUCORE] package"
cp -L $(dirname $0)/$HUCORE $TGT_ROOT/var/cache/apt/archives/
chroot $TGT_ROOT eatmydata dpkg -i /var/cache/apt/archives/$HUCORE
cat $(dirname $0)/huygensLicense >> $TGT_ROOT/usr/local/svi/huygensLicense
echo -e "---\n"

# explicitly set the timezone for PHP:
sed -i 's,^;date.timezone =,date.timezone = "Europe/Zurich",' $TGT_ROOT/etc/php5/apache2/php.ini

# clean up the script blocking dpkg from triggering daemon starts:
rm -f $TGT_ROOT/usr/sbin/policy-rc.d


#############################################################
# HRM setup
#############################################################
source $(dirname $0)/hrm_defaults.inc.sh

# user / group setup:
chroot $TGT_ROOT groupadd --system hrm || true
chroot $TGT_ROOT useradd hrm --create-home --system --gid hrm || true
chroot $TGT_ROOT usermod www-data --append --groups hrm

# create data dir, set permissions:
chroot $TGT_ROOT mkdir -p $HRM_DATA
chroot $TGT_ROOT mkdir -p $HRM_LOG
chroot $TGT_ROOT chown -R hrm:hrm ${HRM_DATA}
chroot $TGT_ROOT chmod -R u+s,g+ws ${HRM_DATA}
chroot $TGT_ROOT chown -R hrm:hrm ${HRM_LOG}
chroot $TGT_ROOT chmod -R u+s,g+ws ${HRM_LOG}

# extract hrm package:
HRM_ZIP_PKG=$(dirname $0)/hrm.zip
eatmydata unzip -q $HRM_ZIP_PKG -d $TGT_ROOT/$WWW_ROOT
echo "Successfully extracted [$HRM_ZIP_PKG] to [$TGT_ROOT/$WWW_ROOT]"

# enable default configuration:
chroot $TGT_ROOT cp -v $HRM_SAMPLES/hrm.conf.sample /etc/hrm.conf
chroot $TGT_ROOT cp -v $HRM_SAMPLES/hrm_server_config.inc.sample $HRM_CONFIG/hrm_server_config.inc
chroot $TGT_ROOT ln -sv hrm_server_config.inc $HRM_CONFIG/hrm_client_config.inc


# install hrmd systemd unit file:
chroot $TGT_ROOT cp -v $HRM_RESRC/systemd/hrmd.service /etc/systemd/system/


#############################################################
# prepare finalization scripts to be run after startup
#############################################################
SETUP_SCRIPTS=$TGT_ROOT/home/hrm/_hrm_setup
mkdir -v $SETUP_SCRIPTS
cp -vL $(dirname $0)/hrm_defaults.inc.sh $SETUP_SCRIPTS/
cp -vL $(dirname $0)/finalize.d/* $SETUP_SCRIPTS/
echo "Scripts to finalize the HRM setup have been placed here:"
echo "  > $SETUP_SCRIPTS"
echo
echo "Log in as user 'root', then just launch:"
echo
echo "  # bash $SETUP_SCRIPTS/do_finalize_setup.sh"
echo


#############################################################
# finish
#############################################################
# clean up downloaded package cache:
chroot $TGT_ROOT eatmydata apt-get clean
