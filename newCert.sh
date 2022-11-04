#!/bin/bash

#Required
domain=$1
caPassword=$2
pfxPassword=$3
#Change to your company details
#country=US
#state=Georgia
#locality=Atlanta
#organization=yourdomain.com
#organizationalunit=IT
#email=yourdomain@gmail.com

#Directories
privatekeys=privatekeys
#certs=certs
#crl=crl
pfxfiles=pfxfiles


if [ -z "$domain" ]
then
    echo "Argument not present - FQDN"
    echo "Useage =  newCert.sh myserver.mydomain.com"
    echo "[common name or fqdn of server eg. myserver.mydomain.com]"

    exit 99
fi

read -r -s -p "Please enter the password for your CA to issue certificates: " caPassword

read -r -s -p "Please enter the password to use for your pfx file: " pfxPassword
read -r -s "Do you want a password on your PEM private key? [y/n] " passAnswer
if [ "$passAnswer" == "y" ]; then
    read -r -s "do you want to use the PFX file password for your private key? [y/n] " answer
    if [ "$answer" != "${answer#[Yy]}" ] ;then
        echo "using same password for private key"
        privKeyPassword=$pfxPassword
    else
        read -r -s -p "Please enter the password to use for your private key: " privKeyPassword
    fi
fi




echo "Generating key request for $domain"

#Generate a key
openssl genrsa -aes256 -passout pass:"$privKeyPassword" -out $privatekeys/"$domain".key 4096

#Remove passphrase from the key. Comment the line out to keep the passphrase
if [ "$passAnswer" == "n" ]; then
    #"Removing passphrase from key"
    openssl rsa -in $privatekeys/"$domain".key -out $privatekeys/"$domain".key -passin pass:"$privKeyPassword"
fi

# Configure teh SANs for the certificate
cp -f ./optionsSample.cnf ./options.cnf
sed -i .bak "s/yourdomainname/$domain/g" options.cnf
#((printf "\n[SAN]\nbasicConstraints=CA:FALSE\nextendedKeyUsage=serverAuth\nsubjectAltName=DNS:%s,DNS:www.%s" "$domain" "$domain")>options.cnf)

#Create the request
echo "Creating CSR"
if [ "$passAnswer" == "y" ]; then
    openssl req -new -sha256 -key $privatekeys/"$domain".key -out requests/"$domain".csr -passin pass:"$pfxPassword" -subj "/CN=$domain" \
    -extensions SAN -config <(cat ./openssl.cnf ./options.cnf)
else
    openssl req -new -sha256 -key $privatekeys/"$domain".key -out requests/"$domain".csr -subj "/CN=$domain" \
    -extensions SAN -config <(cat ./openssl.cnf ./options.cnf)
fi


certpath=cacerts
mycert=( "$certpath"/*.crt )


#Sign the Cert
echo "Signing the certificate with the CA"
openssl ca -batch -passin pass:"$caPassword" -config openssl.cnf -in requests/"$domain".csr \
-extensions SAN -extfile <(cat ./openssl.cnf ./options.cnf) -out certs/"$domain".crt

# Verify the cert
echo "Verifying the cert and adding it to the serial number file"
openssl verify -CAfile "$mycert" certs/"$domain".crt

#Create the PFX
echo "Creating PFX for Windows servers"
openssl pkcs12 -export -in certs/"$domain".crt -inkey $privatekeys/"$domain".key -name "$domain-(expiration date)" -chain -CAfile "$mycert" \
-passin pass:"$privKeyPassword" -passout pass:"$pfxPassword" -out $pfxfiles/"$domain".pfx

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
#cat privatekeys/$domain.key
