#!/bin/bash

[ "$(sudo whoami)" == "root" ] || exit 1

targetService="com.sysctl.ttl.plist"

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
        <string>net.inet.ip.ttl=96</string>
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

sudo cp -rf "/tmp/$targetService" "/Library/LaunchDaemons/$targetService"
sudo chown root:wheel "/Library/LaunchDaemons/$targetService"
sudo chmod 644 "/Library/LaunchDaemons/$targetService"
sudo launchctl load -w "/Library/LaunchDaemons/$targetService"
exit 0


