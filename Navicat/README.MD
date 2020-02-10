# Install
- Download DMG.
```
bash <(curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/Navicat/navicat121_premium_cs.dmg/download.sh")
```
- Install.
- Disconnect Network.
- [Generate a self-signed code-sign certificate](https://support.apple.com/zh-cn/guide/keychain-access/kyca8916/mac) and always trust it.
- Run Command.
```
./navicat-patcher "/Applications/Navicat Premium.app"

codesign -f -s "<CertificateName>" "/Applications/Navicat Premium.app"

./navicat-keygen ./RegPrivateKey.pem
```
- Enjoy.
