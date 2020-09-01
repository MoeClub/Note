#!/bin/bash


command -v certtool >>/dev/null 2>&1
[ $? -ne 0 ] && echo "Not Found `certtool`" && exit 1

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
      echo "bash $0 -o <OrgName> -g <GroupName> -p <PASSWORD>"
      exit 1;
      ;;
  esac
done

[ -n "${OrgName}" ] || OrgName="Haibara"
[ -n "${GroupName}" ] || GroupName="Default"


if [ ! -f ./ca.cert.pem -o ! -f ./ca.key.pem ]; then
  if [ ! -f ./ca.tmpl ]; then
    echo -e "cn = \"${OrgName} CA\"\norganization = \"${OrgName}\"\nserial = 1\nexpiration_days = 3650\nca\nsigning_key\ncert_signing_key\ncrl_signing_key\n" >./ca.tmpl
  fi
  certtool --generate-privkey --outfile ./ca.key.pem
  certtool --generate-self-signed --template ./ca.tmpl --load-privkey ./ca.key.pem --outfile ./ca.cert.pem
  cp -rf ./ca.cert.pem ../ca.cert.pem
fi

echo "cn = \"${OrgName}.${GroupName}\"\nunit = \"${GroupName}\"\nexpiration_days = 3650\nsigning_key\ntls_www_client\n" >user.tmpl
certtool --generate-privkey --outfile ./user.key.pem
certtool --generate-certificate --hash SHA256 --load-privkey ./user.key.pem --load-ca-certificate ./ca.cert.pem --load-ca-privkey ./ca.key.pem --template ./user.tmpl --outfile ./user.cert.pem
cat ./ca.cert.pem >>./user.cert.pem
certtool --to-p12 --pkcs-cipher 3des-pkcs12 --load-privkey ./user.key.pem --load-certificate ./user.cert.pem --p12-name="${OrgName}.${GroupName}" --outfile "./${GroupName}.p12" --outder --empty-password --password=$PASSWORD;

[ $? -eq '0' ] && echo -e "\nSuccess! \nGROUP\t\tPASSWORD\n${GroupName}\t\t$PASSWORD\n" || echo -e "\nFail! \n";
