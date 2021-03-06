#!/usr/bin/env bash

function show_ssid() {
  local AIRPORT_COMMAND="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
  $AIRPORT_COMMAND -I | grep '\ SSID' | awk '{print $2}'
}

function switch_wifi() {
  networksetup -setairportpower en0 $1
}

function is_ip_assigned() {
  local c

  for c in `seq 1 6`; do
    [ `ifconfig en0|grep "inet "|wc -l` = 1 ] && break
    echo 'Retry after 2 seconds...'
    sleep 2
  done

  [ `ifconfig en0|grep "inet "|wc -l` = 1 ] && return 0 || return 1
}

function authorize_titech() {
  local TP_LOGIN_URL="https://wlanauth.noc.titech.ac.jp/login.html"

  # login
  _CURL_RESULT=$(curl $TP_LOGIN_URL -X POST -d buttonClicked=4 -d "username=${TITECH_STUDENT_ID}&password=${TITECH_PASSWORD}" 2>&1)
  local STATUS_CODE=`echo $_CURL_RESULT | grep 'statusCode' | sed -e 's/^.*statusCode=//g' -e 's/\".*//g'`

  if echo $_CURL_RESULT | grep -q "Login Successful"; then
    return 1;
  fi

  case $STATUS_CODE in
      1) echo "You are already logged in.";;
          # u are already logged in.
      2) echo "You needn't authenticate against web portal.";;
          # u needn't authenticate against web portal..
      3) echo "Your account specified cannnot be used now. Perhaps already logged into the system (by other device).";;
          # ur account specified cannnot be used now. Perhaps already logged into the system.
      4) echo "Your account has been excluded. Please contact the Admin.";;
          # ur account has been excluded.
      5) echo "Invalid your account. Rewrite your information.";;
          # invalid username and TITECH_PASSWORD.
      *) echo "No error status code was returned"
          return 0
          ;;
  esac

  return 1
}

function default_proxy_post_export() {
  scselect "${DEFAULT_ENV_NAME}"
}

function titech_pubnet_post_export() {
  if [ `scselect | grep '\*' | grep "${TITECH_NETWORK_ENV}" | wc -l` = 0 ]; then
    scselect ${TITECH_NETWORK_ENV}
    sleep 4
  fi

  if is_ip_assigned; then
    echo 'Now authorizing...'

    if authorize_titech; then
      # wifi off -> on (A case which needs to reboot wifi exists)
      echo 'rebooting wifi'
      switch_wifi off
      switch_wifi on
      sleep 4

      echo 'Retry the authorization for checking...'
      if authorize_titech; then
          echo 'Auto log-in is successful.'
      else
          echo 'Auto log-in is failure.'
      fi
    else
      echo 'Auto log-in is successful.'
    fi
  fi
}

function export_default_proxy() {
  echo "unset http_proxy"
  echo "unset https_proxy"
  echo "unset ALL_PROXY"
}

function export_titech_pubnet() {
  local proxy_addr="http://proxy.noc.titech.ac.jp:3128"
  echo "export http_proxy=${proxy_addr}"
  echo "export https_proxy=${proxy_addr}"
  echo "export ALL_PROXY=${proxy_addr}"
}

function show_escaped_ssid() {
  local escaped=`show_ssid | sed -e 's/-/_/g'`

  if ! type "export_${escaped}" >/dev/null 2>&1; then
    escaped="default_proxy"
  fi

  echo "${escaped}"
}

function change_wifi() {
  networksetup -setairportnetwork en0 "$1" "$2"
}

function first_init() {
  local my_location="$(builtin cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
  local resource="${my_location}/resources"
  local other_export="${my_location}/other-export.sh"

  [ -f ${resource} ] && . ${resource}
  [ -f ${other_export} ] && . ${other_export}
}

first_init
eval "$1"
