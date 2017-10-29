# First, ensure we're in tmux so that we get into tmux as soon as possible
# instead of doing it after everything else loads.
# tmux {{{
# Ensure we're always in a tmux session
ensure_we_are_inside_tmux() {
  if _not_in_tmux; then
    _ensure_tmux_is_running
    tmux attach -t "$(_most_recent_tmux_session)"
  fi
}

# Returns the name of the most recent tmux session, sorted by time the session
# was last attached.
_most_recent_tmux_session(){
  tmux list-sessions -F "#{session_last_attached} #{session_name}" | \
    sort -r | \
    cut -d' ' -f2 | \
    head -1
}

_not_in_tmux() {
  [[ -z "$TMUX" ]]
}

_no_tmux_sessions() {
  [[ -z "$(tmux ls)" ]]
}

_ensure_tmux_is_running() {
  if _no_tmux_sessions; then
    # Daemonize so it doesn't auto-open the session. We just want something that
    # `tmux attach` can use.
    tmux new -d
  fi
}

inside_ssh(){
  [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]
}

if ! inside_ssh; then
  ensure_we_are_inside_tmux
fi
# }}}

# Aliases {{{
alias q="vim ~/.zshrc"
alias qq="cd . && source ~/.zshrc"
alias cp="cp -iv"
alias rm="rm -iv"
alias mv="mv -iv"
alias ls="ls -FGh"
alias du="du -cksh"
alias df="df -h"
# Use modern regexps for sed, i.e. "(one|two)", not "\(one\|two\)"
alias sed="sed -E"
# Just print request/response headers, ignoring ~/.curlrc
alias curl-debug="command curl --disable -vsSo /dev/null -H Fastly-debug:1"
# Search for the string anywhere in the command name, not just in the executable
alias pgrep='command pgrep -f'
# Use modern regexps for grep, and do show color when `grep` is the final
# command, but don't when piping to something else, because the added color
# codes will mess up the expected input.
alias grep="egrep --color=auto"
# dup = "dotfiles update"
alias dup="pushd dotfiles && git checkout master && git pull && git checkout - && popd && qq"
# Copy-pasting `$ python something.py` works
alias \$=''
alias diff="command diff --color=auto -u"
alias mkdir="command mkdir -p"
alias serialnumber="ioreg -l | grep IOPlatformSerialNumber | cut -d= -f2 | sed 's/[ \"]//g'"
alias prettyjson="jq ."
# xmllint is from `brew install libxml2`
alias prettyxml="xmllint --format -"
# Make images smaller
alias pngcrush=/Applications/ImageOptim.app/Contents/MacOS/ImageOptim
# Remove EXIF data
alias exif-remove="exiftool -all= "
alias youtube-dl-safe="youtube-dl --no-mtime --no-overwrites"
y-fallback(){
  youtube-dl-safe \
    --ignore-errors \
    --external-downloader curl \
    "${@:-"$(pbpaste)"}"
}
y(){ youtube-dl-safe --ignore-errors "${@:-"$(pbpaste)"}" }
# Pipe to this to quote filenames with spaces
alias quote="sed \"s/^[^'].*/'&'/\""
# Files created today
alias today="days 0"
# Created in last n days
days(){
  local query="kMDItemFSCreationDate>\$time.today(-$1) && kMDItemContentType != public.folder"
  mdfind -onlyin . "$query" | quote
}
alias epoch="date -r"
alias rg="command rg --max-columns 200"
alias rcup="command rcup -v | grep -v identical"
it(){ icopy -t tumblr/"${*// /-}" }
tcd(){ (cd "$1" && t "$1") }
vdot(){ vim "$@" }
alias xo='quote | xargs open'
alias trust='mkdir -p .git/safe'

o(){
  if [ -d "$1" ]; then
    if [[ -n "$(find "$1" -maxdepth 1 -name '*.mp4' -print -quit)" ]]; then
      open "$1"/*
    else
      open -a Preview "$1"
    fi
  else
    if [[ $# == 0 ]]; then
      open *.*
    else
      open "$@"
    fi
  fi
}
# Get rid of Messages.app's fake unread message badge
unfuck-messages(){ killall Dock }
# The `-g` flag means "global", and means that it can go anywhere in a command
# line and it will be preprocessed in, unlike "regular" aliases.
alias -g G="| grep "
alias -g ONE="| awk '{ print \$1}'"

run-until-succeeds(){ until "$@"; do; sleep 1; done }
announce(){ $@ ; spotify pause && say "Done!" && spotify play }

# `-` by itself will act like `cd -`. Needs to be a function because `alias -`
# breaks.
function -() { cd - }

# Psh, "no nodename or servname not provided". I'll do `whois
# http://google.com/hello` if I want.
whois() {
  command whois $(echo "$1" | sed -E -e 's|^https?://||' -e 's|/.*$||g')
}

al() { ls -tU | head -n ${1:-10}; }

# If piping something in, copy it.
# If just doing `clip`, paste it.
clip() { [ -t 0 ] && pbpaste || pbcopy;}

[[ -r ~/.aliases ]] && source ~/.aliases
# }}}

# Options {{{
HISTFILE=~/.zsh_history
HISTSIZE=1000000000000000000
SAVEHIST=$HISTSIZE
setopt no_list_beep
setopt no_beep
# Append as you type (incrementally) instead of on shell exit
setopt inc_append_history
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt autocd
setopt autopushd
# Timestamp history entries
setopt extended_history

unsetopt correctall
# Allow [ or ] wherever you want
# (Prevents "zsh: no matches found: ...")
unsetopt nomatch

# https://github.com/gabebw/dotfiles/pull/15
unsetopt multios

# i - Vim's smart case
# j.5 - Center search results
# F - Quit if the content is <1 screen
# K - Quit on CTRL-C
# M - Longer prompt
# R - handle ASCII color escapes
# X - Don't send clear screen signal
export LESS="ij.5FKMRX"

# Show grep results in white text on a red background
export GREP_COLOR='1;37;41'

# Note that these FZF options are used by fzf.vim automatically! Yay!
# Use a separate tool to smartly ignore files
export FZF_DEFAULT_COMMAND='rg --hidden --files --ignore-file ~/.ignore'
# Jellybeans theme: https://github.com/junegunn/fzf/wiki/Color-schemes
export FZF_DEFAULT_OPTS='--color fg:188,bg:233,hl:103,fg+:222,bg+:234,hl+:104
--color info:183,prompt:110,spinner:107,pointer:167,marker:215
--bind ctrl-u:page-up,ctrl-f:page-down
'
# }}}

# $PATH {{{

is_osx(){
  [ "$(uname -s)" = Darwin ]
}

if is_osx; then
  # Add Homebrew to the path. This must be above rbenv path stuff.
  PATH=/usr/local/bin:/usr/local/sbin:$PATH
fi

# Heroku standalone client
PATH="/usr/local/heroku/bin:$PATH"

# Node
PATH=$PATH:/usr/local/share/npm/bin:.git/safe/../../node_modules/.bin/
# NVM
mkdir -p ~/.nvm
export NVM_DIR="$HOME/.nvm"
nvm_sh="/usr/local/opt/nvm/nvm.sh"
[[ -r "$nvm_sh" ]] && . "$nvm_sh"
unset nvm_sh

# Postgres.app
PATH=$PATH:/Applications/Postgres.app/Contents/Versions/latest/bin

# Haskell
PATH=~/.local/bin:$PATH

PATH=$HOME/.bin:$PATH

PATH=./bin/stubs:$PATH

# }}}

# Completion {{{
# http://zsh.sourceforge.net/Doc/Release/Completion-System.html
# zmodload -i zsh/complist
fpath=(~/.zsh/completion-scripts /usr/local/share/zsh/site-functions $fpath)
autoload -U compinit && compinit
# Now zsh understands bash completion files. Wild!
autoload -U bashcompinit && bashcompinit

# Try to match as-is then match case-insensitively
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Automatically recognize and complete commands that have been installed since
# the last time the zshrc was sourced.
# https://wiki.voidlinux.eu/Zsh#Persistent_rehash
zstyle ':completion:*' rehash true

# When you paste a <Tab>, don't try to auto-complete
zstyle ':completion:*' insert-tab pending

# Show a menu (with arrow keys) to select the process to kill.
# To filter, type `kill vi<TAB>` and it will select only processes whose name
# contains the substring `vi`.
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*'   force-list always

# When doing `cd ../<TAB>`, don't offer the current directory as an option.
# For example, if you're in foo, then `cd ../f` won't show `cd ../foo` as an
# option.
zstyle ':completion:*:cd:*' ignore-parents parent pwd

# Colorful lists of possible autocompletions for `ls`
# zstyle doesn't understand the BSD-style $LSCOLORS at all, so use Linux-style
# $LS_COLORS
zstyle ':completion:*:ls:*:*' list-colors 'di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

# Complete the command on the left like the command on the right
compdef tcd=cd
compdef viw=which
compdef staging=heroku
compdef production=heroku
_vdot(){
  # -P = "prefix", so it knows to add that if you don't type it
  compadd -P /Users/gabe/. $(ls -d ~/.* | sed -E "s|/Users/gabe/\.||g")
}
compdef _vdot vdot
# }}}

# Key bindings {{{
# Vim-style line editing
# This sets up a bunch of bindings, so call this first and then call all
# other `bindkey`s after it to override anything you like.
bindkey -v

# Open current command in Vim
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^v" edit-command-line

# Copy the most recent command to the clipboard
_pbcopy_last_command(){
  fc -ln -1 | pbcopy && \
    tmux display-message "Previous command copied to clipboard"
}
zle -N pbcopy-last-command _pbcopy_last_command
bindkey '^x^x' pbcopy-last-command

# Fuzzy match against history, edit selected value
# For exact match, start the query with a single quote: 'curl
fuzzy-history() {
  selected=$(fc -l 1 | sed 's/^ *[0-9]* *//' | fzf --tac --reverse --no-sort)
  print -z "$selected"
}

# Ctrl-r triggers fuzzy history search
bindkey -M viins -s '^r' 'fuzzy-history\n'

# https://coderwall.com/p/jpj_6q
# Search through history for previous commands matching everything up to current
# cursor position. Move the cursor to the end of line after each match.
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down
# }}}

# cdpath {{{
has_subdirs(){
  if [[ -d "$1" ]]; then
    [[ "$(find "$1" -type d -maxdepth 0 -empty -exec echo -n empty \;)" != "empty" ]]
  else
    return 1
  fi
}

add_dir_to_cdpath(){
  if [ -d "$1" ]; then
    # Use lowercase `cdpath` because uppercase `CDPATH` can't be set to an array
    cdpath+=("$1")
  fi
}

add_subdirs_to_cdpath(){
  if has_subdirs "$1"; then
    for subdir in "$1"/*; do
      cdpath+=("$subdir")
    done
  fi
}

add_dir_to_cdpath "$HOME/code"
add_subdirs_to_cdpath "$HOME/code"
add_subdirs_to_cdpath "$HOME/code/thoughtbot"

# Exporting $CDPATH is bad:
# https://bosker.wordpress.com/2012/02/12/bash-scripters-beware-of-the-cdpath/
# So, export PROJECT_DIRECTORIES instead, but set it to $CDPATH
export PROJECT_DIRECTORIES=$CDPATH
# }}}

# asdf version manager (ruby, node, etc)
# I truly do not want to deal with the hassle of GPG, so don't fail to install
# when GPG isn't set up.
export NODEJS_CHECK_SIGNATURES=no
[[ -r /usr/local/opt/asdf/asdf.sh ]] && source /usr/local/opt/asdf/asdf.sh
. /usr/local/etc/bash_completion.d/asdf.bash

# Prompt {{{

# Prompt colors {{{
#-------------------

# This is just to get $reset_color, since we generate $fg and $bg ourselves.
autoload colors && colors

# Generate colors for all 256 colors
typeset -AHg fg

for color in {000..255}; do
  fg[$color]="%{[38;5;${color}m%}"
done

prompt_color() {
  [[ -n "$1" ]] && print "%{$fg[$2]%}$1%{$reset_color%}"
}

prompt_green()  { print "$(prompt_color "$1" 158)" }
prompt_magenta(){ print "$(prompt_color "$1" 218)" }
prompt_purple() { print "$(prompt_color "$1" 146)" }
prompt_red()    { print "$(prompt_color "$1" 197)" }
prompt_cyan()   { print "$(prompt_color "$1" 159)" }
prompt_blue()   { print "$(prompt_color "$1" 031)" }
prompt_yellow() { print "$(prompt_color "$1" 222)" }
prompt_spaced() { [[ -n "$1" ]] && print " $@" }
# }}}

# Helper functions: path and Ruby version {{{
#--------------------------------------------
# %2~ means "show the last two components of the path, and show the home
# directory as ~".
#
# Examples:
#
# ~/foo/bar is shown as "foo/bar"
# ~/foo is shown as ~/foo (not /Users/gabe/foo)
prompt_shortened_path() { print "$(prompt_purple "%2~")" }

prompt_unstyled_short_ruby_version(){
  # "version 2.4.2 is not installed for ruby" -> "2.4.2 (missing)"
  asdf current ruby | \
    sed -E \
      -e 's/version (.+) is not installed/\1 (missing)/g' \
      -e 's/No version set for ruby/[None set]/g' \
      -e 's/^(.+) \(set by .+\)/\1/g'
}

prompt_ruby_version() {
  prompt_magenta "$(prompt_unstyled_short_ruby_version)"
}
# }}}

# Git-related prompt stuff {{{
#-----------------------------

# vcs_info docs: http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#Version-Control-Information
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*' formats $(prompt_blue "%b")
zstyle ':vcs_info:git*' actionformats $(prompt_red "%b|%a")

prompt_git_status_symbol(){
  local symbol
  local clean=$(prompt_green ✔)
  local dirty=$(prompt_red ✘)
  local untracked=$(prompt_cyan '?')
  local staged=$(prompt_yellow ⭑)

  case $(prompt_git_status) in
    changed) symbol=$dirty;;
    staged) symbol=$staged;;
    untracked) symbol=$untracked;;
    unchanged) symbol=$clean;;
  esac

  print "$symbol"
}

# Is this branch ahead/behind its remote tracking branch?
prompt_git_relative_branch_status_symbol(){
  local symbol;
  local downwards_arrow=$(prompt_cyan ↓)
  local upwards_arrow=$(prompt_cyan ↑)
  local sideways_arrow=$(prompt_red ⇔)
  local good=$(prompt_green ✔)
  local question_mark=$(prompt_yellow \?)

  case $(prompt_git_relative_branch_status) in
    not_tracking) symbol=$question_mark ;;
    up_to_date) symbol=$good ;;
    ahead_behind) symbol=$sideways_arrow ;;
    behind) symbol=$downwards_arrow ;;
    ahead) symbol=$upwards_arrow ;;
  esac

  prompt_spaced "$symbol"
}

prompt_git_status() {
  local git_status="$(cat "/tmp/git-status-$$")"
  if print "$git_status" | command grep -qF "Changes not staged" ; then
    print "changed"
  elif print "$git_status" | command grep -qF "Changes to be committed"; then
    print "staged"
  elif print "$git_status" | command grep -qF "Untracked files"; then
    print "untracked"
  elif print "$git_status" | command grep -qF "working tree clean"; then
    print "unchanged"
  fi
}

prompt_git_relative_branch_status(){
  local git_status="$(cat "/tmp/git-status-$$")"
  local branch_name=$(git rev-parse --abbrev-ref HEAD)

  if ! git config --get "branch.${branch_name}.merge" > /dev/null; then
    print "not_tracking"
  elif print "$git_status" | command grep -qF "up-to-date"; then
    print "up_to_date"
  elif print "$git_status" | command grep -qF "have diverged"; then
    print "ahead_behind"
  elif print "$git_status" | command grep -qF "Your branch is behind"; then
    print "behind"
  elif print "$git_status" | command grep -qF "Your branch is ahead"; then
    print "ahead"
  fi
}

prompt_git_branch() {
  # vcs_info_msg_0_ is set by the `zstyle vcs_info` directives
  # It is the colored branch name.
  print "$vcs_info_msg_0_"
}

# This shows everything about the current git branch:
# * branch name
# * check mark/x mark/letter etc depending on whether branch is dirty, clean,
#   has staged changes, etc
# * Up arrow if local branch is ahead of remote branch, or down arrow if local
#   branch is behind remote branch
prompt_full_git_status(){
  if [[ -n "$vcs_info_msg_0_" ]]; then
    prompt_spaced "$(prompt_git_branch) $(prompt_git_status_symbol)$(prompt_git_relative_branch_status_symbol)"
  fi
}

# `precmd` is a magic function that's run right before the prompt is evaluated
# on each line.
# Here, it's used to capture the git status to show in the prompt.
function precmd {
  vcs_info
  git status 2> /dev/null >! "/tmp/git-status-$$"
}

# Do I have a custom git email set for this git repo? Announce it so I remember
# to unset it.
prompt_git_email(){
  git_email=$(git config user.email)
  global_git_email=$(git config --global user.email)
  git_name=$(git config user.name)
  global_git_name=$(git config --global user.name)
  x=""

  if [[ "$git_email" != "$global_git_email" ]]; then
    x=" $(prompt_red "[git email: $git_email]")"
  fi

  if [[ "$git_name" != "$global_git_name" ]]; then
    x="${x} $(prompt_red "[git name: $git_name]")"
  fi
  print "$x"
}
# }}}

# prompt_subst allows `$(function)` inside the PROMPT
# Escape the `$()` like `\$()` so it's not immediately evaluated when this file
# is sourced but is evaluated every time we need the prompt.
setopt prompt_subst

PROMPT='$(prompt_ruby_version) $(prompt_shortened_path)$(prompt_git_email)$(prompt_full_git_status) $ '
# }}}

# Git {{{

# By itself: run `git status`
# With arguments: acts like `git`
function g {
  if [[ $# > 0 ]]; then
    git "$@"
  else
    git st
  fi
}

alias gd="git diff"
# Grep with grouped output like Ack
alias gg="git g"
alias amend="git commit --amend -Chead"
alias amend-new="git commit --amend"

alias ga="git add"
alias gai="git add --interactive"
alias gcp="git rev-parse HEAD | xargs echo -n | pbcopy"
gc(){
  if [[ $# == 0 ]]; then
    local branch=$(git branch -a |\
      grep -v HEAD |\
      sed -E -e 's|remotes/[a-z]+/||' -e 's/^\*?[ \t]*//' |\
      sort -u |\
      fzf --reverse --ansi --tac)
    [[ -n "$branch" ]] && git checkout "$branch" || true
  else
    git checkout "$@"
  fi
}
alias gcm="git commit -m"

# Checkout branches starting with my initials
function gb(){
  if [[ $# == 0 ]]; then
    echo "No branch name :(" >&2
    return 1
  fi
  branch="gbw-${1#gbw-}"
  base=$2
  if [[ -n "$base" ]]; then
    git checkout -b "$branch" "$base"
  else
    git checkout -b "$branch"
  fi
}
function gbm(){ gb "$1" origin/master }
function gbi(){ gbm "IXP-$1" }

function gcl {
  local directory="$(superclone "$@")"
  cd "$directory"
}

# Complete `g` like `git`, etc
compdef g=git
compdef _git gc=git-checkout
compdef _git ga=git-add
# }}}

# Docker {{{
docker-kickstart(){
  echo "Run Docker for Mac: https://www.docker.com/docker-mac"
}
# }}}

# Editor {{{
# Why set $VISUAL instead of $EDITOR?
# http://robots.thoughtbot.com/visual-ize-the-future
export VISUAL=vim
alias vi="$VISUAL"
alias v="$VISUAL"

# Remove vim flags for crontab -e
alias crontab="VISUAL=vim crontab"
# }}}

# Go {{{
export GOPATH=$HOME/.go
PATH=$PATH:$GOPATH/bin
# }}}

# Python {{{
export PYTHONSTARTUP=~/.pythonstartup

# Tell Virtualenv to store its data in ~/.virtualenvs
if [ -x /usr/local/bin/virtualenvwrapper.sh ]; then
  export VIRTUALENVWRAPPER_PYTHON=`which python2`
  export WORKON_HOME=~/.virtualenvs

  mkvirtualenv(){
    source /usr/local/bin/virtualenvwrapper.sh
    mkvirtualenv "$@"
  }

  workon(){
    source /usr/local/bin/virtualenvwrapper.sh
    workon "$@"
  }
fi
# }}}

# Haskell {{{
PATH="./.git/safe/../../.cabal-sandbox/bin:$HOME/.cabal/bin:$PATH"

command -v stack > /dev/null && eval "$(stack --bash-completion-script stack)"

new-yesod-project() {
  name=$1
  stack new "$1" yesod-postgres
  cd "$1"
  stack install yesod-bin cabal-install --install-ghc && \
    stack build && \
    echo "Run the server: stack exec -- yesod devel"
}
# }}}

# Ruby/Rails {{{

alias h=heroku
alias hsso="heroku login --sso"
alias migrate="be rake db:migrate db:test:prepare"
alias rollback="be rake db:rollback"
alias remigrate="migrate db:rollback && be rake db:migrate db:test:prepare"
alias rrg="be rake routes | grep"
alias db-reset="DISABLE_DATABASE_ENVIRONMENT_CHECK=1 be rake db:drop db:create db:migrate db:test:prepare"
alias f=start_foreman_on_unused_port
alias unfuck-gemfile="git checkout HEAD -- Gemfile.lock"

export RUBYOPT=rubygems

# Bundler
alias be="bundle exec"

alias tagit='/usr/local/bin/ctags -R'

b(){
  if [[ $# == 0 ]]; then
    (bundle check > /dev/null || bundle install) && \
      bundle --quiet --binstubs=./bin/stubs
  else
    bundle "$@"
  fi
}

# Install capybara-webkit linked against Qt5.5
capy5() {
  brew install --force qt@5.5 && \
    gem uninstall -a capybara-webkit && \
    brew unlink qt@5.5 && \
    brew link --force --overwrite qt@5.5 && \
    b
}
# }}}

# Postgres {{{
# Set filetype on editing. Use `\e` to open the editor from `psql`.
export PSQL_EDITOR="vim -c ':set ft=sql'"

# db-dump DB_NAME FILENAME
function db-dump() {
  if (( $# == 2 )); then
    pg_dump --clean --create --format=custom --file "$2" "$1" && \
      echo "Wrote to $2"
  else
    echo "Usage: db-dump DB_NAME FILENAME"
    return 1
  fi
}

# db-restore DB_NAME FILENAME
function db-restore() {
  if (( $# == 2 )); then
    dropdb "$1" && \
      createdb "$1" && \
      pg_restore \
        --verbose \
        --clean \
        --no-acl \
        --no-owner \
        --jobs `getconf _NPROCESSORS_ONLN` \
        --dbname "$1" \
        "$2"
  else
    echo "Usage: db-restore DB_NAME FILENAME"
    return 1
  fi
}

# This file sticks around when postgres force-quits. Postgres reads it and
# thinks it's running but it's not.
alias unfuck-postgres="rm -f /usr/local/var/postgres/postmaster.pid && brew services restart postgres"
# }}}

# Homebrew {{{
if is_osx; then
  # Opt out of sending Homebrew information to Google Analytics
  # https://github.com/Homebrew/brew/blob/master/share/doc/homebrew/Analytics.md
  export HOMEBREW_NO_ANALYTICS=1
fi
# }}}

# Processing {{{
# Create a new (Java) processing sketch
processing-new(){
  if [[ -d "$1" ]]; then
    echo "Already exists"
    return 1
  fi

  if [[ "$1" == *.* ]]; then
    echo "No dots allowed in the name"
    return 1
  fi

  mkdir "$1"
  cat >> "$1/$1.pde" <<EOF
void setup() {
  size(640,360);
}

void draw() {
  background(255);
}
EOF
  vim "$1/$1.pde"
}
# }}}

# zsh-syntax-highlighting must be sourced after all custom widgets have been
# created (i.e., after all zle -N calls and after running compinit), because it
# has to know about them to highlight them.
source ~/.zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# `print_exit_value` shows a message with the exit code when a command returns
# with a non-zero exit code.
# However, zsh-syntax-highlighting somehow unsets this options option, so we
# must set it after sourcing zsh-syntax-highlighting.
setopt print_exit_value
