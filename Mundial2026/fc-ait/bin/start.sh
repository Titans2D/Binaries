#!/bin/bash
# SS2DTM/大会マネージャが host を引数で渡す場合は $1 を優先 (未指定なら localhost)
HOST=${1:-127.0.0.1}

# 1. スクリプトがあるディレクトリの絶対パスを取得
HOMEDIR=$(cd $(dirname "$0") && pwd)

# 2. そのディレクトリに移動 (これで ./data が見つかる)
cd "$HOMEDIR"

${HOMEDIR}/start ${HOST} ${HOMEDIR} 1 &
sleep 0.5
${HOMEDIR}/start ${HOST} ${HOMEDIR} 2 &
sleep 0.1
${HOMEDIR}/start ${HOST} ${HOMEDIR} 3 &
sleep 0.1
${HOMEDIR}/start ${HOST} ${HOMEDIR} 4 &
sleep 0.1
${HOMEDIR}/start ${HOST} ${HOMEDIR} 5 &
sleep 0.1
${HOMEDIR}/start ${HOST} ${HOMEDIR} 6 &
sleep 0.1
${HOMEDIR}/start ${HOST} ${HOMEDIR} 7 &
sleep 0.1
${HOMEDIR}/start ${HOST} ${HOMEDIR} 8 &
sleep 0.1
${HOMEDIR}/start ${HOST} ${HOMEDIR} 9 &
sleep 0.1
${HOMEDIR}/start ${HOST} ${HOMEDIR} 10 &
sleep 0.1
${HOMEDIR}/start ${HOST} ${HOMEDIR} 11 &
sleep 0.5
${HOMEDIR}/start ${HOST} ${HOMEDIR} 12 &

