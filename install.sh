#!/usr/bin/env bsh
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202308271918-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  LICENSE.md
# @@ReadME           :  install.sh --help
# @@Copyright        :  Copyright: (c) 2023 Jason Hempstead, Casjays Developments
# @@Created          :  Sunday, Aug 27, 2023 19:18 EDT
# @@File             :  install.sh
# @@Description      :
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  shell/bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck disable=SC2016
# shellcheck disable=SC2031
# shellcheck disable=SC2120
# shellcheck disable=SC2155
# shellcheck disable=SC2199
# shellcheck disable=SC2317
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# setup debugging - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
[ -f "/config/.debug" ] && [ -z "$DEBUGGER_OPTIONS" ] && export DEBUGGER_OPTIONS="$(cat "/config/.debug")" || DEBUGGER_OPTIONS="${DEBUGGER_OPTIONS:-}"
{ [ "$DEBUGGER" = "on" ] || [ -f "/config/.debug" ]; } && echo "Enabling debugging" && set -xo pipefail -x$DEBUGGER_OPTIONS && export DEBUGGER="on" || set -o pipefail
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# BASH_SET_SAVED_OPTIONS=$(set +o)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# check for command
__cmd_exists() { command "$1" >/dev/null 2>&1 || return 1; }
__function_exists() { command -v "$1" 2>&1 | grep -q "is a function" || return 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Relative find functions
__find_file_relative() { find "$1"/* -not -path '*env/*' -not -path '.git*' -type f 2>/dev/null | sed 's|'$1'/||g' | sort -u | grep -v '^$' | grep '^' || false; }
__find_directory_relative() { find "$1"/* -not -path '*env/*' -not -path '.git*' -type d 2>/dev/null | sed 's|'$1'/||g' | sort -u | grep -v '^$' | grep '^' || false; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# get and compare versions
__get_version() { printf '%s\n' "${1:-$(cat "/dev/stdin")}" | awk -F. '{ printf("%d%03d\n", $1,$2); }'; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# custom functions

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set default exit code
INSTALL_SH_EXIT_STATUS=0
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define Variables
EXPECTED_OS="alpine"
TEMPLATE_NAME="php"
OVER_WRITE_INIT="yes"
CONFIG_DIR="/usr/local/share/template-files/config"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
TMP_DIR="/tmp/config-$TEMPLATE_NAME"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
WWW_ROOT_DIR="${WWW_ROOT_DIR:-/usr/local/share/httpd/default}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
INIT_DIR="/usr/local/etc/docker/init.d"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set this if a file should exist - comma seperated list
CONFIG_CHECK_FILE=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
GIT_REPO="https://github.com/templatemgr/$TEMPLATE_NAME"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
OS_RELEASE="$(grep -si "$EXPECTED_OS" /etc/*-release* | sed 's|.*=||g;s|"||g' | head -n1)"
[ -n "$OS_RELEASE" ] || { echo "Unexpected OS: ${OS_RELEASE:-N/A}" && exit 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Custom env

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ "$TEMPLATE_NAME" != "sample-template" ] || { echo "Please set variable TEMPLATE_NAME" && exit 1; }
git clone -q "$GIT_REPO" "$TMP_DIR" || { echo "Failed to clone the repo" exit 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Main application
mkdir -p "$CONFIG_DIR" "$INIT_DIR"
find "$TMP_DIR/" -iname '.gitkeep' -exec rm -f {} \;
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# custom pre execution commands
[ -d "/usr/local/bin" ] || mkdir -p "/usr/local/bin"
[ -d "/usr/local/etc/docker/functions" ] || mkdir -p "/usr/local/etc/docker/functions"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
get_dir_list="$(__find_directory_relative "$TMP_DIR/config" || false)"
if [ -n "$get_dir_list" ]; then
  for dir in $get_dir_list; do
    mkdir -p "$CONFIG_DIR/$dir" /etc/$dir
  done
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
get_file_list="$(__find_file_relative "$TMP_DIR/config" || false)"
if [ -n "$get_file_list" ]; then
  for conf in $get_file_list; do
    if [ -f "/etc/$conf" ]; then
      rm -Rf /etc/${conf:?}
    fi
    if [ -d "$TMP_DIR/config/$conf" ]; then
      cp -Rf "$TMP_DIR/config/$conf/." "/etc/$conf/"
      cp -Rf "$TMP_DIR/config/$conf/." "$CONFIG_DIR/$conf/"
    elif [ -e "$TMP_DIR/config/$config" ]; then
      cp -Rf "$TMP_DIR/config/$conf" "/etc/$conf"
      cp -Rf "$TMP_DIR/config/$conf" "$CONFIG_DIR/$conf"
    fi
  done
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -d "$TMP_DIR/init-scripts" ]; then
  init_scripts="$(ls -A "$TMP_DIR/init-scripts/" | grep '^' || false)"
  if [ -n "$init_scripts" ]; then
    mkdir -p "$INIT_DIR"
    for init_script in $init_scripts; do
      if [ "$OVER_WRITE_INIT" = "yes" ] || [ ! -f "$INIT_DIR/$init_script" ]; then
        echo "Installing  $INIT_DIR/$init_script"
        cp -Rf "$TMP_DIR/init-scripts/$init_script" "$INIT_DIR/$init_script" &&
          chmod -Rf 755 "$INIT_DIR/$init_script" || true
      fi
    done
  fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -d "$TMP_DIR/www" ]; then
  rm -Rf "$WWW_ROOT_DIR"
  mkdir -p "$WWW_ROOT_DIR"
  cp -Rf "$TMP_DIR/www/." "$WWW_ROOT_DIR/"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -d "$INIT_DIR" ] && chmod -Rf 755 "$INIT_DIR"/*.sh || true
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -d "$TMP_DIR/functions" ] && cp -Rf "$TMP_DIR/functions/." "/usr/local/etc/docker/functions/" || true
[ -d "$TMP_DIR/bin" ] && chmod -Rf 755 "$TMP_DIR/bin/" && cp -Rf "$TMP_DIR/bin/." "/usr/local/bin/" || true
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Other files to copy to system

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# custom operations

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CONFIG_CHECK_FILE="${CONFIG_CHECK_FILE//,/ }"
if [ -n "$CONFIG_CHECK_FILE" ]; then
  for config_file in $CONFIG_CHECK_FILE; do
    if [ ! -f "$config_file" ]; then
      echo "Can not find a config file: $config_file"
      INSTALL_SH_EXIT_STATUS=1
    fi
  done
else
  echo "CONFIG_CHECK_FILE not enabled"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -d "$TMP_DIR" ] && rm -Rf "$TMP_DIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
# eval "$BASH_SET_SAVED_OPTIONS"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# lets exit with code
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit $INSTALL_SH_EXIT_STATUS
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ex: ts=2 sw=2 et filetype=sh
