#!/bin/bash
#
#chkconfig: 2345 80 90
#description: mongodb
start() {
  sudo mongod -f mongodb.conf
}

stop() {
  sudo mongod -f mongodb.conf --shutdown
  # in macosx:   use admin;  db.shotdownServer();
}

repair() {
  sudo mongod --repair --dbpath /data/db --repairpath /data/repair
}

case "$1" in
  start)
 start
 ;;
  stop)
 stop
 ;;
  restart)
 stop
 start
 ;;
  repair)
 repair
 ;;
  *)
 echo $"Usage: $0 {start|stop|restart}"
 exit 1
esac
