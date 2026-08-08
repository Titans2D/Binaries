#!/bin/sh
set -eu

cd "$(dirname "$0")"

if [ "${LD_LIBRARY_PATH:-}" = "" ]; then
  export LD_LIBRARY_PATH="$PWD/lib"
else
  export LD_LIBRARY_PATH="$PWD/lib:$LD_LIBRARY_PATH"
fi

# 1. Valores padrão
host="localhost"
port="6000"
coach_port="6002"
teamname="NexusPrime"
num_players=11
without_coach="false"
player_config="./player.conf"
coach_config="./coach.conf"
formation_dir="./formations-dt"
team_graphic="./team-graphic.xpm"

usage()
{
  (echo "Usage: $0 [options]"
   echo "Available options:"
   echo "      --help                    prints this"
   echo "  -h, --host HOST             specifies server host (default: localhost)"
   echo "  -p, --port PORT             specifies server port (default: 6000)"
   echo "  -P, --coach-port PORT       specifies server port for online coach (default: 6002)"
   echo "  -t, --teamname TEAMNAME     specifies team name"
   echo "  -n, --number NUMBER         specifies the number of players"
   echo "  -C, --without-coach         specifies not to run the coach"
   echo "  -f, --formation DIR         specifies the formation directory"
   echo "  --team-graphic FILE         specifies the team graphic xpm file") 1>&2
}

# 2. Processamento dos argumentos ANTES de iniciar os processos
while [ $# -gt 0 ]
do
  case $1 in
    --help)
      usage
      exit 0
      ;;
    -h|--host)
      [ $# -lt 2 ] && { usage; exit 1; }
      host="${2}"
      shift 2
      ;;
    -p|--port)
      [ $# -lt 2 ] && { usage; exit 1; }
      port="${2}"
      shift 2
      ;;
    -P|--coach-port)
      [ $# -lt 2 ] && { usage; exit 1; }
      coach_port="${2}"
      shift 2
      ;;
    -t|--teamname)
      [ $# -lt 2 ] && { usage; exit 1; }
      teamname="${2}"
      shift 2
      ;;
    -n|--number)
      [ $# -lt 2 ] && { usage; exit 1; }
      num_players="${2}"
      shift 2
      ;;
    -C|--without-coach)
      without_coach="true"
      shift 1
      ;;
    -f|--formation)
      [ $# -lt 2 ] && { usage; exit 1; }
      formation_dir="${2}"
      shift 2
      ;;
    --team-graphic)
      [ $# -lt 2 ] && { usage; exit 1; }
      team_graphic="${2}"
      shift 2
      ;;
    *)
      # Se passar argumentos antigos posicionais por compatibilidade
      if [ "${1#-}" = "$1" ]; then
        host="${1}"
        port="${2:-6000}"
        coach_port="${3:-6002}"
        shift 1
      else
        echo "invalid option \"${1}\"." 1>&2
        usage
        exit 1
      fi
      ;;
  esac
done

# 3. Inicialização dos Jogadores (agora com as variáveis corretas)

# Jogador 1 (Goalie)
./sample_player --player-config "$player_config" --config_dir "$formation_dir" -h "$host" -p "$port" -t "$teamname" -g >/dev/null 2>&1 &
sleep 1

# Demais jogadores
i=2
while [ "$i" -le "$num_players" ]; do
  ./sample_player --player-config "$player_config" --config_dir "$formation_dir" -h "$host" -p "$port" -t "$teamname" >/dev/null 2>&1 &
  i=$((i + 1))
done

# Coach (se habilitado)
if [ "$without_coach" = "false" ]; then
  ./sample_coach --coach-config "$coach_config" -h "$host" -P "$coach_port" -t "$teamname" --use_team_graphic on --team_graphic_file "$team_graphic" >/dev/null 2>&1 &
fi