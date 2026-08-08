#!/bin/sh

# Valores padrão
HOST="localhost"
PORT=6000
COACH_PORT=6002
TEAM_NAME="Itandroids"

# Parse dos argumentos passados pelo autotest
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--host)
      HOST="$2"
      shift 2
      ;;
    -p|--port)
      PORT="$2"
      shift 2
      ;;
    -P|--coach-port)
      COACH_PORT="$2"
      shift 2
      ;;
    -t|--teamname)
      TEAM_NAME="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

LIBPATH=./lib
if [ x"$LIBPATH" != x ]; then
  if [ x"$LD_LIBRARY_PATH" = x ]; then
    LD_LIBRARY_PATH=$LIBPATH
  else
    LD_LIBRARY_PATH=$LIBPATH:$LD_LIBRARY_PATH
  fi
  export LD_LIBRARY_PATH
fi

player="./sample_player"
coach="./sample_coach"

config="player.conf"
coach_config="coach.conf"
config_dir="formations-dt"

opt="--player-config ${config} --config_dir ${config_dir}"
opt="${opt} -h ${HOST} -p ${PORT} -t ${TEAM_NAME}"

coachopt="--coach-config ${coach_config} --use_team_graphic on"
coachopt="${coachopt} -h ${HOST} -P ${COACH_PORT} -t ${TEAM_NAME}"

# --- LAÇO PARA SUBIR O TIME COMPLETO ---

# 1. Inicia o Goleiro (Uniforme 1 com flag -g)
$player $opt -g &

# 2. Inicia os jogadores de linha de 2 a 11
i=2
while [ $i -le 11 ]; do
  $player $opt &
  i=$((i + 1))
done

# 3. Inicia o Coach/Técnico
$coach $coachopt &

# Mantém o script rodando ou aguarda processos filhos se necessário
wait