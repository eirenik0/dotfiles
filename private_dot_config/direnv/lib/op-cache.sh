# shellcheck disable=SC2148
# Target shell: zsh.
# 1Password helpers for direnv.
# Cache op:// reads so opening new shells/panes does not trigger a
# 1Password verification for every direnv evaluation.
# Security note: cached values are plaintext files with 0600 permissions.

_op_direnv_cache_mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
}

_op_direnv_cache_key() {
  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha256sum | awk '{print $1}'
  else
    printf '%s' "$1" | cksum | awk '{print $1"-"$2}'
  fi
}

_op_direnv_cache_is_fresh() {
  local cache_file="$1"
  local ttl="${OP_DIRENV_CACHE_TTL:-43200}"
  local now mtime

  case "$ttl" in
    ''|*[!0-9]*) ttl=43200 ;;
  esac

  [ -r "$cache_file" ] || return 1
  [ "$ttl" -gt 0 ] 2>/dev/null || return 0

  now=$(date +%s)
  mtime=$(_op_direnv_cache_mtime "$cache_file")
  [ $((now - mtime)) -lt "$ttl" ]
}

_op_direnv_cache_lock_acquire() {
  local lock_dir="$1"
  local stale_after="${OP_DIRENV_LOCK_STALE_AFTER:-120}"
  local wait_seconds="${OP_DIRENV_LOCK_WAIT_SECONDS:-10}"
  local lock_mtime now deadline

  case "$stale_after" in
    ''|*[!0-9]*) stale_after=120 ;;
  esac
  case "$wait_seconds" in
    ''|*[!0-9]*) wait_seconds=10 ;;
  esac

  now=$(date +%s)
  deadline=$((now + wait_seconds))

  while ! mkdir "$lock_dir" 2>/dev/null; do
    if [ ! -d "$lock_dir" ]; then
      echo "op_read_cached: failed to create lock $lock_dir" >&2
      return 1
    fi

    now=$(date +%s)
    lock_mtime=$(_op_direnv_cache_mtime "$lock_dir")
    if [ $((now - lock_mtime)) -ge "$stale_after" ]; then
      rm -rf "$lock_dir" 2>/dev/null || true
      continue
    fi

    if [ "$now" -ge "$deadline" ]; then
      echo "op_read_cached: timed out waiting for lock $lock_dir" >&2
      return 1
    fi

    sleep 0.1
  done

  printf '%s %s\n' "$$" "$(date +%s)" > "$lock_dir/pid" || {
    _op_direnv_cache_lock_release "$lock_dir"
    return 1
  }
}

_op_direnv_cache_lock_release() {
  rm -rf "$1" 2>/dev/null || true
}

op_cache_clear() {
  local op_ref="${1:-}"
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/op-direnv"

  if [ -z "$op_ref" ]; then
    rm -rf "$cache_dir"
    return 0
  fi

  rm -f "$cache_dir/$(_op_direnv_cache_key "$op_ref")"
}

op_read_cached() {
  local var_name="$1"
  local op_ref="$2"

  if [ -z "$var_name" ] || [ -z "$op_ref" ]; then
    echo "op_read_cached: usage: op_read_cached VAR_NAME op://vault/item/field" >&2
    return 2
  fi

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/op-direnv"
  local cache_key cache_file lock_dir value tmp_file rc old_umask
  cache_key="$(_op_direnv_cache_key "$op_ref")"
  cache_file="$cache_dir/$cache_key"
  lock_dir="$cache_file.lock"

  mkdir -p "$cache_dir"
  chmod 700 "$cache_dir" 2>/dev/null || true

  if _op_direnv_cache_is_fresh "$cache_file"; then
    value=$(cat "$cache_file") || return $?
    export "$var_name=$value"
    return 0
  fi

  _op_direnv_cache_lock_acquire "$lock_dir" || return $?

  if _op_direnv_cache_is_fresh "$cache_file"; then
    value=$(cat "$cache_file")
    rc=$?
    _op_direnv_cache_lock_release "$lock_dir"
    [ "$rc" -eq 0 ] || return "$rc"
    export "$var_name=$value"
    return 0
  fi

  value=$(op read "$op_ref")
  rc=$?
  if [ "$rc" -ne 0 ]; then
    _op_direnv_cache_lock_release "$lock_dir"
    return "$rc"
  fi

  old_umask=$(umask)
  umask 077
  tmp_file=$(mktemp "$cache_file.XXXXXX")
  rc=$?
  umask "$old_umask"
  if [ "$rc" -ne 0 ]; then
    _op_direnv_cache_lock_release "$lock_dir"
    return "$rc"
  fi

  printf '%s' "$value" > "$tmp_file"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    rm -f "$tmp_file"
    _op_direnv_cache_lock_release "$lock_dir"
    return "$rc"
  fi

  chmod 600 "$tmp_file" 2>/dev/null
  rc=$?
  if [ "$rc" -ne 0 ]; then
    rm -f "$tmp_file"
    _op_direnv_cache_lock_release "$lock_dir"
    return "$rc"
  fi

  mv "$tmp_file" "$cache_file"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    rm -f "$tmp_file"
    _op_direnv_cache_lock_release "$lock_dir"
    return "$rc"
  fi

  _op_direnv_cache_lock_release "$lock_dir"
  export "$var_name=$value"
}
