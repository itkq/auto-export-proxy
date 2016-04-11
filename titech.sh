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

titech_pubnet_post_export
