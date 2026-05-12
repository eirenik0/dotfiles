# 1Password helpers for direnv.
# Cache op:// reads briefly so opening new shells/panes does not trigger a
# 1Password verification for every direnv evaluation.
# Security note: cached values are plaintext files with 0600 permissions.

_op_direnv_cache_mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
}

_op_direnv_cache_key() {
  printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
}

op_read_cached() {
  local var_name="$1"
  local op_ref="$2"
  local ttl="${OP_DIRENV_CACHE_TTL:-43200}"

  if [ -z "$var_name" ] || [ -z "$op_ref" ]; then
    echo "op_read_cached: usage: op_read_cached VAR_NAME op://vault/item/field" >&2
    return 2
  fi

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/op-direnv"
  mkdir -p "$cache_dir"
  chmod 700 "$cache_dir" 2>/dev/null || true

  local cache_file="$cache_dir/$(_op_direnv_cache_key "$op_ref")"
  local now mtime value
  now=$(date +%s)

  if [ -r "$cache_file" ]; then
    mtime=$(_op_direnv_cache_mtime "$cache_file")
    if [ $((now - mtime)) -lt "$ttl" ]; then
      value=$(cat "$cache_file")
      export "$var_name=$value"
      return 0
    fi
  fi

  value=$(op read "$op_ref") || return $?
  umask 077
  printf '%s' "$value" > "$cache_file"
  chmod 600 "$cache_file" 2>/dev/null || true
  export "$var_name=$value"
}
