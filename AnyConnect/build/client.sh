#!/bin/bash

command -v openssl >>/dev/null 2>&1
[ $? -ne 0 ] && echo "Not Found openssl" && exit 1
cd `dirname "$0"`

export OrgName
export GroupName
export PASSWORD
export INIT


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
      INI_=`echo $1 |sed 's/\s//g'`
      INIT="${INI_:-0.0.0.0}"
      shift
      ;;
    *)
      echo -e "Usage:\n\tbash $0 -o <OrgName> -g <GroupName> -p <PASSWORD> -i <CN>\n"
      exit 1;
      ;;
  esac
done


[ -n "$INIT" ] && [ -f "./ca.cert.pem" ] && [ -n "${OrgName}" ] && rm -rf "./ca.cert.pem"
[ -f "./ca.cert.pem" ] && OrgName=`openssl x509 -noout -in "./ca.cert.pem" -subject 2>/dev/null |sed 's/.*\s*O\s\+=\s\+\([^,\ ]\+\),.*/\1/'`

[ -n "${OrgName}" ] || OrgName="MoeClub"
[ -n "${GroupName}" ] || GroupName="Default"


if [ ! -f ./ca.cert.pem -o ! -f ./ca.key.pem ] || [ -n "$INIT" ] ; then
  openssl req -x509 -sha256 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 3650 -subj "/C=/ST=/L=/OU=/O=${OrgName}/CN=${OrgName} CA" -addext "keyUsage=critical, keyCertSign, cRLSign" -rand /dev/urandom -outform PEM -keyout "./ca.key.pem" -out "./ca.cert.pem"  >/dev/null 2>&1

  [ $? -ne 0 ] && echo "Generating CA Fail" && exit 1
  cp -rf ./ca.cert.pem ../ca.cert.pem
 
  openssl req -x509 -sha256 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 3650 -subj "/C=/ST=/L=/OU=/O=/CN=${INIT:-0.0.0.0}" -config <(echo -e "[ req ]\ndistinguished_name=req\n") -addext "basicConstraints=CA:FALSE" -addext "keyUsage=critical, digitalSignature, keyEncipherment" -addext "extendedKeyUsage=serverAuth, clientAuth" -rand /dev/urandom -outform PEM -keyout "../server.key.pem" -out "../server.cert.pem" >/dev/null 2>&1
  [ $? -ne 0 ] && echo "Generating Server Cert Fail" && exit 1
  
  chmod -R 755 ../
fi

if [ -n "$INIT" ]; then
  exit 0
fi


openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -subj "/C=/ST=/L=/OU=${GroupName}/O=${OrgName}/CN=${OrgName}.${GroupName}" -rand /dev/urandom -outform PEM -keyout "./user.key.pem" -out "./user.csr.pem" >/dev/null 2>&1
[ $? -ne 0 ] && echo "Generating CSR Fail" && exit 1

openssl x509 -set_serial `printf "%04d" "$(($RANDOM % 10000))"` -CAform PEM -CA "./ca.cert.pem" -CAkey "./ca.key.pem" -req -sha256 -days 365 -in "./user.csr.pem" -outform PEM -out "./user.cert.pem" -extfile <(echo -e "basicConstraints=CA:FALSE\nkeyUsage=digitalSignature\nextendedKeyUsage=clientAuth\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid\n")
[ $? -ne 0 ] && echo "Generating Cert Fail" && exit 1


cat ./ca.cert.pem >>./user.cert.pem
openssl pkcs12 -export -inkey "./user.key.pem" -in "./user.cert.pem" -name "${OrgName}.${GroupName}" -certfile "./ca.cert.pem" -caname "${OrgName} CA" -out "./${GroupName}.p12" -passout "pass:$PASSWORD"

[ $? -eq '0' ] && echo -e "\nSuccess! \nGROUP\t\tPASSWORD\n${GroupName}\t\t$PASSWORD\n" || echo -e "\nFail! \n";
rm -rf ./user.csr.pem ./user.key.pem ./user.cert.pem
# openssl x509 -noout -text -in ./ca.cert.pem

exit 0