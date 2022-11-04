# createCa - Create your own CA for your environment and issue and revoke certificates as needed.

## Features:
* Create your own CA for your environment
* Issue certificates for your environment
* Revoke certificates for your environment
* Create a certificate revocation list (CRL) for your environment

## Requirements:
* openssl
* bash
* sed
* grep
* awk
* openssl.cnf
* options.cnf

## Usage:
* Create your own CA for your environment
```shell
chmod +x createCa.sh
./createCa.sh
```

* Issue certificates for your environment
```shell
chmod +x newCert.sh
./newCert.sh
```
