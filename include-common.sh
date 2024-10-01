
#
#Copyright 2024 Frank Stutz.
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
#

###########################
# Declarations 
###########################
if [[ "$SHELL" =~ zsh ]] ; then
  SHELL_TYPE_DECLARE_PARAM="-g"
else
  unset SHELL_TYPE_DECLARE_PARAM
fi
unset SHELL_TYPE_DECLARE_PARAM

# functions that should be "exported"
DECLARE_FNS="LOGTFMT init bcheck color mlog cecho secho isSourced compareSemanticVersions nullify nullerr secho exitnow"
for x in $DECLARE_FNS ; do
  if ! typeset -f "$x" >/dev/null 2>&1; then 
    # shellcheck disable=SC2086
    declare $SHELL_TYPE_DECLARE_PARAM -f $x
  fi
done

###########################
# Functions
###########################
function nullify {
  "$@" >&/dev/null
}

function nullerr {
  "$@" 2>/dev/null
}

function init {
  [[ -n "$BUILD_DEBUG" ]] && set -x
  trap "set +x" HUP INT QUIT TERM EXIT
  # shellcheck disable=SC2086
  declare $SHELL_TYPE_DECLARE_PARAM -x DATELOG ABSPATH BASEDIR APPNAME

  DATELOG=true

  # shellcheck disable=SC2164
  _COMMON_ABSPATH="$(
    cd "${0%/*}" 2>/dev/null
    echo "$PWD"/"${0##*/}"
  )"

  _COMMON_BASEDIR="$(dirname "$_COMMON_ABSPATH")"
  _COMMON_NAME="$(basename "$_COMMON_ABSPATH")"

  unset BASH_FLAG
  unset ZSH_FLAG
  if [ -n "$BASH_VERSION" ] || [[ "$SHELL" =~ bash ]] ; then
    export BASH_FLAG=true
    export ZSH_FLAG=false
  elif [ -n "$ZSH_VERSION" ] || [[ "$SHELL" =~ zsh ]] ; then
    # shellcheck disable=SC2086
    declare -g -x ZSH_FLAG=true
    # shellcheck disable=SC2086
    declare -g -x BASH_FLAG=false
  else
    echo "ERROR:${0} only works for Bash and ZSH"
    return 1
  fi
}

function exitnow {
  declare NUM=$1 ; shift
  declare ERRMSG="$*"

  [[ -n "$ERRMSG" ]] && echo "$ERRMSG" >&2
  if [ -n "$NUM" ] ; then
    case $NUM in
    ''|*[!0-9]*)
      # default to 1 even if not passed an integer
      declare -i EXIT_NUM=1
    ;;
    *)
      declare -i EXIT_NUM=$NUM
    ;;
    esac
    type -a mlog >/dev/null 2>&1 && mlog DEBUG "Exit code is $NUM"
    exit $EXIT_NUM
  fi

  exit 0
}


function isSourced {
  [[ ! "$0" =~ include-common ]] && return
  if [ -n "$ZSH_VERSION" ]; then
    case $ZSH_EVAL_CONTEXT in *:file:*) return 0 ;; esac
  else # Add additional POSIX-compatible shell names here, if needed.
    case ${0##*/} in dash | -dash | bash | -bash | ksh | -ksh | sh | -sh) return 0 ;; esac
  fi
  return 1 # NOT sourced.
}

# little function to mimic boolean checks if user did not properly set 0/false or 1/true
# NOTE: return of 1 is false, return 0 is true (not related to value of variable)
function bcheck {
  local out='' var=''

  [[ -z "$1" ]] && echo "Usage:bcheck <variable> (without \$)" && return 2
  # if variable is not defined automatically false
  out=$(declare -p "$1" 2>&1) || return 1 # Not defined automatic false

  var="$(echo "${out}" | tr '[:upper:]' '[:lower:]' | cut -d= -f2- | tr -d \")"
  [[ "$var" =~ ^(true|1)$ ]] && return 0

  # everything else is considered false (thus name=asdf, name=111 , etc)
  # (should use -z or -n instead of a boolean - bcheck then)
  return 1
}

function LOGTFMT {
  if [ -n "$ZSH_VERSION" ]; then
    print -rP "%D{%FT%T.%6.%z}"
  elif [ -n "$BASH_VERSION" ]; then
    t=$EPOCHREALTIME
    printf "%(%FT%T)T.${t#*.}%(%z)T\n" "${t%.*}"
  else
    # Using internal date (which might not be GNU version - but good enough)
    date +%FT%T.%6N%z
  fi
}

function color {
  tput colors >/dev/null 2>&1 || return # If tput colors error theat term is messed up
  [[ $(tput colors) -ge 8 ]] || return  # Have at least 8 bit colors

  declare x='' codes='' reg=';$'
  declare -a args=()

  if $ZSH_FLAG ; then
    # shellcheck disable=SC2206,SC2296
    args=(${(@s: :)1})
  else
    args=("$1")
  fi

  # shellcheck disable=SC2068
  for x in ${args[@]} ; do
    case "$x" in
      # see https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
      bold|1)           codes+="1"  ;;
      faint|2)          codes+="2"  ;;
      italic|3)         codes+="3"  ;;
      underline|4)      codes+="4"  ;;
      blink|5)          codes+="5"  ;;
      invert|7)         codes+="7"  ;;
      black|30)         codes+="30" ;;
      red|31)           codes+="31" ;;
      green|32)         codes+="32" ;;
      yellow|33)        codes+="33" ;;
      blue|34)          codes+="34" ;;
      magenta|35)       codes+="35" ;;
      cyan|36)          codes+="36" ;;
      white|37)         codes+="37" ;;
      gray|90)          codes+="90" ;;
      brightred|91)     codes+="91" ;;
      brightgreen|92)   codes+="92" ;;
      brightyellow|93)  codes+="93" ;;
      brightblue|94)    codes+="94" ;;
      brightmagenta|95) codes+="95" ;;
      brightcyan|96)    codes+="96" ;;
      brightwhite|97)   codes+="97" ;;
      ^[0-9]+)          codes+="$x" ;;
      reset)            codes='' ;;
    esac
    codes+=\;
  done

  if [[ "$codes" =~ $reg ]] ; then
  if $ZSH_FLAG ; then
      codes=${codes:0:((${#codes} - 1))}
    else
      codes=${codes%?}
    fi
  fi
  echo -en '\033['"${codes}"'m'
}


function cecho {
  declare color="$1"
  shift
  color "$color"
  echo -en "$@"
  color
}

function mlog {
  [[ -z "$1" ]] && return 1
  declare TYPE="$1" MSG="$2" CODE="$3"
  [[ -z "$MSG" ]] && MSG="$TYPE" && TYPE=NORMAL
  if bcheck ZSH_FLAG && ! bcheck BASH_FLAG; then 
    TYPE=${TYPE:u}
  elif ! bcheck ZSH_FLAG && bcheck BASH_FLAG; then 
    TYPE=${TYPE^^}
  else
    #shellcheck disable=SC2060
    TYPE=$(echo "$TYPE" | tr [:lower:] [:upper:])
  fi

  declare TYPE_OUT=
  declare ERRFLAG=false
  case "$TYPE" in
    INFO|SUCCESS)           TYPE_OUT=$(cecho green "$TYPE") ;;
    WARN|WARNING)           TYPE_OUT=$(cecho yellow "$TYPE") ;;
    FATAL|ERROR|CRITICAL)   TYPE_OUT=$(cecho red "$TYPE"); ERRFLAG=true ;;
    TEST)                   bcheck TEST         || return ; TYPE_OUT=$(cecho gray "$TYPE") ;;
    DEBUG)                  bcheck DEBUG        || return ; TYPE_OUT=$(cecho magenta "$TYPE") ;;
    VERBOSE)                bcheck VERBOSE      || return ; TYPE_OUT=$(cecho brightcyan "$TYPE") ;;
    BUILD_DEBUG)            bcheck BUILD_DEBUG  || return ; TYPE_OUT=$(cecho brightgreen "$TYPE") ;;
    CODE_DEBUG)             bcheck CODE_DEBUG   || return ; TYPE_OUT=$(cecho brightgreen "$TYPE") ;;
    NORMAL)                 TYPE_OUT="" ;;
    *)                      TYPE_OUT="" ;;
  esac

  declare APP_NAME=''
  bcheck SHOW_APP_NAME && APP_NAME="$APPNAME"
 
  declare NL=false
  if $ZSH_FLAG && [[ $(print -rn "'$MSG'") == *\\n* || $MSG == *$'\n'* ]]; then
    NL=true
  elif $BASH_FLAG && [[ $MSG == *$'\n'* || "$MSG" =~ \\n ]] ; then
    NL=true 
  fi

  if $NL ; then
    if $ZSH_FLAG ; then
      declare x=''
      # shellcheck disable=SC2066,SC2296
      for x in "${(f@)$(print "$MSG")}" ; do
        [[ ${#x} -ge 1 ]] && mlog "$TYPE" "$x"
      done
    else
      declare x=''
      while IFS= read -r x ; do
        [[ ${#x} -ge 1 ]] && mlog "$TYPE" "$x"
      done < <(echo -e "$MSG")
    fi
  else
    if $DATELOG; then
      if [ -n "$APP_NAME" ] && [ -n "$TYPE_OUT" ]; then
        OUT="$(printf "%-32s %-10s %-17s %-s\n" "$(LOGTFMT)" "$APP_NAME" "$TYPE_OUT" "$MSG")"
      elif [ -n "$APP_NAME" ] ; then
        OUT="$(printf "%-32s %-10s %-s\n" "$(LOGTFMT)" "$APP_NAME" "$MSG")"
      elif [ -n "$TYPE_OUT" ] ; then
        OUT="$(printf "%-32s %-17s %-s\n" "$(LOGTFMT)" "$TYPE_OUT" "$MSG")"
      else
        OUT="$(printf "%-32s %-s\n" "$(LOGTFMT)" "$MSG")"
      fi
    else
      if [ -n "$APP_NAME" ] && [ -n "$TYPE_OUT" ] ; then
        OUT="$(printf "%-10s %-17s %-s" "$APP_NAME" "$TYPE_OUT" "$MSG")"
      elif [ -n "$APP_NAME" ] ; then
        OUT="$(printf "%-10s %-s" "$APP_NAME" "$MSG")"
      elif [ -n "$TYPE_OUT" ] ; then
        OUT="$(printf "%-17s %-s" "$TYPE_OUT" "$MSG")"
      else
        OUT="$(printf "%-s" "$MSG")"
      fi
    fi

    if $ERRFLAG; then
      echo -e "$OUT" >&2
    else
      echo -e "$OUT"
    fi
  fi

  [[ -n "$CODE" ]] && exitnow "$CODE"
}

function compareSemanticVersions {
  # return 0 is equal
  # return 1 is >
  # return 2 is <
  if [ $# -lt 2 ]; then
    mlog FATAL "can't compare Semantic Versions if variables are not passed"
    mlog FATAL "Usage: compareSemanticVersions var1 var2 " 10
  fi

  mlog BUILD_DEBUG "Semantic Compare $1 to $2"

  if [[ "$1" == "$2" ]]; then
    return 0
  fi

  local IFS=.
  # Everything after the first character not in [^0-9.] is compared
  #shellcheck disable=SC2206
  local i a=(${1%%[^0-9.]*}) b=(${2%%[^0-9.]*})
  #shellcheck disable=SC2295
  local arem=${1#${1%%[^0-9.]*}} brem=${2#${2%%[^0-9.]*}}
  for ((i = 0; i < ${#a[@]} || i < ${#b[@]}; i++)); do
    if ((10#${a[i]:-0} < 10#${b[i]:-0})); then
      return 2
    elif ((10#${a[i]:-0} > 10#${b[i]:-0})); then
      return 1
    fi
  done
  [[ "$arem" < "$brem" ]] && return 2
  [[ "$arem" > "$brem" ]] && return 1
  return 0
}


function secho {
  local _e="$*"
  local _PAD="20"
  local _c=''
  # we calculate it every time, as do check to see if columns have changed (ie term size)
  if [ -n "$BASH_VERSION" ] ; then
    (( _c=$"$COLUMNS-$_PAD" ))
  elif [ -n "$ZSH_VERSION" ] ; then
    (( _c= COLUMNS - _PAD ))
  fi

  if [[ -n $SECHO_VAR ]] && [ ${#SECHO_VAR} -eq $_c ]; then
    echo "$SECHO_VAR"
  else
    # NOTE setting the SECHO_VAR is faster then doing seq each time function is called
    printf -v SECHO_VAR "#%.s" $(seq 1 ${_c})
    export SECHO_VAR=$SECHO_VAR
    echo "$SECHO_VAR"
  fi
  [[ -n "$_e" ]] && echo "$_e" && echo "$SECHO_VAR"
}

###########################
# Main
###########################
init
isSourced && return

mlog ERROR "$0 needs to be sourced! (Not executed)"
