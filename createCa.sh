#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

echo 'Please enter the Certificate Authority Name for the CA you are creating.'
echo 'This will also become the filename of your CA certificates'
read -r caname
#caname=myca3
echo 'Please Answer All of the questions in as much detail as you like.'
echo 'The Answers will be shown in the certs you create.'

echo 'You are about to be asked to enter information that will be incorporated'
echo 'into your certificate request.'
echo 'What you are about to enter is what is called a Distinguished Name or a DN.'
echo 'There are quite a few fields but you can leave some blank'
echo 'For some fields there will be a default value,'
echo 'If you enter '.', the field will be left blank.'
echo '-----'
echo 'Country Name (2 letter code):'; read -r C
echo 'State or Province Name (full name):';read -r ST
echo 'Locality Name (eg, city) :';read -r L
echo 'Organization Name (eg, company) :'; read -r O
echo 'Organizational Unit Name (eg, section) :'; read -r OU
echo 'Common Name (eg, fully qualified host name) :'; read -r CN
echo 'Email Address :'; read -r emailAddress
#C=US
#ST=CA
#L=San
#O=Name
#OU=IT
#CN=myca3.com
#emailAddress=leon@myca3.com

declare password
VALID=true
validCharacters='[\~\!\@\#\$\%\^\&\*\(\)\_\+]'
#~	Tilde
#!	Exclamation
#@	At sign
#$  Dollar sign
##	hash
#%	Percent
#^	Caret
#*	Asterisk
#_	Underscore
#+	Plus
#-	Hyphen
#=	Equal sign
#{	Left brace
#}	Right brace
#[	Left bracket
#]	Right bracket
#:	Colon
#,	Comma
#.	Full stop
#/    Forward slash
echo "A password is required to protect your CA Private Key."
echo "A valid password must:"
echo "Have a minimum of 10 characters and a maximum of 25."
echo "Contain at least one digits."
echo "Contain at least one uppercase letters."
echo "Contain at least one lowercase letters."
echo "Contain at least one special character"
echo "eg. one of: ${validCharacters//\\/}"
echo "Not contain spaces."

for (( ;; )); do
	read -r -s -p "Please enter the password for your CA private key: " PASS1
	echo
	read -r -s -p "Please re-enter the password for your CA private key: " PASS2
	echo
	echo

	if [[ "$PASS1" != "$PASS2" ]]; then
		echo "Passwords do not match. Please try again."
		VALID=false
    fi
	if L=${#PASS1}; [[ L -lt 10 || L -gt 25 ]]; then
		echo "Password must have a minimum of 10 characters and a maximum of 25."
		VALID=false
    fi
#	elif [[ $PASS1 != *[[:digit:]]*[[:digit:]]* ]]; then
	if [[ $PASS1 != *[[:digit:]]* ]]; then
		echo "Password should contain at least one digits."
		VALID=false
    fi
#	elif [[ $PASS1 != *[[:upper:]]*[[:upper:]]* ]]; then
	if [[ $PASS1 != *[[:upper:]]* ]]; then
		echo "Password should contain at least one uppercase letters."
		VALID=false
    fi
#	elif [[ $PASS1 != *[[:lower:]]*[[:lower:]]* ]]; then
	if [[ $PASS1 != *[[:lower:]]* ]]; then
		echo "Password should contain at least one lowercase letters."
		VALID=false
    fi
#	elif [[ $PASS1 != *[[:punct:]]*[[:punct:]]* ]]; then
	if ! grep -q -e "$validCharacters" <<< "$PASS1"; then
		echo "Password should contain at least one special character."
		echo "eg. one of: ${validCharacters//\\/}"
		VALID=false
    fi
	if [[ $PASS1 == *[[:blank:]]* ]]; then
		echo "Password cannot contain spaces."
		VALID=false
    fi
	if [[ "$VALID" == "true" ]]; then
		# valid password; break out of the loop
		echo "Password accepted."
		password=$PASS1
		break
    else
        # invalid password; reset VALID and try again
        VALID=true
	fi
	echo
done

mkdir ./cacerts
mkdir ./certs
mkdir ./usercerts
mkdir ./crl
mkdir ./newcerts
mkdir ./pfxfiles
mkdir ./privatekeys
mkdir ./requests
mkdir ./revoked


cp -f ./opensslSample.cnf ./openssl.cnf
sed -i .bak "s/yourcaname/$caname/g" openssl.cnf
sed -i .bak "s/yourcountryname/$C/g" openssl.cnf
sed -i .bak "s/yourstatename/$ST/g" openssl.cnf
sed -i .bak "s/yourlocalityname/$L/g" openssl.cnf
sed -i .bak "s/yourorgname/$O/g" openssl.cnf
sed -i .bak "s/yourorgunitname/$OU/g" openssl.cnf
sed -i .bak "s/yourcommonname/$CN/g" openssl.cnf
sed -i .bak "s/youremailaddress/$emailAddress/g" openssl.cnf

openssl genrsa -aes256 -passout pass:"$password" -out  cacerts/"$caname".key 4096
openssl req -newkey rsa:2048 -sha256 -x509 -days 1826 -key cacerts/"$caname."key -out cacerts/"$caname".crt -passin pass:"$password"  -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN/emailAddress=$emailAddress" -config openssl.cnf -extensions v3_ca
echo "1000" > serial
echo "1000" > crl/crlnumber
touch index.txt
echo "unique_subject = yes" > index.txt.attr
openssl ca -config openssl.cnf -passin pass:"$password" -gencrl -out crl/"$caname".crl.pem

echo "CA Certificate Created and you are ready to issue Certificates"
echo "Please copy the following files to Anywhere that needs to trust certificates from this CA"
echo "cacerts/$caname.crt"

# Create a new Certificate
#./newCert.sh localhost

#To Revoke a certificate, type the following ( for the localhost certificate generated above )
#openssl ca -config openssl.cnf -revoke certs/localhost.crt

