# createCa - Create your own CA for your environment and issue and revoke certificates as needed.

## Features:

* Create your own CA for your environment
* Issue server certificates for your environment
    * Creates PEM and PFX certificates
* Revoke certificates for your environment
* Create a certificate revocation list (CRL) for your environment

## Requirements:

* Linux or MacOS
* openssl

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

### configure nginx server to use your own CA

```shell
#Install nginx on your server
# Create a certificate for your nginx server hostname
./newCert.sh mylittleca.mydomain.com
# run the following command to configure and launch nginx to use your CA and the cert you just created
./startNginx.sh mylittleca.mydomain.com
```

#### Please excuse my repeated code in a few places. Bash functions are still confusing to me when passing complicated variables. I'm open to suggestions for moving some password checking into functions..
