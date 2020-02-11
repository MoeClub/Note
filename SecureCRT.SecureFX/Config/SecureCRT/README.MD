# SecureCRT
## Global.ini
```
curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/SecureCRT.SecureFX/Config/SecureCRT/Global.ini" > "$HOME/Library/Application Support/VanDyke/SecureCRT/Config/Global.ini"
```

## Default.ini
```
curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/SecureCRT.SecureFX/Config/SecureCRT/Default.ini" > "$HOME/Library/Application Support/VanDyke/SecureCRT/Config/Sessions/Default.ini"
```

## SecureCRT.lic
```
find "$HOME/Library/Application Support/VanDyke/SecureCRT/Config/" -name "*.lic" -delete
curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/SecureCRT.SecureFX/Config/SecureCRT/SecureCRT.lic" > "$HOME/Library/Application Support/VanDyke/SecureCRT/Config/SecureCRT.lic"
```
