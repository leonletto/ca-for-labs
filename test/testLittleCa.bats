#!/usr/bin/env bash

# setup the test script

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$DIR/..:$PATH"
}

@test "test that the script is executable" {
    [[ -x "$DIR/../createCa.sh" ]]
}
@test "Test Creating the CA - should return cacerts/testca.crt" {
    run test/testCreateCa.exp
    [ "$status" -eq 0 ]
}

@test "Test newCert should confirm cert was created" {
    run test/testNewCert.exp
    [ "$status" -eq 0 ]
}

@test "Test Create Cert from CSR with no SAN should say cert OK" {
    run test/testNewCertFromCSRNoSAN.exp
    [ "$status" -eq 0 ]
}

@test "Test Create Cert from CSR with SAN should say cert OK" {
    run test/testNewCertFromCSRWithSAN.exp
    [ "$status" -eq 0 ]
}

@test "Test revokeCert should say Data Base Updated" {
    run test/testRevokeCert.exp
    [ "$status" -eq 0 ]
}

@test "Test testNewUserCertNoPass should confirm cert was created" {
    run test/testNewUserCertNoPass.exp
    [ "$status" -eq 0 ]
}

@test "Test revokeUserCertNoPass should say Data Base Updated" {
    run test/testRevokeUserCertNoPass.exp
    [ "$status" -eq 0 ]
}

@test "Test testNewUserCertWithPass should confirm cert was created" {
    run test/testNewUserCertWithPass.exp
    [ "$status" -eq 0 ]
}

@test "Test revokeUserCertWithPass should say Data Base Updated" {
    run test/testRevokeUserCertWithPass.exp
    [ "$status" -eq 0 ]
}


teardown_file() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    "$DIR"/../fixup.sh
}
#teardown() {
#    "$DIR"/../fixup.sh
##    rm -f /tmp/output
#}
