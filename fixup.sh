#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

show_help() {
    cat <<'HELP'
Usage: ./fixup.sh

Remove all generated CA files, certificates, keys, and configuration.
This resets the directory to a clean state so you can start fresh.

WARNING: This permanently deletes all certificates, keys, and CA data.

Options:
  -h, --help    Show this help message and exit

Environment:
  TRACE=1       Enable shell tracing (set -x)

Examples:
  ./fixup.sh
HELP
    exit 0
}

if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_help
fi

. ./common.sh

rm -rf cacerts
rm -rf certs
rm -rf crl
rm -rf newcerts
rm -rf pfxfiles
rm -rf privatekeys
rm -rf requests
rm -rf usercerts
rm -rf revoked
rm -f index.txt
rm -f index.txt.*
rm -f openssl.cnf
rm -f openssl.cnf.*
rm -f options.cnf
rm -f options.cnf.*
rm -f userCertoptions.cnf
rm -f userCertoptions.cnf.*
rm -f serial
rm -f serial.old
rm -f littleCAnginx.conf
rm -f .env





