#!/bin/sh

echo "******************************************************************"
echo " Pimentao-Verde"
echo " Based on HELIOS base / agent2d (Hidehisa Akiyama, Hiroki Shimora)"
echo "******************************************************************"

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR" || exit 1

# Prefer bundled lib/ next to this script (portable package); fall back to build-time path.
# Use relative paths so folder names with spaces (e.g. "Pimentao-Verde (2)") work.
LIBPATH="./lib"
if [ ! -d "$LIBPATH" ] || ! ls "${LIBPATH}"/librcsc.so* >/dev/null 2>&1; then
  LIBPATH=./lib
fi
if [ x"$LIBPATH" != x ] && [ -d "$LIBPATH" ]; then
  if [ x"$LD_LIBRARY_PATH" = x ]; then
    LD_LIBRARY_PATH="$LIBPATH"
  else
    LD_LIBRARY_PATH="$LIBPATH:$LD_LIBRARY_PATH"
  fi
  export LD_LIBRARY_PATH
fi

player="./sample_player"
coach="./sample_coach"
teamname="Pimentao-Verde"
host="localhost"
port=6000
coach_port=""
debug_server_host=""
debug_server_port=""

player_conf="./player.conf"
config_dir="./formations-dt"

coach_conf="./coach.conf"
# Team graphic: prefer team_logo.xpm (Rinobot) beside this script
LOGO_ABS=""
if [ -f "./team_logo.xpm" ]; then
  LOGO_ABS="./team_logo.xpm"
  team_graphic="--use_team_graphic on"
elif [ -f "./logo.xpm" ]; then
  LOGO_ABS="./logo.xpm"
  team_graphic="--use_team_graphic on"
else
  team_graphic="--use_team_graphic off"
fi

number=11
usecoach="true"

unum=0

sleepprog=sleep
goaliesleep=1
sleeptime=0

debugopt=""
coachdebug=""

offline_logging=""
offline_mode=""
fullstateopt=""
extra_player_opt=""

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

    -t|--teamname)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      teamname="${2}"
      shift 1
      ;;

    -n|--number)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      number="${2}"
      shift 1
      ;;

    -u|--unum)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      unum="${2}"
      shift 1
      ;;

    -C|--without-coach)
      usecoach="false"
      ;;

    -f|--formation)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      config_dir="${2}"
      shift 1
      ;;

    --team-graphic)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      team_graphic="--use_team_graphic on --team_graphic_file ${2}"
      shift 1
      ;;

    --offline-logging)
      offline_logging="--offline_logging"
      ;;

    --offline-client-mode)
      offline_mode="on"
      ;;

    --debug)
      debugopt="${debugopt} --debug"
      coachdebug="${coachdebug} --debug"
      ;;

    --debug_*)
      debug_opt="${debug_opt} ${1}"
      ;;

    --debug-server-connect)
      debugopt="${debugopt} --debug_server_connect"
      ;;

    --debug-server-host)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      debug_server_host="${2}"
      shift 1
      ;;

    --debug-server-port)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      debug_server_port="${2}"
      shift 1
      ;;

    --debug-server-logging)
      debugopt="${debugopt} --debug_server_logging"
      ;;

    --log-dir)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      debugopt="${debugopt} --log_dir ${2}"
      shift 1
      ;;

    --debug-log-ext)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      debugopt="${debugopt} --debug_log_ext ${2}"
      shift 1
      ;;

    --fullstate)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      fullstate_type="${2}"
      shift 1

      case "${fullstate_type}" in
        ignore)
          fullstateopt="--use_fullstate false --debug_fullstate false"
          ;;

        reference)
          fullstateopt="--use_fullstate false --debug_fullstate true"
          ;;

        override)
          fullstateopt="--use_fullstate true --debug_fullstate true"
          ;;

        *)
          usage
          exit 1
          ;;
      esac
      ;;

    --LogSafeActionSelectorDatasetV1)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      extra_player_opt="${extra_player_opt} --LogSafeActionSelectorDatasetV1 ${2}"
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

if  [ X"${offline_logging}" != X'' ]; then
  if  [ X"${offline_mode}" != X'' ]; then
    echo "'--offline-logging' and '--offline-mode' cannot be used simultaneously."
    exit 1
  fi
fi

if [ X"${coach_port}" = X'' ]; then
  coach_port=`expr ${port} + 2`
fi

if [ X"${debug_server_host}" = X'' ]; then
  debug_server_host="${host}"
fi

if [ X"${debug_server_port}" = X'' ]; then
  debug_server_port=`expr ${port} + 32`
fi

opt="--player-config ${player_conf} --config_dir ${config_dir}"
opt="${opt} -h ${host} -p ${port} -t ${teamname}"
opt="${opt} ${fullstateopt}"
opt="${opt} --debug_server_host ${debug_server_host}"
opt="${opt} --debug_server_port ${debug_server_port}"
opt="${opt} ${offline_logging}"
opt="${opt} ${debugopt}"
opt="${opt} ${extra_player_opt}"

ping -c 1 "$host"

if [ $number -gt 0 ]; then
  offline_number=""
  if  [ X"${offline_mode}" != X'' ]; then
    offline_number="--offline_client_number 1"
    if [ $unum -eq 0 ]; then
      "$player" ${opt} -g ${offline_number} &
      $sleepprog $goaliesleep
    elif [ $unum -eq 1 ]; then
      "$player" ${opt} -g ${offline_number} &
      $sleepprog $goaliesleep
    fi
  else
    "$player" ${opt} -g &
    $sleepprog $goaliesleep
  fi
fi

i=2
while [ $i -le ${number} ] ; do
  offline_number=""
  if  [ X"${offline_mode}" != X'' ]; then
    offline_number="--offline_client_number ${i}"
    if [ $unum -eq 0 ]; then
      "$player" ${opt} ${offline_number} &
      $sleepprog $sleeptime
    elif [ $unum -eq $i ]; then
      "$player" ${opt} ${offline_number} &
      $sleepprog $sleeptime
    fi
  else
    "$player" ${opt} &
    $sleepprog $sleeptime
  fi

  i=`expr $i + 1`
done

if [ "${usecoach}" = "true" ]; then
  coachopt="--coach-config ${coach_conf}"
  coachopt="${coachopt} -h ${host} -p ${coach_port} -t ${teamname}"
  coachopt="${coachopt} ${team_graphic}"
  coachopt="${coachopt} --debug_server_host ${debug_server_host}"
  coachopt="${coachopt} --debug_server_port ${debug_server_port}"
  coachopt="${coachopt} ${offline_logging}"
  coachopt="${coachopt} ${debugopt}"


  if  [ X"${offline_mode}" != X'' ]; then
    offline_mode="--offline_client_mode"
    if [ $unum -eq 0 ]; then
      if [ -n "${LOGO_ABS}" ]; then
        "$coach" ${coachopt} --team_graphic_file "${LOGO_ABS}" ${offline_mode} &
      else
        "$coach" ${coachopt} ${offline_mode} &
      fi
    elif [ $unum -eq 12 ]; then
      if [ -n "${LOGO_ABS}" ]; then
        "$coach" ${coachopt} --team_graphic_file "${LOGO_ABS}" ${offline_mode} &
      else
        "$coach" ${coachopt} ${offline_mode} &
      fi
    fi
  else
    if [ -n "${LOGO_ABS}" ]; then
      "$coach" ${coachopt} --team_graphic_file "${LOGO_ABS}" &
    else
      "$coach" ${coachopt} &
    fi
  fi
fi
