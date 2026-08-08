#!/bin/bash
#=======================================================
# Agent2D-3.1.0 start script
# RoboCup2D @ Anhui Unversity of Technology
# Bugs or Suggestions please mail to guofeng1208@163.com
#=======================================================

LIBPATH=./data/lib
if [ -z "$LD_LIBRARY_PATH" ]
then
	LD_LIBRARY_PATH=$LIBPATH
else
	LD_LIBRARY_PATH=$LIBPATH:$LD_LIBRARY_PATH
fi

export LD_LIBRARY_PATH


host="localhost"
port=6000
coach_port=6002
teamname="YuShan2026"

player="./YuShan2026_Player"
coach="./YuShan2026_Coach"

config="./data/player.conf"
coach_config="./data/coach.conf"
config_dir="./data/formations-dt"

opt="--player-config ${config} --config_dir ${config_dir}"
coachopt="--coach-config ${coach_config} --use_team_graphic on"


sleeptime=0.5
posnum=0
count=12

usage()
{
  (echo "Usage: $0 [options]"
   echo "Available options:"
   echo "      --help                   prints this"
   echo "  -h, --host HOST              specifies server host (default: localhost)"
   echo "  -p, --port PORT              specifies server port (default: 6000)"
   echo "  -P  --coach-port PORT        specifies server port for online coach (default: 6002)"
   echo "  -t, --teamname TEAMNAME      specifies team name"
   echo "  -n, --number NUMBER          specifies the number of players"
   echo "  -u, --unum UNUM              specifies the uniform number of players"
   echo "  -C, --without-coach          specifies not to run the coach"
   echo "  -f, --formation DIR          specifies the formation directory"
   echo "  --team-graphic FILE          specifies the team graphic xpm file"
   echo "  --offline-logging            writes offline client log (default: off)"
   echo "  --offline-client-mode        starts as an offline client (default: off)"
   echo "  --debug                      writes debug log (default: off)"
   echo "  --debug_DEBUG_CATEGORY       writes DEBUG_CATEGORY to debug log"
   echo "  --debug-start-time TIME      the start time for recording debug log (default: -1)"
   echo "  --debug-end-time TIME        the end time for recording debug log (default: 99999999)"
   echo "  --debug-server-connect       connects to the debug server (default: off)"
   echo "  --debug-server-host HOST     specifies debug server host (default: localhost)"
   echo "  --debug-server-port PORT     specifies debug server port (default: 6032)"
   echo "  --debug-server-logging       writes debug server log (default: off)"
   echo "  --log-dir DIRECTORY          specifies debug log directory (default: /tmp)"
   echo "  --debug-log-ext EXTENSION    specifies debug log file extension (default: .log)"
   echo "  --fullstate FULLSTATE_TYPE   specifies fullstate model handling"
   echo "                               FULLSTATE_TYPE is one of [ignore|reference|override].") 1>&2
}

while [ $# -gt 0 ]
do
  case $1 in

    --help)
      usage
      exit 0
      ;;

    -h|--host)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      host="${2}"
      shift 1
      ;;

    -p|--port)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      port="${2}"
      shift 1
      ;;

    -P|--coach-port)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      coach_port="${2}"
      shift 1
      ;;

	*)
      echo 1>&2
      echo "invalid option \"${1}\"." 1>&2
      echo 1>&2
      usage
      exit 1
      ;;
  esac

  shift 1
done

opt="${opt} -h ${host} -p ${port} -t ${teamname}"
coachopt="${coachopt} -h ${host} -P ${coach_port} -t ${teamname}"



# the limit of core dump file size 
ulimit -f unlimited


if [ $posnum -ne 0 ]
then
	case $posnum in
	1)
		${player} ${opt} -g -n $posnum &
	;;
	12)
		${coach} ${coachopt}  &
	;;
	*)
		${player} ${opt} -n $posnum  &
	;;
	esac
	
	exit 0
fi


i=1
	
while [ ${i} -le ${count} ]
do
	case ${i} in
	1)
		echo "team $teamname: Start Player $i"
		${player} ${opt} -g &
	;;
	12)
		echo "team $teamname: Start Coach"
		${coach} ${coachopt} &
	;;
	*)
		echo "team $teamname: Start Player $i"
		${player} ${opt} &
	;;
	esac

	sleep $sleeptime
	i=$((i+1))
done

exit 0

