#!/bin/bash

if [ -f "/usr/bin/sudo" ]; then
  [ "$(sudo whoami)" == "root" ] || return
  # System setting
  echo -e "\n# System setting ..."
  sudo defaults write com.apple.loginwindow TALLogoutSavesState -bool FALSE
  sudo defaults write com.apple.loginwindow SHOWOTHERUSERS_MANAGED -bool FALSE
  sudo defaults write com.apple.systempreferences AttentionPrefBundleIDs 0
fi


# Check SIP
[ -f "/usr/bin/sudo" ] && [ "$(csrutil status |cut -d':' -f2 |grep -io 'enable\|disable')" != "disable" ] && echo "Please disable SIP. (command + r; csrutil disable)" && exit 1

# Mount
if [ -f "/usr/bin/sudo" ]; then
  sudo mount -uw /
else
  mount -uw /
fi
[ $? -ne 0 ] && echo "Mount root fail." && exit 1


DISABLE(){
  [ -n "$1" ] && [ -n "$2" ] && [ -d "$1" ] || return
  for item in `find "$1" -type f -maxdepth 1 -name "${2}*"`
    do
      [ -n "$item" ] || continue
      echo "$item" |grep -q "\.plist$"
      [ $? -eq 0 ] || continue
      echo "Disable: ${item}"
      if [ -f "/usr/bin/sudo" ]; then
        sudo mv "${item}" "${item}.bak"
      else
        mv "${item}" "${item}.bak"
      fi
    done
}

ENABLEALL(){
  [ -n "$1" ] && [ -d "$1" ] || return
  for item in `find "$1" -type f -maxdepth 1 -name "*.bak"`
    do
      [ -n "$item" ] || continue
      echo "$item" |grep -q "\.bak$"
      [ $? -eq 0 ] || continue
      newItem=`echo "${item}" |sed "s/.\bak$//"`
      echo "Enable: ${newItem}"
      if [ -f "/usr/bin/sudo" ]; then
        sudo mv "${item}" "${newItem}"
      else
        mv "${item}" "${newItem}"
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
    sudo ln -sf "/usr/bin/true" "$1"
  fi
}

RMAPP(){
  [ -n "$1" ] &&  [ -n "$2" ] && [ -d "$1" ] || return
  for item in `find "$1" -type d -maxdepth 1 -name "${2}"`
    do
      [ -n "$item" ] || continue
      echo "RM APP '$2'"
      if [ -f "/usr/bin/sudo" ]; then
        sudo rm -rf "${item}"
      else
        rm -rf "${item}"
      fi
    done
}


DEAMONS=()
# Disable Analytic
DEAMONS+=("com.apple.analyticsd.plist")
# Disable AirPlay
#DEAMONS+=("com.apple.AirPlayXPCHelper.plist")
# Disable Updates
DEAMONS+=("com.apple.softwareupdate.plist")
# Disable DVD
DEAMONS+=("com.apple.dvdplayback.setregion.plist")
# Disable Feedback
DEAMONS+=("com.apple.SubmitDiagInfo.plist" \
          "com.apple.CrashReporterSupportHelper.plist" \
          "com.apple.ReportCrash.Root.plist"\
          "com.apple.GameController.gamecontrollerd.plist")
# Disable FTP
DEAMONS+=("com.apple.ftp-proxy.plist")
# Disable APSD
#DEAMONS+=("com.apple.apsd")
# Disable spindump
DEAMONS+=("com.apple.spindump.plist")
# Disable systemstats
DEAMONS+=("com.apple.systemstats.daily.plist" \
          "com.apple.systemstats.analysis.plist" \
          "com.apple.systemstats.microstackshot_periodic.plist")


AGENTS=()
# Disable iCloud
AGENTS+=("com.apple.cloud" \
         "com.apple.icloud.fmfd.plist" \
         "com.apple.iCloudUserNotifications.plist")
# Disable AddressBook
AGENTS+=("com.apple.AddressBook")
# Disable Safari
AGENTS+=("com.apple.safaridavclient.plist" \
         "com.apple.SafariNotificationAgent.plist" \
         "com.apple.SafariCloudHistoryPushAgent.plist")
# Disable Facetime
AGENTS+=("com.apple.imagent.plist" \
         "com.apple.IMLoggingAgent.plist")
# Quicklook
AGENTS+=("com.apple.quicklook.ui.helper.plist" \
         "com.apple.quicklook.ThumbnailsAgent.plist" \
         "com.apple.quicklook.plist")
# Disable Game Center / Apple TV / Homekit
AGENTS+=("com.apple.gamed.plist" \
         "com.apple.videosubscriptionsd.plist" \
         "com.apple.homed.plist"
         "com.apple.AMPArtworkAgent.plist")
# Disable Siri
AGENTS+=("com.apple.siriknowledged.plist" \
         "com.apple.assistant_service.plist" \
         "com.apple.assistantd.plist" \
         "com.apple.Siri.agent.plist")
# Disable Airplay
#AGENTS+=("com.apple.AirPlayUIAgent.plist")
# Disable Sidecar
#AGENTS+=("com.apple.sidecar-hid-relay.plist" \
#         "com.apple.sidecar-relay.plist")
# Disable Ad
AGENTS+=("com.apple.ap.adprivacyd.plist" \
         "com.apple.ap.adservicesd.plist")
# Disable Debug
AGENTS+=("com.apple.spindump_agent.plist" \
         "com.apple.ReportCrash.plist" \
         "com.apple.ReportGPURestart.plist" \
         "com.apple.ReportPanic.plist")
# Disable Others
AGENTS+=("com.apple.AirPortBaseStationAgent.plist" \
         "com.apple.photoanalysisd.plist" \
         "com.apple.familycircled.plist" \
         "com.apple.familycontrols.useragent.plist" \
         "com.apple.familynotificationd.plist" \
         "com.apple.parentalcontrols.check.plist" \
         "com.apple.podcasts.PodcastContentService.plist" \
         "com.apple.macos.studentd.plist" \
         "com.apple.suggestd.plist" \
         "com.apple.facebook.xpc.plist" \
         "com.apple.linkedin.xpc.plist" \
         "com.apple.twitter.xpc.plist" \
         "com.apple.soagent.plist" \
         "com.apple.SocialPushAgent.plist" \
         "com.apple.Maps.pushdaemon.plist" \
         "com.apple.DictationIM.plist" \
         "com.apple.java.updateSharing.plist" \
         "com.apple.softwareupdate_notify_agent.plist")


APPS=()
APPS+=("TV.app" \
       "News.app" \
       "Home.app" \
       "Books.app" \
       "Chess.app" \
       "Podcasts.app" \
       "Stocks.app")



# Volume
cd "/Volumes/$(ls -1 /Volumes|head -n1)"

# Enable /System/Library/LaunchDaemons
ENABLEALL "./System/Library/LaunchDaemons"

# Enable /System/Library/LaunchAgents
ENABLEALL "./System/Library/LaunchAgents"

# Enable Update Check
echo -e "\n# Enable Update Check ..."
if [ -f "/usr/bin/sudo" ]; then
sudo find "/System/Library/CoreServices/Software Update.app" -type f -name "softwareupdated" |xargs -t -I "{}" sudo chmod 755 "{}"
else
find "/System/Library/CoreServices/Software Update.app" -type f -name "softwareupdated" |xargs -t -I "{}" chmod 755 "{}"
fi

# Enable and Exit
# exit 0

# Disable /System/Library/LaunchDaemons
echo -e "\n# Disable Daemons ..."
for deamon in "${DEAMONS[@]}"; do DISABLE "./System/Library/LaunchDaemons" "$deamon"; done

# Disable /System/Library/LaunchAgents
echo -e "\n# Disable Agents ..."
for agent in "${AGENTS[@]}"; do DISABLE "./System/Library/LaunchAgents" "$agent"; done

# Remove System APP
echo -e "\n# Remove System APP ..."
for app in "${APPS[@]}"; do RMAPP "./System/Applications" "$app"; done

# Replace spindump
echo -e "\n# Replace spindump ..."
RENAMEBIN "/usr/sbin/spindump"

# Disable Update Notice
echo -e "\n# Disable Update Notice ..."
if [ -f "/usr/bin/sudo" ]; then
sudo find "/System/Library/PrivateFrameworks/SoftwareUpdate.framework" -type f -name "SoftwareUpdateNotificationManager" |xargs -t -I "{}" sudo chmod 644 "{}"
else
find "/System/Library/PrivateFrameworks/SoftwareUpdate.framework" -type f -name "SoftwareUpdateNotificationManager" |xargs -t -I "{}" chmod 644 "{}"
fi

# Disable Update Check
#echo -e "\n# Disable Update Check ..."
#if [ -f "/usr/bin/sudo" ]; then
#sudo find "/System/Library/CoreServices/Software Update.app" -type f -name "softwareupdated" |xargs -t -I "{}" sudo chmod 644 "{}"
#else
#find "/System/Library/CoreServices/Software Update.app" -type f -name "softwareupdated" |xargs -t -I "{}" chmod 644 "{}"
#fi

# Finish
echo -e "\n# Finish! \n"
