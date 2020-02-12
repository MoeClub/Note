## Global.ini
```
curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/SecureCRT.SecureFX/Config/Global.ini" > "$HOME/Library/Application Support/VanDyke/SecureCRT/Config/Global.ini"
```

## Default.ini
```
curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/SecureCRT.SecureFX/Config/Default.ini" > "$HOME/Library/Application Support/VanDyke/SecureCRT/Config/Sessions/Default.ini"
```

## SecureCRT.lic
```
curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/SecureCRT.SecureFX/Config/SecureCRT.lic" > "$HOME/Library/Application Support/VanDyke/SecureCRT/Config/SecureCRT.lic"
```

## SecureFX.lic
```
curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/SecureCRT.SecureFX/Config/SecureFX.lic" > "$HOME/Library/Application Support/VanDyke/SecureCRT/Config/SecureFX.lic"
```

## Remove Lic
```
find "$HOME/Library/Application Support/VanDyke/SecureCRT/Config/" -name "*.lic" -delete
```
