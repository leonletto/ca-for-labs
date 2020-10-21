#!/bin/bash

#if [[ `id -u` != 0 ]]; then
#    #https://unix.stackexchange.com/a/23962
#    echo "Must be root to run script"
#    exit
#fi

certpath=cacerts
mycert=( "$certpath"/*.crt )
mykey=( "$certpath"/*.key )
password=password

USERNAME=$1
CERT_DUR=365 #1 year
KEY_LEN=2048

openssl genrsa -aes256 -passout pass:$password -out usercerts/$USERNAME.key $KEY_LEN

#Remove passphrase from the key. Comment the line out to keep the passphrase
echo "Removing passphrase from key"
openssl rsa -in usercerts/$USERNAME.key -out usercerts/$USERNAME.key -passin pass:$password

openssl req -new -config openssl.cnf -key usercerts/$USERNAME.key -sha256 -out usercerts/$USERNAME.csr -passin pass:$password

openssl ca -batch -passin pass:$password -config openssl.cnf -in usercerts/$USERNAME.csr -out usercerts/$USERNAME.crt

openssl pkcs12 -export -clcerts -in usercerts/$USERNAME.crt -inkey usercerts/$USERNAME.key -out usercerts/$USERNAME.p12 -passout pass:""

#for MacOs you eed to do the following:
security import usercerts/$USERNAME.p12 -k ~/Library/Keychains/login.keychain


#bash-3.2$ openssl req -new -config openssl.cnf -key usercerts/$USERNAME.key -sha256 -out usercerts/$USERNAME.csr
#You are about to be asked to enter information that will be incorporated
#into your certificate request.
#What you are about to enter is what is called a Distinguished Name or a DN.
#There are quite a few fields but you can leave some blank
#For some fields there will be a default value,
#If you enter '.', the field will be left blank.
#-----
#ca [US]:^C
#bash-3.2$ openssl req -new -key usercerts/$USERNAME.key -sha256 -out usercerts/$USERNAME.csr
#You are about to be asked to enter information that will be incorporated
#into your certificate request.
#What you are about to enter is what is called a Distinguished Name or a DN.
#There are quite a few fields but you can leave some blank
#For some fields there will be a default value,
#If you enter '.', the field will be left blank.
#-----
#Country Name (2 letter code) []:US
#State or Province Name (full name) []:CA
#Locality Name (eg, city) []:San
#Organization Name (eg, company) []:IT
#Organizational Unit Name (eg, section) []:IT
#Common Name (eg, fully qualified host name) []:leon
#Email Address []:leon@leon.com
#
#Please enter the following 'extra' attributes
#to be sent with your certificate request
#A challenge password []:
