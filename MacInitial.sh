#!/bin/bash

if [ -f "/usr/bin/sudo" ]; then
  #Unload System Daemons
  echo "Unload System Daemons ..."
  [ "$(sudo whoami)" == "root" ] || return

  cd "/Volumes/$(ls -1 /Volumes|head -n1)/System/Library/LaunchDaemons"

  # I don't have Apple TV so disable AirPlay
  sudo launchctl unload -wF com.apple.AirPlayXPCHelper.plist


  # Disable Apple push notification
  sudo launchctl unload -wF com.apple.apsd.plist


  # Disable apple software updates
  sudo launchctl unload -wF com.apple.softwareupdate*


  # Disable DVD
  sudo launchctl unload -wF com.apple.dvdplayback.setregion.plist


  # Disable feedback
  sudo launchctl unload -wF com.apple.SubmitDiagInfo.plist 
  sudo launchctl unload -wF com.apple.CrashReporterSupportHelper.plist 
  sudo launchctl unload -wF com.apple.ReportCrash.Root.plist 
  sudo launchctl unload -wF com.apple.GameController.gamecontrollerd.plist


  # Disable FTP
  sudo launchctl unload -wF com.apple.ftp-proxy.plist


  # Disable spindump
  sudo launchctl unload -wF com.apple.spindump.plist
  sudo launchctl unload -wF com.apple.metadata.mds.spindump.plist
fi

status=`csrutil status |cut -d":" -f2 |grep -io "enable\|disable"`
[ "$status" != "disable" ] && "Please disable SIP. (csrutil disable)" && exit 1


if [ -f "/usr/bin/sudo" ]; then
  sudo mount -uw /
  [ $? -ne 0 ] && echo "Mount / fail." && exit 1
else
  mount -uw /
  [ $? -ne 0 ] && echo "Mount / fail." && exit 1
fi

RENAME(){
  [ -n "$1" ] || return
  for item in `find . -type f -maxdepth 1 -name "$1"`
    do
      [ -n "$item" ] || continue
      echo "$item" |grep -q "\.bak$"
      [ $? -eq 0 ] && continue 
      echo "${item} --> ${item}.bak"
      if [ -f "/usr/bin/sudo" ]; then
        sudo mv "$item" "${item}.bak"
      else
        mv "$item" "${item}.bak"
      fi
    done
}

RENAMEBIN(){
  [ -f "/usr/bin/sudo" ] && [ -n "$1" ] && [ -f "$1" ] || return
  if [ ! -f "${1}.bak" ]; then
    echo "${1} --> ${1}.bak"
    sudo mv "${1}" "${1}.bak"
  fi
  if [ -f "${1}.bak" ]; then
    sudo ln -sf /usr/bin/true "$1"
  fi
}

RMAPP(){
  [ -n "$1" ] && [ -d "$1" ] || return
  echo "RM '$1'" && rm -rf "$1"
}

## Unload System Agents
echo "Unload System Agents ..."
cd "/Volumes/$(ls -1 /Volumes|head -n1)/System/Library/LaunchAgents"

# Disable AddressBook and Calendar
RENAME "com.apple.AddressBook*"
RENAME "com.apple.CalendarAgent.plist"


# iCloud-related
#RENAME "com.apple.iCloudUserNotifications.plist"
#RENAME "com.apple.icbaccountsd.plist"
#RENAME "com.apple.icloud.fmfd.plist"
#RENAME "com.apple.cloud*"


# Disable imclient (Facetime) and smth else
RENAME "com.apple.imagent.plist"
RENAME "com.apple.IMLoggingAgent.plist"


# spindump (see also code below)
RENAME "com.apple.spindump_agent.plist"
RENAMEBIN "/usr/sbin/spindump"

# Safari is not the only browser in the world
RENAME "com.apple.safaridavclient.plist"
RENAME "com.apple.SafariNotificationAgent.plist"
# in future versions of OS X
RENAME "com.apple.SafariCloudHistoryPushAgent.plist"


# Explain these
RENAME "com.apple.AirPlayUIAgent.plist"
RENAME "com.apple.AirPortBaseStationAgent.plist"
RENAME "com.apple.bird.plist"
RENAME "com.apple.findmymacmessenger.plist"
RENAME "com.apple.gamed.plist"
RENAME "com.apple.parentalcontrols.check.plist"
RENAME "com.apple.soagent.plist"
RENAME "com.apple.SocialPushAgent.plist"
RENAME "com.apple.DictationIM.plist"
RENAME "com.apple.Maps.pushdaemon.plist"
RENAME "com.apple.locationmenu.plist"
RENAME "com.apple.java.updateSharing.plist"
RENAME "com.apple.appstoreupdateagent.plist"
RENAME "com.apple.softwareupdate_notify_agent.plist"
RENAME "com.apple.ScreenReaderUIServer.plist"
RENAME "com.apple.speech.*"


# Remove System APP
echo "Remove System APP ..."
cd "/Volumes/$(ls -1 /Volumes|head -n1)/System/Applications"
RMAPP "TV.app"
RMAPP "News.app"
RMAPP "Home.app"
RMAPP "Books.app"
RMAPP "Chess.app"
RMAPP "Podcasts.app"
RMAPP "Stocks.app"
RMAPP "Music.app"

