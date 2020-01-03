# MacOS
```
bash <(curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/mac.sh") <CERT_URL> <CERT_PWD>
```

# iOS
```
anyconnect://create?usecert=true&certcommonname=<CERT_NAME>&name=<NAME>&host=<SERVER>
anyconnect://import?type=profile&uri=<PROFILE_URL>
anyconnect://import?type=pkcs12&uri=<CERT_URL>

anyconnect://connect/?name=<NAME>&onsuccess=anyconnect%3A%2F%2Fclose&onerror=anyconnect%3A%2F%2Fclose
anyconnect://disconnect/?onsuccess=anyconnect%3A%2F%2Fclose&onerror=anyconnect%3A%2F%2Fclose
```
