# Note

## MacOS
### Uncheck "Reopen windows when logging back in" by defaults
```
defaults write com.apple.loginwindow TALLogoutSavesState -bool false
```

### Delete system file
```
# Disbale SIP
csrutil disable

# Mount '/' as write
sudo mount -uw /

# Do something
sudo rm -rf /System/Applications/TV.app
sudo rm -rf /System/Applications/Home.app
sudo rm -rf /System/Applications/Books.app
sudo rm -rf /System/Applications/Chess.app
sudo rm -rf /System/Applications/Podcasts.app
sudo rm -rf /System/Applications/Stocks.app

# Enable SIP
csrutil enable
```
