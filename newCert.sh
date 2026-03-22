#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

show_help() {
    cat <<'HELP'
Usage: ./newCert.sh [DOMAIN [CA_PASSWORD [PFX_PASSWORD [PRIVATE_KEY_PASSWORD]]]]

Create a new server certificate signed by the CA.

Arguments (all optional — interactive prompts if omitted):
  DOMAIN                Server name / FQDN for the certificate
  CA_PASSWORD           Password for the CA private key
  PFX_PASSWORD          Password for the exported PFX file
  PRIVATE_KEY_PASSWORD  Password for the PEM private key (omit to be prompted
                        whether to set one)

Options:
  -h, --help    Show this help message and exit

Environment:
  TRACE=1       Enable shell tracing (set -x)

Examples:
  ./newCert.sh
  ./newCert.sh localhost
  ./newCert.sh myserver.example.com "CaPass123!" "PfxPass456!"
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
    read -r -p "Please enter the server name (FQDN) for your certificate " domain
    echo
else
    domain=$1
fi

validateDomain "$domain" || exit 1
prompt_ca_password "${2:-}"

prompt_pfx_password "${3:-}"

if ! [[ "${4:-}" ]]; then
    prompt_private_key_password
else
    privateKeyPassword="$(escape_password "${4}")"
    passOnPrivateKey="y"
    if validPassword "$privateKeyPassword"; then
        privateKeyPassword=$(unescape_password "$privateKeyPassword")
    else
        exit 1
    fi
fi

echo "Generating key request for $domain"

ca_passfile=$(create_passfile "$caPassword")

#Remove passphrase from the key. Comment the line out to keep the passphrase
if [ "$passOnPrivateKey" == "n" ]; then
    #Generate a key
    temp_passfile=$(create_passfile "tempPassword")
    openssl genrsa -aes256 -passout file:"$temp_passfile" -out privatekeys/"$domain".key 4096
    #"Removing passphrase from key"
    openssl rsa -in privatekeys/"$domain".key -out privatekeys/"$domain".key -passin file:"$temp_passfile"
else
    #Generate a key
    pk_passfile=$(create_passfile "$privateKeyPassword")
    openssl genrsa -aes256 -passout file:"$pk_passfile" -out privatekeys/"$domain".key 4096
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
    pk_passfile=${pk_passfile:-$(create_passfile "$privateKeyPassword")}
    openssl req -new -sha256 -key privatekeys/"$domain".key -out requests/"$domain".csr -passin file:"$pk_passfile" -subj "$subj" \
    -config <(cat ./openssl.cnf ./options.cnf) -extensions SAN
else
    openssl req -new -sha256 -key privatekeys/"$domain".key -out requests/"$domain".csr -subj "$subj" \
    -config <(cat ./openssl.cnf ./options.cnf) -extensions SAN
fi


myCACert=( cacerts/*.crt )

#Sign the Cert
echo "Signing the certificate with the CA"
openssl ca -batch -days "$CERT_DAYS" -passin file:"$ca_passfile" -extfile ./options.cnf -config openssl.cnf -extensions SAN -in requests/"$domain".csr \
 -out certs/"$domain".crt

rm options.cnf

# Verify the cert
echo "Verifying the cert and adding it to the serial number file"
openssl verify -CAfile "${myCACert[0]}" certs/"$domain".crt

#Create the PFX
echo "Creating PFX for Windows servers"

create_pfx_file "certs/$domain.crt" "privatekeys/$domain.key" "pfxfiles/$domain.pfx" -name "$domain-(expiration date)"

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