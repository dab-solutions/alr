#!/usr/bin/env bash

# default to Debian/Ubuntu
# yum is also supported
PKG_MANAGER="apt-get"
PKG_MANAGER_CMD="install"
PKG_MANAGER_PARAMS="-y"

REMOTE_UPLOAD=0
LYNIS_INSTALLED=1
GROUP="$1"
LABEL="$2"

LYNIS_GITHUB_REPO="https://github.com/CISOfy/lynis"

function log {
  local readonly level="$1"
  local readonly message="$2"
  local readonly timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] ${message}"
}

function log_info {
  local readonly message="$1"
  log "INFO" "$message"
}

function log_warn {
  local readonly message="$1"
  log "WARN" "$message"
}

function log_error {
  local readonly message="$1"
  log "ERROR" "$message"
}

function assert_is_installed() {
  local readonly name="$1"

  if [[ ! $(command -v ${name}) ]]; then
    return 1
  fi

  return 0
}

function usage() {
    echo "bash alr.sh <group> <label>"
}

function check_lynis_install() {
    assert_is_installed "lynis"
    if [ "$?" -eq 0 ]; then
        echo `which lynis`
    fi

    if [ -e "$PWD/lynis/lynis" ]; then
        echo "$PWD/lynis/"
    fi

    echo
}

function install_lynis() {
    log_info "Installing lynis via git"

    assert_is_installed "git"
    if [ "$?" -eq 1 ]; then
        log_warn "git not found. Installing via $PKG_MANAGER"
        $PKG_MANAGER $PKG_MANAGER_CMD $PKG_MANAGER_PARAMS git
        return $?
    fi

    git clone "$LYNIS_GITHUB_REPO"
    return $?
}

function upload() {
    local report="$1"
 
    log_info "Uploading to remote server"
    curl --form "file=$report" "${ALR_REMOTE_SERVER}/api/upload"
}

if [ "$REMOTE_UPLOAD" -eq 1 ]; then 
    if [ "$ALR_REMOTE_SERVER"x = x ]; then
        log_error "Cannot find env variable ALR_REMOTE_SERVER. Configure it before proceeding or disable remote upload by setting REMOTE_UPLOAD=0 in the script."
        exit 1
    fi

    if ! assert_is_installed "curl"; then
        log_error "curl not found. Please install it to being able to upload the report automatically"
        exit 1
    fi
fi

if [ "$GROUP"x = x ] || [ "$LABEL"x = x ]; then
    log_error "Please specify a group and a label"
    usage
    exit 1
fi

if assert_is_installed "yum"; then
    PKG_MANAGER="yum"
    PKG_MANAGER_CMD="install"
    PKG_MANAGER_PARAMS="-y"
fi

LYNIS_DIR=`check_lynis_install`
echo "lynis bin $LYNIS_DIR"
if [ "$LYNIS_DIR"x = x ]; then
    log_warn "Lynis not installed. We will install it for you."
    install_lynis
    LYNIS_DIR="$PWD/lynis/"
else
    log_info "Lynis installed!"
fi

profile_file="default.prf"
if [ -e "$PWD/custom.prf" ]; then
    profile_file="$PWD/custom.prf"
    rm -f "${LYNIS_DIR}/default.prf"
fi

log_info "Starting lynis scanning..."
report_file="$PWD/`cat /dev/urandom| tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1`.dat"

sudo chown -R 0:0 $LYNIS_DIR
cd $LYNIS_DIR
sudo ./lynis audit system --report-file "${report_file}" --profile "${profile_file}"
lynis_ret=$?

cd ../

sudo chown -R ${USER}.${USER} "$LYNIS_DIR"
sudo chown -R ${USER}.${USER} "${report_file}"

echo "group=$GROUP" >> "${report_file}"
echo "label=$LABEL" >> "${report_file}"

if [ "$lynis_ret" -eq 1 ]; then
    log_error "Scan interrupted. Report saved at ${report_file}"
    exit 1
fi

log_info "Finished scanning"

if [ "$REMOTE_UPLOAD" -eq 1 ]; then
    upload "${report_file}"
fi

log_info "All done! Please find your report at ${report_file}"
