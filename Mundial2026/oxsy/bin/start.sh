#!/bin/sh
VERSION="${VERSION:-C++}"

# Valores padrão
HOST="127.0.0.1"
BASEDIR="$(cd "$(dirname "$0")" && pwd)"
PORT=6000
COACH_PORT=6002
TEAM="Oxsy"
FORMATION=""
STRATEGY=""

# --- Parse de argumentos (suporta tanto o autotest quanto chamada manual) ---
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
      # Compatibilidade com argumentos posicionais antigos ($1, $2, $3, $4...)
      if [ -z "$POS_HOST" ]; then
        POS_HOST="$1"
      elif [ -z "$POS_BASEDIR" ]; then
        POS_BASEDIR="$1"
      elif [ -z "$POS_NUM" ]; then
        POS_NUM="$1"
      elif [ -z "$POS_PORT" ]; then
        POS_PORT="$1"
      fi
      shift
      ;;
  esac
done

# Aplica argumentos posicionais caso tenham sido passados
[ -n "$POS_HOST" ] && HOST="$POS_HOST"
[ -n "$POS_BASEDIR" ] && BASEDIR="$POS_BASEDIR"
[ -n "$POS_NUM" ] && NUM="$POS_NUM"
[ -n "$POS_PORT" ] && PORT="$POS_PORT"

# Garante a porta correta do coach se não informada
[ -z "$COACH_PORT" ] && COACH_PORT=$((PORT + 2))

cd "$BASEDIR" || exit 1

# Configurações de binários baseadas na versão
case "$VERSION" in
    GO|Go|go)
        FORMATION="${FORMATION:-strategy/4-3-3.conf}"
        STRATEGY="${STRATEGY:-strategy/strategy.conf}"
        LOG_DIR="${LOG_DIR:-log}"
        dbg=""; [ -n "$DEBUG" ] && dbg="-debug"
        player="./bin/oxsy_player"
        coach="./bin/oxsy_coach"
        player_opt="-host ${HOST} -port ${PORT} -team ${TEAM} -formation ${FORMATION} -strategy ${STRATEGY} -log-dir ${LOG_DIR} ${dbg}"
        coach_opt="-host ${HOST} -port ${PORT} -team ${TEAM} -formation ${FORMATION} -log-dir ${LOG_DIR} ${dbg}"
        ;;
    *)
        STRATEGY="${STRATEGY:-config/oxsysoccer.conf}"
        player="./bin/oxsyplayer"
        coach="./bin/oxsycoach"
        player_opt="-team_name ${TEAM} -server_ip ${HOST} -player_port ${PORT} -oxsy_soccer_path ${STRATEGY}"
        coach_opt="-team_name ${TEAM} -server_ip ${HOST} -coach_port ${COACH_PORT} -oxsy_soccer_path ${STRATEGY}"
        ;;
esac

# --- INICIALIZAÇÃO INTELIGENTE PARA O AUTOTEST ---
if [ -z "$NUM" ]; then
    # Se o autotest chamou sem número (modo all-in-one por thread), sobe o time inteiro em background:
    
    # 1. Goleiro (Uniforme 1 com flag de goalie)
    case "$VERSION" in
        GO|Go|go)
            $player $player_opt -goalie >/dev/null 2>&1 &
            ;;
        *)
            $player $player_opt -goalie >/dev/null 2>&1 &
            ;;
    esac

    # 2. Jogadores de linha (2 a 11)
    i=2
    while [ $i -le 11 ]; do
        $player $player_opt >/dev/null 2>&1 &
        i=$((i + 1))
    done

    # 3. Coach/Técnico
    $coach $coach_opt >/dev/null 2>&1 &

    # Aguarda os processos filhos para manter a thread viva
    wait
else
    # Comportamento original individual caso receba um NUM específico
    case $NUM in
        1)
            $player $player_opt -goalie
            ;;
        12)
            $coach $coach_opt
            ;;
        *)
            $player $player_opt
            ;;
    esac
fi