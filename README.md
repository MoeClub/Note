# Note

## MacOS
### Uncheck "Reopen windows when logging back in" by defaults
```
defaults write com.apple.loginwindow TALLogoutSavesState -bool FALSE
```

### Diasble other account
```
defaults write com.apple.loginwindow SHOWOTHERUSERS_MANAGED -bool FALSE
```

### Disable system update
```
defaults write com.apple.systempreferences AttentionPrefBundleIDs 0
```

### Disable App Store Update Notification
```
sudo defaults write /Library/Preferences/com.apple.AppStore.plist DisableSoftwareUpdateNotifications -bool TRUE
```

### Delete system file
```
# Disbale SIP (command + r)
csrutil disable

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
