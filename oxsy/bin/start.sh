#! /bin/bash

HOST="localhost"
HOMEDIR=`dirname $0`
player_port=6000
coach_port=6002

while [ $# -gt 0 ]
do
  case $1 in
    -p|--port)
      if [ $# -lt 2 ]; then
        usage
      fi
      player_port="${2}"
      shift 2
      ;;
    -P|--coach-port)
      if [ $# -lt 2 ]; then
        usage
      fi
      coach_port="${2}"
      shift 2
      ;;
    *)
      echo 1>&2
      echo "invalid option \"${1}\"." 1>&2
      echo 1>&2
      usage
      ;;
  esac
done

cd $HOMEDIR

## The following two lines are necessary to fix the directory path in the configuration file.
cp bin/oxsysoccer_real.conf bin/oxsysoccer.conf
sed -i "s|/home|${HOMEDIR}|g" bin/oxsysoccer.conf

./start ${HOST} ${HOMEDIR} 1 ${player_port} ${coach_port} &
sleep 1
./start ${HOST} ${HOMEDIR} 2 ${player_port} ${coach_port} &
sleep 0.1
./start ${HOST} ${HOMEDIR} 3 ${player_port} ${coach_port} &
sleep 0.1
./start ${HOST} ${HOMEDIR} 4 ${player_port} ${coach_port} &
sleep 0.1
./start ${HOST} ${HOMEDIR} 5 ${player_port} ${coach_port} &
sleep 0.1
./start ${HOST} ${HOMEDIR} 6 ${player_port} ${coach_port} &
sleep 0.1
./start ${HOST} ${HOMEDIR} 7 ${player_port} ${coach_port} &
sleep 0.1
./start ${HOST} ${HOMEDIR} 8 ${player_port} ${coach_port} &
sleep 0.1
./start ${HOST} ${HOMEDIR} 9 ${player_port} ${coach_port} &
sleep 0.1
./start ${HOST} ${HOMEDIR} 10 ${player_port} ${coach_port} &
sleep 0.1
./start ${HOST} ${HOMEDIR} 11 ${player_port} ${coach_port} &
sleep 0.1
./start ${HOST} ${HOMEDIR} 12 ${player_port} ${coach_port} &
sleep 0.1

wait