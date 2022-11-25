#!/bin/bash

[ "$(sudo whoami)" == "root" ] || exit 1

targetService="com.navicat.14days.plist"
targetFile="navicat14.sh"

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
    <string>com.navicat.14days</string>
    <key>ProgramArguments</key>
    <array>
        <string>bash</string>
        <string>/usr/local/$targetFile</string>
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

Plist="\${1:-com.navicat.NavicatPremium.plist}"

defaults write "\$Plist" SUSendProfileInfo -int 0;
defaults write "\$Plist" SUHasLaunchedBefore -int 0;
defaults write "\$Plist" SUEnableAutomaticChecks -int 0;
defaults write "\$Plist" didNAV16WelcomePageShow -int 1;
defaults delete "\$Plist" tableViewPreference >/dev/null 2>&1 ;

defaults read "\$Plist" |grep '{' |grep -o '[0-9A-Z]\{32\}' |xargs -I {} defaults delete "\$Plist" "{}"

for user in \`find /Users -type d -maxdepth 1\`; do NavicatPath="\$user/Library/Application Support/PremiumSoft CyberTech/Navicat CC/Navicat Premium"; [ -d "\$NavicatPath" ] || continue; find "\$NavicatPath" -type f -name ".*" -delete; done

date >"/tmp/navicat_14days.txt" 2>/dev/null
# sudo launchctl load -w /Library/LaunchDaemons/$targetService
# sudo launchctl unload -w /Library/LaunchDaemons/$targetService
# sudo rm -rf /Library/LaunchDaemons/$targetService /usr/local/$targetFile

EOF

sudo cp -rf "/tmp/$targetFile" "/usr/local/$targetFile"
sudo cp -rf "/tmp/$targetService" "/Library/LaunchDaemons/$targetService"
sudo launchctl load -w "/Library/LaunchDaemons/$targetService"
exit 0


