#!/bin/bash
HOST=127.0.0.1

DIR=`dirname $0`
${DIR}/start ${HOST} ${DIR} 1 &
sleep 1.0
${DIR}/start ${HOST} ${DIR} 2 &
sleep 0.1
${DIR}/start ${HOST} ${DIR} 3 &
sleep 0.1
${DIR}/start ${HOST} ${DIR} 4 &
sleep 0.1
${DIR}/start ${HOST} ${DIR} 5 &
sleep 0.1
${DIR}/start ${HOST} ${DIR} 6 &
sleep 0.1
${DIR}/start ${HOST} ${DIR} 7 &
sleep 0.1
${DIR}/start ${HOST} ${DIR} 8 &
sleep 0.1
${DIR}/start ${HOST} ${DIR} 9 &
sleep 0.1
${DIR}/start ${HOST} ${DIR} 10 &
sleep 0.1
${DIR}/start ${HOST} ${DIR} 11 &
sleep 0.1
${DIR}/start ${HOST} ${DIR} 12 &
sleep 0.1
