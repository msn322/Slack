#!/bin/bash

#standard commands
_PKG_QUERY=/usr/bin/dpkg-query
_APT_GET=/usr/bin/apt-get

LOG_TAG='CMT BOOTSTRAP'
SCRIPT_NAME="${0}"

declare -a DEPENDENCIES=( "jq" )

########################
# Logging methods
########################
info() {
  logger -t "$SCRIPT_NAME:$LOG_TAG" [INFO] "$@"
}

error() {
  logger -t "$SCRIPT_NAME:$LOG_TAG" [ERROR] "$@"
}


#/////////////////////////
#  Main starts here
#/////////////////////////

export DEBIAN_FRONTEND=noninteractive
for dependency in "${DEPENDENCIES[@]}";
do
  if ! $_PKG_QUERY -l "${dependency}" >/dev/null 2>&1; then
    info "Installing $dependency.."
    if ! $_APT_GET -yq install "${dependency}"; then
      error "Failed to install ${dependency}.. "
    fi
  fi
done
unset DEBIAN_FRONTEND

exit 0
