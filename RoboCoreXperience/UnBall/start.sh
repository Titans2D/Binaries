#!/bin/sh
# Shim: alguns organizadores procuram o script em bin/start.sh, outros na raiz.
# Este arquivo cobre os dois casos.
DIR=$(cd "$(dirname "$0")" && pwd)
exec "$DIR/bin/start.sh" "$@"
