#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

show_help() {
    cat <<'HELP'
Usage: ./revokeUserCert.sh [USERNAME [CA_PASSWORD]]

Revoke a user/client certificate and update the CRL.

Arguments (all optional — interactive prompts if omitted):
  USERNAME      Subject name of the user certificate to revoke
  CA_PASSWORD   Password for the CA private key

Options:
  -h, --help    Show this help message and exit

Environment:
  TRACE=1       Enable shell tracing (set -x)

Examples:
  ./revokeUserCert.sh
  ./revokeUserCert.sh user1
  ./revokeUserCert.sh user1 "CaPass123!"
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
    read -r -p "Please enter the server name (FQDN) for your certificate " hostname
    echo
else
    hostname=$1
fi

validateDomain "$hostname" "hostname" || exit 1

prompt_ca_password "${2:-}"

ca_passfile=$(create_passfile "$caPassword")

openssl ca -batch -config openssl.cnf -passin file:"$ca_passfile" -revoke usercerts/"$hostname".crt
if [ -f usercerts/"$hostname".crt ]; then
    mv usercerts/"$hostname".crt revoked/
fi
if [ -f privatekeys/"$hostname".key ]; then
    mv privatekeys/"$hostname".key revoked/
fi
if [ -f pfxfiles/"$hostname".pfx ]; then
    mv pfxfiles/"$hostname".pfx revoked/
fi
caname=$(basename "$caCertPath"/*.key .key)
openssl ca -batch -config openssl.cnf -passin file:"$ca_passfile" -gencrl -out crl/"$caname".crl.pem




