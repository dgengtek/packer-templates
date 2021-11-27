#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# entrypoint
# ------------------------------------------------------------------------------


set -u # error on unset variables or parameters
set -e # exit on unchecked errors
set -b # report status of background jobs
# set -m # monitor mode - enable job control
# set -n # read commands but do not execute
# set -p # privileged mode - constrained environment
# set -v # print shell input lines
# set -x # expand every command
set -o pipefail # fail on pipe errors
# set -C # bash does not overwrite with redirection operators

declare -i enable_verbose=0
declare -i enable_quiet=0
declare -i enable_debug=0
declare -i enable_system_log=0
readonly __script_name="${BASH_SOURCE[0]##*/}"
readonly DOCKER_IMAGE_NAME=$(basename $(dirname $(realpath -e "$0")))


usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] <command> [<arguments>] [-- [EXTRA]]
Usage: ${0##*/} [OPTIONS] sh
Usage: ${0##*/} [OPTIONS] packer <packer arguments>

environment variables required
  PACKER_DIRECTORY  directory for created images
  DISTRIBUTION  name of distribution and its variable file found in either the packer directory or ./files
  IMAGE_URI  location of the image

sh  run interactive bash shell in container

packer  run packer in BUILD_DIRECTORY

OPTIONS:
  -h  help
  -v  verbose
  -q  quiet
  -d  debug
  -p,--path <directory>  some directory
EOF
}


main() {
  # flags

  local -a options
  local -a args

  check_dependencies
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- "${args[@]}"
  # remove args array
  unset -v args
  check_input_args "$@"

  set_signal_handlers
  prepare_env
  pre_run
  run "$@"
  post_run 
  unset_signal_handlers
}


################################################################################
# script internal execution functions
################################################################################

run() {
  local command=$1
  if [[ $(type -t _${command}) == "function" ]]; then
    shift
    _${command} "$@"
  else
    exec "$@"
  fi
}


check_dependencies() {
  :
}


check_input_args() {
  if [[ -z ${1:-""} ]]; then
    usage
    exit 1
  fi
}


prepare_env() {
  set_descriptors
}


prepare() {
  export PATH_USER_LIB=${PATH_USER_LIB:-"$HOME/.local/lib/"}

  source_libs
  set_descriptors
}


source_libs() {
  source "${PATH_USER_LIB}libutils.sh"
  source "${PATH_USER_LIB}libcolors.sh"
}


set_descriptors() {
  if (($enable_verbose)); then
    exec {fdverbose}>&2
  else
    exec {fdverbose}>/dev/null
  fi
  if (($enable_debug)); then
    set -xv
    exec {fddebug}>&2
  else
    exec {fddebug}>/dev/null
  fi
}


pre_run() {
  :
}


post_run() {
  :
}


parse_options() {
  # exit if no options left
  [[ -z ${1:-""} ]] && return 0
  # log "parse \$1: $1" 2>&$fddebug

  local do_shift=0
  case $1 in
      -d|--debug)
        enable_debug=1
        ;;
      -v|--verbose)
	enable_verbose=1
	;;
      -q|--quiet)
        enable_quiet=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --enable-log)
        enable_system_log=1
        ;;
      -p|--path)
        path=$2
        do_shift=2
        ;;
      --)
        do_shift=3
        ;;
      *)
        do_shift=1
	;;
  esac
  if (($do_shift == 1)) ; then
    args+=("$1")
  elif (($do_shift == 2)) ; then
    # got option with argument
    shift
  elif (($do_shift == 3)) ; then
    # got --, use all arguments left as options for other commands
    shift
    options+=("$@")
    return
  fi
  shift
  parse_options "$@"
}


################################################################################
# signal handlers
#-------------------------------------------------------------------------------


set_signal_handlers() {
  trap sigh_abort SIGABRT
  trap sigh_alarm SIGALRM
  trap sigh_hup SIGHUP
  trap sigh_cont SIGCONT
  trap sigh_usr1 SIGUSR1
  trap sigh_usr2 SIGUSR2
  trap sigh_cleanup SIGINT SIGQUIT SIGTERM EXIT
}


unset_signal_handlers() {
  trap - SIGABRT
  trap - SIGALRM
  trap - SIGHUP
  trap - SIGCONT
  trap - SIGUSR1
  trap - SIGUSR2
  trap - SIGINT SIGQUIT SIGTERM EXIT
}


sigh_abort() {
  trap - SIGABRT
}


sigh_alarm() {
  trap - SIGALRM
}


sigh_hup() {
  trap - SIGHUP
}


sigh_cont() {
  trap - SIGCONT
}


sigh_usr1() {
  trap - SIGUSR1
}


sigh_usr2() {
  trap - SIGUSR2
}


sigh_cleanup() {
  trap - SIGINT SIGQUIT SIGTERM EXIT
  local active_jobs=$(jobs -p)
  for p in $active_jobs; do
    if [[ -e "/proc/$p" ]]; then
      kill "$p" >/dev/null 2>&1
      wait "$p"
    fi
  done
}


log() {
  local cmd=("-s" "-t $__script_name")
  (($enable_system_log)) || cmd+=("--no-act")
  logger "${cmd[*]}" "$@"
}


# generate system logging function log_* for every level
for level in emerg err warning info debug; do
  printf -v functext -- 'log_%s() { logger -p user.%s -t %s -- "$@" ; }' "$level" "$__script_name"
  eval "$functext"
done


################################################################################
# custom functions
#-------------------------------------------------------------------------------
_docker() {
  cd "$(dirname ${BASH_SOURCE[0]})"
  sudo docker build -t "$DOCKER_IMAGE_NAME" .
}


_sh() {
  sudo docker run \
    --device=/dev/kvm \
    --mount source="${DOCKER_IMAGE_NAME}_images",target=/output \
    --rm -it "$DOCKER_IMAGE_NAME" 
}


_images() {
  sudo docker run \
    --device=/dev/kvm \
    --mount source="${DOCKER_IMAGE_NAME}_images",target=/output \
    --rm -i "$DOCKER_IMAGE_NAME" -c "fd -a -t f . /output"
}


_get_file() {
  local filename=${1:?Filename required}

  local cid=$(sudo docker run -d \
    --mount source="${DOCKER_IMAGE_NAME}_images",target=/output \
    $DOCKER_IMAGE_NAME true)
  sudo docker cp ${cid}:$filename .
  sudo chmod 600 ./$filename
  sudo chown $(id -u):$(id -g) ./$filename
  sudo docker rm $cid
}


_cleanup() {
  sudo docker volume rm ${DOCKER_IMAGE_NAME}_images
}


_rm() {
  _cleanup
}


_packer() {
  mkdir -p output
  sudo docker run \
    --env PACKER_DIRECTORY="$PACKER_DIRECTORY" \
    --env DISTRIBUTION="$DISTRIBUTION" \
    --env IMAGE_URI="$IMAGE_URI" \
    --device=/dev/kvm \
    --mount source="${DOCKER_IMAGE_NAME}_images",target=/output \
    --rm -i "$DOCKER_IMAGE_NAME" -s -- <<'EOF'
set -x
var_file="./${PACKER_DIRECTORY}/vars/${DISTRIBUTION}.json"
test -f "$var_file" || var_file="./files/${DISTRIBUTION}.json"
test -f "$var_file" || exit 1
just --set var_file "$var_file" docker
EOF
}

#-------------------------------------------------------------------------------
# end custom functions
################################################################################


prepare
main "$@"
