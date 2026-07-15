#!/bin/sh
set -eu

cd "$(dirname "$0")"

if [ "${LD_LIBRARY_PATH:-}" = "" ]; then
  export LD_LIBRARY_PATH="$PWD/lib"
else
  export LD_LIBRARY_PATH="$PWD/lib:$LD_LIBRARY_PATH"
fi

host="${1:-localhost}"
port="${2:-6000}"
coach_port="${3:-6002}"

./sample_player --player-config ./player.conf --config_dir ./formations-dt -h "$host" -p "$port" -t "NexusPrime" -g >/dev/null 2>&1 &
sleep 1

i=2
while [ "$i" -le 11 ]; do
  ./sample_player --player-config ./player.conf --config_dir ./formations-dt -h "$host" -p "$port" -t "NexusPrime" >/dev/null 2>&1 &
  i=$((i + 1))
done

./sample_coach --coach-config ./coach.conf -h "$host" -p "$coach_port" -t "NexusPrime" --use_team_graphic on --team_graphic_file ./team-graphic.xpm >/dev/null 2>&1 &
