#!/usr/bin/env bash

# setup the test script

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'test_helper/bats-file/load'
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$DIR/..:$PATH"
}

@test "test that the script is executable" {
    assert_file_executable "$DIR/../createCa.sh"
}
@test "Test Creating the CA - should return cacerts/testca.crt" {
    run test/testCreateCa.exp
    assert_success
}

@test "Test newCert should confirm cert was created" {
    run test/testNewCert.exp
    assert_success
}

@test "Test Create Cert from CSR with no SAN should say cert OK" {
    run test/testNewCertFromCSRNoSAN.exp
    assert_success
}

@test "Test Create Cert from CSR with SAN should say cert OK" {
    run test/testNewCertFromCSRWithSAN.exp
    assert_success
}

@test "Test revokeCert should say Data Base Updated" {
    run test/testRevokeCert.exp
    assert_success
}

@test "Test testNewUserCertNoPass should confirm cert was created" {
    run test/testNewUserCertNoPass.exp
    assert_success
}

@test "Test revokeUserCertNoPass should say Data Base Updated" {
    run test/testRevokeUserCertNoPass.exp
    assert_success
}

@test "Test testNewUserCertWithPass should confirm cert was created" {
    run test/testNewUserCertWithPass.exp
    assert_success
}

@test "Test revokeUserCertWithPass should say Data Base Updated" {
    run test/testRevokeUserCertWithPass.exp
    assert_success
}


teardown_file() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    "$DIR"/../fixup.sh
}
#teardown() {
#    "$DIR"/../fixup.sh
##    rm -f /tmp/output
#}