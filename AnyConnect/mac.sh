#!/bin/bash

[[ "$#" -ge "1" ]] || exit 1
CERT_URL="${1:-}"
CERT_PWD="${2:-}"
CERT_TMP="/tmp/MacOS"


# DO NOT EDIT
[[ -n "${CERT_URL}" ]] || exit 1
[[ -n "${CERT_PWD}" ]] && Mode=0 || Mode=1
USER_HOME=`echo "$HOME"`
[[ "$(sudo whoami)" == "root" ]] || exit 1

[[ -e "${USER_HOME}/.cisco" ]] && rm -rf "${USER_HOME}/.cisco"
[[ -e "${USER_HOME}/.anyconnect" ]] && rm -rf "${USER_HOME}/.anyconnect"

cat >"${USER_HOME}/.anyconnect"<<EOF
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
		<BlockUntrustedServers>false</BlockUntrustedServers>
		<DisableCaptivePortalDetection>true</DisableCaptivePortalDetection>
	</ControllablePreferences>
</AnyConnectPreferences>
EOF

chmod 777 "${USER_HOME}/.anyconnect"
cp -f "${USER_HOME}/.anyconnect" "/opt/cisco/anyconnect/.anyconnect_global"
chmod 777 "/opt/cisco/anyconnect/.anyconnect_global"

cat >"/opt/cisco/anyconnect/profile/profile.xml"<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<AnyConnectProfile xmlns="http://schemas.xmlsoap.org/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://schemas.xmlsoap.org/encoding/ AnyConnectProfile.xsd">
	<ClientInitialization>
		<UseStartBeforeLogon UserControllable="false">false</UseStartBeforeLogon>
		<StrictCertificateTrust>false</StrictCertificateTrust>
		<RestrictPreferenceCaching>false</RestrictPreferenceCaching>
		<RestrictTunnelProtocols>false</RestrictTunnelProtocols>
		<BypassDownloader>true</BypassDownloader>
		<AuthenticationTimeout>16</AuthenticationTimeout>
		<WindowsVPNEstablishment>AllowRemoteUsers</WindowsVPNEstablishment>
		<LinuxVPNEstablishment>AllowRemoteUsers</LinuxVPNEstablishment>
		<CertEnrollmentPin>pinAllowed</CertEnrollmentPin>
		<CertificateMatch>
			<KeyUsage>
				<MatchKey>Digital_Signature</MatchKey>
			</KeyUsage>
			<ExtendedKeyUsage>
				<ExtendedMatchKey>ClientAuth</ExtendedMatchKey>
			</ExtendedKeyUsage>
		</CertificateMatch>
	</ClientInitialization>
</AnyConnectProfile>
EOF
chmod 777 "/opt/cisco/anyconnect/profile/profile.xml"


[[ -f "${CERT_URL}" ]] && cp -f "${CERT_URL}" "${CERT_TMP}.p12" || curl -ksSL -H "User-Agent: wget/1.0" -o "${CERT_TMP}.p12" "${CERT_URL}"
if [[ -f "${CERT_TMP}.p12" ]]; then
  openssl pkcs12 -in "${CERT_TMP}.p12" -nodes -nokeys -nocerts -clcerts -cacerts -password pass:"${CERT_PWD}"
  [[ "$?" -ne "0" ]] && rm -rf "${CERT_TMP}.p12" && exit 1
  openssl pkcs12 -in "${CERT_TMP}.p12" -nodes -nokeys -clcerts -out "${CERT_TMP}_Cert.pem" -password pass:"${CERT_PWD}"
  openssl pkcs12 -in "${CERT_TMP}.p12" -nodes -nocerts -out "${CERT_TMP}_Key.pem" -password pass:"${CERT_PWD}"
  openssl pkcs12 -in "${CERT_TMP}.p12" -nodes -nokeys -cacerts -out "${CERT_TMP}_CA.pem" -password pass:"${CERT_PWD}"
  openssl pkcs12 -export -inkey "${CERT_TMP}_Key.pem" -in "${CERT_TMP}_Cert.pem" -certfile "${CERT_TMP}_CA.pem" -out "${CERT_TMP}_New.p12" -passout pass:NewCert
  security import "${CERT_TMP}_New.p12" -P "NewCert"
  rm -rf "${CERT_TMP}.p12" "${CERT_TMP}_New.p12" "${CERT_TMP}_CA.pem" "${CERT_TMP}_Cert.pem" "${CERT_TMP}_Key.pem"
fi
exit 0
