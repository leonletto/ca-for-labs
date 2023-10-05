#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi
#
#. ./bashLibrary.sh
#
#if [ -f .env ]; then
#    source .env
#
#fi

# Example Usage: ./newUserCert.sh "user1" '$Test458367' "password"

. ./common.sh


if ! [[ "${1:-}" ]]
then
    echo
    read -r -p "Please enter the Subject name (eg. username or email or SID ) for your certificate " certName
    echo
else
    certName=$1
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
    echo
    echo 'Email Address :'; read -r emailAddress
    echo
else
    emailAddress=$4
fi


if ! [[ "${5:-}" ]]
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
    if [ "$5" = "y" ] && [ "$6" = "y" ]; then
        echo "using same password for private key"
        privateKeyPassword=$pfxPassword
        passOnPrivateKey="y"
    elif [ "$5" = "y" ] && [ "$6" = "n" ]; then
        read -r -s -p "Please enter the password to use for your private key: " privateKeyPassword
        privateKeyPassword="$(echo "${privateKeyPassword}" | sed -e 's/[]\/$*.^|[]/\\&/g')"
        passOnPrivateKey="y"
        echo
    elif [ "$5" = "y" ]; then
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
        passOnPrivateKey="n"
        privateKeyPassword=""
    fi
fi

if [ "$passOnPrivateKey" == "y" ]; then
    if validPassword "$privateKeyPassword"; then
        privateKeyPassword=$(echo "${privateKeyPassword}" | sed -e 's/\\//g')
    else
        exit 1
    fi
fi

echo "Generating key request for $certName"


#Get the openssl version
opensslType=$(openssl version | cut -d' ' -f1)
opensslVersion=$(openssl version | cut -d' ' -f2)
opensslNewVersion=""
if [ "$opensslType" == "LibreSSL" ]; then
    if ge "$opensslVersion" "3.0.2"; then
        opensslNewVersion="true"
    else
        opensslNewVersion="false"
    fi
else
    if ge "$opensslVersion" "1.1.1"; then
        opensslNewVersion="true"
    else
        opensslNewVersion="false"
    fi
fi


case "$(uname -sr)" in
    MINGW64*)      subj="//dummy/CN=$certName/emailAddress=$emailAddress";;
    *)             subj="/CN=$certName/emailAddress=$emailAddress";;
esac

if [ "$opensslNewVersion" == "true" ]; then
    echo "passOnPrivateKey: $passOnPrivateKey"
    #Remove passphrase from the key. Comment the line out to keep the passphrase
    if [ "$passOnPrivateKey" == "n" ]; then
        #Generate a key
        echo "Generating key without password"
        openssl req -newkey rsa:2048 \
                -subj "$subj" \
                -config openssl.cnf \
                -extensions user_cert \
                -keyform PEM \
                -keyout usercerts/"$certName".key \
                -passin pass:"${caPassword}" \
                -out requests/"$certName".csr \
                -passout pass:tempPassword \
                -outform PEM
        #"Removing passphrase from key"
        echo "Removing passphrase from key"
        openssl rsa -in usercerts/"$certName".key -out usercerts/"$certName".key -passin pass:tempPassword
    else
        #Generate a key
        echo "Generating key with password"
        openssl req -newkey  rsa:2048 \
                -subj "$subj" \
                -config openssl.cnf \
                -extensions user_cert \
                -keyform PEM \
                -passin pass:"${caPassword}" \
                -keyout usercerts/"$certName".key \
                -out requests/"$certName".csr \
                -passout pass:"$privateKeyPassword" \
                -outform PEM
    fi
else
#     ( (printf "\nkeyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment\nextendedKeyUsage=clientAuth,emailProtection,msEFS")>userCertoptions.cnf )

    #Remove passphrase from the key. Comment the line out to keep the passphrase
    if [ "$passOnPrivateKey" == "n" ]; then
        #Generate a key
        echo "Generating key without password"
        openssl req -newkey rsa:2048 \
                -subj "$subj" \
                -config openssl.cnf -extensions user_cert \
                -keyform PEM \
                -keyout usercerts/"$certName".key \
                -passin pass:"${caPassword}" \
                -out requests/"$certName".csr \
                -passout pass:tempPassword \
                -outform PEM
        #"Removing passphrase from key"
        echo "Removing passphrase from key"
        openssl rsa -in usercerts/"$certName".key -out usercerts/"$certName".key -passin pass:tempPassword
    else
        #Generate a key
        echo "Generating key with password"
        openssl req -newkey  rsa:2048 \
                -subj "$subj" \
                -config openssl.cnf -extensions user_cert \
                -keyform PEM \
                -passin pass:"${caPassword}" \
                -keyout usercerts/"$certName".key \
                -out requests/"$certName".csr \
                -passout pass:"$privateKeyPassword" \
                -outform PEM
    fi
fi


myCACert=( cacerts/*.crt )
#Generate the cert (good for 10 years)
echo "Signing the certificate with the CA"
openssl ca -batch -passin pass:"${caPassword}" -config openssl.cnf -extensions user_cert -in requests/"$certName".csr -out usercerts/"$certName".crt

# Verify the cert
echo "Verifying the cert and adding it to the serial number file"
openssl verify -CAfile "${myCACert[0]}" usercerts/"$certName".crt

#Create the PFX
echo "Creating PFX for Windows"

if [ "$passOnPrivateKey" == "y" ]; then
    openssl pkcs12 -export -clcerts -in usercerts/"$certName".crt -inkey usercerts/"$certName".key -chain -CAfile "${myCACert[0]}" \
    -passin pass:"$privateKeyPassword" -passout pass:"$pfxPassword" -out pfxfiles/"$certName".pfx
else
    openssl pkcs12 -export -clcerts -in usercerts/"$certName".crt -inkey usercerts/"$certName".key -chain -CAfile "${myCACert[0]}" \
    -passout pass:"$pfxPassword" -out pfxfiles/"$certName".pfx
fi



#for MacOs you need to do the following:
#security import usercerts/$certName.p12 -k ~/Library/Keychains/login.keychain


