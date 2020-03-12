#!/bin/bash

[[ $# -ge 1 ]] || exit 1
CERT_URL="${1:-}"
CERT_PWD="${2:-}"


# DO NOT EDIT
[[ -n "${CERT_URL}" ]] || exit 1
[[ -n "${CERT_PWD}" ]] && Mode=0 || Mode=1
USER_Home=`echo "$HOME"`
[[ "$(sudo whoami)" == "root" ]] || exit 1

[[ -e "${USER_Home}/.cisco" ]] && rm -rf "${USER_Home}/.cisco"
[[ -e "${USER_Home}/.anyconnect" ]] && rm -rf "${USER_Home}/.anyconnect"

cat >"${USER_Home}/.anyconnect"<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<AnyConnectPreferences>
<DefaultUser></DefaultUser>
<DefaultSecondUser></DefaultSecondUser>
<ClientCertificateThumbprint></ClientCertificateThumbprint>
<MultipleClientCertificateThumbprints></MultipleClientCertificateThumbprints>
<ServerCertificateThumbprint></ServerCertificateThumbprint>
<DefaultHostName></DefaultHostName>
<DefaultHostAddress></DefaultHostAddress>
<DefaultGroup>Default</DefaultGroup>
<ProxyHost></ProxyHost>
<ProxyPort></ProxyPort>
<SDITokenType>none</SDITokenType>
<ControllablePreferences>
<AutoConnectOnStart>true</AutoConnectOnStart>
<LocalLanAccess>true</LocalLanAccess>
<BlockUntrustedServers>false</BlockUntrustedServers></ControllablePreferences>
</AnyConnectPreferences>
EOF

[[ -f "${CERT_URL}" ]] && cp -f "${CERT_URL}" "/tmp/MacOS.p12" || curl -sSL -H "User-Agent: wget/1.0" -o "/tmp/MacOS.p12" "${CERT_URL}"
if [[ -f "/tmp/MacOS.p12" ]]; then
  if [[ "$Mode" == "0" ]]; then
    security import "/tmp/MacOS.p12" -P "${CERT_PWD}"
    rm -rf "/tmp/MacOS.p12"
  elif [[ "$Mode" == "1" ]]; then
    openssl pkcs12 -in "/tmp/MacOS.p12" -nodes -nokeys -clcerts -out "/tmp/MacOS_Cert.pem" -password pass:
    openssl pkcs12 -in "/tmp/MacOS.p12" -nodes -nocerts -out "/tmp/MacOS_Key.pem" -password pass:
    openssl pkcs12 -in "/tmp/MacOS.p12" -nodes -nokeys -cacerts -out "/tmp/MacOS_CA.pem" -password pass:
    openssl pkcs12 -export -inkey "/tmp/MacOS_Key.pem" -in "/tmp/MacOS_Cert.pem" -certfile "/tmp/MacOS_CA.pem" -out "/tmp/MacOS_New.p12" -passout pass:New
    security import "/tmp/MacOS_New.p12" -P "New"
  else
    exit 1
  fi
fi


