#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# entrypoint wrapper for running packer inside docker
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
readonly DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-$(basename $(dirname $(realpath -e "$0")))}
readonly DOCKER_REGISTRY=${DOCKER_REGISTRY:-""}
readonly PACKER_CACHE_DIR=${PACKER_CACHE_DIR:-/var/cache/packer}
# for image url with registry
declare image_name=$DOCKER_IMAGE_NAME
# for volume names
readonly sanitized_image_name=${DOCKER_IMAGE_NAME%:*}
[[ -n ${DOCKER_REGISTRY:-""} ]] && image_name="${DOCKER_REGISTRY}/${image_name}"
readonly PKR_VAR_build_directory=${PKR_VAR_build_directory:-/output}


usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] sh
Usage: ${0##*/} [OPTIONS] packer [<packer arguments>]
Usage: ${0##*/} [OPTIONS] <arch|debian> <build type> [<packer arguments>]
Usage: ${0##*/} [OPTIONS] <arch|debian> salt <parent_image_type> [<packer arguments>]

$(sed -n 's/^_\([^_)(]*\)() {[ ]*#\(.*\)/\1  \2/p' $__script_name | sort -k1 | column -t -N '<command>' -l 2)

$(sed -n 's/^__build_\([^)(_]*\)() {[ ]*#\(.*\)/\1  \2/p' $__script_name | sort -k1 | column -t -N '<build type>' -l 2)

$(sed -n 's/^__build_salt_\([^)(_]*\)() {[ ]*#\(.*\)/\1  \2/p' $__script_name | sort -k1 | column -t -N '<parent_image_type>' -l 2)

OPTIONS:
  -h  help
  -v  verbose
  -q  quiet
  -d  debug
EOF
}


main() {
  local -r volume_mountpoint=$(__get_first_path_component "$PKR_VAR_build_directory")

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
    usage
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
  set_descriptors
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
_docker() {  # build docker image with dependencies required for build
  cd "$(dirname "${BASH_SOURCE[0]}")"
  local -a args
  [[ -n $DOCKERFILE_FROM_IMAGE ]] && args+=(--build-arg "dockerfile_from_image=$DOCKERFILE_FROM_IMAGE")
  sudo docker build \
    "${args[@]}" \
    -t "$sanitized_image_name" .
}


_sh() {  # run interactive bash shell in container
  sudo docker run \
    --device=/dev/kvm \
    --mount source="${sanitized_image_name}_images",target=$volume_mountpoint \
    --mount source="${sanitized_image_name}_cache",target=${PACKER_CACHE_DIR} \
    --rm -it "$image_name" "$@"
}


_list() {  # show content of output directory containing the built images
  sudo docker run \
    --device=/dev/kvm \
    --mount source="${sanitized_image_name}_images",target=$volume_mountpoint \
    --rm -i "$image_name" -c "fd -a -t f . $volume_mountpoint | xargs ls -l"
}


_cat() {  # output a file from the given path to stdout as a tar archive
  local filename=${1:?Filename required}

  local cid=$(sudo docker run -d \
    --mount source="${sanitized_image_name}_images",target=$volume_mountpoint \
    $image_name true)
  sudo docker cp ${cid}:$filename -
  sudo docker rm $cid
}


_cleanup() {  # remove volumes containing the built images
  sudo docker volume rm ${sanitized_image_name}_images
  sudo docker volume rm ${sanitized_image_name}_cache
}


_rm() {  # alias to cleanup
  _cleanup
}


_cleanup_build() {
  _sh -c "rm -rvf $PKR_VAR_build_directory"
}


_packer() {  # run packer in BUILD_DIRECTORY
  __add_env_var PKR_VAR_build_directory
  __add_env_var PKR_VAR_distribution
  __add_env_var PKR_VAR_output_directory
  __add_env_var PKR_VAR_iso_url
  __add_env_var PKR_VAR_iso_checksum
  __add_env_var PKR_VAR_disk_size
  __add_env_var PKR_VAR_http_proxy http_proxy
  __add_env_var PKR_VAR_https_proxy https_proxy
  __add_env_var PKR_VAR_no_proxy no_proxy
  __add_env_var PKR_VAR_boot_wait
  __add_env_var PACKER_CACHE_DIR
  sudo docker run \
    --env PKR_VAR_enable_pki_install="${PKR_VAR_enable_pki_install:-false}" \
    --env PKR_VAR_vault_addr="${VAULT_ADDR:-https://vault:8200}" \
    --env PKR_VAR_vault_pki_secrets_path="${VAULT_PKI_SECRETS_PATH:-pki}" \
    --device=/dev/kvm \
    --mount type=bind,source=${PWD},target=/wd/,readonly \
    --mount source="${sanitized_image_name}_images",target=$volume_mountpoint \
    --mount source="${sanitized_image_name}_cache",target=${PACKER_CACHE_DIR} \
    "${args[@]}" \
    --rm -i "$image_name" -s -- <<EOF
set -x
packer $@
EOF
}

__add_env_var() {
  set +u
  local -r name=${1:?Var name required}
  local envname=${2:-""}
  [[ -z $envname ]] && envname=$name
  eval "[[ -n \$$envname ]]" && args+=(--env $name="$(eval echo \$$envname)")
  set -u
}


__get_first_path_component() {
  local res=""
  local path=$(realpath -m ${1:?Path required})
  while :; do
    if [[ $path == "/" ]]; then
      break
    fi
    res=$path
    path=$(dirname $path)
  done
  echo "$res"
}


_debian() {  # <build type>    build debian images
  [[ -z ${PKR_VAR_distribution:-""} ]] && PKR_VAR_distribution="debian-11.6-amd64"
  __run_DISTRIBUTION "$@"
}


_arch() {  # <build type>    build archlinux images
  PKR_VAR_distribution="archlinux-x86_64"
  __run_DISTRIBUTION "$@"
}


__run_DISTRIBUTION() {
  local -a args
  local -r os_name=${PKR_VAR_distribution%%-*}
  local -r build_type=$1
  shift

  if [[ -z "${build_type-}" ]]; then
    echo "ERROR: <build type> subcommand required" >&2
    usage
    exit 1
  fi
  __build_${build_type} "$@"
  # _packer "$@"
}


__build_base() {  # build base image
  _packer build -var-file base/$os_name/vars/common.json -var-file base/$os_name/vars/${PKR_VAR_distribution}.json "$@" base/$os_name/
}


__build_cloud() {  # build cloud-init image based on base image
  _packer build -var-file cloud/vars/common.json "$@" cloud
}


__build_kitchen() {  # build kitchen image based on base image
  _packer build -var-file kitchen/vars/common.json "$@" kitchen
}


__build_terminal() {  # build terminal image based on the base image
  _packer build -var-file terminal/vars/common.json "$@" terminal
}


__build_salt() {  # <parent_image_type>  build saltstack image based on a parent image type
  __env_salt
  __build_salt_${1:?Salt type required, either base, cloud or kitchen}
  _packer build -var-file salt/vars/common.json "$@" salt/
}


__build_salt_base() {  # build saltstack image based on the kitchen image
  args+=(--env PKR_VAR_parent_image_type=$os_name)
}

__build_salt_cloud() {  # build saltstack image based on the cloud-init image
  args+=(--env PKR_VAR_parent_image_type=cloud)
}


__build_salt_kitchen() {  # build saltstack image based on the kitchen image
  args+=(--env PKR_VAR_parent_image_type=kitchen)
}


__env_salt() {
  __add_env_var PKR_VAR_salt_version_tag
  __add_env_var PKR_VAR_salt_git_url
}


#-------------------------------------------------------------------------------
# end custom functions
################################################################################


prepare
main "$@"
