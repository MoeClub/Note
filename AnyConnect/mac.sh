#!/bin/bash

[[ $# -eq 2 ]] || exit 1
CERT_URL="$1"
CERT_PWD="$2"


# DO NOT EDIT
[[ -n "${CERT_URL}" ]] && [[ -n "${CERT_PWD}" ]] || exit 1
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
[[ -f "/tmp/MacOS.p12" ]] && security import "/tmp/MacOS.p12" -P "${CERT_PWD}"
[[ -f "/tmp/MacOS.p12" ]] && rm -rf "/tmp/MacOS.p12"

