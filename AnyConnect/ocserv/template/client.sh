#!/bin/bash

command -v openssl >>/dev/null 2>&1
[ $? -ne 0 ] && echo "Not Found openssl" && exit 1
command -v certtool >>/dev/null 2>&1
[ $? -ne 0 ] && echo "Not Found certtool" && exit 1
cd `dirname "$0"`

export OrgName
export GroupName
export PASSWORD


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
    *)
      echo -e "Usage:\n\tbash $0 -o <OrgName> -g <GroupName> -p <PASSWORD>\n"
      exit 1;
      ;;
  esac
done

[ -n "${OrgName}" ] || OrgName="Haibara"
[ -n "${GroupName}" ] || GroupName="Default"


if [ ! -f ./ca.cert.pem -o ! -f ./ca.key.pem ]; then
  if [ ! -f ./ca.cfg ]; then
    echo -e "cn = \"${OrgName} CA\"\norganization = \"${OrgName}\"\nserial = 1\nexpiration_days = 3650\nca\nsigning_key\ncert_signing_key\ncrl_signing_key\n" >./ca.cfg
  fi
  openssl genrsa -out ./ca.key.pem 2048
  certtool --generate-privkey --outfile ./ca.key.pem
  certtool --generate-self-signed --template ./ca.cfg --load-privkey ./ca.key.pem --outfile ./ca.cert.pem
  cp -rf ./ca.cert.pem ../ca.cert.pem
  rm -rf ./ca.cfg
fi

if [ ! -f ../server.cert.pem -o ! -f ../server.key.pem ]; then
  if [ ! -f ./server.cfg ]; then
    echo -e "cn = \"${OrgName} CA\"\norganization = \"${OrgName}\"\nexpiration_days = -1\nsigning_key\nencryption_key\ntls_www_server\n" >./server.cfg
  fi
  openssl genrsa -out ../server.key.pem 2048
  certtool --generate-certificate --load-privkey ../server.key.pem --load-ca-certificate ./ca.cert.pem --load-ca-privkey ./ca.key.pem --template ./server.cfg --outfile ../server.cert.pem
  rm -rf ./server.cfg
fi

if [ ! -f ../dh.pem ]; then
  certtool --generate-dh-params --outfile ../dh.pem
fi

echo -e "cn = \"${OrgName}.${GroupName}\"\nunit = \"${GroupName}\"\nexpiration_days = 3650\nsigning_key\ntls_www_client\n" >./user.cfg
openssl genrsa -out ./user.key.pem 2048
certtool --generate-certificate --load-privkey ./user.key.pem --load-ca-certificate ./ca.cert.pem --load-ca-privkey ./ca.key.pem --template ./user.cfg --outfile ./user.cert.pem
cat ./ca.cert.pem >>./user.cert.pem
openssl pkcs12 -export -inkey ./user.key.pem -in ./user.cert.pem -name "${OrgName}.${GroupName}" -certfile ./ca.cert.pem -caname "${OrgName} CA" -out "./${GroupName}.p12" -passout pass:$PASSWORD

[ $? -eq '0' ] && echo -e "\nSuccess! \nGROUP\t\tPASSWORD\n${GroupName}\t\t$PASSWORD\n" || echo -e "\nFail! \n";
rm -rf ./user.cert.pem ./user.key.pem ./user.cfg
