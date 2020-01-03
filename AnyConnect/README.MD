# MacOS
```
bash <(curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/mac.sh") <CERT_URL> <CERT_PWD>
```

# iOS
```
anyconnect://create?usecert=true&certcommonname=<CERT_NAME>&name=<NAME>&host=<SERVER>
anyconnect://import?type=profile&uri=<PROFILE_URL>
anyconnect://import?type=pkcs12&uri=<CERT_URL>
```
