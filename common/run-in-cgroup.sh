#!/bin/bash

if [ -z "$CPUSPEC" ] || [ "$#" -lt 1 ]; then
	echo "usage: CPUSPEC=... $0 command"
	exit 1
fi

ARGS="$@"

set +e

if type systemd-run >/dev/null 2>&1 ; then # systemd
   sudo systemd-run -G --pty -d --uid=$(whoami)    \
                    -p AllowedCPUs="$CPUSPEC"      \
                    --slice "user-$(whoami).slice" \
                    "$@"
elif type loginctl >/dev/null 2>&1 ; then #elogind
   sudo mkdir /sys/fs/cgroup/jhalfs
   sudo sh -c "echo +cpuset > /sys/fs/cgroup/cgroup.subtree_control"
   (
      sudo sh -c "echo $BASHPID > /sys/fs/cgroup/jhalfs/cgroup.procs"
      sudo sh -c "
         SESS_CGROUP=/sys/fs/cgroup/\$XDG_SESSION_ID
         echo $CPUSPEC > \$SESS_CGROUP/cpuset.cpus
	 ( echo \$BASHPID > \$SESS_CGROUP/cgroup.procs &&
		 exec sudo -u $(whoami) $ARGS )"
   )
   sudo rmdir /sys/fs/cgroup/jhalfs
else # no session manager
   sudo mkdir /sys/fs/cgroup/jhalfs
   sudo sh -c "echo +cpuset > /sys/fs/cgroup/cgroup.subtree_control"
   sudo sh -c "echo \"$CPUSPEC\" > /sys/fs/cgroup/jhalfs/cpuset.cpus"
   (sudo sh -c "echo $BASHPID > /sys/fs/cgroup/jhalfs/cgroup.procs" &&
      exec "$@")
   sudo rmdir /sys/fs/cgroup/jhalfs
fi
