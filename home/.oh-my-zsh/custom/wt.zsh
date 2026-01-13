# ~/.zsh/wt.zsh
# Interactive git-worktree helper for multiple repos via profiles config.
#
# Layout expected per profile repo_root:
#   <repo_root>/main    (canonical checkout)
#   <repo_root>/wt/...  (worktrees)
#
# Commands:
#   wt <profile> <type> <name> [-- <git worktree add args...>]
#   wt ls [profile]
#   wt cd <profile> <type> <name>
#   wt rm <profile> <type> <name> [--branch]
#
# Configuration:
#
# Edit .config/wt/profiles:
#
# platform=~/Development/hyperquote/hq-platform
# webapp=~/Development/hyperquote/hq-webapp


: "${WT_CONFIG:=$HOME/.config/wt/profiles}"

_wt_trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  print -r -- "$s"
}

_wt_expand_tilde() {
  local p="$1"
  # zsh-native: expands leading ~ (and ~user) safely and correctly
  print -r -- ${~p}
}

_wt_profiles() {
  [[ -r "$WT_CONFIG" ]] || return 0
  local line key
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == \#* ]] && continue
    [[ -z "${line//[[:space:]]/}" ]] && continue
    key="$(_wt_trim "${line%%=*}")"
    [[ -n "$key" ]] && print -r -- "$key"
  done < "$WT_CONFIG"
}

_wt_repo_root_for_profile() {
  local profile="$1"
  [[ -r "$WT_CONFIG" ]] || return 1

  local line key val
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == \#* ]] && continue
    [[ -z "${line//[[:space:]]/}" ]] && continue
    key="$(_wt_trim "${line%%=*}")"
    val="$(_wt_trim "${line#*=}")"
    if [[ "$key" == "$profile" ]]; then
      _wt_expand_tilde "$val"
      return 0
    fi
  done < "$WT_CONFIG"

  return 1
}

_wt_usage() {
  cat <<'EOF'
usage:
  wt <profile> <type> <name> [-- <git worktree add args...>]
  wt ls [profile]
  wt cd <profile> <type> <name>
  wt rm <profile> <type> <name> [--branch]

examples:
  wt platform fix pdfbox-memory
  wt webapp feature auth-redirect
  wt ls
  wt ls platform
  wt cd platform chore mychore
  wt rm platform fix pdfbox-memory
  wt rm platform fix pdfbox-memory --branch
EOF
}

_wt_need_main_checkout() {
  local main="$1"
  if [[ ! -d "$main" ]]; then
    print -u2 -- "Missing main checkout at: $main"
    return 1
  fi
  if [[ ! -e "$main/.git" ]]; then
    print -u2 -- "Not a git checkout: $main"
    return 1
  fi
  return 0
}

wt() {
  local cmd="${1-}"

  # Subcommands
  if [[ "$cmd" == "ls" ]]; then
    local profile="${2-}"
    if [[ -n "$profile" ]]; then
      local repo_root
      repo_root="$(_wt_repo_root_for_profile "$profile")" || {
        print -u2 -- "Unknown profile: $profile"
        print -u2 -- "Known profiles:"
        _wt_profiles | sed 's/^/  /' >&2
        return 1
      }
      local main="$repo_root/main"
      _wt_need_main_checkout "$main" || return 1

      print -r -- "== $profile =="
      command git -C "$main" worktree list
      return 0
    fi

    # No profile: list all profiles
    local p repo_root main
    for p in $(_wt_profiles); do
      repo_root="$(_wt_repo_root_for_profile "$p")" || continue
      main="$repo_root/main"
      if _wt_need_main_checkout "$main"; then
        print -r -- "== $p =="
        command git -C "$main" worktree list
        print -r -- ""
      else
        print -u2 -- "== $p == (missing main checkout: $main)"
      fi
    done
    return 0
  fi

  if [[ "$cmd" == "cd" ]]; then
    local profile="${2-}" type="${3-}" name="${4-}"
    if [[ -z "$profile" || -z "$type" || -z "$name" ]]; then
      _wt_usage
      return 1
    fi

    local repo_root
    repo_root="$(_wt_repo_root_for_profile "$profile")" || {
      print -u2 -- "Unknown profile: $profile"
      print -u2 -- "Known profiles:"
      _wt_profiles | sed 's/^/  /' >&2
      return 1
    }

    local dir="$repo_root/wt/$type/$name"

    if [[ -d "$dir" ]]; then
      builtin cd "$dir" || return 1
    else
      print -u2 -- "Worktree directory does not exist: $dir"
      return 1
    fi
    return 0
  fi

  if [[ "$cmd" == "rm" ]]; then
    local profile="${2-}" type="${3-}" name="${4-}"
    if [[ -z "$profile" || -z "$type" || -z "$name" ]]; then
      _wt_usage
      return 1
    fi

    local delete_branch=0
    if [[ "${5-}" == "--branch" ]]; then
      delete_branch=1
    elif [[ -n "${5-}" ]]; then
      print -u2 -- "Unknown option for rm: ${5-}"
      _wt_usage
      return 1
    fi

    local repo_root
    repo_root="$(_wt_repo_root_for_profile "$profile")" || {
      print -u2 -- "Unknown profile: $profile"
      print -u2 -- "Known profiles:"
      _wt_profiles | sed 's/^/  /' >&2
      return 1
    }

    local main="$repo_root/main"
    local dir="$repo_root/wt/$type/$name"
    local branch="$type/$name"

    _wt_need_main_checkout "$main" || return 1

    # Remove worktree safely (also removes git metadata)
    if [[ ! -d "$dir" ]]; then
      print -u2 -- "Worktree directory does not exist: $dir"
      # Still worth pruning stale metadata, in case it was rm -rf'd earlier
      command git -C "$main" worktree prune >/dev/null 2>&1 || true
    else
      local remove_output
      if ! remove_output=$(command git -C "$main" worktree remove "$dir" 2>&1); then
        if [[ "$remove_output" == *"contains modified or untracked files"* ]]; then
          print -u2 -- "$remove_output"
          print -n "Force delete anyway? [y/N] "
          local reply
          read -r reply
          if [[ "$reply" == [yY] ]]; then
            command git -C "$main" worktree remove --force "$dir" || return 1
          else
            return 1
          fi
        else
          print -u2 -- "$remove_output"
          return 1
        fi
      fi
      command git -C "$main" worktree prune >/dev/null 2>&1 || true
    fi

    # Optionally delete branch (safe delete; will fail if unmerged or checked out elsewhere)
    if (( delete_branch )); then
      # Use -d (not -D) to avoid deleting unmerged work accidentally
      command git -C "$main" branch -d "$branch"
    fi

    print -r -- "🗑️ removed worktree: $dir"
    (( delete_branch )) && print -r -- "🧹 attempted branch delete: $branch"
    return 0
  fi

  # Default behavior: create worktree and cd into it
  local profile="$1" type="$2" name="$3"
  if [[ -z "$profile" || -z "$type" || -z "$name" ]]; then
    _wt_usage
    return 1
  fi

  shift 3
  local -a extra_args
  extra_args=()
  if [[ "${1-}" == "--" ]]; then
    shift
    extra_args=("$@")
  fi

  local repo_root
  repo_root="$(_wt_repo_root_for_profile "$profile")" || {
    print -u2 -- "Unknown profile: $profile"
    print -u2 -- "Known profiles:"
    _wt_profiles | sed 's/^/  /' >&2
    return 1
  }

  local main="$repo_root/main"
  local dir="$repo_root/wt/$type/$name"
  local branch="$type/$name"

  _wt_need_main_checkout "$main" || return 1

  builtin cd "$main" || return 1
  command git worktree add "$dir" -b "$branch" "${extra_args[@]}" || return 1
  builtin cd "$dir" || return 1

  print -r -- "✅ worktree: $dir"
}

# -------- Completion (basic but practical) --------
# Completes:
#  - first token: subcommands (ls, rm), --profiles, or profile names
#  - if 'ls': completes profile
#  - if 'rm': completes profile, type, then name (name is freeform)
#  - otherwise: completes profile, type, then name (name is freeform)

# ---- Completion for wt (focus on: wt rm) ----

_wt_profiles_comp() {
  local config="${WT_CONFIG:-$HOME/.config/wt/profiles}"
  local -a profiles
  profiles=()

  if [[ -r "$config" ]]; then
    local line key
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ "$line" == \#* ]] && continue
      [[ -z "${line//[[:space:]]/}" ]] && continue
      key="${line%%=*}"
      key="${key#"${key%%[![:space:]]*}"}"
      key="${key%"${key##*[![:space:]]}"}"
      [[ -n "$key" ]] && profiles+="$key"
    done < "$config"
  fi

  _describe 'profile' profiles
}

_wt_repo_root_for_profile_comp() {
  local profile="$1"
  local config="${WT_CONFIG:-$HOME/.config/wt/profiles}"
  [[ -r "$config" ]] || return 1

  local line key val
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == \#* ]] && continue
    [[ -z "${line//[[:space:]]/}" ]] && continue
    key="${line%%=*}"
    val="${line#*=}"
    key="${key#"${key%%[![:space:]]*}"}"; key="${key%"${key##*[![:space:]]}"}"
    val="${val#"${val%%[![:space:]]*}"}"; val="${val%"${val##*[![:space:]]}"}"
    if [[ "$key" == "$profile" ]]; then
      # zsh-native tilde expansion
      print -r -- ${~val}
      return 0
    fi
  done < "$config"
  return 1
}

_wt_worktree_names_comp() {
  local profile="$1"
  local type="$2"

  local repo_root="$(_wt_repo_root_for_profile_comp "$profile")" || return 1
  local base="$repo_root/wt/$type"
  [[ -d "$base" ]] || { _message "no worktrees under $base"; return 0; }

  local -a names
  names=()
  local d
  for d in "$base"/*; do
    [[ -d "$d" ]] || continue
    names+=("${d:t}")
  done

  # Present as choices
  _describe 'worktree' names
}

_wt() {
  local -a types subcmds
  types=(fix feature chore exp spike)
  subcmds=(ls cd rm)

  # words[1] = wt
  local w2="${words[2]-}"

  # First arg: subcommand or profile (create-mode)
  if (( CURRENT == 2 )); then
    _describe 'subcommand' subcmds
    _wt_profiles_comp
    return
  fi

  # wt rm <profile> <type> <name> [--branch]
  if [[ "$w2" == "rm" ]]; then
    if (( CURRENT == 3 )); then
      _wt_profiles_comp
      return
    fi
    if (( CURRENT == 4 )); then
      _describe 'type' types
      return
    fi
    if (( CURRENT == 5 )); then
      local profile="${words[3]}"
      local type="${words[4]}"
      _wt_worktree_names_comp "$profile" "$type"
      return
    fi
    if (( CURRENT == 6 )); then
      compadd -- --branch
      return
    fi
    return
  fi

  # wt ls [profile]
  if [[ "$w2" == "ls" ]]; then
    if (( CURRENT == 3 )); then
      _wt_profiles_comp
      return
    fi
    return
  fi

  # wt cd <profile> <type> <name>
  if [[ "$w2" == "cd" ]]; then
    if (( CURRENT == 3 )); then
      _wt_profiles_comp
      return
    fi
    if (( CURRENT == 4 )); then
      _describe 'type' types
      return
    fi
    if (( CURRENT == 5 )); then
      local profile="${words[3]}"
      local type="${words[4]}"
      _wt_worktree_names_comp "$profile" "$type"
      return
    fi
    return
  fi

  # Default create: wt <profile> <type> <name>
  if (( CURRENT == 2 )); then
    _wt_profiles_comp
    return
  fi
  if (( CURRENT == 3 )); then
    _describe 'type' types
    return
  fi
  if (( CURRENT == 4 )); then
    _message 'enter worktree name'
    return
  fi
}
compdef _wt wt