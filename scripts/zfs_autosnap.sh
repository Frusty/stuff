#!/bin/sh
# From http://forums.freebsd.org/showthread.php?t=15004

usage() {
  cat <<EOF
usage: ${0##*/} <label> <filesystem>|all
  Rotates filesystem snapshots.  If filesystem has the property
  org.freebsd:snap:<label>=<count>, increments all existing snapshots labeled
  <label>.<num> and creates a new snapshot called <label>.0.  Destroys snapshot
  numbered <label>.<count>.
EOF
  exit
}

# Default values
: ${ZFS=/sbin/zfs} ${PROP=org.freebsd:snap}

# Command line switch: -n for testing
case "$1" in
-n) ZFSd="echo ${ZFS}"; shift ;;
*) ZFSd="${ZFS}"
esac

# Parse command line
LABEL=$1
shift || usage

notsnap() {
  [ "$($ZFS get -Ho value type "$1" 2>/dev/null)" != "snapshot" ]
}

# For each filesystem
while [ $# -ne 0 ]; do
  # Parse filesystem for special "all" name
  case "$1" in
  all) fs="" ;;
  *) fs=$1
  esac

  # Query ZFS for filesystems with the necessary property
  $ZFS get -H ${PROP}:${LABEL} $fs | while read N P V S; do
    [ "$V" -gt 0 ] 2>/dev/null && notsnap "$N" || continue

    # Destroy the oldest
    V=$(($V - 1))
    SNAP="${N}@${LABEL}"
    notsnap ${SNAP}.${V} || $ZFSd destroy ${SNAP}.${V}

    # Increment existing snapshots
    while [ $V -gt 0 ]; do
      next=$(($V - 1))
      notsnap ${SNAP}.${next} || $ZFSd rename "${SNAP}.${next}" "${SNAP}.${V}"
      V=$next
    done

    # Make New Snapshot
    $ZFSd snapshot ${SNAP}.0
  done
  shift
done
