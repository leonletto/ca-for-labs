#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

. ./bashLibrary.sh

if [ -f .env ]; then
    source .env

fi

#Change to your company details
#country=US
#state=Georgia
#locality=Atlanta
#organization=yourdomain.com
#organizationalunit=IT
#email=yourdomain@gmail.com

#Directories
privateKeys=privatekeys
caCertPath=cacerts
#certs=certs
#crl=crl
pfxFiles=pfxfiles




if ! [[ "${1:-}" ]]
then
    echo
    read -r -p "Please enter the server name (FQDN) for your certificate " domain
    echo
else
    domain=$1
fi
if ! [[ "${2:-}" ]]
then
    echo
    read -r -s -p "Please enter the password for your CA to issue certificates: " caPassword
    caPassword="$(echo "${caPassword}" | sed -e 's/[]\/$*.^|[]/\\&/g')"
    echo
else
    caPassword="$(echo "${2}" | sed -e 's/[]\/$*.^|[]/\\&/g')"
fi

if checkCAPassword "$caPassword"; then
    caPassword=$(echo "${caPassword}" | sed -e 's/\\//g')
else
    exit 1
fi


if ! [[ "${3:-}" ]]
then
    read -r -s -p "Please enter the password to use for your pfx file: " pfxPassword
    pfxPassword="$(echo "${pfxPassword}" | sed -e 's/[]\/$*.^|[]/\\&/g')"
    echo
else
    pfxPassword="$(echo "${3}" | sed -e 's/[]\/$*.^|[]/\\&/g')"
fi

if validPassword "$pfxPassword"; then
    pfxPassword=$(echo "${pfxPassword}" | sed -e 's/\\//g')
else
    exit 1
fi


if ! [[ "${4:-}" ]]
then
    read -r -p "Do you want a password on your PEM private key? y/n: " passOnPrivateKey
    echo
    if [ "$passOnPrivateKey" = "y" ]; then
        read -r -s -p "do you want to use the PFX file password for your private key? y/n: " answer
        echo
        if grep -q -e '[Yy]' <<< "$answer";then
            echo "using same password for private key"
            privateKeyPassword=$pfxPassword
        else
            read -r -s -p "Please enter the password to use for your private key: " privateKeyPassword
            privateKeyPassword="$(echo "${privateKeyPassword}" | sed -e 's/[]\/$*.^|[]/\\&/g')"
            echo
        fi
    else
        privateKeyPassword=""
    fi
else
    privateKeyPassword="$(echo "${4}" | sed -e 's/[]\/$*.^|[]/\\&/g')"
    passOnPrivateKey="y"
fi

if validPassword "$privateKeyPassword"; then
    privateKeyPassword=$(echo "${privateKeyPassword}" | sed -e 's/\\//g')
else
    exit 1
fi

echo "Generating key request for $domain"



#Remove passphrase from the key. Comment the line out to keep the passphrase
if [ "$passOnPrivateKey" == "n" ]; then
    #Generate a key
    openssl genrsa -aes256 -passout pass:tempPassword -out $privateKeys/"$domain".key 4096
    #"Removing passphrase from key"
    openssl rsa -in $privateKeys/"$domain".key -out $privateKeys/"$domain".key -passin pass:tempPassword
else
    #Generate a key
    openssl genrsa -aes256 -passout pass:"$privateKeyPassword" -out $privateKeys/"$domain".key 4096
fi

# Configure the SANs for the certificate
cp -f ./optionsSample.cnf ./options.cnf
sedCmd "s/yourdomainname/$domain/g" options.cnf
#((printf "\n[SAN]\nbasicConstraints=CA:FALSE\nextendedKeyUsage=serverAuth\nsubjectAltName=DNS:%s,DNS:www.%s" "$domain" "$domain")>options.cnf)

#Create the request
echo "Creating CSR"
if [ "$passOnPrivateKey" == "y" ]; then
    openssl req -new -sha256 -key $privateKeys/"$domain".key -out requests/"$domain".csr -passin pass:"$privateKeyPassword" -subj "/CN=$domain" \
    -extensions SAN -config <(cat ./openssl.cnf ./options.cnf)
else
    openssl req -new -sha256 -key $privateKeys/"$domain".key -out requests/"$domain".csr -subj "/CN=$domain" \
    -extensions SAN -config <(cat ./openssl.cnf ./options.cnf)
fi


myCACert=( "$caCertPath"/*.crt )

command="openssl ca -batch  -passin pass:${caPassword} -config openssl.cnf requests/${domain}.csr -extensions SAN -extfile <(cat ./options.cnf) -out certs/${domain}.crt &> /dev/null"
echo "$command"

#Sign the Cert
echo "Signing the certificate with the CA"
openssl ca -batch -passin pass:"${caPassword}" -config openssl.cnf -in requests/"$domain".csr \
-extensions SAN -extfile <(cat ./openssl.cnf ./options.cnf) -out certs/"$domain".crt

# Verify the cert
echo "Verifying the cert and adding it to the serial number file"
openssl verify -CAfile "${myCACert[0]}" certs/"$domain".crt

#Create the PFX
echo "Creating PFX for Windows servers"

if [ "$passOnPrivateKey" == "y" ]; then
    openssl pkcs12 -export -in certs/"$domain".crt -inkey $privateKeys/"$domain".key -name "$domain-(expiration date)" -chain -CAfile "${myCACert[0]}" \
    -passin pass:"$privateKeyPassword" -passout pass:"$pfxPassword" -out $pfxFiles/"$domain".pfx
else
    openssl pkcs12 -export -in certs/"$domain".crt -inkey $privateKeys/"$domain".key -name "$domain-(expiration date)" -chain -CAfile "${myCACert[0]}" \
    -passout pass:"$pfxPassword" -out $pfxFiles/"$domain".pfx
fi

#
#echo "---------------------------"
#echo "-----Below is your CSR-----"
#echo "---------------------------"
#echo
#cat requests/$domain.csr
#
#echo
#echo "---------------------------"
#echo "-----Below is your Key-----"
#echo "---------------------------"
#echo
#cat privateKeys/$domain.key
# to see the details of the cert
#openssl x509 -in certs/$domain.crt -text -noout