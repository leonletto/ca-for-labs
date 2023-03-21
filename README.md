# ca-for-labs - formerly littleCa - Create your own CA for your environment and issue and revoke certificates as needed.

## Features:

* Create your own CA for your lab, home network or demo environment
* Issue server certificates for your environment
    * Creates PEM and PFX certificates
* Revoke certificates for your environment
* Create a certificate revocation list (CRL) for your environment

## Requirements:

* Linux or MacOS
* openssl 1.1.1 or higher or LibreSSL 2.8.3 or higher

## Usage:

### Create your own CA for your environment

```shell
chmod +x createCa.sh
./createCa.sh
```

### Issue server certificates for your environment manually

###            

```shell
chmod +x newCert.sh
./newCert.sh myhost.mydomain.com
```

### Issue server certificates for your environment automatically

*Note: all passwords must have single quotes around them to prevent special characters from being interpreted by the
shell*

```shell
chmod +x newCert.sh
./newCert.sh myhost.mydomain.com 'myCAPassword' 'myPFXPassword' 'myPrivateKeyPassword'
```

### Issue server certificates for your environment with your CSR file

Save your CSR file in the same directory as the scripts. The CSR file can have any name you want. The script will
prompt you for the name of the CSR file if you do not supply it as an argument.

###            

```shell
chmod +x newCertFromCSR.sh
./newCert.sh test.com.csr
```

### Issue server certificates for your environment with your CSR file and automatically

Save your CSR file in the same directory as the scripts. The CSR file can have any name you want. The script will
prompt you for the name of the CSR file if you do not supply it as an argument.

###            

```shell
chmod +x newCertFromCSR.sh
./newCert.sh test.com.csr 'myCAPassword'
```

### Issue user certificates for your environment (working on it...)

```shell
chmod +x newUserCert.sh
./newUserCert.sh joe
```

### Revoke certificates for your environment

```shell
chmod +x revokeCert.sh
./revokeCert.sh myhost.mydomain.com

# or
./revokeCert.sh myhost.mydomain.com 'myCAPassword'
```

### Revoke User certificates for your environment

```shell
chmod +x revokeCert.sh
./revokeUserCert.sh joe

# or
./revokeCert.sh joe 'myCAPassword'
```

### configure nginx server to use your own CA

```shell
#Install nginx on your server
# Create a certificate for your nginx server hostname
./newCert.sh mylittleca.mydomain.com
# run the following command to configure and launch nginx to use your CA and the cert you just created
./startNginx.sh mylittleca.mydomain.com
```

# Testing

### I am using the BATS framework to test the scripts. You can find more information about BATS here:

[Bats-Core](https://github.com/bats-core/bats-core)

### To run the test suite for this project, run the following commands to install the testing framework and run the sample tests:

```shell
git submodule add https://github.com/bats-core/bats-core.git test/bats
git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support
git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert
git submodule add https://github.com/bats-core/bats-file.git test/test_helper/bats-file
chmod +x ./createCa.sh ./fixup.sh ./newCert.sh ./newUserCert.sh ./revokeCert.sh ./revokeUserCert.sh
./test/bats/bin/bats test/testLittleCa.bats
```
