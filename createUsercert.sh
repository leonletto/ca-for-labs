#!/bin/bash

#if [[ `id -u` != 0 ]]; then
#    #https://unix.stackexchange.com/a/23962
#    echo "Must be root to run script"
#    exit
#fi

echo 'Please enter the Certificate Name for the Certificateyou are creating.\n'
echo 'This will become the filename of your certificates'
read certname

echo 'Please Answer All of the questions in as much detail as you like.\n'
echo 'The Answers will be shown in the certs you create.\n'

echo 'You are about to be asked to enter information that will be incorporated'
echo 'into your certificate request.'
echo 'What you are about to enter is what is called a Distinguished Name or a DN.'
echo 'There are quite a few fields but you can leave some blank'
echo 'For some fields there will be a default value,'
echo 'If you enter '.', the field will be left blank.'
echo '-----'
echo 'Country Name (2 letter code):'; read C
echo 'State or Province Name (full name):';read ST
echo 'Locality Name (eg, city) :';read L
echo 'Organization Name (eg, company) :'; read O
echo 'Organizational Unit Name (eg, section) :'; read OU
echo 'Common Name (eg, username:serialnumber:whateverelseyoulike) :'; read CN
echo 'Email Address :'; read emailAddress


certpath=cacerts
mycert=( "$certpath"/*.crt )
mykey=( "$certpath"/*.key )
password=password

#certname=$1
#CERT_DUR=365 #1 year
KEY_LEN=2048

openssl genrsa -aes256 -passout pass:$password -out usercerts/$certname.key $KEY_LEN

#Remove passphrase from the key. Comment the line out to keep the passphrase
echo "Removing passphrase from key"
openssl rsa -in usercerts/$certname.key -out usercerts/$certname.key -passin pass:$password

openssl req -new -config openssl.cnf -key usercerts/$certname.key -sha256 -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN/emailAddress=$emailAddress" -out usercerts/$certname.csr

openssl ca -batch -passin pass:$password -config openssl.cnf -in usercerts/$certname.csr -out usercerts/$certname.crt

openssl pkcs12 -export -clcerts -in usercerts/$certname.crt -inkey usercerts/$certname.key -out usercerts/$certname.p12 -passout pass:$password

#for MacOs you need to do the following:
#security import usercerts/$certname.p12 -k ~/Library/Keychains/login.keychain

