#!/bin/bash

[ "$(sudo whoami)" == "root" ] || exit 1

targetService="com.sysctl.ttl.plist"
targetFile="ttl.sh"

cat <<EOF> "/tmp/$targetService"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>EnvironmentVariables</key>
    <dict>
      <key>PATH</key>
      <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:</string>
    </dict>
    <key>Label</key>
    <string>com.sysctl.ttl</string>
    <key>ProgramArguments</key>
    <array>
        <string>sysctl</string>
        <string>-w</string>
        <string>net.inet.ip.ttl=128</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>LaunchOnlyOnce</key>        
    <true/>
</dict>
</plist>
EOF

cat <<EOF>"/tmp/$targetFile"
#!/bin/bash

for user in \`sudo dscl . list /Users NFSHomeDirectory |grep -v '^_\\|^root\\|^daemon\\|^nobody' |sed 's/[[:space:]]\\{1,\}/\\;/g'\`; do userName=\`echo "\$user" |cut -d';' -f1\`; userHome=\`echo "\$user" |cut -d';' -f2\`; PlistPath="\$userHome/Library/Preferences"; [ -d "\$PlistPath" ] || continue; for plist in \`find "\$PlistPath" -type f -name "*NavicatPremium*" -maxdepth 1\`; do sudo -u "\$userName" defaults write "\$plist" SUSendProfileInfo -int 0; sudo -u "\$userName" defaults write "\$plist" SUHasLaunchedBefore -int 0; sudo -u "\$userName" defaults write "\$plist" SUEnableAutomaticChecks -int 0; sudo -u "\$userName" defaults write "\$plist" didNAV16WelcomePageShow -int 1; sudo -u "\$userName" defaults delete "\$plist" tableViewPreference >/dev/null 2>&1 ; sudo -u "\$userName" defaults read "\$plist" |grep '{' |grep -o '[0-9A-Z]\\{32\\}' |xargs -I {} sudo -u "\$userName" defaults delete "\$plist" "{}"; done; NavicatPath="\$userHome/Library/Application Support/PremiumSoft CyberTech/Navicat CC/Navicat Premium"; [ -d "\$NavicatPath" ] || continue; find "\$NavicatPath" -type f -name ".*" -delete; done

date >"/tmp/navicat_14days.txt" 2>/dev/null
# sudo launchctl load -w /Library/LaunchDaemons/$targetService
# sudo launchctl unload -w /Library/LaunchDaemons/$targetService
# sudo rm -rf /Library/LaunchDaemons/$targetService /usr/local/$targetFile

EOF

sudo cp -rf "/tmp/$targetFile" "/usr/local/$targetFile"
sudo cp -rf "/tmp/$targetService" "/Library/LaunchDaemons/$targetService"
sudo launchctl load -w "/Library/LaunchDaemons/$targetService"
exit 0


