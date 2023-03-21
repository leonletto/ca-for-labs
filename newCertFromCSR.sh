#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

. ./common.sh


if ! [[ "${1:-}" ]]
then
    echo
    read -r -p "Please enter the filename of your CSR ( Certificate Signing Request " csrFileName
    echo
else
    csrFileName=$1
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

myCACert=( cacerts/*.crt )

# From the CSR get the Subject
echo "Getting the subject/domain from the CSR"
domain=$(openssl req -in "$csrFileName" -noout -subject | sed -e 's/.*CN=//g' | sed -e 's/\/.*//g')
echo "Subject Line: $domain"

echo "Getting the SANs from the CSR"
sanCheck=$(openssl req -in "$csrFileName" -noout -text)
sanExists=0
while read -r line; do
    if [[ "$line" == "X509v3 Subject Alternative Name:" ]]; then
        sanExists=1
    fi
done <<< "$sanCheck"

if [[ "$sanExists" == "0" ]]; then
    echo "No SANs found in the CSR"
    cp -f ./optionsSample.cnf ./options.cnf
    sedCmd "s/yourdomainname/$domain/g" options.cnf
else
    echo "SANs found in the CSR"
    sans=$(openssl req -in "$csrFileName" -noout -text | grep -A2 "X509v3 Subject Alternative Name:" | grep DNS | sed -e "s/DNS://g" | sed -e "s/,//g" | sed -e "s/^[[:space:]]*//g")
    sanText=""
    for san in $sans; do
        sanText="${sanText}DNS:$san,"
    done
    sanText=$(echo "$sanText" | sed -e 's/,$//g')
    cp -f ./optionsSample.cnf ./options.cnf
    sedCmd "s/DNS:yourdomainname,DNS:www.yourdomainname/$sanText/g" options.cnf
fi

#Sign the Cert
echo "Signing the certificate with the CA"
openssl ca -batch -passin pass:"${caPassword}" -extensions SAN -extfile ./options.cnf -config openssl.cnf  -in "$csrFileName" \
 -out certs/"$domain".crt

rm options.cnf

# Verify the cert
echo "Verifying the cert and adding it to the serial number file"
openssl verify -CAfile "${myCACert[0]}" certs/"$domain".crt


#
#echo "---------------------------"
#echo "-----Below is your CSR-----"
#echo "---------------------------"
#echo
#cat requests/$csrFileName.csr
#
#echo
#echo "---------------------------"
#echo "-----Below is your Key-----"
#echo "---------------------------"
#echo
#cat privateKeys/$csrFileName.key
# to see the details of the cert
#openssl x509 -in certs/$csrFileName.crt -text -noout