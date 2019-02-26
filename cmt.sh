#!/bin/bash

#Bash commands
_RM=/bin/rm
_AWK=/usr/bin/awk
_CP=/bin/cp
_CHMOD=/bin/chmod
_CHOWN=/bin/chown
_ECHO=/bin/echo
_JQ=/usr/bin/jq
_PKG_QUERY=/usr/bin/dpkg-query
_APT_GET=/usr/bin/apt-get
_CHECKSUM=/usr/bin/md5sum
###################################
# Logging:
#   syslog
# Path:
#   /var/log/syslog
# Example:
#  <Time stamp> <host> <script>:<LOG_TAG> [INFO/ERROR] <Message>
#
###################################

#For logging purposes
LOG_TAG='CM Tool'
SCRIPT_NAME="${0}"

METADATA=$(<./metadata.json)
APPLICATION_SOURCE="./index.php"

info() {
  logger -t "$SCRIPT_NAME:$LOG_TAG" [INFO] "$@"
}

error() {
  logger -t "$SCRIPT_NAME:$LOG_TAG" [ERROR] "$@"
}

######################################
# read_property:
#   Reads the json property value
# GLOBAL: 
#  _ECHO
#  _JQ
# ARGUMENTS:
#  1 - the property to read
#  2 - boolean to indicate if the property is an array
# RETURNS:
#  the value of the property
#####################################
read_property() { 
  local property="$1"
  local array="$2"

  local value="$($_ECHO $METADATA | $_JQ -r "${property}")"
  if [[ "${array}" == "true" ]]; then
    $_ECHO "${value}" | $_JQ -r -c ".[]"
  else
    $_ECHO "${value}"
  fi  
}

######################################
# install_packages:
#   Install the packages mentioned in metadata.properties file
# GLOBAL:
# _PKG_QUERY
# _APT_GET
# ARGUMENTS:
#  None
# RETURNS:
#  1 - in case the package installation failed
#####################################
install_pkgs(){
  local pkg=
  local packages=$(read_property '.packages.install' true)
  for pkg in ${packages}; do
    if ! $_PKG_QUERY -l "${pkg}" >/dev/null 2>&1; then
      info "Installing $pkg.."
      if ! $_APT_GET -yq install "${pkg}"; then
        error "Failed to install ${pkg}.. "
        exit 1
      fi
    fi
  done
}

######################################
# uninstall_packages:
#   Uninstall the packages mentioned in metadata.properties file
# GLOBAL:
# _JQ
# _PKG_QUERY
# _APT_GET
# ARGUMENTS:
#  None
# RETURNS:
#  1 - in case the package uninstallation failed
#####################################

uninstall_pkgs() {
  local pkg=
  for pkg in $(read_property '.packages.uninstall' true); do
    if $_PKG_QUERY -l "${pkg}" >/dev/null 2>&1; then
      info "Uninstalling $pkg.."
      if ! $_APT_GET -yq --purge remove "${pkg}"; then
        error "Failed to uninstall ${pkg}.. "
      fi
    fi
  done
}

######################################
# deploy_application:
#  Copy the Index.php file with right permissions in webroot folder
#  md5sum of index.php is checked before we deploy the application 
# GLOBAL:
# _CHOWN
# _CHMOD
#  APPLICATION_SOURCE
# ARGUMENTS:
#  None
# RETURNS:
#  0 - if the application is successfully deployed
#  1 - in case the package deploy failed
#####################################

deploy_application() {
  local webroot=$(read_property '.config.webroot')
  local owner=$(read_property '.config.owner')
  local group=$(read_property '.config.group')
  local filemask=$(read_property '.config.filemask')
 
  [[ -f "${webroot}/index.html" ]] && $_RM -f "${webroot}/index.html"

  if [[ $(calculate_md5_checksum $APPLICATION_SOURCE) == $(calculate_md5_checksum "${webroot}/$APPLICATION_SOURCE") ]];then
    info "No change in application, returning without deploying"
    return 1
  fi

  info "Deploying application..."
  if $_CP $APPLICATION_SOURCE ${webroot}/; then
    if ! $_CHOWN ${owner}:${group} ${webroot}/$APPLICATION_SOURCE; then
      error "Failed to change owner of the application"
    fi

    if ! $_CHMOD ${filemask} ${webroot}/$APPLICATION_SOURCE; then
      error "Failed to change the filemask"
    fi
  else
    error "Failed to copy the application in ${webroot}"
    exit 1
  fi

  return 0
}
######################################
# restart_services:
#  restart the service or services  
# GLOBAL:
#  None 
# ARGUMENTS:
#  None
# RETURNS:
#  1 - in case the service restart failed
#####################################
restart_services() {
  local services=$(read_property '.services' true)
  for service in ${services}; do
    info "Restarting service ${service}.."
    service "${service}" restart
    if ! service "${service}" status; then
      error "${service} is not running..."
      exit 1
    fi
  done
}

######################################
# calculate_md5_checksum:
#  check the md5sum of the index.php in webroot and current folder 
# GLOBAL:
#  _CHECKSUM 
# ARGUMENTS:
#  $1  - Check the current file  
#####################################

calculate_md5_checksum() {
  local file="$1"
  if [[ -r "${file}" ]]; then
    $_CHECKSUM ${file} | $_AWK '{print $1}'
  fi
}

############################
# Main starts here
############################
export DEBIAN_FRONTEND=noninteractive

uninstall_pkgs

install_pkgs

if deploy_application; then
  restart_services
fi

unset DEBIAN_FRONTEND
exit 0
