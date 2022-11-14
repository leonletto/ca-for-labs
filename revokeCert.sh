#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi



caCertPath=cacerts
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
VALID=true
myCAPrivateKey=( "$caCertPath"/*.key )
command="openssl rsa -check -in ${myCAPrivateKey[0]} -passin pass:${caPassword} &> /dev/null"
secondTry=false
for (( ;; )); do
    if ! eval "$command" || false
    then
		VALID=false
	else
	    VALID=true
    fi
	if [[ "$VALID" == "true" ]]; then
		# valid password; break out of the loop
		echo "CA Password accepted."
		caPassword=$(echo "${caPassword}" | sed -e 's/\\//g')
		if [[ "$secondTry" == "true" ]]; then
            caPassword=$(echo "${checkCAPassword}" | sed -e 's/\\//g')
        fi
		break
	else
	    echo "Invalid password for CA private key."
		echo "Please try again."
		echo
	    read -r -s -p "Please enter the password for your CA to issue certificates: " checkCAPassword
	    checkCAPassword="$(echo "${checkCAPassword}" | sed -e 's/[]\/$*.^|[]/\\&/g')"
	    command="openssl rsa -check -in ${myCAPrivateKey[0]} -passin pass:${checkCAPassword} &> /dev/null"
	    echo
	    secondTry=true
    echo
	fi
	echo
done


openssl ca -batch -config openssl.cnf -passin pass:"${caPassword}" -revoke certs/"$hostname".crt
mv certs/"$hostname".crt revoked/
mv privatekeys/"$hostname".key revoked/
mv pfxfiles/"$hostname".pfx revoked/
openssl ca -batch -config openssl.cnf -passin pass:"${caPassword}" -gencrl -out crl/littleCA.crl.pem
