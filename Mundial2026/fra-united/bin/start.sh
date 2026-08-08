#!/bin/bash

# Valores padrão
HOST="127.0.0.1"
BASEDIR=""
NUM=""
PORT=6000
COACH_PORT=6002
TEAM="FRA-UNIted"

# --- Parse de argumentos (suporta autotest e chamadas tradicionais) ---
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
      TEAM="$2"
      shift 2
      ;;
    *)
      if [ -z "$POS_HOST" ]; then
        POS_HOST="$1"
      elif [ -z "$POS_BASEDIR" ]; then
        POS_BASEDIR="$1"
      elif [ -z "$POS_NUM" ]; then
        POS_NUM="$1"
      fi
      shift
      ;;
  esac
done

[ -n "$POS_HOST" ] && HOST="$POS_HOST"
[ -n "$POS_BASEDIR" ] && BASEDIR="$POS_BASEDIR"
[ -n "$POS_NUM" ] && NUM="$POS_NUM"

# Se BASEDIR foi definido, entra nele (ou usa o diretório atual do script)
if [ -n "$BASEDIR" ]; then
  cd "${BASEDIR}" || exit 1
else
  cd "$(dirname "$0")" || exit 1
fi

AGENTDIR="agent/bin"
AGENT="FRA-UNIted_Agent"
# Adiciona a porta ao AGENTOPT
AGENTOPT="-host $HOST -port $PORT -team_name $TEAM"

COACHDIR="coach/bin"
COACH="FRA-UNIted_Coach"
# Adiciona a porta ao COACHOPT
COACHOPT="-server_9.4 0 -host $HOST -port $COACH_PORT -team_name $TEAM"

# --- INICIALIZAÇÃO INTELIGENTE PARA O AUTOTEST ---
if [ -z "$NUM" ]; then
    # Se o autotest chamou sem número, sobe o time inteiro em background:
    
    # 1. Goleiro
    (cd "$AGENTDIR" && ./$AGENT -goalie $AGENTOPT >/dev/null 2>&1) &

    # 2. Jogadores de linha (2 a 11)
    i=2
    while [ $i -le 11 ]; do
        (cd "$AGENTDIR" && ./$AGENT $AGENTOPT >/dev/null 2>&1) &
        i=$((i + 1))
    done

    # 3. Coach
    (cd "$COACHDIR" && ./$COACH $COACHOPT >/dev/null 2>&1) &

    # Mantém a thread viva aguardando os processos
    wait
else
    # Comportamento original caso receba um NUM específico
    case $NUM in
        1)
            cd "$AGENTDIR" || exit 1
            ./$AGENT -goalie $AGENTOPT
            ;;
        12)
            cd "$COACHDIR" || exit 1
            ./$COACH $COACHOPT
            ;;
        *)
            cd "$AGENTDIR" || exit 1
            ./$AGENT $AGENTOPT
            ;;
    esac
fi