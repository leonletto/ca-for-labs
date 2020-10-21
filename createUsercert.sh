#!/bin/bash

if [[ `id -u` != 0 ]]; then
    #https://unix.stackexchange.com/a/23962
    echo "Must be root to run script"
    exit
fi

USERNAME=$1
CA_ROOT = "$CA_ROOT"
CERT_DUR = 365 #1 year
KEY_LEN = 2048

openssl genrsa -aes256 -out $CA_ROOT/certs/users/$USERNAME.key $KEY_LEN

openssl req -new -key $CA_ROOT/certs/users/$USERNAME.key -sha256 \
	    -out $CA_ROOT/certs/users/$USERNAME.csr

openssl x509 -req -days $CERT_DUR \
	    -in $CA_ROOT/certs/users/$USERNAME.csr \
	    -CA $CA_ROOT/certs/ca.crt \
      -CAkey $CA_ROOT/private/ca.key \
	    -CAserial $CA_ROOT/serial \
	    -CAcreateserial \
	    -out $CA_ROOT/certs/users/$USERNAME.crt

openssl pkcs12 -export -clcerts \
	    -in $CA_ROOT/certs/users/$USERNAME.crt \
	    -inkey $CA_ROOT/certs/users/$USERNAME.key \
      -out $CA_ROOT/certs/users/$USERNAME.p12
