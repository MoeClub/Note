#!/bin/bash

command -v openssl >>/dev/null 2>&1
[ $? -ne 0 ] && echo "Not Found openssl" && exit 1
cd `dirname "$0"`

export OrgName
export GroupName
export PASSWORD
export INIT="0"


while [[ $# -ge 1 ]]; do
  case $1 in
    -o)
      shift
      OrgName=`echo "$1" |sed 's/\s//g'`
      shift
      ;;
    -g)
      shift
      GroupName=`echo "$1" |sed 's/\s//g'`
      shift
      ;;
    -p)
      shift
      PASSWORD=`echo "$1" |sed 's/\s//g'`
      shift
      ;;
    -i)
      shift
      INIT="1"
      ;;
    *)
      echo -e "Usage:\n\tbash $0 -o <OrgName> -g <GroupName> -p <PASSWORD>\n"
      exit 1;
      ;;
  esac
done

[ -n "${OrgName}" ] || OrgName="Haibara"
[ -n "${GroupName}" ] || GroupName="Default"


if [ ! -f ./ca.cert.pem -o ! -f ./ca.key.pem ]; then
  openssl req -x509 -sha256 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 3650 -subj "/C=/ST=/L=/OU=/O=/CN=${OrgName} CA" -addext "keyUsage=critical, keyCertSign, cRLSign" -outform PEM -keyout ./ca.key.pem -out ./ca.cert.pem  >/dev/null 2>&1
  [ $? -ne 0 ] && echo "Generating CA Fail" && exit 1
  cp -rf ./ca.cert.pem ../ca.cert.pem
fi

if [ "$INIT" == "1" ]; then
  exit 0
fi

openssl req -x509 -sha256 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 3650 -subj "/C=/ST=/L=/OU=${GroupName}/O=/CN=${OrgName}.${GroupName}" -addext "keyUsage=critical, digitalSignature" -outform PEM -keyout ./user.key.pem -out ./user.cert.pem  >/dev/null 2>&1
[ $? -ne 0 ] && echo "Generating Cert Fail" && exit 1

cat ./ca.cert.pem >>./user.cert.pem
openssl pkcs12 -export -inkey ./user.key.pem -in ./user.cert.pem -name "${OrgName}.${GroupName}" -certfile ./ca.cert.pem -caname "${OrgName} CA" -out "./${GroupName}.p12" -passout pass:$PASSWORD

[ $? -eq '0' ] && echo -e "\nSuccess! \nGROUP\t\tPASSWORD\n${GroupName}\t\t$PASSWORD\n" || echo -e "\nFail! \n";
rm -rf ./user.cert.pem ./user.key.pem
