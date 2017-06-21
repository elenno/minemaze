#!/bin/bash
#
#chkconfig: 2345 80 90
#description: mongodb
start() {
  mongod -f mongodb.conf
  # in macosx:   use admin;  db.shotdownServer();
}

stop() {
  mongod -f mongodb.conf --shutdown
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
  *)
 echo $"Usage: $0 {start|stop|restart}"
 exit 1
esac
