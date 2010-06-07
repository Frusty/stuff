#!/usr/local/bin/bash
#
# From http://andyleonard.com/2010/04/07/automatic-zfs-snapshot-rotation-on-freebsd/
#
# # crontab -l
# @hourly  /usr/local/sbin/zfs-snapshot.sh tank hourly  25
# @daily   /usr/local/sbin/zfs-snapshot.sh tank daily   8
# @weekly  /usr/local/sbin/zfs-snapshot.sh tank weekly  5
# @monthly /usr/local/sbin/zfs-snapshot.sh tank monthly 13

# Path to ZFS executable:
ZFS=/sbin/zfs
ZPOOL=/sbin/zpool
# Parse arguments:
TARGET=$1
SNAP=$2
COUNT=$3

# Function to display usage:
usage() {
    scriptname=`/usr/bin/basename $0`
    echo "$scriptname: Take and rotate snapshots on a ZFS file system"
    echo
    echo "  Usage:"
    echo "  $scriptname target snap_name count"
    echo
    echo "  target:    ZFS file system to act on"
    echo "  snap_name: Base name for snapshots, to be followed by a '_' and"
    echo "             an integer indicating relative age of the snapshot"
    echo "  count:     Number of snapshots in the snap_name.number format to"
    echo "             keep at one time.  Newest snapshot ends in '_00'."
    echo
    exit
}

# Basic argument checks:
if [ -z $COUNT ] || [ ! -z $4 ]; then
    usage
fi

if [ ! -z "$($ZPOOL status $TARGET | grep "scrub in progress")" ] ; then
    $ZPOOL status $TARGET
    echo -e "\nScrub in process on ${TARGET}, skipping $SNAP snapshot...\n"
    exit 1
fi

# Snapshots are number starting at 0; $max_snap is the highest numbered
# snapshot that will be kept.
max_snap=$(($COUNT -1))

# Clean up oldest snapshot:
if [ -d /${TARGET}/.zfs/snapshot/${SNAP}_${max_snap} ] ; then
    $ZFS destroy -r ${TARGET}@${SNAP}_${max_snap}
fi

# Rename existing snapshots:
dest=$max_snap
while [ $dest -gt 0 ] ; do
    src=$(($dest - 1))
    if [ -d /${TARGET}/.zfs/snapshot/${SNAP}_$(printf "%02d" ${src}) ] ; then
        $ZFS rename -r ${TARGET}@${SNAP}_$(printf "%02d" ${src}) ${TARGET}@${SNAP}_$(printf "%02d" ${dest})
    fi
    dest=$(($dest - 1))
done

# Create new snapshot:
$ZFS snapshot -r ${TARGET}@${SNAP}_00
