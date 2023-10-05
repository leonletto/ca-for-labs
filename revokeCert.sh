#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

. ./common.sh

if ! [[ "${1:-}" ]]
then
    echo
    read -r -p "Please enter the server name (FQDN) for your certificate " hostname
    echo
else
    hostname=$1
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

openssl ca -batch -config openssl.cnf -passin pass:"${caPassword}" -revoke certs/"$hostname".crt
if [ -f certs/"$hostname".crt ]; then
    mv certs/"$hostname".crt revoked/
fi
if [ -f privatekeys/"$hostname".key ]; then
    mv privatekeys/"$hostname".key revoked/
fi
if [ -f pfxfiles/"$hostname".pfx ]; then
    mv pfxfiles/"$hostname".pfx revoked/
fi
openssl ca -batch -config openssl.cnf -passin pass:"${caPassword}" -gencrl -out crl/littleCA.crl.pem




