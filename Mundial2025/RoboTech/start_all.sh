#!/bin/bash
#
# start_all.sh — levanta TODOS los players y luego el coach con logo.
#

HOST=localhost
PORT=6000
TEAM=RoboTech
NUM_PLAYERS=11

DIR="$(cd "$(dirname "$0")" && pwd)"
PLAYER="$DIR/sample_player"
COACH="$DIR/sample_coach"
PCONF="$DIR/player.conf"
CCONF="$DIR/coach.conf"
FORMDIR="$DIR/formations-dt"
LIBDIR="$DIR/lib"
LOGO="$DIR/team_logo.xpm"

export LD_LIBRARY_PATH="$LIBDIR${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH"

cd "$DIR" || exit 1

echo "▶ Launching players 1–$NUM_PLAYERS…"
# Primer jugador (goalie)
"$PLAYER" \
  --player-config "$PCONF" \
  --config_dir "$FORMDIR" \
  -h "$HOST" -p "$PORT" -t "$TEAM" -g &
sleep 1

# Jugadores 2..NUM_PLAYERS
for i in $(seq 2 $NUM_PLAYERS); do
  "$PLAYER" \
    --player-config "$PCONF" \
    --config_dir "$FORMDIR" \
    -h "$HOST" -p "$PORT" -t "$TEAM" --unum "$i" &
  sleep 0.1
done

# Coach con logo en port+2
COACH_PORT=$((PORT + 2))
echo "▶ Launching coach with logo…"
"$COACH" \
  --coach-config "$CCONF" \
  --use_team_graphic on \
  --team-graphic-file "$LOGO" \
  -h "$HOST" -p "$COACH_PORT" -t "$TEAM" &

wait
echo "▶ All processes started."

