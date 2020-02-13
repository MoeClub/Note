#!/bin/bash

FriendlyName="AnyConnect"
CA="Moeclub"

[ $# -eq '1' ] && PASSWORD="$1";
command -v openssl >>/dev/null 2>&1
[ $? -ne 0 ] && echo "Not Found `openssl`" && exit 1
command -v certtool >>/dev/null 2>&1
[ $? -ne 0 ] && echo "Not Found `certtool`" && exit 1


Check() {
  if [ ! -f "./$1" ]; then
    echo "Not Found $1"
    exit 1
  fi
}

Remove() {
  [ -n "$1" ] || exit 1
  if [ -f "./$1" ]; then
    rm -rf "./$1"
  fi
}

## Generate CA
# certtool --generate-privkey --outfile ./ca-key.pem
# certtool --generate-self-signed --load-privkey ./ca-key.pem --template ./ca.tmpl --outfile ./ca-cert.pem

Check "ca-cert.pem"
Check "ca-key.pem"
Check "user.tmpl"
Remove "user-key.pem"
Remove "user-cert.pem"
GROUP=`sed -n '/^unit/p' user.tmp |cut -d'"' -f2`
[ ! -n "$GROUP" ] && echo "No Group." && exit 1
certtool --generate-privkey --outfile ./user-key.pem
certtool --generate-certificate --hash SHA256 --load-privkey ./user-key.pem --load-ca-certificate ./ca-cert.pem --load-ca-privkey ./ca-key.pem --template ./user.tmpl --outfile ./user-cert.pem
cat ./ca-cert.pem >>./user-cert.pem
openssl pkcs12 -export -inkey ./user-key.pem -in ./user-cert.pem -name "${FriendlyName}.${GROUP}" -certfile ./ca-cert.pem -caname "${CA}" -out "./${GROUP}.p12" -passout pass:$PASSWORD
[ $? -eq '0' ] && echo -e "\nSuccess! \nGROUP\t\tPASSWORD\n$GROUP\t\t$PASSWORD\n" || echo -e "\nFail! \n";
