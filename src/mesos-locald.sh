#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This is a wrapper for running mesos-slave before it is installed
# that first sets up environment variables as appropriate.


# mesos-locald - Startup script for Mesos Local

# chkconfig: 35 85 15
# description: 
# processname: mesos-local
# config: /etc/mesos/mesos-local.conf
# pidfile: /var/run/mesos-locald.pid

. /etc/rc.d/init.d/functions

# NOTE: if you change any OPTIONS here, you get what you pay for:
# this script assumes all options are in the config file.

PRG="$0"

while [ -h "$PRG" ]; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done

# Get standard environment variables
PRGDIR=`dirname "$PRG"`

# Establish which Command we are going to run.
mesosd=`which mesos-local`
if [ ! -n "$mesosd" ]; then
   echo $"ERROR: It appears that the file $mesosd is unreachable or unexecutable."
   exit -1
fi
prog=$(basename $mesosd)

# Source the default environment variables.
ENV="$PRGDIR/mesos-env.sh"
if [ -f "$ENV" ]; then
    source $ENV
else
    echo "ERROR Environment file $ENV is missing!"
    exit -1
fi

start() {
    [ -x $mesosd ] || exit 5
    echo -n $"Starting Mesos Local ($mesosd):"

    if [ -n "$NUMACTL" ]; then
        echo -n $"Running NUMA $NUMACTL"
    fi

    daemonize -a -e "$OUT_FILE" -o "$OUT_FILE" -p "$PIDFILE" -l "$LOCKFILE" -u "$MESOS_USER" $NUMACTL $mesosd $OPTIONS
    
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        touch "$LOCKFILE"
        success
    else
        failure
    fi
    echo
    return $RETVAL
}

stop() {
    echo -n $"Stopping Mesos Local ($mesosd): "
    killproc $prog -SIGTERM
    RETVAL=$?
    [ $RETVAL -eq 0 ] && rm -f $LOCKFILE
    echo
    return $RETVAL
}


restart() {
    stop
    start
}

reload() {
    echo -n $"Reloading $prog: "
    killproc $prog -HUP
    RETVAL=$?
    echo
    return $RETVAL
}

force_reload() {
    restart
}
 
rh_status() {
    status $prog
}
 
rh_status_q() {
    rh_status >/dev/null 2>&1
}

ulimit -n 12000
RETVAL=0

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart|reload|force-reload)
    restart
    ;;
  condrestart)
    [ -f "$LOCKFILE" ] && restart || :
    ;;
  status)
    status $mesosd
    RETVAL=$?
    ;;
  *)
    echo "Usage: $0 {start|stop|status|restart|reload|force-reload|condrestart}"
    RETVAL=1
esac

exit $RETVAL
