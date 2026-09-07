#!/usr/bin/env bash
# Install Live Sports into the Omarchy shell.
#
#   ./install.sh              copy into ~/.config/omarchy/plugins
#   ./install.sh --link       symlink for development
#   ./install.sh --remove     uninstall
#   ./install.sh --keep-data  with --remove, keep cache and state

set -euo pipefail

id="io.github.marty-schneider.live-sports"
source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/$id"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/omarchy/live-sports"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/live-sports"
mode="copy"
keep_data="no"

for arg in "$@"; do
  case "$arg" in
  --link) mode="link" ;;
  --remove) mode="remove" ;;
  --keep-data) keep_data="yes" ;;
  -h | --help)
    sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
    exit 0
    ;;
  *)
    echo "unknown option: $arg" >&2
    exit 1
    ;;
  esac
done

rescan() {
  if command -v omarchy-shell >/dev/null 2>&1 && omarchy-shell shell ping >/dev/null 2>&1; then
    omarchy-shell shell rescanPlugins >/dev/null
    echo "shell rescanned"
  else
    echo "shell not running — it will pick the plugin up on next start"
  fi
}

if [[ $mode == remove ]]; then
  rm -rf "$target_dir"
  echo "removed $target_dir"
  if [[ $keep_data != yes ]]; then
    rm -rf "$cache_dir" "$state_dir"
  fi
  rescan
  exit 0
fi

mkdir -p "$(dirname "$target_dir")"
rm -rf "$target_dir"

if [[ $mode == link ]]; then
  ln -s "$source_dir" "$target_dir"
  echo "linked $target_dir -> $source_dir"
else
  mkdir -p "$target_dir"
  cp "$source_dir/manifest.json" "$target_dir/"
  cp "$source_dir"/*.qml "$target_dir/"
  cp "$source_dir"/*.js "$target_dir/"
  echo "installed $target_dir"
fi

rescan

cat <<EOF

Next:
  omarchy plugin enable $id
  omarchy bar move $id --section left
EOF
