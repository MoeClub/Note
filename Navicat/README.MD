# Install
- Download DMG.
- Install.
- Disconnect Network.
- Generate a self-signed code-sign certificate and always trust it.
- Run Command.
```
./navicat-patcher "/Applications/Navicat Premium.app"

codesign -f -s "<CertificateName>" "/Applications/Navicat Premium.app"

./navicat-keygen ./RegPrivateKey.pem
```
- Enjoy.
