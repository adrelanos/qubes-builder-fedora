#!/bin/sh

echo "--> Preparing environment..."
mount -t proc proc $PWD/mnt/proc

trap "umount $PWD/mnt/proc" EXIT

export YUM0=$PWD/pkgs-for-template
if [ "$TEMPLATE_FLAVOR" == "minimal" ]; then
    YUM_OPTS="$YUM_OPTS --setopt=group_package_types=mandatory"
    rpmbuild -bb --target noarch --define "_rpmdir $CACHEDIR" $SCRIPTSDIR/qubes-template-minimal-stub.spec || exit 1
    yum install -c $SCRIPTSDIR/../template-yum.conf $YUM_OPTS -y --installroot=$(pwd)/mnt $CACHEDIR/noarch/qubes-template-minimal-stub*rpm || exit 1
else
    YUM_OPTS="$YUM_OPTS --setopt=group_package_types=mandatory,default,optional"
fi

echo "--> Installing RPMs..."
yum install -c $SCRIPTSDIR/../template-yum.conf $YUM_OPTS -y --installroot=$(pwd)/mnt @qubes-vm || RETCODE=1

rpm --root=$PWD/mnt --import $PWD/mnt/etc/pki/rpm-gpg/RPM-GPG-KEY-qubes-*

if [ "$TEMPLATE_FLAVOR" != "minimal" ]; then
    echo "--> Installing 3rd party apps"
    $SCRIPTSDIR/add_3rd_party_software.sh || RETCODE=1
fi


if [ -e mnt/etc/sysconfig/i18n ]; then
    echo "--> Setting up default locale..."
    echo LC_CTYPE=en_US.UTF-8 > mnt/etc/sysconfig/i18n
fi

# Distribution specific steps
source ./functions.sh
buildStep "${0}" "${DIST}"

exit $RETCODE
