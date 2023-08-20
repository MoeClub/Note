# Note

## MacOS
###
```
sudo xattr -r -d com.apple.quarantine </File/To/Path>
```

### Uncheck "Reopen windows when logging back in" by defaults
```
defaults write com.apple.loginwindow TALLogoutSavesState -bool FALSE
```

### Diasble other account
```
defaults write com.apple.loginwindow SHOWOTHERUSERS_MANAGED -bool FALSE
```

### Clear system update red notice
```
defaults delete com.apple.systempreferences AttentionPrefBundleIDs && killall Dock
```

### Clear App Store Update Notification
```
defaults write /Library/Preferences/com.apple.AppStore.plist DisableSoftwareUpdateNotifications -bool TRUE
defaults write com.apple.appstored.plist BadgeCount 0 && killall Dock
```

### System update notice
```
# disable
sudo chmod 644 /System/Library/PrivateFrameworks/SoftwareUpdate.framework/Versions/A/Resources/SoftwareUpdateNotificationManager.app/Contents/MacOS/SoftwareUpdateNotificationManager

# enable
sudo chmod 751 /System/Library/PrivateFrameworks/SoftwareUpdate.framework/Versions/A/Resources/SoftwareUpdateNotificationManager.app/Contents/MacOS/SoftwareUpdateNotificationManager
```

### MacOS System & App Store
```
# check
/usr/libexec/nsurlsessiond

# notice
/System/Library/PrivateFrameworks/SoftwareUpdate.framework/Versions/A/Resources/SoftwareUpdateNotificationManager.app/Contents/MacOS/SoftwareUpdateNotificationManager

# download
/System/Library/PrivateFrameworks/MobileSoftwareUpdate.framework/Support/softwareupdated
```


### Delete system file
```
# Disbale SIP (command + r)
csrutil disable
csrutil authenticated-root disable

# Mount '/' as write
sudo mount -uw /

# Do something
sudo cd "/Volumes/$(ls -1 /Volumes|head -n1)"
sudo rm -rf /System/Applications/TV.app
sudo rm -rf /System/Applications/News.app
sudo rm -rf /System/Applications/Home.app
sudo rm -rf /System/Applications/Books.app
sudo rm -rf /System/Applications/Chess.app
sudo rm -rf /System/Applications/Podcasts.app
sudo rm -rf /System/Applications/Stocks.app
sudo rm -rf /System/Applications/Music.app

# Enable SIP
csrutil enable
csrutil authenticated-root enable
```

# Modify user name and folder
- Create a user as Administrator, like "temp".
- Login "temp".
- Change user name and folder.
- Disable SIP.
- Use `sudo mv <OldFolder> <NewFolder>` to rename folder.
- Enable SIP.
- Login.
- Delete user "temp".


# 7z with MacOS
```
curl -sSL "https://www.7-zip.org/a/7z2107-mac.tar.xz" |tar -C /tmp -zxv 7zz && sudo mv /tmp/7zz /usr/local/bin/7z && sudo chmod a+x /usr/local/bin/7z

```

# Github Tools
```
https://github.com/p0deje/Maccy/releases

```
