#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

. ./common.sh


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
    openssl genrsa -aes256 -passout pass:tempPassword -out privatekeys/"$domain".key 4096
    #"Removing passphrase from key"
    openssl rsa -in privatekeys/"$domain".key -out privatekeys/"$domain".key -passin pass:tempPassword
else
    #Generate a key
    openssl genrsa -aes256 -passout pass:"$privateKeyPassword" -out privatekeys/"$domain".key 4096
fi

# Configure the SANs and extensions for the certificate
cp -f ./optionsSample.cnf ./options.cnf
sedCmd "s/yourdomainname/$domain/g" options.cnf

# Configure the subject for the certificate
case "$(uname -sr)" in
    MINGW64*)      subj="//dummy/CN=$domain";;
    *)             subj="/CN=$domain";;
esac

echo "subj: $subj"



#Create the request
echo "Creating CSR"

if [ "$passOnPrivateKey" == "y" ]; then
    openssl req -new -sha256 -key privatekeys/"$domain".key -out requests/"$domain".csr -passin pass:"$privateKeyPassword" -subj "$subj" \
    -config <(cat ./openssl.cnf ./options.cnf) -extensions SAN
else
    openssl req -new -sha256 -key privatekeys/"$domain".key -out requests/"$domain".csr -subj "$subj" \
    -config <(cat ./openssl.cnf ./options.cnf) -extensions SAN
fi


myCACert=( cacerts/*.crt )

#Sign the Cert
echo "Signing the certificate with the CA"
openssl ca -batch -passin pass:"${caPassword}" -extfile ./options.cnf -config openssl.cnf -extensions SAN -in requests/"$domain".csr \
 -out certs/"$domain".crt

rm options.cnf

# Verify the cert
echo "Verifying the cert and adding it to the serial number file"
openssl verify -CAfile "${myCACert[0]}" certs/"$domain".crt

#Create the PFX
echo "Creating PFX for Windows servers"

if [ "$passOnPrivateKey" == "y" ]; then
    openssl pkcs12 -export -in certs/"$domain".crt -inkey privatekeys/"$domain".key -name "$domain-(expiration date)" -chain -CAfile "${myCACert[0]}" \
    -passin pass:"$privateKeyPassword" -passout pass:"$pfxPassword" -out pfxfiles/"$domain".pfx
else
    openssl pkcs12 -export -in certs/"$domain".crt -inkey privatekeys/"$domain".key -name "$domain-(expiration date)" -chain -CAfile "${myCACert[0]}" \
    -passout pass:"$pfxPassword" -out pfxfiles/"$domain".pfx
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