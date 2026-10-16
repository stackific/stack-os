#!/usr/bin/env bash
# Block any git push that targets main, in whichever repo the push runs:
# explicit `main`, `HEAD` while on main, or a bare `git push` while on main.
input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
# `git [global opts] push <args>` up to the next command separator or newline.
is_push=$'(^|[;&|(\n[:space:]])git([[:space:]]+(-[Cc][[:space:]]+[^[:space:]]+|-[^[:space:]]+))*[[:space:]]+push([^;&|\n]*)'
names_main='(^|[[:space:]:+])(refs/heads/)?main([[:space:]:]|$)'
names_head='(^|[[:space:]+])HEAD([[:space:]:]|$)'
has_refspec='^([[:space:]]+-[^[:space:]]+)*[[:space:]]+[^-[:space:]][^[:space:]]*[[:space:]]+[^-[:space:]]'
git_dir_opt='-C[[:space:]]+([^[:space:]]+)'
cd_to=$'(^|[;&|(\n[:space:]])cd[[:space:]]+([^;&|\n[:space:])]+)'

[[ $cmd =~ $is_push ]] || exit 0
push=${BASH_REMATCH[0]}
args=${BASH_REMATCH[4]}

# The repo the push runs in: `git -C <dir>`, else the last `cd <dir>` before it, else the session's cwd.
dir=${cwd:-$CLAUDE_PROJECT_DIR}
before=${cmd%%"$push"*}
while [[ $before =~ $cd_to ]]; do
  target=${BASH_REMATCH[2]}
  [[ $target == /* || $target == "~"* ]] || target=$dir/$target
  dir=$target
  before=${before#*"${BASH_REMATCH[0]}"}
done
if [[ $push =~ $git_dir_opt ]]; then
  target=${BASH_REMATCH[1]}
  [[ $target == /* || $target == "~"* ]] || target=$dir/$target
  dir=$target
fi
dir=${dir/#\~/$HOME}

branch=$(git -C "$dir" branch --show-current 2>/dev/null)
if [[ $args =~ $names_main ]] ||
  { [[ $branch == main ]] && { [[ $args =~ $names_head ]] || ! [[ $args =~ $has_refspec ]]; }; }; then
  echo "Pushing to main is blocked. Push a feature branch and open a PR." >&2
  exit 2
fi
