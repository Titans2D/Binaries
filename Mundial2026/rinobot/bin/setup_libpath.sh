# shellcheck shell=sh
# Deteta librcsc: ./lib (pacote) ou pimentao_verde_lib/ ao subir a partir do script.
# Uso: . "$(dirname "$0")/setup_libpath.sh" && pimentao_export_libpath "$(cd "$(dirname "$0")" && pwd)"

pimentao_find_libpath() {
  _base="$1"
  if [ -z "$_base" ]; then
    return 1
  fi

  if [ -d "${_base}/lib" ] && ls "${_base}/lib"/librcsc.so* >/dev/null 2>&1; then
    echo "${_base}/lib"
    return 0
  fi

  _dir="${_base}"
  while [ -n "$_dir" ] && [ "$_dir" != "/" ]; do
    if [ -d "${_dir}/pimentao_verde_lib/lib" ] \
       && ls "${_dir}/pimentao_verde_lib/lib"/librcsc.so* >/dev/null 2>&1; then
      echo "${_dir}/pimentao_verde_lib/lib"
      return 0
    fi
    _dir=$(dirname "$_dir")
  done

  for _d in \
    "${HOME}/local/pimentao_verde_lib/lib" \
    "${HOME}/.local/pimentao_verde_lib/lib" \
    "${HOME}/local/cyruslib/lib"
  do
    if [ -d "$_d" ] && ls "${_d}"/librcsc.so* >/dev/null 2>&1; then
      echo "$_d"
      return 0
    fi
  done

  return 1
}

pimentao_export_libpath() {
  _base="$1"
  LIBPATH=$(pimentao_find_libpath "$_base") || return 1
  if [ -z "${LD_LIBRARY_PATH:-}" ]; then
    export LD_LIBRARY_PATH="${LIBPATH}"
  else
    export LD_LIBRARY_PATH="${LIBPATH}:${LD_LIBRARY_PATH}"
  fi
  return 0
}
