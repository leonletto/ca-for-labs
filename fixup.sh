#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

. ./common.sh
sedCmd '/^crlDistributionPoints/d' optionsSample.cnf

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
rm -f optionsSample.cnf.bak
rm -f userCertoptions.cnf
rm -f userCertoptions.cnf.*
rm -f serial
rm -f serial.old
rm -f littleCAnginx.conf
rm -f .env





