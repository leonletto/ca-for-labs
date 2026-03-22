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

show_help() {
    cat <<'HELP'
Usage: ./newUserCert.sh [CERT_NAME [CA_PASSWORD [PFX_PASSWORD [EMAIL [PASS_ON_KEY [REUSE_PFX_PASS]]]]]]

Create a new user/client certificate signed by the CA.

Arguments (all optional — interactive prompts if omitted):
  CERT_NAME       Subject name (username, email, or SID)
  CA_PASSWORD     Password for the CA private key
  PFX_PASSWORD    Password for the exported PFX file
  EMAIL           Email address for the certificate
  PASS_ON_KEY     Whether to password-protect the private key (y/n)
  REUSE_PFX_PASS  Reuse PFX password for private key (y/n)

Options:
  -h, --help      Show this help message and exit

Environment:
  TRACE=1         Enable shell tracing (set -x)

Examples:
  ./newUserCert.sh
  ./newUserCert.sh "user1" "CaPass123!" "PfxPass456!" "user1@example.com"
  ./newUserCert.sh "user1" "CaPass123!" "PfxPass456!" "user1@example.com" y y
HELP
    exit 0
}

if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_help
fi

. ./common.sh


if ! [[ "${1:-}" ]]
then
    echo
    read -r -p "Please enter the Subject name (eg. username or email or SID ) for your certificate " certName
    echo
else
    certName=$1
fi

validateCertName "$certName" || exit 1


prompt_ca_password "${2:-}"

prompt_pfx_password "${3:-}"

if ! [[ "${4:-}" ]]
then
    echo
    echo 'Email Address :'; read -r emailAddress
    echo
else
    emailAddress=$4
fi

validateCertName "$emailAddress" "email address" || exit 1


if ! [[ "${5:-}" ]]; then
    prompt_private_key_password
else
    if [ "$5" = "y" ] && [ "$6" = "y" ]; then
        echo "using same password for private key"
        privateKeyPassword=$pfxPassword
        passOnPrivateKey="y"
    elif [ "$5" = "y" ] && [ "$6" = "n" ]; then
        read -r -s -p "Please enter the password to use for your private key: " privateKeyPassword
        privateKeyPassword="$(escape_password "$privateKeyPassword")"
        passOnPrivateKey="y"
        echo
    elif [ "$5" = "y" ]; then
        read -r -s -p "do you want to use the PFX file password for your private key? y/n: " answer
        echo
        if grep -q -e '[Yy]' <<< "$answer"; then
            echo "using same password for private key"
            privateKeyPassword=$pfxPassword
        else
            read -r -s -p "Please enter the password to use for your private key: " privateKeyPassword
            privateKeyPassword="$(escape_password "$privateKeyPassword")"
            echo
        fi
        passOnPrivateKey="y"
    else
        passOnPrivateKey="n"
        privateKeyPassword=""
    fi

    if [ "$passOnPrivateKey" == "y" ]; then
        if validPassword "$privateKeyPassword"; then
            privateKeyPassword=$(unescape_password "$privateKeyPassword")
        else
            exit 1
        fi
    fi
fi

echo "Generating key request for $certName"


#Get the openssl version
opensslType=$(openssl version | cut -d' ' -f1)
opensslVersion=$(openssl version | cut -d' ' -f2)
opensslNewVersion=""
if [ "$opensslType" == "LibreSSL" ]; then
    if version_ge "$opensslVersion" "3.0.2"; then
        opensslNewVersion="true"
    else
        opensslNewVersion="false"
    fi
else
    if version_ge "$opensslVersion" "1.1.1"; then
        opensslNewVersion="true"
    else
        opensslNewVersion="false"
    fi
fi


case "$(uname -sr)" in
    MINGW64*)      subj="//dummy/CN=$certName/emailAddress=$emailAddress";;
    *)             subj="/CN=$certName/emailAddress=$emailAddress";;
esac

ca_passfile=$(create_passfile "$caPassword")
temp_passfile=$(create_passfile "tempPassword")

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
                -passin file:"$ca_passfile" \
                -out requests/"$certName".csr \
                -passout file:"$temp_passfile" \
                -outform PEM
        #"Removing passphrase from key"
        echo "Removing passphrase from key"
        openssl rsa -in usercerts/"$certName".key -out usercerts/"$certName".key -passin file:"$temp_passfile"
    else
        #Generate a key
        echo "Generating key with password"
        pk_passfile=$(create_passfile "$privateKeyPassword")
        openssl req -newkey  rsa:2048 \
                -subj "$subj" \
                -config openssl.cnf \
                -extensions user_cert \
                -keyform PEM \
                -passin file:"$ca_passfile" \
                -keyout usercerts/"$certName".key \
                -out requests/"$certName".csr \
                -passout file:"$pk_passfile" \
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
                -passin file:"$ca_passfile" \
                -out requests/"$certName".csr \
                -passout file:"$temp_passfile" \
                -outform PEM
        #"Removing passphrase from key"
        echo "Removing passphrase from key"
        openssl rsa -in usercerts/"$certName".key -out usercerts/"$certName".key -passin file:"$temp_passfile"
    else
        #Generate a key
        echo "Generating key with password"
        pk_passfile=${pk_passfile:-$(create_passfile "$privateKeyPassword")}
        openssl req -newkey  rsa:2048 \
                -subj "$subj" \
                -config openssl.cnf -extensions user_cert \
                -keyform PEM \
                -passin file:"$ca_passfile" \
                -keyout usercerts/"$certName".key \
                -out requests/"$certName".csr \
                -passout file:"$pk_passfile" \
                -outform PEM
    fi
fi


myCACert=( cacerts/*.crt )
#Generate the cert (good for 10 years)
echo "Signing the certificate with the CA"
openssl ca -batch -days "$CERT_DAYS" -passin file:"$ca_passfile" -config openssl.cnf -extensions user_cert -in requests/"$certName".csr -out usercerts/"$certName".crt

# Verify the cert
echo "Verifying the cert and adding it to the serial number file"
openssl verify -CAfile "${myCACert[0]}" usercerts/"$certName".crt

#Create the PFX
echo "Creating PFX for Windows"

create_pfx_file "usercerts/$certName.crt" "usercerts/$certName.key" "pfxfiles/$certName.pfx" -clcerts



#for MacOs you need to do the following:
#security import usercerts/$certName.p12 -k ~/Library/Keychains/login.keychain


