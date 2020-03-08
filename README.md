# Note

## MacOS
### Uncheck "Reopen windows when logging back in" by defaults
```
defaults write com.apple.loginwindow TALLogoutSavesState -bool FALSE
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
# Disbale SIP
csrutil disable

# Mount '/' as write
sudo mount -uw /

# Do something
sudo rm -rf /Applications/TV.app
sudo rm -rf /Applications/Home.app
sudo rm -rf /Applications/Books.app
sudo rm -rf /Applications/Chess.app
sudo rm -rf /Applications/Podcasts.app
sudo rm -rf /Applications/Stocks.app
sudo rm -rf /Applications/Music.app

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
