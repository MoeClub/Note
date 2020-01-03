#!/bin/bash

CSET_PWD=""
CSET_URL=""

# DO NOT EDIT
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

curl -sSL -H "User-Agent: wget/1.0" -o "/tmp/MacOS.p12" "${CSET_URL}"
[ -f "/tmp/MacOS.p12" ] && security import "/tmp/MacOS.p12" -P "${CSET_PWD}"
[ -f "/tmp/MacOS.p12" ] && rm -rf "/tmp/MacOS.p12"




