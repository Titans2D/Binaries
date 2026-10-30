#!/bin/sh
# ---------------------------------------------------------------------------
# start.sh endurecido para envio em competição (RoboCore / IronCup - Soccer 2D)
#
# Baseado no src/start.sh.in do RCSS2D, com as correções listadas no README.md:
#   - resolve caminhos relativos ao próprio script, independente do CWD
#   - coloca $DIR/lib e $DIR/../lib no LD_LIBRARY_PATH (librcsc empacotada)
#   - não depende de `ping`
#   - aceita TEAM_NAME / SERVER_HOST / SERVER_PORT por variável de ambiente
#   - falha com mensagem clara se o binário não existir
#
# O rcssserver executa este arquivo como:  /bin/sh -c /caminho/start.sh
# >>> SEM NENHUM ARGUMENTO <<<. Por isso os defaults abaixo precisam estar certos.
# ---------------------------------------------------------------------------

# --- diretório do script, funciona mesmo se chamado com caminho relativo -----
SCRIPT_PATH="$0"
case "$SCRIPT_PATH" in
  /*) : ;;
  *)  SCRIPT_PATH="$PWD/$SCRIPT_PATH" ;;
esac
DIR=$(cd "$(dirname "$SCRIPT_PATH")" && pwd) || exit 1
cd "$DIR" || exit 1

# --- bibliotecas: primeiro as que vieram no pacote, depois a do build --------
# O CMake substitui  pelo caminho da máquina de build.
LIBRCSC_BUILTIN_LIBDIR=""
for CAND in "$DIR/lib" "$DIR/../lib" "$LIBRCSC_BUILTIN_LIBDIR"; do
  case "$CAND" in
    *@*|"") continue ;;            # placeholder não substituído -> ignora
  esac
  [ -d "$CAND" ] || continue
  case ":$LD_LIBRARY_PATH:" in
    *":$CAND:"*) : ;;
    *) if [ -z "$LD_LIBRARY_PATH" ]; then
         LD_LIBRARY_PATH="$CAND"
       else
         LD_LIBRARY_PATH="$CAND:$LD_LIBRARY_PATH"
       fi ;;
  esac
done
export LD_LIBRARY_PATH

# --- configuração ------------------------------------------------------------
teamname="${TEAM_NAME:-UnBall}"
host="${SERVER_HOST:-localhost}"
port="${SERVER_PORT:-6000}"
coach_port=""
debug_server_host=""
debug_server_port=""

player="${DIR}/sample_player"
coach="${DIR}/sample_coach"

player_conf="${DIR}/player.conf"
config_dir="${DIR}/formations-dt"
coach_conf="${DIR}/coach.conf"

team_graphic="--use_team_graphic on"
if [ -f "${DIR}/team_logo.xpm" ]; then
  team_graphic="--use_team_graphic on --team_graphic_file ${DIR}/team_logo.xpm"
fi

number="${PLAYER_NUMBER:-11}"
usecoach="${USE_COACH:-true}"
sleepprog="${SLEEP_PROG:-sleep}"
goaliesleep=1
sleeptime=0
debugopt=""
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
   echo "  -P, --coach-port PORT        specifies server port for online coach (default: port+2)"
   echo "  -t, --teamname TEAMNAME      specifies team name"
   echo "  -n, --number NUMBER          specifies the number of players (default: 11)"
   echo "  -C, --without-coach          specifies not to run the coach"
   echo "  -f, --formation DIR          specifies the formation directory"
   echo "      --offline-logging        writes offline client log"
   echo "      --debug                  writes debug log"
   echo "      --fullstate TYPE         ignore|reference|override") 1>&2
}

while [ $# -gt 0 ]
do
  case "$1" in
    --help) usage; exit 0 ;;
    -h|--host)   [ $# -ge 2 ] || { usage; exit 1; }; host="$2"; shift ;;
    -p|--port)   [ $# -ge 2 ] || { usage; exit 1; }; port="$2"; shift ;;
    -P|--coach-port) [ $# -ge 2 ] || { usage; exit 1; }; coach_port="$2"; shift ;;
    -t|--teamname)   [ $# -ge 2 ] || { usage; exit 1; }; teamname="$2"; shift ;;
    -n|--number)     [ $# -ge 2 ] || { usage; exit 1; }; number="$2"; shift ;;
    -C|--without-coach) usecoach="false" ;;
    -f|--formation)  [ $# -ge 2 ] || { usage; exit 1; }; config_dir="$2"; shift ;;
    --offline-logging) offline_logging="--offline_logging" ;;
    --debug) debugopt="--debug" ;;
    --fullstate)
      [ $# -ge 2 ] || { usage; exit 1; }
      case "$2" in
        ignore)    fullstateopt="--use_fullstate false --debug_fullstate false" ;;
        reference) fullstateopt="--use_fullstate false --debug_fullstate true" ;;
        override)  fullstateopt="--use_fullstate true  --debug_fullstate true" ;;
        *) usage; exit 1 ;;
      esac
      shift ;;
    *) echo "invalid option \"$1\"." 1>&2; usage; exit 1 ;;
  esac
  shift
done

if [ -z "$coach_port" ]; then
  coach_port=$(expr "$port" + 2)
fi
if [ -z "$debug_server_host" ]; then debug_server_host="$host"; fi
if [ -z "$debug_server_port" ]; then debug_server_port=$(expr "$port" + 32); fi

# --- validações ruidosas: melhor falhar aqui do que dar W.O. ----------------
fail=0
[ -x "$player" ] || { echo "ERRO: nao encontrei o executavel: $player" >&2; fail=1; }
[ -f "$player_conf" ] || { echo "ERRO: nao encontrei o player.conf: $player_conf" >&2; fail=1; }
[ -d "$config_dir" ] || { echo "AVISO: pasta de formacao ausente: $config_dir" >&2; }
[ "$fail" -eq 0 ] || exit 1

echo "******************************************************************" >&2
echo " UnBall RCSS2D  |  time=$teamname  servidor=$host:$port  coach_port=$coach_port" >&2
echo " DIR=$DIR" >&2
echo " LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >&2
echo "******************************************************************" >&2

opt="--player-config ${player_conf} --config_dir ${config_dir}"
opt="${opt} -h ${host} -p ${port} -t ${teamname}"
opt="${opt} ${fullstateopt} ${offline_logging} ${debugopt}"

# goleiro (unum 1)
$player $opt -g &
$sleepprog $goaliesleep

i=2
while [ "$i" -le "$number" ]; do
  $player $opt &
  [ "$sleeptime" -gt 0 ] && $sleepprog $sleeptime
  i=$(expr "$i" + 1)
done

if [ "$usecoach" = "true" ] && [ -x "$coach" ]; then
  coachopt="--coach-config ${coach_conf}"
  coachopt="${coachopt} -h ${host} -p ${coach_port} -t ${teamname}"
  coachopt="${coachopt} ${team_graphic} ${offline_logging} ${debugopt}"
  $coach $coachopt &
fi

exit 0
