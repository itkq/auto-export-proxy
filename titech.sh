#!/usr/bin/env bash

atproxy_location=`dirname $0`
functions="${atproxy_location}/encapsulated_functions.sh"
[ -f ${functions} ] && . ${functions}

ssid=`show_ssid | sed -e 's/-/_/g'`
echo $ssid

if [ $ssid != "TokyoTech" ]; then
  echo 'Changing to TokyoTech ...'
  change_wifi TokyoTech "${TOKYOTECH_PASS}"
  sleep 4
fi

if is_ip_assigned; then
  echo 'Now authorizing...'

  authorize_titech
fi
