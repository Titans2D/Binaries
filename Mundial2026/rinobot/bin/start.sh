#!/bin/sh

echo "******************************************************************"
echo " This program is modified by Rinobot."
echo " Copyright 2025. Rinobot."
echo " All rights reserved."
echo "******************************************************************"
echo " This program is based on agent2d created by Hidehisa Akiyama."
echo " Copyright 2006 - 2011. Hidehisa Akiyama and Hiroki Shimora."
echo " All rights reserved."
echo "******************************************************************"

DIR="$(cd "$(dirname "$0")" && pwd)"

# Players load Setting::ReadJson() from ./data/settings/ (e.g. teams.conf, pimentao_verde.json)
# relative to this directory — typically build/src/data/settings/, synced from src/data/settings/
# on each build (CMake target copy_team_settings). Edit JSON under src/data/settings/ and rebuild.

# dash aborta o script se "." falhar num ficheiro inexistente — testar antes de source
if [ -f "${DIR}/../../script/setup_libpath.sh" ]; then
  . "${DIR}/../../script/setup_libpath.sh"
elif [ -f "${DIR}/../script/setup_libpath.sh" ]; then
  . "${DIR}/../script/setup_libpath.sh"
fi
if type pimentao_export_libpath >/dev/null 2>&1; then
  pimentao_export_libpath "${DIR}" 2>/dev/null || true
fi
if [ -z "${LD_LIBRARY_PATH:-}" ] \
   || ! ls "${LD_LIBRARY_PATH%%:*}"/librcsc.so* >/dev/null 2>&1; then
  LIBPATH=/home/andrelcol/Desktop/pimentaoVerde/pimentao_verde_lib/lib
  if [ -d "$LIBPATH" ] && ls "${LIBPATH}"/librcsc.so* >/dev/null 2>&1; then
    export LD_LIBRARY_PATH="${LIBPATH}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  fi
fi

TEAM_LOG="${DIR}/../log/team_start.log"
mkdir -p "$(dirname "${TEAM_LOG}")" 2>/dev/null || TEAM_LOG="/tmp/rinobot_team_start.log"

server_port_open() {
  _h="$1"
  _p="$2"
  if command -v nc >/dev/null 2>&1; then
    nc -z "$_h" "$_p" 2>/dev/null
    return $?
  fi
  if command -v ss >/dev/null 2>&1; then
    ss -tln 2>/dev/null | grep -q ":${_p} "
    return $?
  fi
  return 0
}

player="${DIR}/sample_player"
coach="${DIR}/sample_coach"
teamname="Rinobot-Team"
host="localhost"
port=6000
coach_port=""
debug_server_host=""
debug_server_port=""

player_conf="${DIR}/player.conf"
config_dir="${DIR}/formations-dt"

coach_conf="${DIR}/coach.conf"
# Banner/logo da equipa (aparece no monitor quando o tempo entra em campo)
# Como no itandroids: usar team_logo.xpm no diretório do script; senão logo.xpm
# Caminho absoluto (com aspas ao passar ao coach para paths com espaços)
LOGO_ABS=""
if [ -f "${DIR}/team_logo.xpm" ]; then
  LOGO_ABS="$(cd "${DIR}" && pwd)/team_logo.xpm"
  team_graphic="--use_team_graphic on"
elif [ -f "${DIR}/logo.xpm" ]; then
  LOGO_ABS="$(cd "${DIR}" && pwd)/logo.xpm"
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

show_info=""
offline_logging=""
offline_mode=""
fullstateopt=""

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
   echo "  -i, --info                   show agent output during the game (default: off)"
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

    -i|--info)
      show_info="1"
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

if ! ping -c 1 "$host" >/dev/null 2>&1; then
  echo "AVISO: host '${host}' não responde ao ping." 1>&2
fi

if ! server_port_open "$host" "$port"; then
  echo "" 1>&2
  echo "AVISO: nada escuta em ${host}:${port} (rcssserver parado?)." 1>&2
  echo "  Terminal 1: rcssserver" 1>&2
  echo "            ou: rcssserver server::port=${port}" 1>&2
  echo "  Terminal 2: cd $(dirname "$DIR")/src 2>/dev/null || cd ${DIR}" 1>&2
  echo "            ./start.sh -i" 1>&2
  echo "  Monitor: localhost:${port} -> Kick Off para a equipa entrar em campo." 1>&2
  echo "" 1>&2
fi

# Run agent with optional output suppression (-i enables output)
run_agent() {
  if [ -n "${show_info}" ]; then
    "$@" &
  else
    "$@" >>"${TEAM_LOG}" 2>&1 &
  fi
}

if [ $number -gt 0 ]; then
  offline_number=""
  if  [ X"${offline_mode}" != X'' ]; then
    offline_number="--offline_client_number 1"
    if [ $unum -eq 0 ]; then
      run_agent $player ${opt} -g ${offline_number}
      $sleepprog $goaliesleep
    elif [ $unum -eq 1 ]; then
      run_agent $player ${opt} -g ${offline_number}
      $sleepprog $goaliesleep
    fi
  else
    run_agent $player ${opt} -g
    $sleepprog $goaliesleep
  fi
fi

i=2
while [ $i -le ${number} ] ; do
  offline_number=""
  if  [ X"${offline_mode}" != X'' ]; then
    offline_number="--offline_client_number ${i}"
    if [ $unum -eq 0 ]; then
      run_agent $player ${opt} ${offline_number}
      $sleepprog $sleeptime
    elif [ $unum -eq $i ]; then
      run_agent $player ${opt} ${offline_number}
      $sleepprog $sleeptime
    fi
  else
    run_agent $player ${opt}
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
      if [ -n "${LOGO_ABS}" ]; then run_agent $coach ${coachopt} --team_graphic_file "${LOGO_ABS}" ${offline_mode}; else run_agent $coach ${coachopt} ${offline_mode}; fi
    elif [ $unum -eq 12 ]; then
      if [ -n "${LOGO_ABS}" ]; then run_agent $coach ${coachopt} --team_graphic_file "${LOGO_ABS}" ${offline_mode}; else run_agent $coach ${coachopt} ${offline_mode}; fi
    fi
  else
    if [ -n "${LOGO_ABS}" ]; then run_agent $coach ${coachopt} --team_graphic_file "${LOGO_ABS}"; else run_agent $coach ${coachopt}; fi
  fi
fi

sleep 2
_player_n=0
if command -v pgrep >/dev/null 2>&1; then
  _player_n=$(pgrep -f "${player}" 2>/dev/null | wc -l)
fi
if [ "${_player_n}" -eq 0 ] 2>/dev/null; then
  echo "" 1>&2
  echo "ERRO: nenhum jogador ficou em execução." 1>&2
  if [ -z "${show_info}" ]; then
    echo "  Sem -i, a saída foi para: ${TEAM_LOG}" 1>&2
    echo "  Últimas linhas:" 1>&2
    tail -n 15 "${TEAM_LOG}" 2>/dev/null | sed 's/^/    /' 1>&2
  fi
  echo "  Confirme: rcssserver na porta ${port}; librcsc em LD_LIBRARY_PATH." 1>&2
  exit 1
fi

echo ""
echo "Equipa '${teamname}' lançada (${_player_n} jogadores + coach)."
echo "  Servidor: ${host}:${port}  |  Coach: ${host}:${coach_port}"
if [ -z "${show_info}" ]; then
  echo "  Log dos agentes: ${TEAM_LOG}  (use ./start.sh -i para ver no terminal)"
fi
echo "  No monitor: conecte a ${host}:${port} e dê Kick Off."
echo ""
